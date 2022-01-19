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
EXEC tSQLt.NewTestClass 'AssertEqualsTableTests_2008';
GO
CREATE PROCEDURE AssertEqualsTableTests_2008.[test can handle 2008 date data types]
AS
BEGIN
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'DATE', '''2012-01-01'',''2012-06-19'',''2012-10-25''';
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'TIME', '''10:10:10'',''11:11:11'',''12:12:12''';
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'DATETIMEOFFSET', '''2012-01-01 10:10:10.101010 +10:10'',''2012-06-19 11:11:11.111111 +11:11'',''2012-10-25 12:12:12.121212 -12:12''';
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'DATETIME2', '''2012-01-01 10:10:10.101010'',''2012-06-19 11:11:11.111111'',''2012-10-25 12:12:12.121212''';
END;
GO
CREATE PROCEDURE AssertEqualsTableTests_2008.[test can handle hierarchyid data type]
AS
BEGIN
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'HIERARCHYID', '''/10/'',''/11/'',''/12/''';
END;
GO

CREATE PROCEDURE AssertEqualsTableTests_2008.[test all unsupported 2008 data types]
AS
BEGIN
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can NOT handle a datatype] 'GEOMETRY', 'geometry::STPointFromText(''POINT (10 10)'', 0),geometry::STPointFromText(''POINT (11 11)'', 0),geometry::STPointFromText(''POINT (12 12)'', 0)';
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can NOT handle a datatype] 'GEOGRAPHY', 'geography::STGeomFromText(''LINESTRING(-10.10 10.10, -50.10 50.10)'', 4326),geography::STGeomFromText(''LINESTRING(-11.11 11.11, -50.11 50.11)'', 4326),geography::STGeomFromText(''LINESTRING(-12.12 12.12, -50.12 50.12)'', 4326)';
END;
GO



GO

EXEC tSQLt.NewTestClass 'AssertStringInTests_2008';
GO
CREATE PROCEDURE AssertStringInTests_2008.[test fails if set is empty]
AS
BEGIN
  
  EXEC tSQLt_testutil.assertFailCalled @Command = 
    'DECLARE @ExpectedSet tSQLt.AssertStringTable;
     EXEC tSQLt.AssertStringIn 
             @Expected = @ExpectedSet, 
             @Actual = ''Some String'';';
END;
GO
CREATE PROCEDURE AssertStringInTests_2008.[test succeeds if value is the only element]
AS
BEGIN
  
  DECLARE @ExpectedSet tSQLt.AssertStringTable;
  INSERT INTO @ExpectedSet(value)VALUES('Some String');

  EXEC tSQLt.AssertStringIn 
          @Expected = @ExpectedSet, 
          @Actual = 'Some String';

END;
GO
CREATE PROCEDURE AssertStringInTests_2008.[test succeeds if value is one of many elements]
AS
BEGIN
  
  DECLARE @ExpectedSet tSQLt.AssertStringTable;
  INSERT INTO @ExpectedSet(value)VALUES('String 1'),('String 2'),('Some String'),('String 4'),('String 5');

  EXEC tSQLt.AssertStringIn 
          @Expected = @ExpectedSet, 
          @Actual = 'Some String';

END;
GO
CREATE PROCEDURE AssertStringInTests_2008.[test includes string and ordered table in fail message]
AS
BEGIN
  CREATE TABLE #ExpectedSet (value NVARCHAR(MAX));
  INSERT INTO #ExpectedSet(value)VALUES('String 3'),('String 5'),('String 4'),('String 1'),('String 2');
  DECLARE @FailMessage NVARCHAR(MAX);
  EXEC tSQLt_testutil.CaptureFailMessage @Command = 
  '
    DECLARE @ExpectedSet tSQLt.AssertStringTable;
    INSERT INTO @ExpectedSet(value)SELECT value FROM #ExpectedSet;

    EXEC tSQLt.AssertStringIn 
            @Expected = @ExpectedSet, 
            @Actual = ''Missing String'';
  ',
  @FailMessage = @FailMessage OUT;

  DECLARE @ExpectedMessage NVARCHAR(MAX);
  EXEC tSQLt.TableToText @TableName = '#ExpectedSet', @OrderBy = 'value',@txt = @ExpectedMessage OUTPUT;
  SET @ExpectedMessage = 
  '<Missing String>' + CHAR(13)+CHAR(10)+
  'is not in' + CHAR(13)+CHAR(10)+
  @ExpectedMessage;


  EXEC tSQLt.AssertEqualsString @Expected = @ExpectedMessage, @Actual = @FailMessage;
END;
GO
CREATE PROCEDURE AssertStringInTests_2008.[test produces adequate failure message if @Actual = 'NULL']
AS
BEGIN
  CREATE TABLE #ExpectedSet (value NVARCHAR(MAX));
  INSERT INTO #ExpectedSet(value)VALUES('String 3'),('String 5'),('String 4'),('String 1'),('String 2');
  DECLARE @FailMessage NVARCHAR(MAX);
  EXEC tSQLt_testutil.CaptureFailMessage @Command = 
  '
    DECLARE @ExpectedSet tSQLt.AssertStringTable;
    INSERT INTO @ExpectedSet(value)SELECT value FROM #ExpectedSet;

    EXEC tSQLt.AssertStringIn 
            @Expected = @ExpectedSet, 
            @Actual = NULL;
  ',
  @FailMessage = @FailMessage OUT;

  DECLARE @ExpectedMessage NVARCHAR(MAX);
  EXEC tSQLt.TableToText @TableName = '#ExpectedSet', @OrderBy = 'value',@txt = @ExpectedMessage OUTPUT;
  SET @ExpectedMessage = 
  'NULL' + CHAR(13)+CHAR(10)+
  'is not in' + CHAR(13)+CHAR(10)+
  @ExpectedMessage;


  EXEC tSQLt.AssertEqualsString @Expected = @ExpectedMessage, @Actual = @FailMessage;
END;
GO
CREATE PROCEDURE AssertStringInTests_2008.[test produces adequate failure message if @Expected is empty]
AS
BEGIN
  DECLARE @FailMessage NVARCHAR(MAX);
  EXEC tSQLt_testutil.CaptureFailMessage @Command = 
  '
    DECLARE @ExpectedSet tSQLt.AssertStringTable;
    EXEC tSQLt.AssertStringIn 
            @Expected = @ExpectedSet, 
            @Actual = ''Missing String'';
  ',
  @FailMessage = @FailMessage OUT;

  DECLARE @ExpectedMessage NVARCHAR(MAX);
  CREATE TABLE #ExpectedSet (value NVARCHAR(MAX));
  EXEC tSQLt.TableToText @TableName = '#ExpectedSet', @OrderBy = 'value',@txt = @ExpectedMessage OUTPUT;
  SET @ExpectedMessage = 
  '<Missing String>' + CHAR(13)+CHAR(10)+
  'is not in' + CHAR(13)+CHAR(10)+
  @ExpectedMessage;


  EXEC tSQLt.AssertEqualsString @Expected = @ExpectedMessage, @Actual = @FailMessage;
END;
GO
CREATE PROCEDURE AssertStringInTests_2008.[test produces adequate failure message if @Expected is empty and @Actual is NULL]
AS
BEGIN
  DECLARE @FailMessage NVARCHAR(MAX);
  EXEC tSQLt_testutil.CaptureFailMessage @Command = 
  '
    DECLARE @ExpectedSet tSQLt.AssertStringTable;
    EXEC tSQLt.AssertStringIn 
            @Expected = @ExpectedSet, 
            @Actual = NULL;
  ',
  @FailMessage = @FailMessage OUT;

  DECLARE @ExpectedMessage NVARCHAR(MAX);
  CREATE TABLE #ExpectedSet (value NVARCHAR(MAX));
  EXEC tSQLt.TableToText @TableName = '#ExpectedSet', @OrderBy = 'value',@txt = @ExpectedMessage OUTPUT;
  SET @ExpectedMessage = 
  'NULL' + CHAR(13)+CHAR(10)+
  'is not in' + CHAR(13)+CHAR(10)+
  @ExpectedMessage;


  EXEC tSQLt.AssertEqualsString @Expected = @ExpectedMessage, @Actual = @FailMessage;
END;
GO
CREATE PROC AssertStringInTests_2008.[test AssertStringIn passes supplied message before original failure message when calling fail]
AS
BEGIN
  EXEC tSQLt_testutil.AssertFailMessageLike 
    '
    DECLARE @ExpectedSet tSQLt.AssertStringTable;
    EXEC tSQLt.AssertStringIn 
            @Expected = @ExpectedSet, 
            @Actual = NULL,
            @Message = ''{MyMessage}'';
  ',
  '{MyMessage}%NULL%value%';
END;
GO


--message


GO

EXEC tSQLt.NewTestClass 'FakeFunctionTests_2008';
GO
CREATE TYPE FakeFunctionTests_2008.TableType1001 AS TABLE(SomeInt INT);
GO
CREATE PROCEDURE FakeFunctionTests_2008.[test can fake funktion with table-type parameter]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.AFunction(@p1 int, @p2 FakeFunctionTests_2008.TableType1001 READONLY, @p3 INT) RETURNS INT AS BEGIN RETURN 0; END;');
  EXEC('CREATE FUNCTION FakeFunctionTests.Fake(@p1 INT,@p2 FakeFunctionTests_2008.TableType1001 READONLY,@p3 INT) RETURNS INT AS BEGIN RETURN (SELECT SUM(SomeInt)+@p1+@p3 FROM @p2); END;');
  
  EXEC tSQLt.FakeFunction @FunctionName = 'FakeFunctionTests.AFunction', @FakeFunctionName = 'FakeFunctionTests.Fake';

  DECLARE @Actual INT;
  DECLARE @TableParameter FakeFunctionTests_2008.TableType1001;
  INSERT INTO @TableParameter(SomeInt)VALUES(10);
  INSERT INTO @TableParameter(SomeInt)VALUES(202);
  INSERT INTO @TableParameter(SomeInt)VALUES(3303);

  SET @Actual = FakeFunctionTests.AFunction(10000,@TableParameter,220000);
  EXEC tSQLt.AssertEqualsString @Expected = 233515, @Actual = @Actual;
END;
GO


GO

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


GO


--> New Direction: Drop schema bound objects and offer option to recreate as needed.

EXEC tSQLt.NewTestClass 'Private_RemoveSchemaBindingTests_2008';
GO
CREATE PROCEDURE Private_RemoveSchemaBindingTests_2008.[Assert SB property on view is removed and view is still working]
  @CreateViewStatement NVARCHAR(MAX)
AS
BEGIN
  CREATE TABLE Private_RemoveSchemaBindingTests_2008.T1(C1 INT);
  INSERT INTO Private_RemoveSchemaBindingTests_2008.T1(C1)
  VALUES(CHECKSUM(NEWID()));
  INSERT INTO Private_RemoveSchemaBindingTests_2008.T1(C1)
  VALUES(CHECKSUM(NEWID()));
  INSERT INTO Private_RemoveSchemaBindingTests_2008.T1(C1)
  VALUES(CHECKSUM(NEWID()));

  EXEC(@CreateViewStatement);
 
  DECLARE @object_id INT;SET @object_id = OBJECT_ID('Private_RemoveSchemaBindingTests_2008.V1');
  EXEC tSQLt.Private_RemoveSchemaBinding @object_id = @object_id;

  SELECT QUOTENAME(OBJECT_SCHEMA_NAME(SED.referencing_id))+'.'+QUOTENAME(OBJECT_NAME(SED.referencing_id)) AS schema_bound_object_name,SED.referencing_id,SED.referencing_class_desc
    INTO #SchemaBoundObjects
    FROM sys.sql_expression_dependencies AS SED 
   WHERE SED.is_schema_bound_reference = 1
     AND SED.referenced_id = OBJECT_ID('Private_RemoveSchemaBindingTests_2008.T1');

  EXEC tSQLt.AssertEmptyTable @TableName = '#SchemaBoundObjects';

  SELECT * 
    INTO Private_RemoveSchemaBindingTests_2008.Actual
    FROM Private_RemoveSchemaBindingTests_2008.V1;

  EXEC tSQLt.AssertEqualsTable 'Private_RemoveSchemaBindingTests_2008.T1','Private_RemoveSchemaBindingTests_2008.Actual';  
END;
GO
CREATE PROCEDURE Private_RemoveSchemaBindingTests_2008.[test SB property on view is removed and view is still working]
AS
BEGIN
  EXEC Private_RemoveSchemaBindingTests_2008.[Assert SB property on view is removed and view is still working]
    'CREATE VIEW Private_RemoveSchemaBindingTests_2008.V1 WITH SCHEMABINDING AS SELECT T.C1 FROM Private_RemoveSchemaBindingTests_2008.T1 AS T;';
END;
GO
CREATE PROCEDURE Private_RemoveSchemaBindingTests_2008.[test does not remove second W/SB statement]
AS
BEGIN
  CREATE TABLE Private_RemoveSchemaBindingTests_2008.T1(C1 INT);
  EXEC('CREATE VIEW Private_RemoveSchemaBindingTests_2008.V1 WITH SCHEMABINDING AS SELECT T.C1,''CREATE VIEW dbo.test WITH SCHEMABINDING'' AS C2 FROM Private_RemoveSchemaBindingTests_2008.T1 AS T;');
  INSERT INTO Private_RemoveSchemaBindingTests_2008.T1(C1)
  VALUES(42);
 
  DECLARE @object_id INT;SET @object_id = OBJECT_ID('Private_RemoveSchemaBindingTests_2008.V1');
  EXEC tSQLt.Private_RemoveSchemaBinding @object_id = @object_id;

  SELECT C1,C2
    INTO #Actual
    FROM Private_RemoveSchemaBindingTests_2008.V1;

  SELECT TOP(0) *
  INTO #Expected
  FROM #Actual;

  INSERT INTO #Expected
  VALUES(42,'CREATE VIEW dbo.test WITH SCHEMABINDING');
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROCEDURE Private_RemoveSchemaBindingTests_2008.[test handles leading spaces]
AS
BEGIN
  EXEC Private_RemoveSchemaBindingTests_2008.[Assert SB property on view is removed and view is still working]
    '   CREATE VIEW Private_RemoveSchemaBindingTests_2008.V1 WITH SCHEMABINDING AS SELECT T.C1 FROM Private_RemoveSchemaBindingTests_2008.T1 AS T;';
END;
GO
CREATE PROCEDURE Private_RemoveSchemaBindingTests_2008.[test handles newlines]
AS
BEGIN
  EXEC Private_RemoveSchemaBindingTests_2008.[Assert SB property on view is removed and view is still working]
    '
  CREATE 
  VIEW 
  Private_RemoveSchemaBindingTests_2008.V1 
  WITH 
  SCHEMABINDING 
  AS SELECT T.C1 FROM Private_RemoveSchemaBindingTests_2008.T1 AS T;';
END;
GO
CREATE PROCEDURE Private_RemoveSchemaBindingTests_2008.[test handles leading one line comments]
AS
BEGIN
  EXEC Private_RemoveSchemaBindingTests_2008.[Assert SB property on view is removed and view is still working]
    '-- test 
        CREATE VIEW Private_RemoveSchemaBindingTests_2008.V1 WITH SCHEMABINDING AS SELECT T.C1 FROM Private_RemoveSchemaBindingTests_2008.T1 AS T;';
END;
GO
CREATE PROCEDURE Private_RemoveSchemaBindingTests_2008.[test handles leading one line comments with CREATE VIEW statement]
AS
BEGIN
  EXEC Private_RemoveSchemaBindingTests_2008.[Assert SB property on view is removed and view is still working]
    '-- test: CREATE VIEW Private_RemoveSchemaBindingTests_2008.V1 WITH SCHEMABINDING AS 
        -- test2: CREATE VIEW Private_RemoveSchemaBindingTests_2008.V1 WITH SCHEMABINDING AS 
        --
        CREATE VIEW Private_RemoveSchemaBindingTests_2008.V1 WITH SCHEMABINDING AS SELECT T.C1 FROM Private_RemoveSchemaBindingTests_2008.T1 AS T;';
END;
GO
CREATE PROCEDURE Private_RemoveSchemaBindingTests_2008.[test handles leading multi-line comments with CREATE VIEW statement]
AS
BEGIN
  EXEC Private_RemoveSchemaBindingTests_2008.[Assert SB property on view is removed and view is still working]
    '/* test: CREATE VIEW Private_RemoveSchemaBindingTests_2008.V1 WITH SCHEMABINDING AS 
        -- test2: CREATE VIEW Private_RemoveSchemaBindingTests_2008.V1 WITH SCHEMABINDING AS 
        */CREATE VIEW Private_RemoveSchemaBindingTests_2008.V1 WITH SCHEMABINDING AS SELECT T.C1 FROM Private_RemoveSchemaBindingTests_2008.T1 AS T;';
END;
GO
CREATE PROCEDURE Private_RemoveSchemaBindingTests_2008.[test handles leading double nested multi-line comments]
AS
BEGIN
  EXEC Private_RemoveSchemaBindingTests_2008.[Assert SB property on view is removed and view is still working]
    '/* test: CREATE VIEW Private_RemoveSchemaBindingTests_2008.V1 WITH SCHEMABINDING AS 
        /* test: CREATE VIEW Private_RemoveSchemaBindingTests_2008.V1 WITH SCHEMABINDING AS 
        */ test: CREATE VIEW Private_RemoveSchemaBindingTests_2008.V1 WITH SCHEMABINDING AS 
        */CREATE VIEW Private_RemoveSchemaBindingTests_2008.V1 WITH SCHEMABINDING AS SELECT T.C1 FROM Private_RemoveSchemaBindingTests_2008.T1 AS T;';
END;
GO
CREATE PROCEDURE Private_RemoveSchemaBindingTests_2008.[test handles leading nested multi-line comments and other niceties with CREATE VIEW statement]
AS
BEGIN
  EXEC Private_RemoveSchemaBindingTests_2008.[Assert SB property on view is removed and view is still working]
    '/* /test: CREATE VIEW Private_RemoveSchemaBindingTests_2008.V1 WITH SCHEMABINDING AS 
        /* /test: CREATE VIEW Private_RemoveSchemaBindingTests_2008.V1 WITH SCHEMABINDING AS 
        /* /test: CREATE VIEW Private_RemoveSchemaBindingTests_2008.V1 WITH SCHEMABINDING AS 
        -- *test2: CREATE VIEW Private_RemoveSchemaBindingTests_2008.V1 WITH SCHEMABINDING AS 
        */-- *test2: CREATE VIEW Private_RemoveSchemaBindingTests_2008.V1 WITH SCHEMABINDING AS 
        */-- *test2: CREATE VIEW Private_RemoveSchemaBindingTests_2008.V1 WITH SCHEMABINDING AS 
        */--/*
        CREATE VIEW Private_RemoveSchemaBindingTests_2008.V1 WITH SCHEMABINDING AS SELECT T.C1 FROM Private_RemoveSchemaBindingTests_2008.T1 AS T;';
END;
GO
CREATE PROCEDURE Private_RemoveSchemaBindingTests_2008.[test works on indexed view]
AS
BEGIN
  CREATE TABLE Private_RemoveSchemaBindingTests_2008.T1(C1 INT);
  EXEC('CREATE VIEW Private_RemoveSchemaBindingTests_2008.V1 WITH SCHEMABINDING AS SELECT T.C1,''A Constant'' AS C2 FROM Private_RemoveSchemaBindingTests_2008.T1 AS T;');
  EXEC('CREATE UNIQUE CLUSTERED INDEX [CI:V1] ON Private_RemoveSchemaBindingTests_2008.V1(C1);');
  EXEC('CREATE NONCLUSTERED INDEX [NCI:V1] ON Private_RemoveSchemaBindingTests_2008.V1(C2);');
  INSERT INTO Private_RemoveSchemaBindingTests_2008.T1(C1)
  VALUES(42);
 
  DECLARE @object_id INT;SET @object_id = OBJECT_ID('Private_RemoveSchemaBindingTests_2008.V1');
  EXEC tSQLt.Private_RemoveSchemaBinding @object_id = @object_id;

  SELECT C1,C2
    INTO #Actual
    FROM Private_RemoveSchemaBindingTests_2008.V1;

  SELECT TOP(0) *
  INTO #Expected
  FROM #Actual;

  INSERT INTO #Expected
  VALUES(42,'A Constant');
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO


/*
-- Comments before create view including 
-- superflous whitespace (CREATE VIEW as well as WITH SCHEMABINDING)
-- indexed views
-- computed columns
-- indexed computed columns
-- other object types: (see remarks) http://msdn.microsoft.com/en-us/library/bb677315.aspx 


  SELECT * FROM sys.sql_expression_dependencies AS SED 
  JOIN sys.sql_modules AS SM
  ON SED.referencing_id = SM.object_id
  WHERE SED.referenced_id = OBJECT_ID('Private_RemoveSchemaBindingTests_2008.T1');


-- /*
-- PRINT 1;
-- --/*
-- PRINT 1;
-- /*
-- PRINT 1;
-- --*/
-- PRINT 1;
-- --*/
-- PRINT 1;
-- --*/
-- PRINT 1;





--*/


GO

EXEC tSQLt.NewTestClass 'Private_RemoveSchemBoundReferencesTests_2008';
GO
CREATE PROCEDURE Private_RemoveSchemBoundReferencesTests_2008.[test calls RemoveSchemaBinding for single view]
AS
BEGIN
  CREATE TABLE Private_RemoveSchemBoundReferencesTests_2008.T1(C1 INT);
  EXEC('CREATE VIEW Private_RemoveSchemBoundReferencesTests_2008.V1 WITH SCHEMABINDING AS SELECT T.C1 FROM Private_RemoveSchemBoundReferencesTests_2008.T1 AS T;');

  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_RemoveSchemaBinding';

  DECLARE @object_id INT;SET @object_id = OBJECT_ID('Private_RemoveSchemBoundReferencesTests_2008.T1');
  EXEC tSQLt.Private_RemoveSchemaBoundReferences @object_id = @object_id;

  SELECT object_id 
    INTO #Actual
    FROM tSQLt.Private_RemoveSchemaBinding_SpyProcedureLog;

  SELECT TOP(0) *
  INTO #Expected
  FROM #Actual;
  
  INSERT INTO #Expected
  VALUES(OBJECT_ID('Private_RemoveSchemBoundReferencesTests_2008.V1'));

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
  
END;
GO
CREATE PROCEDURE Private_RemoveSchemBoundReferencesTests_2008.[test calls RemoveSchemaBinding for multiple views]
AS
BEGIN
  CREATE TABLE Private_RemoveSchemBoundReferencesTests_2008.T1(C1 INT);
  EXEC('CREATE VIEW Private_RemoveSchemBoundReferencesTests_2008.V1 WITH SCHEMABINDING AS SELECT T.C1 FROM Private_RemoveSchemBoundReferencesTests_2008.T1 AS T;');
  EXEC('CREATE VIEW Private_RemoveSchemBoundReferencesTests_2008.V2 WITH SCHEMABINDING AS SELECT T.C1 FROM Private_RemoveSchemBoundReferencesTests_2008.T1 AS T;');
  EXEC('CREATE VIEW Private_RemoveSchemBoundReferencesTests_2008.V3 WITH SCHEMABINDING AS SELECT T.C1 FROM Private_RemoveSchemBoundReferencesTests_2008.T1 AS T;');

  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_RemoveSchemaBinding';

  DECLARE @object_id INT;SET @object_id = OBJECT_ID('Private_RemoveSchemBoundReferencesTests_2008.T1');
  EXEC tSQLt.Private_RemoveSchemaBoundReferences @object_id = @object_id;

  SELECT object_id 
    INTO #Actual
    FROM tSQLt.Private_RemoveSchemaBinding_SpyProcedureLog;

  SELECT TOP(0) *
  INTO #Expected
  FROM #Actual;
  
  INSERT INTO #Expected
  VALUES(OBJECT_ID('Private_RemoveSchemBoundReferencesTests_2008.V1'));
  INSERT INTO #Expected
  VALUES(OBJECT_ID('Private_RemoveSchemBoundReferencesTests_2008.V2'));
  INSERT INTO #Expected
  VALUES(OBJECT_ID('Private_RemoveSchemBoundReferencesTests_2008.V3'));

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
  
END;
GO
CREATE PROCEDURE Private_RemoveSchemBoundReferencesTests_2008.[test calls RemoveSchemaBinding for multiple recursive views]
AS
BEGIN
  CREATE TABLE Private_RemoveSchemBoundReferencesTests_2008.T1(C1 INT);
  EXEC('CREATE VIEW Private_RemoveSchemBoundReferencesTests_2008.V1 WITH SCHEMABINDING AS SELECT T.C1 FROM Private_RemoveSchemBoundReferencesTests_2008.T1 AS T;');
  EXEC('CREATE VIEW Private_RemoveSchemBoundReferencesTests_2008.V2 WITH SCHEMABINDING AS SELECT T.C1 FROM Private_RemoveSchemBoundReferencesTests_2008.V1 AS T;');
  EXEC('CREATE VIEW Private_RemoveSchemBoundReferencesTests_2008.V3 WITH SCHEMABINDING AS SELECT T.C1 FROM Private_RemoveSchemBoundReferencesTests_2008.V2 AS T;');

  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_RemoveSchemaBinding';

  DECLARE @object_id INT;SET @object_id = OBJECT_ID('Private_RemoveSchemBoundReferencesTests_2008.T1');
  EXEC tSQLt.Private_RemoveSchemaBoundReferences @object_id = @object_id;

  SELECT _id_*1 call_order,object_id 
    INTO #Actual
    FROM tSQLt.Private_RemoveSchemaBinding_SpyProcedureLog;

  SELECT TOP(0) *
  INTO #Expected
  FROM #Actual;
  
  INSERT INTO #Expected
  VALUES(1, OBJECT_ID('Private_RemoveSchemBoundReferencesTests_2008.V3'));
  INSERT INTO #Expected
  VALUES(2, OBJECT_ID('Private_RemoveSchemBoundReferencesTests_2008.V2'));
  INSERT INTO #Expected
  VALUES(3, OBJECT_ID('Private_RemoveSchemBoundReferencesTests_2008.V1'));

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
  
END;
GO


GO

EXEC tSQLt.NewTestClass 'Private_ScriptIndexTests_2008';
GO
CREATE PROCEDURE Private_ScriptIndexTests_2008.[test handles filter]
AS
BEGIN
  EXEC Private_ScriptIndexTests.[assert index is scripted correctly]
    @index_create_cmd = 'CREATE UNIQUE NONCLUSTERED INDEX [Private_ScriptIndexTests.T1 - IDX1] ON [Private_ScriptIndexTests].[T1]([C1]ASC,[C3]DESC)INCLUDE([C4],[C2])WHERE([C1]=(3));';
END;
GO
CREATE PROCEDURE Private_ScriptIndexTests.[test handles hypothetical index]
AS
BEGIN
  EXEC Private_ScriptIndexTests.[assert index is scripted correctly]
    @index_create_cmd = 'CREATE UNIQUE NONCLUSTERED INDEX [Private_ScriptIndexTests.T1 - IDX1] ON [Private_ScriptIndexTests].[T1]([C1]ASC,[C3]DESC)INCLUDE([C4],[C2])WITH(STATISTICS_ONLY = -1);';
END;
GO
CREATE PROCEDURE Private_ScriptIndexTests_2008.[test handles hypothetical filtered index]
AS
BEGIN
  EXEC Private_ScriptIndexTests.[assert index is scripted correctly]
    @index_create_cmd = 'CREATE UNIQUE NONCLUSTERED INDEX [Private_ScriptIndexTests.T1 - IDX1] ON [Private_ScriptIndexTests].[T1]([C1]ASC,[C3]DESC)INCLUDE([C4],[C2])WHERE([C1]=(3))WITH(STATISTICS_ONLY = -1);';
END;
GO


GO

EXEC tSQLt.NewTestClass 'Private_SqlVariantFormatterTests_2008';
GO
CREATE PROC Private_SqlVariantFormatterTests_2008.[test formats new 2008 data types]
AS
BEGIN
  CREATE TABLE #Input(
    [DATE] DATE,
    [DATETIME2] DATETIME2,
    [DATETIMEOFFSET] DATETIMEOFFSET,
    [TIME] TIME
  );
  INSERT INTO #Input
  SELECT
    '2013-04-05' AS [DATE],
    '2013-04-05T06:07:08.9876543' AS [DATETIME2],
    '2013-04-05T06:07:08.9876543+02:01' AS [DATETIMEOFFSET],
    '06:07:08.9876543'AS [TIME];

  CREATE TABLE #Actual(
    [DATE] NVARCHAR(MAX),
    [DATETIME2] NVARCHAR(MAX),
    [DATETIMEOFFSET] NVARCHAR(MAX),
    [TIME] NVARCHAR(MAX)
  );
  INSERT INTO #Actual
  SELECT
    tSQLt.Private_SqlVariantFormatter([DATE]) AS [DATE],
    tSQLt.Private_SqlVariantFormatter([DATETIME2]) AS [DATETIME2],
    tSQLt.Private_SqlVariantFormatter([DATETIMEOFFSET]) AS [DATETIMEOFFSET],
    tSQLt.Private_SqlVariantFormatter([TIME]) AS [TIME]
  FROM #Input;

  SELECT TOP(0) * INTO #Expected FROM #Actual;
  INSERT INTO #Expected
  SELECT
    '2013-04-05' AS [DATE],
    '2013-04-05T06:07:08.9876543' AS [DATETIME2],
    '2013-04-05T06:07:08.9876543+02:01' AS [DATETIMEOFFSET],
    '06:07:08.9876543' AS [TIME];

  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO


GO

EXEC tSQLt.NewTestClass 'Run_Methods_Tests_2008';
GO
--Valid JUnit XML Schema
--Source:https://raw.githubusercontent.com/windyroad/JUnit-Schema/master/JUnit.xsd
DECLARE @cmd NVARCHAR(MAX);SET @cmd = 
'<?xml version="1.0" encoding="UTF-8"?>

<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema"
	 elementFormDefault="qualified"
	 attributeFormDefault="unqualified">
	<xs:annotation>
		<xs:documentation xml:lang="en">JUnit test result schema for the Apache Ant JUnit and JUnitReport tasks
Copyright � 2011, Windy Road Technology Pty. Limited
The Apache Ant JUnit XML Schema is distributed under the terms of the Apache License Version 2.0 http://www.apache.org/licenses/
Permission to waive conditions of this license may be requested from Windy Road Support (http://windyroad.org/support).</xs:documentation>
	</xs:annotation>
	<xs:element name="testsuite" type="testsuite"/>
	<xs:simpleType name="ISO8601_DATETIME_PATTERN">
		<xs:restriction base="xs:dateTime">
			<xs:pattern value="[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}"/>
		</xs:restriction>
	</xs:simpleType>
	<xs:element name="testsuites">
		<xs:annotation>
			<xs:documentation xml:lang="en">Contains an aggregation of testsuite results</xs:documentation>
		</xs:annotation>
		<xs:complexType>
			<xs:sequence>
				<xs:element name="testsuite" minOccurs="0" maxOccurs="unbounded">
					<xs:complexType>
						<xs:complexContent>
							<xs:extension base="testsuite">
								<xs:attribute name="package" type="xs:token" use="required">
									<xs:annotation>
										<xs:documentation xml:lang="en">Derived from testsuite/@name in the non-aggregated documents</xs:documentation>
									</xs:annotation>
								</xs:attribute>
								<xs:attribute name="id" type="xs:int" use="required">
									<xs:annotation>
										<xs:documentation xml:lang="en">Starts at ''0'' for the first testsuite and is incremented by 1 for each following testsuite</xs:documentation>
									</xs:annotation>
								</xs:attribute>
							</xs:extension>
						</xs:complexContent>
					</xs:complexType>
				</xs:element>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:complexType name="testsuite">
		<xs:annotation>
			<xs:documentation xml:lang="en">Contains the results of exexuting a testsuite</xs:documentation>
		</xs:annotation>
		<xs:sequence>
			<xs:element name="properties">
				<xs:annotation>
					<xs:documentation xml:lang="en">Properties (e.g., environment settings) set during test execution</xs:documentation>
				</xs:annotation>
				<xs:complexType>
					<xs:sequence>
						<xs:element name="property" minOccurs="0" maxOccurs="unbounded">
							<xs:complexType>
								<xs:attribute name="name" use="required">
									<xs:simpleType>
										<xs:restriction base="xs:token">
											<xs:minLength value="1"/>
										</xs:restriction>
									</xs:simpleType>
								</xs:attribute>
								<xs:attribute name="value" type="xs:string" use="required"/>
							</xs:complexType>
						</xs:element>
					</xs:sequence>
				</xs:complexType>
			</xs:element>
			<xs:element name="testcase" minOccurs="0" maxOccurs="unbounded">
				<xs:complexType>
					<xs:choice minOccurs="0">
						<xs:element name="error">
			<xs:annotation>
				<xs:documentation xml:lang="en">Indicates that the test errored.  An errored test is one that had an unanticipated problem. e.g., an unchecked throwable; or a problem with the implementation of the test. Contains as a text node relevant data for the error, e.g., a stack trace</xs:documentation>
			</xs:annotation>
							<xs:complexType>
								<xs:simpleContent>
									<xs:extension base="pre-string">
										<xs:attribute name="message" type="xs:string">
											<xs:annotation>
												<xs:documentation xml:lang="en">The error message. e.g., if a java exception is thrown, the return value of getMessage()</xs:documentation>
											</xs:annotation>
										</xs:attribute>
										<xs:attribute name="type" type="xs:string" use="required">
											<xs:annotation>
												<xs:documentation xml:lang="en">The type of error that occured. e.g., if a java execption is thrown the full class name of the exception.</xs:documentation>
											</xs:annotation>
										</xs:attribute>
									</xs:extension>
								</xs:simpleContent>
							</xs:complexType>
						</xs:element>
						<xs:element name="failure">
			<xs:annotation>
				<xs:documentation xml:lang="en">Indicates that the test failed. A failure is a test which the code has explicitly failed by using the mechanisms for that purpose. e.g., via an assertEquals. Contains as a text node relevant data for the failure, e.g., a stack trace</xs:documentation>
			</xs:annotation>
							<xs:complexType>
								<xs:simpleContent>
									<xs:extension base="pre-string">
										<xs:attribute name="message" type="xs:string">
											<xs:annotation>
												<xs:documentation xml:lang="en">The message specified in the assert</xs:documentation>
											</xs:annotation>
										</xs:attribute>
										<xs:attribute name="type" type="xs:string" use="required">
											<xs:annotation>
												<xs:documentation xml:lang="en">The type of the assert.</xs:documentation>
											</xs:annotation>
										</xs:attribute>
									</xs:extension>
								</xs:simpleContent>
							</xs:complexType>
						</xs:element>
					</xs:choice>
					<xs:attribute name="name" type="xs:token" use="required">
						<xs:annotation>
							<xs:documentation xml:lang="en">Name of the test method</xs:documentation>
						</xs:annotation>
					</xs:attribute>
					<xs:attribute name="classname" type="xs:token" use="required">
						<xs:annotation>
							<xs:documentation xml:lang="en">Full class name for the class the test method is in.</xs:documentation>
						</xs:annotation>
					</xs:attribute>
					<xs:attribute name="time" type="xs:decimal" use="required">
						<xs:annotation>
							<xs:documentation xml:lang="en">Time taken (in seconds) to execute the test</xs:documentation>
						</xs:annotation>
					</xs:attribute>
				</xs:complexType>
			</xs:element>
			<xs:element name="system-out">
				<xs:annotation>
					<xs:documentation xml:lang="en">Data that was written to standard out while the test was executed</xs:documentation>
				</xs:annotation>
				<xs:simpleType>
					<xs:restriction base="pre-string">
						<xs:whiteSpace value="preserve"/>
					</xs:restriction>
				</xs:simpleType>
			</xs:element>
			<xs:element name="system-err">
				<xs:annotation>
					<xs:documentation xml:lang="en">Data that was written to standard error while the test was executed</xs:documentation>
				</xs:annotation>
				<xs:simpleType>
					<xs:restriction base="pre-string">
						<xs:whiteSpace value="preserve"/>
					</xs:restriction>
				</xs:simpleType>
			</xs:element>
		</xs:sequence>
		<xs:attribute name="name" use="required">
			<xs:annotation>
				<xs:documentation xml:lang="en">Full class name of the test for non-aggregated testsuite documents. Class name without the package for aggregated testsuites documents</xs:documentation>
			</xs:annotation>
			<xs:simpleType>
				<xs:restriction base="xs:token">
					<xs:minLength value="1"/>
				</xs:restriction>
			</xs:simpleType>
		</xs:attribute>
		<xs:attribute name="timestamp" type="ISO8601_DATETIME_PATTERN" use="required">
			<xs:annotation>
				<xs:documentation xml:lang="en">when the test was executed. Timezone may not be specified.</xs:documentation>
			</xs:annotation>
		</xs:attribute>
		<xs:attribute name="hostname" use="required">
			<xs:annotation>
				<xs:documentation xml:lang="en">Host on which the tests were executed. ''localhost'' should be used if the hostname cannot be determined.</xs:documentation>
			</xs:annotation>
			<xs:simpleType>
				<xs:restriction base="xs:token">
					<xs:minLength value="1"/>
				</xs:restriction>
			</xs:simpleType>
		</xs:attribute>
		<xs:attribute name="tests" type="xs:int" use="required">
			<xs:annotation>
				<xs:documentation xml:lang="en">The total number of tests in the suite</xs:documentation>
			</xs:annotation>
		</xs:attribute>
		<xs:attribute name="failures" type="xs:int" use="required">
			<xs:annotation>
				<xs:documentation xml:lang="en">The total number of tests in the suite that failed. A failure is a test which the code has explicitly failed by using the mechanisms for that purpose. e.g., via an assertEquals</xs:documentation>
			</xs:annotation>
		</xs:attribute>
		<xs:attribute name="errors" type="xs:int" use="required">
			<xs:annotation>
				<xs:documentation xml:lang="en">The total number of tests in the suite that errorrd. An errored test is one that had an unanticipated problem. e.g., an unchecked throwable; or a problem with the implementation of the test.</xs:documentation>
			</xs:annotation>
		</xs:attribute>
		<xs:attribute name="time" type="xs:decimal" use="required">
			<xs:annotation>
				<xs:documentation xml:lang="en">Time taken (in seconds) to execute the tests in the suite</xs:documentation>
			</xs:annotation>
		</xs:attribute>
	</xs:complexType>
	<xs:simpleType name="pre-string">
		<xs:restriction base="xs:string">
			<xs:whiteSpace value="preserve"/>
		</xs:restriction>
	</xs:simpleType>
</xs:schema>';
SET @cmd = 'CREATE XML SCHEMA COLLECTION Run_Methods_Tests_2008.ValidJUnitXML AS '''+REPLACE(REPLACE(@cmd,'''',''''''),'�','(c)')+''';';
--EXEC(@cmd);
EXEC tSQLt.CaptureOutput @cmd;
GO
CREATE PROC Run_Methods_Tests_2008.[test XmlResultFormatter returns XML that validates against the JUnit specification]
AS
BEGIN
    EXEC tSQLt.FakeTable @TableName = 'tSQLt.TestResult';
    EXEC tSQLt.SpyProcedure 'tSQLt.Private_PrintXML';

    DELETE FROM tSQLt.TestResult;
    INSERT INTO tSQLt.TestResult (Class, TestCase, Result, TestStartTime, TestEndTime)
    VALUES ('MyTestClass1', 'testA', 'Failure', '2015-07-24T00:00:01.000', '2015-07-24T00:00:01.138');
    INSERT INTO tSQLt.TestResult (Class, TestCase, Result, TestStartTime, TestEndTime)
    VALUES ('MyTestClass1', 'testB', 'Success', '2015-07-24T00:00:02.000', '2015-07-24T00:00:02.633');
    INSERT INTO tSQLt.TestResult (Class, TestCase, Result, TestStartTime, TestEndTime)
    VALUES ('MyTestClass2', 'testC', 'Failure', '2015-07-24T00:00:01.111', '2015-07-24T20:31:24.758');
    INSERT INTO tSQLt.TestResult (Class, TestCase, Result, TestStartTime, TestEndTime)
    VALUES ('MyTestClass2', 'testD', 'Error', '2015-07-24T00:00:00.667', '2015-07-24T00:00:01.055');
    
    EXEC tSQLt.XmlResultFormatter;

    EXEC tSQLt.ExpectNoException;
    DECLARE @XML XML(Run_Methods_Tests_2008.ValidJUnitXML);
    SELECT @XML = CAST(Message AS XML) FROM tSQLt.Private_PrintXML_SpyProcedureLog;
   
END;
GO
CREATE PROCEDURE Run_Methods_Tests_2008.[test tSQLt.Private_InputBuffer does not produce output]
AS
BEGIN
  DECLARE @Actual NVARCHAR(MAX);SET @Actual = '<Something went wrong!>';

  EXEC tSQLt.CaptureOutput 'DECLARE @r NVARCHAR(MAX);EXEC tSQLt.Private_InputBuffer @r OUT;';

  SELECT @Actual  = COL.OutputText FROM tSQLt.CaptureOutputLog AS COL;
  
  EXEC tSQLt.AssertEqualsString @Expected = NULL, @Actual = @Actual;
END
GO


GO

EXEC tSQLt.NewTestClass 'SpyProcedureTests_2008';
GO
CREATE TYPE SpyProcedureTests_2008.TableType1001 AS TABLE(SomeInt INT, SomeVarChar VARCHAR(10));
GO
CREATE PROC SpyProcedureTests_2008.[test SpyProcedure can have a table type parameter]
AS
BEGIN
  EXEC('CREATE PROC SpyProcedureTests_2008.InnerProcedure @P1 SpyProcedureTests_2008.TableType1001 READONLY AS EXEC tSQLt.Fail ''InnerProcedure was executed;''');

  EXEC tSQLt.SpyProcedure 'SpyProcedureTests_2008.InnerProcedure';

  DECLARE @TableParameter SpyProcedureTests_2008.TableType1001;
  INSERT INTO @TableParameter(SomeInt,SomeVarChar)VALUES(10,'S1');
  INSERT INTO @TableParameter(SomeInt,SomeVarChar)VALUES(202,'V2');
  INSERT INTO @TableParameter(SomeInt,SomeVarChar)VALUES(3303,'C3');

  DECLARE @InnerProcedure VARCHAR(MAX);SET @InnerProcedure = 'SpyProcedureTests_2008.InnerProcedure'
  EXEC @InnerProcedure @P1 = @TableParameter; 

  SELECT RowNode.value('SomeInt[1]','INT') SomeInt,RowNode.value('SomeVarChar[1]','VARCHAR(10)') SomeVarChar
    INTO #Actual
    FROM SpyProcedureTests_2008.InnerProcedure_SpyProcedureLog
   CROSS APPLY P1.nodes('P1/row') AS N(RowNode);  
  
  SELECT *
  INTO #Expected
  FROM @TableParameter AS TP;
 
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
    
END;
GO


GO

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
EXEC tSQLt.NewTestClass 'TableToTextTests_2008';
GO
CREATE PROC TableToTextTests_2008.[test TableToText works for one DATETIMEOFFSET column #table]
AS
BEGIN
    CREATE TABLE #DoesExist(
      T DATETIMEOFFSET
    );
    INSERT INTO #DoesExist (T)VALUES(CAST('2001-10-13 12:34:56.7891234 +13:24' AS DATETIMEOFFSET));

    DECLARE @result NVARCHAR(MAX);
    SET @result = tSQLt.Private::TableToString('#DoesExist', '', NULL);
   
    EXEC tSQLt.AssertEqualsString '|T                                 |
+----------------------------------+
|2001-10-13 12:34:56.7891234 +13:24|', @result;
END;
GO

CREATE PROC TableToTextTests_2008.[test TableToText works for one DATETIME2 column #table]
AS
BEGIN
    CREATE TABLE #DoesExist(
      T DATETIME2
    );
    INSERT INTO #DoesExist (T)VALUES(CAST('2001-10-13T12:34:56.7891234' AS DATETIME2));

    DECLARE @result NVARCHAR(MAX);
    SET @result = tSQLt.Private::TableToString('#DoesExist', '', NULL);
   
    EXEC tSQLt.AssertEqualsString '|T                          |
+---------------------------+
|2001-10-13 12:34:56.7891234|', @result;
END;
GO

CREATE PROC TableToTextTests_2008.[test TableToText works for one TIME column #table]
AS
BEGIN
    CREATE TABLE #DoesExist(
      T TIME
    );
    INSERT INTO #DoesExist (T)VALUES('2001-10-13T12:34:56.7871234');
    
    DECLARE @result NVARCHAR(MAX);
    SET @result = tSQLt.Private::TableToString('#DoesExist', '', NULL);
   
    EXEC tSQLt.AssertEqualsString '|T               |
+----------------+
|12:34:56.7871234|', @result;
END;
GO

CREATE PROC TableToTextTests_2008.[test TableToText works for one DATE column #table]
AS
BEGIN
    CREATE TABLE #DoesExist(
      T DATE
    );
    INSERT INTO #DoesExist (T)VALUES('2001-10-13T12:34:56.787');
    
    DECLARE @result NVARCHAR(MAX);
    SET @result = tSQLt.Private::TableToString('#DoesExist', '', NULL);
   
    EXEC tSQLt.AssertEqualsString '|T         |
+----------+
|2001-10-13|', @result;
END;
GO


GO

/*
   Copyright 2012 tSQLt

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
EXEC tSQLt.NewTestClass 'tSQLt_test_ResultSetFilter_2008';
GO

CREATE PROCEDURE tSQLt_test_ResultSetFilter_2008.AssertResultSetFilterCanHandleDatatype
  @Value NVARCHAR(MAX),
  @Datatype NVARCHAR(MAX)
AS
BEGIN
    DECLARE @ExpectedStmt NVARCHAR(MAX),
            @ActualStmt NVARCHAR(MAX);

    DECLARE @ActualValue NVARCHAR(MAX);
    SET @ActualValue = REPLACE(@Value, '''', '''''');
    
    SELECT @ExpectedStmt = 'SELECT CAST(' + @Value + ' AS ' + @Datatype + ') AS val;';
    SELECT @ActualStmt = 'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(' + @ActualValue + ' AS ' + @Datatype + ') AS val;''';

    EXEC tSQLt.AssertResultSetsHaveSameMetaData @ExpectedStmt, @ActualStmt;

END
GO

CREATE PROC tSQLt_test_ResultSetFilter_2008.[test ResultSetFilter can handle each 2008 datatype]
AS
BEGIN
    EXEC tSQLt_test_ResultSetFilter_2008.AssertResultSetFilterCanHandleDatatype '''2011-09-27 12:23:47.846753797''', 'DATETIME2';
    EXEC tSQLt_test_ResultSetFilter_2008.AssertResultSetFilterCanHandleDatatype '''2011-09-27 12:23:47.846753797''', 'DATETIME2(3)';
    EXEC tSQLt_test_ResultSetFilter_2008.AssertResultSetFilterCanHandleDatatype '''2011-09-27 12:23:47.846753797 +01:15''', 'DATETIMEOFFSET';
    EXEC tSQLt_test_ResultSetFilter_2008.AssertResultSetFilterCanHandleDatatype '''2011-09-27 12:23:47.846753797 +01:15''', 'DATETIMEOFFSET(3)';
    EXEC tSQLt_test_ResultSetFilter_2008.AssertResultSetFilterCanHandleDatatype '''2011-09-27 12:23:47.846753797''', 'DATE';
    EXEC tSQLt_test_ResultSetFilter_2008.AssertResultSetFilterCanHandleDatatype '''2011-09-27 12:23:47.846753797''', 'TIME';

    EXEC tSQLt_test_ResultSetFilter_2008.AssertResultSetFilterCanHandleDatatype 'geometry::STGeomFromText(''LINESTRING (100 100, 20 180, 180 180)'', 0)', 'geometry';
    EXEC tSQLt_test_ResultSetFilter_2008.AssertResultSetFilterCanHandleDatatype 'geography::STGeomFromText(''LINESTRING(-122.360 47.656, -122.343 47.656)'', 4326)', 'geography';
    EXEC tSQLt_test_ResultSetFilter_2008.AssertResultSetFilterCanHandleDatatype 'hierarchyid::Parse(''/1/'')', 'hierarchyid';

END
GO



GO

