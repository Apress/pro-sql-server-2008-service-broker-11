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

#endregion

namespace Microsoft.Samples.SqlServer
{
	/// <remarks>
	/// The <c>Conversation</c> class represents a service broker conversation between
	/// services. The convesation object may be obtained by invoking <c>Service.GetConversation</c>
	/// or <c>Service.BeginDialog</c> or by invoking the constructor and attaching it to 
	/// a <c>Service</c> object. Messages may be sent or received by calling the <c>Send</c> and
	/// <c>Receive</c> methods.
	/// </remarks>
	public class Conversation
	{
		#region Properties
		private Service m_svc;
		/// <value>The service associated with this conversation.</value>
		public Service Service
		{
			get { return m_svc; }
		}

		private Guid m_handle;
		/// <value>The conversation handle identifying the conversation.</value>
		public Guid Handle
		{
			get { return m_handle; }
		}
		#endregion

		#region Constructors
		/// <summary>
		/// This constructor does not create a new conversation by running the 'BEGIN DIALOG'
		/// T-SQL command. Instead it is used for creating conversation objects from conversation handle
		/// and associated <c>Service</c> object. To create a new conversation with a remote service
		/// use <c>Service.BeginDialog</c>
		/// </summary>
		/// <param name="service">The service associated with this conversation.</param>
		/// <param name="handle">The conversation handle.</param>
		public Conversation(Service service, Guid handle)
		{
			if (service == null)
				throw new ArgumentException("Service parameter of the constructor cannot be null.");
			if (handle == Guid.Empty)
				throw new ArgumentException("Handle cannot be empty.");
			m_svc = service;
			m_handle = handle;
		}
		#endregion

		#region Methods
		/// <summary>
		/// Send the <paramref>message</paramref> on this conversation to
		/// remote service(s). The message is not actually sent until the transaction is committed
		/// <seealso cref="Service">Service.Commit</seealso>.
		/// </summary>
		/// <param name="message">The message to be sent. It should have a message type. 
		/// Body is optional.</param>
		/// <param name="connection">The connection to use for sending this message.</param>
		/// <param name="transaction">The transaction to use for sending this message.</param>
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Design", "CA1062:ValidateArgumentsOfPublicMethods")]
        public void Send(
			Message message,
			SqlConnection connection,
			SqlTransaction transaction)
		{
			SqlParameter param;
			SqlCommand cmd = connection.CreateCommand();
			cmd.Transaction = transaction;

			string query = "SEND ON CONVERSATION @ch MESSAGE TYPE @mt ";
			param = cmd.Parameters.Add("@ch", SqlDbType.UniqueIdentifier);
			param.Value = m_handle;
			param = cmd.Parameters.Add("@mt", SqlDbType.NVarChar, 255);
			param.Value = message.Type;

			if (message.Body != null)
			{
				query += " (@msg)";
				param = cmd.Parameters.Add("@msg", SqlDbType.VarBinary, -1);
				param.Value = new SqlBytes(message.Body);
			}
			cmd.CommandText = query;
			cmd.ExecuteNonQuery();
		}

		/// <summary>
		/// Receive a message from the fetched batch of messages from the queue.
		/// </summary>
		/// <returns>The <c>Message</c> object with all properties set.</returns>
		public Message Receive()
		{
			return m_svc.Reader.Read(this);
		}

        /// <summary>
        /// Removes all the remaining messages associated with this conversation 
        /// from the underlying MessageReader.
        /// </summary>
		[System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Design", "CA1031:DoNotCatchGeneralExceptionTypes")]
		public void DrainReader()
        {
            try
            {
                Message msg = null;
                do
                {
                    msg = m_svc.Reader.Read(this);
                } while (msg != null);
            }
            catch
            {
                // this is a temporary hack to deal with a bug in the client stack
                // where it throws an exception upon close of a datareader following
                // a rollback.  This appears to happen only if the rollback occurs prior
                // to processing all of the existing messages in the datareader.
                ;
            }
        }

        /// <summary>
		/// Move this conversation to a new group by invoking the 'MOVE CONVERSATION' T-SQL
		/// command. Changes are not reflected until the transaction commits
		/// <seealso cref="Service">Service.Commit</seealso>.
		/// </summary>
		/// <param name="newGroupId">The new conversation group ID</param>
		/// <param name="connection">The connection to use for executing this statement.</param>
		/// <param name="transaction">The transaction to use for executing this statement.</param>
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Design", "CA1062:ValidateArgumentsOfPublicMethods")]
        public void MoveToGroup(
			Guid newGroupId,
			SqlConnection connection,
			SqlTransaction transaction)
		{
			SqlParameter param;
			SqlCommand cmd = connection.CreateCommand();
			cmd.Transaction = transaction;

			cmd.CommandText = "MOVE CONVERSATION @ch TO @cgid";
			param = cmd.Parameters.Add("@ch", SqlDbType.UniqueIdentifier);
			param.Value = m_handle;
			param = cmd.Parameters.Add("@Cgid", SqlDbType.UniqueIdentifier);
			param.Value = newGroupId;
			cmd.ExecuteNonQuery();
		}

		/// <summary>
		/// End the conversation by invoking the 'END' T-SQL command.
		/// Changes are not reflected until the transaction commits
		/// <seealso cref="Service">Service.Commit</seealso>.
		/// <param name="connection">The connection to use for executing this statement.</param>
		/// <param name="transaction">The transaction to use for executing this statement.</param>
		/// </summary>
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Design", "CA1062:ValidateArgumentsOfPublicMethods")]
        public virtual void End(
			SqlConnection connection,
			SqlTransaction transaction)
		{
			SqlParameter param;
			SqlCommand cmd = connection.CreateCommand();
			cmd.Transaction = transaction;
			cmd.CommandText = "END CONVERSATION @ch";
			param = cmd.Parameters.Add("@ch", SqlDbType.UniqueIdentifier);
			param.Value = m_handle;
			cmd.ExecuteNonQuery();

            DrainReader();
        }

		/// <summary>
		/// End the conversation with clean-up (Hard kill). This should not be used in
		/// typical applications.
		/// Changes are not reflected until the transaction commits
		/// <seealso cref="Service">Service.Commit</seealso>.
		/// <param name="connection">The connection to use for executing this statement.</param>
		/// <param name="transaction">The transaction to use for executing this statement.</param>
		/// </summary>
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Design", "CA1062:ValidateArgumentsOfPublicMethods")]
        public virtual void CleanUp(
			SqlConnection connection,
			SqlTransaction transaction)
		{
			SqlParameter param;
			SqlCommand cmd = connection.CreateCommand();
			cmd.Transaction = transaction;
			cmd.CommandText = "END CONVERSATION @ch WITH CLEANUP";
			param = cmd.Parameters.Add("@ch", SqlDbType.UniqueIdentifier);
			param.Value = m_handle;
			cmd.ExecuteNonQuery();

            DrainReader();
        }

		/// <summary>
		/// End the conversation with an error. This should not be used in
		/// typical applications.
		/// Changes are not reflected until the transaction commits
		/// <seealso cref="Service">Service.Commit</seealso>.
		/// <param name="errorCode">An integer representing the error code.</param>
		/// <param name="errorDescription">A text description of the error.</param>
		/// <param name="connection">The connection to use for executing this statement.</param>
		/// <param name="transaction">The transaction to use for executing this statement.</param>
		/// </summary>
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Design", "CA1062:ValidateArgumentsOfPublicMethods")]
        public virtual void EndWithError(
			int errorCode,
			string errorDescription,
			SqlConnection connection,
			SqlTransaction transaction)
		{
			SqlParameter param;
			SqlCommand cmd = connection.CreateCommand();
			cmd.Transaction = transaction;
			cmd.CommandText = "END CONVERSATION @ch WITH ERROR = @ec DESCRIPTION = @desc";
			param = cmd.Parameters.Add("@ch", SqlDbType.UniqueIdentifier);
			param.Value = m_handle;
			param = cmd.Parameters.Add("@ec", SqlDbType.Int);
			param.Value = errorCode;
			param = cmd.Parameters.Add("@desc", SqlDbType.NVarChar, 255);
			param.Value = errorDescription;
			cmd.ExecuteNonQuery();

            DrainReader();
        }
		#endregion
	}
}
