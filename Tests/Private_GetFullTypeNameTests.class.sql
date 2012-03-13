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
EXEC tSQLt.NewTestClass 'Private_GetFullTypeNameTests';
GO

CREATE PROC Private_GetFullTypeNameTests.[test Private_GetFullTypeName should properly return int parameters]
AS
BEGIN
    DECLARE @Result VARCHAR(MAX);

    SELECT @Result = TypeName
     FROM tSQLt.Private_GetFullTypeName(TYPE_ID('int'), NULL, NULL, NULL, NULL);

    EXEC tSQLt.AssertEqualsString '[sys].[int]', @Result;
END
GO

CREATE PROC Private_GetFullTypeNameTests.[test Private_GetFullTypeName should properly return VARCHAR with length parameters]
AS
BEGIN
    DECLARE @Result VARCHAR(MAX);

    SELECT @Result = TypeName
     FROM tSQLt.Private_GetFullTypeName(TYPE_ID('varchar'), 8, NULL, NULL, NULL);

    EXEC tSQLt.AssertEqualsString '[sys].[varchar](8)', @Result;
END
GO

CREATE PROC Private_GetFullTypeNameTests.[test Private_GetFullTypeName should properly return NVARCHAR with length parameters]
AS
BEGIN
    DECLARE @Result VARCHAR(MAX);

    SELECT @Result = TypeName
     FROM tSQLt.Private_GetFullTypeName(TYPE_ID('nvarchar'), 8, NULL, NULL, NULL);

    EXEC tSQLt.AssertEqualsString '[sys].[nvarchar](4)', @Result;
END
GO

CREATE PROC Private_GetFullTypeNameTests.[test Private_GetFullTypeName should properly return VARCHAR MAX parameters]
AS
BEGIN
    DECLARE @Result VARCHAR(MAX);

    SELECT @Result = TypeName
     FROM tSQLt.Private_GetFullTypeName(TYPE_ID('varchar'), -1, NULL, NULL, NULL);

    EXEC tSQLt.AssertEqualsString '[sys].[varchar](MAX)', @Result;
END
GO

CREATE PROC Private_GetFullTypeNameTests.[test Private_GetFullTypeName should properly return VARBINARY MAX parameters]
AS
BEGIN
    DECLARE @Result VARCHAR(MAX);

    SELECT @Result = TypeName
     FROM tSQLt.Private_GetFullTypeName(TYPE_ID('varbinary'), -1, NULL, NULL, NULL);

    EXEC tSQLt.AssertEqualsString '[sys].[varbinary](MAX)', @Result;
END
GO

CREATE PROC Private_GetFullTypeNameTests.[test Private_GetFullTypeName should properly return DECIMAL parameters]
AS
BEGIN
    DECLARE @Result VARCHAR(MAX);

    SELECT @Result = TypeName
     FROM tSQLt.Private_GetFullTypeName(TYPE_ID('decimal'), NULL, 12, 13, NULL);

    EXEC tSQLt.AssertEqualsString '[sys].[decimal](12,13)', @Result;
END
GO

CREATE PROC Private_GetFullTypeNameTests.[test Private_GetFullTypeName should properly return typeName when all parameters are valued]
AS
BEGIN
    DECLARE @Result VARCHAR(MAX);

    SELECT @Result = TypeName
     FROM tSQLt.Private_GetFullTypeName(TYPE_ID('int'), 1, 1, 1, NULL);

    EXEC tSQLt.AssertEqualsString '[sys].[int]', @Result;
END;
GO

CREATE PROC Private_GetFullTypeNameTests.[test Private_GetFullTypeName should properly return typename when xml]
AS
BEGIN
    DECLARE @Result VARCHAR(MAX);

    SELECT @Result = TypeName
     FROM tSQLt.Private_GetFullTypeName(TYPE_ID('xml'), -1, 0, 0, NULL);

    EXEC tSQLt.AssertEqualsString '[sys].[xml]', @Result;
END;
GO

CREATE PROC Private_GetFullTypeNameTests.[test Private_GetFullTypeName should handle all 2005 compatible data types]
AS
BEGIN

  CREATE TABLE dbo.Parms(
    ColumnName NVARCHAR(MAX),
    ColumnType NVARCHAR(MAX)
  );
    
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.bigint]', '[sys].[bigint]');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.binary]', '[sys].[binary](42)');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.bit]', '[sys].[bit]');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.char]', '[sys].[char](17)');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.datetime]', '[sys].[datetime]');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.decimal]', '[sys].[decimal](12,6)');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.float]', '[sys].[float]');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.image]', '[sys].[image]');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.int]', '[sys].[int]');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.money]', '[sys].[money]');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.nchar]', '[sys].[nchar](15)');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.ntext]', '[sys].[ntext]');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.numeric]', '[sys].[numeric](13,4)');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.nvarchar]', '[sys].[nvarchar](100)');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.nvarcharMax]', '[sys].[nvarchar](MAX)');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.real]', '[sys].[real]');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.smalldatetime]', '[sys].[smalldatetime]');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.smallint]', '[sys].[smallint]');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.smallmoney]', '[sys].[smallmoney]');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.sql_variant]', '[sys].[sql_variant]');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.sysname]', '[sys].[sysname]');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.text]', '[sys].[text]');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.timestamp]', '[sys].[timestamp]');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.tinyint]', '[sys].[tinyint]');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.uniqueidentifier]', '[sys].[uniqueidentifier]');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.varbinary]', '[sys].[varbinary](200)');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.varbinaryMax]', '[sys].[varbinary](MAX)');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.varchar]', '[sys].[varchar](300)');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.varcharMax]', '[sys].[varchar](MAX)');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[sys.xml]', '[sys].[xml]');
  
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
   CROSS APPLY tSQLt.Private_GetFullTypeName(c.user_type_id,c.max_length, c.precision, c.scale, NULL /*Ignore Collations*/) t
   WHERE c.object_id = OBJECT_ID('dbo.tst1');

  EXEC tSQLt.AssertEqualsTable 'dbo.Parms','#Actual';
END;
GO


CREATE PROC Private_GetFullTypeNameTests.[test Private_GetFullTypeName should handle CLR datatype]
AS
BEGIN
  CREATE TABLE dbo.Parms(
    ColumnName NVARCHAR(MAX),
    ColumnType NVARCHAR(MAX)
  );
    
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[tSQLt.Private]', '[tSQLt].[Private]');
  
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
   CROSS APPLY tSQLt.Private_GetFullTypeName(c.user_type_id,c.max_length, c.precision, c.scale, NULL) t
   WHERE c.object_id = OBJECT_ID('dbo.tst1');

  EXEC tSQLt.AssertEqualsTable 'dbo.Parms','#Actual';
END;
GO



CREATE PROC Private_GetFullTypeNameTests.[test Private_GetFullTypeName keeps collation of column]
AS
BEGIN
  CREATE TABLE dbo.Parms(
    ColumnName NVARCHAR(MAX),
    ColumnType NVARCHAR(MAX)
  );
    
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[collated column 1]', '[sys].[varchar](MAX) COLLATE Albanian_CS_AS_KS');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[collated column 2]', '[sys].[varchar](MAX) COLLATE Latin1_General_CI_AS');
  INSERT INTO dbo.Parms(ColumnName, ColumnType) VALUES ('[collated column 3]', '[sys].[varchar](MAX) COLLATE SQL_Lithuanian_CP1257_CI_AS');
  
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
