using System;
using System.ComponentModel;
using System.ComponentModel.Design;
using System.Collections;
using System.Drawing;
using System.Workflow.ComponentModel.Compiler;
using System.Workflow.ComponentModel.Serialization;
using System.Workflow.ComponentModel;
using System.Workflow.ComponentModel.Design;
using System.Workflow.Runtime;
using System.Workflow.Activities;
using System.Workflow.Activities.Rules;

namespace ServiceBroker.SampleWorkflows
{
    public sealed partial class SimpleWorkflowInitiatorService : SequentialWorkflowActivity
    {
        public static DependencyProperty DialogHandleProperty = DependencyProperty.Register("DialogHandle", typeof(System.Guid), typeof(SimpleWorkflowInitiatorService));

        /// <summary>
        /// Represents the dialog handle of the current Service Broker conversation.
        /// </summary>
        [DesignerSerializationVisibilityAttribute(DesignerSerializationVisibility.Visible)]
        [BrowsableAttribute(true)]
        public Guid DialogHandle
        {
            get
            {
                return ((System.Guid)(base.GetValue(SimpleWorkflowInitiatorService.DialogHandleProperty)));
            }
            set
            {
                base.SetValue(SimpleWorkflowInitiatorService.DialogHandleProperty, value);
            }
        }

        public SimpleWorkflowInitiatorService()
        {
            InitializeComponent();
        }

        private void codeActivity1_ExecuteCode(object sender, EventArgs e)
        {
            Console.WriteLine("BEGIN DIALOG executed...");
        }

        private void codeActivity2_ExecuteCode(object sender, EventArgs e)
        {
            Console.WriteLine("Request message sent...");
        }

        public static DependencyProperty ResponseMessageProperty = DependencyProperty.Register("ResponseMessage", typeof(ServiceBroker.Workflow.Activities.MessageReceivedEventArgs), typeof(ServiceBroker.SampleWorkflows.SimpleWorkflowInitiatorService));

        [DesignerSerializationVisibilityAttribute(DesignerSerializationVisibility.Visible)]
        [BrowsableAttribute(true)]
        [CategoryAttribute("Parameters")]
        public ServiceBroker.Workflow.Activities.MessageReceivedEventArgs ResponseMessage
        {
            get
            {
                return ((ServiceBroker.Workflow.Activities.MessageReceivedEventArgs)(base.GetValue(ServiceBroker.SampleWorkflows.SimpleWorkflowInitiatorService.ResponseMessageProperty)));
            }
            set
            {
                base.SetValue(ServiceBroker.SampleWorkflows.SimpleWorkflowInitiatorService.ResponseMessageProperty, value);
            }
        }

        private void codeActivity3_ExecuteCode(object sender, EventArgs e)
        {
            Console.WriteLine("Response message received: " + ResponseMessage.Message);
        }
    }
}