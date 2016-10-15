USE master;

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'Chapter4_InternalActivation')
BEGIN
	PRINT 'Dropping database ''Chapter4_InternalActivation''';
	DROP DATABASE Chapter4_InternalActivation;
END
GO

CREATE DATABASE Chapter4_InternalActivation
GO

USE Chapter4_InternalActivation
GO

--*********************************************
--*  Create the message type "RequestMessage"
--*********************************************
CREATE MESSAGE TYPE
[http://ssb.csharp.at/SSB_Book/c04/RequestMessage]
VALIDATION = NONE
GO

--*********************************************
--*  Create the message type "ResponseMessage"
--*********************************************
CREATE MESSAGE TYPE
[http://ssb.csharp.at/SSB_Book/c04/ResponseMessage]
VALIDATION = NONE
GO

--************************************************
--*  Changing the validation of the message types
--************************************************
ALTER MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c04/RequestMessage]
VALIDATION = WELL_FORMED_XML
GO

ALTER MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c04/ResponseMessage]
VALIDATION = WELL_FORMED_XML
GO

--************************************************
--*  Create the contract "HelloWorldContract"
--************************************************
CREATE CONTRACT [http://ssb.csharp.at/SSB_Book/c04/HelloWorldContract]
(
	[http://ssb.csharp.at/SSB_Book/c04/RequestMessage] SENT BY INITIATOR,
	[http://ssb.csharp.at/SSB_Book/c04/ResponseMessage] SENT BY TARGET
)
GO

--**************************************************
--*  Create a table to store the processed messages
--**************************************************
CREATE TABLE ProcessedMessages
(
	ID UNIQUEIDENTIFIER NOT NULL,
	MessageBody XML NOT NULL,
	ServiceName NVARCHAR(MAX) NOT NULL
)
GO

--************************************************************************
--*  A stored procedure used for internal activation on the target queue
--************************************************************************
CREATE PROCEDURE ProcessRequestMessages
AS
	DECLARE @ch UNIQUEIDENTIFIER
	DECLARE @messagetypename NVARCHAR(256)
	DECLARE	@messagebody XML
	DECLARE @responsemessage XML;

	WHILE (1=1)
	BEGIN
		BEGIN TRY
			BEGIN TRANSACTION

			WAITFOR (
				RECEIVE TOP(1)
					@ch = conversation_handle,
					@messagetypename = message_type_name,
					@messagebody = CAST(message_body AS XML)
				FROM TargetQueue
			), TIMEOUT 60000

			IF (@@ROWCOUNT = 0)
			BEGIN
				ROLLBACK TRANSACTION
				BREAK
			END

			IF (@messagetypename = 'http://ssb.csharp.at/SSB_Book/c04/RequestMessage')
			BEGIN
				-- Store the received request message in a table
				INSERT INTO ProcessedMessages (ID, MessageBody, ServiceName) VALUES (NEWID(), @messagebody, 'TargetService')

				-- Construct the response message
				SET @responsemessage = '<HelloWorldResponse>' + @messagebody.value('/HelloWorldRequest[1]', 'NVARCHAR(MAX)') + '</HelloWorldResponse>';

				-- Send the response message back to the initiating service
				SEND ON CONVERSATION @ch MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c04/ResponseMessage] (@responsemessage);

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

--********************************************************
--*  Create the queues "InitiatorQueue" and "TargetQueue"
--********************************************************
CREATE QUEUE InitiatorQueue
WITH STATUS = ON
GO

CREATE QUEUE TargetQueue
WITH ACTIVATION
(
	STATUS = ON,
	PROCEDURE_NAME = [ProcessRequestMessages],
	MAX_QUEUE_READERS = 1,
	EXECUTE AS SELF
)
GO

-- or
ALTER QUEUE [TargetQueue]
WITH ACTIVATION
(
   STATUS = ON,
   PROCEDURE_NAME = [ProcessRequestMessages],
   MAX_QUEUE_READERS = 1,
   EXECUTE AS SELF
)


--********************************************************
--*  View the internal activation configuration
--********************************************************
SELECT * FROM sys.service_queues
GO

--************************************************************
--*  Create the queues "InitiatorService" and "TargetService"
--************************************************************
CREATE SERVICE InitiatorService
ON QUEUE InitiatorQueue 
(
	[http://ssb.csharp.at/SSB_Book/c04/HelloWorldContract]
)
GO

CREATE SERVICE TargetService
ON QUEUE TargetQueue
(
	[http://ssb.csharp.at/SSB_Book/c04/HelloWorldContract]
)
GO

--********************************************************
--*  View a status report about the internal activation
--********************************************************
SELECT 
	t1.name AS [Service Name],  
	t3.name AS [Schema Name],  
	t2.name AS [Queue Name],  
	CASE WHEN t4.state IS NULL 
		THEN 'Not available' 
		ELSE t4.state 
		END AS [Queue State],  
	CASE WHEN t4.tasks_waiting IS NULL THEN '--' 
		ELSE CONVERT(VARCHAR, t4.tasks_waiting) 
		END AS [Tasks Waiting], 
	CASE WHEN t4.last_activated_time IS NULL THEN '--' 
		ELSE CONVERT(VARCHAR, t4.last_activated_time) 
		END AS [Last Activated Time],  
	CASE WHEN t4.last_empty_rowset_time IS NULL THEN '--' 
		ELSE CONVERT(VARCHAR, t4.last_empty_rowset_time) 
		END AS [Last Empty Rowset Time], 
	( 
		SELECT 
			COUNT(*) 
		FROM sys.transmission_queue t6 
		WHERE (t6.from_service_name = t1.name) 
		AND (t5.service_broker_guid = t6.to_broker_instance)
	)
	AS [Message Count] 
	FROM sys.services t1    
		INNER JOIN sys.service_queues t2 ON t1.service_queue_id = t2.object_id
		INNER JOIN sys.schemas t3 ON t2.schema_id = t3.schema_id
		LEFT OUTER JOIN sys.dm_broker_queue_monitors t4 ON t2.object_id = t4.queue_id  AND t4.database_id = DB_ID()
		INNER JOIN sys.databases t5 ON t5.database_id = DB_ID()
GO

--********************************************************************
--*  Sending a message from the InitiatorService to the TargetService
--********************************************************************
BEGIN TRY
	BEGIN TRANSACTION;
		DECLARE @ch UNIQUEIDENTIFIER
		DECLARE @msg NVARCHAR(MAX);

		BEGIN DIALOG CONVERSATION @ch
			FROM SERVICE [InitiatorService]
			TO SERVICE 'TargetService'
			ON CONTRACT [http://ssb.csharp.at/SSB_Book/c04/HelloWorldContract]
			WITH ENCRYPTION = OFF;

		SET @msg = 
			'<HelloWorldRequest>
					Klaus Aschenbrenner
			</HelloWorldRequest>';

		SEND ON CONVERSATION @ch MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c04/RequestMessage] (@msg);
	COMMIT;
END TRY
BEGIN CATCH
	ROLLBACK TRANSACTION
END CATCH

--********************************************************************
--*  View the currently activated stored procedures
--********************************************************************
SELECT * FROM sys.dm_broker_activated_tasks 
GO

--**************************************************************************
--*  A stored procedure used for internal activation on the initiator queue
--**************************************************************************
CREATE PROCEDURE ProcessResponseMessages
AS
	DECLARE @ch UNIQUEIDENTIFIER -- conversation handle
	DECLARE @messagetypename NVARCHAR(256)
	DECLARE	@messagebody XML;

	WHILE (1=1)
	BEGIN
		BEGIN TRY
			BEGIN TRANSACTION

			WAITFOR (
				RECEIVE TOP(1)
					@ch = conversation_handle,
					@messagetypename = message_type_name,
					@messagebody = CAST(message_body AS XML)
				FROM InitiatorQueue
			), TIMEOUT 60000

			IF (@@ROWCOUNT = 0)
			BEGIN
				ROLLBACK TRANSACTION
				BREAK
			END

			IF (@messagetypename = 'http://ssb.csharp.at/SSB_Book/c04/ResponseMessage')
			BEGIN
				-- Store the received response) message in a table
				INSERT INTO ProcessedMessages (ID, MessageBody, ServiceName) VALUES (NEWID(), @messagebody, 'InitiatorService')
			END

			IF (@messagetypename = 'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog')
			BEGIN
				-- End the conversation on the initiator's side
				END CONVERSATION @ch;
			END

			COMMIT TRANSACTION
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION
		END CATCH
	END
GO

--*****************************************************************
--*  Enabling internal activation on the queue "InitiatorQueue"
--*****************************************************************
ALTER QUEUE InitiatorQueue
WITH ACTIVATION
(
	STATUS = ON,
	PROCEDURE_NAME = [ProcessResponseMessages],
	MAX_QUEUE_READERS = 5,
	EXECUTE AS SELF
)
GO

--*****************************************************************
--*  Deactivating internal activation on the queue "TargetQueue"
--*****************************************************************
ALTER QUEUE [TargetQueue]
WITH ACTIVATION
(
   STATUS = OFF
)

-- or 
ALTER QUEUE [TargetQueue]
WITH ACTIVATION
(
   MAX_QUEUE_READERS = 0
)

--*************************************************************
--*  Generating a high message workload for the target queue
--*************************************************************
DECLARE @i INT
SET @i = 1

WHILE (@i <= 10000)
BEGIN
	BEGIN TRANSACTION;
		DECLARE @ch UNIQUEIDENTIFIER
		DECLARE @msg NVARCHAR(MAX);

		BEGIN DIALOG CONVERSATION @ch
			FROM SERVICE [InitiatorService]
			TO SERVICE 'TargetService'
			ON CONTRACT [http://ssb.csharp.at/SSB_Book/c04/HelloWorldContract]
			WITH ENCRYPTION = OFF;

		SET @msg = 
			'<HelloWorldRequest>
					Klaus Aschenbrenner
			</HelloWorldRequest>';

		SEND ON CONVERSATION @ch MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c04/RequestMessage] (@msg);

	COMMIT TRANSACTION;
	SET @i = @i + 1
END
GO

--*************************************************************
--*  Activate the target queue for message processing
--*************************************************************
ALTER QUEUE TargetQueue
WITH ACTIVATION
(
	STATUS = ON,
	PROCEDURE_NAME = [ProcessRequestMessages],
	MAX_QUEUE_READERS = 20,
	EXECUTE AS SELF
)
GO