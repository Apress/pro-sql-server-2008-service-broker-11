using System;
using System.Collections.Generic;
using System.Text;
using System.Data;
using System.Data.SqlClient;
using BatchFramework.Interfaces;

namespace BatchFramework.Implementation
{
    /// <summary>
    /// A simple implementation of a Job Server Task. It just dumps the content back to the caller.
    /// </summary>
    public class BatchJobTypeA : IBatchJob
    {
        /// <summary>
        /// This method is called as soon as the Job Server Task is executed through SQL Service Broker.
        /// </summary>
        /// <param name="Message">Payload from the request message body</param>
        /// <param name="ConversationHandle">The handle of the current conversation</param>
        public void Execute(System.Data.SqlTypes.SqlXml Message, Guid ConversationHandle, SqlConnection Connection)
        {
            new ServiceBroker(Connection).EndDialog(ConversationHandle);
        }
    }
}