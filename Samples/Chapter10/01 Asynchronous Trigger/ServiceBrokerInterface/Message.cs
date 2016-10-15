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
using System.IO;
#endregion

namespace Microsoft.Samples.SqlServer
{
    /// <remarks>
    /// The <c>Message</c> class is used both for sending as well as receiving
    /// messages from a <c>Service</c>. When used for sending messages, we only use
    /// the <c>Type</c> and the <c>Body</c> properties. When a message a received,
    /// the object contains all the properties describing the message received.
    /// </remarks>
    public class Message
    {
        # region Constant definitions
        /// <value>
        /// System message type for event notification messages.
        /// </value>
        public const string EventNotificationType = "http://schemas.microsoft.com/SQL/Notifications/EventNotification";

        /// <value>
        /// System message type for query notification messages.
        /// </value>
        public const string QueryNotificationType = "http://schemas.microsoft.com/SQL/Notifications/QueryNotification";

        /// <value>
        /// System message type for message indicating failed remote service binding.
        /// </value>
        public const string FailedRemoteServiceBindingType = "http://schemas.microsoft.com/SQL/ServiceBroker/BrokerConfigurationNotice/FailedRemoteServiceBinding";

        /// <value>
        /// System message type for message indicating failed route.
        /// </value>
        public const string FailedRouteType = "http://schemas.microsoft.com/SQL/ServiceBroker/BrokerConfigurationNotice/FailedRoute";

        /// <value>
        /// System message type for message indicating missing remote service binding.
        /// </value>
        public const string MissingRemoteServiceBindingType = "http://schemas.microsoft.com/SQL/ServiceBroker/BrokerConfigurationNotice/MissingRemoteServiceBinding";

        /// <value>
        /// System message type for message indicating missing route.
        /// </value>
        public const string MissingRouteType = "http://schemas.microsoft.com/SQL/ServiceBroker/BrokerConfigurationNotice/MissingRoute";

        /// <value>
        /// System message type for dialog timer messages.
        /// </value>
        public const string DialogTimerType = "http://schemas.microsoft.com/SQL/ServiceBroker/DialogTimer";

        /// <value>
        /// System message type for message indicating end of dialog.
        /// </value>
        public const string EndDialogType = "http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog";

        /// <value>
        /// System message type for error messages.
        /// </value>
        public const string ErrorType = "http://schemas.microsoft.com/SQL/ServiceBroker/Error";

        /// <value>
        /// System message type for diagnostic description messages.
        /// </value>
        public const string DescriptionType = "http://schemas.microsoft.com/SQL/ServiceBroker/ServiceDiagnostic/Description";

        /// <value>
        /// System message type for diagnostic query messages.
        /// </value>
        public const string QueryType = "http://schemas.microsoft.com/SQL/ServiceBroker/ServiceDiagnostic/Query";

        /// <value>
        /// System message type for diagnostic status messages.
        /// </value>
        public const string StatusType = "http://schemas.microsoft.com/SQL/ServiceBroker/ServiceDiagnostic/Status";

        /// <value>
        /// System message type for echo service messages.
        /// </value>
        public const string EchoType = "http://schemas.microsoft.com/SQL/ServiceBroker/ServiceEcho/Echo";
        # endregion

        #region Constructors
        /// <summary>
        /// Default constructor
        /// </summary>
        public Message()
        {
        }

        /// <summary>
        /// Creates a message object with given parameters.
        /// </summary>
        /// <param name="type">The message type</param>
        /// <param name="body">A stream referencing hte body of the message</param>
        public Message(string type, Stream body)
        {
            m_type = type;
            m_body = body;
        }
        #endregion

        #region private fields
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Performance", "CA1823:AvoidUnusedPrivateFields")]
        private SqlDataReader m_reader;
        #endregion

        #region Properties
        private Stream m_body;
        private string _bodyAsString;

        /// <value>A stream representing the message body.</value>
        public Stream Body
        {
            get { return m_body; }
            set { m_body = value; }
        }

        public string BodyAsString
        {
            get { return _bodyAsString; }
            set { _bodyAsString = value; }
        }

        private string m_type;
        /// <value>The message type.</value>
        public string Type
        {
            get { return m_type; }
            set { m_type = value; }
        }

        private Conversation m_conv;
        /// <value>The conversation from which the message was received.</value>
        public Conversation Conversation
        {
            get { return m_conv; }
            set { m_conv = value; }
        }

        private Guid m_convGroupId;
        /// <value>The conversation group of the conversation from which the message was received.</value>
        public Guid ConversationGroupId
        {
            get { return m_convGroupId; }
            set { m_convGroupId = value; }
        }

        private long m_sequenceNumber;
        /// <value>The sequence number of the message in the queue.</value>
        public long SequenceNumber
        {
            get { return m_sequenceNumber; }
            set { m_sequenceNumber = value; }
        }

        private string m_validation;
        /// <value>The type of validation: 'E' means empty, 'N' means none, 'X' means well-formed XML.</value>
        public string Validation
        {
            get { return m_validation; }
            set { m_validation = value; }
        }

        private string m_serviceName;
        /// <value>The name of the service to which this message was sent.</value>
        public string ServiceName
        {
            get { return m_serviceName; }
            set { m_serviceName = value; }
        }

        private string m_contractName;
        /// <value>The contract that the message adhered to.</value>
        public string ContractName
        {
            get { return m_contractName; }
            set { m_contractName = value; }
        }
        #endregion

        #region Methods
        internal void Read(SqlDataReader reader, Service service)
        {
            //			RECEIVE conversation_group_id, conversation_handle, 
            //				message_sequence_number, service_name, service_contract_name, 
            //				message_type_name, validation, message_body
            //			FROM Queue
            m_reader = reader;
            m_convGroupId = reader.GetGuid(0);
            m_conv = new Conversation(service, reader.GetGuid(1));
            m_sequenceNumber = reader.GetInt64(2);
            m_serviceName = reader.GetString(3);
            m_contractName = reader.GetString(4);
            m_type = reader.GetString(5);
            m_validation = reader.GetString(6);
            if (!reader.IsDBNull(7))
            {
                SqlBytes sb = reader.GetSqlBytes(7);
                Body = sb.Stream;
                BodyAsString = new System.Text.UnicodeEncoding().GetString(sb.Value).Substring(1);
            }
            else
                Body = null;
        }
        #endregion

    }

}
