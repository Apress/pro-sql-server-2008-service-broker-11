USE master;

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'Chapter10_AsynchronousTrigger')
BEGIN
	PRINT 'Dropping database ''Chapter10_AsynchronousTrigger''';
	DROP DATABASE Chapter10_AsynchronousTrigger;
END
GO

CREATE DATABASE Chapter10_AsynchronousTrigger
GO

USE Chapter10_AsynchronousTrigger
GO

-- This table stores our customers
CREATE TABLE [dbo].[Customers](
	[ID] [uniqueidentifier] NOT NULL,
	[CustomerNumber] [varchar](100) NOT NULL,
	[CustomerName] [varchar](100) NOT NULL,
	[CustomerAddress] [varchar](100) NOT NULL,
	[EmailAddress] [varchar](100) NOT NULL,
 CONSTRAINT [PK_Customers] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

-- Setting the Trustworthy property for assemblies with EXTERNAL ACCESS permissions
ALTER DATABASE Chapter10_AsynchronousTrigger SET TRUSTWORTHY ON
GO

-- Import assembly into the database
CREATE ASSEMBLY [CustomerManagement]
FROM 'D:\Klaus\Work\Autorentätigkeit\Apress\Pro SQL 2008 Service Broker\Chapter 10\Samples\01 Asynchronous Trigger\AsynchronousTrigger\bin\Debug\AsynchronousTrigger.dll'
WITH PERMISSION_SET = EXTERNAL_ACCESS
GO

-- Add the debug information about the assembly
ALTER ASSEMBLY [CustomerManagement]
ADD FILE FROM 'D:\Klaus\Work\Autorentätigkeit\Apress\Pro SQL 2008 Service Broker\Chapter 10\Samples\01 Asynchronous Trigger\AsynchronousTrigger\bin\Debug\AsynchronousTrigger.pdb'
GO

-- Add the debug information about the ServiceBrokerInterface assembly
ALTER ASSEMBLY [ServiceBrokerInterface]
ADD FILE FROM 'D:\Klaus\Work\Autorentätigkeit\Apress\Pro SQL 2008 Service Broker\Chapter 10\Samples\01 Asynchronous Trigger\AsynchronousTrigger\bin\Debug\ServiceBrokerInterface.pdb'
GO

-- Create the managed stored procedure
CREATE PROCEDURE [ProcessInsertedCustomer]
AS EXTERNAL NAME [CustomerManagement].[AsynchronousTrigger.TargetService].[ServiceProcedure]
GO

-- Create the request message types
CREATE MESSAGE TYPE 
  [http://ssb.csharp.at/SSB_Book/c10/CustomerInsertedRequestMessage]
  VALIDATION = WELL_FORMED_XML
GO

CREATE MESSAGE TYPE 
  [http://ssb.csharp.at/SSB_Book/c10/EndOfMessageStream]
  VALIDATION = WELL_FORMED_XML
GO

-- Create the contract based on the previous 2 message types
CREATE CONTRACT [http://ssb.csharp.at/SSB_Book/c10/CustomerInsertContract]
(
    [http://ssb.csharp.at/SSB_Book/c10/CustomerInsertedRequestMessage] SENT BY INITIATOR,
	[http://ssb.csharp.at/SSB_Book/c10/EndOfMessageStream] SENT BY INITIATOR
)
GO

-- Create the service queue
CREATE QUEUE [CustomerInsertedServiceQueue]
GO

-- Create the client queue
CREATE QUEUE [CustomerInsertedClientQueue]
GO

-- Create the service
CREATE SERVICE [CustomerInsertedService] 
	ON QUEUE [CustomerInsertedServiceQueue]
(
	[http://ssb.csharp.at/SSB_Book/c10/CustomerInsertContract]
)
GO

-- Create the client service
CREATE SERVICE [CustomerInsertedClient]
	ON QUEUE [CustomerInsertedClientQueue]
(
	[http://ssb.csharp.at/SSB_Book/c10/CustomerInsertContract]
)
GO

-- This table stores all current ongoing conversations
CREATE TABLE SessionConversations
(
	SPID INT NOT NULL,
	FromService SYSNAME NOT NULL,
	ToService SYSNAME NOT NULL,
	OnContract SYSNAME NOT NULL,
	ConversationHandle UNIQUEIDENTIFIER NOT NULL,
	PRIMARY KEY (SPID, FromService, ToService, OnContract),
	UNIQUE (ConversationHandle)
);
GO

-- Create the trigger written with T-SQL
CREATE TRIGGER OnCustomerInserted ON Customers FOR INSERT
AS
	DECLARE @conversationHandle UNIQUEIDENTIFIER
	DECLARE @fromService SYSNAME
	DECLARE @toService SYSNAME
	DECLARE @onContract SYSNAME
	DECLARE @messageBody XML

	SET @fromService = 'CustomerInsertedClient'
	SET @toService = 'CustomerInsertedService'
	SET @onContract = 'http://ssb.csharp.at/SSB_Book/c10/CustomerInsertContract'

	-- Check if there is already an ongoing conversation with the TargetService
	SELECT @conversationHandle = ConversationHandle FROM SessionConversations
		WHERE SPID = @@SPID
		AND FromService = @fromService
		AND ToService = @toService
		AND OnContract = @onContract

	IF @conversationHandle IS NULL
	BEGIN
		-- We have to begin a new Service Broker conversation with the TargetService
		BEGIN DIALOG CONVERSATION @conversationHandle
			FROM SERVICE @fromService
			TO SERVICE @toService
			ON CONTRACT @onContract
			WITH ENCRYPTION = OFF;

		-- Create the dialog timer for ending the ongoing conversation
		BEGIN CONVERSATION TIMER (@conversationHandle) TIMEOUT = 5;

		-- Store the ongoing conversation for further use
		INSERT INTO SessionConversations (SPID, FromService, ToService, OnContract, ConversationHandle)
		VALUES
		(
			@@SPID,
			@fromService,
			@toService,
			@onContract,
			@conversationHandle
		)
	END
	
	-- Construct the request message
	SET @messageBody = (SELECT * FROM INSERTED FOR XML AUTO, ELEMENTS);

	-- Send the message to the TargetService
	;SEND ON CONVERSATION @conversationHandle
	MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c10/CustomerInsertedRequestMessage] (@messageBody);
GO

-- Create the stored procedure that processes the DialogTimer and EndDialog message from the CustomerInsertedClientQueue
CREATE PROCEDURE ProcessCustomerInsertedClientQueue
AS
	DECLARE @conversationHandle UNIQUEIDENTIFIER;
	DECLARE @messageTypeName SYSNAME;

	BEGIN TRANSACTION;

    RECEIVE TOP(1) 
		@conversationHandle = conversation_handle,
		@messageTypeName = message_type_name
	FROM CustomerInsertedClientQueue;

	IF @conversationHandle IS NOT NULL
	BEGIN
		DELETE FROM SessionConversations
		WHERE ConversationHandle = @conversationHandle;

		IF @messageTypeName = 'http://schemas.microsoft.com/SQL/ServiceBroker/DialogTimer'
		BEGIN
			SEND ON CONVERSATION @conversationHandle MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c10/EndOfMessageStream];
		END

		ELSE IF @messageTypeName = 'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog'
		BEGIN
			END CONVERSATION @conversationHandle;
		END
	END

	COMMIT TRANSACTION;
GO

-- Activate internal activation on the InitiatorService
ALTER QUEUE [CustomerInsertedClientQueue]
WITH ACTIVATION 
(
	STATUS = ON,
	PROCEDURE_NAME = ProcessCustomerInsertedClientQueue,
	MAX_QUEUE_READERS = 1,
	EXECUTE AS SELF
)
GO

-- Activate internal activation on the TargetService
ALTER QUEUE [CustomerInsertedServiceQueue]
WITH ACTIVATION 
(
	STATUS = ON,
	PROCEDURE_NAME = ProcessInsertedCustomer,
	MAX_QUEUE_READERS = 1,
	EXECUTE AS SELF
)
GO

-- Try to insert a new record into the table.
-- As soon as the record is inserted into the table, the managed trigger does his work and the text file is created in the file system
INSERT INTO Customers (ID, CustomerNumber, CustomerName, CustomerAddress, EmailAddress)
VALUES (NEWID(), 'AKS', 'Aschenbrenner Klaus', 'A-1220 Vienna', 'Klaus.Aschenbrenner@csharp.at')
GO