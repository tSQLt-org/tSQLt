EXEC tSQLt.NewTestClass 'tSQLt_test_ResultSetFilter';
GO
CREATE PROC tSQLt_test_ResultSetFilter.[test ResultSetFilter returns specified result set]
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

CREATE PROC tSQLt_test_ResultSetFilter.[test ResultSetFilter returns specified result set with multiple columns]
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

CREATE PROC tSQLt_test_ResultSetFilter.[test ResultSetFilter throws error if specified result set is 1 greater than number of result sets returned]
AS
BEGIN
    DECLARE @err NVARCHAR(MAX); SET @err = '--NO Error Thrown!--';
    
    BEGIN TRY
        EXEC tSQLt.ResultSetFilter 4, 'SELECT 1 AS val; SELECT 2 AS val; SELECT 3 AS val;';
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

CREATE PROC tSQLt_test_ResultSetFilter.[test ResultSetFilter throws error if specified result set is more than 1 greater than number of result sets returned]
AS
BEGIN
    DECLARE @err NVARCHAR(MAX); SET @err = '--NO Error Thrown!--';
    
    BEGIN TRY
        EXEC tSQLt.ResultSetFilter 9, 'SELECT 1 AS val; SELECT 2 AS val; SELECT 3 AS val; SELECT 4 AS val; SELECT 5 AS val;';
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

CREATE PROC tSQLt_test_ResultSetFilter.[test ResultSetFilter retrieves no records if 0 is specified]
AS
BEGIN
    CREATE TABLE Actual (val INT);
    INSERT INTO Actual
    EXEC tSQLt.ResultSetFilter 0, 'SELECT 1 AS val; SELECT 2 AS val; SELECT 3 AS val;';
    
    CREATE TABLE Expected (val INT);
    
    EXEC tSQLt.AssertEqualsTable 'Actual', 'Expected';
END;
GO

CREATE PROC tSQLt_test_ResultSetFilter.[test ResultSetFilter throws error if result set number NULL specified]
AS
BEGIN
    DECLARE @err NVARCHAR(MAX); SET @err = '--NO Error Thrown!--';
    
    BEGIN TRY
        EXEC tSQLt.ResultSetFilter NULL, 'SELECT 1 AS val; SELECT 2 AS val; SELECT 3 AS val;';
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


CREATE PROC tSQLt_test_ResultSetFilter.[test ResultSetFilter throws error if result set number of less than 0 specified]
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

CREATE PROC tSQLt_test_ResultSetFilter.[test ResultSetFilter can handle each datatype]
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

CREATE PROC tSQLt_test_ResultSetFilter.[test ResultSetFilter produces only requested columns when underlying table contains primary key]
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

CREATE PROC tSQLt_test_ResultSetFilter.[test ResultSetFilter produces only requested columns when a join on foreign keys is performed]
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

CREATE PROC tSQLt_test_ResultSetFilter.[test ResultSetFilter produces only requested columns when a unique column exists]
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

CREATE PROC tSQLt_test_ResultSetFilter.[test ResultSetFilter produces only requested columns when a check constraint exists]
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
