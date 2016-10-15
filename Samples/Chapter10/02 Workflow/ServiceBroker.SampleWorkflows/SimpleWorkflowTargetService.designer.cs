using System;
using System.ComponentModel;
using System.ComponentModel.Design;
using System.Collections;
using System.Drawing;
using System.Reflection;
using System.Workflow.ComponentModel.Compiler;
using System.Workflow.ComponentModel.Serialization;
using System.Workflow.ComponentModel;
using System.Workflow.ComponentModel.Design;
using System.Workflow.Runtime;
using System.Workflow.Activities;
using System.Workflow.Activities.Rules;

namespace ServiceBroker.SampleWorkflows
{
	partial class SimpleWorkflowTargetService
	{
		#region Designer generated code
		
		/// <summary> 
		/// Required method for Designer support - do not modify 
		/// the contents of this method with the code editor.
		/// </summary>
        [System.Diagnostics.DebuggerNonUserCode]
		private void InitializeComponent()
		{
            this.CanModifyActivities = true;
            System.Workflow.ComponentModel.ActivityBind activitybind1 = new System.Workflow.ComponentModel.ActivityBind();
            System.Workflow.ComponentModel.WorkflowParameterBinding workflowparameterbinding1 = new System.Workflow.ComponentModel.WorkflowParameterBinding();
            System.Workflow.Runtime.CorrelationToken correlationtoken1 = new System.Workflow.Runtime.CorrelationToken();
            System.Workflow.ComponentModel.WorkflowParameterBinding workflowparameterbinding2 = new System.Workflow.ComponentModel.WorkflowParameterBinding();
            System.Workflow.ComponentModel.WorkflowParameterBinding workflowparameterbinding3 = new System.Workflow.ComponentModel.WorkflowParameterBinding();
            System.Workflow.ComponentModel.ActivityBind activitybind2 = new System.Workflow.ComponentModel.ActivityBind();
            System.Workflow.ComponentModel.WorkflowParameterBinding workflowparameterbinding4 = new System.Workflow.ComponentModel.WorkflowParameterBinding();
            this.DisplayWorkflowEnd = new System.Workflow.Activities.CodeActivity();
            this.SendEndDialogMessage = new System.Workflow.Activities.CallExternalMethodActivity();
            this.SendResponseMessage = new System.Workflow.Activities.CallExternalMethodActivity();
            this.DisplayWorkflowStart = new System.Workflow.Activities.CodeActivity();
            // 
            // DisplayWorkflowEnd
            // 
            this.DisplayWorkflowEnd.Name = "DisplayWorkflowEnd";
            this.DisplayWorkflowEnd.ExecuteCode += new System.EventHandler(this.DisplayWorkflowEnd_ExecuteCode);
            // 
            // SendEndDialogMessage
            // 
            this.SendEndDialogMessage.InterfaceType = typeof(ServiceBroker.Workflow.Activities.IServiceBrokerMethods);
            this.SendEndDialogMessage.MethodName = "EndDialog";
            this.SendEndDialogMessage.Name = "SendEndDialogMessage";
            activitybind1.Name = "SimpleWorkflowTargetService";
            activitybind1.Path = "DialogHandle";
            workflowparameterbinding1.ParameterName = "DialogHandle";
            workflowparameterbinding1.SetBinding(System.Workflow.ComponentModel.WorkflowParameterBinding.ValueProperty, ((System.Workflow.ComponentModel.ActivityBind)(activitybind1)));
            this.SendEndDialogMessage.ParameterBindings.Add(workflowparameterbinding1);
            // 
            // SendResponseMessage
            // 
            correlationtoken1.Name = "DialogHandle";
            correlationtoken1.OwnerActivityName = "SimpleWorkflowTargetService";
            this.SendResponseMessage.CorrelationToken = correlationtoken1;
            this.SendResponseMessage.InterfaceType = typeof(ServiceBroker.Workflow.Activities.IServiceBrokerMessageExchange);
            this.SendResponseMessage.MethodName = "SendMessage";
            this.SendResponseMessage.Name = "SendResponseMessage";
            workflowparameterbinding2.ParameterName = "Message";
            workflowparameterbinding2.Value = "<result>This is the response message...</result>";
            workflowparameterbinding3.ParameterName = "MessageType";
            workflowparameterbinding3.Value = "http://ssb.csharp.at/SSB_Book/c10/ResponseMessage";
            activitybind2.Name = "SimpleWorkflowTargetService";
            activitybind2.Path = "DialogHandle";
            workflowparameterbinding4.ParameterName = "DialogHandle";
            workflowparameterbinding4.SetBinding(System.Workflow.ComponentModel.WorkflowParameterBinding.ValueProperty, ((System.Workflow.ComponentModel.ActivityBind)(activitybind2)));
            this.SendResponseMessage.ParameterBindings.Add(workflowparameterbinding2);
            this.SendResponseMessage.ParameterBindings.Add(workflowparameterbinding3);
            this.SendResponseMessage.ParameterBindings.Add(workflowparameterbinding4);
            // 
            // DisplayWorkflowStart
            // 
            this.DisplayWorkflowStart.Name = "DisplayWorkflowStart";
            this.DisplayWorkflowStart.ExecuteCode += new System.EventHandler(this.DisplayWorkflowStart_ExecuteCode);
            // 
            // SimpleWorkflowTargetService
            // 
            this.Activities.Add(this.DisplayWorkflowStart);
            this.Activities.Add(this.SendResponseMessage);
            this.Activities.Add(this.SendEndDialogMessage);
            this.Activities.Add(this.DisplayWorkflowEnd);
            this.Name = "SimpleWorkflowTargetService";
            this.CanModifyActivities = false;

		}

		#endregion

        private CallExternalMethodActivity SendEndDialogMessage;
        private CallExternalMethodActivity SendResponseMessage;
        private CodeActivity DisplayWorkflowEnd;
        private CodeActivity DisplayWorkflowStart;

















    }
}
