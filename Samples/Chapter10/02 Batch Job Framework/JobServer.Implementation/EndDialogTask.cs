using System;
using System.Collections.Generic;
using System.Text;
using Microsoft.SqlServer.Server;
using JobServer.Interfaces;

namespace JobServer.Implementation
{
	public class EndDialogTask : IJobServerTask
	{
		/// <summary>
		/// End the conversation identified by the given conversation handle.
		/// </summary>
		/// <param name="Message"></param>
		/// <param name="ConversationHandle"></param>
		public void Execute(System.Data.SqlTypes.SqlXml Message, Guid ConversationHandle)
		{
			new ServiceBroker("context connection=true;").EndDialog(ConversationHandle);
		}
	}
}
