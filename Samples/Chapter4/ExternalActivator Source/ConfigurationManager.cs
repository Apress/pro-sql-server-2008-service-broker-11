#region Using
using System;
using System.Collections;
using System.Diagnostics;
using System.IO;
using System.Xml;
using System.Xml.Serialization;
#endregion

namespace ExternalActivator
{
    /// <summary>
    ///		This class is used for XML Deserialization. It stores the activator setup and
    ///     list of Configuration Records that need to be inserted into the Configuration Record Table
    /// </summary>
    public class Activator
    {
        [XmlElement("Setup")]
        public Setup m_setup;
        [XmlElement("ConfigurationRecord")]
        public ConfigurationRecord[] m_configurationRecordList; // List of Configuration Records
    }

    /// <summary>
    ///		The setup contains information about the Notification SQL Server, Database and Queue
    ///		to listen to for Event Notifications. It also contains other per-activator information.
    ///		Also used for XML Deserialization
    /// </summary>
    public class Setup
    {
        public Setup()
        {
            m_enableDebugTrace = false;
        }

        // notification processing
        [XmlElement("NotificationSQLServer")]
        public string m_notificationSQLServer; // Name of Notification SQL Server, DB, Queue
        [XmlElement("NotificationDatabase")]
        public string m_notificationDatabase;
        [XmlElement("NotificationService")]
        public string m_notificationService;
        
        [XmlElement("EnableDebugTrace")]
        public bool m_enableDebugTrace;
    }

    /// <summary>
    ///	ConfigurationManager contains code required for startup. It
    ///	is responsible for initialization of the External Activator and performs 
    ///	initialization depending on whether it is a service or not. It is also responsible
    ///	for performing a clean shutdown of the External Activator. It uses the ExternalStorageReader
    ///	to read configuration, listen to configuration file changes and read the log and recover.
    /// </summary>
	class ConfigurationManager
    {
        #region Public methods
        /// <summary>
        /// The callback function that gets called when the configuration file changes.
        /// 
        /// NOTE:
        ///		OnChanged gets fired multiple times if changes are made using notepad..
        ///		this is annoying in terms of performance but otherwise doesn't affect the correctness of
        ///		the program.
        /// </summary>
        /// <param name="a"></param>
        /// <param name="file"></param>
		public void ConfigurationFileChangedCallBack
				(object a,
				FileSystemEventArgs file) 
		{
            try
            {
                //Read the configuration information using External Storage Reader
                //Read the entire XML file and get our part from the file
                Global.WriteInfo("Configuration file changed externally...");

                ReloadActivatorConfiguration();
            }
            catch (Exception e)
            {
                EAException ea = e as EAException;

                // if the exception was warning then just report it and ignore the update
                if (ea != null && (int)ea.Error < 0)
                {
                    EAException.Report(e);
                    Global.WriteWarning(
                        "Configuration file update was ignored because of bad data in it.");
                }
                else
                {
                    Global.DoHardKill(e);
                }
            }
		}

        /// <summary>
        /// Reads the configuration file and updates the current configuration
        /// of the external activator
        /// </summary>
		public void ReloadActivatorConfiguration()
		{
			lock (this)
			{
				// this is grabbed for the period of time when the 
				// Global configuration record table is being changed, so if configuration
				// is being changed, the shutdown mechanism has to wait till
				// it grabs the lock
                Activator newActivator = null;
                Hashtable newConfigurationHash = null;

                try
                {
                    newActivator = LoadActivatorConfiguration();
                    newConfigurationHash = InsertArray(newActivator.m_configurationRecordList);
                }
                catch (Exception e)
                {
                    throw new EAException("Failed to read the configuration file", Error.cannotReadConfigFile, e);
                }

                m_instance = newActivator.m_setup;

                Update(newConfigurationHash);

                Global.AppMonitorMgr.StartUpAllBelowMinimum();
            }
		}

        /// <summary>
        ///		Reads the configuration file and uses it to populate the Global Configuration
        ///		Record Table.
        ///		NOTE: Does not activate processes at the end like ConfigurationFileChangedCallBack does
        /// </summary>
		public void Initialize()
		{
			//Read the configuration information using External Storage Reader
			//Read the entire XML file and get our part from the file
            m_configFile = Global.ApplicationName + ".xml";

            Global.WriteStatus("Initializing configuration manager...");

            m_configRT = new Hashtable();

			Activator myActivator;
			myActivator = LoadActivatorConfiguration();
            m_instance = myActivator.m_setup;
            Global.SetDebug(m_instance.m_enableDebugTrace);

            FileInfo fi = new FileInfo(m_configFile);

            // Register the FileWatcher listener now
            FileSystemWatcher fsw = new FileSystemWatcher();
            fsw.Path = fi.DirectoryName;
            fsw.Filter = fi.Name;
            fsw.NotifyFilter = NotifyFilters.LastWrite;
            fsw.Changed += new FileSystemEventHandler(ConfigurationFileChangedCallBack);
            m_fsw = fsw;
            m_fsw.EnableRaisingEvents = true;
        }

        /// <summary>
        /// Passes the latest notification SQL server, database and service to the caller
        /// </summary>
        /// <param name="notificationSQLServer"></param>
        /// <param name="notificationDatabase"></param>
        /// <param name="notificationService"></param>
        /// <returns></returns>
        public void GetNotificationService(
             ref string notificationSQLServer,
             ref string notificationDatabase,
             ref string notificationService)
        {
			lock (this)
			{
                notificationSQLServer = m_instance.m_notificationSQLServer;
                notificationDatabase = m_instance.m_notificationDatabase;
                notificationService = m_instance.m_notificationService;
            }
        }

        /// <summary>
        /// Retireves the configuration record assocated with
        /// given sql, database, schema and queue. Then returns
        /// the application monitor associated with the
        /// configuration record.
        /// </summary>
        /// <param name="sqlServer"></param>
        /// <param name="database"></param>
        /// <param name="schema"></param>
        /// <param name="queue"></param>
        /// <returns>true if the notification was successfully processed</returns>
        public bool ProcessNotification(
            string sqlServer,
            string database,
            string schema,
            string queue)
        {
            lock (this)
            {
                int i;

                for (i = 0; i < 16; i++)
                {
                    string sqlServerCur = sqlServer;
                    if ((i & 8) == 8)
                    {
                        sqlServerCur = "";
                    }

                    string databaseCur = database;
                    if ((i & 4) == 4)
                    {
                        databaseCur = "";
                    }

                    string schemaCur = schema;
                    if ((i & 2) == 2)
                    {
                        schemaCur = "";
                    }

                    string queueCur = queue;
                    if ((i & 1) == 1)
                    {
                        queueCur = "";
                    }

                    string key = GetKey(sqlServerCur, databaseCur, schemaCur, queueCur);

                    if (m_configRT.ContainsKey(key))
                    {
                        ApplicationMonitor appMonitor = 
                            Global.AppMonitorMgr.GetApplicationMonitor(sqlServerCur, databaseCur, schemaCur, queueCur);
                        if (appMonitor != null)
                        {
                            appMonitor.ActivateProcess(sqlServer, database, schema, queue);
                        }
                        return true;
                    }
                }
            }
            return false;
        }

        /// <summary>
        /// Report the status of the configuration manager
        /// </summary>
        public override string  ToString()
        {
            lock (this)
            {
                string me = "Configuration status for notification service '" + m_instance.m_notificationService +
                    "' on SQL Server '" + m_instance.m_notificationSQLServer + "' and Database '" + m_instance.m_notificationDatabase + "'.";
                foreach (DictionaryEntry d in m_configRT)
                {
                    ConfigurationRecord cfr = ((ConfigurationRecord)(d.Value));
                    me += "\n    " + cfr.ToString();
                }
                return me;
            }
        }
        #endregion

        #region Protected methods
        /// <summary>
        /// Handles invalid elements while reading the configuration XML
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        protected static void serializer_UnknownElement(object sender, XmlElementEventArgs e)
        {
            System.Xml.XmlElement elem = e.Element;
            throw new EAException("Unknown Element:" + elem.Name + "\t" + elem.InnerXml + "\tat (" + e.LineNumber + "," + e.LinePosition + ")", Error.configFileBadXML);
        }

        /// <summary>
        /// Handles invalid nodes while reading the configuration XML
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        protected static void serializer_UnknownNode(object sender, XmlNodeEventArgs e)
        {
            throw new EAException("Unknown Node:" + e.Name + "\t" + e.Text + "\tat (" + e.LineNumber + "," + e.LinePosition + ")", Error.configFileBadXML);
        }

        /// <summary>
        /// Handles invalid attributes while reading the configuration XML
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        protected static void serializer_UnknownAttribute(object sender, XmlAttributeEventArgs e)
        {
            System.Xml.XmlAttribute attr = e.Attr;
            throw new EAException("Unknown attribute " + attr.Name + "='" + attr.Value + "'" + "\tat (" + e.LineNumber + "," + e.LinePosition + ")", Error.configFileBadXML);
        }
        #endregion

        #region Private methods

        /// <summary>
        /// Generates the configuration record key by the given parameters
        /// </summary>
        /// <param name="server"></param>
        /// <param name="database"></param>
        /// <param name="schema"></param>
        /// <param name="queue"></param>
        /// <returns>The generated key</returns>
        private static string GetKey(
            string server,
            string database,
            string schema,
            string queue)
        {
            return
                "\0" + server.ToUpper() +
                "\0" + database +
                "\0" + schema +
                "\0" + queue;
        }

        /// <summary>
        /// Generates the configuration record key of the provided
        /// configuration record
        /// </summary>
        /// <param name="cfr"></param>
        /// <returns>The generated key</returns>
        private static string GetKey(
            ConfigurationRecord cfr)
        {
            return GetKey(cfr.m_sqlServer, cfr.m_database, cfr.m_schema, cfr.m_queue);
        }

        /// <summary>
        /// Retrieves a configuratoin record by given key
        /// </summary>
        /// <param name="SQLServer"></param>
        /// <param name="Database"></param>
        /// <param name="Queue"></param>
        /// <returns></returns>
        private ConfigurationRecord GetConfigRec(
            string sqlServer,
            string database,
            string schema,
            string queue)
        {
            string key = GetKey(sqlServer, database, schema, queue);

            lock (this)
            {
                if (m_configRT.ContainsKey(key))
                {
                    ConfigurationRecord value = (ConfigurationRecord)m_configRT[key];
                    return value;
                }
            }
            return null;
        }
 
        /// <summary>
        ///     Reads the configuration file and validates XML
        ///		Extracts the activator from the configuration file DOM.
        ///     As part of this the code does some basic verification of the
        ///     configuration file and the selected activator correctness.
        /// </summary>
        /// <returns>The activator for the configuration file</returns>
        private Activator LoadActivatorConfiguration()
		{
            Activator myActivator = null;
            XmlSerializer serializer = new XmlSerializer(typeof(Activator));
            FileStream fs = null;

            //If the XML document has been altered with unknown 
            //nodes or attributes, handle them with the 
            //UnknownNode and UnknownAttribute events.
            serializer.UnknownNode += new XmlNodeEventHandler(serializer_UnknownNode);
            serializer.UnknownAttribute += new XmlAttributeEventHandler(serializer_UnknownAttribute);
            serializer.UnknownElement += new XmlElementEventHandler(serializer_UnknownElement);

            try
            {
                fs = File.Open(m_configFile, FileMode.Open, FileAccess.Read, FileShare.ReadWrite);
            }
            catch (FileNotFoundException e)
            {
                throw new EAException ("The configuration file was not found", Error.noConfigFile, e);
            }
            catch (Exception e)
            {
                throw new EAException("Problem accessing the configuration file", Error.problemAccessingLogFiles, e);
            }

            try
            {
                // Use the Deserialize method to restore the object's state with
                // data from the XML document. 
                myActivator = (Activator)serializer.Deserialize(fs);
            }
            catch (InvalidOperationException e)
            {
                throw new EAException("The configuration file XML Data did not parse correctly", Error.configFileBadXML, e);
            }
            finally
            {
                fs.Close();
            }

            // If 0, return error (CF does not contain configuration for this service name) 
            if (myActivator == null)
            {
                throw new EAException("Activator not found", Error.invalidConfigValues);
            }

            // Check all configuration records, make sure that (SQL,DB,queues) are different for diff. configurations
            // myActivator is the activator for this External Activator instance

            Debug.Assert(myActivator != null);

            if (myActivator.m_setup.m_notificationSQLServer == null ||
                    myActivator.m_setup.m_notificationSQLServer == String.Empty)
            {
                throw new EAException("Notification SQL Server not specified or Empty in Configuration file", Error.invalidConfigValues);
            }

            if (myActivator.m_setup.m_notificationDatabase == null ||
                myActivator.m_setup.m_notificationDatabase == String.Empty)
            {
                throw new EAException("Notification Database not specified or Empty in Configuration file", Error.invalidConfigValues);
            }

            if (myActivator.m_setup.m_notificationService == null ||
                myActivator.m_setup.m_notificationService == String.Empty)
            {
                throw new EAException("Notification Queue not specified or Empty in Configuration file", Error.invalidConfigValues);
            }

            //  if the activator setup is already loaded, then confirm that it hasn't changed
            if (m_instance != null)
            {
                if (m_instance.m_notificationSQLServer != myActivator.m_setup.m_notificationSQLServer ||
                    m_instance.m_notificationDatabase != myActivator.m_setup.m_notificationDatabase ||
                    m_instance.m_notificationService != myActivator.m_setup.m_notificationService ||
                    m_instance.m_enableDebugTrace != myActivator.m_setup.m_enableDebugTrace)
                {
                    throw new EAException("Activator setup updates are not accepted while the External activator is running." +
                        " Restart the activator in order to pick up the new setup", Error.invalidConfigValues);
                }
            }

            return myActivator;
        }

        /// <summary>
        ///		Inserts an Array into the configuration record table. Test if the configuration records
        ///		are valid. Also test if a configuration record with the same (SQL Server, DB, Queue)
        ///		is already present in the configuration record table
        /// </summary>
        /// <param name="configRecords">list of configuration records to insert into CRT</param>
        public Hashtable InsertArray(
            ConfigurationRecord[] configRecords)
        {
            Hashtable configHash = new Hashtable ();
            if (configRecords == null)
            {
                // good job!
                return configHash;
            }

            foreach (ConfigurationRecord cfr in configRecords)
            {
                try
                {
                    cfr.Validate();

                    // Key already present check
                    string key = GetKey(cfr);
                    if (m_configRT.ContainsKey(key))
                    {
                        throw new EAException("There was already a configuration record with the same SQLServer, Database and Queue", Error.invalidConfigValues);
                    }
                    configHash.Add(key, cfr);
                }
                catch (Exception e)
                {
                    Global.WriteDebugInfo("Bad configuration: " + cfr.ToString());
                    throw e;
                }
            }

            return configHash;
        }

        /// <summary>
        ///		For the new Configuration Record Table, compare it to the Global Configuration Record Table (this)
        ///		add, delete or replace configuration records and update the application monitor referencing the records.
        /// 
        ///     NOTE: If this function throws an exception we have to kill the application because we will have an
        ///     inconsistent configuration.
        /// </summary>
        /// <param name="ActivateProcessList"></param>
        private void Update(
            Hashtable configNew)
        {
            // First iteration adds / changes configuration records to the Global Configuration Record Table
            foreach (DictionaryEntry d in configNew)
            {
                ConfigurationRecord newcfr = ((ConfigurationRecord)(d.Value));
                // If there is old configuration record then remove it because it will be replaced with new one
                ConfigurationRecord oldcfr = GetConfigRec(newcfr.m_sqlServer, newcfr.m_database, newcfr.m_schema, newcfr.m_queue);
                if (oldcfr != null)
                {
                    RemoveFrom(oldcfr);
                }

                AddTo(newcfr);

                Global.AppMonitorMgr.InsertOrUpdate(newcfr);
            }

            // Second iteration deletes configuration records
            ArrayList listToDelete = new ArrayList();
            foreach (DictionaryEntry d in m_configRT)
            {
                ConfigurationRecord oldcfr = ((ConfigurationRecord)(d.Value));

                // New Configuration Record Table does NOT contain the entry
                string key = GetKey (oldcfr);

                if (!configNew.Contains(key))
                {
                    listToDelete.Add(oldcfr);
                }
            }

            foreach (ConfigurationRecord oldcfr in listToDelete)
            {
                // Add to the list to remove from the Global Configuration Record Table
                RemoveFrom(oldcfr);

                ApplicationMonitor am = Global.AppMonitorMgr.GetApplicationMonitor(oldcfr.m_sqlServer, oldcfr.m_database, oldcfr.m_schema, oldcfr.m_queue);

                if (am != null)
                {
                    am.ResetConfig();
                }
            }
        }

        /// <summary>
        /// Adds a configuration record to the Configuration Record Table
        /// </summary>
        /// <param name="cfr"></param>
        private void AddTo(
            ConfigurationRecord cfr) // I		Adds the configuration record to the Configuration
        //		Record Table
        {
            string RecordKey = GetKey (cfr);
            Debug.Assert(!m_configRT.ContainsKey(RecordKey));
            lock (this)
            {
                m_configRT.Add(RecordKey, cfr);
            }
        }

        /// <summary>
        /// Removes the configuration from the Configuration Record Table
        /// </summary>
        /// <param name="cfr"></param>
        private void RemoveFrom(
            ConfigurationRecord cfr) // I		Remove the configuration record from the Configuration
        //			Record Table
        {
            string recordKey = GetKey(cfr);
            lock (this)
            {
                Debug.Assert(m_configRT.ContainsKey(recordKey));
                Debug.Assert(m_configRT[recordKey] == cfr);
                m_configRT.Remove(recordKey);
            }
        }
        #endregion

        #region Members
        private Hashtable m_configRT; // Hashtable to store configuration records keyed by (SQLServer, Database, Queue)
        private FileSystemWatcher m_fsw;
        private Setup m_instance = null;
        private string m_configFile = null;
        #endregion
    }

    /// <summary>
    ///	    This class contains per-configuration information like ApplicationName, StartUpData, Min,
    ///		Max, etc. Also used for XML Deserialization. 
    /// </summary>
    public class ConfigurationRecord
    {
        #region Public methods
        public override string ToString()
        {
            string me = "";
            if (m_enabled)
            {
                me += "Enabled ";
            }
            else
            {
                me += "Disabled ";
            }
            me += "configuration associated with ";
            me += "[" + m_sqlServer + "].[" + m_database + "].[" + m_schema + "].[" + m_queue + "] and application <" +
                m_applicationName;
            if (m_cmdLineArgs != null && m_cmdLineArgs != String.Empty)
            {
                me += " " + m_cmdLineArgs;
            }
            me += ">\tMin=" + m_min.ToString () + " Max=" + m_max.ToString ();
            if (m_hasConsole)
            {
                me += " and requires console";
            }
            me += ".";
            return me;
        }

        public void Validate()
        {
            // ConfigurationRecord checks
            CheckBadConfig(m_applicationName == null || m_applicationName == String.Empty,
                "ApplicationName is not specified or Empty");
            if(m_standardOutName == String.Empty)
            {
               m_standardOutName = null;
            }
            if(m_standardInName == String.Empty)
            {
                m_standardInName = null;
            }
            if (m_standardErrName == String.Empty)
            {
                m_standardErrName = null;
            }
            CheckBadConfig(m_standardInName != null && m_standardOutName != null && m_standardErrName != null && m_hasConsole,
                "HasConsole is true even though StandardIn, StandardOut and StandardErr are redirected");
            CheckBadConfig(m_standardInName != null && m_standardOutName == m_standardInName,
                "StandardIn must be different from StandardOut");
            CheckBadConfig(m_standardInName != null && m_standardErrName == m_standardInName,
                "StandardIn must be different from StandardErr");
            CheckBadConfig(m_enabled && (m_min < 0 || m_max <= 0 || m_min > m_max),
                "Minimum and Maximum are not correct");
            CheckBadConfig(m_enabled && m_min > 0 && (m_queue == "" || m_schema == "" || m_database == "" || m_sqlServer == ""),
                "Min must be 0 when the queue is not fully qualified by specifying Queue, Schema, Database or SQLServer");
        }
        #endregion

        #region Private methods
        private void CheckBadConfig(
            bool statement,
            string exceptionText)
        {
            if (statement == true)
            {
                throw new EAException(exceptionText + " in " + ToString (), Error.invalidConfigValues);
            }
        }
        #endregion

        #region Members
        [XmlElement("ApplicationName")]
        public string m_applicationName;
        [XmlElement("CommandLineArgs")]
        public string m_cmdLineArgs = "";
        [XmlElement("SQLServer")]
        public string m_sqlServer = "";
        [XmlElement("Database")]
        public string m_database = "";
        [XmlElement("Schema")]
        public string m_schema = "";
        [XmlElement("Queue")]
        public string m_queue = "";
        [XmlElement("Min")]
        public int m_min = 0;
        [XmlElement("Max")]
        public int m_max = 1;
        [XmlAttribute("Enabled")]
        public bool m_enabled = false;
        [XmlElement("HasConsole")]
        public bool m_hasConsole = false;
        [XmlElement("StandardOut")]
        public string m_standardOutName = "";
        [XmlElement("StandardIn")]
        public string m_standardInName = "";
        [XmlElement("StandardErr")]
        public string m_standardErrName = "";
        #endregion
    }
}
