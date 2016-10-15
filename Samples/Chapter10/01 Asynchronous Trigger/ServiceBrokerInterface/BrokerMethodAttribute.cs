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
using System.Collections.Generic;
using System.Text;

#endregion

namespace Microsoft.Samples.SqlServer
{
	/// <summary>
	/// This attribute is used for tagging methods of a derived <c>Service</c> class
	/// with conditions on when the method should be called by <c>Service.DispatchMessage</c>.
	/// The methods of the derived <c>Service</c> class may have multiple BrokerMethodAttributes.
	/// </summary>
	[AttributeUsage(AttributeTargets.Method, Inherited = false, AllowMultiple = true)]
	public sealed class BrokerMethodAttribute : Attribute
	{
        private string m_contract;
        /// <value>The contract the method handles.</value>
        public string Contract
        {
            get { return m_contract; }
        }

        private string m_messageType;
        /// <value>The type of message that the method handles.</value>
        public string MessageType
        {
            get { return m_messageType; }
        }

        private int m_state;
        /// <value>If defined, the state that the method handles. (Else -1)</value>
		public int State
		{
			get { return m_state; }
		}

        /// <summary>
        /// Constructs a <c>BrokerMethodAttribute</c> with no state and contract.
        /// </summary>
        /// <param name="messageType">The message type</param>
        public BrokerMethodAttribute(string messageType)
        {
            m_contract = "";
            m_messageType = messageType;
            m_state = -1;
        }

        /// <summary>
        /// Constructs a <c>BrokerMethodAttribute</c> with no state.
		/// </summary>
        /// <param name="contract">The contract</param>
        /// <param name="messageType">The message type</param>
        public BrokerMethodAttribute(string contract, string messageType)
        {
            m_contract = contract;
            m_messageType = messageType;
			m_state = -1;
		}

        /// <summary>
        /// Constructs a <c>BrokerMethodAttribute</c> with no contract.
        /// </summary>
        /// <param name="messageType">The message type</param>
        /// <param name="state">The state</param>
        public BrokerMethodAttribute(int state, string messageType)
        {
            m_contract = "";
            m_messageType = messageType;
            m_state = state;
        }

        /// <summary>
		/// Constructs a <c>BrokerMethodAttribute</c> with given state.
		/// </summary>
        /// <param name="contract">The contract</param>
        /// <param name="messageType">The message type</param>
        /// <param name="state">The state</param>
		public BrokerMethodAttribute(int state, string contract, string messageType)
		{
            m_contract = contract;
            m_messageType = messageType;
			m_state = state;
		}

		/// <summary>
		/// The GetHashCode is overriden so that this object can be appropriately hashed.
		/// </summary>
		/// <returns>An int valued hash code.</returns>
  		public override int GetHashCode()
		{
			return m_state.GetHashCode() + m_contract.GetHashCode() + m_messageType.GetHashCode();
		}

		/// <summary>
		/// The Equals method is overriden for this class.
		/// </summary>
		/// <param name="obj"></param>
		/// <returns></returns>
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Design", "CA1062:ValidateArgumentsOfPublicMethods")]
        public override bool Equals(object obj)
		{
			if (obj.GetType() != typeof(BrokerMethodAttribute))
				return false;
			BrokerMethodAttribute other = (BrokerMethodAttribute)obj;
			return m_state == other.m_state && 
                   m_contract == other.m_contract && 
                   m_messageType == other.m_messageType;
		}

	}
}
