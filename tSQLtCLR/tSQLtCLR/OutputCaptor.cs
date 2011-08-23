using System;
using System.Collections.Generic;
using System.Text;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using System.Data;

namespace tSQLtCLR
{
    class OutputCaptor
    {
        private TestDatabaseFacade testDatabaseFacade;

        public OutputCaptor(TestDatabaseFacade testDatabaseFacade)
        {
            this.testDatabaseFacade = testDatabaseFacade;
        }

        internal void CaptureOutputToLogTable(System.Data.SqlTypes.SqlString command)
        {
            ExecuteCommand(command);
            testDatabaseFacade.logCapturedOutput(testDatabaseFacade.InfoMessage);
        }

        internal void SuppressOutput(System.Data.SqlTypes.SqlString command)
        {
            ExecuteCommand(command);
        }

        internal void ExecuteCommand(System.Data.SqlTypes.SqlString command)
        {
            SqlDataReader reader = testDatabaseFacade.executeCommand(command);
            reader.Close();
        }
    }
}
