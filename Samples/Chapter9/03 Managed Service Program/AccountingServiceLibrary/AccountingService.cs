using System;
using System.IO;
using System.Xml;
using System.Text;
using System.Data;
using System.Data.SqlClient;
using System.Collections.Generic;
using Microsoft.Samples.SqlServer;

namespace AccountingServiceLibrary
{
    public class AccountingService : Service
    {
        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="Connection">Name of the Service Broker service</param>
        public AccountingService(SqlConnection Connection)
            : base("AccountingService", Connection)
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

                // Instantiate the Service Broker service "AccountingService"
                service = new AccountingService(cnn);
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
        /// This method executes when the AccountingRequestMessage is received from the OrderService.
        /// </summary>
        /// <param name="ReceivedMessage"></param>
        /// <param name="Connection"></param>
        /// <param name="Transaction"></param>
        [BrokerMethod("http://ssb.csharp.at/SSB_Book/c09/AccountingRequestMessage")]
        public void ProcessAccountingRequestMessage(Message ReceivedMessage, SqlConnection Connection, SqlTransaction Transaction)
        {
            XmlDocument doc = new XmlDocument();
            doc.LoadXml(ReceivedMessage.BodyAsString);

            // Create the T-SQL command for updating the application state
            string sql = "INSERT INTO AccountingRecordings (AccountingRecordingsID, CustomerID, Amount) VALUES ";
            sql += "(NEWID(), @CustomerID, @Amount)";

            // Create the necessary T-SQL parameters
            SqlCommand cmd = new SqlCommand(sql, Connection);
            cmd.Transaction = Transaction;
            cmd.Parameters.Add("@CustomerID", SqlDbType.NVarChar);
            cmd.Parameters.Add("@Amount", SqlDbType.Decimal);

            // Set the T-SQL parameters
            cmd.Parameters["@CustomerID"].Value = doc.GetElementsByTagName("CustomerID").Item(0).InnerText;
            cmd.Parameters["@Amount"].Value = decimal.Parse(doc.GetElementsByTagName("Amount").Item(0).InnerText);

            // Execute the query
            cmd.ExecuteNonQuery();

            // Construct the response message
            XmlDocument responseDoc = new XmlDocument();
            XmlElement root = responseDoc.CreateElement("AccountingResponse");
            root.InnerText = "1";
            responseDoc.AppendChild(root);

            // Send the response message back to the OrderService
            ReceivedMessage.Conversation.Send(new Message("http://ssb.csharp.at/SSB_Book/c09/AccountingResponseMessage", 
                new MemoryStream(Encoding.Unicode.GetBytes(responseDoc.InnerXml))), Connection, Transaction);

            // End the conversation with the OrderService
            ReceivedMessage.Conversation.End(Connection, Transaction);
        }
    }
}