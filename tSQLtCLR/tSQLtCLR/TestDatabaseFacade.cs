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
            SqlCommand cmd = new SqlCommand();
            cmd.Connection = connection;
            cmd.CommandText = Command.ToString();

            SqlDataReader dataReader = cmd.ExecuteReader(CommandBehavior.KeyInfo);
            return dataReader;
        }

        public void assertEquals(String expectedString, String actualString)
        {
            SqlCommand cmd = new SqlCommand();
            cmd.Connection = connection;
            cmd.CommandText = "tSQLt.AssertEqualsString";
            cmd.Parameters.AddWithValue("expected", expectedString);
            cmd.Parameters.AddWithValue("actual", actualString);
            cmd.CommandType = CommandType.StoredProcedure;
            cmd.ExecuteNonQuery();
        }

        public void failTestCaseAndThrowException(String failureMessage)
        {
            // tSQLt.Fail throws an exception which is uncaught and passed upwards
            SqlCommand cmd = new SqlCommand();
            cmd.Connection = connection;
            cmd.CommandText = "tSQLt.Fail";
            cmd.Parameters.AddWithValue("message0", failureMessage);
            cmd.CommandType = CommandType.StoredProcedure;
            cmd.ExecuteNonQuery();
        }
    }
}
