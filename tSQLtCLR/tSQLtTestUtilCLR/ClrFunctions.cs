using System;
using System.Collections;
using System.Collections.Generic;
using System.Text;
using Microsoft.SqlServer.Server;
using System.Data.SqlTypes;

namespace tSQLtTestUtilCLR
{
    public class ClrFunctions
    {
        [SqlFunction(DataAccess = DataAccessKind.None, IsDeterministic = true, IsPrecise = true)]
        public static SqlString AClrSvf(SqlString p1, SqlString p2)
        {
            return new SqlString("AClrSvf:["+p1.ToString()+"|"+p2.ToString()+"]");
        }

        [SqlFunction(DataAccess = DataAccessKind.None, IsDeterministic = true, IsPrecise = true, TableDefinition = "id INT,val NVARCHAR(MAX)", FillRowMethodName = "AClrTvf_Row")]
        public static IEnumerable AClrTvf(SqlString p1, SqlString p2)
        {
            return new Dictionary<int, SqlString> { { 1, p1 }, { 2, p2 } };
        }

        [SqlFunction(DataAccess = DataAccessKind.None, IsDeterministic = true, IsPrecise = true, TableDefinition = "id INT,val NVARCHAR(MAX)", FillRowMethodName = "AClrTvf_Row")]
        public static IEnumerable AnEmptyClrTvf(SqlString p1, SqlString p2)
        {
            return new Dictionary<int, SqlString> { };
        }

        private static void AClrTvf_Row(object row, out SqlInt32 id, out SqlString val)
        {
            var keyValuePair = (KeyValuePair<int,SqlString>)row;
            id = keyValuePair.Key;
            val = keyValuePair.Value;
        }
    }
}
