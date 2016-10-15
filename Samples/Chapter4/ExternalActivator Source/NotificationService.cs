#region Using directives

using Microsoft.Samples.SqlServer;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.Sql;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using System.Diagnostics;
using System.Text;
using System.Threading;
using System.Xml;

#endregion

namespace ExternalActivator
{
	class NotificationService : Service
    {
        #region Public methods
        public NotificationService(
            string notificationService,
            SqlConnection connection,
            ConfigurationManager configMgr)
            : base(notificationService, connection)
        {
            m_configMgr = configMgr;
        }

		[BrokerMethod(Message.EventNotificationType)]
		public void ReceiveNotification(Message message, SqlConnection connection, SqlTransaction tran)
		{
            Global.WriteDebugInfo("Processing received message...");
            string sqlServer = null;
			string database = null;
            string schema = null;
			string queue = null;

            if (ParseEventNotificationMessage(message, out sqlServer, out database, out schema, out queue) == false)
			{
				// ignore Event Notification message
                Global.WriteDebugInfo("Received message has bad message body and cannot be processed.");
                return;
			}

			//NOTE:
			// here constraining that USER SQL == NOTIFICATION SQL because of limitation with SQL Eventing mechanism

            Global.WriteDebugInfo("Trying to start application associated with [" + sqlServer + "].[" + database + "].[" + schema + "].[" + queue + "] because a notification message was received.");
			if (m_configMgr.ProcessNotification(sqlServer, database, schema, queue) == false)
			{
				// do nothing about it (because there is no longer a configuration record for it)
				Global.WriteDebugInfo("Ignoring notification message because there is no application associated with it.");
			}
            Global.WriteDebugInfo("Received message is processed.");
        }

		[BrokerMethod(Message.EndDialogType)]
		[BrokerMethod(Message.ErrorType)]
        public void EndConversation(Message message, SqlConnection connection, SqlTransaction tran)
		{
            Global.WriteDebugInfo("Received end dialog or error message.");
			message.Conversation.End(connection, tran);
		}

        /// <summary>
        /// Extracts the database and queue from the recieved  notification message
        /// </summary>
        /// <param name="message"></param>
        /// <param name="Database"></param>
        /// <param name="Queue"></param>
        /// <returns>True if the message was successfully parsed</returns>
        private bool ParseEventNotificationMessage(
		    Message message,  // I			the Notification message to be parsed
            out string sqlServer, // O
			out string database, // O	the Database for which the Notification message was meant
            out string schema,
			out string queue) // O		the Queue for which the Notification message was meant
		{
            sqlServer = null;
			database = null;
            schema = null;
            queue = null;

			// Load XML msg into doc
			XmlDocument doc = new XmlDocument();
			try
			{
				doc.Load(message.Body);
            }
			catch (XmlException e)
			{
				Global.WriteWarning("Incorrect XML or could not parse event notification message.\n" +
					"Exception Details: " + e.Message);
				return false;
			}

			// Locate elements in DOM

            XmlNodeList list = doc.GetElementsByTagName(EN_XML_SERVER);
            if (list.Count >= 1)
                sqlServer = list.Item(0).InnerXml;

            list = doc.GetElementsByTagName(EN_XML_DATABASE);
			if (list.Count >= 1)
				database = list.Item(0).InnerXml;

            list = doc.GetElementsByTagName(EN_XML_SCHEMA);
            if (list.Count >= 1)
                schema = list.Item(0).InnerXml;

			list = doc.GetElementsByTagName(EN_XML_QUEUE);
			if (list.Count >= 1)
				queue = list.Item(0).InnerXml;

			if (sqlServer == null || database == null || schema == null && queue == null)
			{
                //  undone: convert the message to string
				Global.WriteWarning("Server, Database, Schema and/or Queue tags not found in the message.");
				return false;
			}

            return true;
		}

        /// <summary>
        /// Connects to the sql server and database and run the service
        /// </summary>
        public static void Start(
            ConfigurationManager configMgr)
        {
            Global.WriteDebugInfo("Starting up the Notification service...");

            configMgr.GetNotificationService(
                    ref ms_notificationSQLServer,
                    ref ms_notificationDatabase,
                    ref ms_notificationService);
            ms_connected = false;
            ms_connecting = false;
            ms_error = null;

            NotificationService ns = null;
            SqlConnection connection = null;
            int waiting_time = 1000;
            int retry = 0;

            while (true)
            {
                bool fFailedToConnect = false;

                //  define a connection if needed
                if (connection == null)
                {
                    connection = new SqlConnection(
                        String.Format("server={0};Integrated security=true;database={1};Connect Timeout=10;Application Name=External activator",
                            ms_notificationSQLServer,
                            ms_notificationDatabase));
                    ns = null;
                }

                // if connection is up, do not establish again. Else, establish a connection
                // Always started the first time
                if (connection.State != ConnectionState.Open)
                {
                    try
                    {
                        ms_connecting = true;
                        connection.Open();
                    }
                    catch (SqlException e)
                    {
                        if (ms_error != e.Message)
                        {
                            ms_error = e.Message;
                            Global.WriteWarning(
                                "Failed to connect to Notification SQL Server '" + ms_notificationSQLServer + "' and Database: '" + ms_notificationDatabase +
                                "' because: " + e.Message);
                        }
                        else
                        {
                            Global.WriteDebugInfo(
                                "Failed to connect to Notification SQL Server '" + ms_notificationSQLServer + "' and Database: '" + ms_notificationDatabase +
                                "' because: " + e.Message);
                        }
                        connection.Dispose();
                        connection = null;
                        fFailedToConnect = true;
                    }
                    ms_connecting = false;

                    if (fFailedToConnect)
                    {
                        // Implement an exponential back-off rate of connecting (else this might
                        // overflow the EventLog and other logs
                        waiting_time *= 2;
                        if (waiting_time > Global.MAX_WAITING_TIME)
                        {
                            waiting_time = Global.MAX_WAITING_TIME;
                        }
                        Thread.Sleep(waiting_time);

                        continue;
                    }

                    Global.WriteInfo("Connection to notification SQL server '" + ms_notificationSQLServer + "' and database '" + ms_notificationDatabase + "' is established.");
                    waiting_time = 1000;
                    ms_error = null;
                    ms_connected = true;
                }

                //  create a notification service is one does not exist
                if (ns == null)
                {
                    try
                    {
                        ns = new NotificationService(
                            ms_notificationService,
                            connection,
                            configMgr);
                    }
                    catch (ArgumentException e)
                    {
                        //  if bad parameters were provided then
                        //  report the problem and retry later
                        if (ms_error != e.Message)
                        {
                            Global.WriteWarning(e.Message);
                            ms_error = e.Message;
                        }
                        else
                        {
                            Global.WriteDebugInfo(e.Message);
                        }

                        fFailedToConnect = true;
                    }

                    if (fFailedToConnect)
                    {
                        waiting_time *= 2;
                        if (waiting_time > Global.MAX_WAITING_TIME)
                        {
                            waiting_time = Global.MAX_WAITING_TIME;
                        }
                        Thread.Sleep(waiting_time);
                        continue;
                    }
                    waiting_time = 1000;
                }

                //  now receive all the messages for this service and
                //  end the application
                ns.WaitforTimeout = TimeSpan.FromSeconds(-1);
                ns.FetchSize = 1;
                bool fRestart = false;
                Global.WriteInfo("Notification service '" + ms_notificationService + "' is started.");
                try
                {
                    ns.Run(true, connection, null);
                }
                catch (ServiceException e)
                {
                    Global.WriteWarning("Service exception occured while running. External activator will try to reconnect.");
                    if (retry == 3)
                    {
                        Global.DoHardKill(e);
                    }

                    EAException.Report(e);
                    fRestart = true;
                }
                catch (SqlException e)
                {
                    Global.WriteWarning("Service exception occured while running. External activator will try to reconnect.");
                    if (retry == 3)
                    {
                        Global.DoHardKill(e);
                    }

                    EAException.Report(e);
                    fRestart = true;
                }
                catch (Exception e)
                {
                    Global.DoHardKill (e);
                }

                if (fRestart)
                {
                    retry++;
                    //  reset the state and retry again
                    ms_connected = false;
                    ms_connecting = false;
                    ms_error = null;
                    waiting_time = 1000;
                    ns = null;
                    connection.Close();
                    connection = null;
                    continue;
                }

                connection.Close();
                return;
            }
        }

        /// <summary>
        /// Reports the state of the notification service connection
        /// </summary>
        public static string Report()
        {
            string me = "";
            if (ms_connected)
            {
                me = "connected to the database";

                if (ms_error != null)
                {
                    me += ", but " + ms_error;
                }
                else
                {
                    me += " and working.";
                }
            }
            else if (ms_connecting)
            {
                me = "connecting...";
            }
            else
            {
                me = "not connected";
                string error = ms_error;
                if (error != null)
                {
                    me += ", because: '" + error + "'";
                }
                else
                {
                    me += ".";
                }
            }

            return "Notification service '" + ms_notificationService + "' on SQL Server '" + 
                ms_notificationSQLServer + "' and Database '" + ms_notificationDatabase + "' is " + me;
        }
        #endregion

        #region Members
        private ConfigurationManager m_configMgr;

        private static bool ms_connecting = false;
        private static bool ms_connected = false;
        private static string ms_error = null;

        private static string ms_notificationSQLServer = "";
        private static string ms_notificationDatabase = "";
        private static string ms_notificationService = "";
        #endregion

        #region Constants
        private static readonly string EN_XML_SERVER = "ServerName";
        private static readonly string EN_XML_DATABASE = "DatabaseName";
        private static readonly string EN_XML_SCHEMA = "SchemaName";
        private static readonly string EN_XML_QUEUE = "ObjectName";
        #endregion
    }
}
