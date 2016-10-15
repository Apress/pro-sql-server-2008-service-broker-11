USE master;

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'Chapter9_SqlNotificationRequest')
BEGIN
	PRINT 'Dropping database ''Chapter9_SqlNotificationRequest''';
	DROP DATABASE Chapter9_SqlNotificationRequest;
END
GO

CREATE DATABASE Chapter9_SqlNotificationRequest
GO

USE Chapter9_SqlNotificationRequest
GO

--******************************************
--*  Enable Service Broker on the database
--******************************************
ALTER DATABASE Chapter9_SqlNotificationRequest SET ENABLE_BROKER

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

--*********************************************************************
--*  Create the Service Broker objects needed by Query Notifications.
--*********************************************************************
CREATE QUEUE QueryNotificationQueue
GO

CREATE SERVICE QueryNotificationService
ON QUEUE QueryNotificationQueue
(
	[http://schemas.microsoft.com/SQL/Notifications/PostQueryNotification]
)
GO

--*******************************************************************************************************
--*  Execute the following INSERT T-SQL statement when the WinForms application is running.
--*  In this case the DataGridView gets automatically updated because of the created Query Notification.
--*******************************************************************************************************
INSERT INTO Products (ProductName, ProductDescription)
VALUES ('My Product Name2', 'My Product Description2')
GO