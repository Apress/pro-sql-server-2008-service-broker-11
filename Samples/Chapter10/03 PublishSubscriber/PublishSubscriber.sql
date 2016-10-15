USE master;

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'Chapter10_PublishSubscribe')
BEGIN
	PRINT 'Dropping database ''Chapter10_PublishSubscribe''';
	DROP DATABASE Chapter10_PublishSubscribe;
END
GO

CREATE DATABASE Chapter10_PublishSubscribe
GO

USE Chapter10_PublishSubscribe
GO

--***********************************************************************
--*  Create the needed message types for the Publish/Subscribe scenario
--***********************************************************************
CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c10/PublishMessage] VALIDATION = WELL_FORMED_XML;
GO

CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c10/ArticleMessage] VALIDATION = NONE;
GO

CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c10/SubscribeMessage] VALIDATION = WELL_FORMED_XML;
GO

--*******************************************************************
--*  Create the needed contracts for the Publish/Subscribe scenario
--*******************************************************************
CREATE CONTRACT [http://ssb.csharp.at/SSB_Book/c10/PublishContract]
(
	[http://ssb.csharp.at/SSB_Book/c10/PublishMessage] SENT BY INITIATOR,
	[http://ssb.csharp.at/SSB_Book/c10/ArticleMessage] SENT BY INITIATOR
)
GO

CREATE CONTRACT [http://ssb.csharp.at/SSB_Book/c10/SubscribeContract]
(
	[http://ssb.csharp.at/SSB_Book/c10/SubscribeMessage] SENT BY INITIATOR,
	[http://ssb.csharp.at/SSB_Book/c10/ArticleMessage] SENT BY TARGET
)
GO

--***************************************
--*  Create the queue for the publisher
--***************************************
CREATE QUEUE [PublisherQueue]
GO

--*****************************************
--*  Create the service for the publisher
--*****************************************
CREATE SERVICE [PublisherService] ON QUEUE [PublisherQueue]
(
	[http://ssb.csharp.at/SSB_Book/c10/PublishContract], 
	[http://ssb.csharp.at/SSB_Book/c10/SubscribeContract]
)
GO

--*******************************************************
--*  Create the queues and services for the subscribers
--*******************************************************
CREATE QUEUE SubscriberQueue1;
GO

CREATE SERVICE SubscriberService1 ON QUEUE SubscriberQueue1;
GO

CREATE QUEUE SubscriberQueue2;
GO

CREATE SERVICE SubscriberService2 ON QUEUE SubscriberQueue2;
GO

--******************************************************************
--*  Create the queues and services for the author of publications
--******************************************************************
CREATE QUEUE AuthorQueue;
GO

CREATE SERVICE AuthorService ON QUEUE AuthorQueue;
GO

--**************************************************
--*  Create the table that stores the publications
--**************************************************
CREATE TABLE Publications
(
	Publication UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
	Subject NVARCHAR(MAX) NOT NULL,
	OriginalXml XML NOT NULL
)
GO

--***************************************************
--*  Create the table that stores the subscriptions
--***************************************************
CREATE TABLE Subscriptions
(
	Subscriber UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
	Subject NVARCHAR(MAX) NOT NULL,
	OriginalXml XML NOT NULL
)
GO

--***********************************************
--*  This stored procedure subscribes a subject
--***********************************************
CREATE PROCEDURE sp_SubscribeSubject
	@Subscriber UNIQUEIDENTIFIER,
	@Subject NVARCHAR(MAX),
	@OriginalXml XML
AS
BEGIN
	INSERT INTO Subscriptions (Subscriber, Subject, OriginalXml)
	VALUES
	(
		@Subscriber, 
		@Subject, 
		@OriginalXml
	)
END
GO

--**************************************************
--*  This stored procedure publishes a publication
--**************************************************
CREATE PROCEDURE sp_PublishPublication
	@Publication UNIQUEIDENTIFIER,
	@Subject NVARCHAR(MAX),
	@OriginalXml XML
AS
BEGIN
	INSERT INTO Publications (Publication, Subject, OriginalXml)
	VALUES
	(
		@Publication, 
		@Subject, 
		@OriginalXml
	)
END
GO

--************************************************
--*  This stored procedure removes a publication
--************************************************
CREATE PROCEDURE sp_RemovePublication
	@Publication UNIQUEIDENTIFIER
AS
BEGIN
	DELETE FROM Publications
	WHERE Publication = @Publication
END
GO

--*************************************************
--*  This stored procedure removes a subscription
--*************************************************
CREATE PROCEDURE sp_RemoveSubscriber
	@Subscriber UNIQUEIDENTIFIER
AS
BEGIN
	DELETE FROM Subscriptions
	WHERE Subscriber = @Subscriber
END
GO

--**********************************************************************************************************
--*  This stored procedure processes a new received article and sends it to the subscribed subscribers
--**********************************************************************************************************
CREATE PROCEDURE sp_SendOnPublication
	@Publication UNIQUEIDENTIFIER,
	@Article VARBINARY(MAX)
AS
BEGIN
	DECLARE @Subscription UNIQUEIDENTIFIER;
	DECLARE @cursorSubscriptions CURSOR;

	SET @cursorSubscriptions = CURSOR LOCAL SCROLL FOR
		SELECT Subscriber 
		FROM Subscriptions s 
		JOIN Publications p ON s.Subject = p.Subject
		WHERE p.Publication = @Publication;

	BEGIN TRANSACTION;
	OPEN @cursorSubscriptions;

	FETCH NEXT FROM @cursorSubscriptions
	INTO @Subscription;

	WHILE (@@fetch_status = 0)
	BEGIN
		IF (@Article IS NOT NULL)
		BEGIN
			SEND ON CONVERSATION @Subscription MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c10/ArticleMessage] (@Article);
		END
		ELSE
		BEGIN
			SEND ON CONVERSATION @Subscription MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c10/ArticleMessage];
		END
		FETCH NEXT FROM @cursorSubscriptions
		INTO @Subscription;
	END

	CLOSE @cursorSubscriptions;
	DEALLOCATE @cursorSubscriptions;
	COMMIT;
END
GO

--**********************************************************
--*  This stored procedure processes a publication request
--**********************************************************
CREATE PROCEDURE sp_ProcessPublicationRequest
	@Conversation UNIQUEIDENTIFIER,
	@Message VARBINARY(MAX)
AS
BEGIN
	DECLARE @Request XML;
	DECLARE @Subject NVARCHAR(MAX);
	
	SELECT @Request = CAST(@Message AS XML);

	WITH XMLNAMESPACES (DEFAULT 'http://ssb.csharp.at/SSB_Book/c10/PublishSubscribe')
	SELECT @Subject = @Request.value(N'(//Publish/Subject)[1]', N'NVARCHAR(MAX)');

	IF (@Subject IS NOT NULL)
	BEGIN
		EXEC sp_PublishPublication @Conversation, @Subject, @Message;
	END
	ELSE
	BEGIN
		END CONVERSATION @Conversation WITH ERROR = 1 DESCRIPTION = N'The publication is missing a subject';
		EXEC sp_RemovePublication @Conversation;
	END
END
GO

--***********************************************************
--*  This stored procedure processes a subscription request
--***********************************************************
CREATE PROCEDURE sp_ProcessSubscriptionRequest
	@Conversation UNIQUEIDENTIFIER,
	@Message VARBINARY(MAX)
AS
BEGIN
	DECLARE @Request XML;
	DECLARE @Subject NVARCHAR(MAX);
	
	SELECT @Request = CAST(@Message AS XML);

	WITH XMLNAMESPACES (DEFAULT 'http://ssb.csharp.at/SSB_Book/c10/PublishSubscribe')
	SELECT @Subject = @Request.value(N'(//Request/Subject)[1]', N'NVARCHAR(MAX)');

	IF (@Subject IS NOT NULL)
	BEGIN
		EXEC sp_SubscribeSubject @Conversation, @Subject, @Request;
	END
	ELSE
	BEGIN
		END CONVERSATION @Conversation WITH ERROR = 2 DESCRIPTION = N'The subscription request is missing a subject';
		EXEC sp_RemoveSubscriber @Conversation;
	END
END
GO

--***************************************************************************
--*  This stored procedure is the service program for the publisher service
--***************************************************************************
CREATE PROCEDURE sp_PublisherService
AS
BEGIN
	DECLARE @Conversation UNIQUEIDENTIFIER;
	DECLARE @Message VARBINARY(MAX);
	DECLARE @MessageTypeName SYSNAME;

	BEGIN TRANSACTION;

	WAITFOR
	(
		RECEIVE TOP(1) 
			@Conversation = conversation_handle,
			@Message = message_body,
			@MessageTypeName = message_type_name
		FROM PublisherQueue
	), TIMEOUT 1000;

	WHILE (@Conversation IS NOT NULL)
	BEGIN
		IF (@MessageTypeName = 'http://ssb.csharp.at/SSB_Book/c10/PublishMessage')
		BEGIN
			EXEC sp_ProcessPublicationRequest @Conversation, @Message;
		END
		ELSE IF (@MessageTypeName = 'http://ssb.csharp.at/SSB_Book/c10/SubscribeMessage')
		BEGIN
			EXEC sp_ProcessSubscriptionRequest @Conversation, @Message;
		END
		ELSE IF (@MessageTypeName = 'http://ssb.csharp.at/SSB_Book/c10/ArticleMessage')
		BEGIN
			EXEC sp_SendOnPublication @Conversation, @Message;
		END
		ELSE IF (@MessageTypeName IN (
			N'http://schemas.microsoft.com/SQL/ServiceBroker/Error',
			N'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog'))
		BEGIN
			END CONVERSATION @Conversation;

			IF (EXISTS (SELECT * FROM Publications 
			WHERE Publication = @Conversation))
			BEGIN
				EXEC sp_RemovePublication @Conversation;
			END

			IF (EXISTS (SELECT * FROM Subscribers))
			BEGIN
				EXEC sp_RemoveSubscriber @Conversation;
			END
		END
		ELSE
		BEGIN
			-- Unexpected message
			RAISERROR (N'Received unexpected message type: %s', 16, 1, @MessageTypeName);
			ROLLBACK;
			RETURN;
		END
		COMMIT;
		
		SELECT @Conversation = NULL;
		BEGIN TRANSACTION;

		WAITFOR
		(
			RECEIVE TOP(1) 
				@Conversation = conversation_handle,
				@Message = message_body,
				@MessageTypeName = message_type_name
			FROM PublisherQueue
		), TIMEOUT 1000;
	END
	COMMIT;
END
GO

--**************************************************
--*  Alter the PublisherQueue queue for activation
--**************************************************
ALTER QUEUE PublisherQueue
WITH ACTIVATION
(
	STATUS = ON,
	MAX_QUEUE_READERS = 1,
	PROCEDURE_NAME = sp_PublisherService,
	EXECUTE AS SELF
)
GO

--****************************************
--*  Subscribe to the subject "Subject1"
--****************************************
DECLARE @ch UNIQUEIDENTIFIER;

BEGIN DIALOG CONVERSATION @ch
	FROM SERVICE [SubscriberService1]
	TO SERVICE 'PublisherService'
	ON CONTRACT [http://ssb.csharp.at/SSB_Book/c10/SubscribeContract]
	WITH ENCRYPTION = OFF;

SEND ON CONVERSATION @ch
MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c10/SubscribeMessage]
(
	N'<?xml version="1.0"?>
	<Request xmlns="http://ssb.csharp.at/SSB_Book/c10/PublishSubscribe">
		<Subject>Subject1</Subject>
	</Request>'
);
GO

--****************************************
--*  Subscribe to the subject "Subject2"
--****************************************
DECLARE @ch UNIQUEIDENTIFIER;

BEGIN DIALOG CONVERSATION @ch
	FROM SERVICE [SubscriberService1]
	TO SERVICE 'PublisherService'
	ON CONTRACT [http://ssb.csharp.at/SSB_Book/c10/SubscribeContract]
	WITH ENCRYPTION = OFF;

SEND ON CONVERSATION @ch
MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c10/SubscribeMessage]
(
	N'<?xml version="1.0"?>
	<Request xmlns="http://ssb.csharp.at/SSB_Book/c10/PublishSubscribe">
		<Subject>Subject2</Subject>
	</Request>'
);
GO

--***************************************************************
--*  Subscribe to the subject "Subject1" for another subscriber
--***************************************************************
DECLARE @ch UNIQUEIDENTIFIER;

BEGIN DIALOG CONVERSATION @ch
	FROM SERVICE [SubscriberService2]
	TO SERVICE 'PublisherService'
	ON CONTRACT [http://ssb.csharp.at/SSB_Book/c10/SubscribeContract]
	WITH ENCRYPTION = OFF;

SEND ON CONVERSATION @ch
MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c10/SubscribeMessage]
(
	N'<?xml version="1.0"?>
	<Request xmlns="http://ssb.csharp.at/SSB_Book/c10/PublishSubscribe">
		<Subject>Subject1</Subject>
	</Request>'
);
GO

--****************************************************
--*  Publish some articles on the subject "Subject1"
--****************************************************
DECLARE @ch UNIQUEIDENTIFIER;

BEGIN DIALOG CONVERSATION @ch
	FROM SERVICE [AuthorService]
	TO SERVICE 'PublisherService'
	ON CONTRACT [http://ssb.csharp.at/SSB_Book/c10/PublishContract]
	WITH ENCRYPTION = OFF;

SEND ON CONVERSATION @ch
MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c10/PublishMessage]
(
	N'<?xml version="1.0"?>
	<Publish xmlns="http://ssb.csharp.at/SSB_Book/c10/PublishSubscribe">
		<Subject>Subject1</Subject>
	</Publish>'
);

SEND ON CONVERSATION @ch
MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c10/ArticleMessage]
(
	N'This is an article on Subject1'
);

SEND ON CONVERSATION @ch
MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c10/ArticleMessage]
(
	N'And this is another article on Subject1'
);
GO

--*************************************
--*  View the retrieved subscriptions
--*************************************
SELECT CAST (message_body AS NVARCHAR(MAX)), * FROM SubscriberQueue1
GO
SELECT CAST (message_body AS NVARCHAR(MAX)), * FROM SubscriberQueue2
GO