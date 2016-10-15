#region Using
using Microsoft.Win32;
using System;
using System.Collections;
using System.ComponentModel;
using System.Configuration.Install;
using System.Diagnostics;
using System.IO;
using System.Runtime.InteropServices;
using System.ServiceProcess;
using System.Threading;
#endregion

namespace ExternalActivator
{
    /// <summary>
    /// Installer to be used while installing this service
    /// </summary>
	[RunInstaller(true)]
	public class ProjectInstaller : System.Configuration.Install.Installer
	{
		public ProjectInstaller(string svcname, string username, string password)
		{
            System.ServiceProcess.ServiceProcessInstaller serviceProcessInstaller = new System.ServiceProcess.ServiceProcessInstaller();
            System.ServiceProcess.ServiceInstaller serviceInstaller = new System.ServiceProcess.ServiceInstaller();

            //  check for special users as localsystem, networkservice and localservice
            if (username == null || username.ToLower() == "localsystem")
            {
                serviceProcessInstaller.Account = System.ServiceProcess.ServiceAccount.LocalSystem;
            }
            else if (username.ToLower() == "networkservice")
            {
                serviceProcessInstaller.Account = System.ServiceProcess.ServiceAccount.NetworkService;
            }
            else if (username.ToLower() == "localservice")
            {
                serviceProcessInstaller.Account = System.ServiceProcess.ServiceAccount.LocalService;
            }
            else
            {
                serviceProcessInstaller.Account = System.ServiceProcess.ServiceAccount.User;
                serviceProcessInstaller.Username = username;
                serviceProcessInstaller.Password = password;
            }

			serviceInstaller.ServiceName = svcname;
            serviceInstaller.StartType = System.ServiceProcess.ServiceStartMode.Automatic;
            serviceInstaller.Description = "Service broker external activator";
            serviceInstaller.DisplayName = "External Activator - " + svcname;

			Installers.AddRange(new System.Configuration.Install.Installer[] {serviceProcessInstaller, serviceInstaller});
		}
	}


    /// <summary>
    ///		Used to provide the initialization and cleanup routines called in the case
    ///		where the External Activation is started as a service. Also provides functions
    ///		for installing and uninstalling the Windows NT Service
    /// </summary>
    class NTService : System.ServiceProcess.ServiceBase
    {
        /// <summary>
        //	Initializes the Windows NT Service to contain its name. Also sets properties
        //	of the NT Service. 
        /// </summary>
        /// <param name="serviceName">The name of the service</param>
        public NTService(string serviceName)
        {
            this.ServiceName = serviceName;
            this.CanHandlePowerEvent = false;
            this.CanPauseAndContinue = false;
            this.CanShutdown = true;
            this.CanStop = true;
            this.AutoLog = true;
        }

        /// <summary>
        //	Installs the Windows NT Service. Uses a transacted installer, so that
        //	if installation fails midstream for some reason, installation is rolled
        //	back. Post installation, the registry settings for the service are modified
        //	to change the command-line parameters (because currently, CLR does not allow it)
        //	If registry modification fails for some reason, uninstall is called on the service.
        /// </summary>
        /// <param name="svcname">Service to install</param>
        /// <param name="username">User name to execute under</param>
        /// <param name="password">Password of the user</param>
        public static void Install(
                string svcname,
                string username,
                string password)
        {
            bool doUninstall = false;

            try
            {
                Global.WriteStatus("External Activator is installing as NT service '" + svcname + "' ...");
                TransactedInstaller ti = new TransactedInstaller();

                // Sets information required for installing (might get username and password information from the user)
                ProjectInstaller mi = new ProjectInstaller(svcname, username, password);
                ti.Installers.Add(mi);
                String path = String.Format("/assemblypath={0}",
                    System.Reflection.Assembly.GetExecutingAssembly().Location);
                String[] cmdline = { path };
                InstallContext ctx = new InstallContext(String.Format(svcname + ".InstallLog"), cmdline);
                ti.Context = ctx;

                // Starts the installation process
                ti.Install(new Hashtable());
                doUninstall = true;

                // Registry modification of Command-Line arguments to include (-svc) followed by the service name 
                // to install it as a particular External Activator.
                RegistryKey key = Registry.LocalMachine.OpenSubKey(String.Format("System\\CurrentControlSet\\Services\\{0}", svcname), true);
                object ImagePathObject = key.GetValue("ImagePath");
                if (ImagePathObject != null)
                {
                    Global.WriteDebugInfo("Modifying the registry to include command-line parameters after installation.");
                    string ImagePath = String.Format("{0} /{1}:{2}", (string)ImagePathObject, CommandLineArgument.RunAsNTServiceArgument, svcname);
                    key.SetValue("ImagePath", ImagePath);
                }
                else
                {
                    // Calls Uninstall if registry modification not possible
                    throw new EAException("Critical Error : Could not open ImagePath key of NT service '" + svcname + "' in the registry. Uninstalling service", Error.postInstallProblem);
                }
                Global.WriteStatus("External Activator is successfully installed as NT service '" + svcname + "' ...");
            }
            catch (Exception e)
            {
                if (doUninstall)
                {
                    try
                    {
                        NTService.Uninstall(svcname);
                    }
                    catch (Exception eNested)
                    {
                        EAException.Report(eNested);
                    }
                }
                throw new EAException("External Activation Installation failed", Error.installProblem, e);
            }
        }

        /// <summary>
        //	Uninstalls the Windows NT Service. Uses a transacted installer, so that
        //	if installation fails midstream for some reason, installation is rolled
        //	back.
        /// </summary>
        /// <param name="svcname">Service to uninstall</param>
        public static void Uninstall(string svcname)
        {
            try
            {
                Global.WriteStatus("External Activator is uninstalling service " + svcname + "...");
                TransactedInstaller ti = new TransactedInstaller();
                ProjectInstaller mi = new ProjectInstaller(svcname, null, null);
                ti.Installers.Add(mi);
                String path = String.Format("/assemblypath={0}",
                    System.Reflection.Assembly.GetExecutingAssembly().Location);
                String[] cmdline = { path };
                InstallContext ctx = new InstallContext(String.Format(svcname + ".InstallLog"), cmdline);
                ti.Context = ctx;
                ti.Uninstall(null);
                Global.WriteStatus("External Activator service '" + svcname + "' uninstaled successfully.");
            }
            catch (Exception e)
            {
                throw new EAException("External Activator service '" + svcname + "' uninstalling failed!", Error.unexpectedError, e);
            }
        }

        /// <summary>
        /// Starts a new instance of the Windows NT Service
        /// </summary>
        /// <param name="serviceName"></param>
        public static void MainFunction(
            string serviceName)
        {
            System.ServiceProcess.ServiceBase[] ServicesToRun;

            // More than one user Service may run within the same process. To add
            // another service to this process, change the following line to
            // create a second service object. For example,
            //
            //   ServicesToRun = New System.ServiceProcess.ServiceBase[] {new EAService(), new MySecondUserService()};
            //
            ServicesToRun = new System.ServiceProcess.ServiceBase[] { new NTService(serviceName) };
            System.ServiceProcess.ServiceBase.Run(ServicesToRun);
        }

        public static void Execute(string service, int i)
        {
            ServiceController sc = new ServiceController(service);
            try
            {
                Console.WriteLine(sc.DisplayName + " " + sc.Status);
                sc.ExecuteCommand(i);
            }
            catch (Exception e)
            {
                Console.WriteLine(e.Message);
            }
        }

        /// <summary>
        ///		Performs necessary initialization of the External Activation NT Service so that it can start
        ///		doing its work. 
        /// </summary>
        /// <param name="args"></param>
        protected override void OnStart(
            string[] args) // I		optional startup arguments
        {
            try
            {
                if (Global.Shutdown == false)
                {
                    Global.BootExternalActivator();
                    return;
                }
            }
            catch (Exception e)
            {
                Global.SetShutdown();
                EAException.Report(e);
            }

            StopService(new ServiceController(this.ServiceName), new TimeSpan(1));
            return;
        }

        /// <summary>
        /// Processes SC custom control commands
        /// </summary>
        /// <param name="command">custom command id</param>
        protected override void OnCustomCommand(int command)
        {
            Global.ProcessSCCommand (command);
        }

        /// <summary>
        /// Performs cleanup of the External Activation NT Service 
        /// </summary>
        protected override void OnStop()
        {
            if (Global.SetShutdown() == true)
            {
                return;
            }

            Thread cleanupThread = new Thread(new ThreadStart(Global.Cleanup));
            cleanupThread.Start();
            return;
        }

        /// <summary>
        /// Stops the service 
        /// </summary>
        /// <param name="service"></param>
        /// <param name="timeOut"></param>
        private static void StopService(
            ServiceController service, // I		Service Controller object for the corresponding service name
            TimeSpan timeOut) // I				time to wait while checking for status
        {
            Debug.Assert(service != null);

            // Service with a given display name is found, check for its state and act correspondingly

            for (; ; )
            {
                switch (service.Status)
                {
                    case ServiceControllerStatus.PausePending:
                        service.WaitForStatus(ServiceControllerStatus.Paused, timeOut);
                        break;

                    case ServiceControllerStatus.Running:
                    case ServiceControllerStatus.Paused:
                        service.Stop();
                        service.WaitForStatus(ServiceControllerStatus.Stopped, timeOut);
                        break;

                    case ServiceControllerStatus.StopPending:
                        service.WaitForStatus(ServiceControllerStatus.Stopped, timeOut);
                        break;

                    case ServiceControllerStatus.ContinuePending:
                    case ServiceControllerStatus.StartPending:
                        service.WaitForStatus(ServiceControllerStatus.Running, timeOut);
                        break;

                    case ServiceControllerStatus.Stopped:
                        return;

                    default:
                        // can't log because this might be called in cases of HardKill
                        // don't care about logging error because it's stopping the service anyway
                        Global.WriteError("Invalid state of the NT service");
                        return;
                }
            }
        }
    }
}
