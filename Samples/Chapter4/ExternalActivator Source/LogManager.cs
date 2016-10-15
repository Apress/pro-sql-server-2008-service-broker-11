#region Using
using System;
using System.Collections;
using System.Diagnostics;
using System.IO;
using System.Text;
using System.Xml;
using System.Xml.Serialization;
#endregion

namespace ExternalActivator
{
    /// <summary>
    /// Manages the access to the recovery log
    /// </summary>
    class LogManager
    {
        #region Public members
        /// <summary>
        /// Logs process start
        /// </summary>
        /// <param name="configrec">Configuration record having the information about the process to be started</param>
        /// <param name="pd">Process data</param>
        public void StartProcess(
            ConfigurationRecord configRec,
            ProcessData pd)
        {
            lock (this)
            {
                CheckDamaged();

                XmlSerializer serializer = new XmlSerializer(typeof(StartProcess));
                StartProcess sp = new StartProcess();
                sp.ApplicationName = configRec.m_applicationName;
                sp.StartUpData = configRec.m_cmdLineArgs;
                sp.SQLServer = configRec.m_sqlServer;
                sp.Database = configRec.m_database;
                sp.Schema = configRec.m_schema;
                sp.Queue = configRec.m_queue;
                sp.ProcessId = pd.Pid;
                sp.CreationHighDateTime = pd.CreationHighDateTime;
                sp.CreationLowDateTime = pd.CreationLowDateTime;

                StringBuilder sb = new StringBuilder();
                TextWriter writer = new StringWriter(sb);
                XmlTextWriter xwriter = new XmlTextWriter(writer);
                xwriter.Formatting = Formatting.None;
                serializer.Serialize(xwriter, sp);
                string xmlStartProcessString = sb.ToString();

                WriteToLog(String.Format("{0}{1}\n{2}", ms_processStart, xmlStartProcessString.Length, xmlStartProcessString));
            }
        }

        /// <summary>
        /// Logs that a process ended
        /// </summary>
        /// <param name="pd">Process data</param>
        public void EndProcess(
            ProcessData pd)
        {
            lock (this)
            {
                CheckDamaged ();

                try
                {
                    WriteToLog(String.Format("{0}{1} {2} {3}", ms_processDied, pd.Pid, pd.CreationHighDateTime, pd.CreationLowDateTime));

                    m_records++;
                    if (m_records > ms_numberOfEndProcessesMax)
                    {
                        Hashtable dummyTable = null;
                        Checkpoint(out dummyTable);

                        m_records = 0;
                    }
                }
                catch (Exception e)
                {
                    m_damaged = true;
                    throw e;
                }
            }
        }

        /// <summary>
        /// Runs recovery on the log file and generates a hash table of all the
        /// processes that were started when the log was stopped.
        /// </summary>
        /// <param name="pidHashTable">Hash table of possibly running porcesses</param>
        public void RunRecovery(
            out Hashtable pidHashTable)
        {
            lock (this)
            {
                try
                {
                    CheckDamaged();

                    Global.WriteStatus("Running recovery using '" + LogFileName() + "' ...");

                    pidHashTable = null;
                    if (File.Exists(LogFileName()) == false && File.Exists(TempLogFileName()))
                    {
                        Global.WriteStatus("Rename the temporary file '" + TempLogFileName() + "' as '" + LogFileName() + "'.");
                        File.Move(TempLogFileName(), LogFileName());
                    }

                    if (File.Exists(LogFileName()))
                    {
                        Checkpoint(out pidHashTable);
                    }
                    else
                    {
                        m_file = File.Open(LogFileName(), FileMode.Append, FileAccess.Write, FileShare.Read);
                        m_outputStream = new StreamWriter(m_file);
                    }

                    Global.WriteStatus("Recovery completed.");
                }
                catch (Exception e)
                {
                    m_damaged = true;
                    throw e;
                }
            }
        }

        /// <summary>
        /// Clean shutdown of the log manager
        /// </summary>
        public void Shutdown()
        {
            lock (this)
            {
                try
                {
                    CheckDamaged();

                    // Write cleanshutdown to the Recovery Log file (also closes the recovery log file)
                    Global.WriteStatus("Shutting down the recovery log manager");

                    Hashtable dummy = null;
                    Checkpoint(out dummy);
                    CloseFiles();
                }
                catch (Exception e)
                {
                    m_damaged = true;
                    throw e;
                }
            }
        }

        /// <summary>
        /// Unclean shoutdown of the log file
        /// </summary>
        public void UncleanShutdown()
        {
            lock (this)
            {
                if (m_damaged)
                {
                    return;
                }

                m_damaged = true;
                CloseFiles();
            }
        }
        #endregion

        #region Private methods
        /// <summary>
        /// Check if the log file is damaged
        /// </summary>
        private void CheckDamaged()
        {
            if (m_damaged)
            {
                throw new EAException("Recovery log is damaged", Error.damagedRecoveryLog);
            }
        }

        /// <summary>
        /// Closes the log file
        /// </summary>
        private void CloseFiles()
        {
            if (m_outputStream != null)
            {
                m_outputStream.Close();
                m_outputStream = null;
            }

            if (m_file != null)
            {
                m_file.Close();
                m_file = null;
            }
        }

        private string LogFileName()
        {
            return Global.ApplicationName + ".RecoveryLog";
        }
        
        private string TempLogFileName()
        {
            return LogFileName() + ".tmp";
        }

        /// <summary>
        ///     Writes to the recovery log
        /// </summary>
        /// <param name="s">Text to write in the log</param>
        private void WriteToLog(string s)
        {
            try
            {
                if (m_outputStream != null)
                {
                    m_outputStream.WriteLine(s);
                    m_outputStream.Flush();
                }
            }
            catch (Exception e)
            {
                m_damaged = true;
                throw new EAException("Cannot write to recovery log the string: " + s, Error.logingError, e);
            }
        }

        /// <summary>
        /// Recovers the running processes informaion from the log.
        /// </summary>
        /// <param name="logFileName">log file to recover from</param>
        /// <param name="pidHashTable">output table of recovered information</param>
        private void RecoverRunningProcessesInfo(
            string logFileName,
            out Hashtable pidHashTable)
        {
            pidHashTable = new Hashtable();

            FileStream logFile = null;
            StreamReader logStream = null;

            try
            {
                logFile = File.Open(logFileName, FileMode.Open, FileAccess.Read);
                logStream = new StreamReader(logFile);

                // start from the beginning of the Log File
                logFile.Seek(0, SeekOrigin.Begin);
                logStream.DiscardBufferedData();

                string msg;
                while ((msg = logStream.ReadLine()) != null)
                {
                    if (msg.StartsWith(ms_processStart))
                    {
                        string pidStartTimexmlStartProcess = msg.Remove(0, ms_processStart.Length);
                        int length = Int32.Parse(pidStartTimexmlStartProcess);
                        char[] buffer = new char[length];
                        int count = logStream.ReadBlock(buffer, 0, length);
                        if (count < length)
                        {
                            throw new EAException("Corrpted recovery log", Error.badLogFileRecoverNotPossible);
                        }

                        msg = logStream.ReadLine();
                        Debug.Assert(msg == "");
                        StringBuilder sb = new StringBuilder();
                        sb.Append(buffer);
                        string xmlStartDieProcess = sb.ToString();

                        XmlSerializer serializer = new XmlSerializer(typeof(StartProcess));
                        StringReader strRdr = new StringReader(xmlStartDieProcess);
                        StartProcess sp = null;

                        try
                        {
                            sp = (StartProcess)serializer.Deserialize(strRdr);
                        }
                        catch (InvalidOperationException e)
                        {
                            throw new EAException("Invalid xml record", Error.startProcessBadXML, e);
                        }

                        // Add the (PID, ST, StartEntry) to the pidHashTable
                        ProcessData key = new ProcessData(sp.ProcessId, sp.CreationHighDateTime, sp.CreationLowDateTime);
                        pidHashTable.Add(key, sp);
                    }
                    else if (msg.StartsWith(ms_processDied))
                    {
                        string pidStartTime = msg.Remove(0, ms_processDied.Length);
                        char[] seps = new char[] { ' ' };
                        string[] parts = pidStartTime.Split(seps);
                        int pid = Int32.Parse(parts[0]);
                        uint CreationHighDateTime = UInt32.Parse(parts[1]);
                        uint CreationLowDateTime = UInt32.Parse(parts[2]);
                        ProcessData key = new ProcessData(pid, CreationHighDateTime, CreationLowDateTime);
                        if (!pidHashTable.ContainsKey(key))
                        {
                            throw new EAException("Corrpted recovery log", Error.badLogFileRecoverNotPossible);
                        }
                        pidHashTable.Remove(key);
                    }
                    else
                    {
                        throw new EAException("Corrpted recovery log", Error.badLogFileRecoverNotPossible);
                    }
                }
            }
            finally
            {
                if (logStream != null)
                {
                    logStream.Close();
                }

                if (logFile != null)
                {
                    logFile.Close();
                }
            }
        }

        /// <summary>
        /// Checkpoints the recovery log. It will close the existing recovery log
        /// and will create a new one that contains only the current active processes.
        /// </summary>
        private void Checkpoint(
            out Hashtable pidHashTable)
        {
            Global.WriteDebugInfo("Checkpointing the recovery log ...");

            //  read the current recovery file to load the processes recovery information
            CloseFiles();

            RecoverRunningProcessesInfo(LogFileName(), out pidHashTable);

            //  write the running recovered processes in temporary recovery file
            m_file = File.Open(TempLogFileName(), FileMode.Create, FileAccess.Write, FileShare.Read);
            m_outputStream = new StreamWriter(m_file);

            foreach (DictionaryEntry e in pidHashTable)
            {
                StartProcess sp = (StartProcess)e.Value;
                StringBuilder sb = new StringBuilder();
                TextWriter writer = new StringWriter(sb);
                XmlTextWriter xwriter = new XmlTextWriter(writer);
                XmlSerializer serializer = new XmlSerializer(typeof(StartProcess));
                xwriter.Formatting = Formatting.None;
                serializer.Serialize(xwriter, sp);
                string xmlStartProcessString = sb.ToString();

                WriteToLog(String.Format("{0}{1}\n{2}", ms_processStart, xmlStartProcessString.Length, xmlStartProcessString));
            }

            //  now replace the original recovery file with the temporal one
            CloseFiles();
            File.Delete(LogFileName());
            File.Move(TempLogFileName(), LogFileName());

            //  reopen the recovery file
            m_file = File.Open(LogFileName(), FileMode.Append, FileAccess.Write, FileShare.Read);
            m_outputStream = new StreamWriter(m_file);
            Global.WriteDebugInfo("Checkpointed the recovery log.");
        }
        #endregion

        #region Constants
        private static readonly int ms_numberOfEndProcessesMax = 100;
        private static readonly string ms_processStart = "PROCESS START ";
        private static readonly string ms_processDied = "PROCESS DIED ";
        #endregion

        #region Members
        private bool m_damaged = false;
        private FileStream m_file = null;
        private StreamWriter m_outputStream = null; // this is used for writing to the Log 
        private int m_records = 0;
        #endregion
    }
}