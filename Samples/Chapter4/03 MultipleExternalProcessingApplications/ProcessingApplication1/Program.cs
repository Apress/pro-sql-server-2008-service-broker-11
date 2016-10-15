using System;
using System.Collections.Generic;
using System.Text;

namespace ProcessingApplication1
{
	class Program
	{
		static void Main(string[] args)
		{
			Broker broker = new Broker();

			while (true)
			{
				string msg;
				string msgType;
				Guid dialogHandle;
				Guid serviceInstance;

				broker.tran = broker.cnn.BeginTransaction();
				broker.Receive("TargetQueue1", out msgType, out msg, out serviceInstance, out dialogHandle);

				if (msg == null)
				{
					broker.tran.Commit();
					break;
				}

				switch (msgType)
				{
					case "http://ssb.csharp.at/SSB_Book/c04/RequestMessage":
						{
							broker.Send(dialogHandle, "<Response>This is the response message from the external activated C# program #1...</Response>");
							break;
						}
					case "http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog":
						{
							broker.EndDialog(dialogHandle);
							break;
						}
					case "http://schemas.microsoft.com/SQL/ServiceBroker/Error":
						{
							broker.EndDialog(dialogHandle);
							break;
						}
				}

				broker.tran.Commit();
			}

			Console.WriteLine("External activated application succeeds successfully and terminates now...");
			System.Threading.Thread.Sleep(5000);
		}
	}
}