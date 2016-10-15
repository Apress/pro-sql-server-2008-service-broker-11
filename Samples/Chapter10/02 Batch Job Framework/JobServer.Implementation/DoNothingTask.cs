using System;
using System.Collections.Generic;
using System.Text;
using JobServer.Interfaces;
using Microsoft.SqlServer.Server;

namespace JobServer.Implementation
{
	/// <summary>
	/// A simple implementation of a Job Server Task. It just dumps the content back to the caller.
	/// </summary>
	public class DoNothingTask : IJobServerTask
	{
		/// <summary>
		/// This method is called as soon as the Job Server Task is executed through SQL Service Broker.
		/// </summary>
		/// <param name="Message">Payload from the request message body</param>
		/// <param name="ConversationHandle">The handle of the current conversation</param>
		public void Execute(System.Data.SqlTypes.SqlXml Message, Guid ConversationHandle)
		{
			SqlContext.Pipe.Send(Message.Value);
			new ServiceBroker("context connection=true;").EndDialog(ConversationHandle);
		}
	}
}