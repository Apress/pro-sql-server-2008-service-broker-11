using System;
using System.Collections.Generic;
using System.Text;
using System.Data.SqlClient;
using Microsoft.SqlServer.Server;
using BatchFramework.Interfaces;

namespace BatchFramework.Implementation
{
    public class EndDialogTask : IBatchJob
    {
        /// <summary>
        /// End the conversation identified by the given conversation handle.
        /// </summary>
        /// <param name="Message"></param>
        /// <param name="ConversationHandle"></param>
        public void Execute(System.Data.SqlTypes.SqlXml Message, Guid ConversationHandle, SqlConnection Connection)
        {
            new ServiceBroker(Connection).EndDialog(ConversationHandle);
        }
    }
}