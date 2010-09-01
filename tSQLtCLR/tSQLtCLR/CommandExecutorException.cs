using System;
using System.Collections.Generic;
using System.Text;
using System.Runtime.Serialization;

namespace tSQLtCLR
{
    [Serializable]
    public class CommandExecutorException : Exception
    {
        public CommandExecutorException() : base() { }
        public CommandExecutorException(String message) : base(message) { }
        public CommandExecutorException(String message, Exception innerException) : base(message, innerException) { }
        protected CommandExecutorException(SerializationInfo info, StreamingContext context) : base(info, context) { }
    }
}
