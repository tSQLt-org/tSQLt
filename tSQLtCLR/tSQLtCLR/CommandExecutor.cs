using System;
using System.Collections.Generic;
using System.Text;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;
using System.Data.SqlClient;
using System.Transactions;
using System.Security;

namespace tSQLtCLR
{
    class CommandExecutor
    {
        public void Execute(SqlString command)
        {

            SqlConnection conn = null;
            try
            {

                using (TransactionScope scope = new TransactionScope(TransactionScopeOption.Suppress))
                {
                    String connectionString = CreateConnectionStringToContextDatabase();
                    conn = new SqlConnection(connectionString);

                    conn.Open();

                    SqlCommand cmd = new SqlCommand();
                    cmd.Connection = conn;
                    cmd.CommandText = command.ToString();
                    cmd.ExecuteNonQuery();
                }
            }
            catch (SecurityException se)
            {
                throw new CommandExecutorException("Error connecting to database. You may need to create tSQLt assembly with EXTERNAL_ACCESS.", se);
            }
            finally
            {
                if (conn != null)
                {
                    conn.Close();
                }
            }
        }

        private static String CreateConnectionStringToContextDatabase()
        {
            TestDatabaseFacade facade = new TestDatabaseFacade();
            String server = facade.ServerName;
            String database = facade.DatabaseName;
            System.Data.SqlClient.SqlConnectionStringBuilder builder =
              new System.Data.SqlClient.SqlConnectionStringBuilder();
            builder["Data Source"] = server;
            builder["Integrated Security"] = true;
            builder["Initial Catalog"] = database;
            String connectionString = builder.ConnectionString;
            return connectionString;
        }
    }
}
