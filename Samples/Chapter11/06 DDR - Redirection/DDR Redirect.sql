USE master;

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'Chapter10_DDR_Redirect')
BEGIN
	PRINT 'Dropping database ''Chapter10_DDR_Redirect''';
	DROP DATABASE Chapter10_DDR_Redirect;
END
GO

CREATE DATABASE Chapter10_DDR_Redirect
GO

USE Chapter10_DDR_Redirect
GO

-- Create a table for european customers
CREATE TABLE CustomersEurope
(
	CustomerID NVARCHAR(256) NOT NULL PRIMARY KEY,
	CustomerName NVARCHAR(256),
	CustomerAddress NVARCHAR(256),
	City NVARCHAR(256)
)
GO

-- Create a table for american customers
CREATE TABLE CustomersUSA
(
	CustomerID NVARCHAR(256) NOT NULL PRIMARY KEY,
	CustomerName NVARCHAR(256),
	CustomerAddress NVARCHAR(256),
	City NVARCHAR(256)
)
GO

-- Insert a sample record
INSERT INTO CustomersEurope (CustomerID, CustomerName, CustomerAddress, City)
VALUES
(
	'AKS',
	'Klaus Aschenbrenner',
	'Wagramer Straﬂe 4/803',
	'Vienna'
)

-- Insert a sample record
INSERT INTO CustomersUSA (CustomerID, CustomerName, CustomerAddress, City)
VALUES
(
	'MSFT',
	'Microsoft Corp.',
	'Two Microsoft Way',
	'Redmond'
)

--************************************
--*  Create the needed message types
--************************************
CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c10/CustomerUpdateRequestMessage] VALIDATION = WELL_FORMED_XML
GO
CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c10/RedirectMessage] VALIDATION = WELL_FORMED_XML
GO

--************************
--*  Create the contract
--************************
CREATE CONTRACT [http://ssb.csharp.at/SSB_Book/c10/CustomerUpdateContract]
(
	[http://ssb.csharp.at/SSB_Book/c10/CustomerUpdateRequestMessage] SENT BY INITIATOR,
	[http://ssb.csharp.at/SSB_Book/c10/RedirectMessage] SENT BY TARGET
)
GO

--***************************************************
--*  Create the InitiatorQueue and InitiatorService
--***************************************************
CREATE QUEUE InitiatorQueue
WITH RETENTION = ON
GO

CREATE SERVICE InitiatorService
ON QUEUE InitiatorQueue
(
	[http://ssb.csharp.at/SSB_Book/c10/CustomerUpdateContract]
)

--*****************************************
--*  Create the routing queue and service
--*****************************************
CREATE QUEUE RoutingQueue
GO

CREATE SERVICE RoutingService
ON QUEUE RoutingQueue
(
	[http://ssb.csharp.at/SSB_Book/c10/CustomerUpdateContract]
)
GO

--********************************************************
--*  Create the queue and service for european customers
--********************************************************
CREATE QUEUE CustomersEuropeQueue
GO

CREATE SERVICE CustomersEuropeService
ON QUEUE CustomersEuropeQueue
(
	[http://ssb.csharp.at/SSB_Book/c10/CustomerUpdateContract]
)
GO

--********************************************************
--*  Create the queue and service for american customers
--********************************************************
CREATE QUEUE CustomersUSAQueue
GO

CREATE SERVICE CustomersUSAService
ON QUEUE CustomersUSAQueue
(
	[http://ssb.csharp.at/SSB_Book/c10/CustomerUpdateContract]
)
GO

--*************************************************************************
--*  Create the table that stores the associated classifier for a service
--*************************************************************************
CREATE TABLE RoutingServiceConfig
(
	ServiceName SYSNAME NOT NULL,
	Classifier SYSNAME NOT NULL,
	PRIMARY KEY (ServiceName)
)
GO

--*********************************************************************************************************************
--* This stored procedure processes the incoming request messages and redirects them to the configured target service
--*********************************************************************************************************************
CREATE PROCEDURE ProcessRequestMessages
(
	@InboundConversation UNIQUEIDENTIFIER,
	@ContractName NVARCHAR(256),
	@MessageTypeName NVARCHAR(256),
	@MessageBody VARBINARY(MAX)
)
AS
BEGIN
	DECLARE @classifier SYSNAME
	DECLARE	@toServiceName NVARCHAR(256)
	DECLARE	@toBrokerInstance NVARCHAR(256)
	DECLARE	@replyMessage NVARCHAR(1000)

	-- Select the correct classifier component
	SELECT @classifier = Classifier
	FROM RoutingServiceConfig
	WHERE ServiceName = 'RoutingService';

	-- Execute the classifier component
	EXEC @classifier @contractName, @messageTypeName, @messageBody, @toServiceName OUTPUT, @toBrokerInstance OUTPUT;

	IF (@toServiceName IS NULL)
	BEGIN
		-- End the conversation if we got no target service name
		END CONVERSATION @inboundConversation 
			WITH ERROR = 1 
			DESCRIPTION = N'Cannot resolve the message to target service.';
		RETURN;
	END

	-- Construct the redirection message
	SET @replyMessage = 
		N'<RedirectTo>' +
			N'<ServiceName>' + @toServiceName + N'</ServiceName>' +
			N'<BrokerInstance>' + @toBrokerInstance + N'</BrokerInstance>' +
		N'</RedirectTo>';

	-- Send the redirection message back to the InitiatorService
	SEND ON CONVERSATION @inboundConversation 
		MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c10/RedirectMessage] (@replyMessage);

	-- End the conversation between the InitiatorService and the TargetService
	END CONVERSATION @inboundConversation;
END
GO

--*********************************************************************************************************
--* This stored procedure is the service program for the RoutingQueue and processes all incoming messages
--*********************************************************************************************************
CREATE PROCEDURE RouteMessages
AS
BEGIN
	DECLARE @messageTypeName NVARCHAR(256)
	DECLARE	@contractName NVARCHAR(256)
	DECLARE	@messageBody VARBINARY(MAX)
	DECLARE	@inboundConversation UNIQUEIDENTIFIER

	WHILE (1=1)
	BEGIN 
		-- Begin a new transaction
		BEGIN TRANSACTION

		-- Receive a new message from the RoutingQueue
		WAITFOR 
		(
			RECEIVE TOP(1)
				@inboundConversation = conversation_handle,
				@contractName = service_contract_name,
				@messageTypeName = message_type_name,
				@messageBody = message_body
			FROM RoutingQueue
		), TIMEOUT 5000;
		
		IF (@@ROWCOUNT = 0)
		BEGIN
			-- We got no message from the RoutingQueue
			ROLLBACK TRANSACTION;
			BREAK;
		END
		
		-- Process the received error message
		IF (@messageTypeName = N'http://schemas.microsoft.com/SQL/ServiceBroker/Error' OR @messageTypeName = N'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog')
		BEGIN
			END CONVERSATION @inboundConversation
		END
		-- Process all other request message
		ELSE
		BEGIN
			EXEC ProcessRequestMessages @inboundConversation, @contractName,
				@messageTypeName, @messageBody;
		END

		-- Commit the transaction
		COMMIT
	END
END;
GO

--*****************************************************************************************************
--* This table stores the association between a customer partition and the corresponding service name
--*****************************************************************************************************
CREATE TABLE CustomerPartitions
(
	CustomerPartition NVARCHAR(50) NOT NULL,
	ServiceName NVARCHAR(50) NOT NULL,
	BrokerInstanceIdentifier NVARCHAR(50) NOT NULL
	PRIMARY KEY (CustomerPartition, ServiceName, BrokerInstanceIdentifier)
)
GO

--*********************************************
--* Insert the needed configuration meta data
--*********************************************
INSERT INTO CustomerPartitions (CustomerPartition, ServiceName, BrokerInstanceIdentifier)
VALUES ('European', 'CustomersEuropeService', 'CURRENT DATABASE')
GO

INSERT INTO CustomerPartitions (CustomerPartition, ServiceName, BrokerInstanceIdentifier)
VALUES ('USA', 'CustomersUSAService', 'CURRENT DATABASE')
GO

--************************************************************************
--* Create a simple stored procedure that acts as a classifier component
--************************************************************************
CREATE PROCEDURE MySampleClassifierComponent
(
	@ContractName NVARCHAR(256),
	@MessageTypeName NVARCHAR(256),
	@MessageBody VARBINARY(MAX),
	@ToServiceName NVARCHAR(256) OUTPUT,
	@ToBrokerInstance NVARCHAR(256) OUTPUT
)
AS
BEGIN
	DECLARE @customerPartition NVARCHAR(256);
	DECLARE @xmlMessage XML;

	-- Retrieve the customer partition from the received request message
	SET @xmlMessage = CONVERT(XML, @MessageBody);
	SET @customerPartition = @xmlMessage.value('(/CustomerUpdateRequest/CustomerPartition)[1]', 'nvarchar(256)');

	-- Retrieve the service name and the broker instance identifier, that processes this customer partition
	SELECT @ToServiceName = ServiceName, @ToBrokerInstance = BrokerInstanceIdentifier FROM CustomerPartitions
	WHERE CustomerPartition = @customerPartition
END
GO

--*************************************
--* Register the classifier component
--*************************************
INSERT INTO RoutingServiceConfig
VALUES
(
	'RoutingService',
	'MySampleClassifierComponent'
)
GO

--**************************************************************************
--* This stored procedure processes update requests for european customers
--**************************************************************************
CREATE PROCEDURE ProcessEuropeanCustomers
AS
	WHILE (1=1)
	BEGIN 
		DECLARE @conversationHandle UNIQUEIDENTIFIER
		DECLARE @messageTypeName NVARCHAR(256)
		DECLARE @messageBody XML
		DECLARE @customerID NVARCHAR(256)
		DECLARE @customerAddress NVARCHAR(256)

		-- Begin a new transaction
		BEGIN TRANSACTION

		-- Receive a new message from the RoutingQueue
		WAITFOR 
		(
			RECEIVE TOP(1)
				@conversationHandle = conversation_handle,
				@messageTypeName = message_type_name,
				@messageBody = message_body
			FROM CustomersEuropeQueue
		), TIMEOUT 5000;
		
		IF (@@ROWCOUNT = 0)
		BEGIN
			-- We got no message from the RoutingQueue
			ROLLBACK TRANSACTION;
			BREAK;
		END
		
		IF (@messageTypeName = N'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog')
		BEGIN
			END CONVERSATION @conversationhandle
		END
		ELSE IF (@messageTypeName = N'http://ssb.csharp.at/SSB_Book/c10/CustomerUpdateRequestMessage')
		BEGIN
			-- Process the CustomerUpdateRequest message
			SET @customerID = @messageBody.value('(/CustomerUpdateRequest/CustomerID)[1]', 'nvarchar(256)');
			SET @customerAddress = @messageBody.value('(/CustomerUpdateRequest/CustomerAddress)[1]', 'nvarchar(256)');

			-- Update the database table
			UPDATE CustomersEurope
				SET CustomerAddress = @customerAddress
			WHERE CustomerID = @CustomerID

			-- End the conversation
			END CONVERSATION @conversationHandle
		END

		COMMIT TRANSACTION
	END
GO

--**************************************************************************
--* This stored procedure processes update requests for american customers
--**************************************************************************
CREATE PROCEDURE ProcessAmericanCustomers
AS
	WHILE (1=1)
	BEGIN 
		DECLARE @conversationHandle UNIQUEIDENTIFIER
		DECLARE @messageTypeName NVARCHAR(256)
		DECLARE @messageBody XML
		DECLARE @customerID NVARCHAR(256)
		DECLARE @customerAddress NVARCHAR(256)

		-- Begin a new transaction
		BEGIN TRANSACTION

		-- Receive a new message from the RoutingQueue
		WAITFOR 
		(
			RECEIVE TOP(1)
				@conversationHandle = conversation_handle,
				@messageTypeName = message_type_name,
				@messageBody = message_body
			FROM CustomersUSAQueue
		), TIMEOUT 5000;
		
		IF (@@ROWCOUNT = 0)
		BEGIN
			-- We got no message from the RoutingQueue
			ROLLBACK TRANSACTION;
			BREAK;
		END
		
		IF (@messageTypeName = N'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog')
		BEGIN
			END CONVERSATION @conversationhandle
		END
		ELSE IF (@messageTypeName = N'http://ssb.csharp.at/SSB_Book/c10/CustomerUpdateRequestMessage')
		BEGIN
			-- Process the CustomerUpdateRequest message
			SET @customerID = @messageBody.value('(/CustomerUpdateRequest/CustomerID)[1]', 'nvarchar(256)');
			SET @customerAddress = @messageBody.value('(/CustomerUpdateRequest/CustomerAddress)[1]', 'nvarchar(256)');

			-- Update the database table
			UPDATE CustomersUSA
				SET CustomerAddress = @customerAddress
			WHERE CustomerID = @CustomerID

			-- End the conversation
			END CONVERSATION @conversationHandle
		END

		COMMIT TRANSACTION
	END
GO

--************************************************************************
--* This stored procedure processes the messages from the InitiatorQueue
--************************************************************************
CREATE PROCEDURE ProcessInitiatorQueue
AS
	WHILE (1=1)
	BEGIN 
		DECLARE @conversationHandle UNIQUEIDENTIFIER
		DECLARE @messageTypeName NVARCHAR(256)
		DECLARE @messageBody XML

		-- Begin a new transaction
		BEGIN TRANSACTION

		-- Receive a new message from the RoutingQueue
		WAITFOR 
		(
			RECEIVE TOP(1)
				@conversationHandle = conversation_handle,
				@messageTypeName = message_type_name,
				@messageBody = message_body
			FROM InitiatorQueue
		), TIMEOUT 5000;
		
		IF (@@ROWCOUNT = 0)
		BEGIN
			-- We got no message from the RoutingQueue
			ROLLBACK TRANSACTION;
			BREAK;
		END

		IF (@messageTypeName = 'http://ssb.csharp.at/SSB_Book/c10/RedirectMessage')
		BEGIN
			DECLARE @conversationHandleTargetService UNIQUEIDENTIFIER
			DECLARE @targetService NVARCHAR(256)
			DECLARE @brokerIdentifier NVARCHAR(256)
			DECLARE @originalMessage XML

			-- Retrieve the original sent message through the RETENTION feature of Service Broker
			SELECT @originalMessage = message_body FROM InitiatorQueue
			WHERE 
				conversation_handle = @conversationHandle AND
				message_type_name = 'http://ssb.csharp.at/SSB_Book/c10/CustomerUpdateRequestMessage'

			-- Retrieve the redirected TargetService
			SET @targetService = @messageBody.value('(/RedirectTo/ServiceName)[1]', 'nvarchar(256)');
			SET @brokerIdentifier = @messageBody.value('(/RedirectTo/BrokerInstance)[1]', 'nvarchar(256)');

			-- Begin a new conversation with the redirected TargetService
			BEGIN DIALOG @conversationHandleTargetService
				FROM SERVICE InitiatorService
				TO SERVICE @targetService, @brokerIdentifier
				ON CONTRACT [http://ssb.csharp.at/SSB_Book/c10/CustomerUpdateContract]
				WITH ENCRYPTION = OFF;

			-- Send the original request message to the redirected TargetService
			SEND ON CONVERSATION @conversationHandleTargetService
				MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c10/CustomerUpdateRequestMessage] (@originalMessage)

			-- End the conversation with the RoutingService
			END CONVERSATION @conversationhandle
		END
		ELSE IF (@messageTypeName = 'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog')
		BEGIN
			END CONVERSATION @conversationHandle
		END
		
		-- Commit the transaction
		COMMIT TRANSACTION
	END
GO

--******************************************************
--* Activate internal activation on the InitiatorQueue
--******************************************************
ALTER QUEUE InitiatorQueue 
WITH ACTIVATION 
(
	STATUS = ON,
	PROCEDURE_NAME = ProcessInitiatorQueue,
	MAX_QUEUE_READERS = 1,
	EXECUTE AS SELF
)
GO

--****************************************************
--* Activate internal activation on the RoutingQueue
--****************************************************
ALTER QUEUE RoutingQueue 
WITH ACTIVATION 
(
	STATUS = ON,
	PROCEDURE_NAME = RouteMessages,
	MAX_QUEUE_READERS = 1,
	EXECUTE AS SELF
)
GO

--************************************************************
--* Activate internal activation on the CustomersEuropeQueue
--************************************************************
ALTER QUEUE CustomersEuropeQueue 
WITH ACTIVATION 
(
	STATUS = ON,
	PROCEDURE_NAME = ProcessEuropeanCustomers,
	MAX_QUEUE_READERS = 1,
	EXECUTE AS SELF
)
GO

--************************************************************
--* Activate internal activation on the CustomersUSAQueue
--************************************************************
ALTER QUEUE CustomersUSAQueue 
WITH ACTIVATION 
(
	STATUS = ON,
	PROCEDURE_NAME = ProcessAmericanCustomers,
	MAX_QUEUE_READERS = 1,
	EXECUTE AS SELF
)
GO

--**********************************************************************************
--* Send a new request message to the RoutingService to update a european customer
--**********************************************************************************
DECLARE @dialogHandle UNIQUEIDENTIFIER

BEGIN TRANSACTION

-- Begin a new conversation with the RoutingService
BEGIN DIALOG @dialogHandle
	FROM SERVICE InitiatorService
	TO SERVICE 'RoutingService'
	ON CONTRACT [http://ssb.csharp.at/SSB_Book/c10/CustomerUpdateContract]
	WITH ENCRYPTION = OFF;

-- Send a CustomerUpdateRequest with the specified customer partition (eg. 'Europe' or 'USA')
SEND ON CONVERSATION @dialogHandle MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c10/CustomerUpdateRequestMessage]
(
N'<CustomerUpdateRequest>
	<CustomerPartition>European</CustomerPartition>
	<CustomerID>AKS</CustomerID>
	<CustomerAddress>Pichlgasse 16/6</CustomerAddress>
</CustomerUpdateRequest>');

-- Commit the transaction
COMMIT TRANSACTION
GO

--*******************************
--* Select the changed customer
--*******************************
SELECT * FROM CustomersEurope
GO

--**********************************************************************************
--* Send a new request message to the RoutingService to update a american customer
--**********************************************************************************
DECLARE @dialogHandle UNIQUEIDENTIFIER

BEGIN TRANSACTION

-- Begin a new conversation with the RoutingService
BEGIN DIALOG @dialogHandle
	FROM SERVICE InitiatorService
	TO SERVICE 'RoutingService'
	ON CONTRACT [http://ssb.csharp.at/SSB_Book/c10/CustomerUpdateContract]
	WITH ENCRYPTION = OFF;

-- Send a CustomerUpdateRequest with the specified customer partition (eg. 'Europe' or 'USA')
SEND ON CONVERSATION @dialogHandle MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c10/CustomerUpdateRequestMessage]
(
N'<CustomerUpdateRequest>
	<CustomerPartition>USA</CustomerPartition>
	<CustomerID>MSFT</CustomerID>
	<CustomerAddress>One Microsoft Way</CustomerAddress>
</CustomerUpdateRequest>');

-- Commit the transaction
COMMIT TRANSACTION
GO

--*******************************
--* Select the changed customer
--*******************************
SELECT * FROM CustomersUSA
GO