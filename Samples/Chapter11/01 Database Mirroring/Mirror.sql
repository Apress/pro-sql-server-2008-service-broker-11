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
CREATE CERTIFICATE OrderServiceCertPrivate
	WITH SUBJECT = 'For Service Broker authentication - OrderServiceCertPrivate',
	START_DATE = '01/01/2007'
GO

--********************************************************************
--*  Create the Service Broker endpoint for this SQL Server instance
--********************************************************************
CREATE ENDPOINT OrderServiceEndpoint
STATE = STARTED
AS TCP 
(
	LISTENER_PORT = 4742
)
FOR SERVICE_BROKER 
(
	AUTHENTICATION = CERTIFICATE OrderServiceCertPrivate
)
GO

--*********************************************************
--*  Backup the public key of the new created certificate
--*********************************************************
BACKUP CERTIFICATE OrderServiceCertPrivate
	TO FILE = 'c:\OrderServiceCertPublic1.cert'
GO

--*********************************************
--*  Add the login from the ClientService service
--*********************************************
CREATE LOGIN ClientServiceLogin WITH PASSWORD = 'password1!'
GO

CREATE USER ClientServiceUser FOR LOGIN ClientServiceLogin
GO

--******************************************************************
--*  Import the public key certificate from the ClientService
--******************************************************************
CREATE CERTIFICATE ClientServiceCertPublic
	AUTHORIZATION ClientServiceUser
	FROM FILE = 'c:\ClientServiceCertPublic.cert'
GO

--***********************************************************
--*  Grant the CONNECT permission to the ClientService
--***********************************************************
GRANT CONNECT ON ENDPOINT::OrderServiceEndpoint TO ClientServiceLogin
GO

--********************************************************************
--*  Create the certificate used for the database mirroring endpoint
--********************************************************************
CREATE CERTIFICATE MirroringCertPrivate
	WITH SUBJECT = 'For database mirroring authentication - MirroringCertPrivate',
	START_DATE = '01/01/2007'
GO

--*******************************************
--*  Create the database mirroring endpoint
--*******************************************
CREATE ENDPOINT MirroringEndpoint
STATE = STARTED
AS TCP 
(
	LISTENER_PORT = 4740
)
FOR DATABASE_MIRRORING
(
	AUTHENTICATION = CERTIFICATE MirroringCertPrivate,
	ROLE = ALL
)
GO

--*********************************************************
--*  Backup the public key of the new created certificate
--*********************************************************
BACKUP CERTIFICATE MirroringCertPrivate
	TO FILE = 'c:\MirroringCertMirrorPublic.cert'
GO

--***************************************************
--*  Add the login for the other mirroring database
--***************************************************
CREATE LOGIN PrincipalLogin WITH PASSWORD = 'password1!'
GO

CREATE USER PrincipalUser FOR LOGIN PrincipalLogin
GO

--************************************************************************
--*  Import the public key certificate from the other mirroring database
--***********************************************************************
CREATE CERTIFICATE PrincipalCertPublic
	AUTHORIZATION PrincipalUser
	FROM FILE = 'c:\MirroringCertPrincipalPublic.cert'
GO

--***********************************************************
--*  Grant the CONNECT permission to the mirroring endpoint
--***********************************************************
GRANT CONNECT ON ENDPOINT::MirroringEndpoint TO PrincipalLogin
GO

--***************************************************
--*  Restore the database from the principal server.
--***************************************************
RESTORE DATABASE [Chapter11_DatabaseMirroring]
	FROM DISK = 'D:\Chapter11_DatabaseMirroring.bak'
	WITH FILE = 1,  
	NOUNLOAD, STATS = 10
GO

--****************************************************
--*  Restore the log file from the principal server.
--****************************************************
RESTORE LOG Chapter11_DatabaseMirroring 
    FROM DISK = 'd:\Chapter11_DatabaseMirroringLog.bak' 
    WITH FILE = 1,
	NORECOVERY
GO

--*******************************************************
--*  Enable database mirroring on the restored database.
--*******************************************************
ALTER DATABASE Chapter11_DatabaseMirroring
SET PARTNER = 'TCP://PrincipalInstance:4740'
GO



ALTER DATABASE Chapter11_DatabaseMirroring
SET PARTNER OFF
GO



drop database Chapter11_DatabaseMirroring


RESTORE LOG Chapter11_DatabaseMirroring 
    FROM DISK = 'd:\Chapter11_DatabaseMirroring.bak' 
    WITH FILE=1, NORECOVERY
GO

select service_broker_guid, * from sys.databases


select * from sys.endpoints

select * from sys.certificates

select * from applicationstate

select * from sys.transmission_queue