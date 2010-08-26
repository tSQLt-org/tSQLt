using System;
using System.Collections.Generic;
using System.Text;

namespace tSQLtCLR
{
    public static class StringExtensions
    {
        public static String tSQLtReplicate(this String repeatString, int count)
        {
            return new StringBuilder().Insert(0, repeatString, count).ToString();
        }
    }
}
