using System;
using System.Text;
using System.Data;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using System.Configuration;
using System.Collections.Generic;

namespace BatchFramework.Interfaces
{
    public class ServiceBroker
    {
        public SqlConnection cnn;
        public SqlTransaction tran;
        public SqlCommand cmd;

        public ServiceBroker(string ConnectionString)
        {
            cnn = new SqlConnection(ConnectionString);
            cnn.Open();
        }

        public ServiceBroker(SqlConnection Connection)
        {
            cnn = Connection;
        }

        public void Send(Guid ConversationHandle, string Message, string MessageType)
        {
            // Get the context command
            SqlCommand cmd = cnn.CreateCommand();
            cmd.Transaction = tran;

            // Add dialog handle
            SqlParameter paramDialogHandle = new SqlParameter("@dh", SqlDbType.UniqueIdentifier);
            paramDialogHandle.Value = ConversationHandle;
            cmd.Parameters.Add(paramDialogHandle);

            // Add message
            SqlParameter paramMsg = new SqlParameter("@msg", SqlDbType.NVarChar, Message.Length);
            paramMsg.Value = Message;
            cmd.Parameters.Add(paramMsg);

            // Build the SEND command
            cmd.CommandText = "SEND ON CONVERSATION @dh " +
                "MESSAGE TYPE [" + MessageType + "] " +
                "(@msg)";

            try
            {
                cmd.ExecuteNonQuery();
            }
            catch (Exception e)
            {
            }
        }

        public void Receive(string QueueName, out string MessageType, out string Message, out Guid ConversationGroup, out Guid ConversationHandle)
        {
            //default return values
            MessageType = null;
            Message = null;
            ConversationGroup = Guid.Empty;
            ConversationHandle = Guid.Empty;

            // Get the context command
            cmd = cnn.CreateCommand();
            cmd.Transaction = tran;

            // Get output msgtype
            SqlParameter paramMsgType = new SqlParameter("@msgtype", SqlDbType.NVarChar, 256);
            paramMsgType.Direction = ParameterDirection.Output;
            cmd.Parameters.Add(paramMsgType);

            // Get output msg
            SqlParameter paramMsg = new SqlParameter("@msg", SqlDbType.NVarChar, 4000);
            paramMsg.Direction = ParameterDirection.Output;
            cmd.Parameters.Add(paramMsg);

            // Get output si
            SqlParameter paramConversationGroup = new SqlParameter("@cg", SqlDbType.UniqueIdentifier);
            paramConversationGroup.Direction = ParameterDirection.Output;
            cmd.Parameters.Add(paramConversationGroup);

            // Get output dh
            SqlParameter paramDialogHandle = new SqlParameter("@dh", SqlDbType.UniqueIdentifier);
            paramDialogHandle.Direction = ParameterDirection.Output;
            cmd.Parameters.Add(paramDialogHandle);

            // Build the Receive command
            cmd.CommandText = "WAITFOR (RECEIVE TOP(1)  @msgtype = message_type_name, " +
                "@msg = message_body, " +
                "@cg = conversation_group_id, " +
                "@dh = conversation_handle " +
                "FROM [" + QueueName + "]) " +
                ", TIMEOUT 5000";

            try
            {
                cmd.ExecuteNonQuery();

                if (!(paramMsgType.Value is DBNull))
                {
                    MessageType = (string)paramMsgType.Value;
                    Message = (string)paramMsg.Value;
                    ConversationGroup = (System.Guid)paramConversationGroup.Value;
                    ConversationHandle = (System.Guid)paramDialogHandle.Value;
                }
            }
            catch (Exception e)
            {
            }
        }

        public void EndDialog(Guid ConversationHandle)
        {
            // Get the context command
            SqlCommand cmd = cnn.CreateCommand();
            cmd.Transaction = tran;

            // Add dialog handle
            SqlParameter paramDialogHandle = new SqlParameter("@dh", SqlDbType.UniqueIdentifier);
            paramDialogHandle.Value = ConversationHandle;
            cmd.Parameters.Add(paramDialogHandle);

            // Build the SEND command
            cmd.CommandText = "END CONVERSATION @dh ";

            try
            {
                cmd.ExecuteNonQuery();
            }
            catch (Exception e)
            {
            }
        }
    }
}