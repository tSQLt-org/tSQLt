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
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE [_ExploratoryTests].[test FOR XML returns NULL for empty result set]
AS
BEGIN
  SELECT ((SELECT 1 WHERE 1 = 0 FOR XML PATH(''),TYPE).value('.','NVARCHAR(MAX)')) [FOR XML FROM EMPTY] INTO #Actual;
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES(NULL);
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE [_ExploratoryTests].[test CURSOR_STATUS indicates wheter a cursor variable is set (and other things)]
AS
BEGIN
  CREATE TABLE #Actual (Situation NVARCHAR(MAX), [Cursor Status] INT, [Fetch Status] INT);
  EXEC('INSERT INTO #Actual SELECT ''Variable not defined'', CURSOR_STATUS(''variable'',''@ACursor''), @@FETCH_STATUS;');
  DECLARE @ACursor CURSOR;
  INSERT INTO #Actual SELECT 'Variable defined', CURSOR_STATUS('variable','@ACursor'), @@FETCH_STATUS;
  SET @ACursor = CURSOR FOR SELECT 1;
  INSERT INTO #Actual SELECT 'Variable set', CURSOR_STATUS('variable','@ACursor'), @@FETCH_STATUS;
  OPEN @ACursor;
  INSERT INTO #Actual SELECT 'Cursor opened', CURSOR_STATUS('variable','@ACursor'), @@FETCH_STATUS;
  DECLARE @IgnoreThis INT; 
  FETCH NEXT FROM @ACursor INTO @IgnoreThis;
  INSERT INTO #Actual SELECT 'Cursor after fetch', CURSOR_STATUS('variable','@ACursor'), @@FETCH_STATUS;
  FETCH NEXT FROM @ACursor INTO @IgnoreThis;
  INSERT INTO #Actual SELECT 'Cursor after final fetch', CURSOR_STATUS('variable','@ACursor'), @@FETCH_STATUS;
  CLOSE @ACursor;
  INSERT INTO #Actual SELECT 'Cursor closed', CURSOR_STATUS('variable','@ACursor'), @@FETCH_STATUS;
  DEALLOCATE @ACursor;
  INSERT INTO #Actual SELECT 'Cursor deallocated', CURSOR_STATUS('variable','@ACursor'), @@FETCH_STATUS;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES
      ('Variable not defined',-3,-1),
      ('Variable defined',-2,-1),
      ('Variable set',-1,-1),
      ('Cursor opened',1,-1),
      ('Cursor after fetch',1,0),
      ('Cursor after final fetch',1,-1),
      ('Cursor closed',-1,-1),
      ('Cursor deallocated',-2,-1);

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';

END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE [_ExploratoryTests].[test CURSOR OUTPUT parameter requires @Cursor to be opened inside the proc to be visible after call]
AS
BEGIN
EXEC tSQLt.Fail 'multibe test';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE [_ExploratoryTests].[test a @Cursor variable with the CURSOR SET (-1) cannot be passed to a proc with OUTPUT specified in call]
AS
BEGIN
EXEC tSQLt.Fail 'TODO';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE [_ExploratoryTests].[test CURSOR_STATUS indicates whether a cursor variable is set (and other things)]
AS
BEGIN
EXEC tSQLt.Fail 'TODO';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO

--EXEC tSQLt.Run [_ExploratoryTests]