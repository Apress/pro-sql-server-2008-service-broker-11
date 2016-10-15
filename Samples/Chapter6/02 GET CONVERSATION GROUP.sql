USE master;

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'Chapter6_ConversationGroups')
BEGIN
	PRINT 'Dropping database ''Chapter6_ConversationGroups''';
	DROP DATABASE Chapter6_ConversationGroups;
END
GO

CREATE DATABASE Chapter6_ConversationGroups
GO

USE Chapter6_ConversationGroups
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

--**********************************************************************
--*  Create a new conversation and implicitly a new conversation group 
--**********************************************************************
DECLARE @ch UNIQUEIDENTIFIER

BEGIN DIALOG CONVERSATION @ch
	FROM SERVICE [InitiatorService]
	TO SERVICE 'TargetService'
	WITH ENCRYPTION = OFF;

SEND ON CONVERSATION @ch (CAST('<Request></Request>' AS XML));
GO

--**********************************************************************
--*  Retrieve the sent message through GET CONVERSATION GROUP
--**********************************************************************
DECLARE @conversationGroup UNIQUEIDENTIFIER;
DECLARE @messageTypeName NVARCHAR(256);
DECLARE @messageBody XML;

WAITFOR (
	GET CONVERSATION GROUP @conversationGroup FROM TargetQueue
), TIMEOUT 1000

IF (@conversationGroup IS NOT NULL)
BEGIN
	RECEIVE TOP (1)
		@messageTypeName = message_type_name,
		@messageBody = CAST(message_body AS XML)
	FROM TargetQueue
	WHERE conversation_group_id = @conversationGroup;

	PRINT 'Message body: ' + CAST(@messageBody AS NVARCHAR(MAX));
END
GO