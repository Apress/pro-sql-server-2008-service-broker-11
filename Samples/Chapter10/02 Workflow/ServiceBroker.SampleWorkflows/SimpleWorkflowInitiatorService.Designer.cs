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
	partial class SimpleWorkflowInitiatorService
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
            System.Workflow.Runtime.CorrelationToken correlationtoken1 = new System.Workflow.Runtime.CorrelationToken();
            System.Workflow.ComponentModel.ActivityBind activitybind1 = new System.Workflow.ComponentModel.ActivityBind();
            System.Workflow.ComponentModel.WorkflowParameterBinding workflowparameterbinding1 = new System.Workflow.ComponentModel.WorkflowParameterBinding();
            System.Workflow.ComponentModel.ActivityBind activitybind2 = new System.Workflow.ComponentModel.ActivityBind();
            System.Workflow.ComponentModel.WorkflowParameterBinding workflowparameterbinding2 = new System.Workflow.ComponentModel.WorkflowParameterBinding();
            System.Workflow.ComponentModel.WorkflowParameterBinding workflowparameterbinding3 = new System.Workflow.ComponentModel.WorkflowParameterBinding();
            System.Workflow.ComponentModel.WorkflowParameterBinding workflowparameterbinding4 = new System.Workflow.ComponentModel.WorkflowParameterBinding();
            System.Workflow.ComponentModel.ActivityBind activitybind3 = new System.Workflow.ComponentModel.ActivityBind();
            System.Workflow.ComponentModel.WorkflowParameterBinding workflowparameterbinding5 = new System.Workflow.ComponentModel.WorkflowParameterBinding();
            System.Workflow.ComponentModel.WorkflowParameterBinding workflowparameterbinding6 = new System.Workflow.ComponentModel.WorkflowParameterBinding();
            System.Workflow.ComponentModel.WorkflowParameterBinding workflowparameterbinding7 = new System.Workflow.ComponentModel.WorkflowParameterBinding();
            this.DisplayResponseMessageReceived = new System.Workflow.Activities.CodeActivity();
            this.WaitForResponseMessage = new System.Workflow.Activities.HandleExternalEventActivity();
            this.DisplayRequestMessageSent = new System.Workflow.Activities.CodeActivity();
            this.SendRequestMessage = new System.Workflow.Activities.CallExternalMethodActivity();
            this.DisplayBeginDialog = new System.Workflow.Activities.CodeActivity();
            this.BeginDialog = new System.Workflow.Activities.CallExternalMethodActivity();
            // 
            // DisplayResponseMessageReceived
            // 
            this.DisplayResponseMessageReceived.Name = "DisplayResponseMessageReceived";
            this.DisplayResponseMessageReceived.ExecuteCode += new System.EventHandler(this.DisplayResponseMessageReceived_ExecuteCode);
            // 
            // WaitForResponseMessage
            // 
            correlationtoken1.Name = "DialogHandle";
            correlationtoken1.OwnerActivityName = "SimpleWorkflowInitiatorService";
            this.WaitForResponseMessage.CorrelationToken = correlationtoken1;
            this.WaitForResponseMessage.EventName = "MessageReceived";
            this.WaitForResponseMessage.InterfaceType = typeof(ServiceBroker.Workflow.Activities.IServiceBrokerMessageExchange);
            this.WaitForResponseMessage.Name = "WaitForResponseMessage";
            activitybind1.Name = "SimpleWorkflowInitiatorService";
            activitybind1.Path = "ResponseMessage";
            workflowparameterbinding1.ParameterName = "e";
            workflowparameterbinding1.SetBinding(System.Workflow.ComponentModel.WorkflowParameterBinding.ValueProperty, ((System.Workflow.ComponentModel.ActivityBind)(activitybind1)));
            this.WaitForResponseMessage.ParameterBindings.Add(workflowparameterbinding1);
            // 
            // DisplayRequestMessageSent
            // 
            this.DisplayRequestMessageSent.Name = "DisplayRequestMessageSent";
            this.DisplayRequestMessageSent.ExecuteCode += new System.EventHandler(this.DisplayRequestMessageSent_ExecuteCode);
            // 
            // SendRequestMessage
            // 
            this.SendRequestMessage.CorrelationToken = correlationtoken1;
            this.SendRequestMessage.InterfaceType = typeof(ServiceBroker.Workflow.Activities.IServiceBrokerMessageExchange);
            this.SendRequestMessage.MethodName = "SendMessage";
            this.SendRequestMessage.Name = "SendRequestMessage";
            activitybind2.Name = "SimpleWorkflowInitiatorService";
            activitybind2.Path = "DialogHandle";
            workflowparameterbinding2.ParameterName = "DialogHandle";
            workflowparameterbinding2.SetBinding(System.Workflow.ComponentModel.WorkflowParameterBinding.ValueProperty, ((System.Workflow.ComponentModel.ActivityBind)(activitybind2)));
            workflowparameterbinding3.ParameterName = "Message";
            workflowparameterbinding3.Value = "<HelloWorldRequest>Klaus Aschenbrenner</HelloWorldRequest>";
            workflowparameterbinding4.ParameterName = "MessageType";
            workflowparameterbinding4.Value = "http://ssb.csharp.at/SSB_Book/c10/RequestMessage";
            this.SendRequestMessage.ParameterBindings.Add(workflowparameterbinding2);
            this.SendRequestMessage.ParameterBindings.Add(workflowparameterbinding3);
            this.SendRequestMessage.ParameterBindings.Add(workflowparameterbinding4);
            // 
            // DisplayBeginDialog
            // 
            this.DisplayBeginDialog.Name = "DisplayBeginDialog";
            this.DisplayBeginDialog.ExecuteCode += new System.EventHandler(this.DisplayBeginDialog_ExecuteCode);
            // 
            // BeginDialog
            // 
            this.BeginDialog.InterfaceType = typeof(ServiceBroker.Workflow.Activities.IServiceBrokerMethods);
            this.BeginDialog.MethodName = "BeginDialog";
            this.BeginDialog.Name = "BeginDialog";
            activitybind3.Name = "SimpleWorkflowInitiatorService";
            activitybind3.Path = "DialogHandle";
            workflowparameterbinding5.ParameterName = "DialogHandle";
            workflowparameterbinding5.SetBinding(System.Workflow.ComponentModel.WorkflowParameterBinding.ValueProperty, ((System.Workflow.ComponentModel.ActivityBind)(activitybind3)));
            workflowparameterbinding6.ParameterName = "Contract";
            workflowparameterbinding6.Value = "http://ssb.csharp.at/SSB_Book/c10/HelloWorldContract";
            workflowparameterbinding7.ParameterName = "ToService";
            workflowparameterbinding7.Value = "TargetService";
            this.BeginDialog.ParameterBindings.Add(workflowparameterbinding5);
            this.BeginDialog.ParameterBindings.Add(workflowparameterbinding6);
            this.BeginDialog.ParameterBindings.Add(workflowparameterbinding7);
            // 
            // SimpleWorkflowInitiatorService
            // 
            this.Activities.Add(this.BeginDialog);
            this.Activities.Add(this.DisplayBeginDialog);
            this.Activities.Add(this.SendRequestMessage);
            this.Activities.Add(this.DisplayRequestMessageSent);
            this.Activities.Add(this.WaitForResponseMessage);
            this.Activities.Add(this.DisplayResponseMessageReceived);
            this.Name = "SimpleWorkflowInitiatorService";
            this.CanModifyActivities = false;

		}

		#endregion

        private CodeActivity DisplayResponseMessageReceived;
        private CodeActivity DisplayBeginDialog;
        private CallExternalMethodActivity SendRequestMessage;
        private CodeActivity DisplayRequestMessageSent;
        private HandleExternalEventActivity WaitForResponseMessage;
        private CallExternalMethodActivity BeginDialog;

















    }
}
