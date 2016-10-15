USE master;

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'Chapter8_CreditCardService')
BEGIN
	PRINT 'Dropping database ''Chapter8_CreditCardService''';
	DROP DATABASE Chapter8_CreditCardService;
END
GO

CREATE DATABASE Chapter8_CreditCardService
GO

USE Chapter8_CreditCardService
GO

--**************************************************************************************
-- * Create all objects necessary for the communication between the
-- * OrderService and the CreditCardService. The CreditCardService
-- * draws the specified credit card with the provided amount.
--**************************************************************************************

--***************************************************************************************
--*  Create the needed message types between the OrderService and the CreditCardService
--***************************************************************************************
CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c08/CreditCardRequestMessage] VALIDATION = WELL_FORMED_XML
CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c08/CreditCardResponseMessage] VALIDATION = WELL_FORMED_XML
GO

--***************************************************************************
--*  Create the contract between the OrderService and the CreditCardService
--***************************************************************************
CREATE CONTRACT [http://ssb.csharp.at/SSB_Book/c08/CreditCardContract]
(
	[http://ssb.csharp.at/SSB_Book/c08/CreditCardRequestMessage] SENT BY INITIATOR,
	[http://ssb.csharp.at/SSB_Book/c08/CreditCardResponseMessage] SENT BY TARGET
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
	[http://ssb.csharp.at/SSB_Book/c08/CreditCardContract]
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

		IF (@messagetypename = 'http://ssb.csharp.at/SSB_Book/c08/CreditCardRequestMessage')
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
			SEND ON CONVERSATION @ch MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c08/CreditCardResponseMessage] (@responsemessage);

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

--***************************************
--*  Setup anonymous transport security
--***************************************
USE master
GO

CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'password1!'
GO

CREATE CERTIFICATE CreditCardServiceTransportCertPrivate
	WITH SUBJECT = 'For Service Broker authentication',
	START_DATE = '01/01/2008'
GO

-- Create the Service Broker endpoint
CREATE ENDPOINT CreditCardServiceEndpoint
STATE = STARTED
AS TCP 
(
	LISTENER_PORT = 4741
)
FOR SERVICE_BROKER 
(
	AUTHENTICATION = CERTIFICATE CreditCardServiceTransportCertPrivate
)
GO

-- Everyone (anonymous security) can now connect to this Service Broker endpoint!!!
GRANT CONNECT ON ENDPOINT::CreditCardServiceEndpoint TO [PUBLIC]
GO

--*****************************************************************************
--*  Create and setup the database user that represents the CreditCardService
--*****************************************************************************
USE Chapter8_CreditCardService
GO

CREATE USER CreditCardServiceUser WITHOUT LOGIN
GO

-- Grant the CONTROL permission
GRANT CONTROL ON SERVICE::CreditCardService TO CreditCardServiceUser
GO

--**********************************************************************************
--*  Create a new certificate that is owned by the previous created database user
--**********************************************************************************
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'password1!'
GO

CREATE CERTIFICATE CreditCardServiceCertPrivate
	AUTHORIZATION CreditCardServiceUser
	WITH SUBJECT = 'Private certificate for CreditCardService',
	START_DATE = '01/01/2008'
GO

BACKUP CERTIFICATE CreditCardServiceCertPrivate
	TO FILE = 'c:\CreditCardServiceCertPublic.cert'
GO

--*****************************************************************************
--*  Import the public key certificate from the other Service Broker endpoint
--*****************************************************************************
CREATE USER OrderServiceUser WITHOUT LOGIN
GO

CREATE CERTIFICATE OrderServiceCertPublic
	AUTHORIZATION OrderServiceUser
	FROM FILE = 'c:\OrderServiceCertPublic.cert'
GO

-- Grant the SEND permission
GRANT SEND ON SERVICE::CreditCardService TO OrderServiceUser
GO