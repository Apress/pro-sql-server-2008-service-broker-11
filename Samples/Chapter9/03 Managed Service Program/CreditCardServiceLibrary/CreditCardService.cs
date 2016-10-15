using System;
using System.IO;
using System.Xml;
using System.Text;
using System.Data;
using System.Data.SqlClient;
using System.Collections.Generic;
using Microsoft.Samples.SqlServer;

namespace CreditCardServiceLibrary
{
    public class CreditCardService : Service
    {
        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="Connection">Name of the Service Broker service</param>
        public CreditCardService(SqlConnection Connection)
            : base("CreditCardService", Connection)
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
                service = new CreditCardService(cnn);
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
        /// This method executes when the CreditCardRequestMessage is received from the OrderService.
        /// </summary>
        /// <param name="ReceivedMessage"></param>
        /// <param name="Connection"></param>
        /// <param name="Transaction"></param>
        [BrokerMethod("http://ssb.csharp.at/SSB_Book/c09/CreditCardRequestMessage")]
        public void ProcessCreditCardRequestMessage(Message ReceivedMessage, SqlConnection Connection, SqlTransaction Transaction)
        {
            XmlDocument doc = new XmlDocument();
            doc.LoadXml(ReceivedMessage.BodyAsString);

            // Create the T-SQL command for updating the application state
            string sql = "INSERT INTO CreditCardTransactions (CreditCardTransactionID, CreditCardHolder, CreditCardNumber, ValidThrough, Amount) VALUES ";
            sql += "(NEWID(), @CreditCardHolder, @CreditCardNumber, @ValidThrough, @Amount)";

            // Create the necessary T-SQL parameters
            SqlCommand cmd = new SqlCommand(sql, Connection);
            cmd.Transaction = Transaction;
            cmd.Parameters.Add("@CreditCardHolder", SqlDbType.NVarChar);
            cmd.Parameters.Add("@CreditCardNumber", SqlDbType.NVarChar);
            cmd.Parameters.Add("@ValidThrough", SqlDbType.NVarChar);
            cmd.Parameters.Add("@Amount", SqlDbType.Decimal);

            // Set the T-SQL parameters
            cmd.Parameters["@CreditCardHolder"].Value = doc.GetElementsByTagName("Holder").Item(0).InnerText;
            cmd.Parameters["@CreditCardNumber"].Value = doc.GetElementsByTagName("Number").Item(0).InnerText;
            cmd.Parameters["@ValidThrough"].Value = doc.GetElementsByTagName("ValidThrough").Item(0).InnerText;
            cmd.Parameters["@Amount"].Value = doc.GetElementsByTagName("Amount").Item(0).InnerText;

            // Execute the query
            cmd.ExecuteNonQuery();

            // Construct the response message
            XmlDocument responseDoc = new XmlDocument();
            XmlElement root = responseDoc.CreateElement("CreditCardResponse");
            root.InnerText = "1";
            responseDoc.AppendChild(root);

            // Send the response message back to the OrderService
            ReceivedMessage.Conversation.Send(new Message("http://ssb.csharp.at/SSB_Book/c09/CreditCardResponseMessage",
                new MemoryStream(Encoding.Unicode.GetBytes(responseDoc.InnerXml))), Connection, Transaction);

            // End the conversation with the OrderService
            ReceivedMessage.Conversation.End(Connection, Transaction);
        }
    }
}