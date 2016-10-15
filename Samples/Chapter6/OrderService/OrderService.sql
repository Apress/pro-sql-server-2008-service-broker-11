USE master;

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'Chapter6_OrderService')
BEGIN
	PRINT 'Dropping database ''Chapter6_OrderService''';
	DROP DATABASE Chapter6_OrderService;
END
GO

CREATE DATABASE Chapter6_OrderService
GO

USE Chapter6_OrderService
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
CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c06/OrderRequestMessage] VALIDATION = WELL_FORMED_XML
CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c06/OrderResponseMessage] VALIDATION = WELL_FORMED_XML
GO

--*****************************************************************
--*  Create the contract between the client and the Order Service
--*****************************************************************
CREATE CONTRACT [http://ssb.csharp.at/SSB_Book/c06/OrderContract]
(
	[http://ssb.csharp.at/SSB_Book/c06/OrderRequestMessage] SENT BY INITIATOR,
	[http://ssb.csharp.at/SSB_Book/c06/OrderResponseMessage] SENT BY TARGET
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
	[http://ssb.csharp.at/SSB_Book/c06/OrderContract]
)
GO

CREATE SERVICE OrderService
ON QUEUE OrderQueue
(
	[http://ssb.csharp.at/SSB_Book/c06/OrderContract]
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
CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c06/CreditCardRequestMessage] VALIDATION = WELL_FORMED_XML
CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c06/CreditCardResponseMessage] VALIDATION = WELL_FORMED_XML
GO

--***************************************************************************
--*  Create the contract between the OrderService and the CreditCardService
--***************************************************************************
CREATE CONTRACT [http://ssb.csharp.at/SSB_Book/c06/CreditCardContract]
(
	[http://ssb.csharp.at/SSB_Book/c06/CreditCardRequestMessage] SENT BY INITIATOR,
	[http://ssb.csharp.at/SSB_Book/c06/CreditCardResponseMessage] SENT BY TARGET
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
	[http://ssb.csharp.at/SSB_Book/c06/CreditCardContract]
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
CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c06/AccountingRequestMessage] VALIDATION = WELL_FORMED_XML
CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c06/AccountingResponseMessage] VALIDATION = WELL_FORMED_XML
GO

--***************************************************************************
--*  Create the contract between the OrderService and the AccountingService
--***************************************************************************
CREATE CONTRACT [http://ssb.csharp.at/SSB_Book/c06/AccountingContract]
(
	[http://ssb.csharp.at/SSB_Book/c06/AccountingRequestMessage] SENT BY INITIATOR,
	[http://ssb.csharp.at/SSB_Book/c06/AccountingResponseMessage] SENT BY TARGET
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
	[http://ssb.csharp.at/SSB_Book/c06/AccountingContract]
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
CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c06/InventoryRequestMessage] VALIDATION = WELL_FORMED_XML
CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c06/InventoryResponseMessage] VALIDATION = WELL_FORMED_XML
GO

--**************************************************************************
--*  Create the contract between the OrderService and the InventoryService
--**************************************************************************
CREATE CONTRACT [http://ssb.csharp.at/SSB_Book/c06/InventoryContract]
(
	[http://ssb.csharp.at/SSB_Book/c06/InventoryRequestMessage] SENT BY INITIATOR,
	[http://ssb.csharp.at/SSB_Book/c06/InventoryResponseMessage] SENT BY TARGET
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
	[http://ssb.csharp.at/SSB_Book/c06/InventoryContract]
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
CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c06/ShippingRequestMessage] VALIDATION = WELL_FORMED_XML
CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c06/ShippingResponseMessage] VALIDATION = WELL_FORMED_XML
GO

--**************************************************************************
--*  Create the contract between the OrderService and the ShippingService
--**************************************************************************
CREATE CONTRACT [http://ssb.csharp.at/SSB_Book/c06/ShippingContract]
(
	[http://ssb.csharp.at/SSB_Book/c06/ShippingRequestMessage] SENT BY INITIATOR,
	[http://ssb.csharp.at/SSB_Book/c06/ShippingResponseMessage] SENT BY TARGET
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
	[http://ssb.csharp.at/SSB_Book/c06/ShippingContract]
)
GO

--****************************************************************************
-- * Create the message processing logic for the OrderService.
-- * The OrderService send parallel messages out to the CreditCardService,
-- * the AccountingService and the InventoryService. Furthermore the
-- * state of the current conversation group is hold in a state table
-- * managed by the OrderService.
--****************************************************************************

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

--***************************************************************************
--*  Service program that processes incoming order messages from the client
--***************************************************************************
CREATE PROCEDURE ProcessOrderRequestMessages
AS
BEGIN
	DECLARE @conversationGroup UNIQUEIDENTIFIER;
	DECLARE @CreditCardStatus BIT;
	DECLARE @AccountingStatus BIT;
	DECLARE @InventoryStatus BIT;
	DECLARE @ShippingMessageSent BIT;
	DECLARE @ShippingStatus BIT;
	
	-- Outer Loop (State Handling)
	WHILE (1 = 1)
	BEGIN
		BEGIN TRANSACTION;

		-- Retrieve the next conversation group where messages are available for processing
		WAITFOR (
			GET CONVERSATION GROUP @conversationGroup FROM [OrderQueue]
		), TIMEOUT 1000

		IF (@@ROWCOUNT = 0)
		BEGIN
			ROLLBACK TRANSACTION
			BREAK
		END

		-- Retrieve the application state for the current conversation group
		SELECT 
			@CreditCardStatus = CreditCardStatus,
			@AccountingStatus = AccountingStatus,
			@InventoryStatus = InventoryStatus,
			@ShippingMessageSent = ShippingMessageSent,
			@ShippingStatus = ShippingStatus
		FROM ApplicationState
		WHERE ConversationGroupID = @conversationGroup;

		IF (@@ROWCOUNT = 0)
		BEGIN
			-- There is currently no application state available, so we insert the initial application state into the state table
			SET @CreditCardStatus = 0;
			SET @AccountingStatus = 0;
			SET @InventoryStatus = 0;
			SET @ShippingMessageSent = 0;
			SET @ShippingStatus = 0;
		
			-- Insert the new state record
			INSERT INTO ApplicationState (ConversationGroupID, CreditCardStatus, AccountingStatus, InventoryStatus, ShippingMessageSent, ShippingStatus)
			VALUES
			(
				@conversationGroup,
				@CreditCardStatus,
				@AccountingStatus,
				@InventoryStatus,
				@ShippingMessageSent,
				@ShippingStatus
			)
		END

		DECLARE @messageTypeName NVARCHAR(256);
		DECLARE @ch UNIQUEIDENTIFIER;
		DECLARE @messageBody XML;

		-- Inner Loop (Message Processing)
		WHILE (1 = 1)
		BEGIN
			WAITFOR (
				RECEIVE TOP (1)
					@messageTypeName = message_type_name,
					@messageBody = CAST(message_body AS XML),
					@ch = conversation_handle
				FROM [OrderQueue]
				WHERE conversation_group_id = @conversationGroup
			), TIMEOUT 1000

			IF (@@ROWCOUNT = 0)
			BEGIN
				BREAK
			END

			-- Process the OrderRequestMessage sent from the ClientService
			IF (@messageTypeName = 'http://ssb.csharp.at/SSB_Book/c06/OrderRequestMessage')
			BEGIN
				-- Variables for the conversation handles and the messages to be sent
				DECLARE @chCreditCardService UNIQUEIDENTIFIER;
				DECLARE @chAccountingService UNIQUEIDENTIFIER;
				DECLARE @chInventoryService UNIQUEIDENTIFIER;
				DECLARE @msgCreditCardService NVARCHAR(MAX);
				DECLARE @msgAccountingService NVARCHAR(MAX);
				DECLARE @msgInventoryService NVARCHAR(MAX);

				-- Variables needed to store the information extracted from the OrderRequestMessage
				DECLARE @creditCardHolder NVARCHAR(256);
				DECLARE @creditCardNumber NVARCHAR(256);
				DECLARE @validThrough NVARCHAR(10);
				DECLARE @quantity INT;
				DECLARE @price DECIMAL(18, 2);
				DECLARE @amount DECIMAL(18, 2);
				DECLARE @customerID NVARCHAR(256);
				DECLARE @productID INT;

				-- Extract the necessary information from the OrderRequestMessage
				SET @creditCardHolder = @messagebody.value('/OrderRequest[1]/CreditCard[1]/Holder[1]', 'NVARCHAR(256)');
				SET @creditCardNumber = @messagebody.value('/OrderRequest[1]/CreditCard[1]/Number[1]', 'NVARCHAR(256)');
				SET @validThrough = @messagebody.value('/OrderRequest[1]/CreditCard[1]/ValidThrough[1]', 'NVARCHAR(256)');
				SET @quantity = @messagebody.value('/OrderRequest[1]/Product[1]/Quantity[1]', 'INT');
				SET @price = @messagebody.value('/OrderRequest[1]/Product[1]/Price[1]', 'DECIMAL(18, 2)');
				SET @amount = @quantity * @price;
				SET @customerID = @messagebody.value('/OrderRequest[1]/Customer[1]/CustomerID[1]', 'NVARCHAR(256)');
				SET @productID = @messagebody.value('/OrderRequest[1]/Product[1]/ProductID[1]', 'INT');

				-- Begin a new conversation with the CreditCardService on the same conversation group
				BEGIN DIALOG CONVERSATION @chCreditCardService
					FROM SERVICE [OrderService]
					TO SERVICE 'CreditCardService'
					ON CONTRACT [http://ssb.csharp.at/SSB_Book/c06/CreditCardContract]
					WITH RELATED_CONVERSATION = @ch, ENCRYPTION = OFF;

				-- Send a CreditCardRequestMessage to the CreditCardService
				SET @msgCreditCardService = 
					'<CreditCardRequest>
						<Holder>' + @creditCardHolder  + '</Holder>
						<Number>' + @creditCardNumber + '</Number>
						<ValidThrough>' + @validThrough + '</ValidThrough>
						<Amount>' + CAST(@amount AS NVARCHAR(10)) + '</Amount>
					</CreditCardRequest>';

				SEND ON CONVERSATION @chCreditCardService MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c06/CreditCardRequestMessage] (@msgCreditCardService);

				-- Begin a new conversation with the AccountingService on the same conversation group
				BEGIN DIALOG CONVERSATION @chAccountingService
					FROM SERVICE [OrderService]
					TO SERVICE 'AccountingService'
					ON CONTRACT [http://ssb.csharp.at/SSB_Book/c06/AccountingContract]
					WITH RELATED_CONVERSATION = @ch, ENCRYPTION = OFF;

				-- Send a message to the AccountingService
				SET @msgAccountingService = 
					'<AccountingRequest>
						<CustomerID>' + @customerID + '</CustomerID>
						<Amount>' + CAST(@amount AS NVARCHAR(10)) + '</Amount>
					</AccountingRequest>';

				SEND ON CONVERSATION @chAccountingService MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c06/AccountingRequestMessage] (@msgAccountingService);

				-- Begin a new conversation with the InventoryService on the same conversation group
				BEGIN DIALOG CONVERSATION @chInventoryService
					FROM SERVICE [OrderService]
					TO SERVICE 'InventoryService'
					ON CONTRACT [http://ssb.csharp.at/SSB_Book/c06/InventoryContract]
					WITH RELATED_CONVERSATION = @ch, ENCRYPTION = OFF;

				-- Send a message to the CreditCardService
				SET @msgInventoryService = 
					'<InventoryRequest>
						<ProductID>' + CAST(@productID AS NVARCHAR(10)) + '</ProductID>
						<Quantity>' + CAST(@quantity AS NVARCHAR(10)) + '</Quantity>
					</InventoryRequest>';

				SEND ON CONVERSATION @chInventoryService MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c06/InventoryRequestMessage] (@msgInventoryService);
			END

			-- Process the CreditCardResponseMessage sent from the CreditCardService
			IF (@messageTypeName = 'http://ssb.csharp.at/SSB_Book/c06/CreditCardResponseMessage')
			BEGIN
				DECLARE @creditCardResult BIT;

				SET @creditCardResult = @messageBody.value('/CreditCardResponse[1]', 'BIT');

				-- Updating the state information, indicating that the CreditCardService was called
				SET @CreditCardStatus = 1;
			END

			-- Process the AccountingResponseMessage sent from the AccountingService
			IF (@messageTypeName = 'http://ssb.csharp.at/SSB_Book/c06/AccountingResponseMessage')
			BEGIN
				DECLARE @accountingResult BIT;

				SET @accountingResult = @messageBody.value('/AccountingResponse[1]', 'BIT');

				-- Updating the state information, indicating that the AccountingService was called
				SET @AccountingStatus = 1;
			END

			-- Process the InventoryResponseMessage sent from the InventoryService
			IF (@messageTypeName = 'http://ssb.csharp.at/SSB_Book/c06/InventoryResponseMessage')
			BEGIN
				DECLARE @inventoryResult BIT;
					
				SET @inventoryResult = @messageBody.value('/InventoryResponse[1]', 'BIT');

				-- Updating the state information indicating that the InventoryService was called
				SET @InventoryStatus = 1;
			END

			-- Process the ShippingResponseMessage sent from the ShippingService
			IF (@messageTypeName = 'http://ssb.csharp.at/SSB_Book/c06/ShippingResponseMessage')
			BEGIN
				DECLARE @shippingResult BIT;
				DECLARE @orderResponseMessage NVARCHAR(MAX);
				DECLARE @chClientService UNIQUEIDENTIFIER;

				-- Create the response message for the ClientService
				SET @shippingResult = @messageBody.value('/ShippingResponse[1]', 'BIT');
				SET @orderResponseMessage = '<OrderResponse>' + CAST(@shippingResult AS CHAR(1)) + '</OrderResponse>';

				-- The order was shipped
				SET @ShippingStatus = 1;

				-- Get the conversation handle, that is needed to send a response message back to the ClientService
				SELECT @chClientService = conversation_handle FROM sys.conversation_endpoints
				WHERE 
					conversation_group_id = @conversationGroup AND
					far_service = 'ClientService';

				-- Send the response message back to the ClientService
				SEND ON CONVERSATION @chClientService MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c06/OrderResponseMessage] (@orderResponseMessage);

				-- End the conversation with the ClientService
				END CONVERSATION @chClientService;
			END

			-- If we received all response messages from the other service we can send the final message
			-- to the ShippingService
			IF (@CreditCardStatus = 1 AND @AccountingStatus = 1 AND @InventoryStatus = 1 AND @ShippingMessageSent = 0)
			BEGIN
				DECLARE @chShippingService UNIQUEIDENTIFIER;
				DECLARE @msgShippingService NVARCHAR(MAX);

				-- Begin a new conversation with the ShippingService on the same conversation group
				BEGIN DIALOG CONVERSATION @chShippingService
					FROM SERVICE [OrderService]
					TO SERVICE 'ShippingService'
					ON CONTRACT [http://ssb.csharp.at/SSB_Book/c06/ShippingContract]
					WITH RELATED_CONVERSATION = @ch, ENCRYPTION = OFF;

				-- Send the request message to the ShippingService
				DECLARE @msg XML;

				-- SELECT the original order request message from the OrderQueue - RETENTION makes it possible
				SELECT @msg = CAST(message_body AS XML) FROM OrderQueue
				WHERE
					conversation_group_id = @conversationGroup AND
					message_type_name = 'http://ssb.csharp.at/SSB_Book/c06/OrderRequestMessage';
				SET @msgShippingService = CAST(@msg.query('/OrderRequest[1]/Shipping[1]') AS NVARCHAR(MAX));

				SEND ON CONVERSATION @chShippingService MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c06/ShippingRequestMessage] (@msgShippingService);

				SET @ShippingMessageSent = 1;
			END

			IF (@messageTypeName = 'http://schemas.microsoft.com/SQL/ServiceBroker/Error')
			BEGIN
				-- Handle errors
				END CONVERSATION @ch;
			END

			IF (@messageTypeName = 'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog')
			BEGIN
				END CONVERSATION @ch;
			END
		END

		-- Update the application state
		UPDATE ApplicationState SET
			CreditCardStatus = @CreditCardStatus,
			AccountingStatus = @AccountingStatus,
			InventoryStatus = @InventoryStatus,
			ShippingMessageSent = @ShippingMessageSent,
			ShippingStatus = @ShippingStatus
		WHERE ConversationGroupID = @conversationGroup;

		-- Commit the whole transaction
		COMMIT TRANSACTION;
	END
END
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

		IF (@messagetypename = 'http://ssb.csharp.at/SSB_Book/c06/CreditCardRequestMessage')
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
			SEND ON CONVERSATION @ch MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c06/CreditCardResponseMessage] (@responsemessage);

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

		IF (@messagetypename = 'http://ssb.csharp.at/SSB_Book/c06/AccountingRequestMessage')
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
			SEND ON CONVERSATION @ch MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c06/AccountingResponseMessage] (@responsemessage);

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

		IF (@messagetypename = 'http://ssb.csharp.at/SSB_Book/c06/InventoryRequestMessage')
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
				SEND ON CONVERSATION @ch MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c06/InventoryResponseMessage] (@responsemessage);

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
				SEND ON CONVERSATION @ch MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c06/InventoryResponseMessage] (@responsemessage);

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

		IF (@messagetypename = 'http://ssb.csharp.at/SSB_Book/c06/ShippingRequestMessage')
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
			SEND ON CONVERSATION @ch MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c06/ShippingResponseMessage] (@responsemessage);

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

		IF (@messagetypename = 'http://ssb.csharp.at/SSB_Book/c06/OrderResponseMessage')
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

--**********************************************************
--*  Activate internal activation on the queue OrderQueue
--**********************************************************
ALTER QUEUE OrderQueue
WITH ACTIVATION
(
	STATUS = ON,
	PROCEDURE_NAME = ProcessOrderRequestMessages,
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
		ON CONTRACT [http://ssb.csharp.at/SSB_Book/c06/OrderContract]
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

	SEND ON CONVERSATION @ch MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c06/OrderRequestMessage] (@msg);
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

select * from ApplicationState
