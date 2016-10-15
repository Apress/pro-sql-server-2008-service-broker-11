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
    /// This class wraps the exceptions thrown in the <c>Run</c> method of the
	/// <c>Service</c> class.
    /// </remarks>
    [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2237:MarkISerializableTypesWithSerializable"), System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Design", "CA1032:ImplementStandardExceptionConstructors")]
    public class ServiceException : Exception
    {
        #region Fields
		private SqlConnection m_connection;
        /// <summary>
        /// 
        /// </summary>
		public SqlConnection Connection
		{
			get { return m_connection; }
		}

		private SqlTransaction m_transaction;
        /// <summary>
        /// 
        /// </summary>
		public SqlTransaction Transaction
		{
			get { return m_transaction; }
		}

		private Conversation m_currentConversation;
        /// <summary>
        /// 
        /// </summary>
		public Conversation CurrentConversation
		{
			get { return m_currentConversation; }
		}
		#endregion

		#region Constructor
        /// <summary>
        /// 
        /// </summary>
        /// <param name="currentConversation"></param>
        /// <param name="connection"></param>
        /// <param name="transaction"></param>
        /// <param name="exception"></param>
		public ServiceException(
			Conversation currentConversation,
			SqlConnection connection,
			SqlTransaction transaction,
			Exception exception)
			: base(exception.Message, exception)
		{
			m_currentConversation = currentConversation;
			m_connection = connection;
			m_transaction = transaction;
		}
		#endregion
    }
}
