USE master;

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'Chapter10_BatchJobFrameworkClient')
BEGIN
	PRINT 'Dropping database ''Chapter10_BatchJobFrameworkClient''';
	DROP DATABASE Chapter10_BatchJobFrameworkClient;
END
GO

CREATE DATABASE Chapter10_BatchJobFrameworkClient
GO

USE Chapter10_BatchJobFrameworkClient
GO

-- Creating the necessary message types
CREATE MESSAGE TYPE 
[http://ssb.csharp.at/SSB_Book/c10/BatchJobRequestMessage] VALIDATION = VALID_XML
GO

CREATE MESSAGE TYPE 
[http://ssb.csharp.at/SSB_Book/c10/BatchJobResponseMessage] VALIDATION = VALID_XML
GO

-- Create the necessary contract which binds the 2 messages together
CREATE CONTRACT [http://ssb.csharp.at/SSB_Book/c10/SubmitBatchJobContract]
(
	[http://ssb.csharp.at/SSB_Book/c10/BatchJobRequestMessage] SENT BY INITIATOR,
	[http://ssb.csharp.at/SSB_Book/c10/BatchJobResponseMessage] SENT BY TARGET
)
GO

-- Create the Job Server client queue
CREATE QUEUE [BatchJobResponseQueue]
	WITH STATUS = ON
GO

-- Create the Job Server client service
CREATE SERVICE [BatchJobSubmissionService]
ON QUEUE [BatchJobResponseQueue]
(
	[http://ssb.csharp.at/SSB_Book/c10/SubmitBatchJobContract]
)
GO

-- Create the Job Server Service queue
CREATE QUEUE [BatchJobSubmissionQueue]
	WITH STATUS = ON
GO

-- Create the Job Server Service
CREATE SERVICE [BatchJobProcessingService]
ON QUEUE [BatchJobSubmissionQueue]
(
	[http://ssb.csharp.at/SSB_Book/c10/SubmitBatchJobContract]
)
GO

-- Create the service program which is activated on the queue "BatchJobResponseQueue" when a 
-- new "BatchJobResponseMessage" arrives from the backend service
CREATE PROCEDURE sp_ProcessTaskSubmissions
AS
	DECLARE @conversationHandle AS UNIQUEIDENTIFIER;
	DECLARE @messageBody AS XML;
	DECLARE @messageType NVARCHAR(MAX);

	BEGIN TRY
		BEGIN TRANSACTION;

		RECEIVE TOP (1)
			@conversationHandle = conversation_handle,
			@messageBody = CAST(message_body AS XML),
			@messageType = message_type_name
		FROM [BatchJobResponseQueue]

		IF (@@ROWCOUNT > 0)
		BEGIN
			IF (@messageType = 'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog')
			BEGIN
				END CONVERSATION @conversationHandle;
			END

			IF (@messageType = 'http://ssb.csharp.at/SSB_Book/c10/BatchJobResponseMessage')
			BEGIN
				-- We can do whatever we want to do...
				PRINT 'A TaskResponseMessage was received...'
			END
		END

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		-- Log error (eg. in an error table)
		PRINT ERROR_MESSAGE()
		ROLLBACK TRANSACTION
	END CATCH
GO

-- Activating the stored procedure on the incoming queue
ALTER QUEUE [BatchJobResponseQueue]
WITH ACTIVATION
(
	PROCEDURE_NAME = sp_ProcessTaskSubmissions,
	MAX_QUEUE_READERS = 1,
	STATUS = ON,
	EXECUTE AS SELF
)
GO

-- Register the Managed Assembly which does the processing of the submitted Job Server messages
CREATE ASSEMBLY [BatchFramework.Implementation]
FROM 'D:\Klaus\Work\Private\Apress\Pro SQL 2005 Service Broker\Chapter 10\Samples\02 Batch Job Framework\BatchFramework.Implementation\bin\Debug\BatchFramework.Implementation.dll'
GO

-- Add the debug information about the assembly
ALTER ASSEMBLY  [BatchFramework.Implementation]
ADD FILE FROM 'D:\Klaus\Work\Private\Apress\Pro SQL 2005 Service Broker\Chapter 10\Samples\02 Batch Job Framework\BatchFramework.Implementation\bin\Debug\BatchFramework.Implementation.pdb'
GO

-- Register the Managed Stored Procedure "ProcessJobServerTasks"
CREATE PROCEDURE ProcessBatchJob
(
	@Message XML,
	@MessageType NVARCHAR(MAX),
	@ConversationHandle UNIQUEIDENTIFIER
)
AS
EXTERNAL NAME [BatchFramework.Implementation].[BatchFramework.Implementation.BatchFramework].ProcessBatchJobTasks
GO

-- Create a logging table which stores all processed Service Broker messages
CREATE TABLE MessageLog
(
	Date DATETIME,
	LogData NVARCHAR(MAX)
)
GO

-- Create the service program which is activated on the queue "BatchJobSubmissionQueue" 
-- when a new "BatchJobRequestMessage" arrives from a client
CREATE PROCEDURE sp_ProcessBatchJobSubmissions
AS
	DECLARE @conversationHandle AS UNIQUEIDENTIFIER;
	DECLARE @messageType NVARCHAR(MAX);
	DECLARE @messageBody AS XML;

	BEGIN TRY
		BEGIN TRANSACTION;

		RECEIVE TOP (1)
			@conversationHandle = conversation_handle,
			@messageBody = CAST(message_body AS XML),
			@messageType = message_type_name
		FROM [BatchJobSubmissionQueue]

		IF (@@ROWCOUNT > 0)
		BEGIN
			EXECUTE dbo.ProcessBatchJob @messageBody, @messageType, @conversationHandle;
			
			DECLARE @data NVARCHAR(MAX)
			SET @data = CAST(@messageBody AS NVARCHAR(MAX))
			INSERT INTO MessageLog VALUES (GETDATE(), @data);
		END

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		-- Log error (eg. in an error table)
		PRINT ERROR_MESSAGE()
		ROLLBACK TRANSACTION
	END CATCH
GO

-- Create the factory lookup table
CREATE TABLE BatchJobs
(
   ID UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
   BatchJobType NVARCHAR(255) NOT NULL,
   CLRTypeName NVARCHAR(255) NOT NULL
)
GO

-- Insert the available JobServer tasks in the factory lookup table
INSERT INTO BatchJobs (ID, BatchJobType, CLRTypeName)
VALUES (
	NEWID(), 
	'http://ssb.csharp.at/SSB_Book/c10/BatchJobTypeA', 
	'BatchFramework.Implementation.BatchJobTypeA,BatchFramework.Implementation, Version=1.0.0.0,Culture=neutral, PublicKeyToken=neutral')

INSERT INTO BatchJobs (ID, BatchJobType, CLRTypeName)
VALUES (
	NEWID(), 
	'http://schemas.microsoft.com/SQL/ServiceBroker/Error', 
	'BatchFramework.Implementation.BatchJobTypeA,BatchFramework.Implementation, Version=1.0.0.0,Culture=neutral, PublicKeyToken=neutral')
GO

-- Activating the stored procedure on the incoming queue
ALTER QUEUE [BatchJobSubmissionQueue]
WITH ACTIVATION
(
	PROCEDURE_NAME = sp_ProcessBatchJobSubmissions,
	MAX_QUEUE_READERS = 1,
	STATUS = ON,
	EXECUTE AS SELF
)
GO

-- Sending a Job Server request to the service
BEGIN TRANSACTION
DECLARE @conversationHandle UNIQUEIDENTIFIER

BEGIN DIALOG @conversationHandle
	FROM SERVICE [BatchJobSubmissionService]
	TO SERVICE 'BatchJobProcessingService'
	ON CONTRACT [http://ssb.csharp.at/SSB_Book/c10/SubmitBatchJobContract]
	WITH ENCRYPTION = OFF;

SEND ON CONVERSATION @conversationHandle
	MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c10/BatchJobRequestMessage]
	(
		CAST('
			<BatchJobRequest 
				xmlns="http://ssb.csharp.at/JobServer/TaskRequest"
				Submittor="win2003dev\Klaus Aschenbrenner"
				SubmittedTime="12.12.2006 14:23:45"
				ID="D8E97781-0151-4DBF-B983-F1B4AE6F2445"
				MachineName="win2003dev"
				BatchJobType="http://ssb.csharp.at/SSB_Book/c10/BatchJobTypeA">
				<BatchJobData>
					<ContentOfTheCustomBatchJob>
						<FirstElement>This is my first information for the batch job</FirstElement>
						<SecondElement>This is my second information for the batch job</SecondElement>
						<ThirdElement>This is my third information for the batch job</ThirdElement>
					</ContentOfTheCustomBatchJob>
				</BatchJobData>
			</BatchJobRequest>
			'
		AS XML)
	)
COMMIT
GO

CREATE TABLE FlightTickets
(
   ID UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
   [From] NVARCHAR(255) NOT NULL,
   [To] NVARCHAR(255) NOT NULL,
   FlightNumber NVARCHAR(255) NOT NULL,
   Airline NVARCHAR(255) NOT NULL,
   Departure NVARCHAR(255) NOT NULL,
   Arrival NVARCHAR(255) NOT NULL
)
GO

-- Register the new managed assembly
CREATE ASSEMBLY [BatchFramework.TicketReservationTask]
FROM 'D:\Klaus\Work\Private\Apress\Pro SQL 2005 Service Broker\Chapter 10\Samples\02 Batch Job Framework\BatchFramework.TicketReservationTask\bin\Debug\BatchFramework.TicketReservationTask.dll'
GO

-- Add the debug information about the assembly
ALTER ASSEMBLY [BatchFramework.TicketReservationTask]
ADD FILE FROM 'D:\Klaus\Work\Private\Apress\Pro SQL 2005 Service Broker\Chapter 10\Samples\02 Batch Job Framework\BatchFramework.TicketReservationTask\bin\Debug\BatchFramework.TicketReservationTask.pdb'
GO

INSERT INTO BatchJobs
(
   ID,
   BatchJobType,
   CLRTypeName
)
VALUES
(
   NEWID(),
   'http://ssb.csharp.at/SSB_Book/c10/TicketReservationTask',
   'BatchFramework.TicketReservationTask.TicketReservationTask,BatchFramework.TicketReservationTask, Version=1.0.0.0,Culture=neutral,PublicKeyToken=neutral'
)
GO

-- The following message books a flight ticket
BEGIN TRANSACTION
DECLARE @conversationHandle UNIQUEIDENTIFIER

BEGIN DIALOG @conversationHandle
	FROM SERVICE [BatchJobSubmissionService]
	TO SERVICE 'BatchJobProcessingService'
	ON CONTRACT [http://ssb.csharp.at/SSB_Book/c10/SubmitBatchJobContract]
	WITH ENCRYPTION = OFF;

SEND ON CONVERSATION @conversationHandle
	MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c10/BatchJobRequestMessage]
	(
		CAST('
			<BatchJobRequest 
				xmlns="http://ssb.csharp.at/JobServer/TaskRequest"
				Submittor="win2003dev\Klaus Aschenbrenner"
				SubmittedTime="12.12.2006 14:23:45"
				ID="D8E97781-0151-4DBF-B983-F1B4AE6F2445"
				MachineName="win2003dev"
				BatchJobType="http://ssb.csharp.at/SSB_Book/c10/TicketReservationTask">
				<BatchJobData>
					<FlightTicketReservation>
						<From>IAD</From>
						<To>SEA</To>
						<FlightNumber>UA 119</FlightNumber>
						<Airline>United Airlines</Airline>
						<Departure>2006-11-10 08:00</Departure>
						<Arrival>2006-11-10 09:10</Arrival>
					</FlightTicketReservation>
				</BatchJobData>
			</BatchJobRequest>
			'
		AS XML)
	)
COMMIT
GO

SELECT * FROM MessageLog
GO

SELECT * FROM FlightTickets
GO