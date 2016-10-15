using System;
using System.Collections.Generic;
using System.Text;
using System.Data.SqlClient;
using System.IO;
using System.Xml;
using System.Data;
using System.Xml.Serialization;
using System.Net;
using Microsoft.SqlServer.Server;
using System.Text.RegularExpressions;
using System.Data.SqlTypes;

namespace Microsoft.Samples.SqlServer
{
    internal enum RequestFilterAction
    {
        Deny = 0,
        Accept = 1
    }

    internal enum ResponseFilterAction
    {
        Respond = 0,
        Retry = 1,
        Error = 2
    }

    public class WebProxyService : Service
    {
        #region constants
        private const string x_serviceName = "WebProxyService";
        private const string x_httpRequestMessageType = "http://ssb.csharp.at/SSB_Book/c10/HttpRequestMessageType";
        private const string x_httpResponseMessageType = "http://ssb.csharp.at/SSB_Book/c10/HttpResponseMessageType";
        #endregion

        #region member fields
        private SqlConnection s_connection;
        private SqlTransaction s_transaction;
        private Conversation s_currentConversation;
        private Message s_msgReceived;
        private TimeSpan m_timeout;
        private int m_numRetries;
        private int m_numRetriesUsed;
        private int m_retryDelay;
        private float m_backoffFactor;
        private string m_lastError;
        #endregion

        #region c'tor
        public WebProxyService(SqlConnection conn)
            : base(x_serviceName, conn)
        {
            FetchSize = 1;
            WaitforTimeout = TimeSpan.FromSeconds(2);
            m_timeout = TimeSpan.FromSeconds(3);
            m_numRetriesUsed = 0;
            m_numRetries = 3;
            m_retryDelay = 30;
            m_backoffFactor = 1;
        }
        #endregion

        #region broker methods

        [BrokerMethod(Message.EndDialogType)]
        public void OnEndDialog(
            Message msgReceived,
            SqlConnection connection,
            SqlTransaction transaction)
        {
            s_connection = connection;
            s_transaction = transaction;
            s_currentConversation = msgReceived.Conversation;
            s_msgReceived = msgReceived;

            EndConversation();
        }

        [BrokerMethod(WebProxyService.x_httpRequestMessageType)]
        public void OnHttpRequest(
            Message msgReceived,
            SqlConnection connection,
            SqlTransaction transaction)
        {
            s_connection = connection;
            s_transaction = transaction;
            s_currentConversation = msgReceived.Conversation;
            s_msgReceived = msgReceived;

            try
            {
                XmlSerializer xs = new XmlSerializer(typeof(httpRequestType));
                httpRequestType request = (httpRequestType)xs.Deserialize(msgReceived.Body);
                ServiceRequest(request);
            }
            catch (Exception e)
            {
                SqlContext.Pipe.Send(e.StackTrace);

                if (connection.State == ConnectionState.Open)
                {
                    msgReceived.Conversation.EndWithError(1, e.Message + "\n" + e.StackTrace, connection, transaction);
                }
            }
        }

        [BrokerMethod(Message.DialogTimerType)]
        public void OnTimer(
            Message msgReceived,
            SqlConnection connection,
            SqlTransaction transaction)
        {
            s_connection = connection;
            s_transaction = transaction;
            s_currentConversation = msgReceived.Conversation;
            s_msgReceived = msgReceived;

            httpRequestType pendingRequest = GetPendingRequest();

            if (pendingRequest == null)
            {
                ErrorConversation(6, "Your pending request was mysteriously lost.");
                return;
            }

            SqlContext.Pipe.Send("retrieved: " + pendingRequest.url);
            SqlContext.Pipe.Send("num used: " + m_numRetriesUsed);
            ServiceRequest(pendingRequest);
        }
        #endregion

        private void DeletePendingRequest()
        {
            SqlCommand cmd = s_connection.CreateCommand();
            cmd.CommandText = "DELETE FROM PendingRequest WHERE ConversationHandle = @ConversationHandle";
            cmd.CommandType = CommandType.Text;
            cmd.Transaction = s_transaction;
            cmd.Parameters.Add(new SqlParameter("@ConversationHandle", s_currentConversation.Handle));
            cmd.ExecuteNonQuery();
        }

        #region private methods
        private void ServiceRequest(httpRequestType incomingRequest)
        {
            RequestFilterAction reqAction = MatchRequestFilter(incomingRequest);

            switch (reqAction)
            {
                case RequestFilterAction.Deny:
                    ErrorConversation(2, "Proxy does not accept this type of request to given URL.");
                    return;
            }

            HttpWebRequest outgoingRequest = CreateWebRequest(incomingRequest);

            if (outgoingRequest == null)
            {
                SavePendingRequest(incomingRequest);
                BeginTimer();
                return;
            }

            HttpWebResponse incomingResponse = null;
            ResponseFilterAction respAction = TryWebRequest(outgoingRequest, out incomingResponse);
            SqlContext.Pipe.Send(respAction.ToString());

            switch (respAction)
            {
                case ResponseFilterAction.Respond:
                    httpResponseType outgoingResponse = CreateBrokerResponse(incomingResponse);
                    SendResponse(outgoingResponse);
                    EndConversation();

                    // Deletes the pending request, if there was one stored...
                    DeletePendingRequest();
                    break;

                case ResponseFilterAction.Retry:
                    if (m_numRetries == m_numRetriesUsed)
                    {
                        ErrorConversation(5, m_lastError);
                    }
                    else
                    {
                        SavePendingRequest(incomingRequest);
                        BeginTimer();
                    }
                    break;

                case ResponseFilterAction.Error:
                    if (incomingResponse != null)
                    {
                        ErrorConversation(4, m_lastError);
                    }
                    break;
            }
        }

        private HttpWebRequest CreateWebRequest(httpRequestType incomingRequest)
        {
            HttpWebRequest outgoingRequest;

            outgoingRequest = (HttpWebRequest)HttpWebRequest.Create(incomingRequest.url);
            outgoingRequest.Method = incomingRequest.method;
            outgoingRequest.Timeout = (int) m_timeout.TotalMilliseconds;

            if (incomingRequest.protocolVersion != null)
            {
                try
                {
                    string[] s = incomingRequest.protocolVersion.Split(new char[] { '/' });

                    if (s.Length > 1)
                    {
                        outgoingRequest.ProtocolVersion = new Version(s[1]);
                    }
                }
                catch
                { }
            }

            outgoingRequest.ContentLength = incomingRequest.body.Length;

            if (incomingRequest.headers != null)
            {
                foreach (headerType h in incomingRequest.headers)
                {
                    SqlContext.Pipe.Send(h.name + ": " + h.value);

                    switch (h.name.ToLowerInvariant())
                    {
                        case "host":
                        case "date":
                        case "range":
                            break;

                        case "accept":
                            outgoingRequest.Accept = h.value;
                            break;

                        case "connection":
                            outgoingRequest.Connection = h.value;
                            break;

                        //case "content-length":
                        //    outgoingRequest.ContentLength = Int32.Parse(h.value);
                        //    break;

                        case "content-type":
                            outgoingRequest.ContentType = h.value;
                            break;

                        case "expect":
                            outgoingRequest.Expect = h.value;
                            break;

                        case "if-modified-since":
                            outgoingRequest.IfModifiedSince = DateTime.Parse(h.value);
                            break;

                        case "referer":
                            outgoingRequest.Referer = h.value;
                            break;

                        case "transfer-encoding":
                            outgoingRequest.TransferEncoding = h.value;
                            break;

                        case "user-agent":
                            outgoingRequest.UserAgent = h.value;
                            break;

                        default:
                            outgoingRequest.Headers[h.name] = h.value;
                            break;
                    }
                }
            }

            byte[] buffer = incomingRequest.body;

            if (buffer != null && buffer.Length > 0)
            {
                try
                {
                    Stream body = outgoingRequest.GetRequestStream();
                    body.Write(buffer, 0, buffer.Length);
                    body.Close();
                }
                catch (WebException we)
                {
                    // The web service isn't available
                    m_lastError = we.Message;

                    return null;
                }
            }

            return outgoingRequest;
        }

        private RequestFilterAction MatchRequestFilter(httpRequestType incomingRequest)
        {
            SqlCommand cmd = s_connection.CreateCommand();
            cmd.CommandText = "sp_MatchRequestFilter";
            cmd.CommandType = CommandType.StoredProcedure;
            cmd.Transaction = s_transaction;

            SqlParameter prmMethod = cmd.Parameters.AddWithValue("@Method", incomingRequest.method);
            SqlParameter prmUrl = cmd.Parameters.AddWithValue("@Url", incomingRequest.url);
            SqlDataReader reader = cmd.ExecuteReader();

            if (!reader.Read())
            {
                reader.Close();
                return RequestFilterAction.Deny;
            }

            RequestFilterAction action = (RequestFilterAction)reader.GetByte(0);

            if (!reader.IsDBNull(1))
                m_timeout = TimeSpan.FromSeconds(reader.GetInt32(1));

            if (!reader.IsDBNull(2))
                m_numRetries = (int) reader.GetByte(2);

            if (!reader.IsDBNull(3))
                m_retryDelay = reader.GetInt32(3);

            if (!reader.IsDBNull(4))
                m_backoffFactor = reader.GetFloat(4);

            reader.Close();

            return action;
        }

        private ResponseFilterAction TryWebRequest(HttpWebRequest outgoingRequest,
            out HttpWebResponse incomingResponse)
        {
            try
            {
                incomingResponse = (HttpWebResponse)outgoingRequest.GetResponse();
                return MatchResponseFilter(incomingResponse);
            }
            catch (ProtocolViolationException pve)
            {
                incomingResponse = null;
                m_lastError = pve.Message;
                return ResponseFilterAction.Error;
            }
            catch (WebException we)
            {
                incomingResponse = we.Response as HttpWebResponse;
                m_lastError = we.Message;

                if (incomingResponse != null)
                    return MatchResponseFilter(incomingResponse);
                return ResponseFilterAction.Retry;
            }
            catch (InvalidOperationException ioe)
            {
                incomingResponse = null;
                m_lastError = ioe.Message;
                return ResponseFilterAction.Error;
            }
        }

        private ResponseFilterAction MatchResponseFilter(HttpWebResponse incomingResponse)
        {
            SqlCommand cmd = s_connection.CreateCommand();
            cmd.CommandText = "sp_MatchResponseFilter";
            cmd.CommandType = CommandType.StoredProcedure;
            cmd.Transaction = s_transaction;
            SqlParameter prmStatusCode = cmd.Parameters.AddWithValue("@StatusCode", (int)incomingResponse.StatusCode);

            byte? action = (byte?) cmd.ExecuteScalar();

            if (action == null)
                return ResponseFilterAction.Error;

            m_lastError = String.Format("{0} {1} {2}",
                incomingResponse.ProtocolVersion,
                (int)incomingResponse.StatusCode,
                incomingResponse.StatusDescription);

            return (ResponseFilterAction) action.Value;
        }

        private httpResponseType CreateBrokerResponse(HttpWebResponse incomingResponse)
        {
            httpResponseType outgoingResponse = new httpResponseType();
            outgoingResponse.protocolVersion = incomingResponse.ProtocolVersion.ToString();
            outgoingResponse.statusCode = (int)incomingResponse.StatusCode;
            SqlContext.Pipe.Send("statusCode = " + outgoingResponse.statusCode);
            outgoingResponse.statusDescription = incomingResponse.StatusDescription;

            List<headerType> headers = new List<headerType>();

            if (incomingResponse.ContentEncoding != null)
            {
                headerType h = new headerType();
                h.name = "Content-Encoding";
                h.value = incomingResponse.ContentEncoding;
                headers.Add(h);
            }

            if (incomingResponse.ContentLength >= 0)
            {
                headerType h = new headerType();
                h.name = "Content-Length";
                h.value = incomingResponse.ContentLength.ToString();
                headers.Add(h);
            }

            if (incomingResponse.ContentType != null)
            {
                headerType h = new headerType();
                h.name = "Content-Type";
                h.value = incomingResponse.ContentType;
                headers.Add(h);
            }

            if (incomingResponse.LastModified != null)
            {
                headerType h = new headerType();
                h.name = "Last-Modified";
                h.value = incomingResponse.LastModified.ToString();
                headers.Add(h);
            }

            if (incomingResponse.Server != null)
            {
                headerType h = new headerType();
                h.name = "Server";
                h.value = incomingResponse.Server;
                headers.Add(h);
            }
            SqlContext.Pipe.Send("done common headers");
            for (int i = 0; i < incomingResponse.Headers.Count; i++)
            {
                headerType h = new headerType();
                h.name = incomingResponse.Headers.Keys[i];
                h.value = incomingResponse.Headers[i];
                headers.Add(h);
            }
            if (headers.Count > 0)
            {
                outgoingResponse.headers = headers.ToArray();
            }
            SqlContext.Pipe.Send("done headers");

            int n;
            byte[] buffer = new byte[512];
            MemoryStream body = new MemoryStream();

            Stream ins = incomingResponse.GetResponseStream();
            while ((n = ins.Read(buffer, 0, 512)) > 0)
            {
                body.Write(buffer, 0, n);
            }
            SqlContext.Pipe.Send("done copying response stream");

            outgoingResponse.body = body.ToArray();
            incomingResponse.Close();
            return outgoingResponse;
        }

        private void SendResponse(httpResponseType outgoingResponse)
        {
            MemoryStream msgBody = new MemoryStream();
            XmlSerializer xs = new XmlSerializer(typeof(httpResponseType));
            xs.Serialize(msgBody, outgoingResponse);

            Message msgResponse = new Message(x_httpResponseMessageType, msgBody);
            s_currentConversation.Send(msgResponse, s_connection, s_transaction);        
        }

        private void ErrorConversation(int errorCode, string message)
        {
            s_currentConversation.EndWithError(errorCode, message,
                s_connection, s_transaction);
        }

        private void EndConversation()
        {
            s_currentConversation.End(s_connection, s_transaction);
        }

        private void SavePendingRequest(httpRequestType incomingRequest)
        {
            SqlCommand cmd = s_connection.CreateCommand();
            cmd.CommandText = "sp_AddOrUpdatePendingRequest";
            cmd.CommandType = CommandType.StoredProcedure;
            cmd.Transaction = s_transaction;
            cmd.Parameters.AddWithValue("@ConversationHandle", s_currentConversation.Handle);
            cmd.Parameters.AddWithValue("@RetriesUsed", ++m_numRetriesUsed);

            if (s_msgReceived.Type == x_httpRequestMessageType)
            {
                MemoryStream stream = new MemoryStream();
                XmlSerializer xs = new XmlSerializer(typeof(httpRequestType));
                xs.Serialize(stream, incomingRequest);
                cmd.Parameters.AddWithValue("@RequestBody", stream.ToArray());
            }
            else
            {
                cmd.Parameters.Add("@RequestBody", SqlDbType.VarBinary).Value = DBNull.Value;
            }

            if (m_lastError == null)
                cmd.Parameters.AddWithValue("@Status", DBNull.Value);
            else
                cmd.Parameters.AddWithValue("@Status", m_lastError);

            try
            {
                cmd.ExecuteNonQuery();
            }
            catch (SqlException e)
            {
                SqlContext.Pipe.Send(e.Message);
            }
        }

        private void BeginTimer()
        {
            int timeout =  (int) (
                m_retryDelay * Math.Pow(m_backoffFactor, m_numRetriesUsed));
            SqlCommand cmd = s_connection.CreateCommand();
            cmd.CommandText = @"BEGIN CONVERSATION TIMER (@dh) TIMEOUT = @to";
            cmd.Transaction = s_transaction;
            cmd.Parameters.AddWithValue("@dh", s_currentConversation.Handle);
            cmd.Parameters.AddWithValue("@to", timeout);
            cmd.ExecuteNonQuery();
            SqlContext.Pipe.Send("set timer");
        }

        private httpRequestType GetPendingRequest()
        {
            SqlCommand cmd = s_connection.CreateCommand();
            cmd.CommandText = @"SELECT RequestBody, RetriesUsed FROM PendingRequest WHERE ConversationHandle = @ConversationHandle";
            cmd.Transaction = s_transaction;
            cmd.Parameters.AddWithValue("@ConversationHandle", s_currentConversation.Handle);
            SqlDataReader reader = cmd.ExecuteReader();

            if (!reader.Read())
            {
                reader.Close();
                return null;
            }

            SqlBytes requestBytes = reader.GetSqlBytes(0);
            XmlSerializer xs = new XmlSerializer(typeof(httpRequestType));
            httpRequestType pendingRequest = xs.Deserialize(requestBytes.Stream) as httpRequestType;

            m_numRetriesUsed = (int) reader.GetByte(1);
            reader.Close();

            return pendingRequest;
        }
        #endregion

        #region entry point
        public static void Run()
        {
            using (SqlConnection conn = new SqlConnection("context connection=true"))
            {
                conn.Open();

                // Create a new WebProxyService on this in-proc connection.
                Service service = new WebProxyService(conn);

                bool success = false;

                // Loop until you can exit successfully
                while (!success)
                {
                    try
                    {
                        service.Run(true, conn, null);
                        success = true;
                    }
                    catch (ServiceException svcex)
                    {
                        // Let us end the current dialog with the exception
                        // wrapped up in the error message.
                        if (svcex.CurrentConversation != null)
                        {
                            svcex.CurrentConversation.EndWithError(2, svcex.Message,
                               svcex.Connection, svcex.Transaction);
                        }

                        success = false;
                    }
                }
            }
        }
        #endregion

        public static string EncodeToBase64(string Content)
        {
            return System.Convert.ToBase64String(new ASCIIEncoding().GetBytes(Content));
        }

        public static string EncodeFromBase64(string Content)
        {
            return new ASCIIEncoding().GetString(System.Convert.FromBase64String(Content));
        }

        #region UDFs
        public static bool RegexMatchCaseInsensitive(string pattern, string matchString)
        {
            if (pattern == null)
                return false;
            Regex r1 = new Regex(pattern, RegexOptions.IgnoreCase);
            return r1.Match(matchString).Success;
        }
        #endregion
    }
}
