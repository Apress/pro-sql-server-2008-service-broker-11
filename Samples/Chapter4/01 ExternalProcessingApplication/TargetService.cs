using System;
using System.Collections.Generic;
using System.Text;

namespace ProcessingApplication
{
	public class TargetService
	{
		private Broker broker = new Broker();

		public void ProcessMessages()
		{
			while (true)
			{
				string msg;
				string msgType;
				Guid dialogHandle;
				Guid serviceInstance;

				broker.tran = broker.cnn.BeginTransaction();
				broker.Receive("TargetQueue", out msgType, out msg, out serviceInstance, out dialogHandle);

				if (msg == null)
				{
					broker.tran.Commit();
					break;
				}

				switch (msgType)
				{
					case "http://ssb.csharp.at/SSB_Book/c04/RequestMessage":
					{
						broker.Send(dialogHandle, "<Response>This is the response from C#...</Response>");
						break;
					}
					case "http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog":
					{
						broker.EndDialog(dialogHandle);
						break;
					}
					case "http://schemas.microsoft.com/SQL/ServiceBroker/Error":
					{
                        // You don't have to call here broker.tran.Rollback(), because then
                        // the current message would become a poison message after 5 retries.
						broker.EndDialog(dialogHandle);
						break;
					}
				}

				broker.tran.Commit();
			}
		}
	}
}