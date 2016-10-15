using System;
using System.Text;
using System.Data;
using System.Data.SqlClient;
using System.Configuration;
using System.Collections.Generic;
using System.Data.SqlTypes;

namespace ServiceBroker.Workflow.Activities
{
    /// <summary>
    /// Implements the API used for the communication with Service Broker.
    /// </summary>
    public class ServiceBrokerImpl
    {
        private SqlConnection _cnn;
        private SqlTransaction _trans;
        private string _queueName;
        private string _serviceName;
        private int _receiveTimeout = 100;

        /// <summary>
        /// Public property around the SqlConnection object.
        /// </summary>
        public SqlConnection Connection
        {
            get { return _cnn; }
            set { _cnn = value; }
        }

        /// <summary>
        /// Public property around the SqlTransaction object.
        /// </summary>
        public SqlTransaction Transaction
        {
            get { return _trans; }
            set { _trans = value; }
        }

        /// <summary>
        /// Default constructor which intializes the class.
        /// </summary>
        public ServiceBrokerImpl()
        {
            _cnn = new SqlConnection(ConfigurationManager.ConnectionStrings["Database"].ConnectionString);
            _cnn.Open();

            _queueName = ConfigurationManager.AppSettings["QueueName"];
            _serviceName = ConfigurationManager.AppSettings["ServiceName"];
        }

        /// <summary>
        /// Begins a new Service Broker dialog with the specified Service Broker service.
        /// </summary>
        /// <param name="ToService">The service name to which a dialog should be openend</param>
        /// <param name="Contract">The used contract</param>
        /// <param name="ConversationGroupID">The current conversation group id - is the current WorkflowInstanceID</param>
        /// <param name="DialogHandle">The dialog handle of the openend dialog, returned as an output parameter</param>
        public void BeginDialog(string ToService, string Contract, Guid ConversationGroupID, out Guid DialogHandle)
        {
            DialogHandle = Guid.Empty;

            SqlCommand cmd = _cnn.CreateCommand();
            cmd.Transaction = _trans;

            SqlParameter paramDialogHandle = new SqlParameter("@dh", SqlDbType.UniqueIdentifier);
            paramDialogHandle.Direction = ParameterDirection.Output;
            cmd.Parameters.Add(paramDialogHandle);

            // Build the BEGIN DIALOG T-SQL statement
            cmd.CommandText = "BEGIN DIALOG CONVERSATION @dh " +
                              "  FROM SERVICE [" + _serviceName +
                              "]  TO SERVICE    '" + ToService + "'" +
                              "  ON CONTRACT    [" + Contract +
                              "]  WITH RELATED_CONVERSATION_GROUP = '" + ConversationGroupID.ToString() +
                              "', ENCRYPTION = OFF";

            try
            {
                cmd.ExecuteNonQuery();
                DialogHandle = (System.Guid)paramDialogHandle.Value;
            }
            catch (SqlException e)
            {
                Console.WriteLine("BEGIN DIALOG failed " + e.Message);
            }
        }

        /// <summary>
        /// Sends a new Service Broker message over an existing dialog.
        /// </summary>
        /// <param name="MessageType">The used message type</param>
        /// <param name="Message">The content of the actual message</param>
        /// <param name="DialogHandle">The dialog handle for the used dialog</param>
        public void SendMessage(string MessageType, string Message, Guid DialogHandle)
        {
            SqlCommand cmd = _cnn.CreateCommand();
            cmd.Transaction = _trans;

            // Add dialog handle parameter
            SqlParameter paramDialogHandle = new SqlParameter("@dh", SqlDbType.UniqueIdentifier);
            paramDialogHandle.Value = DialogHandle;
            cmd.Parameters.Add(paramDialogHandle);

            // Add message parameter
            SqlParameter paramMsg = new SqlParameter("@msg", SqlDbType.NVarChar, Message.Length);
            paramMsg.Value = Message;
            cmd.Parameters.Add(paramMsg);

            // Build the SEND T-SQL statement
            cmd.CommandText = "SEND ON CONVERSATION @dh MESSAGE TYPE [" + MessageType + "] (@msg)";

            try
            {
                cmd.ExecuteNonQuery();
            }
            catch (SqlException e)
            {
                Console.WriteLine("SEND failed " + e.Message);
            }
        }

        public void ReceiveMessage(out string MessageType, out string Message, out Guid ConversationGroupID, out Guid DialogHandle)
        {
            //default return values
            MessageType = null;
            Message = null;
            ConversationGroupID = Guid.Empty;
            DialogHandle = Guid.Empty;


            SqlCommand cmd = _cnn.CreateCommand();
            cmd.Transaction = _trans;
            cmd.CommandTimeout = _receiveTimeout / 1000 + 2;

            cmd.CommandText = "WAITFOR (RECEIVE TOP(1)  message_type_name, " +
                "CAST(message_body AS XML), " +
                "conversation_group_id, " +
                "conversation_handle FROM [" + _queueName +
                "]), TIMEOUT " + _receiveTimeout;

            try
            {
                SqlDataReader rdr = cmd.ExecuteReader();

                if (rdr.HasRows)
                {
                    rdr.Read();
                    MessageType = (String)rdr.GetSqlString(0);
                    SqlXml sx = rdr.GetSqlXml(1);

                    if (!sx.IsNull)
                    {
                        Message = sx.Value;
                    }

                    ConversationGroupID = rdr.GetGuid(2);
                    DialogHandle = rdr.GetGuid(3);
                }

                rdr.Close();
            }
            catch (SqlException e)
            {
                Console.WriteLine("RECEIVE failed " + e.Message);
            }
        }

        /// <summary>
        /// Ends the current dialog
        /// </summary>
        /// <param name="DialogHandle">Dialog handle for the dialog to be ended.</param>
        public void EndDialog(Guid DialogHandle)
        {
            SqlCommand cmd = _cnn.CreateCommand();
            cmd.Transaction = _trans;

            SqlParameter paramDialogHandle = new SqlParameter("@dh", SqlDbType.UniqueIdentifier);
            paramDialogHandle.Value = DialogHandle;
            cmd.Parameters.Add(paramDialogHandle);

            // Build the END CONVERSATION T-SQL statement
            cmd.CommandText = "END CONVERSATION @dh ";

            try
            {
                cmd.ExecuteNonQuery();
            }
            catch (SqlException e)
            {
                Console.WriteLine("END CONVERSATION failed " + e.Message);
            }
        }
    }
}