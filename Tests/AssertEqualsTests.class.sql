EXEC tSQLt.NewTestClass 'AssertEqualsTests';
GO

CREATE PROC AssertEqualsTests.[test AssertEquals should do nothing with two equal ints]
AS
BEGIN
    EXEC tSQLt.AssertEquals 1, 1;
END;
GO

CREATE PROC AssertEqualsTests.[test AssertEquals should do nothing with two NULLs]
AS
BEGIN
    EXEC tSQLt.AssertEquals NULL, NULL;
END;
GO

CREATE PROC AssertEqualsTests.[test AssertEquals should call fail with nonequal ints]
AS
BEGIN
    EXEC tSQLt_testutil.assertFailCalled 'EXEC tSQLt.AssertEquals 1, 2;', 'AssertEquals did not call Fail';
END;
GO

CREATE PROC AssertEqualsTests.[test AssertEquals should call fail with expected int and actual NULL]
AS
BEGIN
    EXEC tSQLt_testutil.assertFailCalled 'EXEC tSQLt.AssertEquals 1, NULL;', 'AssertEquals did not call Fail';
END;
GO

CREATE PROC AssertEqualsTests.[test AssertEquals should call fail with expected NULL and actual int]
AS
BEGIN
    EXEC tSQLt_testutil.assertFailCalled 'EXEC tSQLt.AssertEquals NULL, 1;', 'AssertEquals did not call Fail';
END;
GO

CREATE PROC AssertEqualsTests.[test AssertEquals passes with various datatypes with the same value]
AS
BEGIN
    EXEC tSQLt.AssertEquals 12345.6789, 12345.6789;
    EXEC tSQLt.AssertEquals 'hello', 'hello';
    EXEC tSQLt.AssertEquals N'hello', N'hello';
    
    DECLARE @Datetime DATETIME; SET @Datetime = CAST('12-13-2005' AS DATETIME);
    EXEC tSQLt.AssertEquals @Datetime, @Datetime;
    
    DECLARE @Bit BIT; SET @Bit = CAST(1 AS BIT);
    EXEC tSQLt.AssertEquals @Bit, @Bit;
END;
GO

CREATE PROC AssertEqualsTests.[test AssertEquals fails with various datatypes of different values]
AS
BEGIN
    EXEC tSQLt_testutil.assertFailCalled 'EXEC tSQLt.AssertEquals 12345.6789, 4321.1234', 'AssertEquals did not call Fail';
    EXEC tSQLt_testutil.assertFailCalled 'EXEC tSQLt.AssertEquals ''hello'', ''goodbye''', 'AssertEquals did not call Fail';
    EXEC tSQLt_testutil.assertFailCalled 'EXEC tSQLt.AssertEquals N''hello'', N''goodbye''', 'AssertEquals did not call Fail';
    
    EXEC tSQLt_testutil.assertFailCalled '
        DECLARE @Datetime1 DATETIME; SET @Datetime1 = CAST(''12-13-2005'' AS DATETIME);
        DECLARE @Datetime2 DATETIME; SET @Datetime2 = CAST(''6-17-2005'' AS DATETIME);
        EXEC tSQLt.AssertEquals @Datetime1, @Datetime2;', 'AssertEquals did not call Fail';
    
    EXEC tSQLt_testutil.assertFailCalled '
        DECLARE @Bit0 BIT; SET @Bit0 = CAST(0 AS BIT);
        DECLARE @Bit1 BIT; SET @Bit1 = CAST(1 AS BIT);
        EXEC tSQLt.AssertEquals @Bit0, @Bit1;', 'AssertEquals did not call Fail';
END;
GO

CREATE PROC AssertEqualsTests.[test AssertEquals with VARCHAR(MAX) throws error]
AS
BEGIN
    DECLARE @Msg NVARCHAR(MAX); SET @Msg = 'no error';

    BEGIN TRY
        DECLARE @V1 VARCHAR(MAX); SET @V1 = REPLICATE(CAST('TestString' AS VARCHAR(MAX)),1000);
        EXEC tSQLt.AssertEquals @V1, @V1;
    END TRY
    BEGIN CATCH
        SET @Msg = ERROR_MESSAGE();
    END CATCH
    
    IF @Msg NOT LIKE '%Operand type clash%'
    BEGIN
        EXEC tSQLt.Fail 'Expected operand type clash error when AssertEquals used with VARCHAR(MAX), instead was: ', @Msg;
    END
    
END;
GO