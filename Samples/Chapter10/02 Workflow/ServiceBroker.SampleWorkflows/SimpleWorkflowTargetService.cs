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
	public sealed partial class SimpleWorkflowTargetService : SequentialWorkflowActivity
	{
        private string _messageType;
        private string _message;
        
        public string MessageType
        {
            get { return _messageType; }
            set { _messageType = value; }
        }

        public string Message
        {
            get { return _message; }
            set { _message = value; }
        }

        public static DependencyProperty DialogHandleProperty = DependencyProperty.Register("DialogHandle", typeof(System.Guid), typeof(SimpleWorkflowTargetService));

        /// <summary>
        /// Represents the dialog handle of the current Service Broker conversation.
        /// </summary>
        [DesignerSerializationVisibilityAttribute(DesignerSerializationVisibility.Visible)]
        [BrowsableAttribute(true)]
        public Guid DialogHandle
        {
            get
            {
                return ((System.Guid)(base.GetValue(SimpleWorkflowTargetService.DialogHandleProperty)));
            }
            set
            {
                base.SetValue(SimpleWorkflowTargetService.DialogHandleProperty, value);
            }
        }

		public SimpleWorkflowTargetService()
		{
			InitializeComponent();
		}

        private void DisplayWorkflowStart_ExecuteCode(object sender, EventArgs e)
        {
            Console.WriteLine("The workflow was started");
        }

        private void DisplayWorkflowEnd_ExecuteCode(object sender, EventArgs e)
        {
            Console.WriteLine("The workflow was completed.");
        }
	}
}