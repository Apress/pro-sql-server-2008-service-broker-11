using System;
using System.Text;
using System.Collections.Generic;
using System.Workflow.Activities;

namespace ServiceBroker.Workflow.Activities
{
    /// <summary>
    /// Defines the methods and events needed for the message exchange with Service Broker.
    /// </summary>
    [ExternalDataExchange]
    [CorrelationParameter("DialogHandle")]
    public interface IServiceBrokerMessageExchange
    {
        /// <summary>
        /// Sends a new Service Broker message over an openend Service Broker dialog.
        /// </summary>
        /// <param name="MessageType">The used message type</param>
        /// <param name="Message">The actual message to be sent</param>
        /// <param name="DialogHandle">The dialog handle for the opened dialog</param>
        [CorrelationInitializer]
        void SendMessage(string MessageType, string Message, Guid DialogHandle);

        /// <summary>
        /// This event is fired when a new Service Broker message is received.
        /// </summary>
        [CorrelationAlias("DialogHandle", "e.DialogHandle")]
        event EventHandler<MessageReceivedEventArgs> MessageReceived;
    }
}