using System;
using System.Xml;
using System.Data;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;
using JobServer.Interfaces;

namespace JobServer.Implementation
{
	/// <summary>
	/// Implements the managed stored procedure for executing Job Server tasks.
	/// </summary>
	public partial class JobServer
	{
		/// <summary>
		/// This method implements the managed stored procedure which drives the execution of the Job Server tasks.
		/// </summary>
		/// <param name="MessageType">Type of the message that must be processed</param>
		/// <param name="Message">Message body from the payload</param>
		/// <param name="ConversationHandle">The handle of the current conversation</param>
		[Microsoft.SqlServer.Server.SqlProcedure]
		public static void ProcessJobServerTasks(SqlXml Message, Guid ConversationHandle)
		{
			if (Message.IsNull)
			{
				SqlContext.Pipe.Send("No message was supplied for processing.");
				new ServiceBroker("context connection=true;").EndDialog(ConversationHandle);
				return;
			}

			XmlDocument doc = new System.Xml.XmlDocument();
			doc.LoadXml(Message.Value);
		
			// Execute the requested task
			IJobServerTask task = JobServerFactory.GetJobServerTask(doc.DocumentElement.Attributes["MessageTypeName"].Value);
			task.Execute(Message, ConversationHandle);
		}
	}
}