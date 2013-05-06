EXEC tSQLt.NewTestClass 'AssertNotEqualsTests';
GO

CREATE PROC AssertNotEqualsTests.[test AssertNotEquals should do nothing with two unequal ints]
AS
BEGIN
    EXEC tSQLt.AssertNotEquals 0, 1;
END;
GO

CREATE PROC AssertNotEqualsTests.[test AssertNotEquals should call fail with equal ints]
AS
BEGIN
    EXEC tSQLt_testutil.assertFailCalled 'EXEC tSQLt.AssertNotEquals 1, 1;', 'AssertNotEquals did not call Fail';
END;
GO

CREATE PROC AssertNotEqualsTests.[test AssertNotEquals should give meaningfull fail message]
AS
BEGIN
    EXEC tSQLt_testutil.AssertFailMessageLike 'EXEC tSQLt.AssertNotEquals 13, 13;', '%Expected actual value to not equal <13>.%';
END;
GO

CREATE PROC AssertNotEqualsTests.[test AssertNotEquals should not call fail with expected null and nonnull actual]
AS
BEGIN
    EXEC tSQLt.AssertNotEquals NULL,1;
END;
GO

CREATE PROC AssertNotEqualsTests.[test AssertNotEquals should not call fail with actual null and nonnull expected]
AS
BEGIN
    EXEC tSQLt.AssertNotEquals 1,NULL;
END;
GO

CREATE PROC AssertNotEqualsTests.[test AssertNotEquals should call fail with equal nulls]
AS
BEGIN
    EXEC tSQLt_testutil.assertFailCalled 'EXEC tSQLt.AssertNotEquals NULL, NULL;', 'AssertNotEquals did not call Fail';
END;
GO

CREATE PROC AssertNotEqualsTests.[test AssertNotEquals should give meaningfull fail message on NULL]
AS
BEGIN
    EXEC tSQLt_testutil.AssertFailMessageLike 'EXEC tSQLt.AssertNotEquals NULL, NULL;', '%Expected actual value to not be NULL.%';
END;
GO

CREATE PROC AssertNotEqualsTests.[test AssertNotEquals should pass message when calling fail]
AS
BEGIN
    EXEC tSQLt_testutil.AssertFailMessageLike 'EXEC tSQLt.AssertNotEquals 1, 1,''{MyMessage}'';', '%{MyMessage}%';
END;
GO

CREATE PROC AssertNotEqualsTests.[test AssertNotEquals passes with various datatypes of different values]
AS
BEGIN
    EXEC tSQLt.AssertNotEquals 12345.6789, 4321.1234;
    EXEC tSQLt.AssertNotEquals 'hello', 'goodbye';
    EXEC tSQLt.AssertNotEquals N'hello', N'goodbye';
    
    DECLARE @Datetime1 DATETIME; SET @Datetime1 = CAST('12-13-2005' AS DATETIME);
    DECLARE @Datetime2 DATETIME; SET @Datetime2 = CAST('6-17-2005' AS DATETIME);
    EXEC tSQLt.AssertNotEquals @Datetime1, @Datetime2;
    
    DECLARE @Bit0 BIT; SET @Bit0 = CAST(0 AS BIT);
    DECLARE @Bit1 BIT; SET @Bit1 = CAST(1 AS BIT);
    EXEC tSQLt.AssertNotEquals @Bit0, @Bit1;
END;
GO

CREATE PROC AssertNotEqualsTests.[test AssertNotEquals fails for equal values of various datatypes]
AS
BEGIN
    EXEC tSQLt_testutil.assertFailCalled 'EXEC tSQLt.AssertNotEquals 12345.6789, 12345.6789' ;
    EXEC tSQLt_testutil.assertFailCalled 'EXEC tSQLt.AssertNotEquals ''hello'', ''hello''';
    EXEC tSQLt_testutil.assertFailCalled 'EXEC tSQLt.AssertNotEquals N''hello'', N''hello''';
    
    EXEC tSQLt_testutil.assertFailCalled '
        DECLARE @Datetime1 DATETIME; SET @Datetime1 = CAST(''12-13-2005'' AS DATETIME);
        EXEC tSQLt.AssertNotEquals @Datetime1, @Datetime1;';
    
    EXEC tSQLt_testutil.assertFailCalled '
        DECLARE @Bit0 BIT; SET @Bit0 = CAST(0 AS BIT);
        EXEC tSQLt.AssertNotEquals @Bit0, @Bit0;';
END;
GO


