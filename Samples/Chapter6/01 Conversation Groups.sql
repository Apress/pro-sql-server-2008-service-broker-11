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

-- Create Database Master key, so that the private key of the certificate can be encrypted
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'password1!'
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
GO

SELECT * FROM sys.conversation_groups
GO

--********************************************************************************
--*  Create the needed queues for 2 conversations in the same conversation group
--********************************************************************************
CREATE QUEUE TargetQueue1
GO

CREATE QUEUE TargetQueue2
GO

--*******************************
--*  Create the needed services
--*******************************
CREATE SERVICE TargetService1	
ON QUEUE TargetQueue1 ([DEFAULT])
GO

CREATE SERVICE TargetService2	
ON QUEUE TargetQueue2 ([DEFAULT])
GO

-- *****************************************************************************
-- * Create two conversations in the same conversation group and send messages
-- *****************************************************************************
BEGIN TRANSACTION;
DECLARE @ch1 UNIQUEIDENTIFIER;
DECLARE @ch2 UNIQUEIDENTIFIER;

BEGIN DIALOG @ch1
	FROM SERVICE [InitiatorService]
	TO SERVICE 'TargetService1'
	WITH ENCRYPTION = OFF;

BEGIN DIALOG @ch2
	FROM SERVICE [InitiatorService]
	TO SERVICE 'TargetService2'
	WITH RELATED_CONVERSATION = @ch1,
	ENCRYPTION = OFF;

SEND ON CONVERSATION @ch1 (CAST('<Request></Request>' AS XML));
SEND ON CONVERSATION @ch2 (CAST('<Request></Request>' AS XML));
COMMIT TRANSACTION
GO

-- *****************************************************************************
-- * Showing the ongoing conversations and the associated conversation groups
-- *****************************************************************************
SELECT * FROM sys.conversation_groups cg
INNER JOIN sys.services svc on cg.service_id = svc.service_id
GO

-- **********************************************************************************************************************
-- * The received messages on both queues are not in the same conversation group on the target side of the conversation
-- **********************************************************************************************************************
SELECT * FROM TargetQueue1
SELECT * FROM TargetQueue2
GO

-- *****************************************************************************
-- * Stored procedure that process messages on the queue "TargetQueue1"
-- *****************************************************************************
CREATE PROCEDURE ProcessTargetQueue1
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
			TargetQueue1
	  ), TIMEOUT 1000

	  IF (@@ROWCOUNT = 0)
	  BEGIN
		 ROLLBACK TRANSACTION
		 BREAK
	  END

	  IF (@messagetypename = 'DEFAULT')
	  BEGIN
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

-- *****************************************************************************
-- * Stored procedure that process messages on the queue "TargetQueue2"
-- *****************************************************************************
CREATE PROCEDURE ProcessTargetQueue2
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
			TargetQueue2
	  ), TIMEOUT 1000

	  IF (@@ROWCOUNT = 0)
	  BEGIN
		 ROLLBACK TRANSACTION
		 BREAK
	  END

	  IF (@messagetypename = 'DEFAULT')
	  BEGIN
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

-- ***********************************************
-- * Select the messages from both target queues
-- ***********************************************
SELECT * FROM TargetQueue1
SELECT * FROM TargetQueue2
GO

-- *******************************************************
-- * Process the received messages on both target queues
-- *******************************************************
EXEC ProcessTargetQueue1
EXEC ProcessTargetQueue2
GO

-- *********************************************************
-- * Select the response messages on the initiator's queue
-- *********************************************************
SELECT * from InitiatorQueue
GO

-- *********************************************************
-- * Select the conversation group
-- *********************************************************
SELECT * FROM sys.conversation_groups cg
INNER JOIN sys.services svc on cg.service_id = svc.service_id
GO

-- ************************************************************************************
-- * Execute the following T-SQL batch in connection #1, without the COMMIT statement
-- ************************************************************************************
BEGIN TRANSACTION;
	RECEIVE TOP (1) * FROM InitiatorQueue

COMMIT TRANSACTION
GO

-- *****************************************************
-- * Execute the following T-SQL batch in connection #2
-- *****************************************************
BEGIN TRANSACTION;
	RECEIVE TOP (1) * FROM InitiatorQueue

COMMIT TRANSACTION
GO