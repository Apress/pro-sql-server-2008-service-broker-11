using System;
using System.Text;
using System.Collections.Generic;
using System.Workflow.Activities;

namespace ServiceBroker.Workflow.Activities
{
    /// <summary>
    /// Defines the methods needed to interact with Service Broker.
    /// </summary>
    [ExternalDataExchange]
    public interface IServiceBrokerMethods
    {
        /// <summary>
        /// Begins a new Service Broker dialog
        /// </summary>
        /// <param name="ToService">The TargetService wo which the dialog should be openend</param>
        /// <param name="Contract">The used contract for this dialog</param>
        /// <param name="DialogHandle">The resulting dialog handle as a output parameter</param>
        void BeginDialog(string ToService, string Contract, out Guid DialogHandle);

        /// <summary>
        /// Ends a Service Broker dialog
        /// </summary>
        /// <param name="DialogHandle">The dialog handle for the Service Broker dialog that should be ended</param>
        void EndDialog(Guid DialogHandle);
    }
}