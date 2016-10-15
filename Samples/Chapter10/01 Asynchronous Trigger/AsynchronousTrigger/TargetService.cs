using System;
using System.IO;
using System.Xml;
using System.Text;
using System.Data;
using System.Data.SqlClient;
using System.Collections.Generic;
using Microsoft.Samples.SqlServer;

namespace AsynchronousTrigger
{
    /// <summary>
    /// This class implements the TargetService.
    /// </summary>
    public class TargetService : Service
    {
        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="Connection">Name of the Service Broker target service</param>
        public TargetService(SqlConnection Connection) : base("CustomerInsertedService", Connection)
        {
            WaitforTimeout = TimeSpan.FromSeconds(1);
        }

        /// <summary>
        /// This is the entry point for the managed stored procedure used with Service Broker.
        /// </summary>
        public static void ServiceProcedure()
        {
            Service service = null;
            SqlConnection cnn = null;

            try
            {
                // Open the database connection
                cnn = new SqlConnection("context connection=true;");
                cnn.Open();

                // Instantiate the Service Broker service "TargetService"
                service = new TargetService(cnn);
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
        /// This method is called when a new customer was inserted into the database table.
        /// </summary>
        /// <param name="ReceivedMessage"></param>
        /// <param name="Connection"></param>
        /// <param name="Transaction"></param>
        [BrokerMethod("http://ssb.csharp.at/SSB_Book/c10/CustomerInsertedRequestMessage")]
        public void OnCustomerInsertedRequestMessage(Message ReceivedMessage, SqlConnection Connection, SqlTransaction Transaction)
        {
            WriteCustomerDetails(ReceivedMessage.BodyAsString);
        }

        /// <summary>
        /// This method is called, when the client has finished to submit all messages across the same Service Broker conversation.
        /// Therefore we are ending in this case the current conversation.
        /// </summary>
        /// <param name="ReceivedMessage"></param>
        /// <param name="Connection"></param>
        /// <param name="Transaction"></param>
        [BrokerMethod("http://ssb.csharp.at/SSB_Book/c10/EndOfMessageStream")]
        public void EndConversation(Message ReceivedMessage, SqlConnection Connection, SqlTransaction Transaction)
        {
            // Ends the current Service Broker conversation
            ReceivedMessage.Conversation.End(Connection, Transaction);
        }

        /// <summary>
        /// This method writes the Service Broker message to the file system. So the Managed Assembly needs the permission set EXTERNAL ACCESS.
        /// </summary>
        /// <param name="xmlMessage"></param>
        private static void WriteCustomerDetails(string xmlMessage)
        {
            // Loading the message into a XmlDocument
            XmlDocument xmlDoc = new XmlDocument();
            xmlDoc.LoadXml(xmlMessage);

            // Appening data to the text file
            using (StreamWriter writer = new StreamWriter(@"c:\InsertedCustomers.txt", true))
            {
                // Writing the message to the file system
                writer.WriteLine("New Customer arrived:");
                writer.WriteLine("=====================");
                writer.WriteLine("CustomerNumber: " + xmlDoc.SelectSingleNode("//CustomerNumber").InnerText);
                writer.WriteLine("CustomerName: " + xmlDoc.SelectSingleNode("//CustomerName").InnerText);
                writer.WriteLine("CustomerAddress: " + xmlDoc.SelectSingleNode("//CustomerAddress").InnerText);
                writer.WriteLine("EmailAddress: " + xmlDoc.SelectSingleNode("//EmailAddress").InnerText);

                writer.Close();
            }
        }
    }
}