using System;
using System.IO;
using System.Xml;
using System.Text;
using System.Data;
using System.Data.SqlClient;
using System.Collections.Generic;
using Microsoft.Samples.SqlServer;

namespace InventoryServiceLibrary
{
    public class InventoryService : Service
    {
        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="Connection">Name of the Service Broker service</param>
        public InventoryService(SqlConnection Connection)
            : base("InventoryService", Connection)
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

                // Instantiate the Service Broker service "CreditCardService"
                service = new InventoryService(cnn);
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
        /// This method executes when the InventoryRequestMessage is received from the OrderService.
        /// </summary>
        /// <param name="ReceivedMessage"></param>
        /// <param name="Connection"></param>
        /// <param name="Transaction"></param>
        [BrokerMethod("http://ssb.csharp.at/SSB_Book/c09/InventoryRequestMessage")]
        public void ProcessInventoryRequestMessage(Message ReceivedMessage, SqlConnection Connection, SqlTransaction Transaction)
        {
            // Load the request message into an XmlDocument
            XmlDocument doc = new XmlDocument();
            doc.LoadXml(ReceivedMessage.BodyAsString);

            // Construct the response message
            XmlDocument responseDoc = new XmlDocument();
            XmlElement root = responseDoc.CreateElement("InventoryResponse");

            // Extract the needed information from the received request message
            string productId = doc.GetElementsByTagName("ProductID").Item(0).InnerText;
            int quantity = int.Parse(doc.GetElementsByTagName("Quantity").Item(0).InnerText);

            // Create the T-SQL command for querying the current available quantity of the specified product in the request message
            string sql = "SELECT Quantity FROM Inventory WHERE ProductID = @ProductID";

            // Create the necessary T-SQL parameters
            SqlCommand cmd = new SqlCommand(sql, Connection);
            cmd.Transaction = Transaction;
            cmd.Parameters.Add("@ProductID", SqlDbType.NVarChar);
            cmd.Parameters["@ProductID"].Value = productId;

            // Execute the query
            SqlDataReader reader = cmd.ExecuteReader();

            if (reader.Read())
            {
                int currentQuantity = int.Parse(reader["Quantity"].ToString());
                reader.Close();

                int newQuantity = currentQuantity - quantity;

                if (newQuantity > 0)
                {
                    // The request message can be processed
                    root.InnerText = "1";

                    // Create the T-SQL command for updating the inventory table
                    sql = "UPDATE Inventory SET Quantity = @Quantity WHERE ProductID = @ProductID";
                    cmd = new SqlCommand(sql, Connection);
                    cmd.Transaction = Transaction;

                    // Create and set the parameters of the T-SQL command
                    cmd.Parameters.Add("@Quantity", SqlDbType.Int);
                    cmd.Parameters.Add("@ProductID", SqlDbType.NVarChar);
                    cmd.Parameters["@Quantity"].Value = newQuantity;
                    cmd.Parameters["@ProductID"].Value = productId;

                    // Execute the T-SQL command
                    cmd.ExecuteNonQuery();
                }
                else
                {
                    // The request message can't be processed
                    root.InnerText = "0";
                }
            }

            // Send the response message back to the OrderService
            responseDoc.AppendChild(root);
            ReceivedMessage.Conversation.Send(new Message("http://ssb.csharp.at/SSB_Book/c09/InventoryResponseMessage",
                new MemoryStream(Encoding.Unicode.GetBytes(responseDoc.InnerXml))), Connection, Transaction);

            // End the conversation with the OrderService
            ReceivedMessage.Conversation.End(Connection, Transaction);
        }
    }
}