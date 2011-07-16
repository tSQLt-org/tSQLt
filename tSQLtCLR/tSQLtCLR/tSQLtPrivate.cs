using System;
using System.Collections.Generic;
using System.Text;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;
using System.Runtime.Serialization;
using System.Data.SqlClient;
using System.Data;

namespace tSQLtCLR
{
    [SqlUserDefinedTypeAttribute(Format.UserDefined, MaxByteSize = 1, IsFixedLength = true)]
    public struct tSQLtPrivate : INullable, IBinarySerialize
    {
        private const String NULL_STRING = "!NULL!";
        private const int MAX_COLUMN_WIDTH = 155;


        [SqlMethod(DataAccess = DataAccessKind.Read)]
        public static SqlString CreateUniqueObjectName()
        {
            return "tSQLt_tempobject_" + Guid.NewGuid().ToString().Replace("-", "");
        }


        [SqlMethod(DataAccess = DataAccessKind.Read)]
        public static SqlChars TableToString(SqlString TableName, SqlString OrderOption) {
            if (TableName.IsNull) {
                throw new Exception("Object name cannot be NULL");
            }

            if (OrderOption.IsNull) {
                OrderOption = "";
            }

            TestDatabaseFacade testDbFacade = new TestDatabaseFacade();
            String selectStmt = getSqlStatement(ref TableName, ref OrderOption);
            SqlDataReader reader = testDbFacade.executeCommand(selectStmt);
            List<String[]> results = getTableStringArray(reader);

            int numRows = 0;
            int[] ColumnLength = new int[results[0].Length];
            foreach (String[] rowData in results) {
                for (int i = 0; i < rowData.Length; i++) {
                    ColumnLength[i] = Math.Max(ColumnLength[i], rowData[i].Length);
                }
                numRows++;
            }

            for (int i = 0; i < ColumnLength.Length; i++) {
                ColumnLength[i] = Math.Min(ColumnLength[i], MAX_COLUMN_WIDTH);
            }

            int size = 0;
            foreach (int i in ColumnLength) {
                size += 1 + i;
            }
            size++;
            size *= (numRows + 1);

            bool isHeader = true;
            StringBuilder output = new StringBuilder(size);
            foreach (String[] rowData in results) {
                if (!isHeader) {
                    output.AppendLine();
                }
                for (int i = 0; i < rowData.Length; i++) {
                    output.Append("|").Append(PadColumn(TrimToMaxLength(rowData[i]), ColumnLength[i]));
                }
                output.Append("|");

                if (isHeader) {
                    isHeader = false;
                    output.AppendLine();
                    for (int i = 0; i < rowData.Length; i++) {
                        output.Append("+");
                        output.Insert(output.Length, "-", ColumnLength[i]);
                    }
                    output.Append("+");
                }
            }

            return new SqlChars(output.ToString());
        }

        private static String PadColumn(String input, int length) {
            return input + (new StringBuilder().Insert(0, " ", length - input.Length).ToString());
        }

        private static String TrimToMaxLength(String rowData) {
            if (rowData.Length > MAX_COLUMN_WIDTH) {
                return rowData.Substring(0, (MAX_COLUMN_WIDTH - 5) / 2) + "<...>" + rowData.Substring(rowData.Length - (MAX_COLUMN_WIDTH - 5) / 2, (MAX_COLUMN_WIDTH - 5) / 2);
            } else {
                return rowData;
            }
        }

        private static String getSqlStatement(ref SqlString TableName, ref SqlString OrderOption) {
            String selectStmt = "SELECT * FROM " + TableName.ToString();
            if (OrderOption.ToString().Length > 0) {
                selectStmt += " ORDER BY " + OrderOption.ToString();
            }
            return selectStmt;
        }

        private static List<String[]> getTableStringArray(SqlDataReader reader) {
            DataTable schema = reader.GetSchemaTable();

            List<String[]> results = new List<string[]>();

            int numCols = schema.Rows.Count;

            String[] header = new String[numCols];
            for (int i = 0; i < numCols; i++) {
                DataRow row = schema.Rows[i];
                header[i] = row["ColumnName"].ToString();
            }
            results.Add(header);

            while (reader.Read()) {
                String[] rowData = new String[numCols];
                for (int i = 0; i < reader.FieldCount; i++) {

                    if (reader.IsDBNull(i)) {
                        rowData[i] = NULL_STRING;
                    } else {
                        SqlDbType dbType = (SqlDbType)schema.Rows[i]["ProviderType"];

                        switch (dbType) {
                            case SqlDbType.Date:
                                rowData[i] = SqlDateToString(reader.GetDateTime(i));
                                break;
                            case SqlDbType.SmallDateTime:
                                rowData[i] = SmallDateTimeToString(reader.GetDateTime(i));
                                break;
                            case SqlDbType.DateTime:
                                rowData[i] = SqlDateTimeToString(reader.GetDateTime(i));
                                break;
                            case SqlDbType.DateTime2:
                                rowData[i] = SqlDateTime2ToString(reader.GetDateTime(i));
                                break;
                            case SqlDbType.DateTimeOffset:
                                rowData[i] = SqlDateTimeOffsetToString(reader.GetDateTimeOffset(i));
                                break;
                            case SqlDbType.Decimal:
                                rowData[i] = reader.GetSqlDecimal(i).ToString();
                                break;
                            case SqlDbType.Float:
                                rowData[i] = reader.GetSqlDouble(i).Value.ToString("0.000000000000000E+0");
                                break;
                            case SqlDbType.Timestamp:
                            case SqlDbType.Image:
                            case SqlDbType.VarBinary:
                                rowData[i] = SqlBinaryToString(reader.GetSqlBinary(i));
                                break;
                            default:
                                rowData[i] = reader.GetValue(i).ToString();
                                break;
                        }
                    }
                }

                results.Add(rowData);
            }
            return results;
        }

        private static string SqlDateToString(SqlDateTime dtValue) {
            return String.Format("{0:yyyy-MM-dd}", dtValue.Value);
        }

        private static String SqlDateTimeToString(SqlDateTime dtValue) {
            return String.Format("{0:yyyy-MM-dd HH:mm:ss.fff}", dtValue.Value);
        }

        private static String SmallDateTimeToString(SqlDateTime dtValue) {
            return String.Format("{0:yyyy-MM-dd HH:mm}", dtValue.Value);
        }

        private static String SqlDateTime2ToString(DateTime dtValue) {
            return String.Format("{0:yyyy-MM-dd HH:mm:ss.fffffff}", new DateTime(dtValue.Ticks));
        }

        private static String SqlDateTimeOffsetToString(DateTimeOffset dtoValue) {
            return String.Format("{0:yyyy-MM-dd HH:mm:ss.fffffff zzz}", dtoValue);
        }

        private static String SqlBinaryToString(SqlBinary sqlBinary) {
            StringBuilder binSB = new StringBuilder().Append("0x");
            foreach (byte bt in sqlBinary.Value) {
                binSB.Append(bt.ToString("X2"));
            }
            return binSB.ToString();
        }

        public static tSQLtPrivate Null {
            get { throw new Exception("tSQLtPrivate is not intended to be used outside of tSQLt!"); }
        }

        public bool IsNull {
            get { throw new Exception("tSQLtPrivate is not intended to be used outside of tSQLt!"); }
        }

        public static tSQLtPrivate Parse(SqlString input) {
            throw new Exception("tSQLtPrivate is not intended to be used outside of tSQLt!");
        }

        public override String ToString() {
            throw new Exception("tSQLtPrivate is not intended to be used outside of tSQLt!");
        }

        public void Read(System.IO.BinaryReader r) {
            throw new NotImplementedException();
        }

        public void Write(System.IO.BinaryWriter w) {
            throw new NotImplementedException();
        }
    }
}
