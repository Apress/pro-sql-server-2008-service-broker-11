using System;
using System.Text;
using System.Threading;
using System.Workflow.Runtime;
using System.Workflow.Activities;
using System.Collections.Generic;
using ServiceBroker.Workflow.Activities;
using ServiceBroker.SampleWorkflows;

namespace InitiatorService
{
    public class Program
    {
        /// <summary>
        /// Main entry point of the WF host process.
        /// </summary>
        /// <param name="args"></param>
        public static void Main(string[] args)
        {
            using (WorkflowRuntime runtime = new WorkflowRuntime())
            {
                ServiceBrokerImpl _broker = new ServiceBrokerImpl();
                AutoResetEvent waitHandle = new AutoResetEvent(false);

                // Handle the various WF Runtime Events
                runtime.WorkflowCompleted += delegate(object sender, WorkflowCompletedEventArgs e)
                {
                    // ssbPresistence.wfStateCleanup(e.WorkflowInstance.InstanceId);
                    waitHandle.Set();
                };

                runtime.WorkflowTerminated += delegate(object sender, WorkflowTerminatedEventArgs e)
                {
                    Console.WriteLine(e.Exception.Message);
                    // ssbPresistence.wfStateCleanup(e.WorkflowInstance.InstanceId);
                    waitHandle.Set();
                };

                runtime.WorkflowSuspended += delegate(object sender, WorkflowSuspendedEventArgs e)
                {
                    waitHandle.Set();
                };

                runtime.WorkflowIdled += delegate(object sender, WorkflowEventArgs e)
                {
                    waitHandle.Set();
                };

                // Setup local Event handlers
                ExternalDataExchangeService exchangeService = new ExternalDataExchangeService();
                runtime.AddService(exchangeService);

                ServiceBrokerLocalService localSvc = new ServiceBrokerLocalService();
                localSvc.Broker = _broker;
                exchangeService.AddService(localSvc);

                try
                {
                    // Begin a new local SQL Server transaction
                    _broker.Transaction = _broker.Connection.BeginTransaction();

                    // Start the workflow and wait until the workflow is idle...
                    WorkflowInstance instance = runtime.CreateWorkflow(typeof(SimpleWorkflowInitiatorService));
                    instance.Start();
                    waitHandle.WaitOne();

                    // Commit the whole SQL Server transaction
                    _broker.Transaction.Commit();
                }
                catch (Exception exception)
                {
                    Console.WriteLine("Failed to create workflow instance " + exception.Message);
                }

                while (true)
                {
                    string messageType;
                    string message;
                    Guid dialogHandle;
                    Guid conversationGroupID;

                    // Begin a new local SQL Server transaction
                    _broker.Transaction = _broker.Connection.BeginTransaction();

                    // Receive a new Service Broker message from the local queue
                    _broker.ReceiveMessage(out messageType, out message, out conversationGroupID, out dialogHandle);

                    if (dialogHandle == Guid.Empty)
                    {
                        Console.WriteLine("No message was received...");
                        _broker.Transaction.Rollback();
                        continue;
                    }
                    else
                    {
                        switch (messageType)
                        {
                            case "http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog":
                                _broker.EndDialog(dialogHandle);
                                _broker.Transaction.Commit();

                                // Press any key to exit the host process at the Initiator's side
                                Console.WriteLine("Press ENTER to exit");
                                Console.ReadLine();
                                return;

                            case "http://schemas.microsoft.com/SQL/ServiceBroker/Error":
                                _broker.EndDialog(dialogHandle);
                                _broker.Transaction.Commit();

                                // Press any key to exit the host process at the Initiator's side
                                Console.WriteLine("Press ENTER to exit");
                                Console.ReadLine();
                                return;
                            default:
                                try
                                {
                                    // Construct the events args for the MessageReceived event
                                    MessageReceivedEventArgs msgReceivedArgs =
                                        new MessageReceivedEventArgs(conversationGroupID, dialogHandle, messageType, message);

                                    // Load the correct workflow to handle the received Service Broker message
                                    runtime.GetWorkflow(conversationGroupID).Resume();

                                    // Call the MessageReceived event inside the current workflow instance
                                    localSvc.OnMessageReceived(msgReceivedArgs);
                                    waitHandle.WaitOne();
                                }
                                catch (Exception exception)
                                {
                                    Console.WriteLine("Failure calling received message event " + exception.Message);
                                }

                                break;
                        }
                    }

                    // Commit the whole SQL Server transaction
                    _broker.Transaction.Commit();
                }
            }
        }
    }
}