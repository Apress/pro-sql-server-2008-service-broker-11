using System;
using System.IO;
using System.Xml;
using System.Text;
using System.Data;
using System.Data.SqlTypes;
using System.Data.SqlClient;
using System.Collections.Generic;
using Microsoft.Samples.SqlServer;

namespace ClientServiceLibrary
{
    public class ClientService : Service
    {
        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="Connection">Name of the Service Broker service</param>
        public ClientService(SqlConnection Connection)
            : base("ClientService", Connection)
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

                // Instantiate the Service Broker service "ClientService"
                service = new ClientService(cnn);
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
        /// This method is executed when the OrderResponseMessage is received from the "OrderService" service.
        /// </summary>
        /// <param name="ReceivedMessage"></param>
        /// <param name="Connection"></param>
        /// <param name="Transaction"></param>
        [BrokerMethod("http://ssb.csharp.at/SSB_Book/c09/OrderResponseMessage")]
        public void ProcessOrderResponseMessage(Message ReceivedMessage, SqlConnection Connection, SqlTransaction Transaction)
        {
            // You can do here whatever you want when the order was successfully completed...
        }
    }
}