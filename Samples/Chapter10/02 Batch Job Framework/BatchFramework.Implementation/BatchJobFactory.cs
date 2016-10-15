using System;
using System.Text;
using System.Data;
using System.Data.SqlClient;
using System.Collections.Generic;
using System.Reflection;
using System.Globalization;
using BatchFramework.Interfaces;

namespace BatchFramework.Implementation
{
    /// <summary>
    /// Factory class for retrieving the concrete instance of the Job Server Task that must be executed.
    /// </summary>
    public static class BatchJobFactory
    {
        /// <summary>
        /// Factory method that retrieves the concrete instance of the Job Server Task.
        /// </summary>
        /// <param name="TaskName">TaskName of the request message. This namespace is matched through a lookup table with the coresponding CLR class 
        /// implementing the concrete Job Server Task</param>
        /// <returns></returns>
        public static IBatchJob GetBatchJobTask(string TaskName, SqlConnection Connection)
        {
            SqlCommand cmd = new SqlCommand(
                "SELECT CLRTypeName FROM BatchJobs WHERE BatchJobType = @BatchJobType",
                Connection);

            cmd.Parameters.Add("@BatchJobType", SqlDbType.NVarChar, 255);
            cmd.Parameters["@BatchJobType"].Value = TaskName;

            SqlDataReader reader = cmd.ExecuteReader();

            if (reader.Read())
            {
                string typeName = (string)reader["CLRTypeName"];
                reader.Close();

                return InstantiateBatchJob(typeName);
            }
            else
                throw new ArgumentException("The given BatchJobType was not found.", TaskName);
        }

        private static IBatchJob InstantiateBatchJob(string fqAssemblyName)
        {
            if (null == fqAssemblyName || fqAssemblyName.Length == 0)
                throw new ArgumentException("AssemblyName parameter cannot be null or empty", fqAssemblyName);

            Type type = Type.GetType(fqAssemblyName);

            if (null == type)
            {
                throw new ArgumentException(string.Format(
                    CultureInfo.InvariantCulture, "Requested type {0} not found, unable to load", fqAssemblyName),
                    "fqAssemblyName");
            }

            ConstructorInfo ctor = type.GetConstructor(new Type[] { });

            IBatchJob task = (IBatchJob)ctor.Invoke(new object[] { });

            return task;
        }
    }
}