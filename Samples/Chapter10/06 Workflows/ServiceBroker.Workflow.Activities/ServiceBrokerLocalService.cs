using System;
using System.Text;
using System.Data;
using System.Data.SqlClient;
using System.Collections.Generic;
using System.Workflow.Runtime;

namespace ServiceBroker.Workflow.Activities
{
    /// <summary>
    /// Implements the local service used for the communication between WF and Service Broker.
    /// </summary>
    public class ServiceBrokerLocalService : IServiceBrokerMethods, IServiceBrokerMessageExchange
    {
        /// <summary>
        /// This private instance encapsulates the complete Service Broker API used in this sample.
        /// </summary>
        private ServiceBrokerImpl _broker;

        /// <summary>
        /// Property around the Service Broker object.
        /// </summary>
        public ServiceBrokerImpl Broker
        {
            get { return _broker; }
            set { _broker = value; }
        }

        /// <summary>
        /// This event is raised when a new Service Broker message is received.
        /// </summary>
        public event EventHandler<MessageReceivedEventArgs> MessageReceived;

        /// <summary>
        /// Begins a new Service Broker dialog.
        /// </summary>
        /// <param name="ToService">The service name to which a Service Broker dialog should be established.</param>
        /// <param name="Contract">The used contract</param>
        /// <param name="DialogHandle">The used dialog handle as an output parameter</param>
        public void BeginDialog(string ToService, string Contract, out Guid DialogHandle)
        {
            _broker.BeginDialog(ToService, Contract, WorkflowEnvironment.WorkflowInstanceId, out DialogHandle);
        }

        /// <summary>
        /// Ends a Service Broker dialog.
        /// </summary>
        /// <param name="DialogHandle">Dialog handle for the dialog to be ended.</param>
        public void EndDialog(Guid DialogHandle)
        {
            _broker.EndDialog(DialogHandle);
        }

        /// <summary>
        /// Sends a new Service Broker message over an existing dialog.
        /// </summary>
        /// <param name="MessageType">The used message type</param>
        /// <param name="Message">The content of the actual message</param>
        /// <param name="DialogHandle">The dialog handle for the used dialog</param>
        public void SendMessage(string MessageType, string Message, Guid DialogHandle)
        {
            _broker.SendMessage(MessageType, Message, DialogHandle);   
        }

        /// <summary>
        /// Is called when a new Service Broker message is received and raised internally the MessageReceived event.
        /// </summary>
        /// <param name="e"></param>
        public void OnMessageReceived(MessageReceivedEventArgs e)
        {
            if (this.MessageReceived != null)
                this.MessageReceived(null, e);
        }
    }
}