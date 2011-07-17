using System;
using System.Data;
using System.Data.Sql;
using System.Data.SqlTypes;
using System.Data.SqlClient;

using Microsoft.SqlServer.Server;

namespace tSQLtCLR
{
    public static partial class StoredProcedures
    {
        public static void AssertResultSetsHaveSameMetaData(SqlString expectedCommand, SqlString actualCommand)
        {
            MetaDataEqualityAsserter asserter = new MetaDataEqualityAsserter(new TestDatabaseFacade());
            asserter.AssertResultSetsHaveSameMetaData(expectedCommand, actualCommand);
        }

        public static void ResultSetFilter(SqlInt32 resultSetNo, SqlString command)
        {
            ResultSetFilter filter = new ResultSetFilter(new TestDatabaseFacade());
            filter.sendSelectedResultSetToSqlContext(resultSetNo, command);
        }

        public static void NewConnection(SqlString command)
        {
            CommandExecutor executor = new CommandExecutor();
            executor.Execute(command);
        }

        public static void CaptureOutput(SqlString command)
        {
            OutputCaptor captor = new OutputCaptor(new TestDatabaseFacade());
            captor.CaptureOutputToLogTable(command);
        }

        public static void SuppressOutput(SqlString command)
        {
            OutputCaptor captor = new OutputCaptor(new TestDatabaseFacade());
            captor.SuppressOutput(command);
        }
    }
}
