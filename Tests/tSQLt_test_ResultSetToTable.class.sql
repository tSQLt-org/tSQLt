-------------------------------------------------------
-- These tests ensure compatablity with ResultSetFilter 
--
-- Basically the same tests with:
--		'INSERT INTO #Actual EXEC tSQLt.ResultSetFilter' 
-- Replaced with:
--		'EXEC tSQLt.ResultSetToTable #Actual ' 
-------------------------------------------------------
EXEC tSQLt.NewTestClass 'tSQLt_test_ResultSetToTable';
GO
CREATE PROC tSQLt_test_ResultSetToTable.[test ResultSetToTable (Compatability) returns specified result set]
AS
BEGIN
    CREATE TABLE #Actual (val INT);
	
    EXEC tSQLt.ResultSetToTable #Actual, 3, 'SELECT 1 AS val; SELECT 2 AS val; SELECT 3 AS val UNION ALL SELECT 4 UNION ALL SELECT 5;';
    
    CREATE TABLE #Expected (val INT);
    INSERT INTO #Expected
    SELECT 3 AS val UNION ALL SELECT 4 UNION ALL SELECT 5;
    
    EXEC tSQLt.AssertEqualsTable '#Actual', '#Expected';
END;
GO

CREATE PROC tSQLt_test_ResultSetToTable.[test ResultSetToTable (Compatability) returns specified result set with multiple columns]
AS
BEGIN
    CREATE TABLE #Actual (val1 INT, val2 VARCHAR(3));
    
    EXEC tSQLt.ResultSetToTable #Actual, 2, 'SELECT 1 AS val; SELECT 3 AS val1, ''ABC'' AS val2 UNION ALL SELECT 4, ''DEF'' UNION ALL SELECT 5, ''GHI''; SELECT 2 AS val;';
    
    CREATE TABLE #Expected (val1 INT, val2 VARCHAR(3));
    INSERT INTO #Expected
    SELECT 3 AS val1, 'ABC' AS val2 UNION ALL SELECT 4, 'DEF' UNION ALL SELECT 5, 'GHI';
    
    EXEC tSQLt.AssertEqualsTable '#Actual', '#Expected';
END;
GO

CREATE PROC tSQLt_test_ResultSetToTable.[test ResultSetToTable (Compatability) throws error if specified result set is 1 greater than number of result sets returned]
AS
BEGIN
    DECLARE @err NVARCHAR(MAX); SET @err = '--NO Error Thrown!--';
    
    BEGIN TRY
		CREATE TABLE #Actual (val INT);
		EXEC tSQLt.ResultSetToTable #Actual, 4, 'SELECT 1 AS val; SELECT 2 AS val; SELECT 3 AS val;';
    END TRY
    BEGIN CATCH
        SET @err = ERROR_MESSAGE();
    END CATCH
    
    IF @err NOT LIKE '%Execution returned only 3 ResultSets. ResultSet [[]4] does not exist.%'
    BEGIN
        EXEC tSQLt.Fail 'Unexpected error message was: ', @err;
    END;
END;
GO

CREATE PROC tSQLt_test_ResultSetToTable.[test ResultSetToTable (Compatability) throws error if result set requested is greater than number of result sets returned]
AS
BEGIN
    DECLARE @err NVARCHAR(MAX); SET @err = '--NO Error Thrown!--';
    
    BEGIN TRY
        CREATE TABLE #Actual (val INT);
		EXEC tSQLt.ResultSetToTable #Actual, 9, 'SELECT 1 AS val; SELECT 2 AS val; SELECT 3 AS val; SELECT 4 AS val; SELECT 5 AS val;';
    END TRY
    BEGIN CATCH
        SET @err = ERROR_MESSAGE();
    END CATCH
    
    IF @err NOT LIKE '%Execution returned only 5 ResultSets. ResultSet [[]9] does not exist.%'
    BEGIN
        EXEC tSQLt.Fail 'Unexpected error message was: ', @err;
    END;
END;
GO

CREATE PROC tSQLt_test_ResultSetToTable.[test ResultSetToTable (Compatability) retrieves no records and throws no error if 0 is specified]
AS
BEGIN
    CREATE TABLE #Actual (val INT);
    
	EXEC tSQLt.ResultSetToTable #Actual, 0, 'SELECT 1 AS val; SELECT 2 AS val; SELECT 3 AS val;';
    
    CREATE TABLE #Expected (val INT);
    
    EXEC tSQLt.AssertEqualsTable '#Actual', '#Expected';
END;
GO

CREATE PROC tSQLt_test_ResultSetToTable.[test ResultSetToTable (Compatability) retrieves no result set if 0 is specified]
AS
BEGIN
    DECLARE @err NVARCHAR(MAX); SET @err = '--NO Error Thrown!--';
    
    BEGIN TRY
        CREATE TABLE #Actual (val INT);
		EXEC tSQLt.ResultSetToTable #Actual, 1, 'EXEC tSQLt.ResultSetFilter 0, ''SELECT 1 AS val; SELECT 2 AS val; SELECT 3 AS val;'';';  
    END TRY
    BEGIN CATCH
        SET @err = ERROR_MESSAGE();
    END CATCH
    
    IF @err NOT LIKE '%Execution returned only 0 ResultSets. ResultSet [[]1] does not exist.%'
    BEGIN
        EXEC tSQLt.Fail 'Unexpected error message was: ', @err;
    END;
END;
GO

CREATE PROC tSQLt_test_ResultSetToTable.[test ResultSetToTable (Compatability) handles code not returning a result set]
AS
BEGIN
    DECLARE @err NVARCHAR(MAX); SET @err = '--NO Error Thrown!--';
    
    BEGIN TRY
		CREATE TABLE #Actual (val INT);
		EXEC tSQLt.ResultSetToTable #Actual, 1, 'DECLARE @NoOp INT;';  
    END TRY
    BEGIN CATCH
        SET @err = ERROR_MESSAGE();
    END CATCH
    
    IF @err NOT LIKE '%Execution returned only 0 ResultSets. ResultSet [[]1] does not exist.%'
    BEGIN
        EXEC tSQLt.Fail 'Unexpected error message was: ', @err;
    END;
END;
GO

CREATE PROC tSQLt_test_ResultSetToTable.[test ResultSetToTable (Compatability) throws no error if code is not returning a result set and 0 is passed in]
AS
BEGIN
	  CREATE TABLE #Actual (val INT);
      EXEC tSQLt.ResultSetToTable #Actual, 0,'DECLARE @NoOp INT;';  
END;
GO

CREATE PROC tSQLt_test_ResultSetToTable.[test ResultSetToTable (Compatability) throws error if result set number NULL specified]
AS
BEGIN
    DECLARE @err NVARCHAR(MAX); SET @err = '--NO Error Thrown!--';
    
    BEGIN TRY
		CREATE TABLE #Actual (val INT);
        EXEC tSQLt.ResultSetToTable #Actual, NULL, 'SELECT 1 AS val; SELECT 2 AS val; SELECT 3 AS val;';
    END TRY
    BEGIN CATCH
        SET @err = ERROR_MESSAGE();
    END CATCH
    
    IF @err NOT LIKE '%ResultSet index begins at 1. ResultSet index [[]Null] is invalid.%'
    BEGIN
        EXEC tSQLt.Fail 'Unexpected error message was: ', @err;
    END;
END;
GO

CREATE PROC tSQLt_test_ResultSetToTable.[test ResultSetToTable (Compatability) throws error if result set number of less than 0 specified]
AS
BEGIN
    DECLARE @err NVARCHAR(MAX); SET @err = '';
    
    BEGIN TRY
		CREATE TABLE #Actual (val INT);
        EXEC tSQLt.ResultSetToTable #Actual, -1, 'SELECT 1 AS val; SELECT 2 AS val; SELECT 3 AS val;';
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

-- GENERATED WITH tSQLt\Experiments\GenerateTestsForResultsetToTableDataTypes.sql
CREATE PROC tSQLt_test_ResultSetToTable.[test ResultSetToTable (Compatability) can handle each datatype]
AS
BEGIN
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''76456376'' AS BIGINT) AS val;',
        'CREATE TABLE #Actual (val BIGINT NULL); EXEC tSQLt.ResultSetToTable #Actual, 1, ''SELECT CAST(''''76456376'''' AS BIGINT) AS val;''; SELECT * FROM #Actual;';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''0x432643'' AS BINARY(15)) AS val;',
        'CREATE TABLE #Actual (val BINARY(15) NULL); EXEC tSQLt.ResultSetToTable #Actual, 1, ''SELECT CAST(''''0x432643'''' AS BINARY(15)) AS val;''; SELECT * FROM #Actual;';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''1'' AS BIT) AS val;',
        'CREATE TABLE #Actual (val BIT NULL); EXEC tSQLt.ResultSetToTable #Actual, 1, ''SELECT CAST(''''1'''' AS BIT) AS val;''; SELECT * FROM #Actual;';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''ABCDEF'' AS CHAR(15)) AS val;',
        'CREATE TABLE #Actual (val CHAR(15) NULL); EXEC tSQLt.ResultSetToTable #Actual, 1, ''SELECT CAST(''''ABCDEF'''' AS CHAR(15)) AS val;''; SELECT * FROM #Actual;';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''12/27/2010 11:54:12.003'' AS DATETIME) AS val;',
        'CREATE TABLE #Actual (val DATETIME NULL); EXEC tSQLt.ResultSetToTable #Actual, 1, ''SELECT CAST(''''12/27/2010 11:54:12.003'''' AS DATETIME) AS val;''; SELECT * FROM #Actual;';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''234.567'' AS DECIMAL(7,4)) AS val;',
        'CREATE TABLE #Actual (val DECIMAL(7,4) NULL); EXEC tSQLt.ResultSetToTable #Actual, 1, ''SELECT CAST(''''234.567'''' AS DECIMAL(7,4)) AS val;''; SELECT * FROM #Actual;';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''12345.6789'' AS FLOAT) AS val;',
        'CREATE TABLE #Actual (val FLOAT NULL); EXEC tSQLt.ResultSetToTable #Actual, 1, ''SELECT CAST(''''12345.6789'''' AS FLOAT) AS val;''; SELECT * FROM #Actual;';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''XYZ'' AS IMAGE) AS val;',
        'CREATE TABLE #Actual (val IMAGE NULL); EXEC tSQLt.ResultSetToTable #Actual, 1, ''SELECT CAST(''''XYZ'''' AS IMAGE) AS val;''; SELECT * FROM #Actual;';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''13'' AS INT) AS val;',
        'CREATE TABLE #Actual (val INT NULL); EXEC tSQLt.ResultSetToTable #Actual, 1, ''SELECT CAST(''''13'''' AS INT) AS val;''; SELECT * FROM #Actual;';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''12.95'' AS MONEY) AS val;',
        'CREATE TABLE #Actual (val MONEY NULL); EXEC tSQLt.ResultSetToTable #Actual, 1, ''SELECT CAST(''''12.95'''' AS MONEY) AS val;''; SELECT * FROM #Actual;';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''ABCDEF'' AS NCHAR(15)) AS val;',
        'CREATE TABLE #Actual (val NCHAR(15) NULL); EXEC tSQLt.ResultSetToTable #Actual, 1, ''SELECT CAST(''''ABCDEF'''' AS NCHAR(15)) AS val;''; SELECT * FROM #Actual;';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''ABCDEF'' AS NTEXT) AS val;',
        'CREATE TABLE #Actual (val NTEXT NULL); EXEC tSQLt.ResultSetToTable #Actual, 1, ''SELECT CAST(''''ABCDEF'''' AS NTEXT) AS val;''; SELECT * FROM #Actual;';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''345.67'' AS NUMERIC(7,4)) AS val;',
        'CREATE TABLE #Actual (val NUMERIC(7,4) NULL); EXEC tSQLt.ResultSetToTable #Actual, 1, ''SELECT CAST(''''345.67'''' AS NUMERIC(7,4)) AS val;''; SELECT * FROM #Actual;';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''ABCDEF'' AS NVARCHAR(15)) AS val;',
        'CREATE TABLE #Actual (val NVARCHAR(15) NULL); EXEC tSQLt.ResultSetToTable #Actual, 1, ''SELECT CAST(''''ABCDEF'''' AS NVARCHAR(15)) AS val;''; SELECT * FROM #Actual;';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''ABCDEF'' AS NVARCHAR(MAX)) AS val;',
        'CREATE TABLE #Actual (val NVARCHAR(MAX) NULL); EXEC tSQLt.ResultSetToTable #Actual, 1, ''SELECT CAST(''''ABCDEF'''' AS NVARCHAR(MAX)) AS val;''; SELECT * FROM #Actual;';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''12345.6789'' AS REAL) AS val;',
        'CREATE TABLE #Actual (val REAL NULL); EXEC tSQLt.ResultSetToTable #Actual, 1, ''SELECT CAST(''''12345.6789'''' AS REAL) AS val;''; SELECT * FROM #Actual;';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''12/27/2010 09:35'' AS SMALLDATETIME) AS val;',
        'CREATE TABLE #Actual (val SMALLDATETIME NULL); EXEC tSQLt.ResultSetToTable #Actual, 1, ''SELECT CAST(''''12/27/2010 09:35'''' AS SMALLDATETIME) AS val;''; SELECT * FROM #Actual;';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''13'' AS SMALLINT) AS val;',
        'CREATE TABLE #Actual (val SMALLINT NULL); EXEC tSQLt.ResultSetToTable #Actual, 1, ''SELECT CAST(''''13'''' AS SMALLINT) AS val;''; SELECT * FROM #Actual;';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''13.95'' AS SMALLMONEY) AS val;',
        'CREATE TABLE #Actual (val SMALLMONEY NULL); EXEC tSQLt.ResultSetToTable #Actual, 1, ''SELECT CAST(''''13.95'''' AS SMALLMONEY) AS val;''; SELECT * FROM #Actual;';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''ABCDEF'' AS SQL_VARIANT) AS val;',
        'CREATE TABLE #Actual (val SQL_VARIANT NULL); EXEC tSQLt.ResultSetToTable #Actual, 1, ''SELECT CAST(''''ABCDEF'''' AS SQL_VARIANT) AS val;''; SELECT * FROM #Actual;';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''ABCDEF'' AS SYSNAME) AS val;',
        'CREATE TABLE #Actual (val SYSNAME NULL); EXEC tSQLt.ResultSetToTable #Actual, 1, ''SELECT CAST(''''ABCDEF'''' AS SYSNAME) AS val;''; SELECT * FROM #Actual;';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''ABCDEF'' AS TEXT) AS val;',
        'CREATE TABLE #Actual (val TEXT NULL); EXEC tSQLt.ResultSetToTable #Actual, 1, ''SELECT CAST(''''ABCDEF'''' AS TEXT) AS val;''; SELECT * FROM #Actual;';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''0x1234'' AS TIMESTAMP) AS val;',
        'CREATE TABLE #Actual (val TIMESTAMP NULL); EXEC tSQLt.ResultSetToTable #Actual, 1, ''SELECT CAST(''''0x1234'''' AS TIMESTAMP) AS val;''; SELECT * FROM #Actual;';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''7'' AS TINYINT) AS val;',
        'CREATE TABLE #Actual (val TINYINT NULL); EXEC tSQLt.ResultSetToTable #Actual, 1, ''SELECT CAST(''''7'''' AS TINYINT) AS val;''; SELECT * FROM #Actual;';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''F12AF25F-E043-4475-ADD1-96B8BBC6F16E'' AS UNIQUEIDENTIFIER) AS val;',
        'CREATE TABLE #Actual (val UNIQUEIDENTIFIER NULL); EXEC tSQLt.ResultSetToTable #Actual, 1, ''SELECT CAST(''''F12AF25F-E043-4475-ADD1-96B8BBC6F16E'''' AS UNIQUEIDENTIFIER) AS val;''; SELECT * FROM #Actual;';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''ABCDEF'' AS VARBINARY(15)) AS val;',
        'CREATE TABLE #Actual (val VARBINARY(15) NULL); EXEC tSQLt.ResultSetToTable #Actual, 1, ''SELECT CAST(''''ABCDEF'''' AS VARBINARY(15)) AS val;''; SELECT * FROM #Actual;';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''ABCDEF'' AS VARBINARY(MAX)) AS val;',
        'CREATE TABLE #Actual (val VARBINARY(MAX) NULL); EXEC tSQLt.ResultSetToTable #Actual, 1, ''SELECT CAST(''''ABCDEF'''' AS VARBINARY(MAX)) AS val;''; SELECT * FROM #Actual;';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''ABCDEF'' AS VARCHAR(15)) AS val;',
        'CREATE TABLE #Actual (val VARCHAR(15) NULL); EXEC tSQLt.ResultSetToTable #Actual, 1, ''SELECT CAST(''''ABCDEF'''' AS VARCHAR(15)) AS val;''; SELECT * FROM #Actual;';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''ABCDEF'' AS VARCHAR(MAX)) AS val;',
        'CREATE TABLE #Actual (val VARCHAR(MAX) NULL); EXEC tSQLt.ResultSetToTable #Actual, 1, ''SELECT CAST(''''ABCDEF'''' AS VARCHAR(MAX)) AS val;''; SELECT * FROM #Actual;';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''<xml>hi</xml>'' AS XML) AS val;',
        'CREATE TABLE #Actual (val XML NULL); EXEC tSQLt.ResultSetToTable #Actual, 1, ''SELECT CAST(''''<xml>hi</xml>'''' AS XML) AS val;''; SELECT * FROM #Actual;';
END;
GO

CREATE PROC tSQLt_test_ResultSetToTable.[test ResultSetToTable (Compatability) produces only requested columns when underlying table contains primary key]
AS
BEGIN
    CREATE TABLE BaseTable (i INT PRIMARY KEY, v VARCHAR(15));
    INSERT INTO BaseTable (i, v) VALUES (1, 'hello');
    
    CREATE TABLE #Actual (v VARCHAR(15));
    EXEC tSQLt.ResultSetToTable #Actual, 1, 'SELECT v FROM BaseTable';
    
    CREATE TABLE #Expected (v VARCHAR(15));
    INSERT INTO #Expected (v) VALUES ('hello');
    
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROC tSQLt_test_ResultSetToTable.[test ResultSetToTable (Compatability) produces only requested columns when a join on foreign keys is performed]
AS
BEGIN
    CREATE TABLE BaseTable1 (i1 INT PRIMARY KEY, v1 VARCHAR(15));
    INSERT INTO BaseTable1 (i1, v1) VALUES (1, 'hello');
    
    CREATE TABLE BaseTable2 (i2 INT PRIMARY KEY, i1 INT FOREIGN KEY REFERENCES BaseTable1(i1), v2 VARCHAR(15));
    INSERT INTO BaseTable2 (i2, i1, v2) VALUES (1, 1, 'goodbye');
    
    CREATE TABLE #Actual (v1 VARCHAR(15), v2 VARCHAR(15));
    EXEC tSQLt.ResultSetToTable #Actual, 1, 'SELECT v1, v2 FROM BaseTable1 JOIN BaseTable2 ON BaseTable1.i1 = BaseTable2.i1';
    
    CREATE TABLE #Expected (v1 VARCHAR(15), v2 VARCHAR(15));
    INSERT INTO #Expected (v1, v2) VALUES ('hello', 'goodbye');
    
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROC tSQLt_test_ResultSetToTable.[test ResultSetToTable (Compatability) produces only requested columns when a unique column exists]
AS
BEGIN
    CREATE TABLE BaseTable1 (i1 INT UNIQUE, v1 VARCHAR(15));
    INSERT INTO BaseTable1 (i1, v1) VALUES (1, 'hello');
    
    CREATE TABLE #Actual (v1 VARCHAR(15));
    EXEC tSQLt.ResultSetToTable #Actual, 1, 'SELECT v1 FROM BaseTable1';
    
    CREATE TABLE #Expected (v1 VARCHAR(15));
    INSERT INTO #Expected (v1) VALUES ('hello');
    
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROC tSQLt_test_ResultSetToTable.[test ResultSetToTable (Compatability) produces only requested columns when a check constraint exists]
AS
BEGIN
    CREATE TABLE BaseTable1 (i1 INT CHECK(i1 = 1), v1 VARCHAR(15));
    INSERT INTO BaseTable1 (i1, v1) VALUES (1, 'hello');
    
    CREATE TABLE #Actual (v1 VARCHAR(15));
    EXEC tSQLt.ResultSetToTable #Actual, 1, 'SELECT v1 FROM BaseTable1';
    
    CREATE TABLE #Expected (v1 VARCHAR(15));
    INSERT INTO #Expected (v1) VALUES ('hello');
    
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

-------------------------------------------------------
-- The remaining tests are for ResultSetToTable 
-- Ensuring it can work without failing with INSERT EXEC nested issue
-------------------------------------------------------
CREATE PROC tSQLt_test_ResultSetToTable.[_DataReturnTable]
AS 
BEGIN
	SELECT CAST('TEST' AS VARCHAR(15)) as col1, CAST(123 AS INT) AS col2
	UNION
	SELECT 'TEST', 456
END;
GO

CREATE PROC tSQLt_test_ResultSetToTable.[_DataUsesInsertExec]
AS 
BEGIN
	DECLARE @cachedResults TABLE(col1 VARCHAR(15) NULL , col2 int NULL);
	INSERT INTO @cachedResults EXEC tSQLt_test_ResultSetToTable.[_DataReturnTable]
	
	-- Multiple Returns using @cachedResults 
	SELECT col1, SUM(col2) AS col2 FROM @cachedResults GROUP BY col1;
	SELECT col1, MIN(col2) AS col2 FROM @cachedResults GROUP BY col1;
END;
GO

CREATE PROC tSQLt_test_ResultSetToTable.[test ResultSetFilter Known Issue that INSERT EXEC cannot be nested]
AS BEGIN	
	-- This will start fail once SQL server allows nested INSERT EXEC
	--  https://github.com/tSQLt-org/tSQLt/issues/18
	DECLARE @actual2 TABLE(col1 VARCHAR(15) NULL, col2 int NULL);

	EXEC tSQLt.ExpectException @Message = 'An INSERT EXEC statement cannot be nested.';

	INSERT INTO @actual2 EXEC tSQLt.ResultSetFilter 1, 'EXEC tSQLt_test_ResultSetToTable._DataUsesInsertExec';
END;
GO

CREATE PROC tSQLt_test_ResultSetToTable.[test ResultSetToTable returns specified result set (1 of 2)]
AS BEGIN
	CREATE TABLE #expected (col1 VARCHAR(15) NULL , col2 int NULL);
	INSERT INTO #expected VALUES ('TEST', 579); -- 123 + 456

	CREATE TABLE #actual (col1 VARCHAR(15) NULL , col2 int NULL);		
	EXEC tSQLt.ResultSetToTable #actual, 1, 'EXEC tSQLt_test_ResultSetToTable._DataUsesInsertExec'

	EXEC tSQLt.AssertEqualsTable '#expected', '#actual';
END;
GO

CREATE PROC tSQLt_test_ResultSetToTable.[test ResultSetToTable returns specified result set (2 of 2)]
AS BEGIN	
	CREATE TABLE #expected (col1 VARCHAR(15) NULL , col2 int NULL);
	INSERT INTO #expected VALUES ('TEST', 123 );

	CREATE TABLE #actual (col1 VARCHAR(15) NULL , col2 int NULL);
	EXEC tSQLt.ResultSetToTable  #actual, 2,  'EXEC tSQLt_test_ResultSetToTable._DataUsesInsertExec'
	
	EXEC tSQLt.AssertEqualsTable '#expected', '#actual';
END;
GO

CREATE PROC tSQLt_test_ResultSetToTable.[test ResultSetToTable uses column names to populate target table]
AS
BEGIN
    CREATE TABLE #Actual (val1 VARCHAR(10), val2 INT);
	EXEC tSQLt.ResultSetToTable #Actual, 1, 'SELECT 2 AS val2, ''ONE'' as val1';

    CREATE TABLE #Expected (val1 VARCHAR(10), val2 INT);
    INSERT INTO #Expected VALUES ('ONE', 2);

    EXEC tSQLt.AssertEqualsTable '#Actual', '#Expected';
END;
GO

CREATE PROC tSQLt_test_ResultSetToTable.[test ResultSetToTable ignores columns not in target table]
AS
BEGIN
    CREATE TABLE #Actual (val1 VARCHAR(10), val2 INT);
	EXEC tSQLt.ResultSetToTable #Actual, 1, 'SELECT 2 AS val2, ''ONE'' as val1, 4 as ExtraColumn';

    CREATE TABLE #Expected (val1 VARCHAR(10), val2 INT);
    INSERT INTO #Expected VALUES ('ONE', 2);

    EXEC tSQLt.AssertEqualsTable '#Actual', '#Expected';
END;
GO

CREATE PROC tSQLt_test_ResultSetToTable.[test ResultSetToTable skips columns not in result set]
AS
BEGIN
    CREATE TABLE #Actual (val1 INT, notpopulated INT);
	EXEC tSQLt.ResultSetToTable #Actual, 1, 'SELECT 1 AS val1';

    CREATE TABLE #Expected (val1 INT, notpopulated INT);
    INSERT INTO #Expected VALUES (1 , null);

    EXEC tSQLt.AssertEqualsTable '#Actual', '#Expected';
END;
GO