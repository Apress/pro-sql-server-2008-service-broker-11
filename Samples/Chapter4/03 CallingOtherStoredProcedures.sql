USE master;

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'Chapter4_CallingOtherStoredProcedures')
BEGIN
	PRINT 'Dropping database ''Chapter4_CallingOtherStoredProcedures''';
	DROP DATABASE Chapter4_CallingOtherStoredProcedures;
END
GO

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'Chapter4_Loggingatabase')
BEGIN
	PRINT 'Dropping database ''Chapter4_LoggingDatabase''';
	DROP DATABASE Chapter4_LoggingDatabase;
END
GO

CREATE DATABASE Chapter4_CallingOtherStoredProcedures
GO

CREATE DATABASE Chapter4_LoggingDatabase
GO

USE Chapter4_LoggingDatabase
GO

--****************************************
--* Creating the logging infrastructure
--****************************************
CREATE TABLE LoggingTable
(
	ID UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
	[Message] NVARCHAR(MAX) NOT NULL
)
GO

CREATE PROCEDURE LoggingProcedure
@Message NVARCHAR(MAX)
AS
	INSERT INTO LoggingTable (ID, [Message])
	VAlUES (NEWID(), @Message)
GO

USE Chapter4_CallingOtherStoredProcedures
GO

--*********************************************
--*  Create the necessary message types
--*********************************************
CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c04/RequestSessions]
	VALIDATION = EMPTY
GO

CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c04/Sessions]
	VALIDATION = WELL_FORMED_XML;
GO

--*********************************************
--*  Create the needed contract
--*********************************************
CREATE CONTRACT [http://ssb.csharp.at/SSB_Book/c04/SessionsContract]
(
	[http://ssb.csharp.at/SSB_Book/c04/RequestSessions] SENT BY INITIATOR,
	[http://ssb.csharp.at/SSB_Book/c04/Sessions] SENT BY TARGET
);
GO

--***********************************************
--*  Create the target queue and target service
--***********************************************
CREATE QUEUE [TargetQueue]
GO

CREATE SERVICE [TargetService] 
ON QUEUE [TargetQueue]
(
	[http://ssb.csharp.at/SSB_Book/c04/SessionsContract]
)
GO

--***********************************************
--*  Create the client queue and client service
--***********************************************
CREATE QUEUE [InitiatorQueue]
GO

CREATE SERVICE [InitiatorService] 
ON QUEUE [InitiatorQueue]
GO

--*************************************************************************************
--*  The service program that handles the request messages on the queue "TargetQueue"
--*************************************************************************************
CREATE PROCEDURE SessionsServiceProcedure
AS
BEGIN
	DECLARE @ch UNIQUEIDENTIFIER
	DECLARE @messagetypename SYSNAME;

	BEGIN TRY
		BEGIN TRANSACTION
		WAITFOR (
			RECEIVE TOP (1) 
				@ch = conversation_handle,
				@messagetypename = message_type_name
			FROM TargetQueue
		), TIMEOUT 60000;

		IF (@@ROWCOUNT > 0)
		BEGIN
			IF (@messagetypename = 'http://ssb.csharp.at/SSB_Book/c04/RequestSessions')
			BEGIN
				DECLARE @response XML;

				-- Create the response message
				SELECT @response = 
				(
					SELECT * FROM sys.dm_exec_sessions
					FOR XML PATH ('session'), TYPE
				);

				-- Calling a stored procedure in another database
				EXEC Chapter4_LoggingDatabase.dbo.LoggingProcedure 'This is a test message for the logging database';

				-- Send the response message over the conversation
				SEND ON CONVERSATION @ch
				MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c04/Sessions] (@response);

				-- End the conversation and commit
				END CONVERSATION @ch;
			END
		END

		-- Commit the whole transaction
		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
	END CATCH
END
GO

--***********************************************************
--*  Enable internal activation on the queue "TargetQueue"
--***********************************************************
ALTER QUEUE [TargetQueue] 
WITH ACTIVATION
(
	STATUS = ON,
	MAX_QUEUE_READERS = 1,
	PROCEDURE_NAME = [SessionsServiceProcedure],
	EXECUTE AS OWNER
)
GO

--*************************************************
--*  Send a request message to the target service
--*************************************************
BEGIN TRANSACTION
DECLARE @ch UNIQUEIDENTIFIER;

BEGIN DIALOG CONVERSATION @ch
	FROM SERVICE [InitiatorService]
	TO SERVICE 'TargetService'
	ON CONTRACT [http://ssb.csharp.at/SSB_Book/c04/SessionsContract]
	WITH ENCRYPTION = OFF;

	SEND ON CONVERSATION @ch 
	MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c04/RequestSessions];

COMMIT TRANSACTION
GO

--*************************************************************************************
--*  Change the service program for code signing
--*************************************************************************************
DROP PROCEDURE SessionsServiceProcedure
GO

CREATE PROCEDURE SessionsServiceProcedure
WITH EXECUTE AS OWNER
AS
BEGIN
	DECLARE @ch UNIQUEIDENTIFIER
	DECLARE @messagetypename SYSNAME;

	BEGIN TRY
		BEGIN TRANSACTION
		WAITFOR (
			RECEIVE TOP (1) 
				@ch = conversation_handle,
				@messagetypename = message_type_name
			FROM TargetQueue
		), TIMEOUT 1000;

		IF (@@ROWCOUNT > 0)
		BEGIN
			IF (@messagetypename = 'http://ssb.csharp.at/SSB_Book/c04/RequestSessions')
			BEGIN
				DECLARE @response XML;

				-- Create the response message
				SELECT @response = 
				(
					SELECT * FROM sys.dm_exec_sessions
					FOR XML PATH ('session'), TYPE
				);

				-- Calling a stored procedure in another database
				EXEC Chapter4_LoggingDatabase.dbo.LoggingProcedure;

				-- Send the response message over the conversation
				SEND ON CONVERSATION @ch
				MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c04/Sessions] (@response);

				-- End the conversation and commit
				END CONVERSATION @ch;
			END
		END

		-- Commit the whole transaction
		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
	END CATCH
END
GO

--***********************************************************
--*  Create a certificate that is needed for code signing
--***********************************************************
CREATE CERTIFICATE SessionsServiceProcedureCertificate
	ENCRYPTION BY PASSWORD = 'Password123'
	WITH SUBJECT = 'SessionsServiceProcedure Signing certificate'
GO

--*********************************************************************
--*  Sign the service program with the private key of the certificate
--*********************************************************************
ADD SIGNATURE TO OBJECT::[SessionsServiceProcedure]
	BY CERTIFICATE [SessionsServiceProcedureCertificate]
	WITH PASSWORD = 'Password123'
GO

--************************************************************************************
--*  Drop the private key. This way it cannot be used again to sign other procedures
--************************************************************************************
ALTER CERTIFICATE [SessionsServiceProcedureCertificate]
	REMOVE PRIVATE KEY
GO

--****************************************************
--*  Copy the certificate into the "master" database
--****************************************************
BACKUP CERTIFICATE [SessionsServiceProcedureCertificate]
	TO FILE = 'C:\SessionsServiceProcedure.cert'
GO

USE Chapter4_LoggingDatabase
GO

CREATE CERTIFICATE [SessionsServiceProcedureCertificate]
	FROM FILE = 'C:\SessionsServiceProcedure.cert'
GO

--****************************************************
--*  Create a login from the certificate
--****************************************************
CREATE USER [SessionsServiceProcedureUser]
	FROM CERTIFICATE [SessionsServiceProcedureCertificate]
GO

--****************************************************
--*  Grant the needed permissions to the login
--****************************************************
GRANT AUTHENTICATE TO [SessionsServiceProcedureUser]
GRANT EXECUTE ON [LoggingProcedure] TO [SessionsServiceProcedureUser]
GO

--**************************************************************
--*  Try to send another request message to the target service
--**************************************************************
USE Chapter4_CallingOtherStoredProcedures
GO

-- Re-Enable the queue "TargetQueue"
ALTER QUEUE TargetQueue
WITH STATUS = ON
GO

BEGIN TRANSACTION
DECLARE @ch UNIQUEIDENTIFIER;

BEGIN DIALOG CONVERSATION @ch
	FROM SERVICE [InitiatorService]
	TO SERVICE 'TargetService'
	ON CONTRACT [http://ssb.csharp.at/SSB_Book/c04/SessionsContract]
	WITH ENCRYPTION = OFF;

	SEND ON CONVERSATION @ch 
	MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c04/RequestSessions];

COMMIT TRANSACTION
GO

--***********************************************************
--*  Review the received response message from the service
--***********************************************************
SELECT CAST(message_body AS XML), * FROM InitiatorQueue
GO