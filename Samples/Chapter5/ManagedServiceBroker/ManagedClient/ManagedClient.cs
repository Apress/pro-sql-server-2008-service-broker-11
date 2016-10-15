using System;
using System.IO;
using System.Text;
using System.Data;
using System.Data.SqlClient;
using System.Collections.Generic;
using Microsoft.Samples.SqlServer;

namespace ManagedServiceBroker
{
	public class ManagedClient
	{
		public static void Main(string[] args)
		{
			SqlConnection cnn = null;
            SqlTransaction tran = null;
            TextReader reader = null;

            try
            {
                Console.WriteLine("Connecting to SQL Server instance");

                // Create a connection
				cnn = new SqlConnection(@"Initial Catalog=Chapter5_ManagedServiceBroker; Data Source=localhost\sql2008feb;Integrated Security=SSPI;");
                cnn.Open();
                Console.WriteLine("Connected to SQL Server instance");

                // Begin a transaction
                tran = cnn.BeginTransaction();
                Console.WriteLine("\nTransaction 1 begins");

                // Create a service object
				Service initiatorService = new Service("InitiatorService", cnn, tran);

                // Set the FetchSize to 1 since we will receive one message at a time
                // i.e. use RECEIVE TOP(1)
                initiatorService.FetchSize = 1;

                // Begin a dialog with the service TargetService
                Conversation dialog = initiatorService.BeginDialog(
					"TargetService",
					null,
					"http://ssb.csharp.at/SSB_Book/c05/HelloWorldContract",
                    TimeSpan.FromMinutes(1),
                    false,
					cnn,
					tran);
				Console.WriteLine("Dialog begun from service (InitiatorService) to service (TargetService)");

                // Create an empty request message
				MemoryStream bodyStream = new MemoryStream(Encoding.ASCII.GetBytes("<HelloWorldRequest>Hello World from C#!</HelloWorldRequest>"));
				Message request = new Message("http://ssb.csharp.at/SSB_Book/c05/RequestMessage", bodyStream);

                // Send the message to the service
                dialog.Send(request, cnn, tran);
                Console.WriteLine("Message sent of type '" + request.Type + "'");

                tran.Commit(); // Message isn't sent until transaction has been committed
                Console.WriteLine("Transaction 1 committed");

                // Begin transaction
                tran = cnn.BeginTransaction();
                Console.WriteLine("\nTransaction 2 begins");

                // Waitfor messages on this conversation
                Console.WriteLine("Waiting for Response....");

                initiatorService.WaitforTimeout = TimeSpan.FromSeconds(5);

                if (initiatorService.GetConversation(dialog, cnn, tran) == null)
                {
                    Console.WriteLine("No message received - Ending dialog with Error");
                    dialog.EndWithError(1, "no response within 5 seconds.", cnn, tran);
                    tran.Commit();
                    Console.WriteLine("Transaction 2 committed");

                    cnn.Close();
                    Console.WriteLine("\nConnection closed - exiting");

                    return;
                }

                // Fetch the message from the conversation
                Message response = dialog.Receive();

                // Output the message to the Console
                if (response.Body != null)
                {
                    Console.Write("Message contains: ");
                    reader = new StreamReader(response.Body);
                    Console.WriteLine(reader.ReadToEnd());
                }

                // End the conversation
                dialog.End(cnn, tran);
                Console.WriteLine("Ended Dialog");

                tran.Commit();
                Console.WriteLine("Transaction 2 committed");

                // Close the database connection
                cnn.Close();
                Console.WriteLine("\nConnection closed - exiting");
            }
            catch (ServiceException e)
            {
                Console.WriteLine("An exception occurred - {0}\n", e.ToString());

                if (tran != null)
                {
                    tran.Rollback();
                    Console.WriteLine("\nTransaction rolled back");
                }
            }
            finally
            {
                if (reader != null)
                    reader.Close();

				if (cnn != null)
                    cnn.Close();

                Console.WriteLine();
                Console.WriteLine("Press Enter to Exit");
                Console.ReadLine();
            }

			Console.WriteLine("Done");
			Console.ReadLine();
		}
	}
}