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
IF OBJECT_ID('tSQLt.ResultSetFilter') IS NOT NULL DROP PROCEDURE tSQLt.ResultSetFilter;
IF OBJECT_ID('tSQLt.AssertResultSetsHaveSameMetaData') IS NOT NULL DROP PROCEDURE tSQLt.AssertResultSetsHaveSameMetaData;
IF OBJECT_ID('tSQLt.NewConnection') IS NOT NULL DROP PROCEDURE tSQLt.NewConnection;
IF OBJECT_ID('tSQLt.CaptureOutput') IS NOT NULL DROP PROCEDURE tSQLt.CaptureOutput;
IF OBJECT_ID('tSQLt.SuppressOutput') IS NOT NULL DROP PROCEDURE tSQLt.SuppressOutput;
IF OBJECT_ID('tSQLt.Private_GetAnnotationList') IS NOT NULL DROP FUNCTION tSQLt.Private_GetAnnotationList;
IF TYPE_ID('tSQLt.[Private]') IS NOT NULL DROP TYPE tSQLt.[Private];

GO

GO
---Build+
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

CREATE FUNCTION tSQLt.Private_GetAnnotationList(@ProcedureDefinition NVARCHAR(MAX))
   RETURNS TABLE(AnnotationNo INT, Annotation NVARCHAR(MAX))
   AS EXTERNAL NAME tSQLtCLR.[tSQLtCLR.Annotations].GetAnnotationList;

GO

