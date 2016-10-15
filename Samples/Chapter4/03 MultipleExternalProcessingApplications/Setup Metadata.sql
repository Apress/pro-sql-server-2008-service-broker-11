USE master;

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'Chapter4_ExternalActivationMultipleActivatedApplications')
BEGIN
	PRINT 'Dropping database ''Chapter4_ExternalActivationMultipleActivatedApplications''';
	DROP DATABASE Chapter4_ExternalActivationMultipleActivatedApplications;
END
GO

CREATE DATABASE Chapter4_ExternalActivationMultipleActivatedApplications
GO

USE Chapter4_ExternalActivationMultipleActivatedApplications
GO

--*********************************************
--*  Create the message type "RequestMessage"
--*********************************************
CREATE MESSAGE TYPE
[www.csharp.at/SSB_Book/c04/RequestMessage]
VALIDATION = NONE
GO

--*********************************************
--*  Create the message type "ResponseMessage"
--*********************************************
CREATE MESSAGE TYPE
[www.csharp.at/SSB_Book/c04/ResponseMessage]
VALIDATION = NONE
GO

--************************************************
--*  Changing the validation of the message types
--************************************************
ALTER MESSAGE TYPE [www.csharp.at/SSB_Book/c04/RequestMessage]
VALIDATION = WELL_FORMED_XML
GO

ALTER MESSAGE TYPE [www.csharp.at/SSB_Book/c04/ResponseMessage]
VALIDATION = WELL_FORMED_XML
GO

--************************************************
--*  Create the contract "HelloWorldContract"
--************************************************
CREATE CONTRACT [www.csharp.at/SSB_Book/c04/HelloWorldContract]
(
	[www.csharp.at/SSB_Book/c04/RequestMessage] SENT BY INITIATOR,
	[www.csharp.at/SSB_Book/c04/ResponseMessage] SENT BY TARGET
)
GO

 --*********************************************************
--*  Create the queues "InitiatorQueue" and "TargetQueue1"
--**********************************************************
CREATE QUEUE InitiatorQueue
WITH STATUS = ON
GO

CREATE QUEUE TargetQueue1
GO

CREATE QUEUE TargetQueue2
GO

 --**************************************************************
--*  Create the services "InitiatorService" and "TargetService"
--***************************************************************
CREATE SERVICE InitiatorService
ON QUEUE InitiatorQueue
(
	[www.csharp.at/SSB_Book/c04/HelloWorldContract]
)
GO

CREATE SERVICE TargetService1
ON QUEUE TargetQueue1
(
	[www.csharp.at/SSB_Book/c04/HelloWorldContract]
)
GO

CREATE SERVICE TargetService2
ON QUEUE TargetQueue2
(
	[www.csharp.at/SSB_Book/c04/HelloWorldContract]
)
GO

 --******************************************************************
--*  Deactivate the internal activation on the queue (if necessary)
--*******************************************************************
ALTER QUEUE TargetQueue1
	WITH ACTIVATION (DROP)
GO

ALTER QUEUE TargetQueue2
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

--*******************************************************************************************
--*  Subscribe to the QUEUE_ACTIVATION event on the queues "TargetQueue1" and "TargetQueue2"
--*******************************************************************************************
CREATE EVENT NOTIFICATION EventNotificationTargetQueue
	ON QUEUE TargetQueue1
	FOR QUEUE_ACTIVATION
	TO SERVICE 'ExternalActivatorService', 'current database';
GO

CREATE EVENT NOTIFICATION EventNotificationTargetQueue
	ON QUEUE TargetQueue2
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
		TO SERVICE 'TargetService2'
		ON CONTRACT [www.csharp.at/SSB_Book/c04/HelloWorldContract]
		WITH ENCRYPTION = OFF;

	SET @msg = 
		'<HelloWorldRequest>
				Klaus Aschenbrenner
		</HelloWorldRequest>';

	SEND ON CONVERSATION @ch MESSAGE TYPE [www.csharp.at/SSB_Book/c04/RequestMessage] (@msg);
COMMIT;
GO

--***********************************************************************
--*  See the received event notification
--***********************************************************************
SELECT CAST(message_body as xml), * FROM ExternalActivatorQueue

SELECT * FROM TargetQueue1
SELECT * FROM TargetQueue2