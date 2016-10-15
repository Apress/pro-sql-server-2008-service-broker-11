USE master;

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'Chapter6_TransactionManagement')
BEGIN
	PRINT 'Dropping database ''Chapter6_TransactionManagement''';
	DROP DATABASE Chapter6_TransactionManagement;
END
GO

CREATE DATABASE Chapter6_TransactionManagement
GO

USE Chapter6_TransactionManagement
GO

--*****************************
--*  Create the needed queues
--*****************************
CREATE QUEUE InitiatorQueue
GO

CREATE QUEUE TargetQueue
GO

--*******************************
--*  Create the needed services
--*******************************
CREATE SERVICE InitiatorService
ON QUEUE InitiatorQueue
GO

CREATE SERVICE TargetService	
ON QUEUE TargetQueue ([DEFAULT])
GO

--*********************************************************
--*  Create the stored procedure that pre-loads the queue
--*********************************************************
CREATE PROCEDURE PreloadQueue
	@ConversationCount INT,
	@MessagesPerConversation INT,
	@Payload VARBINARY(MAX)
AS
BEGIN
	DECLARE @batchCount INT;
	DECLARE @ch UNIQUEIDENTIFIER;
	SELECT @batchCount = 0;

	BEGIN TRANSACTION
	WHILE (@ConversationCount > 0)
	BEGIN
		BEGIN DIALOG CONVERSATION @ch
			FROM SERVICE [InitiatorService]
			TO SERVICE 'TargetService'
			WITH ENCRYPTION = OFF;
  
		DECLARE @messageCount INT;
		SELECT @messageCount = 0;

		WHILE (@messageCount < @messagesPerConversation)
		BEGIN
			SEND ON CONVERSATION @ch (@Payload);

			SELECT @messageCount = @messageCount + 1, @batchCount = @batchCount + 1;

			IF (@batchCount >= 100)
			BEGIN
				COMMIT;
				SELECT @batchCount = 0;
				BEGIN TRANSACTION;
			END
		END

		SELECT @ConversationCount = @ConversationCount  - 1
	END

	COMMIT;
END
GO

--**********************************************************
--*  Create a stored procedure, that does a basic receive
--**********************************************************
CREATE PROCEDURE [BasicReceive]
AS
BEGIN
   DECLARE @ch UNIQUEIDENTIFIER
   DECLARE @messagetypename NVARCHAR(256)
   DECLARE @messagebody XML

   WHILE (1=1)
   BEGIN
      BEGIN TRANSACTION

      WAITFOR (
         RECEIVE TOP (1)
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

      IF (@messagetypename = 'DEFAULT')
      BEGIN
         SEND ON CONVERSATION @ch (@messagebody);

         END CONVERSATION @ch;
      END

      IF (@messagetypename = 'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog')
      BEGIN
         -- End the conversation
         END CONVERSATION @ch;
      END

      COMMIT TRANSACTION
   END
END
GO

--*********************************************************
--*  Pre-load the queue and make performance measurements
--*********************************************************
DECLARE @payload VARBINARY(MAX);
SELECT @payload = CAST(N'<PerformanceMeasurements />' AS VARBINARY(MAX));
EXEC PreloadQueue 100, 100, @payload;
GO

DECLARE @messageCount FLOAT;
DECLARE @startTime DATETIME;
DECLARE @endTime DATETIME;

SELECT @messageCount = COUNT(*) FROM [TargetQueue];
SELECT @startTime = GETDATE();

EXEC BasicReceive;

SELECT @endTime = GETDATE();

SELECT 
	@startTime AS [Start],
	@endTime AS [End],
	@messageCount AS [Count],
	DATEDIFF(second, @startTime, @endTime) AS [Duration],
	@messageCount / DATEDIFF(millisecond, @startTime, @endTime) * 1000 AS [Rate];
GO

--****************************************************************
--*  Create a stored procedure, that commits messages in barches
--****************************************************************
CREATE PROCEDURE [BatchedReceive]
AS
BEGIN
	DECLARE @ch UNIQUEIDENTIFIER;
	DECLARE @messageTypeName SYSNAME;
	DECLARE @messageBody VARBINARY(MAX);
	DECLARE @batchCount INT;
	SELECT @batchCount = 0;
	
	BEGIN TRANSACTION;
	WHILE (1=1)
	BEGIN
		WAITFOR (
			RECEIVE TOP (1)
				@ch = conversation_handle,
				@messageTypeName = message_type_name,
				@messageBody = message_body
			FROM TargetQueue
		), TIMEOUT 1000;

		IF (@@ROWCOUNT = 0)
		BEGIN
			ROLLBACK;
			BREAK;
		END

		IF (@messageTypeName = 'DEFAULT')
		BEGIN
			SEND ON CONVERSATION @ch (@messageBody);
		END
		
		IF (@messagetypename = 'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog')
		BEGIN
			-- End the conversation
			END CONVERSATION @ch;
		END

		SELECT @batchCount = @batchCount + 1
		IF (@batchCount >= 100)
		BEGIN
			COMMIT;
			SELECT @batchCount = 0;
			BEGIN TRANSACTION;
		END
	END

	COMMIT;
END
GO

--*********************************************************
--*  Pre-load the queue and make performance measurements
--*********************************************************
DECLARE @payload VARBINARY(MAX);
SELECT @payload = CAST(N'<PerformanceMeasurements />' AS VARBINARY(MAX));
EXEC PreloadQueue 100, 100, @payload;
GO

DECLARE @messageCount FLOAT;
DECLARE @startTime DATETIME;
DECLARE @endTime DATETIME;

SELECT @messageCount = COUNT(*) FROM [TargetQueue];
SELECT @startTime = GETDATE();

EXEC BatchedReceive;

SELECT @endTime = GETDATE();

SELECT 
	@startTime AS [Start],
	@endTime AS [End],
	@messageCount AS [Count],
	DATEDIFF(second, @startTime, @endTime) AS [Duration],
	@messageCount / DATEDIFF(millisecond, @startTime, @endTime) * 1000 AS [Rate];
GO

--*****************************************************************************
--*  Create a stored procedure, that uses cursors for the message processing
--*****************************************************************************
CREATE PROCEDURE CursorReceive
AS
BEGIN
	DECLARE @tableMessages TABLE
	(
		queuing_order BIGINT,
		conversation_handle UNIQUEIDENTIFIER,
		message_type_name SYSNAME,
		message_body VARBINARY(MAX)
	);

	DECLARE cursorMessages
		CURSOR FORWARD_ONLY READ_ONLY
		FOR SELECT
			queuing_order,
			conversation_handle,
			message_type_name,
			message_body
		FROM @tableMessages
		ORDER BY queuing_order;

	DECLARE	@ch UNIQUEIDENTIFIER;
	DECLARE @messageTypeName SYSNAME;
	DECLARE @payload VARBINARY(MAX);
	DECLARE @order BIGINT;

	WHILE (1 = 1)
	BEGIN
		BEGIN TRANSACTION;

		WAITFOR (
			RECEIVE 
				queuing_order,
				conversation_handle,
				message_type_name,
				message_body
			FROM [TargetQueue] INTO @tableMessages
		), TIMEOUT 1000
		
		IF (@@ROWCOUNT = 0)
		BEGIN
			ROLLBACK;
			BREAK;
		END

		OPEN cursorMessages;

		WHILE (1 = 1)
		BEGIN
			FETCH NEXT FROM cursorMessages
				INTO @order, @ch, @messageTypeName, @payload;

			IF (@@FETCH_STATUS != 0)
				BREAK;

			IF (@messageTypeName = 'DEFAULT')
			BEGIN
				SEND ON CONVERSATION @ch (@payload);
			END
			
			IF (@messagetypename = 'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog')
			BEGIN
				-- End the conversation
				END CONVERSATION @ch;
			END
		END

		CLOSE cursorMessages;
		DELETE FROM @tableMessages;
		COMMIT;
	END

	DEALLOCATE cursorMessages;
END
GO

--*********************************************************
--*  Pre-load the queue and make performance measurements
--*********************************************************
DECLARE @payload VARBINARY(MAX);
SELECT @payload = CAST(N'<PerformanceMeasurements />' AS VARBINARY(MAX));
EXEC PreloadQueue 100, 100, @payload;
GO

DECLARE @messageCount FLOAT;
DECLARE @startTime DATETIME;
DECLARE @endTime DATETIME;

SELECT @messageCount = COUNT(*) FROM [TargetQueue];
SELECT @startTime = GETDATE();

EXEC CursorReceive;

SELECT @endTime = GETDATE();

SELECT 
	@startTime AS [Start],
	@endTime AS [End],
	@messageCount AS [Count],
	DATEDIFF(second, @startTime, @endTime) AS [Duration],
	@messageCount / DATEDIFF(millisecond, @startTime, @endTime) * 1000 AS [Rate];
GO

--*****************************************************************
--*  Create the auditing infrastructure (table & stored procedure)
--*****************************************************************
CREATE TABLE AuditingTrail
(
	Id INT NOT NULL IDENTITY(1, 1),
	Date DATETIME,
	Payload NVARCHAR(MAX),
	[User] NVARCHAR(256),
	OriginalXML XML
)
GO

CREATE PROCEDURE RowsetReceive
AS
BEGIN
	DECLARE @tableMessages TABLE
	(
		queuing_order BIGINT,
		conversation_handle UNIQUEIDENTIFIER,
		message_type_name SYSNAME,
		payload XML
	);

	WHILE (1 = 1)
	BEGIN
		BEGIN TRANSACTION;

		WAITFOR (
			RECEIVE
				queuing_order,
				conversation_handle,
				message_type_name,
				CAST(message_body AS XML) AS payload
			FROM [TargetQueue] INTO @tableMessages
		), TIMEOUT 1000;

		IF (@@ROWCOUNT = 0)
		BEGIN
			COMMIT;
			BREAK;
		END

		-- Shredding the received XML message into the auditing table
		;WITH XMLNAMESPACES (DEFAULT 'http://ssb.csharp.at/SSB_Book/c06/Datagram')
		INSERT INTO AuditingTrail
		(
			Date,
			Payload,
			[User],
			OriginalXML
		)
		SELECT
			payload.value('(/Datagram/@date-time)[1]', 'DATETIME'),
			payload.value('(/Datagram/@payload)[1]', 'NVARCHAR(MAX)'),
			payload.value('(/Datagram/@user)[1]', 'NVARCHAR(256)'),
			payload
		FROM @tableMessages
		WHERE message_type_name = 'DEFAULT'
		ORDER BY queuing_order;

		COMMIT;

		DELETE FROM @tableMessages;
	END
END
GO

--*********************************************************
--*  Pre-load the queue and make performance measurements
--*********************************************************
DECLARE @xmlPayload XML;
DECLARE @payload VARBINARY(MAX);

;WITH XMLNAMESPACES (DEFAULT 'http://ssb.csharp.at/SSB_Book/c06/Datagram')
SELECT @xmlPayload = (SELECT 
	GETDATE() AS [@date-time],
	SUSER_SNAME() AS [@user],
	'Some auditing data' AS [@payload]
FOR XML PATH('Datagram'), TYPE);

SELECT @payload = CAST(@xmlPayload AS VARBINARY(MAX));
EXEC PreloadQueue 100, 100, @payload;
GO

DECLARE @messageCount FLOAT;
DECLARE @startTime DATETIME;
DECLARE @endTime DATETIME;

SELECT @messageCount = COUNT(*) FROM [TargetQueue];
SELECT @startTime = GETDATE();

EXEC RowsetReceive;

SELECT @endTime = GETDATE();

SELECT 
	@startTime AS [Start],
	@endTime AS [End],
	@messageCount AS [Count],
	DATEDIFF(second, @startTime, @endTime) AS [Duration],
	@messageCount / DATEDIFF(millisecond, @startTime, @endTime) * 1000 AS [Rate];
GO

--*****************************************************************
--*  Stored functions to marshal and un-marshal binary data
--*****************************************************************
CREATE FUNCTION BinaryMarshalPayload
(
	@DateTime DATETIME,
	@Payload VARBINARY(MAX),
	@User NVARCHAR(256)
)
RETURNS VARBINARY(MAX)
AS
BEGIN
	DECLARE @marshaledPayload VARBINARY(MAX);
	DECLARE @payloadLength BIGINT;
	DECLARE @userLength INT;
	
	SELECT @payloadLength = LEN(@Payload);
	SELECT @userLength = LEN(@User) * 2;

	SELECT @marshaledPayload = 
		CAST(@DateTime AS VARBINARY(MAX)) + 
		CAST(@payloadLength AS VARBINARY(MAX)) + 
		@payload + 
		CAST(@userLength AS VARBINARY(MAX)) + 
		CAST(@User AS VARBINARY(MAX));

	RETURN @marshaledPayload;
END
GO

CREATE FUNCTION BinaryUnmarshalPayload
(
	@MessageBody VARBINARY(MAX)
)
RETURNS @UnmarshaledBody TABLE
(
	[DateTime] DATETIME,
	[Payload] VARBINARY(MAX),
	[User] NVARCHAR(256)
)
AS
BEGIN
	DECLARE @dateTime DATETIME;
	DECLARE @user NVARCHAR(256);
	DECLARE @userLength INT;
	DECLARE @payload VARBINARY(MAX);
	DECLARE @payloadLength BIGINT;
	
	SELECT @dateTime = CAST(SUBSTRING(@MessageBody, 1, 8) AS DATETIME);
	SELECT @payloadLength = CAST(SUBSTRING(@MessageBody, 9, 8) AS BIGINT);
	SELECT @payload = SUBSTRING(@MessageBody, 17, @payloadLength);
	SELECT @userLength = CAST(SUBSTRING(@MessageBody, @payloadLength + 17, 4) AS INT);
	SELECT @user = CAST(SUBSTRING(@MessageBody, @payloadLength + 21, @userLength) AS NVARCHAR(256));

	INSERT INTO @UnmarshaledBody
		VALUES (@datetime, @payload, @user);

	RETURN;
END
GO

--******************************************************************************
--*  Create a table that stores the retrieved information
--******************************************************************************
CREATE TABLE PayloadData
(
	[Id] INT NOT NULL IDENTITY(1, 1),
	[DateTime] DATETIME,
	[Payload] NVARCHAR(MAX),
	[User] NVARCHAR(256)
)
GO

--******************************************************************************
--*  Stored procedure that retrieves the marshaled message and un-marshales it
--******************************************************************************
CREATE PROCEDURE RowsetBinaryDatagram
AS
BEGIN
	DECLARE @tableMessages TABLE
	(
		queuing_order BIGINT,
		conversation_handle UNIQUEIDENTIFIER,
		message_type_name SYSNAME,
		message_body VARBINARY(MAX)
	);

	WHILE (1 = 1)
	BEGIN
		BEGIN TRANSACTION;

		WAITFOR (
			RECEIVE
				queuing_order,
				conversation_handle,
				message_type_name,
				message_body
			FROM TargetQueue INTO @tableMessages
		), TIMEOUT 1000;

		IF (@@ROWCOUNT = 0)
		BEGIN
			COMMIT;
			BREAK;
		END

		INSERT INTO PayloadData ([DateTime], [Payload], [User])
		SELECT [DateTime], [Payload], [User] FROM @tableMessages
			CROSS APPLY BinaryUnmarshalPayload(message_body)
		WHERE message_type_name = 'DEFAULT';

		COMMIT;

		DELETE FROM @tableMessages;
	END
END
GO

--*********************************************************
--*  Pre-load the queue and make performance measurements
--*********************************************************
DECLARE @marshaledPayload VARBINARY(MAX);
SET @marshaledPayload = dbo.BinaryMarshalPayload(GETDATE(), CAST('Some auditing data' AS VARBINARY(MAX)), SUSER_SNAME());

EXEC PreloadQueue 100, 100, @marshaledPayload;
GO

DECLARE @messageCount FLOAT;
DECLARE @startTime DATETIME;
DECLARE @endTime DATETIME;

SELECT @messageCount = COUNT(*) FROM [TargetQueue];
SELECT @startTime = GETDATE();

EXEC RowsetBinaryDatagram;

SELECT @endTime = GETDATE();

SELECT 
	@startTime AS [Start],
	@endTime AS [End],
	@messageCount AS [Count],
	DATEDIFF(second, @startTime, @endTime) AS [Duration],
	@messageCount / DATEDIFF(millisecond, @startTime, @endTime) * 1000 AS [Rate];
GO