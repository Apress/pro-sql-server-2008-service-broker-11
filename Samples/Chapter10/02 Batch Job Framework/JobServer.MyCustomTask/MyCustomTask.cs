using System;
using System.Collections.Generic;
using System.Text;
using Microsoft.SqlServer.Server;
using JobServer.Interfaces;

namespace JobServer.MyCustomTask
{
	public class MyCustomTask : IJobServerTask
	{
		public void Execute(System.Data.SqlTypes.SqlXml Message, Guid ConversationHandle)
		{
			SqlContext.Pipe.Send("MyCustomTask.Execute was executed. The supplied XML message had the following content:");
			SqlContext.Pipe.Send(Message.Value);
		}
	}
}