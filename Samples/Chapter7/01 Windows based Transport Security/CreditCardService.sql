USE master;

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'Chapter7_CreditCardService')
BEGIN
	PRINT 'Dropping database ''Chapter7_CreditCardService''';
	DROP DATABASE Chapter7_CreditCardService;
END
GO

CREATE DATABASE Chapter7_CreditCardService
GO

USE Chapter7_CreditCardService
GO

--**************************************************************************************
-- * Create all objects necessary for the communication between the
-- * OrderService and the CreditCardService. The CreditCardService
-- * draws the specified credit card with the provided amount.
--**************************************************************************************

--***************************************************************************************
--*  Create the needed message types between the OrderService and the CreditCardService
--***************************************************************************************
CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c07/CreditCardRequestMessage] VALIDATION = WELL_FORMED_XML
CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c07/CreditCardResponseMessage] VALIDATION = WELL_FORMED_XML
GO

--***************************************************************************
--*  Create the contract between the OrderService and the CreditCardService
--***************************************************************************
CREATE CONTRACT [http://ssb.csharp.at/SSB_Book/c07/CreditCardContract]
(
	[http://ssb.csharp.at/SSB_Book/c07/CreditCardRequestMessage] SENT BY INITIATOR,
	[http://ssb.csharp.at/SSB_Book/c07/CreditCardResponseMessage] SENT BY TARGET
)
GO

--*************************************************
--*  Create the queue "CreditCardQueue"
--*************************************************
CREATE QUEUE CreditCardQueue WITH STATUS = ON
GO

--************************************************************
--*  Create the service "CreditCardService"
--************************************************************
CREATE SERVICE CreditCardService
ON QUEUE CreditCardQueue 
(
	[http://ssb.csharp.at/SSB_Book/c07/CreditCardContract]
)
GO

--***********************************************************************************************
--*  Create a table that stores the credit card transactions submitted to the CredidCardService
--***********************************************************************************************
CREATE TABLE CreditCardTransactions
(
	CreditCardTransactionID UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
	CreditCardHolder NVARCHAR(256) NOT NULL,
	CreditCardNumber NVARCHAR(50) NOT NULL,
	ValidThrough NVARCHAR(10) NOT NULL,
	Amount DECIMAL(18, 2) NOT NULL
)
GO

--*********************************************************************************************************
--*  Create the stored procedure that processes the CreditCardRequest messages from the CreditCardService
--*********************************************************************************************************
CREATE PROCEDURE ProcessCreditCardRequestMessages
AS
	DECLARE @ch UNIQUEIDENTIFIER;
	DECLARE @messagetypename NVARCHAR(256);
	DECLARE	@messagebody XML;
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
				CreditCardQueue
		), TIMEOUT 1000

		IF (@@ROWCOUNT = 0)
		BEGIN
			ROLLBACK TRANSACTION
			BREAK
		END

		IF (@messagetypename = 'http://ssb.csharp.at/SSB_Book/c07/CreditCardRequestMessage')
		BEGIN
			-- Create a new credit card transaction record
			INSERT INTO CreditCardTransactions (CreditCardTransactionID, CreditCardHolder, CreditCardNumber, ValidThrough, Amount) 
			VALUES 
			(
				NEWID(), 
				@messagebody.value('/CreditCardRequest[1]/Holder[1]', 'NVARCHAR(256)'),
				@messagebody.value('/CreditCardRequest[1]/Number[1]', 'NVARCHAR(50)'),
				@messagebody.value('/CreditCardRequest[1]/ValidThrough[1]', 'NVARCHAR(10)'),
				@messagebody.value('/CreditCardRequest[1]/Amount[1]', 'DECIMAL(18, 2)')
			)

			-- Create the response message for the OrderService
			SET @responsemessage = '<CreditCardResponse>1</CreditCardResponse>';

			-- Send the response message back to the OrderService
			SEND ON CONVERSATION @ch MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c07/CreditCardResponseMessage] (@responsemessage);

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

--**************************************************************
--*  Activate internal activation on the queue CreditCardQueue
--**************************************************************
ALTER QUEUE CreditCardQueue
WITH ACTIVATION
(
	STATUS = ON,
	PROCEDURE_NAME = ProcessCreditCardRequestMessages,
	MAX_QUEUE_READERS = 1,
	EXECUTE AS SELF
)
GO

--********************************************************
--*  Create the necessary route back to the OrderService
--********************************************************
CREATE ROUTE OrderServiceRoute
	WITH SERVICE_NAME = 'OrderService',
	ADDRESS = 'TCP://127.0.0.1:4740'
GO

--********************************************************************
--*  Create the Service Broker endpoint for this SQL Server instance
--********************************************************************
CREATE ENDPOINT CreditCardServiceEndpoint
STATE = STARTED
AS TCP 
(
	LISTENER_PORT = 4741
)
FOR SERVICE_BROKER 
(
	AUTHENTICATION = WINDOWS
)
GO

--********************************************************************
--*  Add the login from the other SQL Server instance
--********************************************************************
USE master
GO

CREATE LOGIN [VISTA_NOTEBOOK\OrderLogin] FROM WINDOWS
GO

--********************************************************************
--*  Grant the CONNECT permission to the other SQL Server instance
--********************************************************************
GRANT CONNECT ON ENDPOINT::CreditCardServiceEndpoint TO [VISTA_NOTEBOOK\OrderLogin]
GO

--********************************************************************
--*  Grant the SEND permission to the other SQL Server instance
--********************************************************************
USE Chapter7_CreditCardService
GO

GRANT SEND ON SERVICE::[CreditCardService] TO PUBLIC
GO