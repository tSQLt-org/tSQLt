using System;
using System.Collections.Generic;
using System.Text;
using System.Data.SqlTypes;
using System.Data.SqlClient;
using Microsoft.SqlServer.Server;
using System.Data;
using System.Globalization;

namespace tSQLtCLR
{
    class ResultSetFilter
    {
        private TestDatabaseFacade testDatabaseFacade;

        public ResultSetFilter(TestDatabaseFacade testDatabaseFacade)
        {
            this.testDatabaseFacade = testDatabaseFacade;
        }

        public void sendSelectedResultSetToSqlContext(SqlInt32 resultsetNo, SqlString command)
        {
            validateResultSetNumber(resultsetNo);

            SqlDataReader dataReader = testDatabaseFacade.executeCommand(command);

            int ResultsetCount = 0;
            do
            {
                ResultsetCount++;
                if (ResultsetCount == resultsetNo)
                {
                    sendResultsetRecords(dataReader);
                    break;
                }
            } while (dataReader.NextResult());

            dataReader.Close();
        }

        private void validateResultSetNumber(SqlInt32 resultsetNo)
        {
            if (resultsetNo < 1)
            {
                throw new InvalidResultSetException("ResultSet index begins at 1. ResultSet index [" + resultsetNo.ToString() + "] is invalid.");
            }
        }

        private static void sendResultsetRecords(SqlDataReader dataReader)
        {
            SqlMetaData[] meta = createMetaDataForResultset(dataReader);

            SqlContext.Pipe.SendResultsStart(new SqlDataRecord(meta));
            sendEachRecordOfData(dataReader, meta);
            SqlContext.Pipe.SendResultsEnd();
        }

        private static void sendEachRecordOfData(SqlDataReader dataReader, SqlMetaData[] meta)
        {
            while (dataReader.Read())
            {
                SqlContext.Pipe.SendResultsRow(createRecordPopulatedWithData(dataReader, meta));
            }
        }

        private static SqlDataRecord createRecordPopulatedWithData(SqlDataReader dataReader, SqlMetaData[] meta)
        {
            SqlDataRecord rec = new SqlDataRecord(meta);
            object[] recordData = new object[dataReader.FieldCount];
            dataReader.GetSqlValues(recordData);

            rec.SetValues(recordData);
            return rec;
        }

        private static SqlMetaData[] createMetaDataForResultset(SqlDataReader dataReader)
        {
            DataTable schema = dataReader.GetSchemaTable();
            int numberOfColumns = schema.Rows.Count;
            SqlMetaData[] meta = new SqlMetaData[numberOfColumns];

            for (int i = 0; i < numberOfColumns; i++)
            {
                meta[i] = createSqlMetaDataForColumn(schema.Rows[i]);
            }

            return meta;
        }

        private static SqlMetaData createSqlMetaDataForColumn(DataRow columnDetails)
        {
            SqlDbType dbType = (SqlDbType)columnDetails["ProviderType"];
            String colName = (String)columnDetails["ColumnName"];

            switch (dbType)
            {
                case SqlDbType.BigInt:
                case SqlDbType.Int:
                case SqlDbType.SmallInt:
                case SqlDbType.TinyInt:
                case SqlDbType.Bit:
                case SqlDbType.DateTime:
                case SqlDbType.SmallDateTime:
                case SqlDbType.Float:
                case SqlDbType.Image:
                case SqlDbType.Money:
                case SqlDbType.SmallMoney:
                case SqlDbType.Text:
                case SqlDbType.NText:
                case SqlDbType.Real:
                case SqlDbType.Variant:
                case SqlDbType.Timestamp:
                case SqlDbType.UniqueIdentifier:
                case SqlDbType.Xml:
                    return new SqlMetaData(colName, dbType);
                case SqlDbType.Binary:
                case SqlDbType.Char:
                case SqlDbType.NChar:
                    return new SqlMetaData(colName, dbType, (int)columnDetails["ColumnSize"]);
                case SqlDbType.VarBinary:
                case SqlDbType.VarChar:
                case SqlDbType.NVarChar:
                    int length = (int)columnDetails["ColumnSize"];
                    if (length > Int16.MaxValue)
                    {
                        length = -1;
                    }
                    return new SqlMetaData(colName, dbType, length);
                case SqlDbType.Decimal:
                    return new SqlMetaData(colName, dbType, Convert.ToByte(columnDetails["NumericPrecision"], CultureInfo.InvariantCulture), Convert.ToByte(columnDetails["NumericScale"], CultureInfo.InvariantCulture));
                default:
                    throw new ArgumentException("Argument [" + dbType.ToString() + "] is not valid for ResultSetFilter.");
            }
        }

    }
}
