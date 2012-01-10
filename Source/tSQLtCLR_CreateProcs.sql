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

CREATE PROCEDURE tSQLt.TableToText
    @txt NVARCHAR(MAX) OUTPUT,
    @TableName NVARCHAR(MAX),
    @OrderBy NVARCHAR(MAX) = NULL
AS
BEGIN
    SET @txt = tSQLt.Private::TableToString(@TableName,@OrderBy);
END;
GO

CREATE TABLE tSQLt.CaptureOutputLog (
  Id INT IDENTITY(1,1) PRIMARY KEY CLUSTERED,
  OutputText NVARCHAR(MAX)
);
GO

CREATE PROCEDURE tSQLt.LogCapturedOutput @text NVARCHAR(MAX)
AS
BEGIN
  INSERT INTO tSQLt.CaptureOutputLog (OutputText) VALUES (@text);
END;
GO

CREATE PROCEDURE tSQLt.CaptureOutput @command NVARCHAR(MAX)
AS
EXTERNAL NAME tSQLtCLR.[tSQLtCLR.StoredProcedures].CaptureOutput;
GO

CREATE PROCEDURE tSQLt.SuppressOutput @command NVARCHAR(MAX)
AS
EXTERNAL NAME tSQLtCLR.[tSQLtCLR.StoredProcedures].SuppressOutput;
GO

----------------------------------------------------------------
---- Below objects need to go back into tSQLt.class.sql     ----
----------------------------------------------------------------

CREATE FUNCTION tSQLt.Private_GetForeignKeyDefinition(
    @SchemaName NVARCHAR(MAX),
    @ParentTableName NVARCHAR(MAX),
    @ForeignKeyName NVARCHAR(MAX)
)
RETURNS TABLE
AS
RETURN SELECT 'CONSTRAINT ' + name + ' FOREIGN KEY (' +
              parCol + ') REFERENCES ' + refName + '(' + refCol + ')' cmd,
              CASE 
                WHEN RefTableIsFakedInd = 1
                  THEN 'CREATE UNIQUE INDEX ' + tSQLt.Private::CreateUniqueObjectName() + ' ON ' + refName + '(' + refCol + ');' 
                ELSE '' 
              END CreIdxCmd
         FROM (SELECT QUOTENAME(SCHEMA_NAME(k.schema_id)) AS SchemaName,
                      QUOTENAME(k.name) AS name,
                      QUOTENAME(OBJECT_NAME(k.parent_object_id)) AS parName,
                      QUOTENAME(SCHEMA_NAME(refTab.schema_id)) + '.' + QUOTENAME(refTab.name) AS refName,
                      QUOTENAME(parCol.name) AS parCol,
                      QUOTENAME(refCol.name) AS refCol,
                      CASE WHEN e.name IS NULL THEN 0
                           ELSE 1 
                       END AS RefTableIsFakedInd
                 FROM sys.foreign_keys k
                 JOIN sys.foreign_key_columns c
                   ON k.object_id = c.constraint_object_id
                 JOIN sys.columns parCol
                   ON parCol.object_id = c.parent_object_id
                  AND parCol.column_id = c.parent_column_id
                 JOIN sys.columns refCol
                   ON refCol.object_id = c.referenced_object_id
                  AND refCol.column_id = c.referenced_column_id
                 LEFT JOIN sys.extended_properties e
                   ON e.name = 'tSQLt.FakeTable_OrgTableName'
                  AND e.value = OBJECT_NAME(c.referenced_object_id)
                 JOIN sys.tables refTab
                   ON COALESCE(e.major_id,refCol.object_id) = refTab.object_id
                WHERE k.parent_object_id = OBJECT_ID(@SchemaName + '.' + @ParentTableName)
                  AND k.object_id = OBJECT_ID(@SchemaName + '.' + @ForeignKeyName)
               )x;
GO

CREATE PROCEDURE tSQLt.Private_RenameObjectToUniqueName
    @SchemaName NVARCHAR(MAX),
    @ObjectName NVARCHAR(MAX),
    @NewName NVARCHAR(MAX) = NULL OUTPUT
AS
BEGIN
   SET @NewName=tSQLt.Private::CreateUniqueObjectName();

   DECLARE @RenameCmd NVARCHAR(MAX);
   SET @RenameCmd = 'EXEC sp_rename ''' + 
                          @SchemaName + '.' + @ObjectName + ''', ''' + 
                          @NewName + ''';';
   
   EXEC tSQLt.SuppressOutput @RenameCmd;
END;
GO

CREATE PROCEDURE tSQLt.Private_RenameObjectToUniqueNameUsingObjectId
    @ObjectId INT,
    @NewName NVARCHAR(MAX) = NULL OUTPUT
AS
BEGIN
   DECLARE @SchemaName NVARCHAR(MAX);
   DECLARE @ObjectName NVARCHAR(MAX);
   
   SELECT @SchemaName = QUOTENAME(OBJECT_SCHEMA_NAME(@ObjectId)), @ObjectName = QUOTENAME(OBJECT_NAME(@ObjectId));
   
   EXEC tSQLt.Private_RenameObjectToUniqueName @SchemaName,@ObjectName, @NewName OUTPUT;
END;
GO

CREATE FUNCTION tSQLt.Info()
RETURNS TABLE
AS
RETURN
SELECT
Version = '$LATEST-BUILD-NUMBER$',
ClrVersion = (SELECT tSQLt.Private::Info());
GO
