EXEC tSQLt.NewTestClass 'tSQLtclr_test';
GO

CREATE PROC tSQLtclr_test.[test AssertResultSetsHaveSameMetaData does not fail for two single bigint column result sets]
AS
BEGIN
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(1 AS BIGINT) A', 
        'SELECT CAST(1 AS BIGINT) A'; 
END;
GO

CREATE PROC tSQLtclr_test.[test AssertResultSetsHaveSameMetaData fails for a schema with integer and another with bigint]
AS
BEGIN
    EXEC tSQLt_testutil.assertFailCalled 
        'EXEC tSQLt.AssertResultSetsHaveSameMetaData ''SELECT CAST(1 AS INT) A'', ''SELECT CAST(1 AS BIGINT) A'';',
        'Expected tSQLt.Fail to be called when result sets have different meta data';
END;
GO

CREATE PROC tSQLtclr_test.[test AssertResultSetsHaveSameMetaData does not fail for identical single column result sets]
AS
BEGIN
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(1 AS INT) A', 
        'SELECT CAST(3 AS INT) A';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(1.02 AS DECIMAL(10,2)) A', 
        'SELECT CAST(3.05 AS DECIMAL(10,2)) A';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''ABC'' AS VARCHAR(15)) A', 
        'SELECT CAST(''XYZ'' AS VARCHAR(15)) A';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''ABC'' AS VARCHAR(MAX)) A', 
        'SELECT CAST(''XYZ'' AS VARCHAR(MAX)) A';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT NULL A', 
        'SELECT NULL A';
END;
GO

CREATE PROC tSQLtclr_test.[test AssertResultSetsHaveSameMetaData does not fail for identical multiple column result sets]
AS
BEGIN
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(1 AS INT) A, CAST(''ABC'' AS VARCHAR(MAX)) B, CAST(13.9 AS DECIMAL(10,1)) C', 
        'SELECT CAST(3 AS INT) A, CAST(''DEFGH'' AS VARCHAR(MAX)) B, CAST(197.8 AS DECIMAL(10,1)) C';
END;
GO

CREATE PROC tSQLtclr_test.[test AssertResultSetsHaveSameMetaData fails when one result set has no rows]
AS
BEGIN
    EXEC tSQLt_testutil.assertFailCalled 
        'EXEC tSQLt.AssertResultSetsHaveSameMetaData
            ''SELECT CAST(1 AS INT) A'', 
            ''SELECT CAST(A AS INT) A FROM (SELECT CAST(3 AS INT) A) X WHERE 1 = 0''',
            'Expected tSQLt.Fail called when AssertResultSetsHaveSameMetaData called with result set which returns no metadata';
END;
GO

CREATE PROC tSQLtclr_test.[test AssertResultSetsHaveSameMetaData fails for differing single column result sets]
AS
BEGIN
    EXEC tSQLt_testutil.assertFailCalled 
        'EXEC tSQLt.AssertResultSetsHaveSameMetaData 
            ''SELECT CAST(1 AS INT) A'', 
            ''SELECT CAST(3 AS BIGINT) A'';',
            'Expected tSQLt.Fail called when AssertResultSetsHaveSameMetaData called with differing resultsets [INT and BIGINT]';
    EXEC tSQLt_testutil.assertFailCalled 
        'EXEC tSQLt.AssertResultSetsHaveSameMetaData 
            ''SELECT CAST(1.02 AS DECIMAL(10,2)) A'', 
            ''SELECT CAST(3.05 AS DECIMAL(10,9)) A'';',
            'Expected tSQLt.Fail called when AssertResultSetsHaveSameMetaData called with differing resultsets [DECIMAL(10,2) and DECIMAL(10,9)]';
    EXEC tSQLt_testutil.assertFailCalled 
        'EXEC tSQLt.AssertResultSetsHaveSameMetaData 
            ''SELECT CAST(''''ABC'''' AS VARCHAR(15)) A'', 
            ''SELECT CAST(''''XYZ'''' AS VARCHAR(23)) A'';',
            'Expected tSQLt.Fail called when AssertResultSetsHaveSameMetaData called with differing resultsets [VARCHAR(15) and VARCHAR(23)]';
    EXEC tSQLt_testutil.assertFailCalled 
        'EXEC tSQLt.AssertResultSetsHaveSameMetaData 
            ''SELECT CAST(''''ABC'''' AS VARCHAR(12)) A'', 
            ''SELECT CAST(''''XYZ'''' AS VARCHAR(MAX)) A'';',
            'Expected tSQLt.Fail called when AssertResultSetsHaveSameMetaData called with differing resultsets [VARCHAR(12) and VARCHAR(MAX)]';
    EXEC tSQLt_testutil.assertFailCalled 
        'EXEC tSQLt.AssertResultSetsHaveSameMetaData 
            ''SELECT CAST(''''ABC'''' AS VARCHAR(MAX)) A'', 
            ''SELECT CAST(''''XYZ'''' AS NVARCHAR(MAX)) A'';',
            'Expected tSQLt.Fail called when AssertResultSetsHaveSameMetaData called with differing resultsets [VARCHAR(MAX) and NVARCHAR(MAX)]';
    EXEC tSQLt_testutil.assertFailCalled 
        'EXEC tSQLt.AssertResultSetsHaveSameMetaData 
            ''SELECT NULL A'', 
            ''SELECT CAST(3 AS BIGINT) A'';',
            'Expected tSQLt.Fail called when AssertResultSetsHaveSameMetaData called with differing resultsets [NULL(INT) and BIGINT]';
END;
GO

CREATE PROC tSQLtclr_test.[test AssertResultSetsHaveSameMetaData fails for result sets with different number of columns]
AS
BEGIN
    EXEC tSQLt_testutil.assertFailCalled 
        'EXEC tSQLt.AssertResultSetsHaveSameMetaData 
            ''SELECT CAST(1 AS INT) A, CAST(''''ABC'''' AS VARCHAR(MAX)) B'', 
            ''SELECT CAST(1 AS INT) A'';',
            'Expected tSQLt.Fail called when AssertResultSetsHaveSameMetaData called with differing resultsets [INT,VARCHAR(MAX) and INT]';
    EXEC tSQLt_testutil.assertFailCalled 
        'EXEC tSQLt.AssertResultSetsHaveSameMetaData 
            ''SELECT CAST(1 AS INT) A'',
            ''SELECT CAST(1 AS INT) A, CAST(''''ABC'''' AS VARCHAR(MAX)) B'';',
            'Expected tSQLt.Fail called when AssertResultSetsHaveSameMetaData called with differing resultsets [INT and INT,VARCHAR(MAX)]';
END;
GO

CREATE PROC tSQLtclr_test.[test AssertResultSetsHaveSameMetaData fails if either command produces no result set]
AS
BEGIN
    EXEC tSQLt_testutil.assertFailCalled 
        'EXEC tSQLt.AssertResultSetsHaveSameMetaData 
            ''EXEC('''''''')'', 
            ''SELECT CAST(1 AS INT) A'';',
            'Expected tSQLt.Fail called when AssertResultSetsHaveSameMetaData called with first command returning no result set';
    EXEC tSQLt_testutil.assertFailCalled 
        'EXEC tSQLt.AssertResultSetsHaveSameMetaData 
            ''SELECT CAST(1 AS INT) A'',
            ''EXEC('''''''')'';',
            'Expected tSQLt.Fail called when AssertResultSetsHaveSameMetaData called with second command returning no result set';
    EXEC tSQLt_testutil.assertFailCalled 
        'EXEC tSQLt.AssertResultSetsHaveSameMetaData 
            ''EXEC('''''''')'',
            ''EXEC('''''''')'';',
            'Expected tSQLt.Fail called when AssertResultSetsHaveSameMetaData called with both commands returning no result set';
END;
GO

CREATE PROC tSQLtclr_test.[test AssertResultSetsHaveSameMetaData throws an exception if a command produces an exception]
AS
BEGIN
    DECLARE @err NVARCHAR(MAX);
    
    BEGIN TRY
        EXEC tSQLt.AssertResultSetsHaveSameMetaData 
            'SELECT 1/0 AS A', 
            'SELECT CAST(1 AS INT) A';
    END TRY
    BEGIN CATCH
        SET @err = ERROR_MESSAGE();
    END CATCH
    
    IF @err NOT LIKE '%Divide by zero%'
    BEGIN
        EXEC tSQLt.Fail 'Unexpected error message was: ', @err;
    END;
END;
GO

CREATE PROC tSQLtclr_test.[test AssertResultSetsHaveSameMetaData throws an exception if either command has a syntax error]
AS
BEGIN
    DECLARE @err NVARCHAR(MAX);
    
    BEGIN TRY
        EXEC tSQLt.AssertResultSetsHaveSameMetaData 
            'SELECT FROM WHERE', 
            'SELECT CAST(1 AS INT) A';
    END TRY
    BEGIN CATCH
        SET @err = ERROR_MESSAGE();
    END CATCH
    
    IF @err NOT LIKE '%Incorrect syntax near the keyword ''FROM''%'
    BEGIN
        EXEC tSQLt.Fail 'Unexpected error message was: ', @err;
    END;
END;
GO

CREATE PROC tSQLtclr_test.[test ResultSetFilter returns specified result set]
AS
BEGIN
    CREATE TABLE Actual (val INT);
    
    INSERT INTO Actual (val)
    EXEC tSQLt.ResultSetFilter 3, 'SELECT 1 AS val; SELECT 2 AS val; SELECT 3 AS val UNION ALL SELECT 4 UNION ALL SELECT 5;';
    
    CREATE TABLE Expected (val INT);
    INSERT INTO Expected
    SELECT 3 AS val UNION ALL SELECT 4 UNION ALL SELECT 5;
    
    EXEC tSQLt.AssertEqualsTable 'Actual', 'Expected';
END;
GO

CREATE PROC tSQLtclr_test.[test ResultSetFilter returns specified result set with multiple columns]
AS
BEGIN
    CREATE TABLE Actual (val1 INT, val2 VARCHAR(3));
    
    INSERT INTO Actual (val1, val2)
    EXEC tSQLt.ResultSetFilter 2, 'SELECT 1 AS val; SELECT 3 AS val1, ''ABC'' AS val2 UNION ALL SELECT 4, ''DEF'' UNION ALL SELECT 5, ''GHI''; SELECT 2 AS val;';
    
    CREATE TABLE Expected (val1 INT, val2 VARCHAR(3));
    INSERT INTO Expected
    SELECT 3 AS val1, 'ABC' AS val2 UNION ALL SELECT 4, 'DEF' UNION ALL SELECT 5, 'GHI';
    
    EXEC tSQLt.AssertEqualsTable 'Actual', 'Expected';
END;
GO

CREATE PROC tSQLtclr_test.[test ResultSetFilter retrieves no records if specified result set does not exist]
AS
BEGIN
    CREATE TABLE Actual (val INT);
    INSERT INTO Actual
    EXEC tSQLt.ResultSetFilter 4, 'SELECT 1 AS val; SELECT 2 AS val; SELECT 3 AS val;';
    
    CREATE TABLE Expected (val INT);
    
    EXEC tSQLt.AssertEqualsTable 'Actual', 'Expected';
END;
GO

CREATE PROC tSQLtclr_test.[test ResultSetFilter throws error if result set number 0 specified]
AS
BEGIN
    DECLARE @err NVARCHAR(MAX); SET @err = '';
    
    BEGIN TRY
        EXEC tSQLt.ResultSetFilter 0, 'SELECT 1 AS val; SELECT 2 AS val; SELECT 3 AS val;';
    END TRY
    BEGIN CATCH
        SET @err = ERROR_MESSAGE();
    END CATCH
    
    IF @err NOT LIKE '%ResultSet index begins at 1. ResultSet index %0% is invalid.%'
    BEGIN
        EXEC tSQLt.Fail 'Unexpected error message was: ', @err;
    END;
END;
GO


CREATE PROC tSQLtclr_test.[test ResultSetFilter throws error if result set number -1 specified]
AS
BEGIN
    DECLARE @err NVARCHAR(MAX); SET @err = '';
    
    BEGIN TRY
        EXEC tSQLt.ResultSetFilter -1, 'SELECT 1 AS val; SELECT 2 AS val; SELECT 3 AS val;';
    END TRY
    BEGIN CATCH
        SET @err = ERROR_MESSAGE();
    END CATCH
    
    IF @err NOT LIKE '%ResultSet index begins at 1. ResultSet index %-1% is invalid.%'
    BEGIN
        EXEC tSQLt.Fail 'Unexpected error message was: ', @err;
    END;
END;
GO

CREATE PROC tSQLtclr_test.[test ResultSetFilter can handle each datatype]
AS
BEGIN
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''76456376'' AS BIGINT) AS val;',
        'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(''''76456376'''' AS BIGINT) AS val;''';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''0x432643'' AS BINARY(15)) AS val;',
        'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(''''0x432643'''' AS BINARY(15)) AS val;''';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''1'' AS BIT) AS val;',
        'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(''''1'''' AS BIT) AS val;''';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''ABCDEF'' AS CHAR(15)) AS val;',
        'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(''''ABCDEF'''' AS CHAR(15)) AS val;''';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''12/27/2010 11:54:12.003'' AS DATETIME) AS val;',
        'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(''''12/27/2010 11:54:12.003'''' AS DATETIME) AS val;''';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''234.567'' AS DECIMAL(7,4)) AS val;',
        'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(''''234.567'''' AS DECIMAL(7,4)) AS val;''';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''12345.6789'' AS FLOAT) AS val;',
        'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(''''12345.6789'''' AS FLOAT) AS val;''';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''XYZ'' AS IMAGE) AS val;',
        'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(''''XYZ'''' AS IMAGE) AS val;''';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''13'' AS INT) AS val;',
        'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(''''13'''' AS INT) AS val;''';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''12.95'' AS MONEY) AS val;',
        'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(''''12.95'''' AS MONEY) AS val;''';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''ABCDEF'' AS NCHAR(15)) AS val;',
        'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(''''ABCDEF'''' AS NCHAR(15)) AS val;''';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''ABCDEF'' AS NTEXT) AS val;',
        'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(''''ABCDEF'''' AS NTEXT) AS val;''';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''345.67'' AS NUMERIC(7,4)) AS val;',
        'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(''''345.67'''' AS NUMERIC(7,4)) AS val;''';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''ABCDEF'' AS NVARCHAR(15)) AS val;',
        'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(''''ABCDEF'''' AS NVARCHAR(15)) AS val;''';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''ABCDEF'' AS NVARCHAR(MAX)) AS val;',
        'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(''''ABCDEF'''' AS NVARCHAR(MAX)) AS val;''';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''12345.6789'' AS REAL) AS val;',
        'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(''''12345.6789'''' AS REAL) AS val;''';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''12/27/2010 09:35'' AS SMALLDATETIME) AS val;',
        'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(''''12/27/2010 09:35'''' AS SMALLDATETIME) AS val;''';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''13'' AS SMALLINT) AS val;',
        'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(''''13'''' AS SMALLINT) AS val;''';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''13.95'' AS SMALLMONEY) AS val;',
        'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(''''13.95'''' AS SMALLMONEY) AS val;''';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''ABCDEF'' AS SQL_VARIANT) AS val;',
        'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(''''ABCDEF'''' AS SQL_VARIANT) AS val;''';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''ABCDEF'' AS sysname) AS val;',
        'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(''''ABCDEF'''' AS sysname) AS val;''';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''ABCDEF'' AS TEXT) AS val;',
        'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(''''ABCDEF'''' AS TEXT) AS val;''';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''0x1234'' AS TIMESTAMP) AS val;',
        'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(''''0x1234'''' AS TIMESTAMP) AS val;''';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''7'' AS TINYINT) AS val;',
        'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(''''7'''' AS TINYINT) AS val;''';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''F12AF25F-E043-4475-ADD1-96B8BBC6F16E'' AS UNIQUEIDENTIFIER) AS val;',
        'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(''''F12AF25F-E043-4475-ADD1-96B8BBC6F16E'''' AS UNIQUEIDENTIFIER) AS val;''';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''ABCDEF'' AS VARBINARY(15)) AS val;',
        'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(''''ABCDEF'''' AS VARBINARY(15)) AS val;''';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''ABCDEF'' AS VARBINARY(MAX)) AS val;',
        'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(''''ABCDEF'''' AS VARBINARY(MAX)) AS val;''';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''ABCDEF'' AS VARCHAR(15)) AS val;',
        'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(''''ABCDEF'''' AS VARCHAR(15)) AS val;''';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''ABCDEF'' AS VARCHAR(MAX)) AS val;',
        'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(''''ABCDEF'''' AS VARCHAR(MAX)) AS val;''';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''<xml>hi</xml>'' AS XML) AS val;',
        'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(''''<xml>hi</xml>'''' AS XML) AS val;''';
END;
GO

CREATE PROC tSQLtclr_test.[test ResultSetFilter produces only requested columns when underlying table contains primary key]
AS
BEGIN
    CREATE TABLE BaseTable (i INT PRIMARY KEY, v VARCHAR(15));
    INSERT INTO BaseTable (i, v) VALUES (1, 'hello');
    
    CREATE TABLE Actual (v VARCHAR(15));
    INSERT INTO Actual
    EXEC tSQLt.ResultSetFilter 1, 'SELECT v FROM BaseTable';
    
    CREATE TABLE Expected (v VARCHAR(15));
    INSERT INTO Expected (v) VALUES ('hello');
    
    EXEC tSQLt.AssertEqualsTable 'Expected', 'Actual';
END;
GO

CREATE PROC tSQLtclr_test.[test ResultSetFilter produces only requested columns when a join on foreign keys is performed]
AS
BEGIN
    CREATE TABLE BaseTable1 (i1 INT PRIMARY KEY, v1 VARCHAR(15));
    INSERT INTO BaseTable1 (i1, v1) VALUES (1, 'hello');
    
    CREATE TABLE BaseTable2 (i2 INT PRIMARY KEY, i1 INT FOREIGN KEY REFERENCES BaseTable1(i1), v2 VARCHAR(15));
    INSERT INTO BaseTable2 (i2, i1, v2) VALUES (1, 1, 'goodbye');
    
    CREATE TABLE Actual (v1 VARCHAR(15), v2 VARCHAR(15));
    INSERT INTO Actual
    EXEC tSQLt.ResultSetFilter 1, 'SELECT v1, v2 FROM BaseTable1 JOIN BaseTable2 ON BaseTable1.i1 = BaseTable2.i1';
    
    CREATE TABLE Expected (v1 VARCHAR(15), v2 VARCHAR(15));
    INSERT INTO Expected (v1, v2) VALUES ('hello', 'goodbye');
    
    EXEC tSQLt.AssertEqualsTable 'Expected', 'Actual';
END;
GO

CREATE PROC tSQLtclr_test.[test ResultSetFilter produces only requested columns when a unique column exists]
AS
BEGIN
    CREATE TABLE BaseTable1 (i1 INT UNIQUE, v1 VARCHAR(15));
    INSERT INTO BaseTable1 (i1, v1) VALUES (1, 'hello');
    
    CREATE TABLE Actual (v1 VARCHAR(15));
    INSERT INTO Actual
    EXEC tSQLt.ResultSetFilter 1, 'SELECT v1 FROM BaseTable1';
    
    CREATE TABLE Expected (v1 VARCHAR(15));
    INSERT INTO Expected (v1) VALUES ('hello');
    
    EXEC tSQLt.AssertEqualsTable 'Expected', 'Actual';
END;
GO

CREATE PROC tSQLtclr_test.[test ResultSetFilter produces only requested columns when a check constraint exists]
AS
BEGIN
    CREATE TABLE BaseTable1 (i1 INT CHECK(i1 = 1), v1 VARCHAR(15));
    INSERT INTO BaseTable1 (i1, v1) VALUES (1, 'hello');
    
    CREATE TABLE Actual (v1 VARCHAR(15));
    INSERT INTO Actual
    EXEC tSQLt.ResultSetFilter 1, 'SELECT v1 FROM BaseTable1';
    
    CREATE TABLE Expected (v1 VARCHAR(15));
    INSERT INTO Expected (v1) VALUES ('hello');
    
    EXEC tSQLt.AssertEqualsTable 'Expected', 'Actual';
END;
GO

CREATE PROC tSQLtclr_test.[test NewConnection executes a command in a new process]
AS
BEGIN
    EXEC tSQLt.NewConnection 'IF OBJECT_ID(''tSQLtclr_test.[SpidTable for test NewConnection executes a command in a new process]'') IS NOT NULL DROP TABLE tSQLtclr_test.[SpidTable for test NewConnection executes a command in a new process];';

    EXEC tSQLt.NewConnection 'SELECT @@SPID spid INTO tSQLtclr_test.[SpidTable for test NewConnection executes a command in a new process];';
    
    EXEC tSQLt.AssertObjectExists 'tSQLtclr_test.[SpidTable for test NewConnection executes a command in a new process]';
    
    DECLARE @otherSpid INT;
    SELECT @otherSpid = spid
      FROM tSQLtclr_test.[SpidTable for test NewConnection executes a command in a new process];

    IF ISNULL(@otherSpid, -1) = @@SPID
    BEGIN
        EXEC tSQLt.Fail 'Expected otherSpid to be different than @@SPID.';
    END;
    
    EXEC tSQLt.NewConnection 'IF OBJECT_ID(''tSQLtclr_test.[SpidTable for test NewConnection executes a command in a new process]'') IS NOT NULL DROP TABLE tSQLtclr_test.[SpidTable for test NewConnection executes a command in a new process];';
END;
GO

CREATE PROC tSQLtclr_test.[test CaptureOutput places the console output of a command into the CaptureOutputLog]
AS
BEGIN

  EXEC tSQLt.CaptureOutput 'print ''Catch Me if You Can!''';
  
  SELECT OutputText
  INTO #actual
  FROM tSQLt.CaptureOutputLog;
  
  SELECT TOP(0) *
  INTO #expected 
  FROM #actual;
  
  INSERT INTO #expected(OutputText)VALUES('Catch Me if You Can!' + CHAR(13) + CHAR(10));
  
  EXEC tSQLt.AssertEqualsTable '#expected','#actual';
  
END;
GO

CREATE PROC tSQLtclr_test.[test CaptureOutput, called with a command that does not print, results in no messages captured]
AS
BEGIN

  EXEC tSQLt.CaptureOutput 'DECLARE @i INT;';
  
  SELECT OutputText
  INTO #actual
  FROM tSQLt.CaptureOutputLog;
  
  SELECT TOP(0) *
  INTO #expected 
  FROM #actual;
  
  INSERT INTO #expected(OutputText)VALUES(NULL);
  
  EXEC tSQLt.AssertEqualsTable '#expected','#actual';
  
END;
GO

CREATE PROC tSQLtclr_test.[test CaptureOutput captures output that happens in between resultsets]
AS
BEGIN

  EXEC tSQLt.CaptureOutput 'PRINT ''AAAAA'';SELECT 1 a;PRINT ''BBBBB'';SELECT 1 b;PRINT ''CCCCC'';';
  
  DECLARE @OutputText NVARCHAR(MAX);
  SELECT @OutputText = OutputText FROM tSQLt.CaptureOutputLog;
  
  IF(@OutputText NOT LIKE 'AAAAA%BBBBB%CCCCC%')
    EXEC tSQLt.Fail 'Unexpected OutputText Captured! Expected to match ''AAAAA%BBBBB%CCCCC%'', was: ''',@OutputText,'''!';
  
END;
GO

CREATE PROC tSQLtclr_test.[test CaptureOutput can be executed twice with the different output]
AS
BEGIN

  EXEC tSQLt.CaptureOutput 'print ''Catch Me if You Can!''';
  EXEC tSQLt.CaptureOutput 'print ''Oh, you got me!!''';
  
  SELECT Id+0 Id,OutputText
  INTO #actual
  FROM tSQLt.CaptureOutputLog;
  
  SELECT TOP(0) *
  INTO #expected 
  FROM #actual;
  
  INSERT INTO #expected(Id,OutputText)VALUES(1,'Catch Me if You Can!' + CHAR(13) + CHAR(10) );
  INSERT INTO #expected(Id,OutputText)VALUES(2,'Oh, you got me!!' + CHAR(13) + CHAR(10) );
  
  EXEC tSQLt.AssertEqualsTable '#expected','#actual';
  
END;
GO


CREATE PROC tSQLtclr_test.[test CaptureOutput propogates an error]
AS
BEGIN

  DECLARE @msg NVARCHAR(MAX);
  SELECT @msg = 'No error message';
  
  BEGIN TRY
    EXEC tSQLt.CaptureOutput 'RAISERROR(''hello'', 16, 10);';
  END TRY
  BEGIN CATCH
    SET @msg = ERROR_MESSAGE();
  END CATCH
  
  IF @msg NOT LIKE '%hello%'
    EXEC tSQLt.Fail 'Expected the error message to be propogated up to SQL, but the message was: ', @msg;
END;
GO

CREATE PROC tSQLtclr_test.[test CaptureOutput can capture raiserror output with low severity]
AS
BEGIN

  EXEC tSQLt.CaptureOutput 'RAISERROR(''Catch Me if You Can!'', 0, 1);';

  SELECT OutputText
  INTO #actual
  FROM tSQLt.CaptureOutputLog;
  
  SELECT TOP(0) *
  INTO #expected 
  FROM #actual;
  
  INSERT INTO #expected(OutputText)VALUES('Catch Me if You Can!' + CHAR(13) + CHAR(10));
  
  EXEC tSQLt.AssertEqualsTable '#expected','#actual';
  
END;
GO

CREATE PROC tSQLtclr_test.[test SuppressOutput causes no output to be produced]
AS
BEGIN
  EXEC tSQLt.CaptureOutput 'EXEC tSQLt.SuppressOutput ''print ''''hello'''';'';';

  SELECT OutputText
  INTO #actual
  FROM tSQLt.CaptureOutputLog;
  
  SELECT TOP(0) *
  INTO #expected 
  FROM #actual;
  
  INSERT INTO #expected(OutputText)VALUES(NULL);
  
  EXEC tSQLt.AssertEqualsTable '#expected','#actual';
END;
GO

--ROLLBACK
