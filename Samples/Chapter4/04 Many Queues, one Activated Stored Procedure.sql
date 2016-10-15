USE master;

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'Chapter4_ManyQueuesOneStoredProcedure')
BEGIN
	PRINT 'Dropping database ''Chapter4_ManyQueuesOneStoredProcedure''';
	DROP DATABASE Chapter4_ManyQueuesOneStoredProcedure;
END
GO

CREATE DATABASE Chapter4_ManyQueuesOneStoredProcedure
GO

USE Chapter4_ManyQueuesOneStoredProcedure
GO

ALTER DATABASE Chapter4_ManyQueuesOneStoredProcedure
	SET TRUSTWORTHY ON

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

--************************************************************************
--*  A stored procedure used for internal activation on the target queue
--************************************************************************
CREATE PROCEDURE ProcessRequestMessages
AS
	DECLARE @ch UNIQUEIDENTIFIER -- conversation handle
	DECLARE @messagetypename NVARCHAR(256)
	DECLARE	@messagebody XML
	DECLARE @responsemessage XML
	DECLARE @queue_id INT
	DECLARE @queue_name NVARCHAR(MAX)
	DECLARE	@sql NVARCHAR(MAX)
	DECLARE @param_def NVARCHAR(MAX);

	-- Determining the queue for that the stored procedure was activated
	SELECT @queue_id = queue_id FROM sys.dm_broker_activated_tasks
	WHERE spid = @@SPID

	SELECT @queue_name = [name] FROM sys.service_queues
	WHERE object_id = @queue_id

	-- Creating the parameter substitution
	SET @param_def = '
		@ch UNIQUEIDENTIFIER OUTPUT,
		@messagetypename NVARCHAR(MAX) OUTPUT,
		@messagebody XML OUTPUT'

	-- Creating the dynamic T-SQL statement, which does a query on the actual queue
	SET @sql = '
		WAITFOR (
			RECEIVE TOP(1)
				@ch = conversation_handle,
				@messagetypename = message_type_name,
				@messagebody = CAST(message_body AS XML)
			FROM '
				+ QUOTENAME(@queue_name) + '
		), TIMEOUT 60000'

	WHILE (1=1)
	BEGIN
		BEGIN TRY
			BEGIN TRANSACTION

			-- Executing the dynamic T-SQL statement that contains the actual queue
			EXEC sp_executesql
				@sql, 
				@param_def,
				@ch = @ch OUTPUT,
				@messagetypename = @messagetypename OUTPUT,
				@messagebody = @messagebody OUTPUT

			IF (@@ROWCOUNT = 0)
			BEGIN
				ROLLBACK TRANSACTION
				BREAK
			END

			IF (@messagetypename = 'http://ssb.csharp.at/SSB_Book/c04/RequestMessage')
			BEGIN
				-- Construct the response message
				SET @responsemessage = '<HelloWorldResponse>' + @messagebody.value('/HelloWorldRequest[1]', 'nvarchar(max)') +', ' + @queue_name + '</HelloWorldResponse>';

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
--*  Create the queue "InitiatorQueue" 
--********************************************************
CREATE QUEUE InitiatorQueue
WITH STATUS = ON
GO

--********************************************************
--*  Create the queues "TargetQueue1" - "TargetQueue5"
--********************************************************
CREATE QUEUE TargetQueue1
WITH ACTIVATION
(
	STATUS = ON,
	PROCEDURE_NAME = [ProcessRequestMessages],
	MAX_QUEUE_READERS = 5,
	EXECUTE AS SELF
)
GO

CREATE QUEUE TargetQueue2
WITH ACTIVATION
(
	STATUS = ON,
	PROCEDURE_NAME = [ProcessRequestMessages],
	MAX_QUEUE_READERS = 5,
	EXECUTE AS SELF
)
GO

CREATE QUEUE TargetQueue3
WITH ACTIVATION
(
	STATUS = ON,
	PROCEDURE_NAME = [ProcessRequestMessages],
	MAX_QUEUE_READERS = 5,
	EXECUTE AS SELF
)
GO

CREATE QUEUE TargetQueue4
WITH ACTIVATION
(
	STATUS = ON,
	PROCEDURE_NAME = [ProcessRequestMessages],
	MAX_QUEUE_READERS = 5,
	EXECUTE AS SELF
)
GO

CREATE QUEUE TargetQueue5
WITH ACTIVATION
(
	STATUS = ON,
	PROCEDURE_NAME = [ProcessRequestMessages],
	MAX_QUEUE_READERS = 5,
	EXECUTE AS SELF
)
GO

--***********************************************************
--*  Create the service "InitiatorService"
--***********************************************************
CREATE SERVICE InitiatorService
ON QUEUE InitiatorQueue 
(
	[http://ssb.csharp.at/SSB_Book/c04/HelloWorldContract]
)
GO

--***********************************************************
--*  Create the service "TargetService1" - "TargetService5"
--***********************************************************
CREATE SERVICE TargetService1
ON QUEUE TargetQueue1
(
	[http://ssb.csharp.at/SSB_Book/c04/HelloWorldContract]
)
GO

CREATE SERVICE TargetService2
ON QUEUE TargetQueue2
(
	[http://ssb.csharp.at/SSB_Book/c04/HelloWorldContract]
)
GO

CREATE SERVICE TargetService3
ON QUEUE TargetQueue3
(
	[http://ssb.csharp.at/SSB_Book/c04/HelloWorldContract]
)
GO

CREATE SERVICE TargetService4
ON QUEUE TargetQueue4
(
	[http://ssb.csharp.at/SSB_Book/c04/HelloWorldContract]
)
GO

CREATE SERVICE TargetService5
ON QUEUE TargetQueue5
(
	[http://ssb.csharp.at/SSB_Book/c04/HelloWorldContract]
)
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
		ON CONTRACT [http://ssb.csharp.at/SSB_Book/c04/HelloWorldContract]
		WITH ENCRYPTION = OFF;

	SET @msg = 
		'<HelloWorldRequest>
				Klaus Aschenbrenner
		</HelloWorldRequest>';

	SEND ON CONVERSATION @ch MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c04/RequestMessage] (@msg);
COMMIT;
GO