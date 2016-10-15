USE master;

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'Chapter5_ManagedServiceBroker')
BEGIN
	PRINT 'Dropping database ''Chapter5_ManagedServiceBroker''';
	DROP DATABASE Chapter5_ManagedServiceBroker;
END
GO

CREATE DATABASE Chapter5_ManagedServiceBroker
GO

USE Chapter5_ManagedServiceBroker
GO

--*********************************************
--*  Create the message type "RequestMessage"
--*********************************************
CREATE MESSAGE TYPE
[http://ssb.csharp.at/SSB_Book/c05/RequestMessage]
VALIDATION = NONE
GO

--*********************************************
--*  Create the message type "ResponseMessage"
--*********************************************
CREATE MESSAGE TYPE
[http://ssb.csharp.at/SSB_Book/c05/ResponseMessage]
VALIDATION = NONE
GO

--************************************************
--*  Changing the validation of the message types
--************************************************
ALTER MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c05/RequestMessage]
VALIDATION = WELL_FORMED_XML
GO

ALTER MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c05/ResponseMessage]
VALIDATION = WELL_FORMED_XML
GO

--************************************************
--*  Create the contract "HelloWorldContract"
--************************************************
CREATE CONTRACT [http://ssb.csharp.at/SSB_Book/c05/HelloWorldContract]
(
	[http://ssb.csharp.at/SSB_Book/c05/RequestMessage] SENT BY INITIATOR,
	[http://ssb.csharp.at/SSB_Book/c05/ResponseMessage] SENT BY TARGET
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
	[http://ssb.csharp.at/SSB_Book/c05/HelloWorldContract]
)
GO

CREATE SERVICE TargetService
ON QUEUE TargetQueue
(
	[http://ssb.csharp.at/SSB_Book/c05/HelloWorldContract]
)
GO

--************************************************************************
--*  A stored procedure used for internal activation on the target queue
--************************************************************************
CREATE PROCEDURE ProcessRequestMessages
AS
	DECLARE @ch UNIQUEIDENTIFIER -- conversation handle
	DECLARE @messagetypename NVARCHAR(256)
	DECLARE	@messagebody XML
	DECLARE @responsemessage XML;

	WHILE (1=1)
	BEGIN
		BEGIN TRANSACTION

		WAITFOR (
			RECEIVE TOP(1)
				@ch = conversation_handle,
				@messagetypename = message_type_name,
				@messagebody = CAST(message_body AS XML)
			FROM
				TargetQueue
		), TIMEOUT 1000

		IF (@@ROWCOUNT = 0)
		BEGIN
			ROLLBACK TRANSACTION
			BREAK
		END

		IF (@messagetypename = 'http://ssb.csharp.at/SSB_Book/c05/RequestMessage')
		BEGIN
			-- Construct the response message
			SET @responsemessage = '<HelloWorldResponse>' + @messagebody.value('/HelloWorldRequest[1]', 'nvarchar(max)') + '</HelloWorldResponse>';

			-- Send the response message back to the initiating service
			SEND ON CONVERSATION @ch MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c05/ResponseMessage] (@responsemessage);

			-- End the conversation on the target's side
			END CONVERSATION @ch;
		END

		IF (@messagetypename = 'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog')
		BEGIN
			-- End the conversation
			END CONVERSATION @ch;
		END

		COMMIT TRANSACTION
	END
GO

ALTER QUEUE TargetQueue
WITH ACTIVATION
(
	STATUS = ON,
	PROCEDURE_NAME = [ProcessRequestMessages],
	MAX_QUEUE_READERS = 5,
	EXECUTE AS SELF
)
GO

--************************************************************************
--*  Register the assembly in the database
--************************************************************************
CREATE ASSEMBLY [BackendServiceAssembly]
FROM 'J:\Pro SQL 2008 Service Broker\Chapter 5\Samples\ManagedServiceBroker\BackendService\bin\Debug\BackendService.dll'
GO

-- Add the debug information about the assembly
ALTER ASSEMBLY [BackendServiceAssembly]
ADD FILE FROM 'J:\Pro SQL 2008 Service Broker\Chapter 5\Samples\ManagedServiceBroker\BackendService\bin\Debug\BackendService.pdb'
GO

--************************************************************************
--*  Register the stored procedure written in managed code
--************************************************************************
CREATE PROCEDURE ProcessRequestMessagesManaged
AS
EXTERNAL NAME [BackendServiceAssembly].[BackendService.TargetService].ServiceProcedure
GO

--************************************************************************
--*  Use the managed stored procedure for activation
--************************************************************************
ALTER QUEUE TargetQueue
WITH ACTIVATION
(
	STATUS = ON,
	PROCEDURE_NAME = [ProcessRequestMessagesManaged],
	MAX_QUEUE_READERS = 5,
	EXECUTE AS SELF
)
GO

--************************************************************************
--*  View the assembly from the sys.assemblies catalog view
--************************************************************************
SELECT * FROM sys.assemblies
GO

--************************************************************************
--*  Register the assembly in the database
--************************************************************************
CREATE ASSEMBLY [InitiatorServiceAssembly]
FROM 'J:\Pro SQL 2008 Service Broker\Chapter 5\Samples\ManagedServiceBroker\InitiatorService\bin\Debug\InitiatorService.dll'
GO

-- Add the debug information about the assembly
ALTER ASSEMBLY [InitiatorServiceAssembly]
ADD FILE FROM 'J:\Pro SQL 2008 Service Broker\Chapter 5\Samples\ManagedServiceBroker\InitiatorService\bin\Debug\InitiatorService.pdb'
GO

--************************************************************************
--*  Register the stored procedure written in managed code
--************************************************************************
CREATE PROCEDURE ProcessResponseMessagesManaged
AS
EXTERNAL NAME [InitiatorServiceAssembly].[InitiatorService.InitiatorService].ServiceProcedure
GO

--************************************************************************
--*  Use the managed stored procedure for activation
--************************************************************************
ALTER QUEUE InitiatorQueue
WITH ACTIVATION
(
	STATUS = ON,
	PROCEDURE_NAME = [ProcessResponseMessagesManaged],
	MAX_QUEUE_READERS = 5,
	EXECUTE AS SELF
)
GO


select cast(message_body as xml), * from targetqueue

select cast(message_body as xml), * from initiatorqueue

select * from targetqueue

receive * from targetqueue

select * from sys.conversation_endpoints