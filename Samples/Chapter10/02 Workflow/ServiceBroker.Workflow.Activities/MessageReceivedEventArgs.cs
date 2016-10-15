using System;
using System.Text;
using System.Collections.Generic;
using System.Workflow.Activities;

namespace ServiceBroker.Workflow.Activities
{
    /// <summary>
    /// Defines the event args that are used when a message is received from another Service Broker service.
    /// </summary>
    [Serializable]
    public class MessageReceivedEventArgs : ExternalDataEventArgs
    {
        private Guid _dialogHandle;
        private string _messageType;
        private string _message;

        public Guid DialogHandle
        {
            get { return _dialogHandle; }
        }

        public string MessageType
        {
            get { return _messageType; }
        }

        public string Message
        {
            get { return _message; }
        }

        public MessageReceivedEventArgs(Guid WorkflowInstanceID, Guid DialogHandle, string MessageType, string Message)
            : base(WorkflowInstanceID)
        {
            this._dialogHandle = DialogHandle;
            this._messageType = MessageType;
            this._message = Message;
        }
    }
}