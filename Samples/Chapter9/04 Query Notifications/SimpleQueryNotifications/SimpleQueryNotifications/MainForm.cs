using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Data.SqlClient;
using System.Drawing;
using System.Text;
using System.Windows.Forms;

namespace SimpleQueryNotifications
{
    public partial class MainForm : Form
    {
        private string _connectionString = @"Data Source=localhost\sql2008ctp5;Initial Catalog=Chapter9_QueryNotifications;Integrated Security=SSPI;";
        private SqlConnection _cnn;
        private SqlCommand _cmd;
        private DataSet _dataToWatch;

        public MainForm()
        {
            InitializeComponent();
        }

        private void dependency_OnChange(object sender, SqlNotificationEventArgs e)
        {
            ISynchronizeInvoke i = (ISynchronizeInvoke)this;

            if (i.InvokeRequired)
            {
                OnChangeEventHandler tempDelegate = new OnChangeEventHandler(dependency_OnChange);
                object[] args = { sender, e };

                i.BeginInvoke(tempDelegate, args);
                return;
            }

            SqlDependency dependency = (SqlDependency)sender;
            dependency.OnChange -= dependency_OnChange;

            GetData();
        }

        private void GetData()
        {
            _dataToWatch.Clear();
            _cmd.Notification = null;

            SqlDependency dependency = new SqlDependency(_cmd);
            dependency.OnChange += new OnChangeEventHandler(dependency_OnChange);

            using (SqlDataAdapter adapter = new SqlDataAdapter(_cmd))
            {
                adapter.Fill(_dataToWatch, "Products");
                dataGridView1.DataSource = _dataToWatch;
                dataGridView1.DataMember = "Products";
                lblCount.Text = _dataToWatch.Tables["Products"].Rows.Count.ToString();
            }
        }

        private void cmdGetData_Click(object sender, EventArgs e)
        {
            SqlDependency.Stop(_connectionString);
            SqlDependency.Start(_connectionString);

            if (_cnn == null)
                _cnn = new SqlConnection(_connectionString);

            if (_cmd == null)
                _cmd = new SqlCommand("SELECT ProductName, ProductDescription FROM Products", _cnn);

            if (_dataToWatch == null)
                _dataToWatch = new DataSet();

            GetData();
        }

        private void Form1_FormClosing(object sender, FormClosingEventArgs e)
        {
            SqlDependency.Stop(_connectionString);

            if (_cnn != null)
                _cnn.Close();
        }
    }
}