using System;
using System.IO;
using System.Xml;
using System.Text;
using System.Data;
using System.Data.SqlTypes;
using System.Data.SqlClient;
using System.Collections.Generic;
using Microsoft.Samples.SqlServer;

namespace OrderServiceLibrary
{
    /// <summary>
    /// This class implements the Service Broker service "OrderService".
    /// </summary>
    public class OrderService : Service
    {
        private Guid _conversationGroupId;
        private bool _creditCardStatus;
        private bool _accountingStatus;
        private bool _inventoryStatus;
        private bool _shippingMessageSent;
        private bool _shippingStatus;

        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="Connection">Name of the Service Broker service</param>
        public OrderService(SqlConnection Connection)
            : base("OrderService", Connection)
        {
            this.WaitforTimeout = TimeSpan.FromSeconds(1);
            this.AppLoaderProcName = "LoadApplicationState";
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

                // Instantiate the Service Broker service "OrderService"
                service = new OrderService(cnn);
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
        /// This method loads the application state from the state table.
        /// </summary>
        /// <param name="reader"></param>
        /// <param name="connection"></param>
        /// <param name="transaction"></param>
        /// <returns></returns>
        public override bool LoadState(SqlDataReader reader, SqlConnection connection, SqlTransaction transaction)
        {
            if (reader.Read())
            {
                _conversationGroupId = new Guid(reader["ConversationGroupID"].ToString());
                _creditCardStatus = bool.Parse(reader["CreditCardStatus"].ToString());
                _accountingStatus = bool.Parse(reader["AccountingStatus"].ToString());
                _inventoryStatus = bool.Parse(reader["InventoryStatus"].ToString());
                _shippingMessageSent = bool.Parse(reader["ShippingMessageSent"].ToString());
                _shippingStatus = bool.Parse(reader["ShippingStatus"].ToString());

                // Advances the cursor to the next resultset that contains the received message(s)
                return reader.NextResult();
            }
            else
                // Something went wrong...
                return false;
        }

        /// <summary>
        /// This method saves the application state to the state table.
        /// </summary>
        /// <param name="connection"></param>
        /// <param name="transaction"></param>
        public override void SaveState(SqlConnection connection, SqlTransaction transaction)
        {
            // Create the T-SQL command for updating the application state
            string sql = "UPDATE ApplicationState SET ";
            sql += "CreditCardStatus = @CreditCardStatus, ";
            sql += "AccountingStatus = @AccountingStatus, ";
            sql += "InventoryStatus = @InventoryStatus, ";
            sql += "ShippingMessageSent = @ShippingMessageSent, ";
            sql += "ShippingStatus = @ShippingStatus ";
            sql += "WHERE ConversationGroupID = @ConversationGroupID";

            // Create the necessary T-SQL parameters
            SqlCommand cmd = new SqlCommand(sql, connection);
            cmd.Transaction = transaction;
            cmd.Parameters.Add("@CreditCardStatus", SqlDbType.Bit);
            cmd.Parameters.Add("@AccountingStatus", SqlDbType.Bit);
            cmd.Parameters.Add("@InventoryStatus", SqlDbType.Bit);
            cmd.Parameters.Add("@ShippingMessageSent", SqlDbType.Bit);
            cmd.Parameters.Add("@ShippingStatus", SqlDbType.Bit);
            cmd.Parameters.Add("@ConversationGroupID", SqlDbType.UniqueIdentifier);

            // Set the T-SQL parameters
            cmd.Parameters["@CreditCardStatus"].Value = _creditCardStatus;
            cmd.Parameters["@AccountingStatus"].Value = _accountingStatus;
            cmd.Parameters["@InventoryStatus"].Value = _inventoryStatus;
            cmd.Parameters["@ShippingMessageSent"].Value = _shippingMessageSent;
            cmd.Parameters["@ShippingStatus"].Value = _shippingStatus;
            cmd.Parameters["@ConversationGroupID"].Value = _conversationGroupId;

            // Execute the query
            cmd.ExecuteNonQuery();
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
        /// This method is executed when the OrderRequestMessage is received from the "ClientService" service.
        /// </summary>
        /// <param name="ReceivedMessage"></param>
        /// <param name="Connection"></param>
        /// <param name="Transaction"></param>
        [BrokerMethod("http://ssb.csharp.at/SSB_Book/c09/OrderRequestMessage")]
        public void ProcessOrderRequestMessage(Message ReceivedMessage, SqlConnection Connection, SqlTransaction Transaction)
        {
            BeginConversationWithCreditCardService(ReceivedMessage, Connection, Transaction);
            BeginConversationWithAccountingService(ReceivedMessage, Connection, Transaction);
            BeginConversationWithInventoryService(ReceivedMessage, Connection, Transaction);
        }

        /// <summary>
        /// This method executes when the AccountingResponseMessage is received from the "AccountingService" service.
        /// </summary>
        /// <param name="ReceivedMessage"></param>
        /// <param name="Connection"></param>
        /// <param name="Transaction"></param>
        [BrokerMethod("http://ssb.csharp.at/SSB_Book/c09/AccountingResponseMessage")]
        public void ProcessAccountingResponseMessage(Message ReceivedMessage, SqlConnection Connection, SqlTransaction Transaction)
        {
            // The AccountingResponseMessage was successfully received
            _accountingStatus = true;

            // Send the shipping request message, if necessary
            SendShippingRequestMessage(ReceivedMessage, Connection, Transaction);
        }

        /// <summary>
        /// This method executes when the CreditCardResponseMessage is received from the "CreditCardService" service.
        /// </summary>
        /// <param name="ReceivedMessage"></param>
        /// <param name="Connection"></param>
        /// <param name="Transaction"></param>
        [BrokerMethod("http://ssb.csharp.at/SSB_Book/c09/CreditCardResponseMessage")]
        public void ProcessCreditCardResponseMessage(Message ReceivedMessage, SqlConnection Connection, SqlTransaction Transaction)
        {
            // The CreditCardResponseMessage was successfully received
            _creditCardStatus = true;

            // Send the shipping request message, if necessary
            SendShippingRequestMessage(ReceivedMessage, Connection, Transaction);
        }

        /// <summary>
        /// This method executes when the InventoryResponseMessage is received from the "InventoryService" service.
        /// </summary>
        /// <param name="ReceivedMessage"></param>
        /// <param name="Connection"></param>
        /// <param name="Transaction"></param>
        [BrokerMethod("http://ssb.csharp.at/SSB_Book/c09/InventoryResponseMessage")]
        public void ProcessInventoryResponseMessage(Message ReceivedMessage, SqlConnection Connection, SqlTransaction Transaction)
        {
            // The InventoryResponseMessage was successfully received
            _inventoryStatus = true;

            // Send the shipping request message, if necessary
            SendShippingRequestMessage(ReceivedMessage, Connection, Transaction);
        }

        /// <summary>
        /// This method executes when the ShippingResponseMessage is received from the "ShippingService" service.
        /// </summary>
        /// <param name="ReceivedMessage"></param>
        /// <param name="Connection"></param>
        /// <param name="Transaction"></param>
        [BrokerMethod("http://ssb.csharp.at/SSB_Book/c09/ShippingResponseMessage")]
        public void ProcessShippingResponseMessage(Message ReceivedMessage, SqlConnection Connection, SqlTransaction Transaction)
        {
            XmlDocument doc = new XmlDocument();
            doc.LoadXml(ReceivedMessage.BodyAsString);

            // Create the order response message
            XmlDocument responseDoc = new XmlDocument();
            XmlElement root = responseDoc.CreateElement("OrderResponse");
            root.InnerText = doc.GetElementsByTagName("ShippingResponse").Item(0).InnerText;
            responseDoc.AppendChild(root);

            // Create the T-SQL command to retrieve the conversation handle back to the client service
            string sql = "SELECT conversation_handle FROM sys.conversation_endpoints WHERE conversation_group_id = @ConversationGroupID AND far_service = 'ClientService'";
            SqlCommand cmd = new SqlCommand(sql, Connection);
            cmd.Transaction = Transaction;
            cmd.Parameters.Add("@ConversationGroupID", SqlDbType.UniqueIdentifier);
            cmd.Parameters["@ConversationGroupID"].Value = _conversationGroupId;

            // Execute the T-SQL command
            SqlDataReader reader = cmd.ExecuteReader();

            if (reader.Read())
            {
                // Recreate the conversation object that represents the conversation back to the client service
                Conversation conv = new Conversation(reader.GetGuid(0));
                reader.Close();

                // Send the response message back to the OrderService
                conv.Send(new Message("http://ssb.csharp.at/SSB_Book/c09/OrderResponseMessage",
                    new MemoryStream(Encoding.Unicode.GetBytes(responseDoc.InnerXml))), Connection, Transaction);

                // End the conversation with the OrderService
                conv.End(Connection, Transaction);
            }

            // The shipment was successfully completed
            _shippingStatus = true;
        }

        /// <summary>
        /// This method sends a shipping request message to the shipping service, if we already got a response from all the other services.
        /// </summary>
        /// <param name="ReceivedMessage"></param>
        /// <param name="Connection"></param>
        /// <param name="Transaction"></param>
        private void SendShippingRequestMessage(Message ReceivedMessage, SqlConnection Connection, SqlTransaction Transaction)
        {
            // If we received all response messages from all the other services, we can send the final message to the shipping service
            if (_accountingStatus && _creditCardStatus && _inventoryStatus)
            {
                // SELECT the original order request message from the OrderQueue - RETENTION makes it possible
                string sql = "SELECT CAST(message_body AS XML) FROM OrderQueue WHERE conversation_group_id = @ConversationGroupID AND " +
                    "message_type_name = 'http://ssb.csharp.at/SSB_Book/c09/OrderRequestMessage'";

                SqlCommand cmd = new SqlCommand(sql, Connection);
                cmd.Transaction = Transaction;

                // Create and set the parameters for the T-SQL command
                cmd.Parameters.Add("@ConversationGroupID", SqlDbType.UniqueIdentifier);
                cmd.Parameters["@ConversationGroupID"].Value = _conversationGroupId;

                // Execute the T-SQL command
                SqlDataReader reader = cmd.ExecuteReader();

                if (reader.Read())
                {
                    // Get the <ShippingNode> from the original order request message
                    SqlXml xml = reader.GetSqlXml(0);
                    XmlDocument requestDoc = new XmlDocument();
                    requestDoc.LoadXml(reader.GetSqlXml(0).Value);
                    reader.Close();
                    string shippingNode = requestDoc.SelectSingleNode("OrderRequest/Shipping").OuterXml;

                    // Send the request message to the shipping service
                    Conversation conv = this.BeginDialog("ShippingService", null, "http://ssb.csharp.at/SSB_Book/c09/ShippingContract", TimeSpan.FromSeconds(999999), false, ReceivedMessage.Conversation, Connection, Transaction);
                    conv.Send(new Message("http://ssb.csharp.at/SSB_Book/c09/ShippingRequestMessage", new MemoryStream(Encoding.Unicode.GetBytes(shippingNode))), Connection, Transaction);

                    // The shipping request message was successfully sent
                    _shippingMessageSent = true;
                }
            }
        }

        /// <summary>
        /// Begins a new conversation with the InventoryService.
        /// </summary>
        /// <param name="ReceivedMessage"></param>
        /// <param name="Connection"></param>
        /// <param name="Transaction"></param>
        private void BeginConversationWithInventoryService(Message ReceivedMessage, SqlConnection Connection, SqlTransaction Transaction)
        {
            XmlDocument doc = new XmlDocument();
            doc.LoadXml(ReceivedMessage.BodyAsString);

            int quantity = int.Parse(doc.GetElementsByTagName("Quantity").Item(0).InnerText);

            XmlDocument inventoryDoc = new XmlDocument();
            XmlElement root = inventoryDoc.CreateElement("InventoryRequest");
            XmlElement inventoryProductID = inventoryDoc.CreateElement("ProductID");
            XmlElement inventoryQuantity = inventoryDoc.CreateElement("Quantity");

            inventoryProductID.InnerText = doc.GetElementsByTagName("ProductID").Item(0).InnerText;
            inventoryQuantity.InnerText = (quantity).ToString();

            root.AppendChild(inventoryProductID);
            root.AppendChild(inventoryQuantity);
            inventoryDoc.AppendChild(root);

            Conversation conv = this.BeginDialog("InventoryService", null, "http://ssb.csharp.at/SSB_Book/c09/InventoryContract", TimeSpan.FromSeconds(999999), false, ReceivedMessage.Conversation, Connection, Transaction);
            conv.Send(new Message("http://ssb.csharp.at/SSB_Book/c09/InventoryRequestMessage", new MemoryStream(Encoding.Unicode.GetBytes(inventoryDoc.InnerXml))), Connection, Transaction);
        }

        /// <summary>
        /// Begins a new conversation with the AccountingService.
        /// </summary>
        /// <param name="ReceivedMessage"></param>
        /// <param name="Connection"></param>
        /// <param name="Transaction"></param>
        private void BeginConversationWithAccountingService(Message ReceivedMessage, SqlConnection Connection, SqlTransaction Transaction)
        {
            XmlDocument doc = new XmlDocument();
            doc.LoadXml(ReceivedMessage.BodyAsString);

            int quantity = int.Parse(doc.GetElementsByTagName("Quantity").Item(0).InnerText);
            double price = double.Parse(doc.GetElementsByTagName("Price").Item(0).InnerText);

            XmlDocument accountingDoc = new XmlDocument();
            XmlElement root = accountingDoc.CreateElement("AccountingRequest");
            XmlElement accountingCustomerID = accountingDoc.CreateElement("CustomerID");
            XmlElement accountingAmount = accountingDoc.CreateElement("Amount");

            accountingCustomerID.InnerText = doc.GetElementsByTagName("CustomerID").Item(0).InnerText;
            accountingAmount.InnerText = (price * quantity).ToString();

            root.AppendChild(accountingCustomerID);
            root.AppendChild(accountingAmount);
            accountingDoc.AppendChild(root);

            Conversation conv = this.BeginDialog("AccountingService", null, "http://ssb.csharp.at/SSB_Book/c09/AccountingContract", TimeSpan.FromMinutes(99999), false, ReceivedMessage.Conversation, Connection, Transaction);
            conv.Send(new Message("http://ssb.csharp.at/SSB_Book/c09/AccountingRequestMessage", new MemoryStream(Encoding.Unicode.GetBytes(accountingDoc.InnerXml))), Connection, Transaction);
        }

        /// <summary>
        /// Begins a new conversation with the CreditCardService.
        /// </summary>
        /// <param name="ReceivedMessage"></param>
        /// <param name="Connection"></param>
        /// <param name="Transaction"></param>
        private void BeginConversationWithCreditCardService(Message ReceivedMessage, SqlConnection Connection, SqlTransaction Transaction)
        {
            XmlDocument doc = new XmlDocument();
            doc.LoadXml(ReceivedMessage.BodyAsString);

            int quantity = int.Parse(doc.GetElementsByTagName("Quantity").Item(0).InnerText);
            double price = double.Parse(doc.GetElementsByTagName("Price").Item(0).InnerText);

            XmlDocument creditCardDoc = new XmlDocument();
            XmlElement root = creditCardDoc.CreateElement("CreditCardRequest");
            XmlElement creditCardHolderElement = creditCardDoc.CreateElement("Holder");
            XmlElement creditCardNumberElement = creditCardDoc.CreateElement("Number");
            XmlElement creditCardVaildThrough = creditCardDoc.CreateElement("ValidThrough");
            XmlElement creditCardAmount = creditCardDoc.CreateElement("Amount");

            creditCardHolderElement.InnerText = doc.GetElementsByTagName("Holder").Item(0).InnerText;
            creditCardNumberElement.InnerText = doc.GetElementsByTagName("Number").Item(0).InnerText;
            creditCardVaildThrough.InnerText = doc.GetElementsByTagName("ValidThrough").Item(0).InnerText;
            creditCardAmount.InnerText = (price * quantity).ToString();

            root.AppendChild(creditCardHolderElement);
            root.AppendChild(creditCardNumberElement);
            root.AppendChild(creditCardVaildThrough);
            root.AppendChild(creditCardAmount);
            creditCardDoc.AppendChild(root);

            Conversation conv = this.BeginDialog("CreditCardService", null, "http://ssb.csharp.at/SSB_Book/c09/CreditCardContract", TimeSpan.FromSeconds(999999), false, ReceivedMessage.Conversation, Connection, Transaction);
            conv.Send(new Message("http://ssb.csharp.at/SSB_Book/c09/CreditCardRequestMessage", new MemoryStream(Encoding.Unicode.GetBytes(creditCardDoc.InnerXml))), Connection, Transaction);
        }
    }
}