using System;
using System.Data;
using System.Data.Sql;
using System.Data.SqlTypes;
using System.Data.SqlClient;

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
            catch (SqlException se)
            {
                testDatabaseFacade.failTestCaseAndThrowException("Exception encountered while executing command: " + se.Message);
            }
        }

        private String createSchemaStringFromCommand(SqlString command)
        {
            SqlDataReader reader = null;
            try
            {
                reader = testDatabaseFacade.executeCommand(command);
                throwExceptionIfReadingResultSetProducesError(command, reader);

                DataTable schema = reader.GetSchemaTable();
                throwExceptionIfSchemaIsEmpty(command, schema);

                return buildSchemaString(schema);
            }
            catch (InvalidResultSetException)
            {
                throw;
            }
            catch (Exception e)
            {
                throw new InvalidResultSetException("The command [" + command.ToString() + "] did not return a valid result set", e);
            }
            finally
            {
                if (reader != null)
                {
                    reader.Close();
                }
            }
        }

        private static void throwExceptionIfSchemaIsEmpty(SqlString command, DataTable schema)
        {
            if (schema == null)
                throw new InvalidResultSetException("The command [" + command.ToString() + "] did not return a result set");
        }

        private static void throwExceptionIfReadingResultSetProducesError(SqlString command, SqlDataReader reader)
        {
            try
            {
                reader.Read();
            }
            catch (SqlException se)
            {
                throw new InvalidResultSetException("The command [" + command.ToString() + "] produced an exception", se);
            }
        }

        private static String buildSchemaString(DataTable schema)
        {
            String schemaString = "";

            foreach (DataRow row in schema.Rows)
            {
                schemaString += "[";
                foreach (DataColumn column in schema.Columns)
                {
                    if (columnPropertyIsValidForMetaDataComparison(column))
                    {
                        schemaString += "{" + column.ColumnName + ":" + row[column.ColumnName] + "}";
                    }
                }
                schemaString += "]";
            }
            return schemaString;
        }

        private static bool columnPropertyIsValidForMetaDataComparison(DataColumn column)
        {
            return !(column.ColumnName.StartsWith("Is", StringComparison.OrdinalIgnoreCase) || 
                column.ColumnName.StartsWith("Base", StringComparison.OrdinalIgnoreCase));
        }
    }
}
