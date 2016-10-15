using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Data.Sql;
using System.Data.SqlClient;
using System.Drawing;
using System.Text;
using System.Threading;
using System.Windows.Forms;

namespace SqlNotificationRequestSample
{
    public partial class Form1 : Form
    {
        private DataSet _dataToWatch = null;
        private SqlConnection _cnn = null;
        private SqlCommand _cmd = null;
        private string _serviceName = "QueryNotificationService";
        private string _connectionString = "Data Source=localhost;Initial Catalog=Chapter9_SqlNotificationRequest;Integrated Security=SSPI;";
        private int _notificationTimeout = 60000;

        public Form1()
        {
            InitializeComponent();
        }

        private void Form1_Load(object sender, EventArgs e)
        {

        }

        private void StartListener()
        {
            Thread listener = new Thread(Listen);
            listener.Name = "Query Notification Watcher";
            listener.Start();
        }

        private void Listen()
        {
            using (SqlConnection cnn = new SqlConnection(_connectionString))
            {
                using (SqlCommand cmd = new SqlCommand("WAITFOR ( RECEIVE * FROM QueryNotificationQueue);", cnn))
                {
                    // cmd.CommandTimeout = _notificationTimeout + 100;
                    cnn.Open();
                    SqlDataReader reader = cmd.ExecuteReader();

                    while (reader.Read())
                    {
                    }

                    object[] args = { this, EventArgs.Empty };
                    EventHandler notify = new EventHandler(OnNotificationComplete);

                    // Switch back to the UI-Thread
                    this.BeginInvoke(notify, args);
                }
            }
        }

        private void OnNotificationComplete(object sender, EventArgs e)
        {
            GetData();
        }

        private void cmdGetData_Click(object sender, EventArgs e)
        {
            if (_cnn == null)
                _cnn = new SqlConnection(_connectionString);

            if (_cmd == null)
                _cmd = new SqlCommand("SELECT ProductName, ProductDescription FROM Products", _cnn);

            if (_dataToWatch == null)
                _dataToWatch = new DataSet();

            GetData();
        }

        private void GetData()
        {
            _dataToWatch.Clear();
            _cmd.Notification = null;

            SqlNotificationRequest request = new SqlNotificationRequest();
            request.UserData = Guid.NewGuid().ToString();
            request.Options = "service=" + _serviceName + ";";
            request.Timeout = _notificationTimeout;
            _cmd.Notification = request;

            using (SqlDataAdapter adapter = new SqlDataAdapter(_cmd))
            {
                adapter.Fill(_dataToWatch, "Products");
                dataGridView1.DataSource = _dataToWatch;
                dataGridView1.DataMember = "Products";

                StartListener();
            }
        }

        private void Form1_FormClosing(object sender, FormClosingEventArgs e)
        {
            if (_cnn != null)
                _cnn.Close();
        }
    }
}