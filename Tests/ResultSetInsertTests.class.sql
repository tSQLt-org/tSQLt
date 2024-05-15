EXEC tSQLt.NewTestClass 'ResultSetInsertTests';
GO
CREATE PROC ResultSetInsertTests.[test ResultSetInsert returns specified result set]
AS
BEGIN
    CREATE TABLE #Actual (val INT);
    
    EXEC tSQLt.ResultSetInsert 3, 'SELECT 1 AS val; SELECT 2 AS val; SELECT 3 AS val UNION ALL SELECT 4 UNION ALL SELECT 5;', '#Actual';
    
    CREATE TABLE #Expected (val INT);
    INSERT INTO #Expected
    SELECT 3 AS val UNION ALL SELECT 4 UNION ALL SELECT 5;
    
    EXEC tSQLt.AssertEqualsTable '#Actual', '#Expected';
END;
GO

CREATE PROC ResultSetInsertTests.[test ResultSetInsert returns specified result set with multiple columns]
AS
BEGIN
    CREATE TABLE #Actual (val1 INT, val2 VARCHAR(3));
    
    EXEC tSQLt.ResultSetInsert 2, 'SELECT 1 AS val; SELECT 3 AS val1, ''ABC'' AS val2 UNION ALL SELECT 4, ''DEF'' UNION ALL SELECT 5, ''GHI''; SELECT 2 AS val;', '#Actual';
    
    CREATE TABLE #Expected (val1 INT, val2 VARCHAR(3));
    INSERT INTO #Expected
    SELECT 3 AS val1, 'ABC' AS val2 UNION ALL SELECT 4, 'DEF' UNION ALL SELECT 5, 'GHI';
    
    EXEC tSQLt.AssertEqualsTable '#Actual', '#Expected';
END;
GO

CREATE PROC ResultSetInsertTests.[test ResultSetInsert throws error if specified result set is 1 greater than number of result sets returned]
AS
BEGIN
    DECLARE @err NVARCHAR(MAX); SET @err = '--NO Error Thrown!--';

    CREATE TABLE #Actual (val INT);

    BEGIN TRY
        EXEC tSQLt.ResultSetInsert 4, 'SELECT 1 AS val; SELECT 2 AS val; SELECT 3 AS val;', '#Actual';
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

CREATE PROC ResultSetInsertTests.[test ResultSetFilter throws error if specified result set is more than 1 greater than number of result sets returned]
AS
BEGIN
    DECLARE @err NVARCHAR(MAX); SET @err = '--NO Error Thrown!--';

    CREATE TABLE #Actual (val INT);

    BEGIN TRY
        EXEC tSQLt.ResultSetInsert 9, 'SELECT 1 AS val; SELECT 2 AS val; SELECT 3 AS val; SELECT 4 AS val; SELECT 5 AS val;', '#Actual';
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

CREATE PROC ResultSetInsertTests.[test ResultSetFilter retrieves no records and throws no error if 0 is specified]
AS
BEGIN
    CREATE TABLE #Actual (val INT);

    EXEC tSQLt.ResultSetInsert 0, 'SELECT 1 AS val; SELECT 2 AS val; SELECT 3 AS val;', '#Actual';
    
    CREATE TABLE #Expected (val INT);
    
    EXEC tSQLt.AssertEqualsTable '#Actual', '#Expected';
END;
GO

CREATE PROC ResultSetInsertTests.ResultSetInsertHelperP
AS
BEGIN
    CREATE TABLE #t (val INT);
    INSERT INTO #t
    EXEC ResultSetInsertTests.ResultSetInsertHelperQ
    SELECT * FROM #t
END;
GO

CREATE PROC ResultSetInsertTests.ResultSetInsertHelperQ
AS
BEGIN
    SELECT 42
END;
GO

CREATE PROC ResultSetInsertTests.[test ResultSetInserts handles nested insert execs]
AS
BEGIN
    CREATE TABLE #Actual (val INT);
    EXEC tSQLt.ResultSetInsert 1, 'EXEC ResultSetInsertTests.ResultSetInsertHelperP', '#Actual';
    
    CREATE TABLE #Expected (val INT);
    INSERT INTO #Expected
    VALUES (42)
    
    EXEC tSQLt.AssertEqualsTable '#Actual', '#Expected';
END;
GO
