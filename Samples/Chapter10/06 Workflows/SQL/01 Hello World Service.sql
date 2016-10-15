USE master;

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'Chapter10_Workflows')
BEGIN
	PRINT 'Dropping database ''Chapter10_Workflows''';
	DROP DATABASE Chapter10_Workflows;
END
GO

CREATE DATABASE Chapter10_Workflows
GO

USE Chapter10_Workflows
GO

--*********************************************
--*  Create the message type "RequestMessage"
--*********************************************
CREATE MESSAGE TYPE
[http://ssb.csharp.at/SSB_Book/c10/RequestMessage]
VALIDATION = WELL_FORMED_XML
GO

--*********************************************
--*  Create the message type "ResponseMessage"
--*********************************************
CREATE MESSAGE TYPE
[http://ssb.csharp.at/SSB_Book/c10/ResponseMessage]
VALIDATION = WELL_FORMED_XML
GO

--************************************************
--*  Create the contract "HelloWorldContract"
--************************************************
CREATE CONTRACT [http://ssb.csharp.at/SSB_Book/c10/HelloWorldContract]
(
	[http://ssb.csharp.at/SSB_Book/c10/RequestMessage] SENT BY INITIATOR,
	[http://ssb.csharp.at/SSB_Book/c10/ResponseMessage] SENT BY TARGET
)
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

--************************************************************
--*  Create the queues "InitiatorService" and "TargetService"
--************************************************************
CREATE SERVICE InitiatorService
ON QUEUE InitiatorQueue 
(
	[http://ssb.csharp.at/SSB_Book/c10/HelloWorldContract]
)
GO

CREATE SERVICE TargetService
ON QUEUE TargetQueue
(
	[http://ssb.csharp.at/SSB_Book/c10/HelloWorldContract]
)
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
			ON CONTRACT [http://ssb.csharp.at/SSB_Book/c10/HelloWorldContract]
			WITH ENCRYPTION = OFF;

		SET @msg = 
			'<HelloWorldRequest>
					Klaus Aschenbrenner
			</HelloWorldRequest>';

		SEND ON CONVERSATION @ch MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c10/RequestMessage] (@msg);
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

--*******************************************************
--* The workflow processed now the sent request message 
--*******************************************************
-- ...
-- ...
-- ...

--*****************************************************
--*  View the sent response message from the workflow
--*****************************************************
SELECT CAST(message_body AS XML), * FROM InitiatorQueue
GO

--********************************************************
--*  Process the sent response message from the workflow
--********************************************************
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