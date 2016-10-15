using System;
using System.Xml;
using System.Data;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;
using BatchFramework.Interfaces;

namespace BatchFramework.Implementation
{
    /// <summary>
    /// Implements the managed stored procedure for executing Job Server tasks.
    /// </summary>
    public partial class BatchFramework
    {
        /// <summary>
        /// This method implements the managed stored procedure which drives the execution of the Job Server tasks.
        /// </summary>
        /// <param name="MessageType">Type of the message that must be processed</param>
        /// <param name="Message">Message body from the payload</param>
        /// <param name="ConversationHandle">The handle of the current conversation</param>
        public static void ProcessBatchJobTasks(SqlXml Message, string MessageType, Guid ConversationHandle)
        {
            SqlConnection cnn = new SqlConnection("context connection=true;");

            try
            {
                cnn.Open();

                if (MessageType == "http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog")
                {
                    new ServiceBroker("context connection=true;").EndDialog(ConversationHandle);
                    return;
                }

                if (Message.IsNull)
                {
                    SqlContext.Pipe.Send("No message was supplied for processing.");
                    new ServiceBroker(cnn).EndDialog(ConversationHandle);
                    return;
                }

                XmlDocument doc = new System.Xml.XmlDocument();
                doc.LoadXml(Message.Value);

                // Execute the requested task
                IBatchJob task = BatchJobFactory.GetBatchJobTask(
                    doc.DocumentElement.Attributes["BatchJobType"].Value, cnn);

                task.Execute(Message, ConversationHandle, cnn);
            }
            finally
            {
                cnn.Close();
            }
        }
    }
}