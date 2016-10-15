using System;
using System.Xml;
using System.Text;
using System.Data;
using System.Data.SqlClient;
using System.Collections.Generic;
using Microsoft.SqlServer.Server;
using BatchFramework.Interfaces;

namespace BatchFramework.TicketReservationTask
{
    public class TicketReservationTask : IBatchJob
    {
        /// <summary>
        /// Implements the reservation of a flight ticket.
        /// </summary>
        /// <param name="Message"></param>
        /// <param name="ConversationHandle"></param>
        /// <param name="Connection"></param>
        public void Execute(System.Data.SqlTypes.SqlXml Message, Guid ConversationHandle, SqlConnection Connection)
        {
            XmlDocument doc = new XmlDocument();
            doc.LoadXml(Message.Value);

            try
            {
                // Construct the SqlCommand
                SqlCommand cmd = new SqlCommand("INSERT INTO FlightTickets (ID, [From], [To], FlightNumber, Airline, Departure, Arrival) VALUES ("
                    + "@ID, @From, @To, @FlightNumber, @Airline, @Departure, @Arrival)", Connection);
                cmd.Parameters.Add(new SqlParameter("@ID", SqlDbType.UniqueIdentifier));
                cmd.Parameters.Add(new SqlParameter("@From", SqlDbType.NVarChar));
                cmd.Parameters.Add(new SqlParameter("@To", SqlDbType.NVarChar));
                cmd.Parameters.Add(new SqlParameter("@FlightNumber", SqlDbType.NVarChar));
                cmd.Parameters.Add(new SqlParameter("@Airline", SqlDbType.NVarChar));
                cmd.Parameters.Add(new SqlParameter("@Departure", SqlDbType.NVarChar));
                cmd.Parameters.Add(new SqlParameter("@Arrival", SqlDbType.NVarChar));
                cmd.Parameters["@ID"].Value = Guid.NewGuid();
                cmd.Parameters["@From"].Value = doc.GetElementsByTagName("From").Item(0).InnerText;
                cmd.Parameters["@To"].Value = doc.GetElementsByTagName("To").Item(0).InnerText;
                cmd.Parameters["@FlightNumber"].Value = doc.GetElementsByTagName("FlightNumber").Item(0).InnerText;
                cmd.Parameters["@Airline"].Value = doc.GetElementsByTagName("Airline").Item(0).InnerText;
                cmd.Parameters["@Departure"].Value = doc.GetElementsByTagName("Departure").Item(0).InnerText;
                cmd.Parameters["@Arrival"].Value = doc.GetElementsByTagName("Arrival").Item(0).InnerText;

                // Execute the query
                cmd.ExecuteNonQuery();
            }
            finally
            {
                // End the ongoing conversation between the two services
                new ServiceBroker(Connection).EndDialog(ConversationHandle);
            }
        }
    }
}