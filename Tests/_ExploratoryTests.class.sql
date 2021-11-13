EXEC tSQLt.NewTestClass '_ExploratoryTests';
GO
CREATE PROCEDURE [_ExploratoryTests].[test NULL can be CAST into any datatype]
AS
BEGIN
  DECLARE @cmd NVARCHAR(MAX) = 
    (
      SELECT ',CAST(NULL AS '+QUOTENAME(SCHEMA_NAME(schema_id))+'.'+QUOTENAME(name)+')['+CAST(user_type_id AS NVARCHAR(MAX))+']'
        FROM sys.types
       WHERE is_user_defined = 0
         FOR XML PATH(''),TYPE
    ).value('.','NVARCHAR(MAX)');
  SET @cmd = STUFF(@cmd,1,1,'');
  SET @cmd = 'SELECT TOP(0) '+@cmd+' INTO [_ExploratoryTests].DataTypeTestTable;'
  EXEC(@cmd);
  SELECT * 
    INTO #Actual
    FROM sys.columns 
   WHERE object_id = OBJECT_ID('[_ExploratoryTests].DataTypeTestTable')
     AND name <> user_type_id
  EXEC tSQLt.AssertEmptyTable @TableName = '#Actual';
END;
GO

CREATE PROCEDURE [_ExploratoryTests].[test MSSQL preserves COLLATION when using SELECT INTO]
AS
BEGIN
  SELECT 
    'Hello World!' COLLATE SQL_Polish_CP1250_CI_AS c1, 
    'Hello World!' COLLATE SQL_Latin1_General_CP437_BIN c2, 
    'Hello World!' COLLATE Albanian_BIN2 c3 
  INTO [_ExploratoryTests].Table1

  SELECT * INTO [_ExploratoryTests].Table2 FROM [_ExploratoryTests].Table1

  EXEC tSQLt.AssertEqualsTableSchema @Expected = '[_ExploratoryTests].Table1', @Actual = '[_ExploratoryTests].Table2';
END;
GO
CREATE PROCEDURE [_ExploratoryTests].[test MSSQL preserves COLLATION when using SELECT INTO across databases]
AS
BEGIN
  SELECT 
    'Hello World!' COLLATE SQL_Polish_CP1250_CI_AS c1, 
    'Hello World!' COLLATE SQL_Latin1_General_CP437_BIN c2, 
    'Hello World!' COLLATE Albanian_BIN2 c3 
  INTO [_ExploratoryTests].Table1

  SELECT * INTO tempdb.dbo.Table2 FROM [_ExploratoryTests].Table1

  SELECT
      C.name COLLATE DATABASE_DEFAULT name, 
      C.collation_name COLLATE DATABASE_DEFAULT collation_name
    INTO #Expected
    FROM sys.columns C 
   WHERE C.object_id = OBJECT_ID('[_ExploratoryTests].Table1');

  SELECT
      C.name COLLATE DATABASE_DEFAULT name, 
      C.collation_name COLLATE DATABASE_DEFAULT collation_name
    INTO #Actual
    FROM tempdb.sys.columns C 
   WHERE C.object_id = OBJECT_ID('tempdb.dbo.Table2');

   EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
   
END;
GO
CREATE PROCEDURE [_ExploratoryTests].[test MSSQL creates INTO table before processing]
AS
BEGIN
  SELECT 1 X INTO #Test;
  DECLARE @NotExpected INT = OBJECT_ID('tempdb..#Test');
  DECLARE @Actual INT;

  EXEC sys.sp_executesql N'
    SELECT * INTO #Test FROM tempdb.sys.objects C WHERE C.object_id = OBJECT_ID(''tempdb..#Test'');
    EXEC sys.sp_executesql N''SELECT @Actual = object_id FROM #Test;'',N''@Actual INT OUTPUT'',@Actual OUT;',
    N'@Actual INT OUTPUT',
    @Actual OUT;

  EXEC tSQLt.AssertNotEquals @Expected = @NotExpected, @Actual = @Actual;
END;
GO
CREATE PROCEDURE [_ExploratoryTests].[test MSSQL creates INTO table after compiling]
AS
BEGIN
  SELECT 1 X INTO #Test;
  DECLARE @NotExpected INT = OBJECT_ID('tempdb..#Test');
  DECLARE @Actual INT;

  EXEC tSQLt.ExpectException @ExpectedMessage = 'Invalid column name ''object_id''.';
  EXEC sys.sp_executesql N'
    SELECT * INTO #Test FROM tempdb.sys.objects C WHERE C.object_id = OBJECT_ID(''tempdb..#Test'');
    SELECT @Actual = object_id FROM #Test;',
    N'@Actual INT OUTPUT',
    @Actual OUT;

END;
GO
