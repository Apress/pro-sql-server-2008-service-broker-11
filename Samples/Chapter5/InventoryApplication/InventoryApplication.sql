USE master;

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'Chapter5_InventoryApplication')
BEGIN
	PRINT 'Dropping database ''Chapter5_InventoryApplication''';
	DROP DATABASE Chapter5_InventoryApplication;
END
GO

CREATE DATABASE Chapter5_InventoryApplication
GO

USE Chapter5_InventoryApplication
GO

--*************************************************************************
--*  Create the message type and the contract for updating the inventory
--*************************************************************************
CREATE MESSAGE TYPE
[http://ssb.csharp.at/SSB_Book/c05/InventoryUpdateMessage]
VALIDATION = WELL_FORMED_XML
GO

CREATE CONTRACT [http://ssb.csharp.at/SSB_Book/c05/InventoryUpdateContract]
( 
	[http://ssb.csharp.at/SSB_Book/c05/InventoryUpdateMessage] SENT BY INITIATOR
)
GO

--***********************************************************************************
--*  Create the message type and the contract for removing items from the inventory
--***********************************************************************************
CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c05/InventoryQueryRequestMessage]
VALIDATION = WELL_FORMED_XML
GO

CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c05/InventoryQueryResponseMessage]
VALIDATION = WELL_FORMED_XML
GO

CREATE CONTRACT [http://ssb.csharp.at/SSB_Book/c05/InventoryQueryContract]
(
    [http://ssb.csharp.at/SSB_Book/c05/InventoryQueryRequestMessage] SENT BY INITIATOR,
    [http://ssb.csharp.at/SSB_Book/c05/InventoryQueryResponseMessage] SENT BY TARGET
)
GO

--******************************
--*  Create the target service
--******************************
CREATE QUEUE [InventoryTargetQueue]
GO

CREATE SERVICE [InventoryTargetService] 
ON QUEUE [InventoryTargetQueue] 
(
	[http://ssb.csharp.at/SSB_Book/c05/InventoryUpdateContract],
	[http://ssb.csharp.at/SSB_Book/c05/InventoryQueryContract]
)
GO

--*********************************
--*  Create the initiator service
--*********************************
CREATE QUEUE [InventoryInitiatorQueue]
GO

CREATE SERVICE [InventoryInitiatorService] 
ON QUEUE [InventoryInitiatorQueue] 
(
	[http://ssb.csharp.at/SSB_Book/c05/InventoryUpdateContract],
	[http://ssb.csharp.at/SSB_Book/c05/InventoryQueryContract]
)
GO

--*********************************
--*  Create the inventory table
--*********************************
CREATE TABLE Inventory
(
	InventoryId	NVARCHAR(10) NOT NULL,
	Quantity INT NOT NULL, 
	PRIMARY KEY (InventoryId)
)
GO

--*********************************
--*  Populate the inventory table
--*********************************
INSERT Inventory VALUES ('PS1372', 200)
INSERT Inventory VALUES ('PC1035', 200)
INSERT Inventory VALUES ('BU1111', 200)
INSERT Inventory VALUES ('PS7777', 200)
INSERT Inventory VALUES ('TC4203', 200)
INSERT Inventory VALUES ('PS2091', 200)
INSERT Inventory VALUES ('PS2106', 200)
INSERT Inventory VALUES ('PC9999', 200)
INSERT Inventory VALUES ('TC3218', 200)
INSERT Inventory VALUES ('PS3333', 200)
INSERT Inventory VALUES ('PC8888', 200)
INSERT Inventory VALUES ('MC2222', 200)
INSERT Inventory VALUES ('BU7832', 200)
INSERT Inventory VALUES ('TC7777', 200)
INSERT Inventory VALUES ('BU1032', 200)
INSERT Inventory VALUES ('MC3021', 200)
INSERT Inventory VALUES ('MC3026', 200)
INSERT Inventory VALUES ('BU2075', 200)
GO

--******************************************
--*  Register the assembly
--******************************************
CREATE ASSEMBLY [InventoryTargetServiceAssembly]
FROM 'J:\Pro SQL 2008 Service Broker\Chapter 5\Samples\InventoryApplication\InventoryTargetService\bin\Debug\InventoryTargetService.dll'
GO

-- Add the debug information about the assembly
ALTER ASSEMBLY [InventoryTargetServiceAssembly]
ADD FILE FROM 'J:\Pro SQL 2008 Service Broker\Chapter 5\Samples\InventoryApplication\InventoryTargetService\bin\Debug\InventoryTargetService.pdb'
GO

ALTER ASSEMBLY [ServiceBrokerInterface]
ADD FILE FROM 'J:\Pro SQL 2008 Service Broker\Chapter 5\Samples\InventoryApplication\ServiceBrokerInterface\bin\Debug\ServiceBrokerInterface.pdb'
GO

--******************************************
--*  Register the managed stored procedure
--******************************************
CREATE PROCEDURE InventoryTargetProcedure
AS
EXTERNAL NAME [InventoryTargetServiceAssembly].[InventoryTargetService.TargetService].ServiceProcedure
GO

--****************************************************************
--*  Use internal activation on the queue "InventoryTargetQueue"
--****************************************************************
ALTER QUEUE [InventoryTargetQueue]
WITH ACTIVATION
(
	STATUS = ON,
	PROCEDURE_NAME = InventoryTargetProcedure,
	MAX_QUEUE_READERS = 5,
	EXECUTE AS SELF
)
GO

--***************************
--*  Updating the inventory
--***************************
BEGIN TRANSACTION;
	DECLARE @dh UNIQUEIDENTIFIER;
	DECLARE @msg NVARCHAR(MAX);
	DECLARE @count INT;
	DECLARE @max INT;

	BEGIN DIALOG @dh
		FROM SERVICE [InventoryInitiatorService]
		TO SERVICE 'InventoryTargetService'
		ON CONTRACT [http://ssb.csharp.at/SSB_Book/c05/InventoryUpdateContract]
		WITH ENCRYPTION = OFF;

	SET @msg = 
		'<InventoryUpdate>
			<InventoryId>BU1032</InventoryId>
			<Quantity>30</Quantity>
		</InventoryUpdate>';

	SEND ON CONVERSATION @dh MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c05/InventoryUpdateMessage] (@msg);
COMMIT;
GO

--**************************************
--*  Ordering items from the inventory
--**************************************
BEGIN TRANSACTION;
	DECLARE @dh UNIQUEIDENTIFIER;
	DECLARE @msg NVARCHAR(MAX);
	DECLARE @count INT;
	DECLARE @max INT;

	BEGIN DIALOG @dh
		FROM SERVICE [InventoryInitiatorService]
		TO SERVICE 'InventoryTargetService'
		ON CONTRACT [http://ssb.csharp.at/SSB_Book/c05/InventoryQueryContract]
		WITH ENCRYPTION = OFF;

	SET @msg = 
		'<InventoryQuery>
			<InventoryId>BU1032</InventoryId>
			<Quantity>30</Quantity>
		</InventoryQuery>';

	SEND ON CONVERSATION @dh MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c05/InventoryQueryRequestMessage] (@msg);
COMMIT;
GO



select cast(message_body as xml), * from inventoryinitiatorqueue

select * from inventorytargetqueue

exec inventorytargetprocedure

select * from sys.assembly_files

select * from inventory

