/*
   Copyright 2011 tSQLt

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/
GO

CREATE PROCEDURE tSQLt.ResultSetFilter @ResultsetNo INT, @Command NVARCHAR(MAX)
AS
EXTERNAL NAME tSQLtCLR.[tSQLtCLR.StoredProcedures].ResultSetFilter;
GO

CREATE PROCEDURE tSQLt.AssertResultSetsHaveSameMetaData @expectedCommand NVARCHAR(MAX), @actualCommand NVARCHAR(MAX)
AS
EXTERNAL NAME tSQLtCLR.[tSQLtCLR.StoredProcedures].AssertResultSetsHaveSameMetaData;
GO

CREATE TYPE tSQLt.[Private] EXTERNAL NAME tSQLtCLR.[tSQLtCLR.tSQLtPrivate];
GO

CREATE PROCEDURE tSQLt.NewConnection @command NVARCHAR(MAX)
AS
EXTERNAL NAME tSQLtCLR.[tSQLtCLR.StoredProcedures].NewConnection;
GO

CREATE PROCEDURE tSQLt.CaptureOutput @command NVARCHAR(MAX)
AS
EXTERNAL NAME tSQLtCLR.[tSQLtCLR.StoredProcedures].CaptureOutput;
GO

CREATE PROCEDURE tSQLt.SuppressOutput @command NVARCHAR(MAX)
AS
EXTERNAL NAME tSQLtCLR.[tSQLtCLR.StoredProcedures].SuppressOutput;
GO

