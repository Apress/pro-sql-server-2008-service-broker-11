USE master;

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'Chapter6_ManagedServiceBrokerWithState')
BEGIN
	PRINT 'Dropping database ''Chapter6_ManagedServiceBrokerWithState''';
	DROP DATABASE Chapter6_ManagedServiceBrokerWithState;
END
GO

CREATE DATABASE Chapter6_ManagedServiceBrokerWithState
GO

USE Chapter6_ManagedServiceBrokerWithState
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

--************************************************************************
--*  Register the assembly in the database
--************************************************************************
CREATE ASSEMBLY [ProductOrderServiceAssembly]
FROM 'd:\Klaus\Work\Private\Apress\Pro SQL 2005 Service Broker\Chapter 6\Samples\ManagedServiceBrokerWithState\TargetService\bin\Debug\TargetService.dll'
GO

-- Add the debug information about the assembly
ALTER ASSEMBLY [ProductOrderServiceAssembly]
ADD FILE FROM 'd:\Klaus\Work\Private\Apress\Pro SQL 2005 Service Broker\Chapter 6\Samples\ManagedServiceBrokerWithState\TargetService\bin\Debug\TargetService.pdb'
GO

ALTER ASSEMBLY [ServiceBrokerInterface]
ADD FILE FROM 'd:\Klaus\Work\Private\Apress\Pro SQL 2005 Service Broker\Chapter 6\Samples\ManagedServiceBrokerWithState\ServiceBrokerInterface\bin\Debug\ServiceBrokerInterface.pdb'
GO

--************************************************************************
--*  Register the stored procedure written in managed code
--************************************************************************
CREATE PROCEDURE ProductOrderProcessingProcedure
AS
EXTERNAL NAME [ProductOrderServiceAssembly].[TargetService.ProductOrderService].ServiceProcedure
GO

--************************************************************************
--*  Use the managed stored procedure for activation
--************************************************************************
ALTER QUEUE ProductOrderQueue
WITH ACTIVATION
(
	STATUS = ON,
	PROCEDURE_NAME = [ProductOrderProcessingProcedure],
	MAX_QUEUE_READERS = 1,
	EXECUTE AS SELF
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

--*******************************************************************************************************
--*  Create a stored procedure that loads the application state from the state table "ApplicationState"
--*******************************************************************************************************
CREATE PROCEDURE LoadApplicationState
@ConversationGroupID UNIQUEIDENTIFIER
AS
BEGIN
	DECLARE @CreditCardValidationStatus BIT;
	DECLARE @InventoryAdjustmentStatus BIT;
	DECLARE @ShippingStatus BIT;
	DECLARE @AccountingStatus BIT;

	-- Retrieving the application state for the current conversation group
	SELECT 
		@CreditCardValidationStatus = CreditCardValidation,
		@InventoryAdjustmentStatus = InventoryAdjustment,
		@ShippingStatus = Shipping,
		@AccountingStatus = Accounting
	FROM ApplicationState
	WHERE ConversationGroupId = @ConversationGroupID;

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
			@ConversationGroupID,
			@CreditCardValidationStatus,
			@InventoryAdjustmentStatus,
			@ShippingStatus,
			@AccountingStatus
		)
	END

	-- Retrieving the application state for the current conversation group
	SELECT 
		ConversationGroupId,
		CreditCardValidation,
		InventoryAdjustment,
		Shipping,
		Accounting
	FROM ApplicationState
	WHERE ConversationGroupId = @ConversationGroupID;
END
GO

--*****************************************************
--*  Send a new message to the service "TargetService
--*****************************************************
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

--***********************************
--*  SELECT the updated state table
--***********************************
SELECT * FROM ApplicationState
GO