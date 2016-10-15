using System;
using System.Text;
using System.Data;
using System.Data.SqlClient;
using System.Collections.Generic;
using Microsoft.Samples.SqlServer;

namespace TargetService
{
	public class ProductOrderService : Service
	{
		private Guid _conversationGroupId;
		private bool _creditCardValidationStatus;
		private bool _inventoryAdjustmentStatus;
		private bool _shippingStatus;
		private bool _accountingStatus;

		/// <summary>
		/// Constructor
		/// </summary>
		/// <param name="Connection">Name of the Service Broker target service</param>
		public ProductOrderService(SqlConnection Connection)
			: base("ProductOrderService", Connection)
		{
			WaitforTimeout = TimeSpan.FromSeconds(1);
			this.AppLoaderProcName = "LoadApplicationState";
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
				service = new ProductOrderService(cnn);
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
				_conversationGroupId = new Guid(reader["ConversationGroupId"].ToString());
				_creditCardValidationStatus = bool.Parse(reader["CreditCardValidation"].ToString());
				_inventoryAdjustmentStatus = bool.Parse(reader["InventoryAdjustment"].ToString());
				_shippingStatus = bool.Parse(reader["Shipping"].ToString());
				_accountingStatus = bool.Parse(reader["Accounting"].ToString());

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
			sql += "CreditCardValidation = @CreditCardValidationStatus, ";
			sql += "InventoryAdjustment = @InventoryAdjustmentStatus, ";
			sql += "Shipping = @ShippingStatus, ";
			sql += "Accounting = @AccountingStatus ";
			sql += "WHERE ConversationGroupId = @ConversationGroupId";

			// Create the necessary T-SQL parameters
			SqlCommand cmd = new SqlCommand(sql, connection);
			cmd.Transaction = transaction;
			cmd.Parameters.Add("@CreditCardValidationStatus", SqlDbType.Bit);
			cmd.Parameters.Add("@InventoryAdjustmentStatus", SqlDbType.Bit);
			cmd.Parameters.Add("@ShippingStatus", SqlDbType.Bit);
			cmd.Parameters.Add("@AccountingStatus", SqlDbType.Bit);
			cmd.Parameters.Add("@ConversationGroupId", SqlDbType.UniqueIdentifier);

			// Set the T-SQL parameters
			cmd.Parameters["@CreditCardValidationStatus"].Value = _creditCardValidationStatus;
			cmd.Parameters["@InventoryAdjustmentStatus"].Value = _inventoryAdjustmentStatus;
			cmd.Parameters["@ShippingStatus"].Value = _shippingStatus;
			cmd.Parameters["@AccountingStatus"].Value = _accountingStatus;
			cmd.Parameters["@ConversationGroupId"].Value = _conversationGroupId;

			// Execute the query
			cmd.ExecuteNonQuery();
		}

		/// <summary>
		/// This method is called when a new ProductOrderMessage arrives on our service queue.
		/// </summary>
		/// <param name="ReceivedMessage"></param>
		/// <param name="Connection"></param>
		/// <param name="Transaction"></param>
		[BrokerMethod("http://ssb.csharp.at/SSB_Book/c06/ProductOrderMessage")]
		public void ProcessProductOrderMessage(Message ReceivedMessage, SqlConnection Connection, SqlTransaction Transaction)
		{
			_creditCardValidationStatus = true;

			// Send the response message back to the initiator of the conversation
			ReceivedMessage.Conversation.End(Connection, Transaction);
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
	}
}
