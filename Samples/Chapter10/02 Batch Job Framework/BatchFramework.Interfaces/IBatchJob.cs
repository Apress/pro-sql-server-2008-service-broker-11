using System;
using System.Text;
using System.Data;
using System.Data.SqlTypes;
using System.Data.SqlClient;
using System.Collections.Generic;

namespace BatchFramework.Interfaces
{
    public interface IBatchJob
    {
        /// <summary>
        /// This method is called, when the batch job gets executed
        //  through the batch framework.
        /// </summary>
        /// <param name="Message"></param>
        /// <param name="ConversationHandle"></param>
        void Execute(SqlXml Message, Guid ConversationHandle, SqlConnection Connection);
    }
}