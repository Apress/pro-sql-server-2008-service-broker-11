using System;
using System.Xml;
using System.Text;
using System.Collections.Generic;
using ClientApplication.vista_notebook;

namespace ClientApplication
{
    class Program
    {
        static void Main(string[] args)
        {
            string message = "<OrderRequest>" +
                            "<Customer>" +
                                "<CustomerID>4242</CustomerID>" +
                            "</Customer>" +
                            "<Product>" +
                                "<ProductID>123</ProductID>" +
                                "<Quantity>5</Quantity>" +
                                "<Price>40.99</Price>" +
                            "</Product>" +
                            "<CreditCard>" +
                                "<Holder>Klaus Aschenbrenner</Holder>" +
                                "<Number>1234-1234-1234-1234</Number>" +
                                "<ValidThrough>2009-10</ValidThrough>" +
                            "</CreditCard>" +
                            "<Shipping>" +
                                "<Name>Klaus Aschenbrenner</Name>" +
                                "<Address>Wagramer Strasse 4/803</Address>" +
                                "<ZipCode>1220</ZipCode>" +
                                "<City>Vienna</City>" +
                                "<Country>Austria</Country>" +
                            "</Shipping>" +
                        "</OrderRequest>";

            ClientApplication.vista_notebook.WebServiceEndpoint svc = new WebServiceEndpoint();
            XmlDocument doc = new XmlDocument();
            doc.LoadXml(message);

            xml requestMessage = new xml();
            requestMessage.Any = new XmlNode[1] { doc.DocumentElement.ParentNode };

            svc.UseDefaultCredentials = true;
            svc.SendOrderRequestMessage(requestMessage);

            Console.WriteLine("Done");
            Console.ReadLine();
        }
    }
}