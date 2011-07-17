using System;
using System.Collections.Generic;
using System.Text;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using System.Data;

namespace tSQLtCLR
{
    class TestDatabaseFacade : IDisposable
    {
        private SqlConnection connection;
        private SqlString infoMessage;
        Boolean disposed = false;

        public TestDatabaseFacade()
        {
            connect();
        }

        public void Dispose()
        {
            if (!disposed)
            {
                disconnect();
                disposed = true;
            }
            GC.SuppressFinalize(this);
        }

        public SqlString InfoMessage
        {
            get { return infoMessage; }
        }

        private void connect()
        {
            connection = new SqlConnection();
            connection.ConnectionString = "Context Connection=true;";
            connection.Open();
        }

        private void disconnect()
        {
            connection.Dispose();
        }

        public String ServerName
        {
            get {
                SqlDataReader reader = executeCommand("SELECT SERVERPROPERTY('ServerName');");
                reader.Read();
                String serverName = reader.GetString(0);
                reader.Close();
                return serverName;
            }
        }

        public String DatabaseName
        {
            get { return connection.Database; }
        }

        public SqlDataReader executeCommand(SqlString Command)
        {
            infoMessage = SqlString.Null;
            connection.InfoMessage += new SqlInfoMessageEventHandler(OnInfoMessage);
            SqlCommand cmd = new SqlCommand();
            
            cmd.Connection = connection;
            cmd.CommandText = Command.ToString();

            SqlDataReader dataReader = cmd.ExecuteReader(CommandBehavior.KeyInfo);

            return dataReader;
        }

        protected void OnInfoMessage(object sender, SqlInfoMessageEventArgs args)
        {
            if (infoMessage.IsNull)
            {
                infoMessage = "";
            }
            infoMessage += args.Message + "\r\n";
        }

        public void assertEquals(String expectedString, String actualString)
        {
            SqlCommand cmd = new SqlCommand();
            cmd.Connection = connection;
            cmd.CommandText = "tSQLt.AssertEqualsString";
            cmd.Parameters.AddWithValue("Expected", expectedString);
            cmd.Parameters.AddWithValue("Actual", actualString);
            cmd.CommandType = CommandType.StoredProcedure;
            cmd.ExecuteNonQuery();
        }

        public void failTestCaseAndThrowException(String failureMessage)
        {
            // tSQLt.Fail throws an exception which is uncaught and passed upwards
            SqlCommand cmd = new SqlCommand();
            cmd.Connection = connection;
            cmd.CommandText = "tSQLt.Fail";
            cmd.Parameters.AddWithValue("Message0", failureMessage);
            cmd.CommandType = CommandType.StoredProcedure;
            cmd.ExecuteNonQuery();
        }

        public void logCapturedOutput(SqlString text)
        {
            SqlCommand cmd = new SqlCommand();
            cmd.Connection = connection;
            cmd.CommandText = "tSQLt.LogCapturedOutput";
            cmd.Parameters.AddWithValue("text", text);
            cmd.CommandType = CommandType.StoredProcedure;
            cmd.ExecuteNonQuery();
        }
    }
}
