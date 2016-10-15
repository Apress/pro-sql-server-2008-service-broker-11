USE master;

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'Chapter9_SODA_Services')
BEGIN
	PRINT 'Dropping database ''Chapter9_SODA_Services''';
	DROP DATABASE Chapter9_SODA_Services;
END
GO

CREATE DATABASE Chapter9_SODA_Services
GO

USE Chapter9_SODA_Services
GO

--****************************************************************************
-- * Create all objects necessary for the communication between the
-- * ClientService and the OrderService. The OrderService starts additional
-- * conversations with other Service Broker services to fulfil the order
-- * received from the client
--****************************************************************************

--*****************************************************************************
--*  Create the needed message types between the client and the Order Service
--*****************************************************************************
CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c09/OrderRequestMessage] VALIDATION = WELL_FORMED_XML
CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c09/OrderResponseMessage] VALIDATION = WELL_FORMED_XML
GO

--*****************************************************************
--*  Create the contract between the client and the Order Service
--*****************************************************************
CREATE CONTRACT [http://ssb.csharp.at/SSB_Book/c09/OrderContract]
(
	[http://ssb.csharp.at/SSB_Book/c09/OrderRequestMessage] SENT BY INITIATOR,
	[http://ssb.csharp.at/SSB_Book/c09/OrderResponseMessage] SENT BY TARGET
)
GO

--***************************************************************************************
--*  Create the needed message types between the OrderService and the AccountingService
--***************************************************************************************
CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c09/AccountingRequestMessage] VALIDATION = WELL_FORMED_XML
CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c09/AccountingResponseMessage] VALIDATION = WELL_FORMED_XML
GO

--***************************************************************************
--*  Create the contract between the OrderService and the AccountingService
--***************************************************************************
CREATE CONTRACT [http://ssb.csharp.at/SSB_Book/c09/AccountingContract]
(
	[http://ssb.csharp.at/SSB_Book/c09/AccountingRequestMessage] SENT BY INITIATOR,
	[http://ssb.csharp.at/SSB_Book/c09/AccountingResponseMessage] SENT BY TARGET
)
GO

--**************************************************************************************
--*  Create the needed message types between the OrderService and the InventoryService
--**************************************************************************************
CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c09/InventoryRequestMessage] VALIDATION = WELL_FORMED_XML
CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c09/InventoryResponseMessage] VALIDATION = WELL_FORMED_XML
GO

--**************************************************************************
--*  Create the contract between the OrderService and the InventoryService
--**************************************************************************
CREATE CONTRACT [http://ssb.csharp.at/SSB_Book/c09/InventoryContract]
(
	[http://ssb.csharp.at/SSB_Book/c09/InventoryRequestMessage] SENT BY INITIATOR,
	[http://ssb.csharp.at/SSB_Book/c09/InventoryResponseMessage] SENT BY TARGET
)
GO

--**************************************************************************************
--*  Create the needed message types between the OrderService and the ShippingServicee
--**************************************************************************************
CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c09/ShippingRequestMessage] VALIDATION = WELL_FORMED_XML
CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c09/ShippingResponseMessage] VALIDATION = WELL_FORMED_XML
GO

--**************************************************************************
--*  Create the contract between the OrderService and the ShippingService
--**************************************************************************
CREATE CONTRACT [http://ssb.csharp.at/SSB_Book/c09/ShippingContract]
(
	[http://ssb.csharp.at/SSB_Book/c09/ShippingRequestMessage] SENT BY INITIATOR,
	[http://ssb.csharp.at/SSB_Book/c09/ShippingResponseMessage] SENT BY TARGET
)
GO

--***************************************************************************************
--*  Create the needed message types between the OrderService and the CreditCardService
--***************************************************************************************
CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c09/CreditCardRequestMessage] VALIDATION = WELL_FORMED_XML
CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c09/CreditCardResponseMessage] VALIDATION = WELL_FORMED_XML
GO

--***************************************************************************
--*  Create the contract between the OrderService and the CreditCardService
--***************************************************************************
CREATE CONTRACT [http://ssb.csharp.at/SSB_Book/c09/CreditCardContract]
(
	[http://ssb.csharp.at/SSB_Book/c09/CreditCardRequestMessage] SENT BY INITIATOR,
	[http://ssb.csharp.at/SSB_Book/c09/CreditCardResponseMessage] SENT BY TARGET
)
GO

--***************************************************************
--*  Create the queues "ClientQueue" and "OrderQueue"
--***************************************************************
CREATE QUEUE ClientQueue WITH STATUS = ON
GO

--************************************************************
--*  Create the queues "ClientService" and "TargetService"
--************************************************************
CREATE SERVICE ClientService
ON QUEUE ClientQueue 
(
	[http://ssb.csharp.at/SSB_Book/c09/OrderContract]
)
GO

--***************************************************************
--*  Create the queue "OrderQueue"
--***************************************************************
CREATE QUEUE OrderQueue WITH STATUS = ON, RETENTION = ON
GO

--************************************************************
--*  Create the service "OrderService"
--************************************************************
CREATE SERVICE OrderService
ON QUEUE OrderQueue
(
	[http://ssb.csharp.at/SSB_Book/c09/OrderContract]
)
GO

--*************************************************
--*  Create the queue "AccountingQueue"
--*************************************************
CREATE QUEUE AccountingQueue WITH STATUS = ON
GO

--************************************************************
--*  Create the service "CreditCardValidationService"
--************************************************************
CREATE SERVICE AccountingService
ON QUEUE AccountingQueue 
(
	[http://ssb.csharp.at/SSB_Book/c09/AccountingContract]
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
	[http://ssb.csharp.at/SSB_Book/c09/CreditCardContract]
)
GO

--*************************************************
--*  Create the queue "InventoryQueue"
--*************************************************
CREATE QUEUE InventoryQueue WITH STATUS = ON
GO

--************************************************************
--*  Create the service "InventoryService"
--************************************************************
CREATE SERVICE InventoryService
ON QUEUE InventoryQueue 
(
	[http://ssb.csharp.at/SSB_Book/c09/InventoryContract]
)
GO

--*************************************************
--*  Create the queue "ShippingQueue"
--*************************************************
CREATE QUEUE ShippingQueue WITH STATUS = ON
GO

--************************************************************
--*  Create the service "ShippingService"
--************************************************************
CREATE SERVICE ShippingService
ON QUEUE ShippingQueue 
(
	[http://ssb.csharp.at/SSB_Book/c09/ShippingContract]
)
GO

--*********************************************************************************
--*  Create the stored procedure that sends a request message to the OrderService
--*********************************************************************************
CREATE PROCEDURE SendOrderRequestMessage
@RequestMessage XML
AS
	BEGIN TRANSACTION;
		DECLARE @ch UNIQUEIDENTIFIER
		DECLARE @msg NVARCHAR(MAX);

		BEGIN DIALOG CONVERSATION @ch
			FROM SERVICE [ClientService]
			TO SERVICE 'OrderService'
			ON CONTRACT [http://ssb.csharp.at/SSB_Book/c09/OrderContract]
			WITH ENCRYPTION = OFF;

		SET @msg = CAST(@RequestMessage AS NVARCHAR(MAX));

		SEND ON CONVERSATION @ch MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c09/OrderRequestMessage] (@msg);
	COMMIT;
GO

--***************************************************************************************************
--*  Create the HTTP endpoint for exposing the previous created stored procedure to other clients
--***************************************************************************************************
--CREATE ENDPOINT WebServiceEndpoint
--STATE = STARTED
--AS HTTP
--(
--	PATH = '/SendOrderRequestMessage',
--	AUTHENTICATION = (INTEGRATED),
--	PORTS = (CLEAR),
--	SITE = 'vista_notebook'
--)
--FOR SOAP
--(
--	WEBMETHOD 'SendOrderRequestMessage'
--	(
--		NAME = 'Chapter9_SODA_Services.dbo.SendOrderRequestMessage'
--	),
--	WSDL = DEFAULT,
--	SCHEMA = STANDARD,
--	DATABASE = 'Chapter9_SODA_Services',
--	NAMESPACE = 'http://www.csharp.at'
--)
--GO

--*******************************************************
--* Create the state table, that holds the state of the 
--* current conversation group
--*******************************************************
CREATE TABLE ApplicationState
(
	ConversationGroupID UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
	CreditCardStatus BIT NOT NULL,
	AccountingStatus BIT NOT NULL,
	InventoryStatus BIT NOT NULL,
	ShippingMessageSent BIT NOT NULL,
	ShippingStatus BIT NOT NULL
)
GO

--************************************************************************************************
--* Create the stored procedure that loads the application state for the managed service program
--************************************************************************************************
CREATE PROCEDURE LoadApplicationState
@ConversationGroupID UNIQUEIDENTIFIER
AS
BEGIN
	DECLARE @CreditCardStatus BIT;
	DECLARE @AccountingStatus BIT;
	DECLARE @InventoryStatus BIT;
	DECLARE @ShippingMessageSent BIT;
	DECLARE @ShippingStatus BIT;

	-- Retrieving the application state for the current conversation group
	SELECT 
		@CreditCardStatus = CreditCardStatus,
		@AccountingStatus = AccountingStatus,
		@InventoryStatus = InventoryStatus,
		@ShippingMessageSent = ShippingMessageSent,
		@ShippingStatus = ShippingStatus
	FROM ApplicationState
	WHERE ConversationGroupID = @ConversationGroupID;

	IF (@@ROWCOUNT = 0)
	BEGIN
		-- There is currently no application state available, so we insert the application state into the state table
		SET @CreditCardStatus = 0;
		SET @AccountingStatus = 0;
		SET @InventoryStatus = 0;
		SET @ShippingMessageSent = 0;
		SET @ShippingStatus = 0;
	
		-- Insert the state record
		INSERT INTO ApplicationState (ConversationGroupID, CreditCardStatus, AccountingStatus, InventoryStatus, ShippingMessageSent, ShippingStatus)
		VALUES
		(
			@ConversationGroupID,
			@CreditCardStatus,
			@AccountingStatus,
			@InventoryStatus,
			@ShippingMessageSent,
			@ShippingStatus
		)
	END

	-- Retrieving the application state for the current conversation group
	SELECT 
		ConversationGroupID,
		CreditCardStatus,
		AccountingStatus,
		InventoryStatus,
		ShippingMessageSent,
		ShippingStatus
	FROM ApplicationState
	WHERE ConversationGroupId = @ConversationGroupID;
END
GO

--******************************************************************************************
--* Create the assembly that implements the service program for the "OrderService" service
--******************************************************************************************
CREATE ASSEMBLY [OrderServiceLibrary]
FROM 'D:\Klaus\Work\Private\Apress\Pro SQL 2005 Service Broker\Chapter 9\Samples\03 Managed Service Program\OrderServiceLibrary\bin\Debug\OrderServiceLibrary.dll'
GO

ALTER ASSEMBLY [OrderServiceLibrary]
ADD FILE FROM 'D:\Klaus\Work\Private\Apress\Pro SQL 2005 Service Broker\Chapter 9\Samples\03 Managed Service Program\OrderServiceLibrary\bin\Debug\OrderServiceLibrary.pdb'
GO

ALTER ASSEMBLY [ServiceBrokerInterface]
ADD FILE FROM 'D:\Klaus\Work\Private\Apress\Pro SQL 2005 Service Broker\Chapter 9\Samples\03 Managed Service Program\OrderServiceLibrary\bin\Debug\ServiceBrokerInterface.pdb'
GO

--**************************************************************
--*  Register the managed service program for the OrderService
--**************************************************************
CREATE PROCEDURE OrderServiceProcedure
AS
EXTERNAL NAME [OrderServiceLibrary].[OrderServiceLibrary.OrderService].ServiceProgramProcedure
GO

--***********************************************************************************************
--* Create the assembly that implements the service program for the "AccountingService" service
--***********************************************************************************************
CREATE ASSEMBLY [AccountingServiceLibrary]
FROM 'D:\Klaus\Work\Private\Apress\Pro SQL 2005 Service Broker\Chapter 9\Samples\03 Managed Service Program\AccountingServiceLibrary\bin\Debug\AccountingServiceLibrary.dll'
GO

ALTER ASSEMBLY [AccountingServiceLibrary]
ADD FILE FROM 'D:\Klaus\Work\Private\Apress\Pro SQL 2005 Service Broker\Chapter 9\Samples\03 Managed Service Program\AccountingServiceLibrary\bin\Debug\AccountingServiceLibrary.pdb'
GO

--*******************************************************************
--*  Register the managed service program for the AccountingService
--*******************************************************************
CREATE PROCEDURE AccountingServiceProcedure
AS
EXTERNAL NAME [AccountingServiceLibrary].[AccountingServiceLibrary.AccountingService].ServiceProgramProcedure
GO

--***********************************************************************************************
--* Create the assembly that implements the service program for the "CreditCardService" service
--***********************************************************************************************
CREATE ASSEMBLY [CreditCardServiceLibrary]
FROM 'D:\Klaus\Work\Private\Apress\Pro SQL 2005 Service Broker\Chapter 9\Samples\03 Managed Service Program\CreditCardServiceLibrary\bin\Debug\CreditCardServiceLibrary.dll'
GO

ALTER ASSEMBLY [CreditCardServiceLibrary]
ADD FILE FROM 'D:\Klaus\Work\Private\Apress\Pro SQL 2005 Service Broker\Chapter 9\Samples\03 Managed Service Program\CreditCardServiceLibrary\bin\Debug\CreditCardServiceLibrary.pdb'
GO

--*******************************************************************
--*  Register the managed service program for the CreditCardService
--*******************************************************************
CREATE PROCEDURE CreditCardServiceProcedure
AS
EXTERNAL NAME [CreditCardServiceLibrary].[CreditCardServiceLibrary.CreditCardService].ServiceProgramProcedure
GO

--***********************************************************************************************
--* Create the assembly that implements the service program for the "InventoryService" service
--***********************************************************************************************
CREATE ASSEMBLY [InventoryServiceLibrary]
FROM 'D:\Klaus\Work\Private\Apress\Pro SQL 2005 Service Broker\Chapter 9\Samples\03 Managed Service Program\InventoryServiceLibrary\bin\Debug\InventoryServiceLibrary.dll'
GO

ALTER ASSEMBLY [InventoryServiceLibrary]
ADD FILE FROM 'D:\Klaus\Work\Private\Apress\Pro SQL 2005 Service Broker\Chapter 9\Samples\03 Managed Service Program\InventoryServiceLibrary\bin\Debug\InventoryServiceLibrary.pdb'
GO

--*******************************************************************
--*  Register the managed service program for the InventoryService
--*******************************************************************
CREATE PROCEDURE InventoryServiceProcedure
AS
EXTERNAL NAME [InventoryServiceLibrary].[InventoryServiceLibrary.InventoryService].ServiceProgramProcedure
GO

--***********************************************************************************************
--* Create the assembly that implements the service program for the "ShippingService" service
--***********************************************************************************************
CREATE ASSEMBLY [ShippingServiceLibrary]
FROM 'D:\Klaus\Work\Private\Apress\Pro SQL 2005 Service Broker\Chapter 9\Samples\03 Managed Service Program\ShippingServiceLibrary\bin\Debug\ShippingServiceLibrary.dll'
GO

ALTER ASSEMBLY [ShippingServiceLibrary]
ADD FILE FROM 'D:\Klaus\Work\Private\Apress\Pro SQL 2005 Service Broker\Chapter 9\Samples\03 Managed Service Program\ShippingServiceLibrary\bin\Debug\ShippingServiceLibrary.pdb'
GO

--*******************************************************************
--*  Register the managed service program for the ShippingService
--*******************************************************************
CREATE PROCEDURE ShippingServiceProcedure
AS
EXTERNAL NAME [ShippingServiceLibrary].[ShippingServiceLibrary.ShippingService].ServiceProgramProcedure
GO

--***********************************************************************************************
--* Create the assembly that implements the service program for the "ClientService" service
--***********************************************************************************************
CREATE ASSEMBLY [ClientServiceLibrary]
FROM 'D:\Klaus\Work\Private\Apress\Pro SQL 2005 Service Broker\Chapter 9\Samples\03 Managed Service Program\ClientServiceLibrary\bin\Debug\ClientServiceLibrary.dll'
GO

ALTER ASSEMBLY [ClientServiceLibrary]
ADD FILE FROM 'D:\Klaus\Work\Private\Apress\Pro SQL 2005 Service Broker\Chapter 9\Samples\03 Managed Service Program\ClientServiceLibrary\bin\Debug\ClientServiceLibrary.pdb'
GO

--*******************************************************************
--*  Register the managed service program for the ClientService
--*******************************************************************
CREATE PROCEDURE ClientServiceProcedure
AS
EXTERNAL NAME [ClientServiceLibrary].[ClientServiceLibrary.ClientService].ServiceProgramProcedure
GO

--**********************************************************
--*  Activate internal activation on the "OrderQueue" queue
--**********************************************************
ALTER QUEUE OrderQueue
WITH ACTIVATION
(
	STATUS = ON,
	PROCEDURE_NAME = OrderServiceProcedure,
	MAX_QUEUE_READERS = 1,
	EXECUTE AS SELF
)
GO

----****************************************************************
----*  Activate internal activation on the "AccountingQueue" queue
----****************************************************************
ALTER QUEUE AccountingQueue
WITH ACTIVATION
(
	STATUS = ON,
	PROCEDURE_NAME = AccountingServiceProcedure,
	MAX_QUEUE_READERS = 1,
	EXECUTE AS SELF
)
GO

----****************************************************************
----*  Activate internal activation on the "CreditCardQueue" queue
----****************************************************************
ALTER QUEUE CreditCardQueue
WITH ACTIVATION
(
	STATUS = ON,
	PROCEDURE_NAME = CreditCardServiceProcedure,
	MAX_QUEUE_READERS = 1,
	EXECUTE AS SELF
)
GO

----****************************************************************
----*  Activate internal activation on the "InventoryQueue" queue
----****************************************************************
ALTER QUEUE InventoryQueue
WITH ACTIVATION
(
	STATUS = ON,
	PROCEDURE_NAME = InventoryServiceProcedure,
	MAX_QUEUE_READERS = 1,
	EXECUTE AS SELF
)
GO

----****************************************************************
----*  Activate internal activation on the "ShippingQueue" queue
----****************************************************************
ALTER QUEUE ShippingQueue
WITH ACTIVATION
(
	STATUS = ON,
	PROCEDURE_NAME = ShippingServiceProcedure,
	MAX_QUEUE_READERS = 1,
	EXECUTE AS SELF
)
GO

--**********************************************************
--*  Activate internal activation on the queue ClientQueue
--**********************************************************
ALTER QUEUE ClientQueue
WITH ACTIVATION
(
	STATUS = ON,
	PROCEDURE_NAME = ClientServiceProcedure,
	MAX_QUEUE_READERS = 1,
	EXECUTE AS SELF
)
GO

--********************************************************************************************
--*  Create a table that stores the accounting recordings submitted to the AccountingService
--********************************************************************************************
CREATE TABLE AccountingRecordings
(
	AccountingRecordingsID UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
	CustomerID NVARCHAR(10) NOT NULL,
	Amount DECIMAL(18, 2) NOT NULL
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

--***********************************************************************************************
--*  Create a table that stores the inventory that is recalculated through the InventoryService
--***********************************************************************************************
CREATE TABLE Inventory
(
	ProductID NVARCHAR(10) NOT NULL PRIMARY KEY,
	Quantity INT NOT NULL
)
GO

-- ****************************************************
-- * Insert some sample data into the Inventory table
-- ****************************************************
INSERT INTO Inventory (ProductID, Quantity) VALUES ('123', 50)
INSERT INTO Inventory (ProductID, Quantity) VALUES ('456', 80)
INSERT INTO Inventory (ProductID, Quantity) VALUES ('789', 563)
GO

--*********************************************************************************
--*  Create a table that stores the shipping information from the ShippingService
--*********************************************************************************
CREATE TABLE ShippingInformation
(
	ShippingID UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
	[Name] NVARCHAR(256) NOT NULL,
	Address NVARCHAR(256) NOT NULL,
	ZipCode NVARCHAR(10) NOT NULL,
	City NVARCHAR(256) NOT NULL,
	Country NVARCHAR(256) NOT NULL	
)
GO

--***************************************************************************************************
--*  Send a message to start the conversation with the distributed deployed Service Broker services
--***************************************************************************************************
EXEC SendOrderRequestMessage
'<OrderRequest><Customer>
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
</OrderRequest>'
GO

select * from inventory

exec OrderServiceProcedure

-- {bd7d83e2-b596-db11-813e-0014c2e615aa} cg

exec AccountingServiceProcedure

select cast(message_body as xml), * from orderqueue

select * from applicationstate

select * from accountingqueue

select * from clientqueue





select cast(message_body as xml), * from accountingqueue

select * from accountingrecordings

select * from creditcardtransactions

select * from shippinginformation


select * from sys.conversation_endpoints

select * from sys.service_queues

select cast(message_body as xml), * from sys.transmission_queue













select cast(message_body as xml), * from orderqueue
order by queuing_order

select * from clientqueue

processorderrequestmessages

select * from sys.conversation_endpoints

select * from sys.service_queues

select cast(message_body as xml), * from sys.transmission_queue

select * from sys.transmission_queue
where to_service_name = 'CreditCardService'

select * from applicationstate

select * from sys.routes