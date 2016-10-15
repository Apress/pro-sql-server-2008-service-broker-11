USE master;

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'Chapter10_PriorityBasedMessaging')
BEGIN
	PRINT 'Dropping database ''Chapter10_PriorityBasedMessaging''';
	DROP DATABASE Chapter10_PriorityBasedMessaging;
END
GO

CREATE DATABASE Chapter10_PriorityBasedMessaging
GO

USE Chapter10_PriorityBasedMessaging
GO


--****************************************************
--*  Create the needed message types for this sample
--****************************************************
CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c10/LongWorkloadRequestMessageType] VALIDATION = WELL_FORMED_XML
GO

CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c10/SetPriorityMessageType] VALIDATION = WELL_FORMED_XML
GO

CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c10/LongWorkflowResponseMessageType] VALIDATION = WELL_FORMED_XML
GO

--************************************************
--*  Create the needed contracts for this sample
--************************************************
CREATE CONTRACT [http://ssb.csharp.at/SSB_Book/c10/RequestWithPriorityContract]
(
	[http://ssb.csharp.at/SSB_Book/c10/LongWorkloadRequestMessageType] SENT BY INITIATOR,
	[http://ssb.csharp.at/SSB_Book/c10/SetPriorityMessageType] SENT BY INITIATOR,
	[http://ssb.csharp.at/SSB_Book/c10/LongWorkflowResponseMessageType] SENT BY TARGET
)
GO

-- This is the contract used for the communication between the 
-- front-end service and the internal service
CREATE CONTRACT [http://ssb.csharp.at/SSB_Book/c10/RequestInternalContract]
(
	[http://ssb.csharp.at/SSB_Book/c10/LongWorkloadRequestMessageType] SENT BY INITIATOR,
	[http://ssb.csharp.at/SSB_Book/c10/LongWorkflowResponseMessageType] SENT BY TARGET
)
GO	

--******************************
--*  Create the service queues
--******************************
CREATE QUEUE FrontEndQueue
GO

CREATE QUEUE BackEndQueue
GO

--*******************************
--*  Create the services itself
--*******************************
CREATE SERVICE [FrontEndService] 
ON QUEUE [FrontEndQueue]
(
	[http://ssb.csharp.at/SSB_Book/c10/RequestWithPriorityContract]
)
GO

-- the back end service
CREATE SERVICE [BackEndService]
ON QUEUE [BackEndQueue]
(
	[http://ssb.csharp.at/SSB_Book/c10/RequestInternalContract]
)
GO

--***************************************************************************************
--*  This table links incoming request to the front end service to the back end service
--***************************************************************************************
CREATE TABLE RequestsBindings
(
	FrontendConversation UNIQUEIDENTIFIER PRIMARY KEY,
	BackendConversation UNIQUEIDENTIFIER UNIQUE
)
GO

--*********************************************************************************************
--*  This stored procedure retrieves the opposite side conversation from the bindings table.
--*  It will retrieve the frondend conversation from the backend conversation and vice versa.
--*********************************************************************************************
CREATE PROCEDURE sp_BindingGetPeer (
	@Conversation UNIQUEIDENTIFIER,
	@Peer UNIQUEIDENTIFIER OUTPUT)
AS
SET NOCOUNT ON;
SELECT @Peer = 
(
	SELECT 
		BackendConversation
		FROM RequestsBindings
		WHERE FrontendConversation = @Conversation

	UNION ALL

	SELECT FrontendConversation
		FROM RequestsBindings
		WHERE BackendConversation = @Conversation
)

IF (@@ROWCOUNT = 0)
BEGIN
	SELECT @Peer = NULL;
END
GO

--************************************************************************************************
--*  This stored procedure retrieves a backend conversation for a frondend conversation.
--*  It will initiate a new conversation with the backend service, if one doesn't already exist.
--************************************************************************************************
CREATE PROCEDURE sp_BindingGetBackend (
	@FrontendConversation UNIQUEIDENTIFIER,
	@BackendConversation UNIQUEIDENTIFIER OUTPUT)
AS
SET NOCOUNT ON;
BEGIN TRANSACTION;

SELECT @BackendConversation = BackendConversation
	FROM RequestsBindings
	WHERE FrontendConversation = @FrontendConversation;

IF (@@ROWCOUNT = 0)
BEGIN
	BEGIN DIALOG CONVERSATION @BackendConversation
		FROM SERVICE [FrontEndService]
		TO SERVICE N'BackEndService', N'current database'
		ON CONTRACT [http://ssb.csharp.at/SSB_Book/c10/RequestInternalContract]
		WITH
			RELATED_CONVERSATION = @FrontendConversation,
			ENCRYPTION = OFF;

	INSERT INTO RequestsBindings (FrontendConversation, BackendConversation)
	VALUES 
	(
		@FrontendConversation, 
		@BackendConversation
	);
END
COMMIT;
GO

--*****************************************************************
--*  This table stores the priorities of the conversation groups.
--*****************************************************************
CREATE TABLE Priority 
(
	ConversationGroup UNIQUEIDENTIFIER UNIQUE,
	Priority TINYINT,
	EnqueueTime TIMESTAMP,
	PRIMARY KEY CLUSTERED 
	(
		Priority DESC, 
		EnqueueTime ASC, 
		ConversationGroup
	)
)
GO

--****************************************************************************************
--*  This stored procedure dequeues the next conversation group from the Priority table.
--****************************************************************************************
CREATE PROCEDURE sp_DequeuePriority 
@ConversationGroup UNIQUEIDENTIFIER OUTPUT
AS
SET NOCOUNT ON;
BEGIN TRANSACTION;

SELECT @ConversationGroup = NULL;
DECLARE @cgt TABLE (ConversationGroup UNIQUEIDENTIFIER);

DELETE FROM Priority WITH (READPAST)
OUTPUT DELETED.ConversationGroup INTO @cgt
WHERE ConversationGroup = 
(
	SELECT TOP (1) ConversationGroup 
	FROM Priority WITH (READPAST) 
	ORDER BY Priority DESC, EnqueueTime ASC
)

SELECT @ConversationGroup = ConversationGroup 
FROM @cgt;

COMMIT;
GO

--*************************************************************************************
--*  This stored procedure enqueues a new conversation group into the Priority table.
--*************************************************************************************
CREATE PROCEDURE sp_EnqueuePriority
@ConversationGroup UNIQUEIDENTIFIER,
@Priority TINYINT
AS
SET NOCOUNT ON;
BEGIN TRANSACTION;

DELETE FROM Priority
WHERE ConversationGroup = @ConversationGroup;

INSERT INTO Priority (ConversationGroup, Priority)
VALUES (@ConversationGroup, @Priority);

COMMIT;
GO

--***************************************************************************
--*  This stored procedure is the service program for the frontend service.
--***************************************************************************
CREATE PROCEDURE sp_FrontendService 
AS
SET NOCOUNT ON
DECLARE @dh UNIQUEIDENTIFIER;
DECLARE @bind_dh UNIQUEIDENTIFIER;
DECLARE @message_type_name SYSNAME;
DECLARE @message_body VARBINARY(MAX);

BEGIN TRANSACTION;

WAITFOR 
(
	RECEIVE TOP (1) 
		@dh = conversation_handle,
		@message_type_name = message_type_name,
		@message_body = message_body
	FROM [FrontEndQueue]
), TIMEOUT 1000;

WHILE @dh IS NOT NULL
BEGIN
	
	IF @message_type_name = N'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog'
	BEGIN
		-- End the conversation on which the End was received,
		-- then end the conversation on the other side of the binding
		END CONVERSATION @dh;

		EXEC sp_BindingGetPeer @dh, @bind_dh OUTPUT;

		IF @bind_dh IS NOT NULL
		BEGIN
			END CONVERSATION @bind_dh;
			DELETE FROM RequestsBindings
			WHERE FrontendConversation = @dh OR BackendConversation = @dh;
		END
	END 
	ELSE IF @message_type_name = N'http://schemas.microsoft.com/SQL/ServiceBroker/Error'
	BEGIN 
		-- End the conversation on which the Error was received,
		-- then forward the error to the conversation on the other side of the binding
		END CONVERSATION @dh;

		EXEC sp_BindingGetPeer @dh, @bind_dh OUTPUT;

		IF @bind_dh IS NOT NULL
		BEGIN
			-- Extract the error code and description from the error message body
			DECLARE @error_number INT;
			DECLARE @error_description NVARCHAR(4000);
			DECLARE @error_message_body XML;

			SELECT @error_message_body = CAST(@message_body AS XML);
			WITH XMLNAMESPACES (DEFAULT 'http://schemas.microsoft.com/SQL/ServiceBroker/Error')

			SELECT @error_number  = @error_message_body.value ('(/Error/Code)[1]', 'INT'),
				@error_description = @error_message_body.value ('(/Error/Description)[1]', 'NVARCHAR(4000)');

			IF (@error_number < 0 )
			BEGIN
				SELECT @error_number = -@error_number;
			END

			END CONVERSATION @bind_dh WITH 
				ERROR = @error_number 
				DESCRIPTION = @error_description;

			DELETE FROM RequestsBindings
			WHERE FrontendConversation = @dh OR BackendConversation = @dh;
		END
	END
	ELSE IF @message_type_name = N'http://ssb.csharp.at/SSB_Book/c10/LongWorkloadRequestMessageType'
	BEGIN
		-- forward the workload request to the back end service
		EXEC sp_BindingGetBackend @dh, @bind_dh OUTPUT;

		SEND ON CONVERSATION @bind_dh MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c10/LongWorkloadRequestMessageType] (@message_body);
	END
	ELSE IF @message_type_name = N'http://ssb.csharp.at/SSB_Book/c10/SetPriorityMessageType'
	BEGIN
		-- increase the priority of this conversation
		-- we need the target side conversation group 
		-- of the back end conversation bound to @dh
		DECLARE @cg UNIQUEIDENTIFIER;

		SELECT @cg = tep.conversation_group_id
		FROM sys.conversation_endpoints tep WITH (NOLOCK)
		JOIN sys.conversation_endpoints iep WITH (NOLOCK) ON
			tep.conversation_id = iep.conversation_id
			AND tep.is_initiator = 0
			AND iep.is_initiator = 1
		JOIN RequestsBindings rb ON 
			iep.conversation_handle = rb.BackendConversation
		WHERE rb.FrontendConversation = @dh;

		IF @cg IS NOT NULL
		BEGIN 
			-- retrieve the desired priority from the message body
			DECLARE @priority TINYINT;
			SELECT @priority = cast(@message_body as XML).value (N'(/priority)[1]', N'TINYINT');

			EXEC sp_EnqueuePriority @cg, @priority;
		END
	END
	ELSE IF @message_type_name = N'http://ssb.csharp.at/SSB_Book/c10/LongWorkflowResponseMessageType'
	BEGIN
		-- forward the workload response to the front end conversation
		EXEC sp_BindingGetPeer @dh, @bind_dh OUTPUT;

		SEND ON CONVERSATION @bind_dh MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c10/LongWorkflowResponseMessageType] (@message_body);
	END

	-- commit this transaction, then loop again
	COMMIT;
	BEGIN TRANSACTION;

	SELECT @dh = NULL, @bind_dh = NULL;

	WAITFOR 
	(
		RECEIVE TOP (1) 
			@dh = conversation_handle,
			@message_type_name = message_type_name,
			@message_body = message_body
		FROM [FrontEndQueue]
	), TIMEOUT 1000;
END
COMMIT;
GO

--**********************************************************************************
--*  This stored procedure implements the service program for the backend service.
--**********************************************************************************
CREATE PROCEDURE sp_BackendService
AS
SET NOCOUNT ON
DECLARE @dh UNIQUEIDENTIFIER;
DECLARE @cg UNIQUEIDENTIFIER
DECLARE @message_type_name SYSNAME;
DECLARE @message_body VARBINARY(MAX);

BEGIN TRANSACTION;

-- dequeue o priority conversation_group,
-- or wait from an unprioritized one from the queue
EXEC sp_DequeuePriority @cg OUTPUT;

IF (@cg IS NULL)
BEGIN
	WAITFOR 
	(
		GET CONVERSATION GROUP @cg 
		FROM [BackEndQueue]
	), TIMEOUT 1000;
END

WHILE @cg IS NOT NULL
BEGIN
	-- We have a conversation group
	-- process all messages in this group
	RECEIVE TOP (1) 
		@dh = conversation_handle,
		@message_type_name = message_type_name,
		@message_body = message_body
		FROM [BackEndQueue]
		WHERE conversation_group_id = @cg;

	WHILE @dh IS NOT NULL
	BEGIN
		IF @message_type_name = N'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog'
			OR @message_type_name = N'http://schemas.microsoft.com/SQL/ServiceBroker/Error'
		BEGIN
			-- In a real app the Error message might need to be somehow handled, like logged
			END CONVERSATION @dh;
		END
		ELSE IF @message_type_name = N'http://ssb.csharp.at/SSB_Book/c10/LongWorkloadRequestMessageType'
		BEGIN
			-- simulate a really lengthy worload. sleep for 2 seconds.
			WAITFOR DELAY '00:00:02';

			-- send back the 'result' of the workload
			-- For our sample the result is simply the request wraped in <response> tag,
			-- decorated with the current time and @@spid attributes
			DECLARE @result XML;
			SELECT @result  = 
			(
				SELECT 
					@@SPID as [@spid],
					GETDATE() as [@time],
					CAST(@message_body AS XML) AS [*]
					FOR XML PATH ('result'), TYPE
			);

			SEND ON CONVERSATION @dh 
			MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c10/LongWorkflowResponseMessageType] (@result);
		END;
		-- In a real app we'd need to treat the ELSE case, when an unknown type message was received
		
		SELECT @dh = NULL;

		-- get more messages on this conversation_group
		RECEIVE TOP (1) 
			@dh = conversation_handle,
			@message_type_name = message_type_name,
			@message_body = message_body
		FROM [BackEndQueue]
		WHERE conversation_group_id = @cg;
	END
	
	-- commit this transaction, then loop again
	COMMIT;
	BEGIN TRANSACTION;
	SELECT @cg = NULL;
	EXEC sp_DequeuePriority @cg OUTPUT;

	IF @cg IS NULL
	BEGIN
		WAITFOR 
		(
			GET CONVERSATION GROUP @cg 
			FROM [BackEndQueue]
		), TIMEOUT 1000;
	END
END
COMMIT;
GO

--************************************************
--*  Configuration of Service Broker activation.
--************************************************
ALTER QUEUE [FrontEndQueue]
WITH ACTIVATION 
(
	STATUS = ON,
	MAX_QUEUE_READERS = 10,
	PROCEDURE_NAME = [sp_FrontendService],
	EXECUTE AS OWNER
)
GO

ALTER QUEUE [BackEndQueue]
WITH ACTIVATION
(
	STATUS = ON,
	MAX_QUEUE_READERS = 10,
	PROCEDURE_NAME = [sp_BackendService],
	EXECUTE AS OWNER
)
GO

--*********************************************
--*  We also need a simple initiator service.
--*********************************************
CREATE QUEUE [SampleClientQueue]
GO

CREATE SERVICE [SampleClientService] 
ON QUEUE [SampleClientQueue]
GO

--***********************************************
--*  Sending the messages with some priorities.
--***********************************************
DECLARE @dh UNIQUEIDENTIFIER;
DECLARE @i INT;
SELECT @i = 0;
WHILE @i < 100
BEGIN
	BEGIN TRANSACTION;
	BEGIN DIALOG CONVERSATION @dh
		FROM SERVICE [SampleClientService]
		TO SERVICE N'FrontEndService'
		ON CONTRACT [http://ssb.csharp.at/SSB_Book/c10/RequestWithPriorityContract]
		WITH ENCRYPTION = OFF;

	DECLARE @request XML;
	SELECT @request = 
	(
		SELECT GETDATE() AS [@time],
			@@SPID AS [@spid],
			@i 
			FOR XML PATH ('request'), TYPE
	);

	SEND ON CONVERSATION @dh 
		MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c10/LongWorkloadRequestMessageType]
		(@request);

	-- Every 10 requests ask for a priority bump
	IF (@i % 10) = 0
	BEGIN
		DECLARE @priority XML;

		SELECT @priority = 
		(
			SELECT @i 
			FOR XML PATH ('priority'), TYPE
		);

		SEND ON CONVERSATION @dh 
			MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c10/SetPriorityMessageType]
			(@priority);
	END

	COMMIT;

	SELECT @i = @i + 1;
END
GO

--***********************************
--*  Receive the response messages.
--***********************************
DECLARE @dh UNIQUEIDENTIFIER;
DECLARE @message_body NVARCHAR(4000);
BEGIN TRANSACTION

WAITFOR
(
	RECEIVE
		@dh = conversation_handle,
		@message_body = cast(message_body as NVARCHAR(4000)) 
	FROM [SampleClientQueue]
), TIMEOUT 10000;

WHILE @dh IS NOT NULL
BEGIN
	END CONVERSATION @dh;
	PRINT @message_body;
	COMMIT;

	SELECT @dh = NULL;
	BEGIN TRANSACTION;

	WAITFOR
	(
		RECEIVE
			@dh = conversation_handle,
			@message_body = cast(message_body as NVARCHAR(4000)) 
		FROM [SampleClientQueue]
	), TIMEOUT 10000;
END
COMMIT;
GO