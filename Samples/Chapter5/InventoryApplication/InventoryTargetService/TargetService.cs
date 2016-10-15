using System;
using System.IO;
using System.Xml;
using System.Text;
using System.Data;
using System.Data.SqlClient;
using System.Collections.Generic;
using Microsoft.Samples.SqlServer;

namespace InventoryTargetService
{
	/// <summary>
	/// This class implements the Service Broker service "InventoryTargetService".
	/// </summary>
	public class TargetService : Service
	{
		/// <summary>
		/// Constructor
		/// </summary>
		/// <param name="Connection">Name of the Service Broker target service</param>
		public TargetService(SqlConnection Connection) : base("InventoryTargetService", Connection)
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
		/// This method is called when a message for updating the inventory is received.
		/// </summary>
		/// <param name="ReceivedMessage"></param>
		/// <param name="Connection"></param>
		/// <param name="Transaction"></param>
		[BrokerMethod("http://ssb.csharp.at/SSB_Book/c05/InventoryUpdateMessage")]
		public void ProcessInventoryUpdate(Message ReceivedMessage, SqlConnection Connection, SqlTransaction Transaction)
		{
			try
			{
				XmlDocument doc = new XmlDocument();
				doc.LoadXml(ReceivedMessage.BodyAsString);

				// Locate elements in DOM
				XmlNodeList list = doc.GetElementsByTagName("InventoryId");
				string inventoryId = list.Item(0).InnerXml;

				list = doc.GetElementsByTagName("Quantity");
				int quantity = Convert.ToInt32(list.Item(0).InnerXml);
				 
				// Updating the inventory
				UpdateInventory(Connection, Transaction, inventoryId, quantity);

				// End the conversation between the two services
				ReceivedMessage.Conversation.End(Connection, Transaction);
			}
			catch (Exception ex)
			{
				// An error occured during the inventory update
				ReceivedMessage.Conversation.EndWithError(1, ex.Message, Connection, Transaction);
			}
		}

		/// <summary>
		/// This method is called when a message for removing items from the inventory is received.
		/// </summary>
		/// <param name="ReceivedMessage"></param>
		/// <param name="Connection"></param>
		/// <param name="Transaction"></param>
		[BrokerMethod("http://ssb.csharp.at/SSB_Book/c05/InventoryQueryRequestMessage")]
		public void ProcessInventoryQueryRequest(Message ReceivedMessage, SqlConnection Connection, SqlTransaction Transaction)
		{
			try
			{
				XmlDocument doc = new XmlDocument();
				doc.LoadXml(ReceivedMessage.BodyAsString);

				// Locate elements in DOM
				XmlNodeList list = doc.GetElementsByTagName("InventoryId");
				string inventoryId = list.Item(0).InnerXml;

				list = doc.GetElementsByTagName("Quantity");
				int quantity = Convert.ToInt32(list.Item(0).InnerXml);

				// Remove the items from the inventory, if the items are available
				bool rc = CheckInventory(Connection, Transaction, inventoryId, quantity);

				// Send a response message back to the initiator of the conversation
				SendCustomerReply(ReceivedMessage.Conversation, Connection, Transaction, rc);
			}
			catch (Exception ex)
			{
				// An error occured during the inventory update
				ReceivedMessage.Conversation.EndWithError(1, ex.Message, Connection, Transaction);
			}
		}

		/// <summary>
		/// This method is called when a EndDialog message is received on the queue "TargetQueue".
		/// </summary>
		/// <param name="ReceivedMessage"></param>
		/// <param name="Connection"></param>
		/// <param name="Transaction"></param>
		[BrokerMethod(Message.EndDialogType)]
		public void EndConversation(Message ReceivedMessage, SqlConnection Connection, SqlTransaction Transaction)
		{
			// Ends the current Service Broker conversation
			ReceivedMessage.Conversation.End(Connection, Transaction);
		}

		/// <summary>
		/// This method is called when a Error message is received on the queue "TargetQueue".
		/// </summary>
		/// <param name="ReceivedMessage"></param>
		/// <param name="Connection"></param>
		/// <param name="Transaction"></param>
		[BrokerMethod(Message.ErrorType)]
		public void ProcessErrorMessages(Message ReceivedMessage, SqlConnection Connection, SqlTransaction Transaction)
		{
			// Ends the current Service Broker conversation due to an error
			ReceivedMessage.Conversation.End(Connection, Transaction);
		}

		/// <summary>
		/// This method updates the inventory according to the quantity of the given InventoryId.
		/// </summary>
		/// <param name="Connection"></param>
		/// <param name="Transaction"></param>
		/// <param name="InventoryId"></param>
		/// <param name="Quantity"></param>
		private void UpdateInventory(SqlConnection Connection, SqlTransaction Transaction, string InventoryId, int Quantity)
		{
			// Creating the SqlCommand
			SqlCommand cmd = new SqlCommand("UPDATE Inventory SET Quantity = Quantity + @Quantity  " +
				"WHERE InventoryId = @InventoryId", Connection);
			cmd.Transaction = Transaction;

			// Add InventoryId parameter 
			SqlParameter paramInventoryId = new SqlParameter("@InventoryId", SqlDbType.NVarChar, 10);
			paramInventoryId.Value = InventoryId;
			cmd.Parameters.Add(paramInventoryId);

			// Add Quantity parameter
			SqlParameter paramQuantity = new SqlParameter("@Quantity", SqlDbType.Int);
			paramQuantity.Value = Quantity;
			cmd.Parameters.Add(paramQuantity);

			// Execute the SqlCommand
			cmd.ExecuteNonQuery();
		}

		/// <summary>
		/// This method checks if the inventory has the required items in stock.
		/// If yes, then the items are removed from the inventory through a call to the method "SubtractFromInventory".
		/// </summary>
		/// <param name="Connection"></param>
		/// <param name="Transaction"></param>
		/// <param name="InventoryId"></param>
		/// <param name="Quantity"></param>
		/// <returns></returns>
		private bool CheckInventory(SqlConnection Connection, SqlTransaction Transaction, string InventoryId, int Quantity)
		{
			int realQuantity;

			// Create Instance of Connection and Command Object
			SqlCommand cmd = new SqlCommand("SELECT Quantity FROM Inventory WHERE InventoryId = @InventoryId", Connection);
			cmd.Transaction = Transaction;

			// Add InventoryId parameter 
			SqlParameter paramInventoryId = new SqlParameter("@InventoryId", SqlDbType.NVarChar, 10);
			paramInventoryId.Value = InventoryId;
			cmd.Parameters.Add(paramInventoryId);

			SqlDataReader reader = cmd.ExecuteReader();

			if (reader.Read())
			{
				realQuantity = reader.GetInt32(0);
				reader.Close();

				if (Quantity <= realQuantity)
				{
					SubtractFromInventory(Connection, Transaction, InventoryId, Quantity);
					return true;
				}
				else return false;
			}
			else
			{
				reader.Close();
				return false;
			}
		}

		/// <summary>
		/// This method removes the required items from the inventory.
		/// </summary>
		/// <param name="Connection"></param>
		/// <param name="Transaction"></param>
		/// <param name="InventoryId"></param>
		/// <param name="Quantity"></param>
		private void SubtractFromInventory(SqlConnection Connection, SqlTransaction Transaction, string InventoryId, int Quantity)
		{
			// Create the SqlCommand
			SqlCommand cmd = new SqlCommand("UPDATE Inventory SET Quantity = Quantity - @Quantity WHERE InventoryId = @InventoryId", Connection);
			cmd.Transaction = Transaction;

			// Add InventoryId parameter
			SqlParameter paramInventoryId = new SqlParameter("@InventoryId", SqlDbType.NVarChar, 10);
			paramInventoryId.Value = InventoryId;
			cmd.Parameters.Add(paramInventoryId);

			// Add Quantity parameter
			SqlParameter paramQuantity = new SqlParameter("@Quantity", SqlDbType.Int);
			paramQuantity.Value = Quantity;
			cmd.Parameters.Add(paramQuantity);

			// Execute the SqlCommand
			cmd.ExecuteNonQuery();
		}

		/// <summary>
		/// This method sends a response message back to the initiator of the conversation.
		/// </summary>
		/// <param name="Conversation"></param>
		/// <param name="Connection"></param>
		/// <param name="Transaction"></param>
		/// <param name="InStockFlag"></param>
		private void SendCustomerReply(Conversation Conversation, SqlConnection Connection, SqlTransaction Transaction, bool InStockFlag)
		{
			// Create the XML response message
			XmlDocument doc = new XmlDocument();
			XmlElement root = doc.CreateElement("InventoryResponse");
			doc.AppendChild(root);

			XmlElement response = doc.CreateElement("Response");

			if (InStockFlag)
				response.InnerText = "In stock";
			else
				response.InnerText = "Out of stock";
			
			root.AppendChild(response);

			// Send the message
			Message msg = new Message("http://ssb.csharp.at/SSB_Book/c05/InventoryQueryResponseMessage", new MemoryStream(Encoding.ASCII.GetBytes(doc.InnerXml)));
			Conversation.Send(msg, Connection, Transaction);
			
			// End the dialog
			Conversation.End(Connection, Transaction);
		}
	}
}