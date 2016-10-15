using System;
using System.Collections.Generic;
using System.Text;
using Microsoft.SqlServer.Management.Smo;
using Microsoft.SqlServer.Management.Smo.Broker;

namespace SMOApplication
{
    class Program
    {
        static void Main(string[] args)
        {
            Server svr = new Server("localhost");

            Console.WriteLine("Language: " + svr.Information.Language);
            Console.WriteLine("OS version: " + svr.Information.OSVersion);
            Console.WriteLine("Edition: " + svr.Information.Edition);
            Console.WriteLine("Root directory: " + svr.Information.RootDirectory);

            // Create a new database
            Database db = new Database(svr, "Chapter12_SMOSample");
            db.Create();

            // Create the required message types
            MessageType requestMessage = new MessageType(db.ServiceBroker, "RequestMessage");
            MessageType responseMessage = new MessageType(db.ServiceBroker, "ResponseMessage");

            requestMessage.Create();
            responseMessage.Create();

            // Create the service contract
            ServiceContract contract = new ServiceContract(db.ServiceBroker, "SampleContract");
            contract.MessageTypeMappings.Add(new MessageTypeMapping(contract, "RequestMessage", Microsoft.SqlServer.Management.Smo.Broker.MessageSource.Initiator));
            contract.MessageTypeMappings.Add(new MessageTypeMapping(contract, "ResponseMessage", Microsoft.SqlServer.Management.Smo.Broker.MessageSource.Target));
            contract.Create();

            // Create the queue
            ServiceQueue queue = new ServiceQueue(db.ServiceBroker, "SampleQueue");
            queue.Create();

            // Create the Service Broker service
            BrokerService service = new BrokerService(db.ServiceBroker, "SampleService");
            service.QueueName = "SampleQueue";
            service.ServiceContractMappings.Add(new ServiceContractMapping(service, "SampleContract"));
            service.Create();

            // Retrieve Service Broker information through SMO
            foreach (MessageType messageType in db.ServiceBroker.MessageTypes)
            {
                Console.WriteLine(messageType.Name);
            }

            foreach (ServiceContract serviceContract in db.ServiceBroker.ServiceContracts)
            {
                Console.WriteLine(serviceContract.Name);
            }

            foreach (ServiceQueue serviceQueue in db.ServiceBroker.Queues)
            {
                Console.WriteLine(serviceQueue.Name);
                Console.WriteLine("\tActivation enabled:" + serviceQueue.IsActivationEnabled);
                Console.WriteLine("\tMax Queue Readers: " + serviceQueue.MaxReaders);
                Console.WriteLine("\tProcedure name: " + serviceQueue.ProcedureName);
            }

            foreach (BrokerService brokerService in db.ServiceBroker.Services)
            {
                Console.WriteLine(brokerService.Name);
                Console.WriteLine("\tQueue name: " + brokerService.QueueName);
            }

            Console.ReadLine();
        }
    }
}