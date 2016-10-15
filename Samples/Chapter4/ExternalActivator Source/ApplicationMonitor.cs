#region Using
using System;
using System.Collections;
using System.Diagnostics;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;
using System.Xml;
using System.Xml.Serialization;
#endregion

namespace ExternalActivator
{
    /// <summary>
    ///		ApplicationMonitor contains classes used to keep track of specific applications.
    ///		It keeps track of the current number of instances of both applications whose
    ///		configuration records no longer exist as well as those whose configuration records
    ///		exist. It is also responsible for activating applications on receiving notification
    ///		messages.
    /// </summary>
	public class ApplicationMonitor
    {
        #region External structures
        /// <summary>
        /// Used to store security information for creating file handles
        /// </summary>
        [StructLayout(LayoutKind.Sequential)]
        public struct SECURITY_ATTRIBUTES
        {
            public uint nLength;
            public IntPtr lpSecurityDescriptor;
            public bool bInheritHandle;
        }

        /// <summary>
        /// Used to store File information to pass to the GetProcessTimes external function
        /// </summary>
        [StructLayout(LayoutKind.Sequential)]
        public struct FILETIME
        {
            public uint dwLowDateTime;
            public uint dwHighDateTime;
        }

        /// <summary>
        /// Used to store Start-up information to pass to the CreateProcess external function
        /// </summary>
        [StructLayout(LayoutKind.Sequential)]
        public struct STARTUPINFO
        {
            public uint cb;
            public string lpReserved;
            public string lpDesktop;
            public string lpTitle;
            public uint dwX;
            public uint dwY;
            public uint dwXSize;
            public uint dwYSize;
            public uint dwXCountChars;
            public uint dwYCountChars;
            public uint dwFillAttribute;
            public uint dwFlags;
            public ushort wShowWindow;
            public ushort cbReserved2;
            public uint lpReserved2;
            public uint hStdInput;
            public uint hStdOutput;
            public uint hStdError;
        }

        /// <summary>
        /// Used to obtain information about the started process from the
        /// CreateProcess external function
        /// </summary>
        [StructLayout(LayoutKind.Sequential)]
        public struct PROCESS_INFORMATION
        {
            public uint hProcess;
            public uint hThread;
            public uint nProcessId;
            public uint nThreadId;
        }
        #endregion

        #region Imports
        /// <summary>
        /// Calls the Windows API function GetProcessTimes in kernel32.dll
        /// </summary>
        /// <param name="hProcess">Process handle</param>
        /// <param name="lpCreationTime">process creation time</param>
        /// <param name="lpExitTime">process exit time</param>
        /// <param name="lpKernelTime"></param>
        /// <param name="lpUserTime"></param>
        /// <returns>Whether the function succeeded or not</returns>
        [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode, CallingConvention = CallingConvention.StdCall)]
        private static extern bool GetProcessTimes(
            uint hProcess, // I			
            ref FILETIME lpCreationTime,
            ref FILETIME lpExitTime,
            ref FILETIME lpKernelTime,
            ref FILETIME lpUserTime);


        /// <summary>
        /// Calls the Windows API function GetStdHandle in kernel32.dll
        /// </summary>
        /// <param name="nStdHandle">Type of the handle to get</param>
        /// <returns>The handle value</returns>
        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, CallingConvention = CallingConvention.StdCall)]
        private static extern uint GetStdHandle(
            uint nStdHandle);

        /// <summary>
        /// Calls the Windows API function CreateFile in kernel32.dll
        /// </summary>
        /// <param name="lpFileName">Name of File to create</param>
        /// <param name="dwDesiredAccess">File access</param>
        /// <param name="dwShareMode">File share mode</param>
        /// <param name="lpSecurityAttributes"></param>
        /// <param name="dwCreationDisposition"></param>
        /// <param name="dwFlagsAndAttributes"></param>
        /// <param name="hTemplateFile"></param>
        /// <returns>Whether the function succeeded or not</returns>
        [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode, CallingConvention = CallingConvention.StdCall)]
        private static extern uint CreateFile(
            string lpFileName,
            uint dwDesiredAccess,
            uint dwShareMode,
            ref SECURITY_ATTRIBUTES lpSecurityAttributes,
            uint dwCreationDisposition,
            uint dwFlagsAndAttributes,
            IntPtr hTemplateFile);

        //----------------------------------------------------------------------
        // Function: CreateProcess (External)
        //
        // Description:
        //		Calls the Windows API function CreateProcess in kernel32.dll
        //
        // Returns:
        //		Whether the function succeeded or not
        //
        /// <summary>
        /// Calls the Windows API function CreateProcess in kernel32.dll
        /// </summary>
        /// <param name="strApplication">Name of Application to start</param>
        /// <param name="strFullCmd">Command-line to execute</param>
        /// <param name="lpProcessAttribute"></param>
        /// <param name="lpThreadAttribute"></param>
        /// <param name="bInheritHandles">Should it inherit handles or not</param>
        /// <param name="lCreationFlags"Process Creation flags></param>
        /// <param name="lpEnvironment">Environment block for the new process</param>
        /// <param name="strCurrentDirectory">Current Directory</param>
        /// <param name="siInfo">Start up Information</param>
        /// <param name="pInfo">Identification information for the new process</param>
        /// <returns>Whether the function succeeded or not</returns>
        [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode, CallingConvention = CallingConvention.StdCall)]
        private static extern bool CreateProcess(
            string strApplication,
            string strFullCmd,
            IntPtr lpProcessAttribute,
            IntPtr lpThreadAttribute,
            bool bInheritHandles,
            uint lCreationFlags,
            IntPtr lpEnvironment,
            string strCurrentDirectory,
            ref STARTUPINFO siInfo,
            ref PROCESS_INFORMATION pInfo);

        /// <summary>
        /// Calls the Windows API function ResumeThread in kernel32.dll
        /// </summary>
        /// <param name="hThread">Handle of the thread to resume</param>
        /// <returns>Whether the function succeeded or not</returns>
        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, CallingConvention = CallingConvention.StdCall)]
        private static extern uint ResumeThread(
            uint hThread); // I		Handle of the thread to resume

        /// <summary>
        /// Calls the Windows API function TerminateProcess in kernel32.dll
        /// </summary>
        /// <param name="hThread">Handle of the main thread of the process to terminate</param>
        /// <param name="uExitCode">Exit Code to use while returning</param>
        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, CallingConvention = CallingConvention.StdCall)]
        private static extern void TerminateProcess(
            uint hThread,
            uint uExitCode);

        /// <summary>
        /// Calls the Windows API function CloseHandle in kernel32.dll
        /// </summary>
        /// <param name="handle">Handle to close</param>
        /// <returns>Whether the function succeeded or not</returns>
        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, CallingConvention = CallingConvention.StdCall)]
        private static extern bool CloseHandle(
            uint handle);
        #endregion

        #region External constants
        private static readonly uint STD_INPUT_HANDLE = 0xfffffff6;
        private static readonly uint STD_OUTPUT_HANDLE = 0xfffffff5;
        private static readonly uint STD_ERROR_HANDLE = 0xfffffff4;
        private static readonly uint INVALID_HANDLE_VALUE = 0xffffffff;

        private static readonly uint GENERIC_READ = 0x80000000;
        private static readonly uint GENERIC_WRITE = 0x40000000;
        private static readonly uint FILE_ATTRIBUTE_NORMAL = 0x00000080;
        private static readonly uint OPEN_ALWAYS = 4;
        private static readonly uint OPEN_EXISTING = 3;
        private static readonly uint FILE_SHARE_READ = 1;
        private static readonly uint FILE_SHARE_WRITE = 2;

        private static readonly uint STARTF_USESTDHANDLES = 0x00000100;

        private static readonly uint NORMAL_PRIORITY_CLASS = 0x00000020;
        private static readonly uint CREATE_NEW_CONSOLE = 0x00000010;
        private static readonly uint DETACHED_PROCESS = 0x00000008;
        private static readonly uint CREATE_SUSPENDED = 0x00000004;
        #endregion

        /// <summary>
        ///		The class encapsulates information that would help the Callback associated 
        ///		with the Process.Exited event to decrement the current number of instances
        ///		of the corresponding Application Monitor.
        /// </summary>
        private class ExitedFunc
        {
            /// <summary>
            ///	This function is called when a process exits. This function reduces the current
            ///	number of instances for this Application Monitor. 
            /// </summary>
            /// <param name="a"></param>
            /// <param name="b"></param>
            public void ExitedFunctionCallBack(
                    object a, // I			Object from which the Event was thrown
                    EventArgs b) // I //	Event Arguments
            {
                try
                {
                    m_appMon.ProcessEnded(this);
                }
                catch (Exception e)
                {
                    Global.DoHardKill(e);
                }
            }

            #region Members
            public ApplicationMonitor m_appMon; // Application Monitor that started the process
            public ProcessData m_processData; // Process Data - contains the process object and eventHandler 
            #endregion
        }

        #region Methods
        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="sqlServer"></param>
        /// <param name="database"></param>
        /// <param name="queue"></param>
        /// <param name="cfr"></param>
		public ApplicationMonitor(
			string sqlServer,  // I		Name of SQL Server
			string database,  // I		Name of Database
            string schema, // I queue schema
			string queue, // I			Name of Queue
            ConfigurationRecord cfr)
		{
			m_sqlServer = sqlServer;
			m_database = database;
            m_schema = schema;
			m_queue = queue;

            m_configRec = cfr;
            m_error = null;

            m_enabled = true;

			m_currentNumberOfInstances = 0;
            m_startedProcesses = 0;
            m_lastStart = DateTime.Now;

            m_missedNotification = false;
            m_outOfMemory = false;
            m_keyAsSQL = "[" + m_sqlServer + "].[" + m_database + "].[" + m_schema + "].[" + m_queue + "]";
		}

        /// <summary>
        ///		Tries to register for the Exited event of a process if it exists. In this way, it starts
        ///		keeping track of the process. 
        /// </summary>
        /// <param name="pd"></param>
		public void AttachToProcess(
            ProcessData pd)
		{
            bool ok;
			bool processdied = false;
			Process process = null;


			FILETIME filetimeCreation = new FILETIME();
			FILETIME filetimeExit = new FILETIME();
			FILETIME filetimeKernel = new FILETIME();
			FILETIME filetimeUser = new FILETIME();
			try
			{
                //  get the process by id 
				process = Process.GetProcessById(pd.Pid);
				process.EnableRaisingEvents = true;
				ok = GetProcessTimes((uint)process.Handle, ref filetimeCreation, ref filetimeExit, ref filetimeKernel, ref filetimeUser);
				if (!ok)
				{
					processdied = true;
				}
				else
				{
                    // verify that this is the process we started by checking its creation time
					if (filetimeCreation.dwHighDateTime != pd.CreationHighDateTime || filetimeCreation.dwLowDateTime != pd.CreationLowDateTime )
					{
						Global.WriteDebugInfo(
							"Process mismatch: " + filetimeCreation.dwHighDateTime + " to " +
							pd.CreationHighDateTime + " and " + filetimeCreation.dwLowDateTime + " to " +
							pd.CreationLowDateTime);
						processdied = true;
					}
				}
			}
			catch (ArgumentException e) 
				// Cases when cannot attach to processes because they are being debugged or something
				// it can be attached without problems
			{
				Global.WriteDebugInfo("Process " + pd.Pid + " died. " + e.Message);
				processdied = true;
			}
			catch(InvalidOperationException e)
			{
                Global.WriteDebugInfo("Process " + pd.Pid + " died. Exception Raised (process died while checking for Start Time): " + e.Message);
				processdied = true;
			}
			catch (Exception e) // this takes care of the "Access Denied" case.
			{
				Global.WriteDebugInfo(
                    "Process died. Not able to get process by pid " + pd.Pid + ". Assuming process died because it " + 
					"might have been started with different credentials. Details:" + e.Message);
				processdied = true;
			}

            //  if we could not attach to the process then report that process died
			if (processdied)
			{
                Global.LogMgr.EndProcess(pd);
			}
			else
			{
                // Add to the callback list
                ExitedFunc ef = null;
                lock (this)
                {
					ef = new ExitedFunc();

					EventHandler x = new EventHandler(ef.ExitedFunctionCallBack);
					m_currentNumberOfInstances++;
                    m_startedProcesses++;

					// this might fail too
					ef.m_appMon = this;
					ef.m_processData = pd;
                    process.Exited += x;

                    if (process.HasExited)  // if the process has exited
					{
                        if (ef.m_appMon != null)
                        {
                            Global.LogMgr.EndProcess(pd);
                            m_currentNumberOfInstances -= 1;
                            ef.m_appMon = null;
                        }
					}
                }
            }
        }

        /// <summary>
        ///		Starts (creates) a process corresponding to this Application Monitor (i.e. a specific
        ///		application with specific start up data) only if current number of instances is below max
        /// </summary>
		public bool ActivateProcess(
            string sqlServer,
            string database,
            string schema,
            string queue)
        {
            while (true)
            {
                lock (this)
                {
                    //  If:
                    //  1. There is no configuration OR
                    //  2. The configuration is disabled OR
                    //  3. The application monitor is disabled because could not start a process OR
                    //  4. Too many processes are started
                    //  then we cannot activate the process
                    if (m_configRec == null)
                    {
                        Global.WriteDebugInfo("Will not activate process associated with '" + m_keyAsSQL + "' because there is no config record associated.");
                        return false;
                    }

                    if (m_configRec.m_enabled == false)
                    {
                        Global.WriteDebugInfo("Will not activate process '" + m_configRec.m_applicationName + "' associated with " + m_keyAsSQL + " because the configuration is disabled.");
                        return false;
                    }

                    if (m_enabled == false)
                    {
                        Global.WriteDebugInfo("Will not activate process '" + m_configRec.m_applicationName + "' associated with " + m_keyAsSQL + " because the application is disabled.");
                        return false;
                    }

                    int max = m_configRec.m_max;

                    if (m_currentNumberOfInstances >= max)
                    {
                        //  we do not support notifications for generic objects
                        if (m_sqlServer != "" && m_database != "" && m_schema != "" && m_queue != "")
                        {
                            m_missedNotification = true;
                        }
                        Global.WriteDebugInfo("Will not activate process '" + m_configRec.m_applicationName + "' associated with " + m_keyAsSQL + " because there are " + max + " processes running and Max is " + max + ".");
                        return false;
                    }

                    // I will use the same ApplicationName and StartupData with which I started. If StartUpData/App is changed,
                    // a new ApplicationMonitor created, so if a user wants to achieve that, he must kill all his present applications
                    // and then add a new configuration (or vice versa). 
                    Global.WriteDebugInfo("Activating process '" + m_configRec.m_applicationName + "' associated with " + m_keyAsSQL + " number of running instances is " + m_currentNumberOfInstances + " and Max is " + max + ".");

                    m_missedNotification = false;
                    m_outOfMemory = false;
                    m_error = null;
                    try
                    {
                        string processToStart = m_configRec.m_applicationName;
                        if (m_configRec.m_cmdLineArgs != null && m_configRec.m_cmdLineArgs != "")
                        {
                            processToStart += " " + FillInTheBlanks(
                                m_configRec.m_cmdLineArgs,
                                sqlServer,
                                database,
                                schema,
                                queue);
                        }
                        if (CommonActivationRoutine(processToStart))
                        {
                            m_currentNumberOfInstances++;
                            m_startedProcesses++;
                            m_lastStart = DateTime.Now;
                            return true;
                        }
                    }
                    catch (EAException ea)
                    {
                        if (ea.Error == Error.cannotStartProcess)
                        {
                            m_error = ea.Message;
                            m_enabled = false;
                            Global.WriteWarning(
                                "Disabling application associated with [" + m_sqlServer + "].[" + m_database + "].[" + m_schema + "].[" + m_queue +
                                "] because failed to start process '" + m_configRec.m_applicationName + "'");
                            return false;
                        }
                        else
                        {
                            throw ea;
                        }
                    }
                    Global.WriteDebugInfo("Could not activate process '" + m_configRec.m_applicationName + "' associated with " + m_keyAsSQL + " because out of Resources. Will try again later.");
                    m_outOfMemory = true;
                    return false;
                }
            }
        }
		
        /// <summary>
        /// Tries to activate processes until we reach the minimum
        /// required number of processes
        /// </summary>
		public void ActivateIfFallingBelowMinimum()
		{
            while (true)
            {
                lock (this)
                {
                    //  if there is no configuration record then there is no minimum.
                    if (m_configRec == null)
                    {
                        return;
                    }

                    //  if we exceed the minimum then we have nothing to do
                    int min = m_configRec.m_min;
                    if (m_currentNumberOfInstances >= min &&
                        m_outOfMemory == false &&
                        (m_currentNumberOfInstances > 0 || m_missedNotification == false))
                    {
                        return;
                    }

                    if (m_outOfMemory)
                    {
                        Global.WriteDebugInfo("Trying to activate a process '" + m_configRec.m_applicationName + "' associated with " + m_keyAsSQL + " because it failed to start due to out of memory.");
                    }
                    else if (min > 0)
                    {
                        Global.WriteDebugInfo("Trying to activate a process '" + m_configRec.m_applicationName + "' associated with " + m_keyAsSQL + " because number of running instances is " + m_currentNumberOfInstances + " and Min is " + min);
                    }
                    else if (m_missedNotification)
                    {
                        Global.WriteDebugInfo("Trying to activate a process '" + m_configRec.m_applicationName + "' associated with " + m_keyAsSQL + " because there was a missed notification message.");
                    }

                    if (ActivateProcess(m_sqlServer, m_database, m_schema, m_queue) == false)
                    {
                        break;
                    }
                }
			}
        }

        /// <summary>
        /// Checks if the application monitor is ok to be removed from
        /// the application monitor table
        /// </summary>
        /// <returns>true if is ok, false otherwise</returns>
        public bool CanBeRemoved()
        {
            lock (this)
            {
                if (m_configRec == null && m_currentNumberOfInstances == 0)
                {
                    return true;
                }

                return false;
            }
        }

        /// <summary>
        /// The configuration record was removed
        /// </summary>
        public void ResetConfig()
        {
            lock (this)
            {
                m_configRec = null;
                m_missedNotification = false;
                m_outOfMemory = false;
                m_enabled = true;
            }
        }

        /// <summary>
        /// Add a new configuration record or replace the existing one
        /// </summary>
        /// <param name="cfr">the new configuration record</param>
        public void SetConfig(
            ConfigurationRecord cfr)
        {
            lock (this)
            {
                Debug.Assert(cfr != null);
                Debug.Assert(cfr != m_configRec);
                m_configRec = cfr;
                if (m_enabled == false)
                {
                    m_error = null;
                }
                m_enabled = true;
            }
        }

        /// <summary>
        /// Returns the string descrtion of the object
        /// </summary>
        /// <returns></returns>
        public override string ToString()
        {
            string me;
            lock (this)
            {
                me = "Application associated with [" + m_sqlServer + "].[" + m_database + "].[" + m_schema + "].[" + m_queue + "]";
                if (m_enabled == false)
                {
                    me += " is disabled because could not start a process (Reason: '" + m_error + "'),";
                }
                me += " monitors " + m_currentNumberOfInstances + " running processes";
                if (m_configRec == null)
                {
                    me += ", has no corresponding configuration";
                }
                else if (m_outOfMemory)
                {
                    me += ", last time failed to start process due to '" + m_error + "' and will retry soon";
                }

                me += ". " + m_startedProcesses + " processes were started successfully";
                if (m_startedProcesses > 0)
                {
                    me += ", last one at " + m_lastStart;
                }

                me += ".";


                
            }

            return me;
        }
        #endregion

        #region Private methods
        /// <summary>
        /// 	Replaces %sqlserver%, %database%, %queue% in the StartUpData string with the appropriate names
        /// </summary>
        /// <param name="input">string to update</param>
        /// <returns>updated string</returns>
        private string FillInTheBlanks(
            string input,
            string sqlServer,
            string database,
            string schema,
            string queue)
        {
            StringBuilder x = new StringBuilder(input);
            x = x.Replace("%sqlserver%", sqlServer);
            x = x.Replace("%database%", database);
            x = x.Replace("%schema%", schema);
            x = x.Replace("%queue%", queue);
            return x.ToString();
        }

        /// <summary>
        /// Create Files that will be used to redirect I/O for a child
        /// </summary>
        /// <param name="suInfo">Process startup info</param>
        /// <param name="hOutputFile">handle to the output file</param>
        /// <param name="hErrorFile">handle to the error file</param>
        /// <param name="hInputFile">handle to the input file</param>
        private void CreateFilesForRedirection(
            ref STARTUPINFO suInfo,
            ref uint hOutputFile,
            ref uint hErrorFile,
            ref uint hInputFile)
        {
            Debug.Assert(m_configRec != null);
            string outputFile = m_configRec.m_standardOutName;
            string inputFile = m_configRec.m_standardErrName;
            string errorFile = m_configRec.m_standardInName;

            if (outputFile != null || inputFile != null || errorFile != null)
            {
                Global.WriteDebugInfo("Creating files used to redirect process Standard Out, In, Error for process '" +
                    m_configRec.m_applicationName + "':" +
                    "\nStandard Out " + (outputFile != null ? " to '" + outputFile + "'" : "is not redirected") +
                    "\nStandard In " + (inputFile != null ? " to '" + inputFile + "'" : "is not redirected") +
                    "\nStandard Error " + (errorFile != null ? " to '" + errorFile + "'" : "is not redirected") +
                    ".");
            }
            else
            {
                Global.WriteDebugInfo("Using standard Out, In and Error for process '" + m_configRec.m_applicationName + "'.");
            }

            //  set process security
            SECURITY_ATTRIBUTES security_attributes_output = new SECURITY_ATTRIBUTES();
            security_attributes_output.nLength = (uint)Marshal.SizeOf(typeof(SECURITY_ATTRIBUTES));
            security_attributes_output.bInheritHandle = true;
            security_attributes_output.lpSecurityDescriptor = IntPtr.Zero;

            SECURITY_ATTRIBUTES security_attributes_input = new SECURITY_ATTRIBUTES();
            security_attributes_input.nLength = (uint)Marshal.SizeOf(typeof(SECURITY_ATTRIBUTES));
            security_attributes_input.bInheritHandle = true;
            security_attributes_input.lpSecurityDescriptor = IntPtr.Zero;

            SECURITY_ATTRIBUTES security_attributes_error = new SECURITY_ATTRIBUTES();
            security_attributes_error.nLength = (uint)Marshal.SizeOf(typeof(SECURITY_ATTRIBUTES));
            security_attributes_error.bInheritHandle = true;
            security_attributes_error.lpSecurityDescriptor = IntPtr.Zero;

            //  open an output file
            if (outputFile != null)
            {

                hOutputFile = CreateFile(outputFile,
                    GENERIC_WRITE, // write to the file
                    FILE_SHARE_READ | FILE_SHARE_WRITE, // share the file for reading and writing                            
                    ref security_attributes_output,   // has bInheritHandle = true     
                    OPEN_ALWAYS,     // always open the file if it exists, else create            
                    FILE_ATTRIBUTE_NORMAL,   // normal file     
                    IntPtr.Zero); // no file template                 

                if (hOutputFile == INVALID_HANDLE_VALUE)
                {
                    int error = Marshal.GetLastWin32Error();
                    throw new EAException("Output file '" + outputFile + "' cannot be opened error number: " + error, Error.cannotCreateOpenFiles);
                }

                suInfo.hStdOutput = hOutputFile;
            }
            else
            {
                suInfo.hStdOutput = GetStdHandle(STD_OUTPUT_HANDLE);
            }

            //  open an error file
            if (errorFile != null)
            {
                //  if the error file is the same as the output, reuse the output
                if (errorFile == outputFile)
                {
                    suInfo.hStdError = hOutputFile;
                }
                else
                {
                    hErrorFile = CreateFile(errorFile,
                        GENERIC_WRITE, // write to the file
                        FILE_SHARE_READ | FILE_SHARE_WRITE, // share the file for reading and writing                            
                        ref security_attributes_error,   // has bInheritHandle = true     
                        OPEN_ALWAYS,     // always open the file if it exists, else create
                        FILE_ATTRIBUTE_NORMAL,   // normal file     
                        IntPtr.Zero); // no file template                 

                    if (hErrorFile == INVALID_HANDLE_VALUE)
                    {
                        int error = Marshal.GetLastWin32Error();
                        throw new EAException("Error file '" + errorFile + "' cannot be opened error number: " + error, Error.cannotCreateOpenFiles);
                    }
                    suInfo.hStdError = hErrorFile;
                }
            }
            else
            {
                suInfo.hStdError = GetStdHandle(STD_ERROR_HANDLE);
            }

            // open an input file
            if (inputFile != null)
            {
                hInputFile = CreateFile(inputFile,
                    GENERIC_READ, // write to the file
                    FILE_SHARE_READ, // share the file for reading and writing                            
                    ref security_attributes_input,   // has bInheritHandle = true     
                    OPEN_EXISTING,     // always open the file if it exists, else create
                    FILE_ATTRIBUTE_NORMAL,   // normal file     
                    IntPtr.Zero); // no file template   

                if (hInputFile == INVALID_HANDLE_VALUE)
                {
                    int error = Marshal.GetLastWin32Error();
                    throw new EAException("Input file '" + inputFile + "' cannot be opened error number: " + error, Error.cannotCreateOpenFiles);
                }
                suInfo.hStdInput = hInputFile;
            }
            else
            {
                suInfo.hStdInput = GetStdHandle(STD_INPUT_HANDLE);
            }
        }

        /// <summary>
        ///     Creates a process and logs "PROCESS START" as one transacted step
        ///     NOTE: Always called while holding the ApplicationMonitor lock.
        /// </summary>
        /// <returns>false if there was a resource failure</returns>
        private bool CommonActivationRoutine(
            string processToStart)
        {
            Debug.Assert(m_configRec != null);

            STARTUPINFO suInfo = new STARTUPINFO();
            PROCESS_INFORMATION pInfo = new PROCESS_INFORMATION();
            FILETIME ftCreation = new FILETIME();
            FILETIME ftExit = new FILETIME();
            FILETIME ftKernel = new FILETIME();
            FILETIME ftUser = new FILETIME();

            suInfo.cb = (uint)Marshal.SizeOf(typeof(STARTUPINFO));
            suInfo.dwFlags = STARTF_USESTDHANDLES;

            // It is recommended to use the Marshal.SizeOf  function if already in unsafe code.
            // this can be called from a safe context

            uint hInputFile = INVALID_HANDLE_VALUE;
            uint hOutputFile = INVALID_HANDLE_VALUE;
            uint hErrorFile = INVALID_HANDLE_VALUE;

            try
            {
                try
                {
                    // redirect the standard i/o
                    CreateFilesForRedirection(
                        ref suInfo,
                        ref hOutputFile,
                        ref hErrorFile,
                        ref hInputFile);

                    // create the process in suspended mode
                    uint CreationFlags = NORMAL_PRIORITY_CLASS | CREATE_SUSPENDED;
                    if (m_configRec.m_hasConsole)
                        CreationFlags |= CREATE_NEW_CONSOLE;
                    else
                        CreationFlags |= DETACHED_PROCESS;

                    bool ok = CreateProcess(
                        null,
                        String.Format(processToStart),
                        IntPtr.Zero,
                        IntPtr.Zero,
                        true,
                        CreationFlags,
                        IntPtr.Zero,
                        null,
                        ref suInfo,
                        ref pInfo);

                    if (!ok)
                    {
                        int err = Marshal.GetLastWin32Error();
                        Global.WriteDebugInfo(String.Format("Create process '" + processToStart + "' failed. Error: {0}", err));

                        // check if process creation failed because of 'Out of Resources'
                        if (err == ERR_NOT_ENOUGH_MEM || err == ERR_OUTOFMEM || err == ERR_OUT_OF_STRUCTURES ||
                            err == ERR_NO_PROC_SLOTS || err == ERR_IS_JOIN_PATH || err == ERR_TOO_MANY_TCBS ||
                            err == ERR_MAX_THRDS_REACHED || err == ERR_NO_SYSTEM_RESOURCES)
                        {
                            m_error = "Out of memory error: " + err.ToString();
                            return false;
                        }
                        else // failed because of some other reason like File Not Found/Access Denied
                        {
                            throw new EAException("Error: " + err, Error.cannotStartProcess);
                        }
                    }
                }
                catch (Exception e)
                {
                    throw new EAException("Failed to create process: '" + processToStart + "' (" + e.Message + ").", Error.cannotStartProcess, e);
                }
                finally
                {
                    //  close all the redirected handles
                    if (hInputFile != INVALID_HANDLE_VALUE)
                        CloseHandle(hInputFile);
                    if (hOutputFile != INVALID_HANDLE_VALUE)
                        CloseHandle(hOutputFile);
                    if (hErrorFile != INVALID_HANDLE_VALUE && hErrorFile != hOutputFile)
                        CloseHandle(hErrorFile);
                }

                //  log process start
                Process process = Process.GetProcessById((int)pInfo.nProcessId);

                GetProcessTimes(pInfo.hProcess, ref ftCreation, ref ftExit, ref ftKernel, ref ftUser);
                process.EnableRaisingEvents = true;

                ExitedFunc ef = new ExitedFunc();
                EventHandler x = new EventHandler(ef.ExitedFunctionCallBack);
                ProcessData pD = new ProcessData((int)pInfo.nProcessId, ftCreation.dwHighDateTime, ftCreation.dwLowDateTime);
                ef.m_appMon = this;
                ef.m_processData = pD;

                Global.LogMgr.StartProcess(m_configRec, pD);

                process.Exited += x;

                Global.WriteDebugInfo("Process '" + processToStart + "' started with pid: " + process.Id);

                try
                {
                    //  now resume the process
                    ResumeThread(pInfo.hThread);
                }
                catch (Exception e)
                {
                    m_error = Marshal.GetLastWin32Error().ToString ();
                    throw new EAException("Cannot resume process: '" + processToStart + "'", Error.cannotStartProcess, e);
                }
            }
            catch (Exception e)
            {
                TerminateProcess(pInfo.hProcess, 10);
                throw e;
            }
            finally
            {
                CloseHandle(pInfo.hThread);
                CloseHandle(pInfo.hProcess);
            }
            return true;
        }

        /// <summary>
        /// Deals with ended processes
        /// </summary>
        /// <param name="ef"></param>
        private void ProcessEnded(
            ExitedFunc ef)
        {
            lock (this)
            {
                //  verify that if nobody else has reported process died
                if (ef.m_appMon != null)
                {
                    //  report that process died
                    ef.m_appMon = null;
                    m_currentNumberOfInstances--;
                    Global.LogMgr.EndProcess(ef.m_processData);
                    Global.WriteDebugInfo("Process with pid: " + ef.m_processData.Pid + " died.");
                }
            }

            //  see if we need to start more processes
            ActivateIfFallingBelowMinimum();
        }
        #endregion

        #region Properties
        private string m_sqlServer; // the name of the SQL Server, Database and Queue the application being activated
        public string SQLServer
        {
            get { return m_sqlServer; }
        }

        private string m_database;	 // is receiving messages from
        public string Database
        {
            get { return m_database; }
        }

        private string m_schema;
        public string Schema
        {
            get { return m_schema; }
        }

        private string m_queue;
        public string Queue
        {
            get { return m_queue; }
        }

        #endregion

        #region Members
        // for a configuration record that no longer exists in the configuration
        // record table
        private int m_currentNumberOfInstances;
        private int m_startedProcesses;
        private DateTime m_lastStart;
        private bool m_missedNotification;
        private bool m_outOfMemory;
        private ConfigurationRecord m_configRec;
        private bool m_enabled;
        private string m_error;
        private string m_keyAsSQL;
        #endregion

        #region Constants
		private static readonly int ERR_NOT_ENOUGH_MEM			=    8;
		private static readonly int ERR_OUTOFMEM				=   14;
		private static readonly int ERR_OUT_OF_STRUCTURES		=   84;
		private static readonly int ERR_NO_PROC_SLOTS			=   89;
		private static readonly int ERR_IS_JOIN_PATH			=  147;
		private static readonly int ERR_TOO_MANY_TCBS			=  155;
		private static readonly int ERR_MAX_THRDS_REACHED		=  164;
		private static readonly int ERR_NO_SYSTEM_RESOURCES		= 1450;	
        #endregion
    }

    /// <summary>
    ///		Used to store information about process and eventHandler so that it can
    ///		be unregistered at a later stage and also used to store information
    ///		for HashTable
    /// </summary>
    public class ProcessData
    {
        #region Constructors
        public ProcessData(int pid, uint creationHighDateTime, uint creationLowDateTime)
        {
            m_pid = pid;
            m_creationHighDateTime = creationHighDateTime;
            m_creationLowDateTime = creationLowDateTime;
        }
        #endregion

        #region Methods
        public override bool Equals(object obj)
        {
            bool equal = false;
            ProcessData other = (ProcessData)obj;
            if (other.m_pid == this.m_pid &&
                other.m_creationHighDateTime == this.m_creationHighDateTime &&
                other.m_creationLowDateTime == this.m_creationLowDateTime)
                equal = true;
            return equal;
        }

        public override int GetHashCode()
        {
            return ((m_pid + (int)m_creationLowDateTime) % MAX_HASH_VALUE);
        }
        #endregion

        #region Properties
        private int m_pid;
        public int Pid
        {
            get { return m_pid; }
        }

        private uint m_creationHighDateTime;
        public uint CreationHighDateTime
        {
            get { return m_creationHighDateTime; }
        }

        private uint m_creationLowDateTime;
        public uint CreationLowDateTime
        {
            get { return m_creationLowDateTime; }
        }
        #endregion

        #region Constants
        private static readonly int MAX_HASH_VALUE = 1001;
        #endregion
    }

    /// <summary>
    ///		Used for XML Serialization/Deserialization. It is used to store information
    ///		about process start.  
    /// </summary>
	public class StartProcess
	{
        public int ProcessId;
        public uint CreationHighDateTime;
        public uint CreationLowDateTime;
		public string SQLServer; // Name of SQLServer instance, Database, Queue, AppName, StartUpData
		public string Database;  // are useful when adding to the ApplicationMonitorTable during recovery. 
        public string Schema;
		public string Queue;
		public string ApplicationName; 
		public string StartUpData; // same as command-line arguments
	}


    /// <summary>
    ///		Table that contains the Application Monitors for the corresponding
    ///		(SQL Server, DB, Q) key
    /// </summary>
	class ApplicationMonitorManager
    {
        #region Methods
        /// <summary>
        /// Constructor
        /// </summary>
		public ApplicationMonitorManager()
		{
			m_appMT = new Hashtable();
            m_shutdown = false;
		}

        /// <summary>
        /// Retrieves application monitor that corresponds to given SQL Server, Database and Queue
        /// </summary>
        /// <param name="sqlServer"></param>
        /// <param name="database"></param>
        /// <param name="schema"></param>
        /// <param name="queue"></param>
        /// <returns>The applicaion monitor or null if such does not exist</returns>
		public ApplicationMonitor GetApplicationMonitor(
				string sqlServer,
				string database,
                string schema,
				string queue)
		{
            lock (this)
            {
                if (m_shutdown)
                {
                    return null;
                }

                string key = GetKey(sqlServer, database, schema, queue);

                if (m_appMT.ContainsKey(key))
                {
                    return (ApplicationMonitor)m_appMT[key];
                }

                return null;
            }
		}

        /// <summary>
        /// If an application with the same key as configuration record exists then
        /// update it, otherwise create a new one and associate it with the
        /// configuration record
        /// </summary>
        /// <param name="cfr"></param>
        public void InsertOrUpdate(
                ConfigurationRecord cfr)
        {
            lock (this)
            {
                if (m_shutdown)
                {
                    return;
                }

                ApplicationMonitor am;
                string key = GetKey (cfr.m_sqlServer, cfr.m_database, cfr.m_schema, cfr.m_queue);
                if (m_appMT.ContainsKey(key))
                {
                    am = (ApplicationMonitor)(m_appMT[key]);
                    am.SetConfig(cfr);
                }
                else
                {
                    am = new ApplicationMonitor(cfr.m_sqlServer, cfr.m_database, cfr.m_schema, cfr.m_queue, cfr);
                    m_appMT.Add(key, am);
                }
            }
        }

        /// <summary>
        /// Creates Application monitors and attaches them to the processes specified in the hash table
        /// </summary>
        /// <param name="pidHashTable">Hashtable of processes to attach to</param>
        public void AttachToProcesses(
            Hashtable pidHashTable)
        {
            if (pidHashTable != null)
            {
                foreach (DictionaryEntry d in pidHashTable)
                {
                    ApplicationMonitor am;
                    StartProcess sp = (StartProcess)d.Value;

                    // get the max last_msg_queuing_order
                    lock (this)
                    {
                        if (m_shutdown)
                        {
                            return;
                        }

                        string keyValue = GetKey(sp.SQLServer, sp.Database, sp.Schema, sp.Queue);
                        if (m_appMT.ContainsKey(keyValue))
                        {
                            am = (ApplicationMonitor)(m_appMT[keyValue]);
                        }
                        else
                        {
                            am = new ApplicationMonitor(sp.SQLServer, sp.Database, sp.Schema, sp.Queue, null);
                            m_appMT.Add(keyValue, am);
                        }
                    }

                    am.AttachToProcess((ProcessData)(d.Key));
                }
            }

            //  starts the periodic check thread
            Thread startThread = new Thread(new ThreadStart(DoPeriodicCheck));
            startThread.Start();
        }

        /// <summary>
        /// Detaches all Application Monitors from all processes and disables all the
        /// application monitors from future work.
        /// </summary>
		public void Shutdown()
		{
            // NOTHING
		}

        /// <summary>
        ///		Starts up processes if current number of instances is less than the
        ///		Minimum number of instances for all configuration records. If the 
        ///		corresponding Application Monitor is not present in the Application
        ///		Monitor Table, create a new Application Monitor for it. 
        /// </summary>
        public void StartUpAllBelowMinimum()
        {
            Global.WriteDebugInfo("Starting up any applications if number of instances is below minimum");

            ArrayList activateProcessList = GetAllAMs ();

            if (activateProcessList == null)
            {
                return;
            }

            foreach (ApplicationMonitor am in activateProcessList)
            {
                am.ActivateIfFallingBelowMinimum();
            }
        }

        /// <summary>
        /// Reports the status of all the active monitors
        /// </summary>
        public override string ToString()
        {
            ArrayList amList = GetAllAMs ();
            string me = "Monitored applications status";
            foreach (ApplicationMonitor am in amList)
            {
                me += "\n    " + am.ToString();
            }

            return me;
        }
        #endregion

        #region Private methods
        /// <summary>
        /// Removes an application monitor from the hash table
        /// </summary>
        /// <param name="am">Application monitor to remove</param>
        private void TryToRemoveAM(
            ApplicationMonitor am)
        {
            lock (this)
            {
                string key = GetKey(am.SQLServer, am.Database, am.Schema, am.Queue);
                Debug.Assert(m_appMT.ContainsKey(key));

                if (m_shutdown || am.CanBeRemoved())
                {
                    m_appMT.Remove(key);
                }
            }
        }

        /// <summary>
        /// Periodically checks all the existing application monitors for
        /// missed process starts
        /// </summary>
        private void DoPeriodicCheck()
        {
            try
            {
                while (true)
                {
                    //  wait for a while
                    Thread.Sleep(WAIT_TIME);

                    //  try to startup all the aplicatoin monitors that are below minimum
                    Global.WriteDebugInfo("Check for monitored applications that need to start processes.");
                    StartUpAllBelowMinimum();
                }

            }
            catch (Exception e)
            {
                Global.DoHardKill(e);
            }
        }

        /// <summary>
        /// Generates a list of all the application monitors
        /// 
        /// NOTE: can return NULL if the application monitor is shutdown
        /// </summary>
        /// <returns>Returns a list of all the application monitors</returns>
        private ArrayList GetAllAMs()
        {
            ArrayList amList = new ArrayList();
            lock (this)
            {
                if (m_shutdown)
                {
                    return null;
                }

                foreach (DictionaryEntry e in m_appMT)
                {
                    ApplicationMonitor am = (ApplicationMonitor)(e.Value);
                    amList.Add(am);
                }

                return amList;
            }
        }

        /// <summary>
        /// Generates the application monitor key by the given parameters
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
        #endregion

        #region Members
        private Hashtable m_appMT;
        private bool m_shutdown;
        private static readonly int WAIT_TIME = 30000;
        #endregion
    }
}
