using System;
using System.Text;
using System.Data;
using System.Data.SqlClient;
using System.Collections.Generic;
using System.Reflection;
using System.Globalization;
using JobServer.Interfaces;

namespace JobServer.Implementation
{
	/// <summary>
	/// Factory class for retrieving the concrete instance of the Job Server Task that must be executed.
	/// </summary>
	public static class JobServerFactory
	{
		/// <summary>
		/// Factory method that retrieves the concrete instance of the Job Server Task.
		/// </summary>
		/// <param name="MessageType">Namespace of the request message. This namespace is matched through a lookup table with the coresponding CLR class 
		/// implementing the concrete Job Server Task</param>
		/// <returns></returns>
		public static IJobServerTask GetJobServerTask(string MessageType)
		{
			SqlConnection cnn = new SqlConnection("context connection=true");

			try
			{
				SqlCommand cmd = new SqlCommand("SELECT TypeName FROM JobServerTasks WHERE MessageType = @MessageType", cnn);
				cmd.Parameters.Add("@MessageType", SqlDbType.NVarChar, 255);
				cmd.Parameters["@MessageType"].Value = MessageType;

				cnn.Open();
				SqlDataReader reader = cmd.ExecuteReader();

				if (reader.Read())
				{
					string typeName = (string)reader["TypeName"];
					reader.Close();

					return InstantiateJobTask(typeName);
				}
				else
					throw new ArgumentException("The given MessageType was not found.", MessageType);
			}
			finally
			{
				cnn.Close();
			}
		}

		private static IJobServerTask InstantiateJobTask(string fqAssemblyName)
		{
			if (null == fqAssemblyName || fqAssemblyName.Length == 0)
				throw new ArgumentException("AssemblyName parameter cannot be null or empty", fqAssemblyName);

			Type type = Type.GetType(fqAssemblyName);

			if (null == type)
			{
				throw new ArgumentException(string.Format(CultureInfo.InvariantCulture, "Requested type {0} not found, unable to load", fqAssemblyName), "fqAssemblyName");
			}

			ConstructorInfo ctor = type.GetConstructor(new Type[] { });

			IJobServerTask task = (IJobServerTask)ctor.Invoke(new object[] { });

			return task;
		}
	}
}