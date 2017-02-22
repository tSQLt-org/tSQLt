/*
 * Copyright 2017 Jonathan Hall <jonathan.hall@kjr.com.au>
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *     http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using System.Text;

namespace tSQLtCLR
{
    class ResultSetToTable
    {
        private TestDatabaseFacade testDatabaseFacade;

        public ResultSetToTable(TestDatabaseFacade testDatabaseFacade)
        {
            this.testDatabaseFacade = testDatabaseFacade;
        }


        /// <summary>
        /// Replacement for "INSERT INTO [table] EXEC" pattern this works like tSQLt.ResultSetFilter
        /// with the addition of the extra TargetTable param 
        /// 
        /// This method will:
        /// - Execute the desired command and
        /// - Extract the selected result set
        /// - Insert new rows into the TargetTable.
        /// 
        /// Notes:
        /// - Unlike ResultSetFilter this cannot stream the new rows into the target table, they're kept in memory until after command is finished. 
        /// - Only columns in common to the result set and target table will be populated; 
        /// - extra result columns will be discarded 
        /// - extra target table columns will be populated with NULL (will fail if these are 'NOT NULL')
        /// 
        /// </summary>
        /// <param name="targetTableName">Target Table (this can be a #TemporaryTable, but not a @variable)</param>
        /// <param name="resultsetNo">If command returns multiple result sets select which one to capture</param>
        /// <param name="command">SQL String that will be executed</param>
        /// <exception cref="InvalidResultSetException"></exception>
        /// <example>
        /// <![CDATA[
        /// 	    CREATE TABLE #Actual (val INT);
        ///         EXEC tSQLt.ResultSetToTable #Actual, 1, 'SELECT 1 AS val; SELECT 2 AS val; SELECT 3 AS val;';
        ///         -- #Actual now contains a single row with 1 in it
        /// ]]></example>
        internal void sendSelectedResultSetToTable(string targetTableName, SqlInt32 resultsetNo, SqlString command)
        {
            validateResultSetNumber(resultsetNo);

            // Establish a updatable DataTable linked to the target table
            using (var adapter = testDatabaseFacade.getSQLAdapterForCommand("SELECT TOP 0 * FROM " + targetTableName))
            // ReSharper disable once UnusedVariable
            // SqlCommandBuilder is needed to allow targetDataSet to be updated.
            using (var builder = new SqlCommandBuilder(adapter))
            using (var targetDataSet = new DataSet())
            {
                adapter.Fill(targetDataSet);
                var targetTable = targetDataSet.Tables[0];

                // Run the desired command using a SqlDataRreader so that the results can be streamed.
                using (var dataReader = testDatabaseFacade.executeCommand(command))
                {
                    // Find the relevent result by steping througth Result Sets
                    int resultsetCount = 0;
                    do
                    {
                        // ignore blank Result Sets.
                        if (dataReader.HasRows || dataReader.FieldCount > 0)
                        {
                            resultsetCount++;
                            if (resultsetCount == resultsetNo)
                                break;
                        }
                    } while (dataReader.NextResult());
                    
                    if (resultsetCount < resultsetNo)
                    {
                        throw new InvalidResultSetException(
                            string.Format("Execution returned only {0} ResultSets. ResultSet [{1}] does not exist.",
                                resultsetCount, resultsetNo));
                    }


                    // 4. Work out which columns to keep
                    //  and Extract columns from result's schema
                    var schemaTable = dataReader.GetSchemaTable();
                    if (schemaTable == null)
                        return; // ResultSet has no data.


                    var availableColumns = new Dictionary<String, Int32>();
                    foreach (DataRow c in schemaTable.Rows)
                    {
                        availableColumns.Add((string)c["ColumnName"], (int)c["ColumnOrdinal"]);
                    }

                    // 3b. Use target table schema to determine which columns are common.
                    var commonColumns = new Dictionary<DataColumn, Int32>();
                    foreach (DataColumn k in targetTable.Columns)
                    {
                        int index;
                        if (availableColumns.TryGetValue(k.ToString(), out index))
                        {
                            commonColumns.Add(k, index);
                        }
                    }

                    // Step 4. Itterate through Results creating new rows in Target Table
                    object[] recordData = new object[dataReader.FieldCount];
                    while (dataReader.Read())
                    {
                        dataReader.GetValues(recordData);

                        var newrow = targetTable.NewRow();
                        foreach (KeyValuePair<DataColumn, Int32> kvp in commonColumns)
                        {
                            newrow[kvp.Key] = recordData[kvp.Value];
                        }
                        targetTable.Rows.Add(newrow);
                    }
                }
                adapter.Update(targetDataSet);
            }
        }

        private void validateResultSetNumber(SqlInt32 resultsetNo)
        {
            if (resultsetNo < 0 || resultsetNo.IsNull)
            {
                throw new InvalidResultSetException("ResultSet index begins at 1. ResultSet index [" + resultsetNo.ToString() + "] is invalid.");
            }
        }

    }
}
