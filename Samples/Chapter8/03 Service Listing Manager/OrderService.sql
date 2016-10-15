USE master;

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'Chapter8_OrderService')
BEGIN
	PRINT 'Dropping database ''Chapter8_OrderService''';
	DROP DATABASE Chapter8_OrderService;
END
GO

CREATE DATABASE Chapter8_OrderService
GO

USE Chapter8_OrderService
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
CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c08/OrderRequestMessage] VALIDATION = WELL_FORMED_XML
CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c08/OrderResponseMessage] VALIDATION = WELL_FORMED_XML
GO

--*****************************************************************
--*  Create the contract between the client and the Order Service
--*****************************************************************
CREATE CONTRACT [http://ssb.csharp.at/SSB_Book/c08/OrderContract]
(
	[http://ssb.csharp.at/SSB_Book/c08/OrderRequestMessage] SENT BY INITIATOR,
	[http://ssb.csharp.at/SSB_Book/c08/OrderResponseMessage] SENT BY TARGET
)
GO

--***************************************************************************************
--*  Create the needed message types between the OrderService and the AccountingService
--***************************************************************************************
CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c08/AccountingRequestMessage] VALIDATION = WELL_FORMED_XML
CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c08/AccountingResponseMessage] VALIDATION = WELL_FORMED_XML
GO

--***************************************************************************
--*  Create the contract between the OrderService and the AccountingService
--***************************************************************************
CREATE CONTRACT [http://ssb.csharp.at/SSB_Book/c08/AccountingContract]
(
	[http://ssb.csharp.at/SSB_Book/c08/AccountingRequestMessage] SENT BY INITIATOR,
	[http://ssb.csharp.at/SSB_Book/c08/AccountingResponseMessage] SENT BY TARGET
)
GO

--**************************************************************************************
--*  Create the needed message types between the OrderService and the InventoryService
--**************************************************************************************
CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c08/InventoryRequestMessage] VALIDATION = WELL_FORMED_XML
CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c08/InventoryResponseMessage] VALIDATION = WELL_FORMED_XML
GO

--**************************************************************************
--*  Create the contract between the OrderService and the InventoryService
--**************************************************************************
CREATE CONTRACT [http://ssb.csharp.at/SSB_Book/c08/InventoryContract]
(
	[http://ssb.csharp.at/SSB_Book/c08/InventoryRequestMessage] SENT BY INITIATOR,
	[http://ssb.csharp.at/SSB_Book/c08/InventoryResponseMessage] SENT BY TARGET
)
GO

--**************************************************************************************
--*  Create the needed message types between the OrderService and the ShippingServicee
--**************************************************************************************
CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c08/ShippingRequestMessage] VALIDATION = WELL_FORMED_XML
CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c08/ShippingResponseMessage] VALIDATION = WELL_FORMED_XML
GO

--**************************************************************************
--*  Create the contract between the OrderService and the ShippingService
--**************************************************************************
CREATE CONTRACT [http://ssb.csharp.at/SSB_Book/c08/ShippingContract]
(
	[http://ssb.csharp.at/SSB_Book/c08/ShippingRequestMessage] SENT BY INITIATOR,
	[http://ssb.csharp.at/SSB_Book/c08/ShippingResponseMessage] SENT BY TARGET
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
	[http://ssb.csharp.at/SSB_Book/c08/OrderContract]
)
GO

CREATE SERVICE OrderService
ON QUEUE OrderQueue
(
	[http://ssb.csharp.at/SSB_Book/c08/OrderContract]
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

	BEGIN TRY
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
				IF (@messageTypeName = 'http://ssb.csharp.at/SSB_Book/c08/OrderRequestMessage')
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
						ON CONTRACT [http://ssb.csharp.at/SSB_Book/c08/CreditCardContract]
						WITH RELATED_CONVERSATION = @ch, ENCRYPTION = OFF;

					-- Send a CreditCardRequestMessage to the CreditCardService
					SET @msgCreditCardService = 
						'<CreditCardRequest>
							<Holder>' + @creditCardHolder  + '</Holder>
							<Number>' + @creditCardNumber + '</Number>
							<ValidThrough>' + @validThrough + '</ValidThrough>
							<Amount>' + CAST(@amount AS NVARCHAR(10)) + '</Amount>
						</CreditCardRequest>';

					SEND ON CONVERSATION @chCreditCardService MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c08/CreditCardRequestMessage] (@msgCreditCardService);

					-- Begin a new conversation with the AccountingService on the same conversation group
					BEGIN DIALOG CONVERSATION @chAccountingService
						FROM SERVICE [OrderService]
						TO SERVICE 'AccountingService'
						ON CONTRACT [http://ssb.csharp.at/SSB_Book/c08/AccountingContract]
						WITH RELATED_CONVERSATION = @ch, ENCRYPTION = OFF;

					-- Send a message to the AccountingService
					SET @msgAccountingService = 
						'<AccountingRequest>
							<CustomerID>' + @customerID + '</CustomerID>
							<Amount>' + CAST(@amount AS NVARCHAR(10)) + '</Amount>
						</AccountingRequest>';

					SEND ON CONVERSATION @chAccountingService MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c08/AccountingRequestMessage] (@msgAccountingService);

					-- Begin a new conversation with the InventoryService on the same conversation group
					BEGIN DIALOG CONVERSATION @chInventoryService
						FROM SERVICE [OrderService]
						TO SERVICE 'InventoryService'
						ON CONTRACT [http://ssb.csharp.at/SSB_Book/c08/InventoryContract]
						WITH RELATED_CONVERSATION = @ch, ENCRYPTION = OFF;

					-- Send a message to the CreditCardService
					SET @msgInventoryService = 
						'<InventoryRequest>
							<ProductID>' + CAST(@productID AS NVARCHAR(10)) + '</ProductID>
							<Quantity>' + CAST(@quantity AS NVARCHAR(10)) + '</Quantity>
						</InventoryRequest>';

					SEND ON CONVERSATION @chInventoryService MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c08/InventoryRequestMessage] (@msgInventoryService);
				END

				-- Process the CreditCardResponseMessage sent from the CreditCardService
				IF (@messageTypeName = 'http://ssb.csharp.at/SSB_Book/c08/CreditCardResponseMessage')
				BEGIN
					DECLARE @creditCardResult BIT;

					SET @creditCardResult = @messageBody.value('/CreditCardResponse[1]', 'BIT');

					-- Updating the state information, indicating that the CreditCardService was called
					SET @CreditCardStatus = 1;
				END

				-- Process the AccountingResponseMessage sent from the AccountingService
				IF (@messageTypeName = 'http://ssb.csharp.at/SSB_Book/c08/AccountingResponseMessage')
				BEGIN
					DECLARE @accountingResult BIT;

					SET @accountingResult = @messageBody.value('/AccountingResponse[1]', 'BIT');

					-- Updating the state information, indicating that the AccountingService was called
					SET @AccountingStatus = 1;
				END

				-- Process the InventoryResponseMessage sent from the InventoryService
				IF (@messageTypeName = 'http://ssb.csharp.at/SSB_Book/c08/InventoryResponseMessage')
				BEGIN
					DECLARE @inventoryResult BIT;
						
					SET @inventoryResult = @messageBody.value('/InventoryResponse[1]', 'BIT');

					-- Updating the state information indicating that the InventoryService was called
					SET @InventoryStatus = 1;
				END

				-- Process the ShippingResponseMessage sent from the ShippingService
				IF (@messageTypeName = 'http://ssb.csharp.at/SSB_Book/c08/ShippingResponseMessage')
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
					SEND ON CONVERSATION @chClientService MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c08/OrderResponseMessage] (@orderResponseMessage);

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
						ON CONTRACT [http://ssb.csharp.at/SSB_Book/c08/ShippingContract]
						WITH RELATED_CONVERSATION = @ch, ENCRYPTION = OFF;

					-- Send the request message to the ShippingService
					DECLARE @msg XML;

					-- SELECT the original order request message from the OrderQueue - RETENTION makes it possible
					SELECT @msg = CAST(message_body AS XML) FROM OrderQueue
					WHERE
						conversation_group_id = @conversationGroup AND
						message_type_name = 'http://ssb.csharp.at/SSB_Book/c08/OrderRequestMessage';
					SET @msgShippingService = CAST(@msg.query('/OrderRequest[1]/Shipping[1]') AS NVARCHAR(MAX));

					SEND ON CONVERSATION @chShippingService MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c08/ShippingRequestMessage] (@msgShippingService);

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
	END TRY
	BEGIN CATCH
		SELECT
			ERROR_NUMBER() AS ErrorNumber,
			ERROR_SEVERITY() AS ErrorSeverity,
			ERROR_STATE() AS ErrorState,
			ERROR_PROCEDURE() AS ErrorProcedure,
			ERROR_LINE() AS ErrorLine,
			ERROR_MESSAGE() AS ErrorMessage;

		ROLLBACK TRANSACTION
	END CATCH
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

		IF (@messagetypename = 'http://ssb.csharp.at/SSB_Book/c08/OrderResponseMessage')
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

--***************************************************************************************
--*  The rest of the security configuration is done through the Service Listing Manager
--***************************************************************************************








--*******************************************************************************
--*  Create the necessary routes to the CreditCardService and AccountingService
--*******************************************************************************
CREATE ROUTE CreditCardServiceRoute
	WITH SERVICE_NAME = 'CreditCardService',
	ADDRESS	= 'TCP://192.168.0.102:4741'
GO

CREATE ROUTE AccountingServiceRoute
	WITH SERVICE_NAME = 'AccountingServiceRoute',
	ADDRESS = 'TCP://127.0.0.1:4742'
GO

--***************************************
--*  Setup anonymous transport security
--***************************************
USE master
GO

CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'password1!'
GO

CREATE CERTIFICATE OrderServiceTransportCertPrivate
	WITH SUBJECT = 'For Service Broker authentication',
	START_DATE = '01/01/2008'
GO

-- Create the Service Broker endpoint
CREATE ENDPOINT OrderServiceEndpoint
STATE = STARTED
AS TCP 
(
	LISTENER_PORT = 4740
)
FOR SERVICE_BROKER 
(
	AUTHENTICATION = CERTIFICATE OrderServiceTransportCertPrivate
)
GO

-- Everyone (anonymous security) can now connect to this Service Broker endpoint!!!
GRANT CONNECT ON ENDPOINT::OrderServiceEndpoint TO [PUBLIC]
GO

--***********************************************************************
--*  Create and setup the database user that represents the OrderService
--***********************************************************************
USE Chapter8_OrderService
GO

CREATE USER OrderServiceUser WITHOUT LOGIN
GO

ALTER AUTHORIZATION ON SERVICE::OrderService TO OrderServiceUser
GO

--**********************************************************************************
--*  Create a new certificate that is owned by the previous created database user
--**********************************************************************************
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'password1!'
GO

CREATE CERTIFICATE OrderServiceCertPrivate
	AUTHORIZATION OrderServiceUser
	WITH SUBJECT = 'Private certificate for OrderService',
	START_DATE = '01/01/2008'
GO

BACKUP CERTIFICATE OrderServiceCertPrivate
	TO FILE = 'c:\OrderServiceCertPublic.cert'
GO

--*****************************************************************************
--*  Import the public key certificate from the other Service Broker endpoint
--*****************************************************************************
CREATE USER CreditCardServiceUser WITHOUT LOGIN
GO

CREATE CERTIFICATE CreditCardServiceCertPublic
	AUTHORIZATION CreditCardServiceUser
	FROM FILE = 'c:\CreditCardServiceCertPublic.cert'
GO

-- Create the remote service binding
CREATE REMOTE SERVICE BINDING RemoteServiceBindingToCreditCardService
	TO SERVICE 'CreditCardService'
	WITH USER = CreditCardServiceUser
GO

--***************************************************************************************************
--*  Send a message to start the conversation with the distributed deployed Service Broker services
--***************************************************************************************************
BEGIN TRANSACTION;
	DECLARE @ch UNIQUEIDENTIFIER
	DECLARE @msg NVARCHAR(MAX);

	BEGIN DIALOG CONVERSATION @ch
		FROM SERVICE [ClientService]
		TO SERVICE 'OrderService'
		ON CONTRACT [http://ssb.csharp.at/SSB_Book/c08/OrderContract]
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

	SEND ON CONVERSATION @ch MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c08/OrderRequestMessage] (@msg);
COMMIT;
GO