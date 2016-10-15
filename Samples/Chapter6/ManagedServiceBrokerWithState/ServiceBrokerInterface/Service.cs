//-----------------------------------------------------------------------
//  This file is part of the Microsoft Code Samples.
// 
//  Copyright (C) Microsoft Corporation.  All rights reserved.
// 
//This source code is intended only as a supplement to Microsoft
//Development Tools and/or on-line documentation.  See these other
//materials for detailed information regarding Microsoft code samples.
// 
//THIS CODE AND INFORMATION ARE PROVIDED AS IS WITHOUT WARRANTY OF ANY
//KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
//IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
//PARTICULAR PURPOSE.
//-----------------------------------------------------------------------

#region Using directives

using System;
using System.Data;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using System.Collections.Generic;
using System.Text;
using System.Diagnostics;
using System.Reflection;

#endregion

namespace Microsoft.Samples.SqlServer
{
    /// <remarks>
    /// This class represents a SQL Service Broker service endpoint.
    /// It is bound to an instance of the <c>SqlConnection</c> interface
    /// which is of type <c>System.Data.SqlClient.SqlConnection</c>.
    /// The <c>Service</c> class contains methods to create 
    /// <c>Conversation</c> objects by beginning a dialog or getting one from
    /// the queue.
    /// </remarks>
    public class Service
    {
        #region Fields
        /// <summary>
        /// This is the queue name associated with the service. It is 
        /// initilized in the constructor of the <c>Service</c> by
        /// querying the appropriate database management view.
        /// </summary>
        private string m_queueName;

        /// <summary>
        /// The system defined contract name for echo.
        /// </summary>
        private const string EchoContractName = "http://schemas.microsoft.com/SQL/ServiceBroker/ServiceEcho";

        private string m_appLoaderProcName;
        /// <value>
        /// If this property is non-null, the message loop executes
        /// the stored proc with this name while fetching the next batch of
        /// messages to be processed. The stored proc is an application
        /// specific stored proc that takes the conversation group ID as a 
        /// parameter and returns one or more result sets that are used for
        /// loading an application from database tables.
        /// </value>
        protected string AppLoaderProcName
        {
            get { return m_appLoaderProcName; }
            set { m_appLoaderProcName = value; }
        }

        private string m_name;
        /// <value>
        /// The service name
        /// </value>
        public string Name
        {
            get { return m_name; }
        }

        private int m_fetchSize;
        /// <value>
        /// The number of messages to be fetched in a database roundtrip.
        /// </value>
        public int FetchSize
        {
            get { return m_fetchSize; }
            set { m_fetchSize = value; }
        }

        /// <value>
        /// Override this property if stateful behaviour of the service is desired. 
        /// Default returns -1.
        /// </value>
        public virtual int State
        {
            get { return -1; }
        }

        /// <value>
        /// This is a reference to a <c>MessageReader</c> object that serves
        /// as a cursor for the batch of messages received from the queue.
        /// </value>
        private MessageReader m_reader;
        internal MessageReader Reader
        {
            get { return m_reader; }
        }

        /// <value>Returns a value indicating whether there are more messages 
        /// to be processed from the queue.</value>
        protected bool HasMoreMessages
        {
            get { return m_reader.IsOpen; }
        }

        private TimeSpan m_waitforTimeout;
        /// <value>The waitfor parameter for doing a RECEIVE while fetching new messages.</value>
        public TimeSpan WaitforTimeout
        {
            get { return m_waitforTimeout; }
            set { m_waitforTimeout = value; }
        }
        #endregion

        #region Constructor
        /// <summary>
        /// The constructor instantiates a <c>Service</c> object by
        /// querying the appropriate database management view for the given
        /// <paramref>name</paramref>. It reads the name of the
        /// queue associated with this <c>Service</c>.
        /// </summary>
        /// <param name="name">The name of the <c>Service</c> as defined
        /// in the database</param>
        /// <param name="connection">The database connection to be used
        /// by this <c>Service</c></param>
        /// <param name="transaction">The transaction to use for firing database queries
        /// </param>
        /// <exception cref="ArgumentException">Thrown if no such service found
        /// in the database connected to the given connection.</exception>
        public Service(String name, SqlConnection connection, SqlTransaction transaction)
        {
            if (connection.State != ConnectionState.Open)
                throw new ArgumentException("Database connection is not open");

            m_name = name;

			SqlCommand cmd = connection.CreateCommand();
			cmd.CommandText = "SELECT q.name "
                + "FROM sys.service_queues q JOIN sys.services as s "
                + "ON s.service_queue_id = q.object_id "
                + "WHERE s.name = @sname";
			cmd.Transaction = transaction;

            SqlParameter param;
            param = cmd.Parameters.Add("@sname", SqlDbType.NChar, 255);
            param.Value = m_name;

            m_queueName = (string)cmd.ExecuteScalar();

            if (m_queueName == null)
            {
                throw new ArgumentException(
                    "Could not find any service with the name '"
                    + name + "' in this database.");
            }

			m_appLoaderProcName = null;
			m_fetchSize = 0;
            m_reader = new MessageReader(this);
            BuildCallbackMap();
        }

        /// <summary>
        /// The constructor is identical to the one above minus the ability to
        /// pass in a pre-existing transaction.
        /// </summary>
        public Service(String name, SqlConnection connection)
            : this(name, connection, null)
        { }
        #endregion

        #region Virtual Methods
        /// <summary>
        /// <para>
        /// This method is invoked inside the message loop for loading
        /// the application state associated with the conversation group
        /// being processed into the current context. It is passed an
        /// <c>SqlDataReader</c> containing the result set(s) of executing
        /// the stored proc <c>m_appLoaderProcName</c>. For proper functioning
        /// it must only consume as many result sets as the stored proc is
        /// designed to emit since the <paramref>reader</paramref> also
        /// contains a batch of messages on the queue which are processed
        /// later.</para>
        /// <para>Users must override this method to perform application specific
        /// database operations.</para>
		/// <param name="reader">Data reader containing result set(s) of
		/// executing the configured stored proc</param>
		/// <param name="connection">Connection which was used for doing the RECEIVE</param>
		/// <param name="transaction">Transaction which was used for doing the RECEIVE</param>
        /// </summary>
		public virtual bool LoadState(SqlDataReader reader, SqlConnection connection, SqlTransaction transaction)
        {
            return true;
        }

        /// <summary>
        /// This method is invoked inside the message loop when the 
        /// service program has finished processing a conversation group and
        /// wishes to save the state to the database.
        /// Users must override this method to perform application specific
        /// database operations.
		/// <param name="connection">Connection which was used for doing the RECEIVE</param>
		/// <param name="transaction">Transaction which was used for doing the RECEIVE</param>
        /// </summary>
        public virtual void SaveState(SqlConnection connection, SqlTransaction transaction)
        {
        }

        /// <summary>
        /// This method provides a default implementation for dispatching messages
        /// to the appropriate broker methods as specified in the derived class. The user
        /// may overrride this method if attributed methods are not desired.
        /// </summary>
        /// <param name="message">The message received by the service</param>
		/// <param name="connection">Connection which was used for doing the RECEIVE</param>
		/// <param name="transaction">Transaction which was used for doing the RECEIVE</param>
        /// <exception cref="NotImplementedException">Thrown if there is no broker method to
        /// handle the current event</exception>
		public virtual void DispatchMessage(
			Message message,
			SqlConnection connection,
			SqlTransaction transaction)
		{
			if (message.Type == Message.EchoType && message.ContractName == EchoContractName)
			{
				EchoHandler(message, connection, transaction);
				return;
            }
            MethodInfo mi;
            BrokerMethodAttribute statefulTransition = new BrokerMethodAttribute(State, message.ContractName, message.Type);
            BrokerMethodAttribute statefulMessageTypeTransition = new BrokerMethodAttribute(State, message.Type);
            BrokerMethodAttribute statelessTransition = new BrokerMethodAttribute(message.ContractName, message.Type);
            BrokerMethodAttribute statelessMessageTypeTransition = new BrokerMethodAttribute(message.Type);
            if (m_dispatchMap.ContainsKey(statefulTransition))
                mi = m_dispatchMap[statefulTransition];
            else if (m_dispatchMap.ContainsKey(statefulMessageTypeTransition))
                mi = m_dispatchMap[statefulMessageTypeTransition];
            else if (m_dispatchMap.ContainsKey(statelessTransition))
                mi = m_dispatchMap[statelessTransition];
            else if (m_dispatchMap.ContainsKey(statelessMessageTypeTransition))
                mi = m_dispatchMap[statelessMessageTypeTransition];
            else
            {
                string exceptionMessage = "No broker method defined for message type '" + message.Type +
                        "' on contract '" + message.ContractName + "'";
                if (State != -1)
                    exceptionMessage += " in state " + State;
                throw new InvalidOperationException(exceptionMessage);
            }
            mi.Invoke(this, new object[3] { message, connection, transaction });
            if (connection.State != ConnectionState.Open)
            {
                throw new ObjectDisposedException("Connection", "Method '" + mi.Name + "' closed the database connection.");
            }
        }

		/// <summary>
		/// This is an example implementation of the message loop. It fetches the
		/// next conversation from the message queue, reads one message at a time
		/// from the conversation, translates the message using the current
		/// application object and fires the corresponding event to the application.
		/// Application state is saved automatically whenever a new batch of messages
		/// are fetched.
		/// <param name="autoCommit">Set TRUE if you would like the message loop to automatically
		/// commmit at the end of each fetch batch</param>
		/// <param name="connection">Connection to use for doing the RECEIVE</param>
		/// <param name="transaction">Transaction to use for doing the RECEIVE</param>
		/// </summary>
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Design", "CA1062:ValidateArgumentsOfPublicMethods")]
        public virtual void Run(
			bool autoCommit,
			SqlConnection connection,
			SqlTransaction transaction)
		{
			Message message = null;
			Conversation currentConversation = null;

			try
			{
				if (autoCommit == true && transaction == null)
				{
					transaction = connection.BeginTransaction();
				}
				while ((currentConversation = GetConversation(connection, transaction)) != null)
				{
					while ((message = currentConversation.Receive()) != null)
					{
						DispatchMessage(message, connection, transaction);
					}
					if (!HasMoreMessages)
					{
						SaveState(connection, transaction);
						if (autoCommit == true)
						{
							transaction.Commit();
							transaction = connection.BeginTransaction();
						}
					}
				}
				if (autoCommit == true)
				{
					transaction.Commit();
					transaction = null;
				}
			}
			catch (Exception e)
			{
				throw new ServiceException(
					currentConversation,
					connection,
					transaction,
					e);
			}
		}

		/// <summary>
		/// Event handler for Echo messages.
		/// </summary>
		/// <param name="msgReceived">The message received.</param>
		/// <param name="connection">Connection which was used for doing the RECEIVE</param>
		/// <param name="transaction">Transaction which was used for doing the RECEIVE</param>
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Design", "CA1062:ValidateArgumentsOfPublicMethods")]
        public virtual void EchoHandler(
			Message msgReceived,
			SqlConnection connection,
			SqlTransaction transaction)
		{
			msgReceived.Conversation.Send(msgReceived, connection, transaction);
		}
        #endregion

        #region Public Methods
		/// <summary>
		/// This method begins a new dialog with a remote service by invoking
		/// the corresponding database command. 
		/// </summary>
		/// <param name="toServiceName">The name of the remote service to begin this
		/// dialog with</param>
		/// <param name="brokerInstance">The broker instance of the target broker
		///  that has the remote service</param>
		/// <param name="contractName">The contract to be used for this dialog
		/// </param>
		/// <param name="lifetime">The duration for which the dialog will be active. 
		/// Any operation performed after the conversation has expired will result in
		/// dialog errors.</param>
		/// <param name="encryption">A boolean indicating whether to use encryption
		/// on the dialog</param>
		/// <param name="connection">The connection to use for beginning this dialog
		/// </param>
		/// <param name="transaction">The transaction to use for beginning this dialog
		/// </param>
		/// <returns>A conversation object representing this dialog</returns>
		public Conversation BeginDialog(
			string toServiceName,
			string brokerInstance,
			string contractName,
			TimeSpan lifetime,
			bool encryption,
			SqlConnection connection,
			SqlTransaction transaction)
		{
			return BeginDialogInternal(toServiceName, brokerInstance, contractName,
				lifetime, encryption, null, Guid.Empty, connection, transaction);
		}

		/// <summary>
		/// This method begins a new dialog with a remote service by invoking
		/// the corresponding database command. It associates the dialog with
		/// the conversation specified in <paramref>relatedConversation</paramref>
		/// by putting them in the same conversation group.
		/// </summary>
		/// <param name="toServiceName">The name of the remote service to begin this
		/// dialog with</param>
		/// <param name="brokerInstance">The broker instance of the target broker
		///  that has the remote service</param>
		/// <param name="contractName">The contract to be used for this dialog
		/// </param>
		/// <param name="lifetime">The duration for which the dialog will be active. 
		/// Any operation performed after the conversation has expired will result in
		/// dialog errors.</param>
		/// <param name="encryption">A boolean indicating whether to use encryption
		/// on the dialog</param>
		/// <param name="relatedConversation">The conversation that the new dialog
		/// should be related to</param>
		/// <param name="connection">The connection to use for beginning this dialog
		/// </param>
		/// <param name="transaction">The transaction to use for beginning this dialog
		/// </param>
		/// <returns>A conversation object representing this dialog</returns>
		public Conversation BeginDialog(
			string toServiceName,
			string brokerInstance,
			string contractName,
			TimeSpan lifetime,
			bool encryption,
			Conversation relatedConversation,
			SqlConnection connection,
			SqlTransaction transaction)
		{
			return BeginDialogInternal(toServiceName, brokerInstance, contractName,
				lifetime, encryption, relatedConversation, Guid.Empty, connection, transaction);
		}

		/// <summary>
		/// This method begins a new dialog with a remote service by invoking
		/// the corresponding database command. It associates the dialog with
		/// the specified conversation group.
		/// </summary>
		/// <param name="toServiceName">The name of the remote service to begin this
		/// dialog with</param>
		/// <param name="brokerInstance">The broker instance of the target broker
		///  that has the remote service</param>
		/// <param name="contractName">The contract to be used for this dialog
		/// </param>
		/// <param name="lifetime">The duration for which the dialog will be active. 
		/// Any operation performed after the conversation has expired will result in
		/// dialog errors.</param>
		/// <param name="encryption">A boolean indicating whether to use encryption
		/// on the dialog</param>
		/// <param name="groupId">The conversation group Id that the new dialog
		/// should belong to</param>
		/// <param name="connection">The connection to use for beginning this dialog
		/// </param>
		/// <param name="transaction">The transaction to use for beginning this dialog
		/// </param>
		/// <returns>A conversation object representing this dialog</returns>
		public Conversation BeginDialog(
			string toServiceName,
			string brokerInstance,
			string contractName,
			TimeSpan lifetime,
			bool encryption,
			Guid groupId,
			SqlConnection connection,
			SqlTransaction transaction)
		{
			return BeginDialogInternal(toServiceName, brokerInstance, contractName,
				lifetime, encryption, null, groupId, connection, transaction);
		}

		/// <summary>
		/// This method returns the next active conversation on the message queue. If
		/// associated <c>MessageReader</c> object is empty, a new batch of messages
		/// are fetched from the database.
		/// </summary>
		/// <param name="connection">The connection to use for fetching message batch
		/// </param>
		/// <param name="transaction">The transaction to use for fetching message batch
		/// </param>
		/// <returns>A <c>Conversation</c> object on which <c>Receive</c> may be invoked
		/// to get the messages received on that conversation.</returns>
		public Conversation GetConversation(
			SqlConnection connection,
			SqlTransaction transaction)
		{
			if (!m_reader.IsOpen)
			{
				FetchNextMessageBatch(null, connection, transaction);
			}
			return m_reader.GetNextConversation();
		}

		/// <summary>
		/// This method blocks (or times out) until the specified conversation is
		/// available on the message queue.
		/// </summary>
		/// <param name="conversation">The conversation to fetch from the queue</param>
		/// <param name="connection">The connection to use for fetching message batch
		/// </param>
		/// <param name="transaction">The transaction to use for fetching message batch
		/// </param>
		/// <returns>The conversation available on the queue</returns>
		/// <exception cref="InvalidOperationException">Thrown if attempted to call
		/// this method when there is some other conversation active.</exception>
		public Conversation GetConversation(
			Conversation conversation,
			SqlConnection connection,
			SqlTransaction transaction)
		{
			Conversation nextConv;
			if (m_reader.IsOpen)
			{
				nextConv = m_reader.GetNextConversation();
				if (nextConv.Handle == conversation.Handle)
					return nextConv;
				else
					throw new InvalidOperationException("Cannot get conversation '" +
						conversation.Handle + "' while there are still more messages to be processed.");
			}

			FetchNextMessageBatch(conversation, connection, transaction);
			nextConv = m_reader.GetNextConversation();
			Debug.Assert(nextConv == null || nextConv.Handle == conversation.Handle);
			return nextConv;
		}
		#endregion

        #region Private methods
        /// <summary>
        /// This is an internal method that is called by the various <c>BeginDialog</c> 
        /// methods. It invokes the BEGIN DIALOG T-SQL command and creates a new
        /// Conversation object wrapping the returned conversation handle.
        /// </summary>
        /// <param name="toServiceName">The name of the remote service to connect
        /// to</param>
		/// <param name="brokerInstance">The broker instance of the target broker
		///  that has the remote service</param>
        /// <param name="contractName">The contract to be used for this dialog
        /// </param>
        /// <param name="lifetime">The duration for which the dialog will be active. 
        /// Any operation performed after the conversation has expired will result in
        /// dialog errors.</param>
        /// <param name="encryption">A boolean indicating whether to use encryption
        /// on the dialog</param>
        /// <param name="conversation">The conversation that the new dialog
        /// should be related to</param>
        /// <param name="groupId">The conversation group Id that the new dialog
        /// should belong to</param>
		/// <param name="connection">The connection to use for beginning this dialog
		/// </param>
		/// <param name="transaction">The transaction to use for beginning this dialog
		/// </param>
		/// <returns>A conversation object representing this dialog</returns>
		private Conversation BeginDialogInternal(
			string toServiceName,
			string brokerInstance,
			string contractName,
			TimeSpan lifetime,
			bool encryption,
			Conversation conversation,
			Guid groupId,
			SqlConnection connection,
			SqlTransaction transaction)
		{
			SqlParameter param;
			SqlCommand cmd = connection.CreateCommand();

			StringBuilder query = new StringBuilder();
			if (brokerInstance != null)
			{
				query.Append("BEGIN DIALOG @ch FROM SERVICE @fs TO SERVICE @ts, @bi ON CONTRACT @cn WITH ENCRYPTION = ");
				param = cmd.Parameters.Add("@bi", SqlDbType.NVarChar, brokerInstance.Length);
				param.Value = brokerInstance;
			}
			else
			{
				query.Append("BEGIN DIALOG @ch FROM SERVICE @fs TO SERVICE @ts ON CONTRACT @cn WITH ENCRYPTION = ");
			}

			if (encryption)
				query.Append("ON ");
			else
				query.Append("OFF ");
			if (conversation != null)
			{
				query.Append(", RELATED_CONVERSATION = @rch ");
				param = cmd.Parameters.Add("@rch", SqlDbType.UniqueIdentifier);
				param.Value = conversation.Handle;
			}
			else if (groupId != Guid.Empty)
			{
				query.Append(", RELATED_CONVERSATION_GROUP = @rcg ");
				param = cmd.Parameters.Add("@rcg", SqlDbType.UniqueIdentifier);
				param.Value = groupId;
			}
			if (lifetime > TimeSpan.Zero)
			{
				query.Append(", LIFETIME = ");
				query.Append((long)lifetime.TotalSeconds);
				query.Append(' ');
			}

			param = cmd.Parameters.Add("@ch", SqlDbType.UniqueIdentifier);
			param.Direction = ParameterDirection.Output;
			param = cmd.Parameters.Add("@fs", SqlDbType.NVarChar, 255);
			param.Value = m_name;
			param = cmd.Parameters.Add("@ts", SqlDbType.NVarChar, 255);
			param.Value = toServiceName;
			param = cmd.Parameters.Add("@cn", SqlDbType.NVarChar, 128);
			param.Value = contractName;

			cmd.CommandText = query.ToString(); ;
			cmd.Transaction = transaction;

			cmd.ExecuteNonQuery();

			param = cmd.Parameters["@ch"] as SqlParameter;
			Guid handle = (Guid)param.Value;
			Conversation dialog = new Conversation(this, handle);
			return dialog;
		}

        /// <summary>
        /// <para>
        /// This private method is called to fetch a new set of messages from the
        /// queue. If the <paramref>conversation</paramref> parameter is non-null, we execute
        /// the following database command:
        /// <code>
        /// RECEIVE conversation_group_id, conversation_handle,message_sequence_number, 
        ///			service_name, service_contract_name, message_type_name, validation,
        ///			message_body
        /// FROM m_queuename
        /// WHERE conversation_handle=conversation.Handle
        /// </code>
        /// 
        /// If <paramref>conversation</paramref> is null, we check if a stored proc is set or 
        /// not and then invoke the appropriate database command. If no stored proc is
        /// set, then the batch of commands we use is:
        /// <code>
        /// RECEIVE conversation_group_id, conversation_handle,message_sequence_number, 
        ///			service_name, service_contract_name, message_type_name, validation,
        ///			message_body
        /// FROM m_queuename
        /// </code>
        /// If a stored proc is set, then we use:
        /// <code>
        /// DECLARE @cgid UNIQUEIDENTIFIER;
        /// IF @cgid IS NOT NULL
        /// BEGIN
        ///		GET CONVERSATION GROUP @cgid FROM m_queuename;
        ///		EXEC m_AppLoaderProcName (@cgid);
        ///		RECEIVE conversation_group_id, conversation_handle,message_sequence_number, 
        ///			service_name, service_contract_name, message_type_name, validation,
        ///			message_body
        ///		FROM m_queuename
        ///		WHERE conversation_group_id=@cgid;
        /// END
        /// </code>
        /// </para>
        /// 
        /// <para>If the stored proc was specified, then we send the <c>SqlDataReader</c>
        /// returned to the <c>Load</c> method to load the application state associated
        /// with the current conversation group. The <c>Load</c> method consumes all the 
        /// result sets returned by the user's stored proc but leaves the result set
        /// returned by the RECEIVE. After loading the application state, we initialize
        /// the message reader with the <c>SqlDataReader</c>, which can iterate over the 
        /// batch of messages received.
        /// </para>
        /// </summary>
        /// <param name="conversation">If set to a valid conversation, then we only fetch
        /// messages belonging to that conversation</param>
		/// <param name="connection">The connection to use for issuing the T-SQL batch for
		/// fetching messages</param>
		/// <param name="transaction">The transaction to use issuing the T-SQL batch for
		/// fetching messages</param>
		private void FetchNextMessageBatch(
			Conversation conversation,
			SqlConnection connection,
			SqlTransaction transaction)
		{
			SqlCommand cmd;
			if (conversation != null || m_appLoaderProcName == null)
			{
				cmd = BuildReceiveCommand(conversation, connection, transaction);

				SqlDataReader dataReader = cmd.ExecuteReader();

				m_reader.Open(dataReader);
			}
			else if (m_appLoaderProcName != null)
			{
				cmd = BuildGcgrCommand(connection, transaction);
				SqlDataReader dataReader = cmd.ExecuteReader();

				if (!LoadState(dataReader, connection, transaction))
				{
					dataReader.Close();
					return;
				}

				m_reader.Open(dataReader);
			}
		}

		private SqlCommand BuildReceiveCommand(
			Conversation conversation,
			SqlConnection connection,
			SqlTransaction transaction)
		{
			SqlParameter param;
			SqlCommand cmd = connection.CreateCommand();
			cmd.Transaction = transaction;
			StringBuilder query = new StringBuilder();

			if (m_waitforTimeout != TimeSpan.Zero)
				query.Append("WAITFOR(");
			query.Append("RECEIVE ");

			if (m_fetchSize > 0)
				query.Append("TOP(" + m_fetchSize + ") ");

			query.Append("conversation_group_id, conversation_handle, " +
						 "message_sequence_number, service_name, service_contract_name, " +
						 "message_type_name, validation, message_body " +
						 "FROM ");
			query.Append(m_queueName);
			if (conversation != null)
			{
				query.Append(" WHERE conversation_handle = @ch");
				param = cmd.Parameters.Add("@ch", SqlDbType.UniqueIdentifier);
				param.Value = conversation.Handle;
			}
			if (m_waitforTimeout < TimeSpan.Zero)
			{
				query.Append(")");
				cmd.CommandTimeout = 0;
			}
			else if (m_waitforTimeout > TimeSpan.Zero)
			{
				query.Append("), TIMEOUT @to");
				param = cmd.Parameters.Add("@to", SqlDbType.Int);
				param.Value = (int)m_waitforTimeout.TotalMilliseconds;
				cmd.CommandTimeout = 0;
			}
			cmd.CommandText = query.ToString();
			return cmd;
		}

		private SqlCommand BuildGcgrCommand(
			SqlConnection connection,
			SqlTransaction transaction)
		{
			SqlParameter param;
			SqlCommand cmd = connection.CreateCommand();
			cmd.Transaction = transaction;
			StringBuilder query = new StringBuilder(
				"DECLARE @cgid UNIQUEIDENTIFIER;\n"
			);

			if (m_waitforTimeout != TimeSpan.Zero)
				query.Append("WAITFOR(");
			query.Append("GET CONVERSATION GROUP @cgid FROM " + m_queueName);
			if (m_waitforTimeout < TimeSpan.Zero)
			{
				query.Append(")");
				cmd.CommandTimeout = 0;
			}
			else if (m_waitforTimeout > TimeSpan.Zero)
			{
				query.Append("), TIMEOUT @to");
				param = cmd.Parameters.Add("@to", SqlDbType.Int);
				param.Value = (int)m_waitforTimeout.TotalMilliseconds;
				cmd.CommandTimeout = 0;
			}
			query.Append(";\nIF @cgid IS NOT NULL\nBEGIN\nEXEC " + m_appLoaderProcName + " @cgid;\n");
			query.Append("RECEIVE ");

			if (m_fetchSize > 0)
				query.Append("TOP(" + m_fetchSize + ") ");

			query.Append("conversation_group_id, conversation_handle, " +
						 "message_sequence_number, service_name, service_contract_name, " +
						 "message_type_name, validation, message_body " +
						 "FROM ");
			query.Append(m_queueName);
			query.Append(" WHERE conversation_group_id = @cgid;\nEND");
			cmd.CommandText = query.ToString();
			return cmd;
		}
		#endregion

		#region Message Dispatcher
		private Dictionary<BrokerMethodAttribute, MethodInfo> m_dispatchMap;

		private void BuildCallbackMap()
		{
			Type t = GetType();
			m_dispatchMap = new Dictionary<BrokerMethodAttribute, MethodInfo>();
			MethodInfo[] methodInfoArray = t.GetMethods(BindingFlags.Public | BindingFlags.Instance);
			foreach (MethodInfo methodInfo in methodInfoArray)
			{
				object[] attributes = methodInfo.GetCustomAttributes(typeof(BrokerMethodAttribute), true);
				foreach (BrokerMethodAttribute statefulTransition in attributes)
				{
					BrokerMethodAttribute statelessTransition =
						new BrokerMethodAttribute(statefulTransition.Contract, statefulTransition.MessageType);
					if (m_dispatchMap.ContainsKey(statefulTransition) ||
						m_dispatchMap.ContainsKey(statelessTransition))
					{
						string exceptionMessage = "Method '" + methodInfo.Name +
							"' redefines a handler for message type '" + statefulTransition.MessageType + "'";
						if (statefulTransition.State != -1)
							exceptionMessage += " in state " + statefulTransition.State;

						throw new NotSupportedException(exceptionMessage);
					}

					m_dispatchMap[statefulTransition] = methodInfo;
				}
			}
		}
		#endregion

        #region MessageReader inner class
        internal class MessageReader
        {
            private Service m_svc;
            private SqlDataReader m_dataReader;
            private Message m_curMsg;

            public MessageReader(Service svc)
            {
                m_svc = svc;
				m_dataReader = null;
				m_curMsg = null;
            }

            public void Open(SqlDataReader dataReader)
            {
                m_dataReader = dataReader;
                AdvanceCursor();
            }

            public bool IsOpen
            {
                get
                {
                    return m_curMsg != null;
                }
            }

            public Message Read(Conversation conversation)
            {
                if (m_curMsg == null || m_curMsg.Conversation.Handle != conversation.Handle)
                    return null;

                Message result = m_curMsg;
                AdvanceCursor();
                return result;
            }

            public Conversation GetNextConversation()
            {
                if (m_curMsg == null)
                    return null;

                return m_curMsg.Conversation;
            }

            private void AdvanceCursor()
            {
                if (m_dataReader.Read())
                {
                    m_curMsg = new Message();
                    m_curMsg.Read(m_dataReader, m_svc);
                }
                else
                {
                    m_dataReader.Close();
                    m_curMsg = null;
                }
            }
        }
        #endregion
    }
}
