using System;
using System.Collections.Generic;
using System.Text;

namespace ProcessingApplication
{
	public class Program
	{
		public static void Main(string[] args)
		{
			Broker broker = new Broker();

			while (true)
			{
				string msg;
				string msgType;
				Guid dialogHandle;
				Guid serviceInstance;

				broker.tran = broker.cnn.BeginTransaction();
				broker.Receive("ExternalActivatorQueue", out msgType, out msg, out serviceInstance, out dialogHandle);

                if (msg != null)
                {
                    Console.WriteLine("External activation occured...");
                    new TargetService().ProcessMessages();
                }

				broker.tran.Commit();
			}

			Console.WriteLine("Done");
			Console.ReadLine();
		}
	}
}