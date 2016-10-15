--*************************************
--*  Create a new database master key
--*************************************
USE master
GO

CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'password1!'
GO

--**********************************************************************
--*  Create the certificate that holds both the public and private key
--**********************************************************************
CREATE CERTIFICATE MessageForwardingServiceCertPrivate
	WITH SUBJECT = 'For Service Broker authentication - MessageForwardingServiceCertPrivate',
	START_DATE = '01/01/2007'
GO

--******************************************************
--*  Create the endpoint needed for message forwarding
--******************************************************
CREATE ENDPOINT ForwardingServiceEndpoint
STATE = STARTED
AS TCP 
(
	LISTENER_PORT = 4740
)
FOR SERVICE_BROKER 
(
	AUTHENTICATION = CERTIFICATE MessageForwardingServiceCertPrivate,
	MESSAGE_FORWARDING = ENABLED
)
GO

--*********************************************************
--*  Backup the public key of the new created certificate
--*********************************************************
BACKUP CERTIFICATE MessageForwardingServiceCertPrivate
	TO FILE = 'c:\MessageForwardingServiceCertPublic.cert'
GO

--************************************************
--*  Add the login for the ClientService service
--************************************************
CREATE LOGIN ClientServiceLogin WITH PASSWORD = 'password1!'
GO

CREATE USER ClientServiceUser FOR LOGIN ClientServiceLogin
GO

--*************************************************************
--*  Import the public key certificate from the ClientService
--*************************************************************
CREATE CERTIFICATE ClientServiceCertPublic
	AUTHORIZATION ClientServiceUser
	FROM FILE = 'c:\ClientServiceCertPublic.cert'
GO

--******************************************************
--*  Grant the CONNECT permission to the ClientService
--******************************************************
GRANT CONNECT ON ENDPOINT::ForwardingServiceEndpoint TO ClientServiceLogin
GO

--***********************************************
--*  Add the login for the OrderService service
--***********************************************
CREATE LOGIN OrderServiceLogin WITH PASSWORD = 'password1!'
GO

CREATE USER OrderServiceUser FOR LOGIN OrderServiceLogin
GO

--************************************************************
--*  Import the public key certificate from the OrderService
--************************************************************
CREATE CERTIFICATE OrderServiceCertPublic
	AUTHORIZATION OrderServiceUser
	FROM FILE = 'c:\OrderServiceCertPublic.cert'
GO

--*****************************************************
--*  Grant the CONNECT permission to the OrderService
--*****************************************************
GRANT CONNECT ON ENDPOINT::ForwardingServiceEndpoint TO OrderServiceLogin
GO

USE msdb
GO

--*****************************************
--*  Create the route to the OrderService
--*****************************************
CREATE ROUTE OrderServiceRoute
	WITH SERVICE_NAME = 'OrderService',
	ADDRESS	= 'TCP://OrderServiceInstance:4742'
GO

--***********************************************
--*  Create the route back to the ClientService
--***********************************************
CREATE ROUTE ClientServiceRoute
	WITH SERVICE_NAME = 'ClientService',
	ADDRESS	= 'TCP://ClientServiceInstance:4741'
GO