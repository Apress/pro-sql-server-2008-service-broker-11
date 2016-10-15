using System;
using System.IO;
using System.Xml;
using System.Text;
using System.Data;
using System.Data.SqlTypes;
using System.Data.SqlClient;
using System.Collections.Generic;
using Microsoft.Samples.SqlServer;

namespace ShippingServiceLibrary
{
    public class ShippingService : Service
    {
        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="Connection">Name of the Service Broker service</param>
        public ShippingService(SqlConnection Connection)
            : base("ShippingService", Connection)
        {
            this.WaitforTimeout = TimeSpan.FromSeconds(1);
        }

        /// <summary>
        /// This is the entry point for the managed stored procedure used with Service Broker.
        /// </summary>
        public static void ServiceProgramProcedure()
        {
            Service service = null;
            SqlConnection cnn = null;

            try
            {
                // Open the database connection
                cnn = new SqlConnection("context connection=true;");
                cnn.Open();

                // Instantiate the Service Broker service "ShippingService"
                service = new ShippingService(cnn);
                service.FetchSize = 1;

                // Run the message loop of the service
                service.Run(true, cnn, null);
            }
            catch (ServiceException ex)
            {
                if (ex.Transaction != null)
                    ex.Transaction.Rollback();
            }
            finally
            {
                if (cnn != null)
                    cnn.Close();
            }
        }

        /// <summary>
        /// This method executes when an EndDialog message is received.
        /// </summary>
        /// <param name="ReceivedMessage"></param>
        /// <param name="Connection"></param>
        /// <param name="Transaction"></param>
        [BrokerMethod("http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog")]
        public void EndDialog(Message ReceivedMessage, SqlConnection Connection, SqlTransaction Transaction)
        {
            ReceivedMessage.Conversation.End(Connection, Transaction);
        }

        /// <summary>
        /// This method executes when the ShippingRequestMessage is received from the OrderService.
        /// </summary>
        /// <param name="ReceivedMessage"></param>
        /// <param name="Connection"></param>
        /// <param name="Transaction"></param>
        [BrokerMethod("http://ssb.csharp.at/SSB_Book/c09/ShippingRequestMessage")]
        public void ProcessShippingRequestMessage(Message ReceivedMessage, SqlConnection Connection, SqlTransaction Transaction)
        {
            XmlDocument doc = new XmlDocument();
            doc.LoadXml(ReceivedMessage.BodyAsString);

            // Create the T-SQL command to insert the shipping information
            string sql = "INSERT INTO ShippingInformation (ShippingID, [Name], Address, ZipCode, City, Country) VALUES ";
            sql += "(NEWID(), @Name, @Address, @ZipCode, @City, @Country)";

            // Create the necessary T-SQL parameters
            SqlCommand cmd = new SqlCommand(sql, Connection);
            cmd.Transaction = Transaction;
            cmd.Parameters.Add("@Name", SqlDbType.NVarChar);
            cmd.Parameters.Add("@Address", SqlDbType.NVarChar);
            cmd.Parameters.Add("@ZipCode", SqlDbType.NVarChar);
            cmd.Parameters.Add("@City", SqlDbType.NVarChar);
            cmd.Parameters.Add("@Country", SqlDbType.NVarChar);

            // Set the T-SQL parameters
            cmd.Parameters["@Name"].Value = doc.GetElementsByTagName("Name").Item(0).InnerText;
            cmd.Parameters["@Address"].Value = doc.GetElementsByTagName("Address").Item(0).InnerText;
            cmd.Parameters["@ZipCode"].Value = doc.GetElementsByTagName("ZipCode").Item(0).InnerText;
            cmd.Parameters["@City"].Value = doc.GetElementsByTagName("City").Item(0).InnerText;
            cmd.Parameters["@Country"].Value = doc.GetElementsByTagName("Country").Item(0).InnerText;

            // Execute the query
            cmd.ExecuteNonQuery();

            // Construct the response message
            XmlDocument responseDoc = new XmlDocument();
            XmlElement root = responseDoc.CreateElement("ShippingResponse");
            root.InnerText = "1";
            responseDoc.AppendChild(root);

            // Send the response message back to the OrderService
            ReceivedMessage.Conversation.Send(new Message("http://ssb.csharp.at/SSB_Book/c09/ShippingResponseMessage",
                new MemoryStream(Encoding.Unicode.GetBytes(responseDoc.InnerXml))), Connection, Transaction);

            // End the conversation with the OrderService
            ReceivedMessage.Conversation.End(Connection, Transaction);
        }
    }
}