USE master;

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'Chapter10_OrderServiceWithWorkflow')
BEGIN
	PRINT 'Dropping database ''Chapter10_OrderServiceWithWorkflow''';
	DROP DATABASE Chapter10_OrderServiceWithWorkflow;
END
GO

CREATE DATABASE Chapter10_OrderServiceWithWorkflow
GO

USE Chapter10_OrderServiceWithWorkflow
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
CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c10/OrderRequestMessage] VALIDATION = WELL_FORMED_XML
CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c10/OrderResponseMessage] VALIDATION = WELL_FORMED_XML
GO

--*****************************************************************
--*  Create the contract between the client and the Order Service
--*****************************************************************
CREATE CONTRACT [http://ssb.csharp.at/SSB_Book/c10/OrderContract]
(
	[http://ssb.csharp.at/SSB_Book/c10/OrderRequestMessage] SENT BY INITIATOR,
	[http://ssb.csharp.at/SSB_Book/c10/OrderResponseMessage] SENT BY TARGET
)
GO

--***************************************************************
--*  Create the queues "ClientQueue" and "OrderQueue"
--***************************************************************
CREATE QUEUE ClientQueue WITH STATUS = ON
GO

CREATE QUEUE OrderQueue WITH STATUS = ON, RETENTION = ON
GO

--************************************************************
--*  Create the queues "ClientService" and "TargetService"
--************************************************************
CREATE SERVICE ClientService
ON QUEUE ClientQueue 
(
	[http://ssb.csharp.at/SSB_Book/c10/OrderContract]
)
GO

CREATE SERVICE OrderService
ON QUEUE OrderQueue
(
	[http://ssb.csharp.at/SSB_Book/c10/OrderContract]
)
GO

--**************************************************************************************
-- * Create all objects necessary for the communication between the
-- * OrderService and the CreditCardService. The CreditCardService
-- * draws the specified credit card with the provided amount.
--**************************************************************************************

--***************************************************************************************
--*  Create the needed message types between the OrderService and the CreditCardService
--***************************************************************************************
CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c10/CreditCardRequestMessage] VALIDATION = WELL_FORMED_XML
CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c10/CreditCardResponseMessage] VALIDATION = WELL_FORMED_XML
GO

--***************************************************************************
--*  Create the contract between the OrderService and the CreditCardService
--***************************************************************************
CREATE CONTRACT [http://ssb.csharp.at/SSB_Book/c10/CreditCardContract]
(
	[http://ssb.csharp.at/SSB_Book/c10/CreditCardRequestMessage] SENT BY INITIATOR,
	[http://ssb.csharp.at/SSB_Book/c10/CreditCardResponseMessage] SENT BY TARGET
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
	[http://ssb.csharp.at/SSB_Book/c10/CreditCardContract]
)
GO

--****************************************************************************
-- * Create all objects necessary for the communication between the
-- * OrderService and the AccountingService. The AccountingService
-- * creates an accounting transaction that is stored in a accounting table.
--****************************************************************************

--***************************************************************************************
--*  Create the needed message types between the OrderService and the AccountingService
--***************************************************************************************
CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c10/AccountingRequestMessage] VALIDATION = WELL_FORMED_XML
CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c10/AccountingResponseMessage] VALIDATION = WELL_FORMED_XML
GO

--***************************************************************************
--*  Create the contract between the OrderService and the AccountingService
--***************************************************************************
CREATE CONTRACT [http://ssb.csharp.at/SSB_Book/c10/AccountingContract]
(
	[http://ssb.csharp.at/SSB_Book/c10/AccountingRequestMessage] SENT BY INITIATOR,
	[http://ssb.csharp.at/SSB_Book/c10/AccountingResponseMessage] SENT BY TARGET
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
	[http://ssb.csharp.at/SSB_Book/c10/AccountingContract]
)
GO

--****************************************************************************
-- * Create all objects necessary for the communication between the
-- * OrderService and the InventoryService. The InventoryService
-- * substracts the quantity of the ordered product from an inventory table.
--****************************************************************************

--**************************************************************************************
--*  Create the needed message types between the OrderService and the InventoryService
--**************************************************************************************
CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c10/InventoryRequestMessage] VALIDATION = WELL_FORMED_XML
CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c10/InventoryResponseMessage] VALIDATION = WELL_FORMED_XML
GO

--**************************************************************************
--*  Create the contract between the OrderService and the InventoryService
--**************************************************************************
CREATE CONTRACT [http://ssb.csharp.at/SSB_Book/c10/InventoryContract]
(
	[http://ssb.csharp.at/SSB_Book/c10/InventoryRequestMessage] SENT BY INITIATOR,
	[http://ssb.csharp.at/SSB_Book/c10/InventoryResponseMessage] SENT BY TARGET
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
	[http://ssb.csharp.at/SSB_Book/c10/InventoryContract]
)
GO

--****************************************************************************
-- * Create all objects necessary for the communication between the
-- * OrderService and the ShippingService. The ShippingService
-- * adds the order information to a shipping table
--****************************************************************************

--**************************************************************************************
--*  Create the needed message types between the OrderService and the ShippingServicee
--**************************************************************************************
CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c10/ShippingRequestMessage] VALIDATION = WELL_FORMED_XML
CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c10/ShippingResponseMessage] VALIDATION = WELL_FORMED_XML
GO

--**************************************************************************
--*  Create the contract between the OrderService and the ShippingService
--**************************************************************************
CREATE CONTRACT [http://ssb.csharp.at/SSB_Book/c10/ShippingContract]
(
	[http://ssb.csharp.at/SSB_Book/c10/ShippingRequestMessage] SENT BY INITIATOR,
	[http://ssb.csharp.at/SSB_Book/c10/ShippingResponseMessage] SENT BY TARGET
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
	[http://ssb.csharp.at/SSB_Book/c10/ShippingContract]
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

		IF (@messagetypename = 'http://ssb.csharp.at/SSB_Book/c10/CreditCardRequestMessage')
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
			SEND ON CONVERSATION @ch MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c10/CreditCardResponseMessage] (@responsemessage);

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

--*********************************************************************************************************
--*  Create the stored procedure that processes the AccountingRequest messages from the AccountingService
--*********************************************************************************************************
CREATE PROCEDURE ProcessAccountingRequestMessages
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
				AccountingQueue
		), TIMEOUT 1000

		IF (@@ROWCOUNT = 0)
		BEGIN
			ROLLBACK TRANSACTION
			BREAK
		END

		IF (@messagetypename = 'http://ssb.csharp.at/SSB_Book/c10/AccountingRequestMessage')
		BEGIN
			-- Create a new booking record
			INSERT INTO AccountingRecordings (AccountingRecordingsID, CustomerID, Amount) 
			VALUES 
			(
				NEWID(), 
				@messagebody.value('/AccountingRequest[1]/CustomerID[1]', 'NVARCHAR(10)'),
				@messagebody.value('/AccountingRequest[1]/Amount[1]', 'DECIMAL(18, 2)')
			)

			-- Construct the response message
			SET @responsemessage = '<AccountingResponse>1</AccountingResponse>';

			-- Send the response message back to the OrderService
			SEND ON CONVERSATION @ch MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c10/AccountingResponseMessage] (@responsemessage);

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

--*********************************************************************************************************
--*  Create the stored procedure that processes the InventoryRequest messages from the InventoryService
--*********************************************************************************************************
CREATE PROCEDURE ProcessInventoryRequestMessages
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
				InventoryQueue
		), TIMEOUT 1000

		IF (@@ROWCOUNT = 0)
		BEGIN
			ROLLBACK TRANSACTION
			BREAK
		END

		IF (@messagetypename = 'http://ssb.csharp.at/SSB_Book/c10/InventoryRequestMessage')
		BEGIN
			DECLARE @productID NVARCHAR(10);
			DECLARE	@oldQuantity INT;
			DECLARE @newQuantity INT;
			DECLARE @quantity INT;

			-- Check if there is enough quantity of the specified product in stock
			SET @productID = @messagebody.value('/InventoryRequest[1]/ProductID[1]', 'NVARCHAR(10)');
			SET @quantity = @messagebody.value('/InventoryRequest[1]/Quantity[1]', 'INT');
			SELECT @oldQuantity = Quantity FROM Inventory WHERE ProductID = @productID;

			SET @newQuantity = @oldQuantity - @quantity;

			IF (@newQuantity <= 0)
			BEGIN
				-- There is not enough quantity of the specified product in stock
				SET @responsemessage = '<InventoryResponse>0</InventoryResponse>';

				-- Send the response message back to the OrderService
				SEND ON CONVERSATION @ch MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c10/InventoryResponseMessage] (@responsemessage);

				-- End the conversation on the target's side
				END CONVERSATION @ch;
			END
			ELSE
			BEGIN
				-- Update the inventory with the new quantity of the specified product
				UPDATE Inventory SET Quantity = @newQuantity WHERE ProductID = @productID;

				-- There is enough quantity of the specified product in stock
				SET @responsemessage = '<InventoryResponse>1</InventoryResponse>';

				-- Send the response message back to the OrderService
				SEND ON CONVERSATION @ch MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c10/InventoryResponseMessage] (@responsemessage);

				-- End the conversation on the target's side
				END CONVERSATION @ch;
			END
		END

		IF (@messagetypename = 'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog')
		BEGIN
			-- End the conversation
			END CONVERSATION @ch;
		END

		COMMIT TRANSACTION
	END
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

--*********************************************************************************************************
--*  Create the stored procedure that processes the ShippingRequest messages from the ShippingService
--*********************************************************************************************************
CREATE PROCEDURE ProcessShippingRequestMessages
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
				ShippingQueue
		), TIMEOUT 1000

		IF (@@ROWCOUNT = 0)
		BEGIN
			ROLLBACK TRANSACTION
			BREAK
		END

		IF (@messagetypename = 'http://ssb.csharp.at/SSB_Book/c10/ShippingRequestMessage')
		BEGIN
			DECLARE @name NVARCHAR(256);
			DECLARE @address NVARCHAR(256);
			DECLARE @zipCode NVARCHAR(10);
			DECLARE @city NVARCHAR(256);
			DECLARE @country NVARCHAR(256);

			-- Extract the information from the ShippingRequestMessage
			SET @name = @messagebody.value('/Shipping[1]/Name[1]', 'NVARCHAR(256)');
			SET @address = @messagebody.value('/Shipping[1]/Address[1]', 'NVARCHAR(256)');
			SET @zipCode = @messagebody.value('/Shipping[1]/ZipCode[1]', 'NVARCHAR(10)');
			SET @city = @messagebody.value('/Shipping[1]/City[1]', 'NVARCHAR(256)');
			SET @country = @messagebody.value('/Shipping[1]/Country[1]', 'NVARCHAR(256)');

			-- Insert the information into the shipping table
			INSERT INTO ShippingInformation (ShippingID, [Name], Address, ZipCode, City, Country)
			VALUES
			(
				NEWID(),
				@name,
				@address,
				@zipCode,
				@city,
				@country
			)

			-- Send the response message back to the OrderService
			SET @responsemessage = '<ShippingResponse>1</ShippingResponse>';
			SEND ON CONVERSATION @ch MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c10/ShippingResponseMessage] (@responsemessage);

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
END
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
				ClientQueue
		), TIMEOUT 1000

		IF (@@ROWCOUNT = 0)
		BEGIN
			ROLLBACK TRANSACTION
			BREAK
		END

		IF (@messagetypename = 'http://ssb.csharp.at/SSB_Book/c10/OrderResponseMessage')
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

--**************************************************************
--*  Activate internal activation on the queue AccountingQueue
--**************************************************************
ALTER QUEUE AccountingQueue
WITH ACTIVATION
(
	STATUS = ON,
	PROCEDURE_NAME = ProcessAccountingRequestMessages,
	MAX_QUEUE_READERS = 1,
	EXECUTE AS SELF
)
GO

--*************************************************************
--*  Activate internal activation on the queue InventoryQueue
--*************************************************************
ALTER QUEUE InventoryQueue
WITH ACTIVATION
(
	STATUS = ON,
	PROCEDURE_NAME = ProcessInventoryRequestMessages,
	MAX_QUEUE_READERS = 1,
	EXECUTE AS SELF
)
GO

--************************************************************
--*  Activate internal activation on the queue ShippingQueue
--************************************************************
ALTER QUEUE ShippingQueue
WITH ACTIVATION
(
	STATUS = ON,
	PROCEDURE_NAME = ProcessShippingRequestMessages,
	MAX_QUEUE_READERS = 1,
	EXECUTE AS SELF
)
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
		ON CONTRACT [http://ssb.csharp.at/SSB_Book/c10/OrderContract]
		WITH ENCRYPTION = OFF;

	SET @msg = 
		'<OrderRequest>
				<Customer>
					<CustomerID>4242</CustomerID>
				</Customer>
				<Product>
					<ProductID>123</ProductID>
					<Quantity>5</Quantity>
					<Price>41</Price>
				</Product>
				<CreditCard>
					<Holder>Klaus Aschenbrenner</Holder>
					<Number>1234-1234-1234-1234</Number>
					<ValidThrough>2009-10</ValidThrough>
				</CreditCard>
				<Shipping>
					<Name>Klaus Aschenbrenner</Name>
					<Address>Pichlgasse 16/6</Address>
					<ZipCode>1220</ZipCode>
					<City>Vienna</City>
					<Country>Austria</Country>
				</Shipping>
		</OrderRequest>';

	SEND ON CONVERSATION @ch MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c10/OrderRequestMessage] (@msg);
COMMIT;
GO





exec ProcessOrderRequestMessages
exec ProcessCreditCardRequestMessages
exec ProcessAccountingRequestMessages
exec ProcessInventoryRequestMessages
exec ProcessOrderRequestMessages
exec ProcessShippingRequestMessages
exec ProcessOrderRequestMessages
exec ProcessOrderResponseMessages

select cast(message_body as xml), * from orderqueue
select cast(message_body as xml), * from creditcardqueue
select cast(message_body as xml), * from accountingqueue
select cast(message_body as xml), * from inventoryqueue
select cast(message_body as xml), * from shippingqueue
select cast(message_body as xml), * from clientqueue

select * from CreditCardTransactions
select * from AccountingRecordings
select * from Inventory
select * from ShippingInformation