USE master;

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'Chapter3_HelloWorldSvc')
BEGIN
	PRINT 'Dropping database ''Chapter3_HelloWorldSvc''';
	DROP DATABASE Chapter3_HelloWorldSvc;
END
GO

CREATE DATABASE Chapter3_HelloWorldSvc
GO

USE Chapter3_HelloWorldSvc
GO

--*********************************************
--*  Create the message type "RequestMessage"
--*********************************************
CREATE MESSAGE TYPE
[http://ssb.csharp.at/SSB_Book/c03/RequestMessage]
VALIDATION = NONE
GO

--*********************************************
--*  Create the message type "ResponseMessage"
--*********************************************
CREATE MESSAGE TYPE
[http://ssb.csharp.at/SSB_Book/c03/ResponseMessage]
VALIDATION = NONE
GO

--*********************************************
--*  Show the created message types
--*********************************************
SELECT * FROM sys.service_message_types 
GO

--************************************************
--*  Changing the validation of the message types
--************************************************
ALTER MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c03/RequestMessage]
VALIDATION = WELL_FORMED_XML
GO

ALTER MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c03/ResponseMessage]
VALIDATION = WELL_FORMED_XML
GO

--************************************************
--*  Create the contract "HelloWorldContract"
--************************************************
CREATE CONTRACT [http://ssb.csharp.at/SSB_Book/c03/HelloWorldContract]
(
	[http://ssb.csharp.at/SSB_Book/c03/RequestMessage] SENT BY INITIATOR,
	[http://ssb.csharp.at/SSB_Book/c03/ResponseMessage] SENT BY TARGET
)
GO

--*************************************************************
--*  Getting some information about the newly created contract
--*************************************************************
SELECT 
	sc.name AS 'Contract', 
	mt.name AS 'Message type', 
	cm.is_sent_by_initiator,
	cm.is_sent_by_target,
	mt.validation
FROM sys.service_contract_message_usages cm 
	INNER JOIN sys.service_message_types mt ON cm.message_type_id = mt.message_type_id
	INNER JOIN sys.service_contracts sc ON sc.service_contract_id = cm.service_contract_id
GO

--********************************************************
--*  Create the queues "InitiatorQueue" and "TargetQueue"
--********************************************************
CREATE QUEUE InitiatorQueue
WITH STATUS = ON
GO

CREATE QUEUE TargetQueue
WITH STATUS = ON
GO

--*************************************************************
--*  Getting some information about the newly created queues
--*************************************************************
SELECT * FROM sys.service_queues
GO

--************************************************************
--*  Create the queues "InitiatorService" and "TargetService"
--************************************************************
CREATE SERVICE InitiatorService
ON QUEUE InitiatorQueue 
(
	[http://ssb.csharp.at/SSB_Book/c03/HelloWorldContract]
)
GO

CREATE SERVICE TargetService
ON QUEUE TargetQueue
(
	[http://ssb.csharp.at/SSB_Book/c03/HelloWorldContract]
)
GO

--*************************************************************
--*  Getting some information about the newly created services
--*************************************************************
SELECT
	sv.name AS 'Service',
	sc.name AS 'Contract'
FROM sys.services sv
	INNER JOIN sys.service_contract_usages scu ON scu.service_id = sv.service_id
	INNER JOIN sys.service_contracts sc ON sc.service_contract_id = scu.service_contract_id
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
			ON CONTRACT [http://ssb.csharp.at/SSB_Book/c03/HelloWorldContract]
			WITH ENCRYPTION = OFF;

		SET @msg = 
			'<HelloWorldRequest>
					Klaus Aschenbrenner
			</HelloWorldRequest>';

		SEND ON CONVERSATION @ch MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c03/RequestMessage] (@msg);
	COMMIT
END TRY
BEGIN CATCH
	ROLLBACK TRANSACTION
END CATCH
GO

--********************************************************************
--*  View the sent message on the queue "TargetQueue"
--********************************************************************
SELECT * FROM TargetQueue
GO

--********************************************************************
--*  View the created conversation endpoints
--********************************************************************
SELECT * FROM sys.conversation_endpoints
GO

--********************************************************************
--*  Retrieve the sent message from the queue "TargetQueue"
--********************************************************************
DECLARE @cg UNIQUEIDENTIFIER
DECLARE @ch UNIQUEIDENTIFIER
DECLARE @messagetypename NVARCHAR(256)
DECLARE	@messagebody XML;

BEGIN TRY
	BEGIN TRANSACTION;

		RECEIVE TOP(1)
			@cg = conversation_group_id,
			@ch = conversation_handle,
			@messagetypename = message_type_name,
			@messagebody = CAST(message_body AS XML)
		FROM TargetQueue

		PRINT 'Conversation group: ' + CAST(@cg AS NVARCHAR(MAX))
		PRINT 'Conversation handle: ' + CAST(@ch AS NVARCHAR(MAX))
		PRINT 'Message type: ' + @messagetypename
		PRINT 'Message body: ' + CAST(@messagebody AS NVARCHAR(MAX))

	COMMIT
END TRY
BEGIN CATCH
	ROLLBACK TRANSACTION
END CATCH
GO

--***********************************************************************************
--*  Retrieve the sent message from the queue "TargetQueue" with a WAITFOR statement
--***********************************************************************************
DECLARE @cg UNIQUEIDENTIFIER
DECLARE @ch UNIQUEIDENTIFIER
DECLARE @messagetypename NVARCHAR(256)
DECLARE	@messagebody XML;

BEGIN TRY
	BEGIN TRANSACTION;

		WAITFOR (
			RECEIVE TOP (1)
				@cg = conversation_group_id,
				@ch = conversation_handle,
				@messagetypename = message_type_name,
				@messagebody = CAST(message_body AS XML)
			FROM TargetQueue
		), TIMEOUT 60000

		IF (@@ROWCOUNT > 0)
		BEGIN
			PRINT 'Conversation group: ' + CAST(@cg AS NVARCHAR(MAX))
			PRINT 'Conversation handle: ' + CAST(@ch AS NVARCHAR(MAX))
			PRINT 'Message type: ' + @messagetypename
			PRINT 'Message body: ' + CAST(@messagebody AS NVARCHAR(MAX))
		END

	COMMIT
END TRY
BEGIN CATCH
	ROLLBACK TRANSACTION
END CATCH
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

--*******************************************************************
--*  Send a response message back to the service "InitiatorService"
--*******************************************************************
DECLARE @ch UNIQUEIDENTIFIER
DECLARE @messagetypename NVARCHAR(256)
DECLARE	@messagebody XML
DECLARE @responsemessage XML;

BEGIN TRY
	BEGIN TRANSACTION
		WAITFOR (
			RECEIVE TOP (1)
				@ch = conversation_handle,
				@messagetypename = message_type_name,
				@messagebody = CAST(message_body AS XML)
			FROM TargetQueue
		), TIMEOUT 60000

		IF (@@ROWCOUNT > 0)
		BEGIN
			IF (@messagetypename = 'http://ssb.csharp.at/SSB_Book/c03/RequestMessage')
			BEGIN
				-- Store the received request message in a table
				INSERT INTO ProcessedMessages (ID, MessageBody, ServiceName) VALUES (NEWID(), @messagebody, 'TargetService')

				-- Construct the response message
				SET @responsemessage = '<HelloWorldResponse>' + @messagebody.value('/HelloWorldRequest[1]', 'NVARCHAR(MAX)') + '</HelloWorldResponse>';

				-- Send the response message back to the initiating service
				SEND ON CONVERSATION @ch MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c03/ResponseMessage] (@responsemessage);

				-- End the conversation on the target's side
				END CONVERSATION @ch;
			END
		END
	COMMIT
END TRY
BEGIN CATCH
	ROLLBACK TRANSACTION
END CATCH
GO


--********************************************************************
--*  View the sent message on the queue "InitiatorQueue"
--********************************************************************
SELECT * FROM InitiatorQueue
GO

--********************************************************************
--*  View the processed message in the table "ProcessedMessages"
--********************************************************************
SELECT * FROM ProcessedMessages
GO

--*******************************************************************
--*  Service program for the service "InitiatorService"
--*******************************************************************
DECLARE @ch UNIQUEIDENTIFIER
DECLARE @messagetypename NVARCHAR(256)
DECLARE	@messagebody XML;

BEGIN TRY
	BEGIN TRANSACTION
		WAITFOR (
			RECEIVE TOP (1)
				@ch = conversation_handle,
				@messagetypename = message_type_name,
				@messagebody = CAST(message_body AS XML)
			FROM InitiatorQueue
		), TIMEOUT 60000

		IF (@@ROWCOUNT > 0)
		BEGIN
			IF (@messagetypename = 'http://ssb.csharp.at/SSB_Book/c03/ResponseMessage')
			BEGIN
				-- Store the received response) message in a table
				INSERT INTO ProcessedMessages (ID, MessageBody, ServiceName) VALUES (NEWID(), @messagebody, 'InitiatorService')
			END

			IF (@messagetypename = 'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog')
			BEGIN
				-- End the conversation on the initiator's side
				END CONVERSATION @ch;
			END
		END
	COMMIT
END TRY
BEGIN CATCH
	ROLLBACK TRANSACTION
END CATCH
GO

--***********************************************************************************
--*  Endless receive loop for processing incoming messages on the initiator's queue
--***********************************************************************************
DECLARE @ch UNIQUEIDENTIFIER
DECLARE @messagetypename NVARCHAR(256)
DECLARE	@messagebody XML;

WHILE (1=1)
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION

		WAITFOR (
			RECEIVE TOP (1)
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

		IF (@messagetypename = 'http://ssb.csharp.at/SSB_Book/c03/ResponseMessage')
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

--********************************************************************************
--*  Endless receive loop for processing incoming messages on the target's queue
--********************************************************************************
DECLARE @ch UNIQUEIDENTIFIER
DECLARE @messagetypename NVARCHAR(256)
DECLARE	@messagebody XML
DECLARE @responsemessage XML;

WHILE (1=1)
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION

		WAITFOR (
			RECEIVE TOP (1)
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

		IF (@messagetypename = 'http://ssb.csharp.at/SSB_Book/c03/RequestMessage')
		BEGIN
			-- Store the received request message in a table
			INSERT INTO ProcessedMessages (ID, MessageBody, ServiceName) VALUES (NEWID(), @messagebody, 'TargetService')

			-- Construct the response message
			SET @responsemessage = '<HelloWorldResponse>' + @messagebody.value('/HelloWorldRequest[1]', 'nvarchar(max)') + '</HelloWorldResponse>';

			-- Send the response message back to the initiating service
			SEND ON CONVERSATION @ch MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c03/ResponseMessage] (@responsemessage);

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

--**********************************************************
--*  Error handling with a savepoint on the target's queue
--**********************************************************
DECLARE @ch UNIQUEIDENTIFIER
DECLARE @messagetypename NVARCHAR(256)
DECLARE	@messagebody XML
DECLARE @responsemessage XML;

WHILE (1=1)
BEGIN
	BEGIN TRANSACTION

	WAITFOR (
		RECEIVE TOP (1)
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

	SAVE TRANSACTION MessageReceivedSavepoint

	IF (@messagetypename = 'http://ssb.csharp.at/SSB_Book/c03/RequestMessage')
	BEGIN
		BEGIN TRY
			-- Store the received request message in a table
			INSERT INTO ProcessedMessages (ID, MessageBody, ServiceName) VALUES (NEWID(), @messagebody, 'TargetService')

			-- Construct the response message
			SET @responsemessage = '<HelloWorldResponse>' + @messagebody.value('/HelloWorldRequest[1]', 'nvarchar(max)') + '</HelloWorldResponse>';

			-- Send the response message back to the initiating service
			SEND ON CONVERSATION @ch MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c03/ResponseMessage] (@responsemessage);

			-- End the conversation on the target's side
			END CONVERSATION @ch;
		END TRY
		BEGIN CATCH
			IF (ERROR_NUMBER() = 1205) 
			BEGIN
				-- A deadlock occurred. 
				-- We can try it again...
				ROLLBACK TRANSACTION
				CONTINUE
			END
			ELSE
			BEGIN
				-- A other error occurred.
				-- The message can't be processed successfully, because it's a poison message
				ROLLBACK TRANSACTION MessageReceivedSavepoint
				PRINT 'Error occured: ' + CAST(@messagebody AS NVARCHAR(MAX))
			END
		END CATCH
	END

	IF (@messagetypename = 'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog')
	BEGIN
		-- End the conversation
		END CONVERSATION @ch;
	END

	COMMIT TRANSACTION
END
GO

--**************************************
--*  Poison messages in Service Broker
--**************************************
-- Reactivating the queue
ALTER QUEUE TargetQueue WITH STATUS = ON
GO

-- Service program for handling the poison message
DECLARE @ch UNIQUEIDENTIFIER
DECLARE @messagetypename NVARCHAR(256)
DECLARE	@messagebody XML

WHILE (1=1)
BEGIN
	BEGIN TRANSACTION

	WAITFOR (
		RECEIVE TOP (1)
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

	-- Rollling back the current transaction
	PRINT 'Rollback the current transaction - simulating a poison message...'
	ROLLBACK TRANSACTION
END
GO

--**********************************************************
--*  Setting up the event notification for poison messages
--**********************************************************
-- Create the queue which stores the event notification messages
CREATE QUEUE PoisonMessageNotifyQueue
GO

-- Create the service that accepts the event notification messages
CREATE SERVICE PoisonMessageNotifyService ON QUEUE PoisonMessageNotifyQueue
(
	[http://schemas.microsoft.com/SQL/Notifications/PostEventNotification]
);
GO

-- Create the event notification itself
CREATE EVENT NOTIFICATION PoisonMessageNotification ON QUEUE TargetQueue
FOR Broker_Queue_Disabled
TO SERVICE 'PoisonMessageNotifyService', 'current database'
GO

-- Select the received event notification message
SELECT * FROM PoisonMessageNotifyQueue
GO

--**********************************************************
--*  End an conversation with an error
--**********************************************************
DECLARE @ch UNIQUEIDENTIFIER
DECLARE @messagetypename NVARCHAR(256)
DECLARE	@messagebody XML

BEGIN TRY
	BEGIN TRANSACTION
		WAITFOR (
			RECEIVE TOP (1)
				@ch = conversation_handle,
				@messagetypename = message_type_name,
				@messagebody = CAST(message_body AS XML)
			FROM TargetQueue
		), TIMEOUT 60000

		IF (@messagetypename = 'http://ssb.csharp.at/SSB_Book/c03/RequestMessage')
		BEGIN
			-- End the conversation with an error
			END CONVERSATION @ch WITH ERROR = 4242 DESCRIPTION = 'My custom error message'
		END
	COMMIT
END TRY
BEGIN CATCH
	ROLLBACK TRANSACTION
END CATCH
GO

-- Table that stores error information
CREATE TABLE ErrorLog
(
	ID UNIQUEIDENTIFIER NOT NULL,
	ErrorCode INT NOT NULL,
	ErrorMessage NVARCHAR(MAX) NOT NULL
)
GO

-- Service program for the InitiatorService, that handles also error message types
DECLARE @ch UNIQUEIDENTIFIER 
DECLARE @messagetypename NVARCHAR(256)
DECLARE	@messagebody XML
DECLARE @errorcode INT
DECLARE @errormessage NVARCHAR(3000);

BEGIN TRY
	BEGIN TRANSACTION
		WAITFOR (
			RECEIVE TOP(1)
				@ch = conversation_handle,
				@messagetypename = message_type_name,
				@messagebody = CAST(message_body AS XML)
			FROM InitiatorQueue
		), TIMEOUT 60000

		IF (@@ROWCOUNT > 0)
		BEGIN
			IF (@messagetypename = 'http://ssb.csharp.at/SSB_Book/c03/ResponseMessage')
			BEGIN
				-- Store the received response) message in a table
				INSERT INTO ProcessedMessages (ID, MessageBody, ServiceName) VALUES (NEWID(), @messagebody, 'InitiatorService')
			END

			IF (@messagetypename = 'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog')
			BEGIN
				-- End the conversation on the initiator's side
				END CONVERSATION @ch;
			END

			IF (@messagetypename = 'http://schemas.microsoft.com/SQL/ServiceBroker/Error')
			BEGIN
				-- Extract the error information from the sent message
				SET @errorcode = (SELECT @messagebody.value(
					N'declare namespace brokerns="http://schemas.microsoft.com/SQL/ServiceBroker/Error"; 
					(/brokerns:Error/brokerns:Code)[1]', 'int'));
				SET @errormessage = (SELECT @messagebody.value(
					'declare namespace brokerns="http://schemas.microsoft.com/SQL/ServiceBroker/Error";
					(/brokerns:Error/brokerns:Description)[1]', 'nvarchar(3000)'));

				-- Log the error
				INSERT INTO ErrorLog(ID, ErrorCode, ErrorMessage)
				VALUES (NEWID(), @errorcode, @errormessage)

				-- End the conversation on the initiator's side
				END CONVERSATION @ch;
			END
		END
	COMMIT
END TRY
BEGIN CATCH
	ROLLBACK TRANSACTION
END CATCH
GO