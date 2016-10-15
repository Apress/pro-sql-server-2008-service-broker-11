USE master;

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'Chapter10_ReliableWebRequest')
BEGIN
	PRINT 'Dropping database ''Chapter10_ReliableWebRequest''';
	DROP DATABASE Chapter10_ReliableWebRequest;
END
GO

CREATE DATABASE Chapter10_ReliableWebRequest
GO

USE Chapter10_ReliableWebRequest
GO

ALTER DATABASE Chapter10_ReliableWebRequest SET TRUSTWORTHY ON;
GO

USE Chapter10_ReliableWebRequest
GO

--**************************************************
--*  This table maps incoming requests to actions.
--**************************************************
CREATE TABLE RequestFilter
(
	RequestFilterID	INT IDENTITY(1, 1) NOT NULL CONSTRAINT PkRequestFilter PRIMARY KEY,
	Method NCHAR(10),
	UrlPattern NVARCHAR(256),
	Timeout	INT NOT NULL,
	NumberOfRetries	TINYINT NOT NULL, 
	RetryDelay	INT NOT NULL,
	BackoffFactor REAL NOT NULL,
	[Action] TINYINT NOT NULL CONSTRAINT CkRequestAction CHECK (Action >= 0 AND Action <= 1)
)
GO

-- Insert some configuration information
INSERT INTO RequestFilter (Timeout, NumberOfRetries, RetryDelay, BackoffFactor, [Action])
	VALUES (60000, 100, 3, 1, 1);
GO

--***************************************************
--*  This table maps incoming responses to actions.
--***************************************************
CREATE TABLE ResponseFilter
(
	ResponseFilterID INT IDENTITY(1, 1) NOT NULL CONSTRAINT PkResponsePolicy PRIMARY KEY,
	StatusCodeLower SMALLINT NOT NULL,
	StatusCodeUpper SMALLINT,
	[Action] TINYINT NOT NULL CONSTRAINT CkResponseAction CHECK (Action >= 0 AND Action <= 2)
)
GO

-- Insert some configuration information
INSERT INTO ResponseFilter (StatusCodeLower, [Action])
VALUES (200, 0);

INSERT INTO ResponseFilter (StatusCodeLower, StatusCodeUpper, [Action])
VALUES (400, 499, 1);

INSERT INTO ResponseFilter (StatusCodeLower, StatusCodeUpper, [Action])
VALUES (500, 599, 2);
GO

--*******************************************************************
--*  This stored procedure returns the correct HTTP request filter.
--*******************************************************************
CREATE PROCEDURE sp_MatchRequestFilter 
@Method NCHAR(10),
@Url NVARCHAR(256)
AS
BEGIN
	SELECT TOP (1) [Action], Timeout, NumberOfRetries, RetryDelay, BackoffFactor
	FROM RequestFilter
	WHERE
		(Method IS NULL OR Method = @Method) 
		AND (UrlPattern IS NULL OR dbo.RegEx(UrlPattern, @Url) = 1)
	ORDER BY 
		CASE
			WHEN [Action] = 0 THEN 0
			WHEN Method IS NOT NULL AND UrlPattern IS NOT NULL THEN 1
			WHEN Method IS NULL AND UrlPattern IS NOT NULL THEN 2
			WHEN Method IS NULL AND UrlPattern IS NULL THEN 3
			ELSE 4
		END;
END
GO

--********************************************************************
--*  This stored procedure returns the correct HTTP response filter.
--********************************************************************
CREATE PROCEDURE sp_MatchResponseFilter 
@StatusCode SMALLINT
AS
BEGIN
	SELECT TOP(1) [Action]
	FROM ResponseFilter
	WHERE
		(StatusCodeLower = @StatusCode AND StatusCodeUpper IS NULL)
		OR (StatusCodeLower <= @StatusCode AND StatusCodeUpper >= @StatusCode)
	ORDER BY
		CASE
			WHEN StatusCodeLower = @StatusCode AND StatusCodeUpper IS NULL THEN 0
			ELSE 1
		END
END
GO

--*********************************************************************************************
--*  Create an XML schema collection that stores the XML schema for the HTTP request message.
--*********************************************************************************************
CREATE XML SCHEMA COLLECTION HttpRequestSchema AS
N'<xsd:schema xmlns:xsd="http://www.w3.org/2001/XMLSchema" 
		targetNamespace="http://ssb.csharp.at/SSB_Book/c10/ReliableWebRequestsSchema"
		      xmlns:tns="http://ssb.csharp.at/SSB_Book/c10/ReliableWebRequestsSchema">
	<xsd:complexType name="headerType">
		<xsd:attribute name="name" type="xsd:string" use="required" />
		<xsd:attribute name="value" type="xsd:string" use="required" />
	</xsd:complexType>
	<xsd:complexType name="headersType">
		<xsd:sequence>
			<xsd:element name="header" type="tns:headerType" minOccurs="1" maxOccurs="unbounded" />
		</xsd:sequence>
	</xsd:complexType>
	<xsd:complexType name="httpRequestType">
		<xsd:sequence>
			<xsd:element name="headers" type="tns:headersType" minOccurs="0" maxOccurs="1" />
			<xsd:element name="body" type="xsd:base64Binary" minOccurs="0" maxOccurs="1" />
		</xsd:sequence>
		<xsd:attribute name="method" type="xsd:string" use="optional" default="GET" />
		<xsd:attribute name="url" type="xsd:anyURI" use="required" />
		<xsd:attribute name="protocolVersion" type="xsd:string" use="optional" default="HTTP/1.1"/>
	</xsd:complexType>
	<xsd:element name="httpRequest" type="tns:httpRequestType" />
</xsd:schema>'
GO

--**********************************************************************************************
--*  Create an XML schema collection that stores the XML schema for the HTTP response message.
--**********************************************************************************************
CREATE XML SCHEMA COLLECTION HttpResponseSchema AS
N'<xsd:schema xmlns:xsd="http://www.w3.org/2001/XMLSchema" 
		targetNamespace="http://ssb.csharp.at/SSB_Book/c10/ReliableWebRequestsSchema"
		      xmlns:tns="http://ssb.csharp.at/SSB_Book/c10/ReliableWebRequestsSchema">
	<xsd:complexType name="headerType">
		<xsd:attribute name="name" type="xsd:string" use="required" />
		<xsd:attribute name="value" type="xsd:string" use="required" />
	</xsd:complexType>
	<xsd:complexType name="headersType">
		<xsd:sequence>
			<xsd:element name="header" type="tns:headerType" minOccurs="1" maxOccurs="unbounded" />
		</xsd:sequence>
	</xsd:complexType>
	<xsd:complexType name="httpResponseType">
		<xsd:sequence>
			<xsd:element name="headers" type="tns:headersType" minOccurs="0" maxOccurs="1" />
			<xsd:element name="body" type="xsd:base64Binary" minOccurs="0" maxOccurs="1" />
		</xsd:sequence>
		<xsd:attribute name="protocolVersion" type="xsd:string" use="optional" default="HTTP/1.1"/>
		<xsd:attribute name="statusCode" type="xsd:string" use="optional" default="GET" />
		<xsd:attribute name="statusDescription" type="xsd:anyURI" use="required" />
	</xsd:complexType>
	<xsd:element name="httpResponse" type="tns:httpResponseType" />
</xsd:schema>'
GO

--*************************************
--*  Create the needed message types.
--*************************************
CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c10/HttpRequestMessageType]
VALIDATION = VALID_XML WITH SCHEMA COLLECTION HttpRequestSchema;
CREATE MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c10/HttpResponseMessageType]
VALIDATION = VALID_XML WITH SCHEMA COLLECTION HttpResponseSchema;
GO

--******************************
--*  Create the used contract.
--******************************
CREATE CONTRACT [http://ssb.csharp.at/SSB_Book/c10/ReliableWebRequestContract]
(
	[http://ssb.csharp.at/SSB_Book/c10/HttpRequestMessageType]  SENT BY INITIATOR,
	[http://ssb.csharp.at/SSB_Book/c10/HttpResponseMessageType] SENT BY TARGET
)
GO

--**********************************
--*  Create the initiator service.
--**********************************
CREATE QUEUE [WebClientQueue];
CREATE SERVICE [WebClientService] ON QUEUE [WebClientQueue];
GO

--*******************************
--*  Create the target service.
--*******************************
CREATE QUEUE [WebProxyQueue];
CREATE SERVICE [WebProxyService] ON QUEUE [WebProxyQueue]
(
	[http://ssb.csharp.at/SSB_Book/c10/ReliableWebRequestContract]
);
GO

--**************************************************************************************
--*  This table stores the pending requests that must be forwarded to the web service.
--**************************************************************************************
CREATE TABLE PendingRequest
(
	ConversationHandle UNIQUEIDENTIFIER NOT NULL CONSTRAINT PkPendingRequest PRIMARY KEY,
	RequestBody VARBINARY(MAX) NOT NULL,
	RetriesUsed	TINYINT NOT NULL,
	Status NVARCHAR(MAX)
)
GO

CREATE PROCEDURE sp_AddOrUpdatePendingRequest
	@ConversationHandle UNIQUEIDENTIFIER,
	@RequestBody VARBINARY(MAX),
	@RetriesUsed TINYINT,
	@Status NVARCHAR(256)
AS
BEGIN
	BEGIN TRANSACTION;

	IF (EXISTS 
	(
		SELECT * FROM PendingRequest WHERE ConversationHandle = @ConversationHandle
	))
	BEGIN
		UPDATE PendingRequest SET 
			RetriesUsed = @RetriesUsed, 
			Status = @Status
		WHERE ConversationHandle = @ConversationHandle
	END
	ELSE
	BEGIN
		INSERT INTO PendingRequest (ConversationHandle, RequestBody, RetriesUsed, Status)
		VALUES 
		(
			@ConversationHandle,
			@RequestBody,
			@RetriesUsed, 
			@Status
		);
	END

	COMMIT;
END
GO

--**********************************************
--*  Registering the managed stored procedure.
--**********************************************
CREATE ASSEMBLY [ServiceBrokerInterface]
FROM 'D:\Klaus\Work\Autorentätigkeit\Apress\Pro SQL 2005 Service Broker\Chapter 10\Samples\05 Reliable Web Requests\WebProxy\WebProxy\bin\Debug\ServiceBrokerInterface.dll'
WITH PERMISSION_SET = EXTERNAL_ACCESS
GO

CREATE ASSEMBLY [WebProxy]
FROM 'D:\Klaus\Work\Autorentätigkeit\Apress\Pro SQL 2005 Service Broker\Chapter 10\Samples\05 Reliable Web Requests\WebProxy\WebProxy\bin\Debug\WebProxy.dll'
WITH PERMISSION_SET = EXTERNAL_ACCESS;
GO

CREATE ASSEMBLY [WebProxy.XmlSerializers]
FROM 'D:\Klaus\Work\Autorentätigkeit\Apress\Pro SQL 2005 Service Broker\Chapter 10\Samples\05 Reliable Web Requests\WebProxy\WebProxy\bin\Debug\WebProxy.XmlSerializers.dll'
WITH PERMISSION_SET = EXTERNAL_ACCESS;
GO

ALTER ASSEMBLY [WebProxy]
ADD FILE FROM 'D:\Klaus\Work\Autorentätigkeit\Apress\Pro SQL 2005 Service Broker\Chapter 10\Samples\05 Reliable Web Requests\WebProxy\WebProxy\bin\Debug\WebProxy.pdb'
GO

--*******************************************
--*  Creating the managed stored procedure.
--*******************************************
CREATE PROCEDURE sp_WebProxyService
AS EXTERNAL NAME [WebProxy].[Microsoft.Samples.SqlServer.WebProxyService].Run
GO

--***************************************
--*  Creating a managed RegEx function.
--***************************************
CREATE FUNCTION RegEx 
(
@Pattern NVARCHAR(MAX),
@MatchString NVARCHAR(MAX)
)
RETURNS BIT
AS EXTERNAL NAME [WebProxy].[Microsoft.Samples.SqlServer.WebProxyService].RegexMatchCaseInsensitive
GO

--**************************************************************
--*  Creating the managed functions used for BASE64 encodings.
--**************************************************************
CREATE FUNCTION EncodeToBase64
(
@Content NVARCHAR(MAX)
)
RETURNS NVARCHAR(MAX)
AS EXTERNAL NAME [WebProxy].[Microsoft.Samples.SqlServer.WebProxyService].EncodeToBase64
GO

CREATE FUNCTION EncodeFromBase64
(
@Content NVARCHAR(MAX)
)
RETURNS NVARCHAR(MAX)
AS EXTERNAL NAME [WebProxy].[Microsoft.Samples.SqlServer.WebProxyService].EncodeFromBase64
GO

--********************************************************************
--*  Configure the managed stored procedure for internal activation.
--********************************************************************
ALTER QUEUE WebProxyQueue 
WITH ACTIVATION 
(
	STATUS = ON,
	PROCEDURE_NAME = sp_WebProxyService,
	MAX_QUEUE_READERS = 1,
	EXECUTE AS SELF
)
GO

--*********************************************
--*  Send a new reliable web service request.
--*********************************************
BEGIN TRANSACTION
DECLARE @conversationHandle UNIQUEIDENTIFIER
DECLARE @messageBody NVARCHAR(MAX)

SET @messageBody = 
'
<soap:Envelope 
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
	xmlns:xsd="http://www.w3.org/2001/XMLSchema" 
	xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
	<soap:Body>
		<HelloWorld xmlns="http://tempuri.org/" />
	</soap:Body>
</soap:Envelope>
'

BEGIN DIALOG @conversationHandle
	FROM SERVICE [WebClientService]
	TO SERVICE 'WebProxyService'
	ON CONTRACT [http://ssb.csharp.at/SSB_Book/c10/ReliableWebRequestContract]
	WITH ENCRYPTION = OFF;

SEND ON CONVERSATION @conversationHandle
MESSAGE TYPE [http://ssb.csharp.at/SSB_Book/c10/HttpRequestMessageType]
(
	CAST(N'
		<tns:httpRequest url="http://localhost:8080/WebService/Service.asmx" method="POST" xsi:schemaLocation="http://ssb.csharp.at/SSB_Book/c10/ReliableWebRequestsSchema/MessageTypes.xsd" xmlns:tns="http://ssb.csharp.at/SSB_Book/c10/ReliableWebRequestsSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
			<headers>
				<header name="SOAPAction" value="http://www.csharp.at/HelloWorld" />
				<header name="Content-Type" value="text/xml; charset=utf-8" />
			</headers>
			<body>' + dbo.EncodeToBase64(@messageBody) +
			'</body>
		</tns:httpRequest>
		'
	AS XML)
)
COMMIT
GO

--***********************************************
--*  Receive the reliable web service response.
--***********************************************
DECLARE @response XML

SELECT
	TOP (1) @response = message_body FROM WebClientQueue
WHERE message_type_name = 'http://ssb.csharp.at/SSB_Book/c10/HttpResponseMessageType'

IF (@response IS NOT NULL)
BEGIN
	SELECT
		dbo.EncodeFromBase64(@response.value(
		'declare namespace WS="http://ssb.csharp.at/SSB_Book/c10/ReliableWebRequestsSchema";
		/WS:httpResponse[1]/body[1]', 'NVARCHAR(MAX)'));

	RECEIVE TOP (1) * FROM WebClientQueue
END
GO

select * from pendingrequest

select cast(message_body as xml), * from webclientqueue