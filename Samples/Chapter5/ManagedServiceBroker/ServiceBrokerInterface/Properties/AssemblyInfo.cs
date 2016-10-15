#region Using directives

using System;
using System.Reflection;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;
using System.Security;
using System.Security.Permissions;

#endregion

// General Information about an assembly is controlled through the following 
// set of attributes. Change these attribute values to modify the information
// associated with an assembly.
[assembly: AssemblyTitle("Microsoft.SqlServer.Broker")]
[assembly: AssemblyDescription("Class library for access SQL Service Broker functions from stored procs or external programs")]
[assembly: AssemblyConfiguration("")]
[assembly: AssemblyCompany("Microsoft Corporation")]
[assembly: AssemblyProduct("Microsoft.SqlServer.Broker")]
[assembly: AssemblyCopyright("Copyright © Microsoft Corporation 2005")]
[assembly: AssemblyTrademark("")]
[assembly: AssemblyCulture("")]

// Version information for an assembly consists of the following four values:
//
//      Major Version
//      Minor Version 
//      Build Number
//      Revision
//
// You can specify all the values or you can default the Revision and Build Numbers 
// by using the '*' as shown below:
[assembly: AssemblyVersion("1.0.*")]
[assembly: ComVisible(false)]
[assembly: CLSCompliant(true)]
[assembly: AllowPartiallyTrustedCallers]
[assembly: System.Runtime.ConstrainedExecution.ReliabilityContract(System.Runtime.ConstrainedExecution.Consistency.MayCorruptInstance, System.Runtime.ConstrainedExecution.Cer.None)]
[assembly: System.Security.Permissions.SecurityPermissionAttribute(System.Security.Permissions.SecurityAction.RequestMinimum)]
[assembly: System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Design", "CA1020:AvoidNamespacesWithFewTypes", Scope="namespace", Target="Microsoft.Samples.SqlServer")]

[assembly: System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Globalization", "CA1303:DoNotPassLiteralsAsLocalizedParameters", Scope = "member", Target = "Microsoft.Samples.SqlServer.Conversation..ctor(Microsoft.Samples.SqlServer.Service,System.Guid)", MessageId = "System.ArgumentException.#ctor(System.String)")]
[assembly: System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Performance", "CA1805:DoNotInitializeUnnecessarily", Scope = "member", Target = "Microsoft.Samples.SqlServer.Service..ctor(System.String,System.Data.SqlClient.SqlConnection,System.Data.SqlClient.SqlTransaction)")]
[assembly: System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Globalization", "CA1303:DoNotPassLiteralsAsLocalizedParameters", Scope = "member", Target = "Microsoft.Samples.SqlServer.Service..ctor(System.String,System.Data.SqlClient.SqlConnection,System.Data.SqlClient.SqlTransaction)", MessageId = "System.ArgumentException.#ctor(System.String)")]
[assembly: System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Design", "CA1062:ValidateArgumentsOfPublicMethods", Scope = "member", Target = "Microsoft.Samples.SqlServer.Service..ctor(System.String,System.Data.SqlClient.SqlConnection,System.Data.SqlClient.SqlTransaction)")]
[assembly: System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Globalization", "CA1303:DoNotPassLiteralsAsLocalizedParameters", Scope = "member", Target = "Microsoft.Samples.SqlServer.Service.GetConversation(Microsoft.Samples.SqlServer.Conversation,System.Data.SqlClient.SqlConnection,System.Data.SqlClient.SqlTransaction):Microsoft.Samples.SqlServer.Conversation", MessageId = "System.InvalidOperationException.#ctor(System.String)")]
[assembly: System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Design", "CA1062:ValidateArgumentsOfPublicMethods", Scope = "member", Target = "Microsoft.Samples.SqlServer.Service.GetConversation(Microsoft.Samples.SqlServer.Conversation,System.Data.SqlClient.SqlConnection,System.Data.SqlClient.SqlTransaction):Microsoft.Samples.SqlServer.Conversation")]
[assembly: System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Performance", "CA1805:DoNotInitializeUnnecessarily", Scope = "member", Target = "Microsoft.Samples.SqlServer.Service+MessageReader..ctor(Microsoft.Samples.SqlServer.Service)")]
[assembly: System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Design", "CA1062:ValidateArgumentsOfPublicMethods", Scope = "member", Target = "Microsoft.Samples.SqlServer.ServiceException..ctor(Microsoft.Samples.SqlServer.Conversation,System.Data.SqlClient.SqlConnection,System.Data.SqlClient.SqlTransaction,System.Exception)")]
