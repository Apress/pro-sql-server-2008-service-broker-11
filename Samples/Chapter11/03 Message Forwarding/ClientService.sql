USE master;

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'Chapter11_ClientServiceMessageForwarding')
BEGIN
	PRINT 'Dropping database ''Chapter11_ClientServiceMessageForwarding''';
	DROP DATABASE Chapter11_ClientServiceMessageForwarding;
END
GO

CREATE DATABASE Chapter11_ClientServiceMessageForwarding
GO

USE Chapter11_ClientServiceMessageForwarding
GO

--*****************************************************************************
--*  Create the needed message types between the client and the Order Service
--*****************************************************************************
CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c11/OrderRequestMessage] VALIDATION = WELL_FORMED_XML
CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c11/OrderResponseMessage] VALIDATION = WELL_FORMED_XML
GO

--*****************************************************************
--*  Create the contract between the client and the Order Service
--*****************************************************************
CREATE CONTRACT [http://ssb.csharp.at/SSB_Book/c11/OrderContract]
(
	[http://ssb.csharp.at/SSB_Book/c11/OrderRequestMessage] SENT BY INITIATOR,
	[http://ssb.csharp.at/SSB_Book/c11/OrderResponseMessage] SENT BY TARGET
)
GO

--***********************************
--*  Create the queue "ClientQueue"
--***********************************
CREATE QUEUE ClientQueue WITH STATUS = ON
GO

--***************************************
--*  Create the service "ClientService"
--***************************************
CREATE SERVICE ClientService
ON QUEUE ClientQueue 
(
	[http://ssb.csharp.at/SSB_Book/c11/OrderContract]
)
GO

--**********************************************************************************************
--*  Create the stored procedure that processes the OrderResponseMessages from the OrderService
--**********************************************************************************************
CREATE PROCEDURE ProcessOrderResponseMessages
AS
BEGIN
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
				[ClientQueue]
		), TIMEOUT 1000

		IF (@@ROWCOUNT = 0)
		BEGIN
			ROLLBACK TRANSACTION
			BREAK
		END

		IF (@messagetypename = 'http://ssb.csharp.at/SSB_Book/c11/OrderResponseMessage')
		BEGIN
			-- Here you can send an email to the customer that his/her order was successfully processed
			PRINT 'Your order was successfully processed...';
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

--**********************************************************
--*  Activate internal activation on the queue ClientQueue
--**********************************************************
ALTER QUEUE ClientQueue
WITH ACTIVATION
(
	STATUS = ON,
	PROCEDURE_NAME = ProcessOrderResponseMessages,
	MAX_QUEUE_READERS = 1,
	EXECUTE AS SELF
)
GO

--*******************************************************************
--*  Create the necessary route to the message forwarding service
--*******************************************************************
CREATE ROUTE MessageForwardingServiceRoute
	WITH SERVICE_NAME = 'OrderService',
	ADDRESS	= 'TCP://MessageForwardingInstance:4740'
GO

--*************************************
--*  Create a new database master key
--*************************************
USE master
GO

CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'password1!'
GO

--**********************************************************************
--*  Create the certificate that holds both the public and private key
--**********************************************************************
CREATE CERTIFICATE ClientServiceCertPrivate
	WITH SUBJECT = 'For Service Broker authentication - ClientServiceCertPrivate',
	START_DATE = '01/01/2007'
GO

--********************************************************************
--*  Create the Service Broker endpoint for this SQL Server instance
--********************************************************************
CREATE ENDPOINT ClientServiceEndpoint
STATE = STARTED
AS TCP 
(
	LISTENER_PORT = 4741
)
FOR SERVICE_BROKER 
(
	AUTHENTICATION = CERTIFICATE ClientServiceCertPrivate
)
GO

--*********************************************************
--*  Backup the public key of the new created certificate
--*********************************************************
BACKUP CERTIFICATE ClientServiceCertPrivate
	TO FILE = 'c:\ClientServiceCertPublic.cert'
GO

--*****************************************************
--*  Add the login for the message forwarding service
--*****************************************************
CREATE LOGIN MessageForwardingServiceLogin WITH PASSWORD = 'password1!'
GO

CREATE USER MessageForwardingServiceUser FOR LOGIN MessageForwardingServiceLogin
GO

--******************************************************************
--*  Import the public key certificate from the OrderService
--******************************************************************
CREATE CERTIFICATE MessageForwardingServiceCertPublic
	AUTHORIZATION MessageForwardingServiceUser
	FROM FILE = 'c:\MessageForwardingServiceCertPublic.cert'
GO

--***********************************************************
--*  Grant the CONNECT permission to the OrderService
--***********************************************************
GRANT CONNECT ON ENDPOINT::ClientServiceEndpoint TO MessageForwardingServiceLogin
GO

USE Chapter11_ClientServiceMessageForwarding
GO

--****************************************************
--*  Send a new message to the "OrderService"
--****************************************************
BEGIN TRANSACTION;
	DECLARE @ch UNIQUEIDENTIFIER
	DECLARE @msg NVARCHAR(MAX);

	BEGIN DIALOG CONVERSATION @ch
		FROM SERVICE [ClientService]
		TO SERVICE 'OrderService'
		ON CONTRACT [http://ssb.csharp.at/SSB_Book/c11/OrderContract]
		WITH ENCRYPTION = OFF;

	SET @msg = 
		'<OrderRequest>
				<Customer>
					<CustomerID>4242</CustomerID>
				</Customer>
				<Product>
					<ProductID>123</ProductID>
					<Quantity>5</Quantity>
					<Price>40.99</Price>
				</Product>
				<CreditCard>
					<Holder>Klaus Aschenbrenner</Holder>
					<Number>1234-1234-1234-1234</Number>
					<ValidThrough>2009-10</ValidThrough>
				</CreditCard>
				<Shipping>
					<Name>Klaus Aschenbrenner</Name>
					<Address>Wagramer Strasse 4/803</Address>
					<ZipCode>1220</ZipCode>
					<City>Vienna</City>
					<Country>Austria</Country>
				</Shipping>
		</OrderRequest>';

	SEND ON CONVERSATION @ch MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c11/OrderRequestMessage] (@msg);
COMMIT;
GO

select * from sys.transmission_queue