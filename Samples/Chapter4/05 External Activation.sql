USE master;

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'Chapter4_ExternalActivation')
BEGIN
	PRINT 'Dropping database ''Chapter4_ExternalActivation''';
	DROP DATABASE Chapter4_ExternalActivation;
END
GO

CREATE DATABASE Chapter4_ExternalActivation
GO

USE Chapter4_ExternalActivation
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

 --********************************************************
--*  Create the queues "InitiatorQueue" and "TargetQueue"
--*********************************************************
CREATE QUEUE InitiatorQueue
WITH STATUS = ON
GO

CREATE QUEUE TargetQueue
GO

 --**************************************************************
--*  Create the services "InitiatorService" and "TargetService"
--***************************************************************
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

 --******************************************************************
--*  Deactivate the internal activation on the queue (if necessary)
--*******************************************************************
ALTER QUEUE TargetQueue
	WITH ACTIVATION (DROP)
GO

--*********************************************
--*  Create the event notification queue
--*********************************************
CREATE QUEUE ExternalActivatorQueue
GO

--*********************************************
--*  Create the event notification service
--*********************************************
CREATE SERVICE ExternalActivatorService
ON QUEUE ExternalActivatorQueue
(
	[http://schemas.microsoft.com/SQL/Notifications/PostEventNotification]
)
GO

--***********************************************************************
--*  Subscribe to the QUEUE_ACTIVATION event on the queue "TargetQueue"
--***********************************************************************
CREATE EVENT NOTIFICATION EventNotificationTargetQueue
	ON QUEUE TargetQueue
	FOR QUEUE_ACTIVATION
	TO SERVICE 'ExternalActivatorService', 'current database';
GO

--********************************************************************
--*  Sending a message from the InitiatorService to the TargetService
--********************************************************************
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
GO

--***********************************************************************
--*  See the received event notification
--***********************************************************************
SELECT * FROM ExternalActivatorQueue

SELECT * FROM TargetQueue