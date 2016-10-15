using System;
using System.Text;
using System.Data.SqlTypes;
using System.Collections.Generic;

namespace JobServer.Interfaces
{
	/// <summary>
	/// Defines the interface for job server tasks.
	/// </summary>
	public interface IJobServerTask
	{
		/// <summary>
		/// Defines the method that is executed in the Job Server Task.
		/// </summary>
		/// <param name="Message">Payload from the message body. The content is specific to each Job Server Task</param>
		/// <param name="ConversationHandle">The handle of the current conversation</param>
		void Execute(SqlXml Message, Guid ConversationHandle);
	}
}