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

CREATE PROC AssertNotEqualsTests.[test AssertNotEquals passes with various values of different datatypes]
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

CREATE PROC AssertNotEqualsTests.[test AssertNotEquals should give meaningfull failmessage]
AS
BEGIN
  EXEC tSQLt.RemoveObject 'tSQLt.Private_SqlVariantFormatter';
  EXEC('CREATE FUNCTION tSQLt.Private_SqlVariantFormatter(@Value SQL_VARIANT)RETURNS'+
       ' NVARCHAR(MAX) AS BEGIN DECLARE @msg NVARCHAR(MAX);SET @msg ='+
       '''{SVF was called with <''+CAST(@Value AS NVARCHAR(MAX))+''>}'';RETURN @msg; END;');

  EXEC tSQLt_testutil.AssertFailMessageLike 'EXEC tSQLt.AssertNotEquals 13, 13;', 
       'Expected actual value to not equal <{SVF was called with <13>}>.';
    
END;
GO

CREATE PROC AssertNotEqualsTests.[test AssertNotEquals with VARCHAR(MAX) throws error]
AS
BEGIN
    DECLARE @Msg NVARCHAR(MAX); SET @Msg = 'no error';

    BEGIN TRY
        DECLARE @V1 VARCHAR(MAX); SET @V1 = REPLICATE(CAST('TestString' AS VARCHAR(MAX)),1000);
        EXEC tSQLt.AssertNotEquals @V1, @V1;
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

