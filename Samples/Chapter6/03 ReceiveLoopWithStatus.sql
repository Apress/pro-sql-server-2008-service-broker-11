USE master;

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'Chapter6_ReceiveLoopWithStatus')
BEGIN
	PRINT 'Dropping database ''Chapter6_ReceiveLoopWithStatus''';
	DROP DATABASE Chapter6_ReceiveLoopWithStatus;
END
GO

CREATE DATABASE Chapter6_ReceiveLoopWithStatus
GO

USE Chapter6_ReceiveLoopWithStatus
GO

--************************************
--*  Create the needed message types
--************************************
CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c06/ProductOrderMessage] VALIDATION = WELL_FORMED_XML
CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c06/ResponseMessage] VALIDATION = WELL_FORMED_XML
GO

--*******************************
--*  Create the needed contract
--*******************************
CREATE CONTRACT [http://ssb.csharp.at/SSB_Book/c06/ProductOrderContract]
(
	[http://ssb.csharp.at/SSB_Book/c06/ProductOrderMessage] SENT BY INITIATOR,
	[http://ssb.csharp.at/SSB_Book/c06/ResponseMessage] SENT BY TARGET
)
GO

--***************************************************************
--*  Create the queues "InitiatorQueue" and "ProductOrderQueue"
--***************************************************************
CREATE QUEUE InitiatorQueue WITH STATUS = ON
GO

CREATE QUEUE [ProductOrderQueue] WITH STATUS = ON
GO

--************************************************************
--*  Create the queues "InitiatorService" and "TargetService"
--************************************************************
CREATE SERVICE InitiatorService
ON QUEUE InitiatorQueue 
(
	[http://ssb.csharp.at/SSB_Book/c06/ProductOrderContract]
)
GO

CREATE SERVICE ProductOrderService
ON QUEUE ProductOrderQueue
(
	[http://ssb.csharp.at/SSB_Book/c06/ProductOrderContract]
)
GO

--****************************
--*  This is our state table
--****************************
CREATE TABLE ApplicationState
(
	ConversationGroupID UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
	CreditCardValidation BIT NOT NULL,
	InventoryAdjustment BIT NOT NULL,
	Shipping BIT NOT NULL,
	Accounting BIT NOT NULL
)
GO

--*****************************************************
--*  Service program that processes incoming messages
--*****************************************************
CREATE PROCEDURE ProcessOrderMessages
AS
BEGIN
	DECLARE @conversationGroup UNIQUEIDENTIFIER;
	DECLARE @CreditCardValidationStatus BIT;
	DECLARE @InventoryAdjustmentStatus BIT;
	DECLARE @ShippingStatus BIT;
	DECLARE @AccountingStatus BIT;

	-- Outer Loop (State Handling)
	WHILE (1 = 1)
	BEGIN
		BEGIN TRANSACTION;

		-- Retrieving the next conversation group where messages are available for processing
		WAITFOR (
			GET CONVERSATION GROUP @conversationGroup FROM [ProductOrderQueue]
		), TIMEOUT 1000

		IF (@@ROWCOUNT = 0)
		BEGIN
			ROLLBACK TRANSACTION
			BREAK
		END

		-- Retrieving the application state for the current conversation group
		SELECT 
			@CreditCardValidationStatus = CreditCardValidation,
			@InventoryAdjustmentStatus = InventoryAdjustment,
			@ShippingStatus = Shipping,
			@AccountingStatus = Accounting
		FROM ApplicationState
		WHERE ConversationGroupId = @conversationGroup;

		IF (@@ROWCOUNT = 0)
		BEGIN
			-- There is currently no application state available, so we insert the application state into the state table
			SET @CreditCardValidationStatus = 0;
			SET @InventoryAdjustmentStatus = 0;
			SET @ShippingStatus = 0;
			SET @AccountingStatus = 0;
		
			-- Insert the state record
			INSERT INTO ApplicationState (ConversationGroupId, CreditCardValidation, InventoryAdjustment, Shipping, Accounting)
			VALUES
			(
				@conversationGroup,
				@CreditCardValidationStatus,
				@InventoryAdjustmentStatus,
				@ShippingStatus,
				@AccountingStatus
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
				FROM [ProductOrderQueue]
				WHERE conversation_group_id = @conversationGroup
			), TIMEOUT 1000

			IF (@@ROWCOUNT = 0)
			BEGIN
				BREAK
			END

			IF (@messageTypeName = 'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog')
			BEGIN
				END CONVERSATION @ch;
			END

			IF (@messageTypeName = 'http://schemas.microsoft.com/SQL/ServiceBroker/Error')
			BEGIN
				-- Handle errors
				END CONVERSATION @ch;
			END

			IF (@messageTypeName = 'http://ssb.csharp.at/SSB_Book/c06/ProductOrderMessage')
			BEGIN
				-- Process the message
				SELECT @messageBody;
	
				-- We assume here that the credit card validation was successful
				SET @CreditCardValidationStatus = 1;
				END CONVERSATION @ch;
			END
		END

		-- Update the application state
		UPDATE ApplicationState SET
			CreditCardValidation = @CreditCardValidationStatus,
			InventoryAdjustment = @InventoryAdjustmentStatus,
			Shipping = @ShippingStatus,
			Accounting = @AccountingStatus
		WHERE ConversationGroupId = @conversationGroup;

		-- Commit the whole transaction
		COMMIT TRANSACTION;
	END
END
GO

--****************************************************
--*  Send a new message to the "ProductOrderService"
--****************************************************
BEGIN TRANSACTION;
	DECLARE @ch UNIQUEIDENTIFIER
	DECLARE @msg NVARCHAR(MAX);

	BEGIN DIALOG CONVERSATION @ch
		FROM SERVICE [InitiatorService]
		TO SERVICE 'ProductOrderService'
		ON CONTRACT [http://ssb.csharp.at/SSB_Book/c06/ProductOrderContract]
		WITH ENCRYPTION = OFF;

	SET @msg = 
		'<ProductOrderRequest>
				<ProductId>ISBN123</ProductId>
				<Quantity>5</Quantity>
				<Price>40.99</Price>
		</ProductOrderRequest>';

	SEND ON CONVERSATION @ch MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c06/ProductOrderMessage] (@msg);
COMMIT;
GO

--****************************
--*  SELECT tht sent message
--****************************
SELECT * FROM ProductOrderQueue
GO

--***************************************************************
--*  Process the sent messages on the queue "ProductOrderQueue"
--***************************************************************
EXEC ProcessOrderMessages
GO

--***************************************************************
--*  SELECT the stored application state
--***************************************************************
SELECT * FROM ApplicationState
GO