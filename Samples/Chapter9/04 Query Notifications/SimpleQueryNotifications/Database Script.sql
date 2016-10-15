USE master;

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'Chapter9_QueryNotifications')
BEGIN
	PRINT 'Dropping database ''Chapter9_QueryNotifications''';
	DROP DATABASE Chapter9_QueryNotifications;
END
GO

CREATE DATABASE Chapter9_QueryNotifications
GO

USE Chapter9_QueryNotifications
GO

--******************************************
--*  Enable Service Broker on the database
--******************************************
ALTER DATABASE Chapter9_QueryNotifications SET ENABLE_BROKER

--*****************************************************************
--*  Create the table that stores the products that are displayed 
--*  in the DataGridView control inside the WinForms application.
--*****************************************************************
CREATE TABLE Products
(
	ID INT PRIMARY KEY IDENTITY(1, 1) NOT NULL,
	ProductName NVARCHAR(255) NOT NULL,
	ProductDescription NVARCHAR(255) NOT NULL
)
GO

--*******************************************************************************************************
--*  Execute the following INSERT T-SQL statement when the WinForms application is running.
--*  In this case the DataGridView gets automatically updated because of the created Query Notification.
--*******************************************************************************************************
INSERT INTO Products (ProductName, ProductDescription)
VALUES ('My Product Name', 'My Product Description')
GO