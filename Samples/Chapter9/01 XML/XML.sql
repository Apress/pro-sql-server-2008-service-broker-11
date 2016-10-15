--*********************************************
--*  Using the XML data type method "query()"
--*********************************************
DECLARE @myDoc XML
SET @myDoc = 
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
</OrderRequest>'

-- Extracting some information from the XML data
SELECT
	@myDoc.query('/OrderRequest/Customer') AS 'Customer',
	@myDoc.query('/OrderRequest/Product') AS 'Product',
	@myDoc.query('/OrderRequest/CreditCard') AS 'CreditCard',
	@myDoc.query('/OrderRequest/Shipping') AS 'Shipping'

--*********************************************
--*  Using the XML data type method "value()"
--*********************************************
SELECT 
	@myDoc.value('/OrderRequest[1]/CreditCard[1]/Holder[1]', 'NVARCHAR(256)') AS 'CreditCardHolder',
	@myDoc.value('/OrderRequest[1]/CreditCard[1]/Number[1]', 'NVARCHAR(256)') AS 'CreditCardNumber',
	@myDoc.value('/OrderRequest[1]/CreditCard[1]/ValidThrough[1]', 'NVARCHAR(256)') AS 'ValidThrough',
	@myDoc.value('/OrderRequest[1]/Product[1]/Quantity[1]', 'INT') AS 'Quantity',
	@myDoc.value('/OrderRequest[1]/Product[1]/Price[1]', 'DECIMAL(18, 2)') AS 'Price',
	@myDoc.value('/OrderRequest[1]/Customer[1]/CustomerID[1]', 'NVARCHAR(256)') AS 'CustomerID',
	@myDoc.value('/OrderRequest[1]/Product[1]/ProductID[1]', 'INT') AS 'ProductID'

--*********************************************
--*  Using the XML data type method "exist()"
--*********************************************
SELECT
	@myDoc.exist('/OrderRequest[1]/CreditCard') AS 'CreditCardAvailable',
	@myDoc.exist('/OrderRequest[1]/Inventory') AS 'InventoryDataAvailable'

--*********************************************
--*  Using the XML data type method "modify()"
--*********************************************
SET @myDoc.modify('insert <MyNewNode></MyNewNode> as first into (/OrderRequest)[1]')
SELECT @myDoc

--*********************************************
--*  Using the XML data type method "nodes()"
--*********************************************
SELECT T.c.query('.') AS result FROM @myDoc.nodes('/OrderRequest') T(c)