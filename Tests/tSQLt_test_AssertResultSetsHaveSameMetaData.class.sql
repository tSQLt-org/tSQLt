EXEC tSQLt.NewTestClass 'tSQLt_test_AssertResultSetsHaveSameMetaData';
GO
CREATE PROC tSQLt_test_AssertResultSetsHaveSameMetaData.[test AssertResultSetsHaveSameMetaData does not fail for two single bigint column result sets]
AS
BEGIN
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(1 AS BIGINT) A', 
        'SELECT CAST(1 AS BIGINT) A'; 
END;
GO

CREATE PROC tSQLt_test_AssertResultSetsHaveSameMetaData.[test AssertResultSetsHaveSameMetaData fails for a schema with integer and another with bigint]
AS
BEGIN
    EXEC tSQLt_testutil.assertFailCalled 
        'EXEC tSQLt.AssertResultSetsHaveSameMetaData ''SELECT CAST(1 AS INT) A'', ''SELECT CAST(1 AS BIGINT) A'';',
        'Expected tSQLt.Fail to be called when result sets have different meta data';
END;
GO

CREATE PROC tSQLt_test_AssertResultSetsHaveSameMetaData.[test AssertResultSetsHaveSameMetaData does not fail for identical single column result sets]
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

CREATE PROC tSQLt_test_AssertResultSetsHaveSameMetaData.[test AssertResultSetsHaveSameMetaData does not fail for identical multiple column result sets]
AS
BEGIN
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(1 AS INT) A, CAST(''ABC'' AS VARCHAR(MAX)) B, CAST(13.9 AS DECIMAL(10,1)) C', 
        'SELECT CAST(3 AS INT) A, CAST(''DEFGH'' AS VARCHAR(MAX)) B, CAST(197.8 AS DECIMAL(10,1)) C';
END;
GO

CREATE PROC tSQLt_test_AssertResultSetsHaveSameMetaData.[test AssertResultSetsHaveSameMetaData fails when one result set has no rows]
AS
BEGIN
    IF (SELECT CAST(SUBSTRING(product_version, 1, 2) AS INT) FROM sys.dm_os_loaded_modules WHERE name LIKE '%\sqlservr.exe') >= 11
    BEGIN
      EXEC tSQLt.AssertResultSetsHaveSameMetaData
          'SELECT CAST(1 AS INT) A', 
          'SELECT CAST(A AS INT) A FROM (SELECT CAST(3 AS INT) A) X WHERE 1 = 0';
    END
    ELSE
    BEGIN
      EXEC tSQLt_testutil.assertFailCalled 
          'EXEC tSQLt.AssertResultSetsHaveSameMetaData
              ''SELECT CAST(1 AS INT) A'', 
              ''SELECT CAST(A AS INT) A FROM (SELECT CAST(3 AS INT) A) X WHERE 1 = 0''',
              'Expected tSQLt.Fail called when AssertResultSetsHaveSameMetaData called with result set which returns no metadata';
    END;
END;
GO

CREATE PROC tSQLt_test_AssertResultSetsHaveSameMetaData.[test AssertResultSetsHaveSameMetaData fails for differing single column result sets]
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

CREATE PROC tSQLt_test_AssertResultSetsHaveSameMetaData.[test AssertResultSetsHaveSameMetaData fails for result sets with different number of columns]
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

CREATE PROC tSQLt_test_AssertResultSetsHaveSameMetaData.[test AssertResultSetsHaveSameMetaData fails if either command produces no result set]
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

CREATE PROC tSQLt_test_AssertResultSetsHaveSameMetaData.[test AssertResultSetsHaveSameMetaData throws an exception if a command produces an exception]
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

CREATE PROC tSQLt_test_AssertResultSetsHaveSameMetaData.[test AssertResultSetsHaveSameMetaData throws an exception if either command has a syntax error]
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

CREATE PROC tSQLt_test_AssertResultSetsHaveSameMetaData.[test AssertResultSetsHaveSameMetaData does not compare hidden columns]
AS
BEGIN
    EXEC('CREATE VIEW tSQLt_test_AssertResultSetsHaveSameMetaData.TmpView AS SELECT ''X'' Type FROM sys.objects;');

    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT ''X'' AS Type;', 
        'SELECT Type FROM tSQLt_test_AssertResultSetsHaveSameMetaData.TmpView;'; 
END;
GO

