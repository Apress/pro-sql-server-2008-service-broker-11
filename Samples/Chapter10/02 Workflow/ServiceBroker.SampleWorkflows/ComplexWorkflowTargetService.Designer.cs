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
	partial class ComplexWorkflowTargetService
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
            System.Workflow.ComponentModel.ActivityBind activitybind3 = new System.Workflow.ComponentModel.ActivityBind();
            System.Workflow.ComponentModel.WorkflowParameterBinding workflowparameterbinding4 = new System.Workflow.ComponentModel.WorkflowParameterBinding();
            System.Workflow.ComponentModel.WorkflowParameterBinding workflowparameterbinding5 = new System.Workflow.ComponentModel.WorkflowParameterBinding();
            System.Workflow.ComponentModel.ActivityBind activitybind4 = new System.Workflow.ComponentModel.ActivityBind();
            System.Workflow.ComponentModel.WorkflowParameterBinding workflowparameterbinding6 = new System.Workflow.ComponentModel.WorkflowParameterBinding();
            System.Workflow.ComponentModel.WorkflowParameterBinding workflowparameterbinding7 = new System.Workflow.ComponentModel.WorkflowParameterBinding();
            System.Workflow.Runtime.CorrelationToken correlationtoken2 = new System.Workflow.Runtime.CorrelationToken();
            System.Workflow.ComponentModel.ActivityBind activitybind5 = new System.Workflow.ComponentModel.ActivityBind();
            System.Workflow.ComponentModel.WorkflowParameterBinding workflowparameterbinding8 = new System.Workflow.ComponentModel.WorkflowParameterBinding();
            System.Workflow.ComponentModel.ActivityBind activitybind6 = new System.Workflow.ComponentModel.ActivityBind();
            System.Workflow.ComponentModel.WorkflowParameterBinding workflowparameterbinding9 = new System.Workflow.ComponentModel.WorkflowParameterBinding();
            System.Workflow.ComponentModel.WorkflowParameterBinding workflowparameterbinding10 = new System.Workflow.ComponentModel.WorkflowParameterBinding();
            System.Workflow.ComponentModel.ActivityBind activitybind7 = new System.Workflow.ComponentModel.ActivityBind();
            System.Workflow.ComponentModel.WorkflowParameterBinding workflowparameterbinding11 = new System.Workflow.ComponentModel.WorkflowParameterBinding();
            System.Workflow.ComponentModel.ActivityBind activitybind8 = new System.Workflow.ComponentModel.ActivityBind();
            System.Workflow.ComponentModel.WorkflowParameterBinding workflowparameterbinding12 = new System.Workflow.ComponentModel.WorkflowParameterBinding();
            System.Workflow.ComponentModel.WorkflowParameterBinding workflowparameterbinding13 = new System.Workflow.ComponentModel.WorkflowParameterBinding();
            System.Workflow.ComponentModel.WorkflowParameterBinding workflowparameterbinding14 = new System.Workflow.ComponentModel.WorkflowParameterBinding();
            System.Workflow.Runtime.CorrelationToken correlationtoken3 = new System.Workflow.Runtime.CorrelationToken();
            System.Workflow.ComponentModel.ActivityBind activitybind9 = new System.Workflow.ComponentModel.ActivityBind();
            System.Workflow.ComponentModel.WorkflowParameterBinding workflowparameterbinding15 = new System.Workflow.ComponentModel.WorkflowParameterBinding();
            System.Workflow.Runtime.CorrelationToken correlationtoken4 = new System.Workflow.Runtime.CorrelationToken();
            System.Workflow.ComponentModel.ActivityBind activitybind10 = new System.Workflow.ComponentModel.ActivityBind();
            System.Workflow.ComponentModel.WorkflowParameterBinding workflowparameterbinding16 = new System.Workflow.ComponentModel.WorkflowParameterBinding();
            System.Workflow.ComponentModel.WorkflowParameterBinding workflowparameterbinding17 = new System.Workflow.ComponentModel.WorkflowParameterBinding();
            System.Workflow.ComponentModel.ActivityBind activitybind11 = new System.Workflow.ComponentModel.ActivityBind();
            System.Workflow.ComponentModel.WorkflowParameterBinding workflowparameterbinding18 = new System.Workflow.ComponentModel.WorkflowParameterBinding();
            System.Workflow.ComponentModel.ActivityBind activitybind12 = new System.Workflow.ComponentModel.ActivityBind();
            System.Workflow.ComponentModel.WorkflowParameterBinding workflowparameterbinding19 = new System.Workflow.ComponentModel.WorkflowParameterBinding();
            System.Workflow.ComponentModel.WorkflowParameterBinding workflowparameterbinding20 = new System.Workflow.ComponentModel.WorkflowParameterBinding();
            System.Workflow.ComponentModel.WorkflowParameterBinding workflowparameterbinding21 = new System.Workflow.ComponentModel.WorkflowParameterBinding();
            System.Workflow.Runtime.CorrelationToken correlationtoken5 = new System.Workflow.Runtime.CorrelationToken();
            System.Workflow.ComponentModel.ActivityBind activitybind13 = new System.Workflow.ComponentModel.ActivityBind();
            System.Workflow.ComponentModel.WorkflowParameterBinding workflowparameterbinding22 = new System.Workflow.ComponentModel.WorkflowParameterBinding();
            System.Workflow.ComponentModel.ActivityBind activitybind14 = new System.Workflow.ComponentModel.ActivityBind();
            System.Workflow.ComponentModel.WorkflowParameterBinding workflowparameterbinding23 = new System.Workflow.ComponentModel.WorkflowParameterBinding();
            System.Workflow.ComponentModel.WorkflowParameterBinding workflowparameterbinding24 = new System.Workflow.ComponentModel.WorkflowParameterBinding();
            System.Workflow.Runtime.CorrelationToken correlationtoken6 = new System.Workflow.Runtime.CorrelationToken();
            System.Workflow.ComponentModel.ActivityBind activitybind15 = new System.Workflow.ComponentModel.ActivityBind();
            System.Workflow.ComponentModel.WorkflowParameterBinding workflowparameterbinding25 = new System.Workflow.ComponentModel.WorkflowParameterBinding();
            System.Workflow.ComponentModel.ActivityBind activitybind16 = new System.Workflow.ComponentModel.ActivityBind();
            System.Workflow.ComponentModel.WorkflowParameterBinding workflowparameterbinding26 = new System.Workflow.ComponentModel.WorkflowParameterBinding();
            System.Workflow.ComponentModel.WorkflowParameterBinding workflowparameterbinding27 = new System.Workflow.ComponentModel.WorkflowParameterBinding();
            System.Workflow.ComponentModel.ActivityBind activitybind17 = new System.Workflow.ComponentModel.ActivityBind();
            System.Workflow.ComponentModel.WorkflowParameterBinding workflowparameterbinding28 = new System.Workflow.ComponentModel.WorkflowParameterBinding();
            System.Workflow.ComponentModel.ActivityBind activitybind18 = new System.Workflow.ComponentModel.ActivityBind();
            System.Workflow.ComponentModel.WorkflowParameterBinding workflowparameterbinding29 = new System.Workflow.ComponentModel.WorkflowParameterBinding();
            System.Workflow.ComponentModel.WorkflowParameterBinding workflowparameterbinding30 = new System.Workflow.ComponentModel.WorkflowParameterBinding();
            System.Workflow.ComponentModel.WorkflowParameterBinding workflowparameterbinding31 = new System.Workflow.ComponentModel.WorkflowParameterBinding();
            this.DisplayInventoryServiceReceive = new System.Workflow.Activities.CodeActivity();
            this.ReceiveInventoryServiceResponseMessage = new System.Workflow.Activities.HandleExternalEventActivity();
            this.SendInventoryServiceRequestMessage = new System.Workflow.Activities.CallExternalMethodActivity();
            this.BeginDialogInventoryService = new System.Workflow.Activities.CallExternalMethodActivity();
            this.ConstructInventoryServiceRequestMessage = new System.Workflow.Activities.CodeActivity();
            this.DisplayAccountingServiceReceive = new System.Workflow.Activities.CodeActivity();
            this.ReceiveAccountingServiceResponseMessage = new System.Workflow.Activities.HandleExternalEventActivity();
            this.SendAccountingServiceRequestMessage = new System.Workflow.Activities.CallExternalMethodActivity();
            this.BeginDialogAccountingService = new System.Workflow.Activities.CallExternalMethodActivity();
            this.ConstructAccountingServiceRequestMessage = new System.Workflow.Activities.CodeActivity();
            this.DisplayCreditCardServiceReceive = new System.Workflow.Activities.CodeActivity();
            this.ReceiveCreditCardServiceResponseMessage = new System.Workflow.Activities.HandleExternalEventActivity();
            this.SendCreditCardServiceRequestMessage = new System.Workflow.Activities.CallExternalMethodActivity();
            this.BeginDialogCreditCardService = new System.Workflow.Activities.CallExternalMethodActivity();
            this.ConstructCreditCardRequestMessage = new System.Workflow.Activities.CodeActivity();
            this.InventoryService = new System.Workflow.Activities.SequenceActivity();
            this.AccountingService = new System.Workflow.Activities.SequenceActivity();
            this.CreditCardService = new System.Workflow.Activities.SequenceActivity();
            this.WorkflowFinished = new System.Workflow.Activities.CodeActivity();
            this.SendOrderServiceResponseMessage = new System.Workflow.Activities.CallExternalMethodActivity();
            this.ConstructOrderResponseMessage = new System.Workflow.Activities.CodeActivity();
            this.ReceiveShippingServiceResponseMessage = new System.Workflow.Activities.HandleExternalEventActivity();
            this.SendShippingServiceRequestMessage = new System.Workflow.Activities.CallExternalMethodActivity();
            this.BeginDialogShippingService = new System.Workflow.Activities.CallExternalMethodActivity();
            this.ConstructShippingServiceRequestMessage = new System.Workflow.Activities.CodeActivity();
            this.SendOutRequestMessages = new System.Workflow.Activities.ParallelActivity();
            this.DisplayOrderRequestMessage = new System.Workflow.Activities.CodeActivity();
            // 
            // DisplayInventoryServiceReceive
            // 
            this.DisplayInventoryServiceReceive.Name = "DisplayInventoryServiceReceive";
            this.DisplayInventoryServiceReceive.ExecuteCode += new System.EventHandler(this.DisplayInventoryServiceReceive_ExecuteCode);
            // 
            // ReceiveInventoryServiceResponseMessage
            // 
            correlationtoken1.Name = "InventoryServiceDialogHandle";
            correlationtoken1.OwnerActivityName = "ComplexWorkflowTargetService";
            this.ReceiveInventoryServiceResponseMessage.CorrelationToken = correlationtoken1;
            this.ReceiveInventoryServiceResponseMessage.EventName = "MessageReceived";
            this.ReceiveInventoryServiceResponseMessage.InterfaceType = typeof(ServiceBroker.Workflow.Activities.IServiceBrokerMessageExchange);
            this.ReceiveInventoryServiceResponseMessage.Name = "ReceiveInventoryServiceResponseMessage";
            activitybind1.Name = "ComplexWorkflowTargetService";
            activitybind1.Path = "InventoryServiceResponseMessage";
            workflowparameterbinding1.ParameterName = "e";
            workflowparameterbinding1.SetBinding(System.Workflow.ComponentModel.WorkflowParameterBinding.ValueProperty, ((System.Workflow.ComponentModel.ActivityBind)(activitybind1)));
            this.ReceiveInventoryServiceResponseMessage.ParameterBindings.Add(workflowparameterbinding1);
            // 
            // SendInventoryServiceRequestMessage
            // 
            this.SendInventoryServiceRequestMessage.CorrelationToken = correlationtoken1;
            this.SendInventoryServiceRequestMessage.InterfaceType = typeof(ServiceBroker.Workflow.Activities.IServiceBrokerMessageExchange);
            this.SendInventoryServiceRequestMessage.MethodName = "SendMessage";
            this.SendInventoryServiceRequestMessage.Name = "SendInventoryServiceRequestMessage";
            activitybind2.Name = "ComplexWorkflowTargetService";
            activitybind2.Path = "InventoryServiceDialogHandle";
            workflowparameterbinding2.ParameterName = "DialogHandle";
            workflowparameterbinding2.SetBinding(System.Workflow.ComponentModel.WorkflowParameterBinding.ValueProperty, ((System.Workflow.ComponentModel.ActivityBind)(activitybind2)));
            workflowparameterbinding3.ParameterName = "MessageType";
            workflowparameterbinding3.Value = "http://ssb.csharp.at/SSB_Book/c10/InventoryRequestMessage";
            activitybind3.Name = "ComplexWorkflowTargetService";
            activitybind3.Path = "InventoryServiceRequestMessage";
            workflowparameterbinding4.ParameterName = "Message";
            workflowparameterbinding4.SetBinding(System.Workflow.ComponentModel.WorkflowParameterBinding.ValueProperty, ((System.Workflow.ComponentModel.ActivityBind)(activitybind3)));
            this.SendInventoryServiceRequestMessage.ParameterBindings.Add(workflowparameterbinding2);
            this.SendInventoryServiceRequestMessage.ParameterBindings.Add(workflowparameterbinding3);
            this.SendInventoryServiceRequestMessage.ParameterBindings.Add(workflowparameterbinding4);
            // 
            // BeginDialogInventoryService
            // 
            this.BeginDialogInventoryService.InterfaceType = typeof(ServiceBroker.Workflow.Activities.IServiceBrokerMethods);
            this.BeginDialogInventoryService.MethodName = "BeginDialog";
            this.BeginDialogInventoryService.Name = "BeginDialogInventoryService";
            workflowparameterbinding5.ParameterName = "ToService";
            workflowparameterbinding5.Value = "InventoryService";
            activitybind4.Name = "ComplexWorkflowTargetService";
            activitybind4.Path = "InventoryServiceDialogHandle";
            workflowparameterbinding6.ParameterName = "DialogHandle";
            workflowparameterbinding6.SetBinding(System.Workflow.ComponentModel.WorkflowParameterBinding.ValueProperty, ((System.Workflow.ComponentModel.ActivityBind)(activitybind4)));
            workflowparameterbinding7.ParameterName = "Contract";
            workflowparameterbinding7.Value = "http://ssb.csharp.at/SSB_Book/c10/InventoryContract";
            this.BeginDialogInventoryService.ParameterBindings.Add(workflowparameterbinding5);
            this.BeginDialogInventoryService.ParameterBindings.Add(workflowparameterbinding6);
            this.BeginDialogInventoryService.ParameterBindings.Add(workflowparameterbinding7);
            // 
            // ConstructInventoryServiceRequestMessage
            // 
            this.ConstructInventoryServiceRequestMessage.Name = "ConstructInventoryServiceRequestMessage";
            this.ConstructInventoryServiceRequestMessage.ExecuteCode += new System.EventHandler(this.ConstructInventoryServiceRequestMessage_ExecuteCode);
            // 
            // DisplayAccountingServiceReceive
            // 
            this.DisplayAccountingServiceReceive.Name = "DisplayAccountingServiceReceive";
            this.DisplayAccountingServiceReceive.ExecuteCode += new System.EventHandler(this.DisplayAccountingServiceReceive_ExecuteCode);
            // 
            // ReceiveAccountingServiceResponseMessage
            // 
            correlationtoken2.Name = "AccountingServiceDialogHandle";
            correlationtoken2.OwnerActivityName = "ComplexWorkflowTargetService";
            this.ReceiveAccountingServiceResponseMessage.CorrelationToken = correlationtoken2;
            this.ReceiveAccountingServiceResponseMessage.EventName = "MessageReceived";
            this.ReceiveAccountingServiceResponseMessage.InterfaceType = typeof(ServiceBroker.Workflow.Activities.IServiceBrokerMessageExchange);
            this.ReceiveAccountingServiceResponseMessage.Name = "ReceiveAccountingServiceResponseMessage";
            activitybind5.Name = "ComplexWorkflowTargetService";
            activitybind5.Path = "AccountingServiceResponseMessage";
            workflowparameterbinding8.ParameterName = "e";
            workflowparameterbinding8.SetBinding(System.Workflow.ComponentModel.WorkflowParameterBinding.ValueProperty, ((System.Workflow.ComponentModel.ActivityBind)(activitybind5)));
            this.ReceiveAccountingServiceResponseMessage.ParameterBindings.Add(workflowparameterbinding8);
            // 
            // SendAccountingServiceRequestMessage
            // 
            this.SendAccountingServiceRequestMessage.CorrelationToken = correlationtoken2;
            this.SendAccountingServiceRequestMessage.InterfaceType = typeof(ServiceBroker.Workflow.Activities.IServiceBrokerMessageExchange);
            this.SendAccountingServiceRequestMessage.MethodName = "SendMessage";
            this.SendAccountingServiceRequestMessage.Name = "SendAccountingServiceRequestMessage";
            activitybind6.Name = "ComplexWorkflowTargetService";
            activitybind6.Path = "AccountingServiceDialogHandle";
            workflowparameterbinding9.ParameterName = "DialogHandle";
            workflowparameterbinding9.SetBinding(System.Workflow.ComponentModel.WorkflowParameterBinding.ValueProperty, ((System.Workflow.ComponentModel.ActivityBind)(activitybind6)));
            workflowparameterbinding10.ParameterName = "MessageType";
            workflowparameterbinding10.Value = "http://ssb.csharp.at/SSB_Book/c10/AccountingRequestMessage";
            activitybind7.Name = "ComplexWorkflowTargetService";
            activitybind7.Path = "AccountingServiceRequestMessage";
            workflowparameterbinding11.ParameterName = "Message";
            workflowparameterbinding11.SetBinding(System.Workflow.ComponentModel.WorkflowParameterBinding.ValueProperty, ((System.Workflow.ComponentModel.ActivityBind)(activitybind7)));
            this.SendAccountingServiceRequestMessage.ParameterBindings.Add(workflowparameterbinding9);
            this.SendAccountingServiceRequestMessage.ParameterBindings.Add(workflowparameterbinding10);
            this.SendAccountingServiceRequestMessage.ParameterBindings.Add(workflowparameterbinding11);
            // 
            // BeginDialogAccountingService
            // 
            this.BeginDialogAccountingService.InterfaceType = typeof(ServiceBroker.Workflow.Activities.IServiceBrokerMethods);
            this.BeginDialogAccountingService.MethodName = "BeginDialog";
            this.BeginDialogAccountingService.Name = "BeginDialogAccountingService";
            activitybind8.Name = "ComplexWorkflowTargetService";
            activitybind8.Path = "AccountingServiceDialogHandle";
            workflowparameterbinding12.ParameterName = "DialogHandle";
            workflowparameterbinding12.SetBinding(System.Workflow.ComponentModel.WorkflowParameterBinding.ValueProperty, ((System.Workflow.ComponentModel.ActivityBind)(activitybind8)));
            workflowparameterbinding13.ParameterName = "ToService";
            workflowparameterbinding13.Value = "AccountingService";
            workflowparameterbinding14.ParameterName = "Contract";
            workflowparameterbinding14.Value = "http://ssb.csharp.at/SSB_Book/c10/AccountingContract";
            this.BeginDialogAccountingService.ParameterBindings.Add(workflowparameterbinding12);
            this.BeginDialogAccountingService.ParameterBindings.Add(workflowparameterbinding13);
            this.BeginDialogAccountingService.ParameterBindings.Add(workflowparameterbinding14);
            // 
            // ConstructAccountingServiceRequestMessage
            // 
            this.ConstructAccountingServiceRequestMessage.Name = "ConstructAccountingServiceRequestMessage";
            this.ConstructAccountingServiceRequestMessage.ExecuteCode += new System.EventHandler(this.ConstructAccountingServiceRequestMessage_ExecuteCode);
            // 
            // DisplayCreditCardServiceReceive
            // 
            this.DisplayCreditCardServiceReceive.Name = "DisplayCreditCardServiceReceive";
            this.DisplayCreditCardServiceReceive.ExecuteCode += new System.EventHandler(this.DisplayCreditCardServiceReceive_ExecuteCode);
            // 
            // ReceiveCreditCardServiceResponseMessage
            // 
            correlationtoken3.Name = "CreditCardServiceDialogHandle";
            correlationtoken3.OwnerActivityName = "ComplexWorkflowTargetService";
            this.ReceiveCreditCardServiceResponseMessage.CorrelationToken = correlationtoken3;
            this.ReceiveCreditCardServiceResponseMessage.EventName = "MessageReceived";
            this.ReceiveCreditCardServiceResponseMessage.InterfaceType = typeof(ServiceBroker.Workflow.Activities.IServiceBrokerMessageExchange);
            this.ReceiveCreditCardServiceResponseMessage.Name = "ReceiveCreditCardServiceResponseMessage";
            activitybind9.Name = "ComplexWorkflowTargetService";
            activitybind9.Path = "CreditCardServiceResponseMessage";
            workflowparameterbinding15.ParameterName = "e";
            workflowparameterbinding15.SetBinding(System.Workflow.ComponentModel.WorkflowParameterBinding.ValueProperty, ((System.Workflow.ComponentModel.ActivityBind)(activitybind9)));
            this.ReceiveCreditCardServiceResponseMessage.ParameterBindings.Add(workflowparameterbinding15);
            // 
            // SendCreditCardServiceRequestMessage
            // 
            correlationtoken4.Name = "CreditCardServiceDialogHandle";
            correlationtoken4.OwnerActivityName = "ComplexWorkflowTargetService";
            this.SendCreditCardServiceRequestMessage.CorrelationToken = correlationtoken4;
            this.SendCreditCardServiceRequestMessage.InterfaceType = typeof(ServiceBroker.Workflow.Activities.IServiceBrokerMessageExchange);
            this.SendCreditCardServiceRequestMessage.MethodName = "SendMessage";
            this.SendCreditCardServiceRequestMessage.Name = "SendCreditCardServiceRequestMessage";
            activitybind10.Name = "ComplexWorkflowTargetService";
            activitybind10.Path = "CreditCardServiceDialogHandle";
            workflowparameterbinding16.ParameterName = "DialogHandle";
            workflowparameterbinding16.SetBinding(System.Workflow.ComponentModel.WorkflowParameterBinding.ValueProperty, ((System.Workflow.ComponentModel.ActivityBind)(activitybind10)));
            workflowparameterbinding17.ParameterName = "MessageType";
            workflowparameterbinding17.Value = "http://ssb.csharp.at/SSB_Book/c10/CreditCardRequestMessage";
            activitybind11.Name = "ComplexWorkflowTargetService";
            activitybind11.Path = "CreditCardServiceRequestMessage";
            workflowparameterbinding18.ParameterName = "Message";
            workflowparameterbinding18.SetBinding(System.Workflow.ComponentModel.WorkflowParameterBinding.ValueProperty, ((System.Workflow.ComponentModel.ActivityBind)(activitybind11)));
            this.SendCreditCardServiceRequestMessage.ParameterBindings.Add(workflowparameterbinding16);
            this.SendCreditCardServiceRequestMessage.ParameterBindings.Add(workflowparameterbinding17);
            this.SendCreditCardServiceRequestMessage.ParameterBindings.Add(workflowparameterbinding18);
            // 
            // BeginDialogCreditCardService
            // 
            this.BeginDialogCreditCardService.InterfaceType = typeof(ServiceBroker.Workflow.Activities.IServiceBrokerMethods);
            this.BeginDialogCreditCardService.MethodName = "BeginDialog";
            this.BeginDialogCreditCardService.Name = "BeginDialogCreditCardService";
            activitybind12.Name = "ComplexWorkflowTargetService";
            activitybind12.Path = "CreditCardServiceDialogHandle";
            workflowparameterbinding19.ParameterName = "DialogHandle";
            workflowparameterbinding19.SetBinding(System.Workflow.ComponentModel.WorkflowParameterBinding.ValueProperty, ((System.Workflow.ComponentModel.ActivityBind)(activitybind12)));
            workflowparameterbinding20.ParameterName = "ToService";
            workflowparameterbinding20.Value = "CreditCardService";
            workflowparameterbinding21.ParameterName = "Contract";
            workflowparameterbinding21.Value = "http://ssb.csharp.at/SSB_Book/c10/CreditCardContract";
            this.BeginDialogCreditCardService.ParameterBindings.Add(workflowparameterbinding19);
            this.BeginDialogCreditCardService.ParameterBindings.Add(workflowparameterbinding20);
            this.BeginDialogCreditCardService.ParameterBindings.Add(workflowparameterbinding21);
            // 
            // ConstructCreditCardRequestMessage
            // 
            this.ConstructCreditCardRequestMessage.Name = "ConstructCreditCardRequestMessage";
            this.ConstructCreditCardRequestMessage.ExecuteCode += new System.EventHandler(this.ConstructCreditCardRequestMessage_ExecuteCode);
            // 
            // InventoryService
            // 
            this.InventoryService.Activities.Add(this.ConstructInventoryServiceRequestMessage);
            this.InventoryService.Activities.Add(this.BeginDialogInventoryService);
            this.InventoryService.Activities.Add(this.SendInventoryServiceRequestMessage);
            this.InventoryService.Activities.Add(this.ReceiveInventoryServiceResponseMessage);
            this.InventoryService.Activities.Add(this.DisplayInventoryServiceReceive);
            this.InventoryService.Name = "InventoryService";
            // 
            // AccountingService
            // 
            this.AccountingService.Activities.Add(this.ConstructAccountingServiceRequestMessage);
            this.AccountingService.Activities.Add(this.BeginDialogAccountingService);
            this.AccountingService.Activities.Add(this.SendAccountingServiceRequestMessage);
            this.AccountingService.Activities.Add(this.ReceiveAccountingServiceResponseMessage);
            this.AccountingService.Activities.Add(this.DisplayAccountingServiceReceive);
            this.AccountingService.Name = "AccountingService";
            // 
            // CreditCardService
            // 
            this.CreditCardService.Activities.Add(this.ConstructCreditCardRequestMessage);
            this.CreditCardService.Activities.Add(this.BeginDialogCreditCardService);
            this.CreditCardService.Activities.Add(this.SendCreditCardServiceRequestMessage);
            this.CreditCardService.Activities.Add(this.ReceiveCreditCardServiceResponseMessage);
            this.CreditCardService.Activities.Add(this.DisplayCreditCardServiceReceive);
            this.CreditCardService.Name = "CreditCardService";
            // 
            // WorkflowFinished
            // 
            this.WorkflowFinished.Name = "WorkflowFinished";
            this.WorkflowFinished.ExecuteCode += new System.EventHandler(this.WorkflowFinished_ExecuteCode);
            // 
            // SendOrderServiceResponseMessage
            // 
            correlationtoken5.Name = "DialogHandle";
            correlationtoken5.OwnerActivityName = "ComplexWorkflowTargetService";
            this.SendOrderServiceResponseMessage.CorrelationToken = correlationtoken5;
            this.SendOrderServiceResponseMessage.InterfaceType = typeof(ServiceBroker.Workflow.Activities.IServiceBrokerMessageExchange);
            this.SendOrderServiceResponseMessage.MethodName = "SendMessage";
            this.SendOrderServiceResponseMessage.Name = "SendOrderServiceResponseMessage";
            activitybind13.Name = "ComplexWorkflowTargetService";
            activitybind13.Path = "DialogHandle";
            workflowparameterbinding22.ParameterName = "DialogHandle";
            workflowparameterbinding22.SetBinding(System.Workflow.ComponentModel.WorkflowParameterBinding.ValueProperty, ((System.Workflow.ComponentModel.ActivityBind)(activitybind13)));
            activitybind14.Name = "ComplexWorkflowTargetService";
            activitybind14.Path = "OrderServiceResponseMessage";
            workflowparameterbinding23.ParameterName = "Message";
            workflowparameterbinding23.SetBinding(System.Workflow.ComponentModel.WorkflowParameterBinding.ValueProperty, ((System.Workflow.ComponentModel.ActivityBind)(activitybind14)));
            workflowparameterbinding24.ParameterName = "MessageType";
            workflowparameterbinding24.Value = "http://ssb.csharp.at/SSB_Book/c10/OrderResponseMessage";
            this.SendOrderServiceResponseMessage.ParameterBindings.Add(workflowparameterbinding22);
            this.SendOrderServiceResponseMessage.ParameterBindings.Add(workflowparameterbinding23);
            this.SendOrderServiceResponseMessage.ParameterBindings.Add(workflowparameterbinding24);
            // 
            // ConstructOrderResponseMessage
            // 
            this.ConstructOrderResponseMessage.Name = "ConstructOrderResponseMessage";
            this.ConstructOrderResponseMessage.ExecuteCode += new System.EventHandler(this.ConstructOrderResponseMessage_ExecuteCode);
            // 
            // ReceiveShippingServiceResponseMessage
            // 
            correlationtoken6.Name = "ShippingServiceDialogHandle";
            correlationtoken6.OwnerActivityName = "ComplexWorkflowTargetService";
            this.ReceiveShippingServiceResponseMessage.CorrelationToken = correlationtoken6;
            this.ReceiveShippingServiceResponseMessage.EventName = "MessageReceived";
            this.ReceiveShippingServiceResponseMessage.InterfaceType = typeof(ServiceBroker.Workflow.Activities.IServiceBrokerMessageExchange);
            this.ReceiveShippingServiceResponseMessage.Name = "ReceiveShippingServiceResponseMessage";
            activitybind15.Name = "ComplexWorkflowTargetService";
            activitybind15.Path = "ShippingServiceResponseMessage";
            workflowparameterbinding25.ParameterName = "e";
            workflowparameterbinding25.SetBinding(System.Workflow.ComponentModel.WorkflowParameterBinding.ValueProperty, ((System.Workflow.ComponentModel.ActivityBind)(activitybind15)));
            this.ReceiveShippingServiceResponseMessage.ParameterBindings.Add(workflowparameterbinding25);
            // 
            // SendShippingServiceRequestMessage
            // 
            this.SendShippingServiceRequestMessage.CorrelationToken = correlationtoken6;
            this.SendShippingServiceRequestMessage.InterfaceType = typeof(ServiceBroker.Workflow.Activities.IServiceBrokerMessageExchange);
            this.SendShippingServiceRequestMessage.MethodName = "SendMessage";
            this.SendShippingServiceRequestMessage.Name = "SendShippingServiceRequestMessage";
            activitybind16.Name = "ComplexWorkflowTargetService";
            activitybind16.Path = "ShippingServiceDialogHandle";
            workflowparameterbinding26.ParameterName = "DialogHandle";
            workflowparameterbinding26.SetBinding(System.Workflow.ComponentModel.WorkflowParameterBinding.ValueProperty, ((System.Workflow.ComponentModel.ActivityBind)(activitybind16)));
            workflowparameterbinding27.ParameterName = "MessageType";
            workflowparameterbinding27.Value = "http://ssb.csharp.at/SSB_Book/c10/ShippingRequestMessage";
            activitybind17.Name = "ComplexWorkflowTargetService";
            activitybind17.Path = "ShippingServiceRequestMessage";
            workflowparameterbinding28.ParameterName = "Message";
            workflowparameterbinding28.SetBinding(System.Workflow.ComponentModel.WorkflowParameterBinding.ValueProperty, ((System.Workflow.ComponentModel.ActivityBind)(activitybind17)));
            this.SendShippingServiceRequestMessage.ParameterBindings.Add(workflowparameterbinding26);
            this.SendShippingServiceRequestMessage.ParameterBindings.Add(workflowparameterbinding27);
            this.SendShippingServiceRequestMessage.ParameterBindings.Add(workflowparameterbinding28);
            // 
            // BeginDialogShippingService
            // 
            this.BeginDialogShippingService.InterfaceType = typeof(ServiceBroker.Workflow.Activities.IServiceBrokerMethods);
            this.BeginDialogShippingService.MethodName = "BeginDialog";
            this.BeginDialogShippingService.Name = "BeginDialogShippingService";
            activitybind18.Name = "ComplexWorkflowTargetService";
            activitybind18.Path = "ShippingServiceDialogHandle";
            workflowparameterbinding29.ParameterName = "DialogHandle";
            workflowparameterbinding29.SetBinding(System.Workflow.ComponentModel.WorkflowParameterBinding.ValueProperty, ((System.Workflow.ComponentModel.ActivityBind)(activitybind18)));
            workflowparameterbinding30.ParameterName = "Contract";
            workflowparameterbinding30.Value = "http://ssb.csharp.at/SSB_Book/c10/ShippingContract";
            workflowparameterbinding31.ParameterName = "ToService";
            workflowparameterbinding31.Value = "ShippingService";
            this.BeginDialogShippingService.ParameterBindings.Add(workflowparameterbinding29);
            this.BeginDialogShippingService.ParameterBindings.Add(workflowparameterbinding30);
            this.BeginDialogShippingService.ParameterBindings.Add(workflowparameterbinding31);
            // 
            // ConstructShippingServiceRequestMessage
            // 
            this.ConstructShippingServiceRequestMessage.Name = "ConstructShippingServiceRequestMessage";
            this.ConstructShippingServiceRequestMessage.ExecuteCode += new System.EventHandler(this.ConstructShippingServiceRequestMessage_ExecuteCode);
            // 
            // SendOutRequestMessages
            // 
            this.SendOutRequestMessages.Activities.Add(this.CreditCardService);
            this.SendOutRequestMessages.Activities.Add(this.AccountingService);
            this.SendOutRequestMessages.Activities.Add(this.InventoryService);
            this.SendOutRequestMessages.Name = "SendOutRequestMessages";
            // 
            // DisplayOrderRequestMessage
            // 
            this.DisplayOrderRequestMessage.Name = "DisplayOrderRequestMessage";
            this.DisplayOrderRequestMessage.ExecuteCode += new System.EventHandler(this.DisplayOrderRequestMessage_ExecuteCode);
            // 
            // ComplexWorkflowTargetService
            // 
            this.Activities.Add(this.DisplayOrderRequestMessage);
            this.Activities.Add(this.SendOutRequestMessages);
            this.Activities.Add(this.ConstructShippingServiceRequestMessage);
            this.Activities.Add(this.BeginDialogShippingService);
            this.Activities.Add(this.SendShippingServiceRequestMessage);
            this.Activities.Add(this.ReceiveShippingServiceResponseMessage);
            this.Activities.Add(this.ConstructOrderResponseMessage);
            this.Activities.Add(this.SendOrderServiceResponseMessage);
            this.Activities.Add(this.WorkflowFinished);
            this.Name = "ComplexWorkflowTargetService";
            this.CanModifyActivities = false;

		}

		#endregion

        private CodeActivity WorkflowFinished;
        private CodeActivity DisplayInventoryServiceReceive;
        private CodeActivity DisplayAccountingServiceReceive;
        private CodeActivity DisplayCreditCardServiceReceive;
        private HandleExternalEventActivity ReceiveShippingServiceResponseMessage;
        private CallExternalMethodActivity SendShippingServiceRequestMessage;
        private CallExternalMethodActivity BeginDialogShippingService;
        private CodeActivity ConstructShippingServiceRequestMessage;
        private CodeActivity DisplayOrderRequestMessage;
        private CodeActivity ConstructOrderResponseMessage;
        private CodeActivity ConstructInventoryServiceRequestMessage;
        private CodeActivity ConstructAccountingServiceRequestMessage;
        private CodeActivity ConstructCreditCardRequestMessage;
        private CallExternalMethodActivity SendOrderServiceResponseMessage;
        private SequenceActivity AccountingService;
        private SequenceActivity CreditCardService;
        private ParallelActivity SendOutRequestMessages;
        private CallExternalMethodActivity BeginDialogInventoryService;
        private CallExternalMethodActivity BeginDialogAccountingService;
        private CallExternalMethodActivity BeginDialogCreditCardService;
        private SequenceActivity InventoryService;
        private CallExternalMethodActivity SendInventoryServiceRequestMessage;
        private CallExternalMethodActivity SendAccountingServiceRequestMessage;
        private CallExternalMethodActivity SendCreditCardServiceRequestMessage;
        private HandleExternalEventActivity ReceiveInventoryServiceResponseMessage;
        private HandleExternalEventActivity ReceiveAccountingServiceResponseMessage;
        private HandleExternalEventActivity ReceiveCreditCardServiceResponseMessage;
























































    }
}
