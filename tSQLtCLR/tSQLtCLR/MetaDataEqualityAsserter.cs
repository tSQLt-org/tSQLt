using System;
using System.Data;
using System.Data.Sql;
using System.Data.SqlTypes;
using System.Data.SqlClient;
using System.Text;
using Microsoft.SqlServer.Server;

namespace tSQLtCLR
{
    class MetaDataEqualityAsserter
    {
        private TestDatabaseFacade testDatabaseFacade;

        public MetaDataEqualityAsserter(TestDatabaseFacade testDatabaseFacade)
        {
            this.testDatabaseFacade = testDatabaseFacade;
        }

        public void AssertResultSetsHaveSameMetaData(SqlString expectedCommand, SqlString actualCommand)
        {
            try
            {
                String expectedSchemaString = createSchemaStringFromCommand(expectedCommand);
                String actualSchemaString = createSchemaStringFromCommand(actualCommand);

                testDatabaseFacade.assertEquals(expectedSchemaString, actualSchemaString);
            }
            catch (InvalidResultSetException irse)
            {
                testDatabaseFacade.failTestCaseAndThrowException(irse.Message);
            }
        }

        private String createSchemaStringFromCommand(SqlString command)
        {
            SqlDataReader reader = null;
            int resultSet = 0;
            StringBuilder schemaString = new StringBuilder();

            try
            {
                reader = testDatabaseFacade.executeCommand(command);

                do
                {
                    resultSet++;
                    reader.Read();
                    DataTable schema = attemptToGetSchemaTable(command, reader);
                    throwExceptionIfSchemaIsEmpty(command, schema);
                    buildSchemaString(schema, resultSet, schemaString);
                } while (reader.NextResult());

                return schemaString.ToString();
            }
            finally
            {
                closeReader(reader);
            }

        }

        private static void closeReader(SqlDataReader reader)
        {
            if (reader != null)
            {
                reader.Close();
            }
        }

        private static DataTable attemptToGetSchemaTable(SqlString command, SqlDataReader reader)
        {
            try
            {
                return reader.GetSchemaTable();
            }
            catch (Exception e)
            {
                throw new InvalidResultSetException("The command [" + command.ToString() + "] did not return a valid result set", e);
            }
        }

        private static void throwExceptionIfSchemaIsEmpty(SqlString command, DataTable schema)
        {
            if (schema == null) 
            {
                throw new InvalidResultSetException("The command [" + command.ToString() + "] did not return a result set");
            }
        }

        private static void buildSchemaString(DataTable schema, int resultSet, StringBuilder schemaString)
        {
            if (resultSet > 1)
            {
                schemaString.AppendLine();
            }

            schemaString.Append(resultSet).Append(": ");

            foreach (DataRow row in schema.Rows)
            {
                if (row["IsHidden"].ToString() != "True")
                {
                    schemaString.Append("[");
                    foreach (DataColumn column in schema.Columns)
                    {
                        if (columnPropertyIsValidForMetaDataComparison(column))
                        {
                            schemaString.Append("{").Append(column.ColumnName).Append(":").Append(row[column.ColumnName]).Append("}");
                        }
                    }
                    schemaString.Append("]");
                }
            }
        }

        private static bool columnPropertyIsValidForMetaDataComparison(DataColumn column)
        {
            return !(column.ColumnName.StartsWith("Is", StringComparison.OrdinalIgnoreCase) ||
                column.ColumnName.StartsWith("Base", StringComparison.OrdinalIgnoreCase));
        }
    }
}
