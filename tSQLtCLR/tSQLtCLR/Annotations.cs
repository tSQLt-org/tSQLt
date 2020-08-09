using System;
using System.Collections;
using System.Collections.Generic;
using System.Text;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;
using System.Data.SqlClient;
using System.Transactions;
using System.Security;
using System.Text.RegularExpressions;

namespace tSQLtCLR
{

	public class Annotations
	{
		public Annotations()
		{
		}

        [SqlFunction(DataAccess = DataAccessKind.None, IsDeterministic = true, IsPrecise = true, TableDefinition = "AnnotationNo INT, Annotation NVARCHAR(MAX)", FillRowMethodName = "ProcessRowForGetAnnotationList")]
        public static IEnumerable GetAnnotationList([SqlFacet(MaxSize = -1)] SqlString procedureText)
        {
            Dictionary<int, SqlString> annotations = new Dictionary<int, SqlString> {};
            int annotationNo = 0;
            var reader = new System.IO.StringReader(procedureText.Value);
            string line;
            Regex rgx = new Regex(@"^\s*--\[@tSQLt:");
            while ((line = reader.ReadLine()) != null)
            {
                if (rgx.IsMatch(line))
                {
                    annotationNo++;
                    annotations.Add(annotationNo, line.Trim().Substring(2));
                }
            }
            return annotations;
        }

        private static void ProcessRowForGetAnnotationList(object row, out SqlInt32 AnnotationNo, out SqlString Annotation)
        {
            var keyValuePair = (KeyValuePair<int, SqlString>)row;
            AnnotationNo = keyValuePair.Key;
            Annotation = keyValuePair.Value;
        }

    }
}
