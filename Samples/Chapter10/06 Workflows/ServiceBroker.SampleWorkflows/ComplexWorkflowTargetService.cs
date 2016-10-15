using System;
using System.Xml;
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
	public sealed partial class ComplexWorkflowTargetService : SequentialWorkflowActivity
	{
        private string _messageType;
        private string _message;
        private XmlDocument OrderRequestMessage;

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

        #region DependencyProperties

        public static DependencyProperty DialogHandleProperty = DependencyProperty.Register("DialogHandle", typeof(System.Guid), typeof(ComplexWorkflowTargetService));
        public static DependencyProperty CreditCardServiceResponseMessageProperty = DependencyProperty.Register("CreditCardServiceResponseMessage", typeof(ServiceBroker.Workflow.Activities.MessageReceivedEventArgs), typeof(ServiceBroker.SampleWorkflows.ComplexWorkflowTargetService));
        public static DependencyProperty AccountingServiceResponseMessageProperty = DependencyProperty.Register("AccountingServiceResponseMessage", typeof(ServiceBroker.Workflow.Activities.MessageReceivedEventArgs), typeof(ServiceBroker.SampleWorkflows.ComplexWorkflowTargetService));
        public static DependencyProperty InventoryServiceResponseMessageProperty = DependencyProperty.Register("InventoryServiceResponseMessage", typeof(ServiceBroker.Workflow.Activities.MessageReceivedEventArgs), typeof(ServiceBroker.SampleWorkflows.ComplexWorkflowTargetService));
        public static DependencyProperty CreditCardServiceRequestMessageProperty = DependencyProperty.Register("CreditCardServiceRequestMessage", typeof(System.String), typeof(ServiceBroker.SampleWorkflows.ComplexWorkflowTargetService));
        public static DependencyProperty AccountingServiceRequestMessageProperty = DependencyProperty.Register("AccountingServiceRequestMessage", typeof(System.String), typeof(ServiceBroker.SampleWorkflows.ComplexWorkflowTargetService));
        public static DependencyProperty InventoryServiceRequestMessageProperty = DependencyProperty.Register("InventoryServiceRequestMessage", typeof(System.String), typeof(ServiceBroker.SampleWorkflows.ComplexWorkflowTargetService));
        public static DependencyProperty OrderServiceResponseMessageProperty = DependencyProperty.Register("OrderServiceResponseMessage", typeof(System.String), typeof(ServiceBroker.SampleWorkflows.ComplexWorkflowTargetService));
        public static DependencyProperty CreditCardServiceDialogHandleProperty = DependencyProperty.Register("CreditCardServiceDialogHandle", typeof(System.Guid), typeof(ServiceBroker.SampleWorkflows.ComplexWorkflowTargetService));
        public static DependencyProperty AccountingServiceDialogHandleProperty = DependencyProperty.Register("AccountingServiceDialogHandle", typeof(System.Guid), typeof(ServiceBroker.SampleWorkflows.ComplexWorkflowTargetService));
        public static DependencyProperty InventoryServiceDialogHandleProperty = DependencyProperty.Register("InventoryServiceDialogHandle", typeof(System.Guid), typeof(ServiceBroker.SampleWorkflows.ComplexWorkflowTargetService));
        public static DependencyProperty ShippingServiceDialogHandleProperty = DependencyProperty.Register("ShippingServiceDialogHandle", typeof(System.Guid), typeof(ServiceBroker.SampleWorkflows.ComplexWorkflowTargetService));
        public static DependencyProperty ShippingServiceRequestMessageProperty = DependencyProperty.Register("ShippingServiceRequestMessage", typeof(System.String), typeof(ServiceBroker.SampleWorkflows.ComplexWorkflowTargetService));
        public static DependencyProperty ShippingServiceResponseMessageProperty = DependencyProperty.Register("ShippingServiceResponseMessage", typeof(ServiceBroker.Workflow.Activities.MessageReceivedEventArgs), typeof(ServiceBroker.SampleWorkflows.ComplexWorkflowTargetService));

        /// <summary>
        /// Represents the dialog handle of the current Service Broker conversation.
        /// </summary>
        [DesignerSerializationVisibilityAttribute(DesignerSerializationVisibility.Visible)]
        [BrowsableAttribute(true)]
        public Guid DialogHandle
        {
            get
            {
                return ((System.Guid)(base.GetValue(ComplexWorkflowTargetService.DialogHandleProperty)));
            }
            set
            {
                base.SetValue(ComplexWorkflowTargetService.DialogHandleProperty, value);
            }
        }

		public ComplexWorkflowTargetService()
		{
			InitializeComponent();
		}

        [DesignerSerializationVisibilityAttribute(DesignerSerializationVisibility.Visible)]
        [BrowsableAttribute(true)]
        [CategoryAttribute("Parameters")]
        public ServiceBroker.Workflow.Activities.MessageReceivedEventArgs CreditCardServiceResponseMessage
        {
            get
            {
                return ((ServiceBroker.Workflow.Activities.MessageReceivedEventArgs)(base.GetValue(ServiceBroker.SampleWorkflows.ComplexWorkflowTargetService.CreditCardServiceResponseMessageProperty)));
            }
            set
            {
                base.SetValue(ServiceBroker.SampleWorkflows.ComplexWorkflowTargetService.CreditCardServiceResponseMessageProperty, value);
            }
        }

        [DesignerSerializationVisibilityAttribute(DesignerSerializationVisibility.Visible)]
        [BrowsableAttribute(true)]
        [CategoryAttribute("Parameters")]
        public ServiceBroker.Workflow.Activities.MessageReceivedEventArgs AccountingServiceResponseMessage
        {
            get
            {
                return ((ServiceBroker.Workflow.Activities.MessageReceivedEventArgs)(base.GetValue(ServiceBroker.SampleWorkflows.ComplexWorkflowTargetService.AccountingServiceResponseMessageProperty)));
            }
            set
            {
                base.SetValue(ServiceBroker.SampleWorkflows.ComplexWorkflowTargetService.AccountingServiceResponseMessageProperty, value);
            }
        }

        [DesignerSerializationVisibilityAttribute(DesignerSerializationVisibility.Visible)]
        [BrowsableAttribute(true)]
        [CategoryAttribute("Parameters")]
        public ServiceBroker.Workflow.Activities.MessageReceivedEventArgs InventoryServiceResponseMessage
        {
            get
            {
                return ((ServiceBroker.Workflow.Activities.MessageReceivedEventArgs)(base.GetValue(ServiceBroker.SampleWorkflows.ComplexWorkflowTargetService.InventoryServiceResponseMessageProperty)));
            }
            set
            {
                base.SetValue(ServiceBroker.SampleWorkflows.ComplexWorkflowTargetService.InventoryServiceResponseMessageProperty, value);
            }
        }

        [DesignerSerializationVisibilityAttribute(DesignerSerializationVisibility.Visible)]
        [BrowsableAttribute(true)]
        [CategoryAttribute("Parameters")]
        public String CreditCardServiceRequestMessage
        {
            get
            {
                return ((string)(base.GetValue(ServiceBroker.SampleWorkflows.ComplexWorkflowTargetService.CreditCardServiceRequestMessageProperty)));
            }
            set
            {
                base.SetValue(ServiceBroker.SampleWorkflows.ComplexWorkflowTargetService.CreditCardServiceRequestMessageProperty, value);
            }
        }

        [DesignerSerializationVisibilityAttribute(DesignerSerializationVisibility.Visible)]
        [BrowsableAttribute(true)]
        [CategoryAttribute("Parameters")]
        public String AccountingServiceRequestMessage
        {
            get
            {
                return ((string)(base.GetValue(ServiceBroker.SampleWorkflows.ComplexWorkflowTargetService.AccountingServiceRequestMessageProperty)));
            }
            set
            {
                base.SetValue(ServiceBroker.SampleWorkflows.ComplexWorkflowTargetService.AccountingServiceRequestMessageProperty, value);
            }
        }

        [DesignerSerializationVisibilityAttribute(DesignerSerializationVisibility.Visible)]
        [BrowsableAttribute(true)]
        [CategoryAttribute("Parameters")]
        public String InventoryServiceRequestMessage
        {
            get
            {
                return ((string)(base.GetValue(ServiceBroker.SampleWorkflows.ComplexWorkflowTargetService.InventoryServiceRequestMessageProperty)));
            }
            set
            {
                base.SetValue(ServiceBroker.SampleWorkflows.ComplexWorkflowTargetService.InventoryServiceRequestMessageProperty, value);
            }
        }

        [DesignerSerializationVisibilityAttribute(DesignerSerializationVisibility.Visible)]
        [BrowsableAttribute(true)]
        [CategoryAttribute("Parameters")]
        public String OrderServiceResponseMessage
        {
            get
            {
                return ((string)(base.GetValue(ServiceBroker.SampleWorkflows.ComplexWorkflowTargetService.OrderServiceResponseMessageProperty)));
            }
            set
            {
                base.SetValue(ServiceBroker.SampleWorkflows.ComplexWorkflowTargetService.OrderServiceResponseMessageProperty, value);
            }
        }

        [DesignerSerializationVisibilityAttribute(DesignerSerializationVisibility.Visible)]
        [BrowsableAttribute(true)]
        [CategoryAttribute("Parameters")]
        public Guid CreditCardServiceDialogHandle
        {
            get
            {
                return ((System.Guid)(base.GetValue(ServiceBroker.SampleWorkflows.ComplexWorkflowTargetService.CreditCardServiceDialogHandleProperty)));
            }
            set
            {
                base.SetValue(ServiceBroker.SampleWorkflows.ComplexWorkflowTargetService.CreditCardServiceDialogHandleProperty, value);
            }
        }

        [DesignerSerializationVisibilityAttribute(DesignerSerializationVisibility.Visible)]
        [BrowsableAttribute(true)]
        [CategoryAttribute("Parameters")]
        public Guid AccountingServiceDialogHandle
        {
            get
            {
                return ((System.Guid)(base.GetValue(ServiceBroker.SampleWorkflows.ComplexWorkflowTargetService.AccountingServiceDialogHandleProperty)));
            }
            set
            {
                base.SetValue(ServiceBroker.SampleWorkflows.ComplexWorkflowTargetService.AccountingServiceDialogHandleProperty, value);
            }
        }

        [DesignerSerializationVisibilityAttribute(DesignerSerializationVisibility.Visible)]
        [BrowsableAttribute(true)]
        [CategoryAttribute("Parameters")]
        public Guid InventoryServiceDialogHandle
        {
            get
            {
                return ((System.Guid)(base.GetValue(ServiceBroker.SampleWorkflows.ComplexWorkflowTargetService.InventoryServiceDialogHandleProperty)));
            }
            set
            {
                base.SetValue(ServiceBroker.SampleWorkflows.ComplexWorkflowTargetService.InventoryServiceDialogHandleProperty, value);
            }
        }

        [DesignerSerializationVisibilityAttribute(DesignerSerializationVisibility.Visible)]
        [BrowsableAttribute(true)]
        [CategoryAttribute("Parameters")]
        public Guid ShippingServiceDialogHandle
        {
            get
            {
                return ((System.Guid)(base.GetValue(ServiceBroker.SampleWorkflows.ComplexWorkflowTargetService.ShippingServiceDialogHandleProperty)));
            }
            set
            {
                base.SetValue(ServiceBroker.SampleWorkflows.ComplexWorkflowTargetService.ShippingServiceDialogHandleProperty, value);
            }
        }

        [DesignerSerializationVisibilityAttribute(DesignerSerializationVisibility.Visible)]
        [BrowsableAttribute(true)]
        [CategoryAttribute("Parameters")]
        public String ShippingServiceRequestMessage
        {
            get
            {
                return ((string)(base.GetValue(ServiceBroker.SampleWorkflows.ComplexWorkflowTargetService.ShippingServiceRequestMessageProperty)));
            }
            set
            {
                base.SetValue(ServiceBroker.SampleWorkflows.ComplexWorkflowTargetService.ShippingServiceRequestMessageProperty, value);
            }
        }

        [DesignerSerializationVisibilityAttribute(DesignerSerializationVisibility.Visible)]
        [BrowsableAttribute(true)]
        [CategoryAttribute("Parameters")]
        public ServiceBroker.Workflow.Activities.MessageReceivedEventArgs ShippingServiceResponseMessage
        {
            get
            {
                return ((ServiceBroker.Workflow.Activities.MessageReceivedEventArgs)(base.GetValue(ServiceBroker.SampleWorkflows.ComplexWorkflowTargetService.ShippingServiceResponseMessageProperty)));
            }
            set
            {
                base.SetValue(ServiceBroker.SampleWorkflows.ComplexWorkflowTargetService.ShippingServiceResponseMessageProperty, value);
            }
        }

        #endregion

        /// <summary>
        /// This method gets called as soon as a OrderRequestMessage is received.
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void DisplayOrderRequestMessage_ExecuteCode(object sender, EventArgs e)
        {
            Console.WriteLine(Message);

            // Create an instance of an XmlDocument with the received OrderRequestMessage
            OrderRequestMessage = new XmlDocument();
            OrderRequestMessage.LoadXml(Message);
        }

        /// <summary>
        /// Constructs the request message sent to the CreditCardService.
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void ConstructCreditCardRequestMessage_ExecuteCode(object sender, EventArgs e)
        {
            string holder = OrderRequestMessage.GetElementsByTagName("Holder")[0].InnerText;
            string number = OrderRequestMessage.GetElementsByTagName("Number")[0].InnerText;
            string validThrough = OrderRequestMessage.GetElementsByTagName("ValidThrough")[0].InnerText;
            string price = OrderRequestMessage.GetElementsByTagName("Price")[0].InnerText;

            CreditCardServiceRequestMessage = string.Format(
                "<CreditCardRequest>" +
                    "<Holder>{0}</Holder>" +
                    "<Number>{1}</Number>" +
                    "<ValidThrough>{2}</ValidThrough>" +
                    "<Amount>{3}</Amount>" +
                "</CreditCardRequest>", holder, number, validThrough, price);

            Console.WriteLine("Starting dialog with the CreditCardService...");
        }

        /// <summary>
        /// Constructs the request message sent to the AccountingService.
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void ConstructAccountingServiceRequestMessage_ExecuteCode(object sender, EventArgs e)
        {
            string customerID = OrderRequestMessage.GetElementsByTagName("CustomerID")[0].InnerText;
            string amount = (double.Parse(OrderRequestMessage.GetElementsByTagName("Quantity")[0].InnerText) * double.Parse(OrderRequestMessage.GetElementsByTagName("Price")[0].InnerText)).ToString();

            AccountingServiceRequestMessage = string.Format(
                "<AccountingRequest>" +
                    "<CustomerID>{0}</CustomerID>" +
                    "<Amount>{1}</Amount>" +
                "</AccountingRequest>", customerID, amount);

            Console.WriteLine("Starting dialog with the AccountingService...");
        }

        /// <summary>
        /// Constructs the request message sent to the InventoryService.
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void ConstructInventoryServiceRequestMessage_ExecuteCode(object sender, EventArgs e)
        {
            string productID = OrderRequestMessage.GetElementsByTagName("ProductID")[0].InnerText;
            string quantity = OrderRequestMessage.GetElementsByTagName("Quantity")[0].InnerText;

            InventoryServiceRequestMessage = string.Format(
                "<InventoryRequest>" +
                    "<ProductID>{0}</ProductID>" +
                    "<Quantity>{1}</Quantity>" +
                "</InventoryRequest>", productID, quantity);

            Console.WriteLine("Starting dialog with the InventoryService...");
        }

        /// <summary>
        /// Constructs the request message sent to the ShippingService.
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void ConstructShippingServiceRequestMessage_ExecuteCode(object sender, EventArgs e)
        {
            string name = OrderRequestMessage.GetElementsByTagName("Name")[0].InnerText;
            string address = OrderRequestMessage.GetElementsByTagName("Address")[0].InnerText;
            string zipCode = OrderRequestMessage.GetElementsByTagName("ZipCode")[0].InnerText;
            string city = OrderRequestMessage.GetElementsByTagName("City")[0].InnerText;
            string country = OrderRequestMessage.GetElementsByTagName("Country")[0].InnerText;

            ShippingServiceRequestMessage = string.Format(
                "<Shipping>" +
                    "<Name>{0}</Name>" +
                    "<Address>{1}</Address>" +
                    "<ZipCode>{2}</ZipCode>" +
                    "<City>{3}</City>" +
                    "<Country>{4}</Country>" +
                "</Shipping>", name, address, zipCode, city, country);

            Console.WriteLine("Starting dialog with the ShippingService...");
        }

        /// <summary>
        /// Constructs the response message sent back to the InitiatorService.
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void ConstructOrderResponseMessage_ExecuteCode(object sender, EventArgs e)
        {
            Console.WriteLine("ShippingServiceResponseMessage received...");

            OrderServiceResponseMessage = "<OrderResponse>1</OrderResponse>";
        }

        /// <summary>
        /// This method gets called as soon as a CreditCardResponseMessage is received.
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void DisplayCreditCardServiceReceive_ExecuteCode(object sender, EventArgs e)
        {
            Console.WriteLine("CreditCardResponseMessage received...");
        }

        /// <summary>
        /// This method gets called as soon as a AccountingServiceResponseMessage is received.
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void DisplayAccountingServiceReceive_ExecuteCode(object sender, EventArgs e)
        {
            Console.WriteLine("AccountingServiceResponseMessage received...");
        }

        /// <summary>
        /// This method gets called as soon as a InventoryServiceResponseMessage is received.
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void DisplayInventoryServiceReceive_ExecuteCode(object sender, EventArgs e)
        {
            Console.WriteLine("InventoryResponseMessage received...");
        }

        /// <summary>
        /// This method gets called as soon as the workflow is finished.
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void WorkflowFinished_ExecuteCode(object sender, EventArgs e)
        {
            Console.WriteLine("The workflow is now finished...");
        }
	}
}