USE master;

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'Chapter10_ConversationPriority')
BEGIN
	PRINT 'Dropping database ''Chapter10_ConversationPriority''';
	DROP DATABASE Chapter10_ConversationPriority;
END
GO

CREATE DATABASE Chapter10_ConversationPriority
GO

--*******************************************************************************************************************
--*  Enable the trustworthy property on the database, because we're making stored procedure calls between databases
--*******************************************************************************************************************
ALTER DATABASE Chapter10_ConversationPriority SET TRUSTWORTHY ON
GO

USE Chapter10_ConversationPriority
GO

--****************************************************
--*  Create the needed message types for this sample
--****************************************************
CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c10/EmailRequestMessageType] VALIDATION = WELL_FORMED_XML
GO

CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c10/EmailResponseMessageType] VALIDATION = WELL_FORMED_XML
GO

--************************************************
--*  Create the needed contracts for this sample
--************************************************
CREATE CONTRACT [http://ssb.csharp.at/SSB_Book/c10/EmailContract]
(
	[http://ssb.csharp.at/SSB_Book/c10/EmailRequestMessageType] SENT BY INITIATOR,
	[http://ssb.csharp.at/SSB_Book/c10/EmailResponseMessageType] SENT BY TARGET
)
GO

--******************************
--*  Create the service queues
--******************************
CREATE QUEUE InitiatorQueue1
GO

CREATE QUEUE TargetQueue
GO

--*******************************
--*  Create the services itself
--*******************************
CREATE SERVICE InitiatorService1
ON QUEUE InitiatorQueue1
(
	[http://ssb.csharp.at/SSB_Book/c10/EmailContract]
)
GO

CREATE SERVICE TargetService
ON QUEUE TargetQueue
(
	[http://ssb.csharp.at/SSB_Book/c10/EmailContract]
)
GO

--**************************************************************
--*  Create the table that stores the processed email messages
--**************************************************************
CREATE TABLE ProcessedEmailMessages
(
	ID UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
	Recipients NVARCHAR(MAX) NOT NULL,
	Subject NVARCHAR(256) NOT NULL,
	Body NVARCHAR(MAX) NOT NULL,
	Priority INT NOT NULL
)
GO

--*****************************************************************************************
--* Create the stored procedure that processes the received messages from the TargetQueue
--*****************************************************************************************
CREATE PROCEDURE ProcessRequestMessages
AS
	DECLARE @ch UNIQUEIDENTIFIER;
	DECLARE @messagetypename NVARCHAR(256);
	DECLARE	@messagebody XML;
	DECLARE @responsemessage XML;
	DECLARE @priority INT;

	WHILE (1=1)
	BEGIN
		BEGIN TRY
			BEGIN TRANSACTION;

			RECEIVE TOP(1)
				@ch = conversation_handle,
				@messagetypename = message_type_name,
				@messagebody = CAST(message_body AS XML),
				@priority = priority
			FROM TargetQueue;

			IF (@@ROWCOUNT = 0)
			BEGIN
				ROLLBACK TRANSACTION
				BREAK
			END

			IF (@messagetypename = 'http://ssb.csharp.at/SSB_Book/c10/EmailRequestMessageType')
			BEGIN
				DECLARE @recipients VARCHAR(MAX);
				DECLARE	@subject NVARCHAR(256);
				DECLARE @body NVARCHAR(MAX);
				DECLARE @profileName SYSNAME = 'KlausProfile';
				
				-- Get the needed information from the received message
				SELECT @recipients = @messagebody.value('/Email[1]/Recipients[1]', 'NVARCHAR(MAX)')
				SELECT @subject = @messagebody.value('/Email[1]/Subject[1]', 'NVARCHAR(MAX)')
				SELECT @body = @messagebody.value('/Email[1]/Body[1]', 'NVARCHAR(MAX)')
				
				-- Store the received request message in a table
				INSERT INTO ProcessedEmailMessages (ID, Recipients, Subject, Body, Priority) VALUES (NEWID(), @recipients, @subject, @body, @priority)
				
				-- Send the email
				-- EXEC msdb.dbo.sp_send_dbmail 'KlausProfile', @recipients, NULL, NULL, @subject, @body;

				-- Construct the response message
				SET @responsemessage = '<EmailResponse>Your email message was queued for further processing.</EmailResponse>';

				-- Send the response message back to the initiating service
				SEND ON CONVERSATION @ch MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c10/EmailResponseMessageType] (@responsemessage);

				-- End the conversation on the target's side
				END CONVERSATION @ch;
			END

			IF (@messagetypename = 'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog')
			BEGIN
				-- End the conversation
				END CONVERSATION @ch;
			END

			COMMIT TRANSACTION
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION
		END CATCH
	END
GO

--*******************************************************
--* Enable the stored procedure for internal activation
--*******************************************************
ALTER QUEUE [TargetQueue]
WITH ACTIVATION
(
   STATUS = ON,
   PROCEDURE_NAME = [ProcessRequestMessages],
   MAX_QUEUE_READERS = 1,
   EXECUTE AS SELF
)
GO

--*********************************************************************************************
--* Create some workload between the InitiatorService1 and the TargetService
--*********************************************************************************************
DECLARE @dh UNIQUEIDENTIFIER;
DECLARE @i INT = 0;
DECLARE @message XML;

SET @message = 
'
<Email>
	<Recipients>Klaus.Aschenbrenner@csharp.at</Recipients>
	<Subject>SQL Service Broker email</Subject>
	<Body>This is a test email from SQL Server 2008 using Conversation Priorities</Body>
</Email>
'

WHILE @i < 10
BEGIN
	BEGIN TRANSACTION;
	
	-- Begin a low priority conversation
	BEGIN DIALOG CONVERSATION @dh
		FROM SERVICE [InitiatorService1]
		TO SERVICE N'TargetService'
		ON CONTRACT [http://ssb.csharp.at/SSB_Book/c10/EmailContract]
		WITH ENCRYPTION = OFF;
		
	SEND ON CONVERSATION @dh 
		MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c10/EmailRequestMessageType]
		(@message);

	COMMIT;
	
	SELECT @i += 1;
END
GO

--*****************************************
--* Retrieve all processed email messages 
--*****************************************
SELECT * FROM ProcessedEmailMessages
GO

--**********************************
--* Create a new initiator service
--**********************************
CREATE QUEUE InitiatorQueue2
GO

CREATE SERVICE InitiatorService2
ON QUEUE InitiatorQueue2
(
	[http://ssb.csharp.at/SSB_Book/c10/EmailContract]
)
GO

--*********************************
--*  Enable conversation priority
--*********************************
ALTER DATABASE Chapter10_ConversationPriority SET HONOR_BROKER_PRIORITY ON
GO

--*******************************************************************
--*  -- Check, if the database is enabled for Conversation Priority
--*******************************************************************
SELECT name, is_honor_broker_priority_on from sys.databases;
GO

--******************************************
--*  Create the necessary priority objects
--******************************************
CREATE BROKER PRIORITY LowPriorityInitiatorToTarget FOR CONVERSATION SET
(
	CONTRACT_NAME = [http://ssb.csharp.at/SSB_Book/c10/EmailContract],
	LOCAL_SERVICE_NAME = InitiatorService1,
	REMOTE_SERVICE_NAME = 'TargetService',
	PRIORITY_LEVEL = 1
)
GO

CREATE BROKER PRIORITY LowPriorityTargetToInitiator FOR CONVERSATION SET
(
	CONTRACT_NAME = [http://ssb.csharp.at/SSB_Book/c10/EmailContract],
	LOCAL_SERVICE_NAME = TargetService,
	REMOTE_SERVICE_NAME = 'InitiatorService1',
	PRIORITY_LEVEL = 1
)
GO

CREATE BROKER PRIORITY HighPriorityInitiatorToTarget FOR CONVERSATION SET
(
	CONTRACT_NAME = [http://ssb.csharp.at/SSB_Book/c10/EmailContract],
	LOCAL_SERVICE_NAME = InitiatorService2,
	REMOTE_SERVICE_NAME = 'TargetService',
	PRIORITY_LEVEL = 10
)
GO

CREATE BROKER PRIORITY HighPriorityTargetToInitiator FOR CONVERSATION SET
(
	CONTRACT_NAME = [http://ssb.csharp.at/SSB_Book/c10/EmailContract],
	LOCAL_SERVICE_NAME = TargetService,
	REMOTE_SERVICE_NAME = 'InitiatorService2',
	PRIORITY_LEVEL = 10
)
GO

--*************************************
--* View the created priority objects
--*************************************
SELECT * FROM sys.conversation_priorities
GO

--*********************************************************************************************
--* Create some workload between the InitiatorService1/InitiatorService2 and the TargetService
--*********************************************************************************************
DECLARE @dh UNIQUEIDENTIFIER;
DECLARE @i INT = 0;
DECLARE @message XML;

SET @message = 
'
<Email>
	<Recipients>Klaus.Aschenbrenner@csharp.at</Recipients>
	<Subject>SQL Service Broker email</Subject>
	<Body>This is a test email from SQL Server 2008 using Conversation Priorities</Body>
</Email>
'

WHILE @i < 10
BEGIN
	BEGIN TRANSACTION;
	
	-- Every 10 requests we're sending the message from a different initiator service to get a different priority
	IF (@i % 10) = 0
	BEGIN
		-- Begin a high priority conversation
		BEGIN DIALOG CONVERSATION @dh
			FROM SERVICE [InitiatorService1]
			TO SERVICE N'TargetService'
			ON CONTRACT [http://ssb.csharp.at/SSB_Book/c10/EmailContract]
			WITH ENCRYPTION = OFF;
			
		SEND ON CONVERSATION @dh 
			MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c10/EmailRequestMessageType]
			(@message);
	END
	ELSE
	BEGIN
		-- Begin a low priority conversation
		BEGIN DIALOG CONVERSATION @dh
			FROM SERVICE [InitiatorService2]
			TO SERVICE N'TargetService'
			ON CONTRACT [http://ssb.csharp.at/SSB_Book/c10/EmailContract]
			WITH ENCRYPTION = OFF;
			
		SEND ON CONVERSATION @dh 
			MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c10/EmailRequestMessageType]
			(@message);
	END

	COMMIT;

	SELECT @i += 1;
END
GO

--*****************************************************************************
--* Retrieve the conversation priority for the openend conversation endpoints 
--*****************************************************************************
SELECT priority, * FROM sys.conversation_endpoints
GO

--*****************************************
--* Retrieve all processed email messages 
--*****************************************
SELECT * FROM ProcessedEmailMessages
GO