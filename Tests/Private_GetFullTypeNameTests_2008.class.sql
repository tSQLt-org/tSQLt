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
DECLARE @Msg VARCHAR(MAX);SELECT @Msg = 'Compiled at '+CONVERT(VARCHAR,GETDATE(),121);RAISERROR(@Msg,0,1);
GO
EXEC tSQLt.NewTestClass 'Private_GetFullTypeNameTests_2008';
GO

CREATE PROC Private_GetFullTypeNameTests_2008.[test Private_GetFullTypeName should handle all 2008 compatible data types]
AS
BEGIN

  CREATE TABLE dbo.Parms(
    ColumnName NVARCHAR(MAX),
    ColumnType NVARCHAR(MAX)
  );
    
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.date]', '[sys].[date]');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.datetime2]', '[sys].[datetime2]');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.datetimeoffset]', '[sys].[datetimeoffset]');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.geography]', '[sys].[geography]');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.geometry]', '[sys].[geometry]');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.hierarchyid]', '[sys].[hierarchyid]');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.time]', '[sys].[time]');
  
  DECLARE @Cmd NVARCHAR(MAX);
  SET @Cmd = STUFF((
                    SELECT ', ' + ColumnName + ' ' + ColumnType
                      FROM dbo.Parms
                       FOR XML PATH(''), TYPE
                   ).value('.','NVARCHAR(MAX)'),1,2,'');
  SET @Cmd = 'CREATE TABLE dbo.tst1(' + @Cmd + ');';

  IF OBJECT_ID('dbo.tst1') IS NOT NULL DROP TABLE dbo.tst1;
  EXEC(@Cmd);
  
  SELECT QUOTENAME(c.name) ColumnName, t.TypeName AS ColumnType
    INTO #Actual
    FROM sys.columns c
   CROSS APPLY tSQLt.Private_GetFullTypeName(c.user_type_id,c.max_length, c.precision, c.scale, c.collation_name) t
   WHERE c.object_id = OBJECT_ID('dbo.tst1');

  EXEC tSQLt.AssertEqualsTable 'dbo.Parms','#Actual';
END;
GO
