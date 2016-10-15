USE master;

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'Chapter4_ParallelActivation')
BEGIN
	PRINT 'Dropping database ''Chapter4_ParallelActivation''';
	DROP DATABASE Chapter4_ParallelActivation;
END
GO

CREATE DATABASE Chapter4_ParallelActivation
GO

USE Chapter4_ParallelActivation
GO

--*********************************************
--*  Create the target service
--*********************************************
CREATE QUEUE [TargetQueue]
GO

CREATE SERVICE [TargetService]
ON QUEUE [TargetQueue]
(
	[DEFAULT]
)
GO

--*********************************************************
--*  Create the queues needed for the external activation
--*********************************************************
CREATE QUEUE [ActivatorQueue_1];
CREATE QUEUE [ActivatorQueue_2];
CREATE QUEUE [ActivatorQueue_3];
CREATE QUEUE [ActivatorQueue_4];
CREATE QUEUE [ActivatorQueue_5];
GO

--****************************************************
--*  Create the services for the external activation
--****************************************************
CREATE SERVICE [ActivatorService_1]
ON QUEUE [ActivatorQueue_1]
(
	[http://schemas.microsoft.com/SQL/Notifications/PostEventNotification]
)
GO

CREATE SERVICE [ActivatorService_2]
ON QUEUE [ActivatorQueue_2]
(
	[http://schemas.microsoft.com/SQL/Notifications/PostEventNotification]
)
GO

CREATE SERVICE [ActivatorService_3]
ON QUEUE [ActivatorQueue_3]
(
	[http://schemas.microsoft.com/SQL/Notifications/PostEventNotification]
)
GO

CREATE SERVICE [ActivatorService_4]
ON QUEUE [ActivatorQueue_4]
(
	[http://schemas.microsoft.com/SQL/Notifications/PostEventNotification]
)
GO

CREATE SERVICE [ActivatorService_5]
ON QUEUE [ActivatorQueue_5]
(
	[http://schemas.microsoft.com/SQL/Notifications/PostEventNotification]
)
GO

--*********************************************
--*  Create the needed service program
--*********************************************
CREATE PROCEDURE [ApplicationServiceProgram_1]
AS
BEGIN
	DECLARE @conversationHandle UNIQUEIDENTIFIER;
	DECLARE @messageTypeName SYSNAME;
	DECLARE @notification XML;
	DECLARE @applicationMessage VARBINARY(MAX);

	BEGIN TRY
		BEGIN TRANSACTION;

		RECEIVE TOP (1)
			@conversationHandle = conversation_handle,
			@messageTypeName = message_type_name,
			@notification = CAST(message_body AS XML)
		FROM [ActivatorQueue_1];

		IF (@messageTypeName = 'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog')
		BEGIN
			END CONVERSATION @conversationHandle;
		END

		IF (@messageTypeName = 'http://schemas.microsoft.com/SQL/ServiceBroker/Error')
		BEGIN
			END CONVERSATION @conversationHandle;
		END

		WHILE (1 = 1)
		BEGIN
			WAITFOR (
				RECEIVE
					@conversationHandle = conversation_handle,
					@messageTypeName = message_type_name,
					@applicationMessage = message_body
				FROM [TargetQueue]
			), TIMEOUT 1000;

			IF (@@ROWCOUNT = 0)
			BEGIN
				-- Do not rollback here!
				BREAK;
			END

			IF (@messageTypeName = 'http://schemas.microsoft.com/SQL/ServiceBroker/Error')
			BEGIN
				END CONVERSATION @conversationHandle;
			END

			IF (@messageTypeName = 'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog')
			BEGIN
				END CONVERSATION @conversationHandle;
			END

			IF (@messageTypeName = 'DEFAULT')
			BEGIN
				-- Here's the place where you implement your application logic
				SEND ON CONVERSATION @conversationHandle (@applicationMessage);
				END CONVERSATION @conversationHandle;
			END

			COMMIT TRANSACTION;
			BEGIN TRANSACTION;
		END

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
	END CATCH
END
GO

--*********************************************
--*  Create the needed service program
--*********************************************
CREATE PROCEDURE [ApplicationServiceProgram_2]
AS
BEGIN
	DECLARE @conversationHandle UNIQUEIDENTIFIER;
	DECLARE @messageTypeName SYSNAME;
	DECLARE @notification XML;
	DECLARE @applicationMessage VARBINARY(MAX);

	BEGIN TRY
		BEGIN TRANSACTION;
		RECEIVE TOP (1)
			@conversationHandle = conversation_handle,
			@messageTypeName = message_type_name,
			@notification = CAST(message_body AS XML)
		FROM [ActivatorQueue_2];

		IF (@messageTypeName = 'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog')
		BEGIN
			END CONVERSATION @conversationHandle;
		END

		IF (@messageTypeName = 'http://schemas.microsoft.com/SQL/ServiceBroker/Error')
		BEGIN
			END CONVERSATION @conversationHandle;
		END

		WHILE (1 = 1)
		BEGIN
			WAITFOR (
				RECEIVE
					@conversationHandle = conversation_handle,
					@messageTypeName = message_type_name,
					@applicationMessage = message_body
				FROM [TargetQueue]
			), TIMEOUT 1000;

			IF (@@ROWCOUNT = 0)
			BEGIN
				-- Do not rollback here!
				BREAK;
			END

			IF (@messageTypeName = 'http://schemas.microsoft.com/SQL/ServiceBroker/Error')
			BEGIN
				END CONVERSATION @conversationHandle;
			END

			IF (@messageTypeName = 'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog')
			BEGIN
				END CONVERSATION @conversationHandle;
			END

			IF (@messageTypeName = 'DEFAULT')
			BEGIN
				-- Here's the place where you implement your application logic
				SEND ON CONVERSATION @conversationHandle (@applicationMessage);
				END CONVERSATION @conversationHandle;
			END

			COMMIT TRANSACTION;
			BEGIN TRANSACTION;
		END

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
	END CATCH
END
GO

--*********************************************
--*  Create the needed service program
--*********************************************
CREATE PROCEDURE [ApplicationServiceProgram_3]
AS
BEGIN
	DECLARE @conversationHandle UNIQUEIDENTIFIER;
	DECLARE @messageTypeName SYSNAME;
	DECLARE @notification XML;
	DECLARE @applicationMessage VARBINARY(MAX);

	BEGIN TRY
		BEGIN TRANSACTION;
		RECEIVE TOP (1)
			@conversationHandle = conversation_handle,
			@messageTypeName = message_type_name,
			@notification = CAST(message_body AS XML)
		FROM [ActivatorQueue_3];

		IF (@messageTypeName = 'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog')
		BEGIN
			END CONVERSATION @conversationHandle;
		END

		IF (@messageTypeName = 'http://schemas.microsoft.com/SQL/ServiceBroker/Error')
		BEGIN
			END CONVERSATION @conversationHandle;
		END

		WHILE (1 = 1)
		BEGIN
			WAITFOR (
				RECEIVE
					@conversationHandle = conversation_handle,
					@messageTypeName = message_type_name,
					@applicationMessage = message_body
				FROM [TargetQueue]
			), TIMEOUT 1000;

			IF (@@ROWCOUNT = 0)
			BEGIN
				-- Do not rollback here!
				BREAK;
			END

			IF (@messageTypeName = 'http://schemas.microsoft.com/SQL/ServiceBroker/Error')
			BEGIN
				END CONVERSATION @conversationHandle;
			END

			IF (@messageTypeName = 'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog')
			BEGIN
				END CONVERSATION @conversationHandle;
			END

			IF (@messageTypeName = 'DEFAULT')
			BEGIN
				-- Here's the place where you implement your application logic
				SEND ON CONVERSATION @conversationHandle (@applicationMessage);
				END CONVERSATION @conversationHandle;
			END

			COMMIT TRANSACTION;
			BEGIN TRANSACTION;
		END

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
	END CATCH
END
GO

--*********************************************
--*  Create the needed service program
--*********************************************
CREATE PROCEDURE [ApplicationServiceProgram_4]
AS
BEGIN
	DECLARE @conversationHandle UNIQUEIDENTIFIER;
	DECLARE @messageTypeName SYSNAME;
	DECLARE @notification XML;
	DECLARE @applicationMessage VARBINARY(MAX);

	BEGIN TRY
		BEGIN TRANSACTION;
		RECEIVE TOP (1)
			@conversationHandle = conversation_handle,
			@messageTypeName = message_type_name,
			@notification = CAST(message_body AS XML)
		FROM [ActivatorQueue_4];

		IF (@messageTypeName = 'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog')
		BEGIN
			END CONVERSATION @conversationHandle;
		END

		IF (@messageTypeName = 'http://schemas.microsoft.com/SQL/ServiceBroker/Error')
		BEGIN
			END CONVERSATION @conversationHandle;
		END

		WHILE (1 = 1)
		BEGIN
			WAITFOR (
				RECEIVE
					@conversationHandle = conversation_handle,
					@messageTypeName = message_type_name,
					@applicationMessage = message_body
				FROM [TargetQueue]
			), TIMEOUT 1000;

			IF (@@ROWCOUNT = 0)
			BEGIN
				-- Do not rollback here!
				BREAK;
			END

			IF (@messageTypeName = 'http://schemas.microsoft.com/SQL/ServiceBroker/Error')
			BEGIN
				END CONVERSATION @conversationHandle;
			END

			IF (@messageTypeName = 'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog')
			BEGIN
				END CONVERSATION @conversationHandle;
			END

			IF (@messageTypeName = 'DEFAULT')
			BEGIN
				-- Here's the place where you implement your application logic
				SEND ON CONVERSATION @conversationHandle (@applicationMessage);
				END CONVERSATION @conversationHandle;
			END

			COMMIT TRANSACTION;
			BEGIN TRANSACTION;
		END

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
	END CATCH
END
GO

--*********************************************
--*  Create the needed service program
--*********************************************
CREATE PROCEDURE [ApplicationServiceProgram_5]
AS
BEGIN
	DECLARE @conversationHandle UNIQUEIDENTIFIER;
	DECLARE @messageTypeName SYSNAME;
	DECLARE @notification XML;
	DECLARE @applicationMessage VARBINARY(MAX);

	BEGIN TRY
		BEGIN TRANSACTION;
		RECEIVE TOP (1)
			@conversationHandle = conversation_handle,
			@messageTypeName = message_type_name,
			@notification = CAST(message_body AS XML)
		FROM [ActivatorQueue_5];

		IF (@messageTypeName = 'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog')
		BEGIN
			END CONVERSATION @conversationHandle;
		END

		IF (@messageTypeName = 'http://schemas.microsoft.com/SQL/ServiceBroker/Error')
		BEGIN
			END CONVERSATION @conversationHandle;
		END

		WHILE (1 = 1)
		BEGIN
			WAITFOR (
				RECEIVE
					@conversationHandle = conversation_handle,
					@messageTypeName = message_type_name,
					@applicationMessage = message_body
				FROM [TargetQueue]
			), TIMEOUT 1000;

			IF (@@ROWCOUNT = 0)
			BEGIN
				-- Do not rollback here!
				BREAK;
			END

			IF (@messageTypeName = 'http://schemas.microsoft.com/SQL/ServiceBroker/Error')
			BEGIN
				END CONVERSATION @conversationHandle;
			END

			IF (@messageTypeName = 'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog')
			BEGIN
				END CONVERSATION @conversationHandle;
			END

			IF (@messageTypeName = 'DEFAULT')
			BEGIN
				-- Here's the place where you implement your application logic
				SEND ON CONVERSATION @conversationHandle (@applicationMessage);
				END CONVERSATION @conversationHandle;
			END

			COMMIT TRANSACTION;
			BEGIN TRANSACTION;
		END

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
	END CATCH
END
GO

--******************************************
--*  Create the needed event notifications
--******************************************
CREATE EVENT NOTIFICATION [ActivatorEvent_1]
	ON QUEUE [TargetQueue]
	FOR QUEUE_ACTIVATION
	TO SERVICE 'ActivatorService_1', 'current database';
GO

CREATE EVENT NOTIFICATION [ActivatorEvent_2]
	ON QUEUE [TargetQueue]
	FOR QUEUE_ACTIVATION
	TO SERVICE 'ActivatorService_2', 'current database';
GO

CREATE EVENT NOTIFICATION [ActivatorEvent_3]
	ON QUEUE [TargetQueue]
	FOR QUEUE_ACTIVATION
	TO SERVICE 'ActivatorService_3', 'current database';
GO

CREATE EVENT NOTIFICATION [ActivatorEvent_4]
	ON QUEUE [TargetQueue]
	FOR QUEUE_ACTIVATION
	TO SERVICE 'ActivatorService_4', 'current database';
GO

CREATE EVENT NOTIFICATION [ActivatorEvent_5]
	ON QUEUE [TargetQueue]
	FOR QUEUE_ACTIVATION
	TO SERVICE 'ActivatorService_5', 'current database';
GO

--************************
--*  Enabling activation
--************************
ALTER QUEUE [ActivatorQueue_1]
WITH ACTIVATION
(
	STATUS = ON,
	MAX_QUEUE_READERS = 1,
	PROCEDURE_NAME = [ApplicationServiceProgram_1],
	EXECUTE AS OWNER
)
GO

ALTER QUEUE [ActivatorQueue_2]
WITH ACTIVATION
(
	STATUS = ON,
	MAX_QUEUE_READERS = 1,
	PROCEDURE_NAME = [ApplicationServiceProgram_2],
	EXECUTE AS OWNER
)
GO

ALTER QUEUE [ActivatorQueue_3]
WITH ACTIVATION
(
	STATUS = ON,
	MAX_QUEUE_READERS = 1,
	PROCEDURE_NAME = [ApplicationServiceProgram_3],
	EXECUTE AS OWNER
)
GO

ALTER QUEUE [ActivatorQueue_4]
WITH ACTIVATION
(
	STATUS = ON,
	MAX_QUEUE_READERS = 1,
	PROCEDURE_NAME = [ApplicationServiceProgram_4],
	EXECUTE AS OWNER
)
GO

ALTER QUEUE [ActivatorQueue_5]
WITH ACTIVATION
(
	STATUS = ON,
	MAX_QUEUE_READERS = 1,
	PROCEDURE_NAME = [ApplicationServiceProgram_5],
	EXECUTE AS OWNER
)
GO

--*********************************************
--*  Create the initiator service
--*********************************************
CREATE QUEUE InitiatorQueue
GO

CREATE SERVICE InitiatorService
ON QUEUE InitiatorQueue
GO

--*********************************************
--*  Sending a message to the target service
--*********************************************
DECLARE @conversationHandle UNIQUEIDENTIFIER;
BEGIN DIALOG CONVERSATION @conversationHandle
	FROM SERVICE [InitiatorService]
	TO SERVICE 'TargetService'
	WITH ENCRYPTION = OFF;

SEND ON CONVERSATION @conversationHandle ('Test')
GO