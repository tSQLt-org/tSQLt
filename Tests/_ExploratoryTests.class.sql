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
CREATE PROCEDURE [_ExploratoryTests].[test CURSOR_STATUS indicates whether a cursor variable is set (and other things)]
AS
BEGIN
  CREATE TABLE #Actual (Situation NVARCHAR(MAX), [Cursor Status] INT, [Fetch Status] INT);
  EXEC('INSERT INTO #Actual SELECT ''Variable not defined'', CURSOR_STATUS(''variable'',''@ACursor''),NULL;');
  DECLARE @ACursor CURSOR;
  INSERT INTO #Actual SELECT 'Variable defined (DECLARE)', CURSOR_STATUS('variable','@ACursor'), NULL;
  SET @ACursor = CURSOR FOR SELECT 1;
  INSERT INTO #Actual SELECT 'Variable allocated (SET)', CURSOR_STATUS('variable','@ACursor'), NULL;
  OPEN @ACursor;
  INSERT INTO #Actual SELECT 'Cursor opened', CURSOR_STATUS('variable','@ACursor'), NULL;
  DECLARE @IgnoreThis INT; 
  FETCH NEXT FROM @ACursor INTO @IgnoreThis;
  INSERT INTO #Actual SELECT 'Cursor after fetch', CURSOR_STATUS('variable','@ACursor'), @@FETCH_STATUS;
  FETCH NEXT FROM @ACursor INTO @IgnoreThis;
  INSERT INTO #Actual SELECT 'Cursor after final fetch', CURSOR_STATUS('variable','@ACursor'), @@FETCH_STATUS;
  CLOSE @ACursor;
  INSERT INTO #Actual SELECT 'Cursor closed', CURSOR_STATUS('variable','@ACursor'), NULL;
  DEALLOCATE @ACursor;
  INSERT INTO #Actual SELECT 'Cursor deallocated', CURSOR_STATUS('variable','@ACursor'), NULL;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES
      ('Variable not defined',-3,NULL),
      ('Variable defined (DECLARE)',-2,NULL),
      ('Variable allocated (SET)',-1,NULL),
      ('Cursor opened',1,NULL),
      ('Cursor after fetch',1,0),
      ('Cursor after final fetch',1,-1),
      ('Cursor closed',-1,NULL),
      ('Cursor deallocated',-2,NULL);

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';

END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE [_ExploratoryTests].[test CURSOR will not be passed out through OUTPUT @parameter if it has not been opened (CURSOR_STATUS = -1)]
AS
BEGIN
  DECLARE @CursorProc NVARCHAR(MAX) = '[_ExploratoryTests].CursorProc';
  EXEC('
    CREATE PROCEDURE '+@CursorProc+'
       @CursorParameter CURSOR VARYING OUTPUT
    AS
    BEGIN
      SET @CursorParameter = CURSOR FOR SELECT 42;
    END;
  ');

  DECLARE @CursorVariable CURSOR;

  EXEC @CursorProc @CursorParameter = @CursorVariable OUTPUT;

  CREATE TABLE #Actual ([Cursor Status] INT);
  INSERT INTO #Actual SELECT CURSOR_STATUS('variable','@CursorVariable');

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES(-2);

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
  
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE [_ExploratoryTests].[test CURSOR can be passed out through OUTPUT @parameter if it has been opened (CURSOR_STATUS = 1)]
AS
BEGIN
  DECLARE @CursorProc NVARCHAR(MAX) = '[_ExploratoryTests].CursorProc';
  EXEC('
    CREATE PROCEDURE '+@CursorProc+'
       @CursorParameter CURSOR VARYING OUTPUT
    AS
    BEGIN
      SET @CursorParameter = CURSOR FOR SELECT 42;
      OPEN @CursorParameter;
    END;
  ');

  DECLARE @IntValue INT = NULL;
  DECLARE @CursorVariable CURSOR;

  EXEC @CursorProc @CursorParameter = @CursorVariable OUTPUT;

  FETCH NEXT FROM @CursorVariable INTO @IntValue;
  CLOSE @CursorVariable;
  DEALLOCATE @CursorVariable;

  EXEC tSQLt.AssertEquals @Expected = 42, @Actual = @IntValue;
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE [_ExploratoryTests].[test CURSOR cannot be passed to a proc with OUTPUT specified in the call if it has been allocated (SET, CURSOR_STATUS = -1)]
AS
BEGIN
  DECLARE @CursorProc NVARCHAR(MAX) = '[_ExploratoryTests].CursorProc';
  EXEC('
    CREATE PROCEDURE '+@CursorProc+'
       @CursorParameter CURSOR VARYING OUTPUT
    AS
    BEGIN
      RETURN;
    END;
  ');

  DECLARE @IntValue INT = NULL;
  DECLARE @CursorVariable CURSOR;
  SET @CursorVariable = CURSOR FOR SELECT 13;

  EXEC tSQLt.ExpectException @ExpectedMessage = 'The variable ''@CursorVariable'' cannot be used as a parameter because a CURSOR OUTPUT parameter must not have a cursor allocated to it before execution of the procedure.';
  EXEC @CursorProc @CursorParameter = @CursorVariable OUTPUT;

END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE [_ExploratoryTests].[test CURSOR can be passed to a proc without OUTPUT specified in the call even if it has been allocated (SET, CURSOR_STATUS = -1)]
AS
BEGIN
  DECLARE @CursorProc NVARCHAR(MAX) = '[_ExploratoryTests].CursorProc';
  EXEC('
    CREATE PROCEDURE '+@CursorProc+'
       @CursorParameter CURSOR VARYING OUTPUT
    AS
    BEGIN
      RETURN;
    END;
  ');

  DECLARE @IntValue INT = NULL;
  DECLARE @CursorVariable CURSOR;
  SET @CursorVariable = CURSOR FOR SELECT 13;

  EXEC tSQLt.ExpectNoException;
  EXEC @CursorProc @CursorParameter = @CursorVariable;

END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE [_ExploratoryTests].[test CURSOR gets deallocated when its variable goes out of scope?]
AS
BEGIN
  SELECT IDENTITY(INT,1,1) AS ID, name, is_open, fetch_status
    INTO #Actual FROM (SELECT NULL)ID(ID) LEFT JOIN sys.dm_exec_cursors(@@SPID) ON name = '@ACursor';

  EXEC('
    DECLARE @ACursor CURSOR;
    SET @ACursor = CURSOR FOR SELECT 42;
    INSERT INTO #Actual SELECT name, is_open, fetch_status
      FROM (SELECT NULL )ID(ID) LEFT JOIN sys.dm_exec_cursors(@@SPID) ON name = ''@ACursor'';
    OPEN @ACursor;
    INSERT INTO #Actual SELECT name, is_open, fetch_status
      FROM (SELECT NULL )ID(ID) LEFT JOIN sys.dm_exec_cursors(@@SPID) ON name = ''@ACursor'';
    DECLARE @I INT; FETCH NEXT FROM @ACursor INTO @I;
    INSERT INTO #Actual SELECT name, is_open, fetch_status
      FROM (SELECT NULL )ID(ID) LEFT JOIN sys.dm_exec_cursors(@@SPID) ON name = ''@ACursor'';
  ');

  INSERT INTO #Actual SELECT name, is_open, fetch_status
    FROM (SELECT NULL )ID(ID) LEFT JOIN sys.dm_exec_cursors(@@SPID) ON name = '@ACursor';

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES
    (1,NULL,NULL,NULL),
    (2,'@ACursor','false', -9),
    (3,'@ACursor','true', -9),
    (4,'@ACursor','true', 0),
    (5,NULL,NULL,NULL);
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
  
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE [_ExploratoryTests].[test LOCAL CURSOR (not a variable) gets deallocated when it goes out of scope?]
AS
BEGIN
  SELECT IDENTITY(INT,1,1) AS ID, name, is_open, fetch_status, CURSOR_STATUS('local','ACursor') AS [cursor status]
    INTO #Actual FROM (SELECT NULL)ID(ID) LEFT JOIN sys.dm_exec_cursors(@@SPID) ON name = 'ACursor';

  EXEC('
    DECLARE ACursor CURSOR LOCAL FOR SELECT 42;
    INSERT INTO #Actual SELECT name, is_open, fetch_status, CURSOR_STATUS(''local'',''ACursor'')
      FROM (SELECT NULL )ID(ID) LEFT JOIN sys.dm_exec_cursors(@@SPID) ON name = ''ACursor'';
    OPEN ACursor;
    INSERT INTO #Actual SELECT name, is_open, fetch_status, CURSOR_STATUS(''local'',''ACursor'')
      FROM (SELECT NULL )ID(ID) LEFT JOIN sys.dm_exec_cursors(@@SPID) ON name = ''ACursor'';
    DECLARE @I INT; FETCH NEXT FROM ACursor INTO @I;
    INSERT INTO #Actual SELECT name, is_open, fetch_status, CURSOR_STATUS(''local'',''ACursor'')
      FROM (SELECT NULL )ID(ID) LEFT JOIN sys.dm_exec_cursors(@@SPID) ON name = ''ACursor'';
  ');

  INSERT INTO #Actual SELECT name, is_open, fetch_status, CURSOR_STATUS('local','ACursor')
    FROM (SELECT NULL )ID(ID) LEFT JOIN sys.dm_exec_cursors(@@SPID) ON name = 'ACursor';

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES
    (1,NULL,NULL,NULL, -3),
    (2,'ACursor','false', -9, -1),
    (3,'ACursor','true', -9, 1),
    (4,'ACursor','true', 0, 1),
    (5,NULL,NULL,NULL, -3);

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
  
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE [_ExploratoryTests].[test GLOBAL CURSOR (not a variable) gets deallocated when it goes out of scope?]
AS
BEGIN
  SELECT IDENTITY(INT,1,1) AS ID, name, is_open, fetch_status, CURSOR_STATUS('global','ACursor') AS [cursor status]
    INTO #Actual FROM (SELECT NULL)ID(ID) LEFT JOIN sys.dm_exec_cursors(@@SPID) ON name = 'ACursor';

  EXEC('
    DECLARE ACursor CURSOR /*GLOBAL*/ FOR SELECT 42;
    INSERT INTO #Actual SELECT name, is_open, fetch_status, CURSOR_STATUS(''global'',''ACursor'')
      FROM (SELECT NULL )ID(ID) LEFT JOIN sys.dm_exec_cursors(@@SPID) ON name = ''ACursor'';
    OPEN ACursor;
    INSERT INTO #Actual SELECT name, is_open, fetch_status, CURSOR_STATUS(''global'',''ACursor'')
      FROM (SELECT NULL )ID(ID) LEFT JOIN sys.dm_exec_cursors(@@SPID) ON name = ''ACursor'';
    DECLARE @I INT; FETCH NEXT FROM ACursor INTO @I;
    INSERT INTO #Actual SELECT name, is_open, fetch_status, CURSOR_STATUS(''global'',''ACursor'')
      FROM (SELECT NULL )ID(ID) LEFT JOIN sys.dm_exec_cursors(@@SPID) ON name = ''ACursor'';
  ');

  INSERT INTO #Actual SELECT name, is_open, fetch_status, CURSOR_STATUS('global','ACursor')
    FROM (SELECT NULL )ID(ID) LEFT JOIN sys.dm_exec_cursors(@@SPID) ON name = 'ACursor';

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES
    (1,NULL,NULL,NULL, -3),
    (2,'ACursor','false', -9, -1),
    (3,'ACursor','true', -9, 1),
    (4,'ACursor','true', 0, 1),
    (5,'ACursor','true', 0, 1);
  BEGIN TRY CLOSE ACursor; END TRY BEGIN CATCH END CATCH;
  BEGIN TRY DEALLOCATE ACursor; END TRY BEGIN CATCH END CATCH;
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
  
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE [_ExploratoryTests].[test sp_addextendedproperty can handle odd values]
AS
BEGIN
  CREATE TABLE [_ExploratoryTests].ATable(I INT);

  EXEC sys.sp_addextendedproperty 
     @name = N'ATestProperty', 
     @value = 'a string.with''special chars', 
     @level0type = N'SCHEMA', @level0name = '_ExploratoryTests', 
     @level1type = 'TABLE',  @level1name = 'ATable';

  SELECT * FROM sys.extended_properties AS EP WHERE EP.major_id = OBJECT_ID('[_ExploratoryTests].ATable');

END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
--CREATE PROCEDURE [_ExploratoryTests].[test TBD]
--AS
--BEGIN
--  EXEC tSQLt.Fail 'TemplateTest';
--END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO

--EXEC tSQLt.Run [_ExploratoryTests]