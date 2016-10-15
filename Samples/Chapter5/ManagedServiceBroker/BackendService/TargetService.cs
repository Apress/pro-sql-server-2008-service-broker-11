using System;
using System.IO;
using System.Text;
using System.Data;
using System.Data.SqlClient;
using System.Collections.Generic;
using Microsoft.Samples.SqlServer;

namespace BackendService
{
	/// <summary>
	/// This class implements the Service Broker service "TargetService".
	/// </summary>
	public class TargetService : Service
	{
		/// <summary>
		/// Constructor
		/// </summary>
		/// <param name="Connection">Name of the Service Broker target service</param>
		public TargetService(SqlConnection Connection)
			: base("TargetService", Connection)
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
		/// This method is called when a Requestmessage is received on the queue "TargetQueue".
		/// </summary>
		/// <param name="ReceivedMessage"></param>
		/// <param name="Connection"></param>
		/// <param name="Transaction"></param>
		[BrokerMethod("http://ssb.csharp.at/SSB_Book/c05/RequestMessage")]
		public void ProcessRequestMessage(Message ReceivedMessage, SqlConnection Connection, SqlTransaction Transaction)
		{
			// Create the response message
			MemoryStream body = new MemoryStream(Encoding.ASCII.GetBytes("<HelloWorldResponse>Hello world from a managed stored procedure activated by Service Broker!</HelloWorldResponse>"));
			Message msgSend = new Message("www.csharp.at/SSB_Book/c05/ResponseMessage", body);
		
			// Send the response message back to the initiator of the conversation
			ReceivedMessage.Conversation.Send(msgSend, Connection, Transaction);
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
	}
}