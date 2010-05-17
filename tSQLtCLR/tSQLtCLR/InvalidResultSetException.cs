using System;
using System.Collections.Generic;
using System.Text;
using System.Runtime.Serialization;

namespace tSQLtCLR
{
    [Serializable]
    public class InvalidResultSetException : Exception
    {
        public InvalidResultSetException() : base() { }
        public InvalidResultSetException(String message) : base(message) { }
        public InvalidResultSetException(String message, Exception innerException) : base(message, innerException) { }
        protected InvalidResultSetException(SerializationInfo info, StreamingContext context) : base(info, context) { }
    }
}
