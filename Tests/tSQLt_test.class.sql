DECLARE @Msg VARCHAR(MAX);SELECT @Msg = 'Compiled at '+CONVERT(VARCHAR,GETDATE(),121);RAISERROR(@Msg,0,1);
GO
EXEC tSQLt.DropClass tSQLt_testutil;
GO

CREATE SCHEMA tSQLt_testutil;
GO

CREATE PROC tSQLt_testutil.assertFailCalled
    @Command NVARCHAR(MAX),
    @Message VARCHAR(MAX)
AS
BEGIN
    DECLARE @CallCount INT;
    BEGIN TRAN;
    DECLARE @TranName CHAR(32); EXEC tSQLt.GetNewTranName @TranName OUT;
    SAVE TRAN @TranName;
      EXEC tSQLt.SpyProcedure 'tSQLt.Fail';
      EXEC (@Command);
      SELECT @CallCount = COUNT(1) FROM tSQLt.Fail_SpyProcedureLog;
    ROLLBACK TRAN @TranName;
    COMMIT TRAN;

    IF (@CallCount = 0)
    BEGIN
      EXEC tSQLt.Fail @Message;
    END;
END;
GO

CREATE PROC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses
AS
BEGIN
  DECLARE @TestClassName NVARCHAR(MAX);
  DECLARE @TestProcName NVARCHAR(MAX);

  DECLARE tests CURSOR LOCAL FAST_FORWARD FOR
   SELECT DISTINCT s.name AS testClassName
     FROM sys.extended_properties ep
     JOIN sys.schemas s
       ON ep.major_id = s.schema_id
    WHERE ep.name = N'tSQLt.TestClass';

  OPEN tests;
  
  FETCH NEXT FROM tests INTO @TestClassName;
  WHILE @@FETCH_STATUS = 0
  BEGIN
    EXEC sp_dropextendedproperty @name = 'tSQLt.TestClass',
                                 @level0type = 'SCHEMA',
                                 @level0name = @TestClassName;
    
    FETCH NEXT FROM tests INTO @TestClassName;
  END;
  
  CLOSE tests;
  DEALLOCATE tests;
END;
GO

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
EXEC tSQLt.DropClass tSQLt_test;
GO

IF OBJECT_ID('tSQLt.NewTestClass') IS NOT NULL
    EXEC tSQLt.NewTestClass 'tSQLt_test';
ELSE
    EXEC('CREATE SCHEMA tSQLt_test;');
GO

CREATE PROC [tSQLt_test].[SetUp]
AS
BEGIN
    EXEC tSQLt.SpyProcedure 'tSQLt.Private_PrintXML';
END;
GO

CREATE PROC tSQLt_test.test_TestCasesAreWrappedInTransactions
AS
BEGIN
    DECLARE @ActualTranCount INT;

    BEGIN TRAN;
    DECLARE @TranName CHAR(32); EXEC tSQLt.GetNewTranName @TranName OUT;
    SAVE TRAN @TranName;

    EXEC ('CREATE PROC TestCaseA AS IF(@@TRANCOUNT < 2) RAISERROR(''TranCountMisMatch:%i'',16,10,@@TRANCOUNT);');

    EXEC tSQLt.Private_RunTest TestCaseA;

    SELECT @ActualTranCount=CAST(SUBSTRING(Msg,19,100) AS INT) FROM tSQLt.TestResult WHERE Msg LIKE 'TranCountMisMatch:%';

    ROLLBACK TRAN @TranName;
    COMMIT;

    IF (@ActualTranCount IS NOT NULL)
    BEGIN
        DECLARE @Message VARCHAR(MAX);
        SET @Message = 'Expected 2 transactions but was '+CAST(@ActualTranCount AS VARCHAR);

        EXEC tSQLt.Fail @Message;
    END;
END;
GO

CREATE PROC tSQLt_test.[test Run truncates TestResult table]
AS
BEGIN
    INSERT tSQLt.TestResult(Class, TestCase, TranName) VALUES('TestClass', 'TestCaseDummy','');

    EXEC ('CREATE PROC TestCaseA AS IF(EXISTS(SELECT 1 FROM tSQLt.TestResult WHERE Class = ''TestClass'' AND TestCase = ''TestCaseDummy'')) RAISERROR(''NoTruncationError'',16,10);');

    EXEC tSQLt.Run TestCaseA;

    IF(EXISTS(SELECT 1 FROM tSQLt.TestResult WHERE Msg LIKE '%NoTruncationError%'))
    BEGIN
        EXEC tSQLt.Fail 'tSQLt.Run did not truncate tSQLt.TestResult!';
    END;
END;
GO

CREATE PROC tSQLt_test.[test RunTestClass truncates TestResult table]
AS
BEGIN
    INSERT tSQLt.TestResult(Class, TestCase, TranName) VALUES('TestClass', 'TestCaseDummy','');

    EXEC('CREATE SCHEMA MyTestClass;');
    EXEC('CREATE PROC MyTestClass.TestCaseA AS IF(EXISTS(SELECT 1 FROM tSQLt.TestResult WHERE Class = ''TestClass'' AND TestCase = ''TestCaseDummy'')) RAISERROR(''NoTruncationError'',16,10);');

    EXEC tSQLt.RunTestClass MyTestClass;
   
    IF(EXISTS(SELECT 1 FROM tSQLt.TestResult WHERE Msg LIKE '%NoTruncationError%'))
    BEGIN
        EXEC tSQLt.Fail 'tSQLt.RunTestClass did not truncate tSQLt.TestResult!';
    END;
END;
GO

CREATE PROC tSQLt_test.[test RunTestClass raises error if error in default print mode]
AS
BEGIN
    DECLARE @ErrorRaised INT; SET @ErrorRaised = 0;

    EXEC tSQLt.SetTestResultFormatter 'tSQLt.DefaultResultsFormatter';
    EXEC('CREATE SCHEMA MyTestClass;');
    EXEC('CREATE PROC MyTestClass.TestCaseA AS RETURN 1/0;');
    
    BEGIN TRY
        EXEC tSQLt.RunTestClass MyTestClass;
    END TRY
    BEGIN CATCH
        SET @ErrorRaised = 1;
    END CATCH
    IF(@ErrorRaised = 0)
    BEGIN
        EXEC tSQLt.Fail 'tSQLt.RunTestClass did not raise an error!';
    END
END;
GO

CREATE PROC tSQLt_test.test_Run_handles_test_names_with_spaces
AS
BEGIN
    DECLARE @ErrorRaised INT; SET @ErrorRaised = 0;

    EXEC('CREATE SCHEMA MyTestClass;');
    EXEC('CREATE PROC MyTestClass.[Test Case A] AS RAISERROR(''GotHere'',16,10);');
    
    BEGIN TRY
        EXEC tSQLt.Run 'MyTestClass.Test Case A';
    END TRY
    BEGIN CATCH
        SET @ErrorRaised = 1;
    END CATCH
    SELECT Class, TestCase, Msg 
      INTO actual
      FROM tSQLt.TestResult;
    SELECT 'MyTestClass' Class, 'Test Case A' TestCase, 'GotHere{Test Case A,1}' Msg
      INTO expected;
    
    EXEC tSQLt.AssertEqualsTable 'expected', 'actual';
END;
GO


CREATE PROC tSQLt_test.[test SpyProcedure should allow tester to not execute behavior of procedure]
AS
BEGIN

    EXEC('CREATE PROC dbo.InnerProcedure AS EXEC tSQLt.Fail ''Original InnerProcedure was executed'';');

    EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure';

    EXEC dbo.InnerProcedure;

END;
GO

CREATE PROC tSQLt_test.[test SpyProcedure should allow tester to not execute behavior of procedure with a parameter]
AS
BEGIN

    EXEC('CREATE PROC dbo.InnerProcedure @P1 VARCHAR(MAX) AS EXEC tSQLt.Fail ''InnerProcedure was executed '',@P1;');

    EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure';

    EXEC dbo.InnerProcedure 'with a parameter';

END;
GO

CREATE PROC tSQLt_test.[test SpyProcedure should allow tester to not execute behavior of procedure with multiple parameters]
AS
BEGIN

    EXEC('CREATE PROC dbo.InnerProcedure @P1 VARCHAR(MAX), @P2 VARCHAR(MAX), @P3 VARCHAR(MAX) ' +
         'AS EXEC tSQLt.Fail ''InnerProcedure was executed '',@P1,@P2,@P3;');

    EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure';

    EXEC dbo.InnerProcedure 'with', 'multiple', 'parameters';

END;
GO

CREATE PROC tSQLt_test.[test SpyProcedure should log calls]
AS
BEGIN

    EXEC('CREATE PROC dbo.InnerProcedure @P1 VARCHAR(MAX), @P2 VARCHAR(MAX), @P3 VARCHAR(MAX) ' +
         'AS EXEC tSQLt.Fail ''InnerProcedure was executed '',@P1,@P2,@P3;');

    EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure';

    EXEC dbo.InnerProcedure 'with', 'multiple', 'parameters';

    IF NOT EXISTS(SELECT 1 FROM dbo.InnerProcedure_SpyProcedureLog)
    BEGIN
        EXEC tSQLt.Fail 'InnerProcedure call was not logged!';
    END;

END;
GO

CREATE PROC tSQLt_test.[test SpyProcedure should log calls with varchar parameters]
AS
BEGIN

    EXEC('CREATE PROC dbo.InnerProcedure @P1 VARCHAR(MAX), @P2 VARCHAR(10), @P3 VARCHAR(8000) ' +
         'AS EXEC tSQLt.Fail ''InnerProcedure was executed '',@P1,@P2,@P3;');

    EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure';

    EXEC dbo.InnerProcedure 'with', 'multiple', 'parameters';


    IF NOT EXISTS(SELECT 1
                   FROM dbo.InnerProcedure_SpyProcedureLog
                  WHERE P1 = 'with'
                    AND P2 = 'multiple'
                    AND P3 = 'parameters')
    BEGIN
        EXEC tSQLt.Fail 'InnerProcedure call was not logged correctly!';
    END;

END;
GO

CREATE PROC tSQLt_test.[test SpyProcedure should log call when output parameters are present]
AS
BEGIN
    EXEC('CREATE PROC dbo.InnerProcedure @P1 VARCHAR(100) OUT AS EXEC tSQLt.Fail ''InnerProcedure was executed;''');
    
    EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure';
    
    DECLARE @ActualOutputValue VARCHAR(100);
    
    EXEC dbo.InnerProcedure @P1 = @ActualOutputValue OUT;
    
    IF NOT EXISTS(SELECT 1
                    FROM dbo.InnerProcedure_SpyProcedureLog
                   WHERE P1 IS NULL)
    BEGIN
        EXEC tSQLt.Fail 'InnerProcedure call was not logged correctly!';
    END
END;
GO

CREATE PROC tSQLt_test.[test SpyProcedure should log values of output parameters if input was provided for them]
AS
BEGIN
    EXEC('CREATE PROC dbo.InnerProcedure @P1 VARCHAR(100) OUT AS EXEC tSQLt.Fail ''InnerProcedure was executed;''');
    
    EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure';
    
    DECLARE @ActualOutputValue VARCHAR(100);
    SET @ActualOutputValue = 'HELLO';
    
    EXEC dbo.InnerProcedure @P1 = @ActualOutputValue OUT;
    
    IF NOT EXISTS(SELECT 1
                    FROM dbo.InnerProcedure_SpyProcedureLog
                   WHERE P1 = 'HELLO')
    BEGIN
        EXEC tSQLt.Fail 'InnerProcedure call was not logged correctly!';
    END
END;
GO

CREATE PROC tSQLt_test.[test SpyProcedure should log values if a mix of input an output parameters are provided]
AS
BEGIN
    EXEC('CREATE PROC dbo.InnerProcedure @P1 VARCHAR(100) OUT, @P2 INT, @P3 BIT OUT AS EXEC tSQLt.Fail ''InnerProcedure was executed;''');
    
    EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure';
    
    EXEC dbo.InnerProcedure @P1 = 'PARAM1', @P2 = 2, @P3 = 0;
    
    IF NOT EXISTS(SELECT 1
                    FROM dbo.InnerProcedure_SpyProcedureLog
                   WHERE P1 = 'PARAM1'
                     AND P2 = 2
                     AND P3 = 0)
    BEGIN
        EXEC tSQLt.Fail 'InnerProcedure call was not logged correctly!';
    END
END;
GO

CREATE PROC tSQLt_test.[test SpyProcedure should not log the default values of parameters if no value is provided]
AS
BEGIN
    EXEC('CREATE PROC dbo.InnerProcedure @P1 VARCHAR(100) = ''MY DEFAULT'' AS EXEC tSQLt.Fail ''InnerProcedure was executed;''');
    
    EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure';
    
    EXEC dbo.InnerProcedure;
    
    IF NOT EXISTS(SELECT 1
                    FROM dbo.InnerProcedure_SpyProcedureLog
                   WHERE P1 IS NULL)
    BEGIN
        EXEC tSQLt.Fail 'InnerProcedure call was not logged correctly!';
    END
END;
GO

CREATE PROC tSQLt_test.[test SpyProcedure can be given a command to execute]
AS
BEGIN
    EXEC ('CREATE PROC dbo.InnerProcedure AS EXEC tSQLt.Fail ''InnerProcedure was executed'';');
    
    EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure', 'RETURN 1';
    
    DECLARE @ReturnVal INT;
    EXEC @ReturnVal = dbo.InnerProcedure;
    
    IF NOT EXISTS(SELECT 1 FROM dbo.InnerProcedure_SpyProcedureLog)
    BEGIN
        EXEC tSQLt.Fail 'InnerProcedure call was not logged!';
    END;
    
    EXEC tSQLt.AssertEquals 1, @ReturnVal;
END;
GO

CREATE PROC tSQLt_test.[test command given to SpyProcedure can be used to set output parameters]
AS
BEGIN
    EXEC('CREATE PROC dbo.InnerProcedure @P1 VARCHAR(100) OUT AS EXEC tSQLt.Fail ''InnerProcedure was executed;''');
    
    EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure', 'SET @P1 = ''HELLO'';';
    
    DECLARE @ActualOutputValue VARCHAR(100);
    
    EXEC dbo.InnerProcedure @P1 = @ActualOutputValue OUT;
    
    EXEC tSQLt.AssertEqualsString 'HELLO', @ActualOutputValue;
    
    IF NOT EXISTS(SELECT 1
                    FROM dbo.InnerProcedure_SpyProcedureLog
                   WHERE P1 IS NULL)
    BEGIN
        EXEC tSQLt.Fail 'InnerProcedure call was not logged correctly!';
    END
END;
GO

CREATE PROC tSQLt_test.[test SpyProcedure can have a cursor output parameter]
AS
BEGIN
    EXEC('CREATE PROC dbo.InnerProcedure @P1 CURSOR VARYING OUTPUT AS EXEC tSQLt.Fail ''InnerProcedure was executed;''');

    EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure';
    
    DECLARE @OutputCursor CURSOR;
    EXEC dbo.InnerProcedure @P1 = @OutputCursor OUTPUT; 
    
    IF NOT EXISTS(SELECT 1
                    FROM dbo.InnerProcedure_SpyProcedureLog)
    BEGIN
        EXEC tSQLt.Fail 'InnerProcedure call was not logged correctly!';
    END
END;
GO

CREATE PROC tSQLt_test.[test SpyProcedure raises appropriate error if the procedure does not exist]
AS
BEGIN
    DECLARE @Msg NVARCHAR(MAX); SET @Msg = 'no error';
    
    BEGIN TRY
      EXEC tSQLt.SpyProcedure 'tSQLt_test.DoesNotExist';
    END TRY
    BEGIN CATCH
        SET @Msg = ERROR_MESSAGE();
    END CATCH

    IF @Msg NOT LIKE '%Cannot use SpyProcedure on %DoesNotExist% because the procedure does not exist%'
    BEGIN
        EXEC tSQLt.Fail 'Expected SpyProcedure to throw a meaningful error, but message was: ', @Msg;
    END
END;
GO

CREATE PROC tSQLt_test.[test SpyProcedure raises appropriate error if the procedure name given references another type of object]
AS
BEGIN
    DECLARE @Msg NVARCHAR(MAX); SET @Msg = 'no error';
    
    BEGIN TRY
      CREATE TABLE tSQLt_test.dummy (i int);
      EXEC tSQLt.SpyProcedure 'tSQLt_test.dummy';
    END TRY
    BEGIN CATCH
        SET @Msg = ERROR_MESSAGE();
    END CATCH

    IF @Msg NOT LIKE '%Cannot use SpyProcedure on %dummy% because the procedure does not exist%'
    BEGIN
        EXEC tSQLt.Fail 'Expected SpyProcedure to throw a meaningful error, but message was: ', @Msg;
    END
END;
GO

CREATE PROC tSQLt_test.test_getFullTypeName_shouldProperlyReturnIntParameters
AS
BEGIN
    DECLARE @Result VARCHAR(MAX);

    SELECT @Result = COALESCE(typeName, '<NULL>')
     FROM tSQLt.GetFullTypeName(TYPE_ID('int'), NULL, NULL, NULL);

    IF ISNULL(@Result,'') <> 'int'
    BEGIN
        EXEC tSQLt.Fail 'getFullTypeName should have returned int, but returned ', @Result, ' instead';
    END
END
GO

CREATE PROC tSQLt_test.test_getFullTypeName_should_properly_return_VARCHAR_with_length_parameters
AS
BEGIN
    DECLARE @Result VARCHAR(MAX);

    SELECT @Result = COALESCE(typeName, '<NULL>')
     FROM tSQLt.GetFullTypeName(TYPE_ID('varchar'), 8, NULL, NULL);

    IF ISNULL(@Result,'') <> 'varchar(8)'
    BEGIN
        EXEC tSQLt.Fail 'getFullTypeName should have returned varchar(8), but returned ', @Result, ' instead';
    END
END
GO

CREATE PROC tSQLt_test.test_getFullTypeName_should_properly_return_NVARCHAR_with_length_parameters
AS
BEGIN
    DECLARE @Result VARCHAR(MAX);

    SELECT @Result = COALESCE(typeName, '<NULL>')
     FROM tSQLt.GetFullTypeName(TYPE_ID('nvarchar'), 8, NULL, NULL);

    IF ISNULL(@Result,'') <> 'nvarchar(4)'
    BEGIN
        EXEC tSQLt.Fail 'getFullTypeName should have returned nvarchar(4), but returned ', @Result, ' instead';
    END
END
GO

CREATE PROC tSQLt_test.test_getFullTypeName_should_properly_return_VARCHAR_MAX_parameters
AS
BEGIN
    DECLARE @Result VARCHAR(MAX);

    SELECT @Result = COALESCE(typeName, '<NULL>')
     FROM tSQLt.GetFullTypeName(TYPE_ID('varchar'), -1, NULL, NULL);

    IF ISNULL(@Result,'') <> 'varchar(MAX)'
    BEGIN
        EXEC tSQLt.Fail 'getFullTypeName should have returned varchar(MAX), but returned ', @Result, ' instead';
    END
END
GO

CREATE PROC tSQLt_test.test_getFullTypeName_should_properly_return_VARBINARY_MAX_parameters
AS
BEGIN
    DECLARE @Result VARCHAR(MAX);

    SELECT @Result = COALESCE(typeName, '<NULL>')
     FROM tSQLt.GetFullTypeName(TYPE_ID('varbinary'), -1, NULL, NULL);

    IF ISNULL(@Result,'') <> 'varbinary(MAX)'
    BEGIN
        EXEC tSQLt.Fail 'getFullTypeName should have returned varbinary(MAX), but returned ', @Result, ' instead';
    END
END
GO

CREATE PROC tSQLt_test.test_getFullTypeName_should_properly_return_DECIMAL_parameters
AS
BEGIN
    DECLARE @Result VARCHAR(MAX);

    SELECT @Result = COALESCE(typeName, '<NULL>')
     FROM tSQLt.GetFullTypeName(TYPE_ID('decimal'), NULL, 12,13);

    IF ISNULL(@Result,'') <> 'decimal(12,13)'
    BEGIN
        EXEC tSQLt.Fail 'getFullTypeName should have returned decimal(12,13), but returned ', @Result, ' instead';
    END
END
GO

CREATE PROC tSQLt_test.test_getFullTypeName_should_properly_return_typeName_when_all_parameters_are_valued
AS
BEGIN
    DECLARE @Result VARCHAR(MAX);

    SELECT @Result = COALESCE(typeName, '<NULL>')
     FROM tSQLt.GetFullTypeName(TYPE_ID('int'), 1, 1,1);

    IF ISNULL(@Result,'') <> 'int'
    BEGIN
        EXEC tSQLt.Fail 'getFullTypeName should have returned int, but returned ', @Result, ' instead';
    END
END;
GO

CREATE PROC tSQLt_test.test_getFullTypeName_should_properly_return_typename_when_xml
AS
BEGIN
    DECLARE @Result VARCHAR(MAX);

    SELECT @Result = COALESCE(typeName, '<NULL>')
     FROM tSQLt.GetFullTypeName(TYPE_ID('xml'), -1, 0, 0);

    IF ISNULL(@Result,'') <> 'xml'
    BEGIN
        EXEC tSQLt.Fail 'getFullTypeName should have returned xml, but returned ', @Result, ' instead';
    END
END;
GO

CREATE PROC tSQLt_test.[test AssertEquals should do nothing with two equal ints]
AS
BEGIN
    EXEC tSQLt.AssertEquals 1, 1;
END;
GO

CREATE PROC tSQLt_test.[test AssertEquals should do nothing with two NULLs]
AS
BEGIN
    EXEC tSQLt.AssertEquals NULL, NULL;
END;
GO

CREATE PROC tSQLt_test.[test AssertEquals should call fail with nonequal ints]
AS
BEGIN
    EXEC tSQLt_testutil.assertFailCalled 'EXEC tSQLt.AssertEquals 1, 2;', 'AssertEquals did not call Fail';
END;
GO

CREATE PROC tSQLt_test.[test AssertEquals should call fail with expected int and actual NULL]
AS
BEGIN
    EXEC tSQLt_testutil.assertFailCalled 'EXEC tSQLt.AssertEquals 1, NULL;', 'AssertEquals did not call Fail';
END;
GO

CREATE PROC tSQLt_test.[test AssertEquals should call fail with expected NULL and actual int]
AS
BEGIN
    EXEC tSQLt_testutil.assertFailCalled 'EXEC tSQLt.AssertEquals NULL, 1;', 'AssertEquals did not call Fail';
END;
GO

CREATE PROC tSQLt_test.[test AssertEquals passes with various datatypes with the same value]
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

CREATE PROC tSQLt_test.[test AssertEquals fails with various datatypes of different values]
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

CREATE PROC tSQLt_test.[test AssertEquals with VARCHAR(MAX) throws error]
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

CREATE PROC tSQLt_test.[test getNewTranName should generate a name]
AS
BEGIN
   DECLARE @Value CHAR(32)

   EXEC tSQLt.GetNewTranName @Value OUT;

   IF @Value IS NULL OR @Value = ''
   BEGIN
      EXEC tSQLt.Fail 'getNewTranName should have returned a name';
   END
END;
GO

CREATE PROC tSQLt_test.[test AssertEqualsString should do nothing with two equal VARCHAR Max Values]
AS
BEGIN
    DECLARE @TestString VARCHAR(Max);
    SET @TestString = REPLICATE(CAST('TestString' AS VARCHAR(MAX)),1000);
    EXEC tSQLt.AssertEqualsString @TestString, @TestString;
END
GO

CREATE PROC tSQLt_test.[test AssertEqualsString should do nothing with two NULLs]
AS
BEGIN
    EXEC tSQLt.AssertEqualsString NULL, NULL;
END
GO

CREATE PROC tSQLt_test.[test AssertEqualsString should call fail with nonequal VARCHAR MAX]
AS
BEGIN
    DECLARE @TestString1 VARCHAR(MAX);
    SET @TestString1 = REPLICATE(CAST('TestString' AS VARCHAR(MAX)),1000)+'1';
    DECLARE @TestString2 VARCHAR(MAX);
    SET @TestString2 = REPLICATE(CAST('TestString' AS VARCHAR(MAX)),1000)+'2';

    DECLARE @Command VARCHAR(MAX); SET @Command = 'EXEC tSQLt.AssertEqualsString ''' + @TestString1 + ''', ''' + @TestString2 + ''';';
    EXEC tSQLt_testutil.assertFailCalled @Command, 'AssertEqualsString did not call Fail';
END;
GO

CREATE PROC tSQLt_test.[test AssertEqualsString should call fail with expected value and actual NULL]
AS
BEGIN
    DECLARE @Command VARCHAR(MAX); SET @Command = 'EXEC tSQLt.AssertEqualsString ''1'', NULL;';
    EXEC tSQLt_testutil.assertFailCalled @Command, 'AssertEqualsString did not call Fail';
END;
GO

CREATE PROC tSQLt_test.[test AssertEqualsString should call fail with expected NULL and actual value]
AS
BEGIN
    DECLARE @Command VARCHAR(MAX); SET @Command = 'EXEC tSQLt.AssertEqualsString NULL, ''1'';';
    EXEC tSQLt_testutil.assertFailCalled @Command, 'AssertEqualsString did not call Fail';
END;
GO

CREATE PROC tSQLt_test.[test AssertEqualsString with expected NVARCHAR(MAX) and actual VARCHAR(MAX) of same value]
AS
BEGIN
    DECLARE @Expected NVARCHAR(MAX); SET @Expected = N'hello';
    DECLARE @Actual VARCHAR(MAX); SET @Actual = 'hello';
    EXEC tSQLt.AssertEqualsString @Expected, @Actual;
END;
GO

CREATE PROC tSQLt_test.test_that_tests_in_testclasses_get_executed
AS
BEGIN
    EXEC('EXEC tSQLt.DropClass innertest;');
    EXEC('CREATE SCHEMA innertest;');
    EXEC('CREATE PROC innertest.testMe as RETURN 0;');

    EXEC tSQLt.RunTestClass 'innertest';

    IF NOT EXISTS(SELECT 1 FROM tSQLt.TestResult WHERE Class = 'innertest' and TestCase = 'testMe')
    BEGIN
       EXEC tSQLt.Fail 'innertest.testMe did not get executed.';
    END;
END;
GO

CREATE PROC tSQLt_test.test_that_nontests_in_testclasses_do_not_get_executed
AS
BEGIN
    EXEC('EXEC tSQLt.DropClass innertest;');
    EXEC('CREATE SCHEMA innertest;');
    EXEC('CREATE PROC innertest.do_not_test_me as RETURN 0;');

    EXEC tSQLt.RunTestClass 'innertest';

    IF EXISTS(SELECT 1 FROM tSQLt.TestResult WHERE TestCase = 'do_not_test_me')
    BEGIN
       EXEC tSQLt.Fail 'innertest.do_not_test_me did get executed.';
    END;
END;
GO

CREATE PROC tSQLt_test.test_that_a_failing_SetUp_causes_test_to_be_marked_as_failed
AS
BEGIN
    EXEC('EXEC tSQLt.DropClass innertest;');
    EXEC('CREATE SCHEMA innertest;');
    EXEC('CREATE PROC innertest.SetUp AS EXEC tSQLt.Fail ''expected failure'';');
    EXEC('CREATE PROC innertest.test AS RETURN 0;');
    
    BEGIN TRY
        EXEC tSQLt.RunTestClass 'innertest';
    END TRY
    BEGIN CATCH
    END CATCH

    IF NOT EXISTS(SELECT 1 FROM tSQLt.TestResult WHERE Class = 'innertest' and TestCase = 'test' AND Result = 'Failure')
    BEGIN
       EXEC tSQLt.Fail 'failing innertest.SetUp did not cause innertest.test to fail.';
   END;
END;
GO


CREATE PROC tSQLt_test.test_Run_handles_uncommitable_transaction
AS
BEGIN
    DECLARE @TranName sysname; 
    SELECT TOP(1) @TranName = TranName FROM tSQLt.TestResult WHERE Class = 'tSQLt_test' AND TestCase = 'test_Run_handles_uncommitable_transaction' ORDER BY Id DESC;
    EXEC ('CREATE PROC testUncommitable AS BEGIN CREATE TABLE t1 (i int); CREATE TABLE t1 (i int); END;');
    BEGIN TRY
        EXEC tSQLt.Run 'testUncommitable';
    END TRY
    BEGIN CATCH
      IF NOT EXISTS(SELECT 1
                      FROM tSQLt.TestResult
                     WHERE TestCase = 'testUncommitable'
                       AND Result = 'Error'
                       AND Msg LIKE '%There is already an object named ''t1'' in the database.{testUncommitable,1}%'
                       AND Msg LIKE '%The current transaction cannot be committed and cannot be rolled back to a savepoint.%'
                   )
      BEGIN
        EXEC tSQLt.Fail 'tSQLt.Run ''testUncommitable'' did not error correctly';
      END;
      IF(@@TRANCOUNT > 0)
      BEGIN
        EXEC tSQLt.Fail 'tSQLt.Run ''testUncommitable'' did not rollback the transactions';
      END
      DELETE FROM tSQLt.TestResult
             WHERE TestCase = 'testUncommitable'
               AND Result = 'Error'
               AND Msg LIKE '%There is already an object named ''t1'' in the database.{testUncommitable,1}%'
               AND Msg LIKE '%The current transaction cannot be committed and cannot be rolled back to a savepoint.%'
      BEGIN TRAN
      SAVE TRAN @TranName
    END CATCH
END;
GO

CREATE PROCEDURE tSQLt_test.[test Private_ResolveFakeTableNamesForBackwardCompatibility returns quoted schema when schema and table provided]
AS
BEGIN
  DECLARE @CleanSchemaName NVARCHAR(MAX);
          
  EXEC ('CREATE SCHEMA MySchema');
  EXEC ('CREATE TABLE MySchema.MyTable (i INT)');
          
  SELECT @CleanSchemaName = CleanSchemaName
    FROM tSQLt.Private_ResolveFakeTableNamesForBackwardCompatibility('MyTable', 'MySchema');
    
  EXEC tSQLt.AssertEqualsString '[MySchema]', @CleanSchemaName;
END;
GO

CREATE PROCEDURE tSQLt_test.[test Private_ResolveFakeTableNamesForBackwardCompatibility can handle quoted names]
AS
BEGIN
  DECLARE @CleanSchemaName NVARCHAR(MAX);
          
  EXEC ('CREATE SCHEMA MySchema');
  EXEC ('CREATE TABLE MySchema.MyTable (i INT)');
          
  SELECT CleanSchemaName, CleanTableName
    INTO #actual
    FROM tSQLt.Private_ResolveFakeTableNamesForBackwardCompatibility('[MyTable]', '[MySchema]');
    
  SELECT TOP(0)* INTO #expected FROM #actual;
  
  INSERT INTO #expected(CleanSchemaName, CleanTableName) VALUES('[MySchema]','[MyTable]');

  EXEC tSQLt.AssertEqualsTable '#expected','#actual';
END;
GO

CREATE PROCEDURE tSQLt_test.[test Private_ResolveFakeTableNamesForBackwardCompatibility returns quoted table when schema and table provided]
AS
BEGIN
  DECLARE @CleanTableName NVARCHAR(MAX);
          
  EXEC ('CREATE SCHEMA MySchema');
  EXEC ('CREATE TABLE MySchema.MyTable (i INT)');
          
  SELECT @CleanTableName = CleanTableName
    FROM tSQLt.Private_ResolveFakeTableNamesForBackwardCompatibility('MyTable', 'MySchema');
    
  EXEC tSQLt.AssertEqualsString '[MyTable]', @CleanTableName;
END;
GO

CREATE PROCEDURE tSQLt_test.[test Private_ResolveFakeTableNamesForBackwardCompatibility returns NULL schema name when table does not exist]
AS
BEGIN
  DECLARE @CleanSchemaName NVARCHAR(MAX);
          
  EXEC ('CREATE SCHEMA MySchema');
          
  SELECT @CleanSchemaName = CleanSchemaName
    FROM tSQLt.Private_ResolveFakeTableNamesForBackwardCompatibility('MyTable', 'MySchema');
    
  EXEC tSQLt.AssertEqualsString NULL, @CleanSchemaName;
END;
GO

CREATE PROCEDURE tSQLt_test.[test Private_ResolveFakeTableNamesForBackwardCompatibility returns NULL table name when table does not exist]
AS
BEGIN
  DECLARE @CleanTableName NVARCHAR(MAX);
          
  EXEC ('CREATE SCHEMA MySchema');
          
  SELECT @CleanTableName = CleanTableName
    FROM tSQLt.Private_ResolveFakeTableNamesForBackwardCompatibility('MyTable', 'MySchema');
    
  EXEC tSQLt.AssertEqualsString NULL, @CleanTableName;
END;
GO

CREATE PROCEDURE tSQLt_test.[test Private_ResolveFakeTableNamesForBackwardCompatibility returns NULLs when table name has special char]
AS
BEGIN
  EXEC ('CREATE SCHEMA MySchema');
  EXEC ('CREATE TABLE MySchema.[.MyTable] (i INT)');
          
  SELECT CleanSchemaName, CleanTableName
    INTO #actual
    FROM tSQLt.Private_ResolveFakeTableNamesForBackwardCompatibility('.MyTable', 'MySchema');
  
  SELECT TOP(0) * INTO #expected FROM #actual;
  
  INSERT INTO #expected (CleanSchemaName, CleanTableName) VALUES (NULL, NULL);
  
  EXEC tSQLt.AssertEqualsTable '#expected', '#actual';
END;
GO

CREATE PROCEDURE tSQLt_test.[test Private_ResolveFakeTableNamesForBackwardCompatibility accepts full name as 1st parm if 2nd parm is null]
AS
BEGIN
  EXEC ('CREATE SCHEMA MySchema');
  EXEC ('CREATE TABLE MySchema.MyTable (i INT)');
          
  SELECT CleanSchemaName, CleanTableName
    INTO #actual
    FROM tSQLt.Private_ResolveFakeTableNamesForBackwardCompatibility('MySchema.MyTable',NULL);
  
  SELECT TOP(0) * INTO #expected FROM #actual;
  
  INSERT INTO #expected (CleanSchemaName, CleanTableName) VALUES ('[MySchema]', '[MyTable]');
  
  EXEC tSQLt.AssertEqualsTable '#expected', '#actual';
END;
GO

CREATE PROCEDURE tSQLt_test.[test Private_ResolveFakeTableNamesForBackwardCompatibility accepts parms in wrong order]
AS
BEGIN
  EXEC ('CREATE SCHEMA MySchema');
  EXEC ('CREATE TABLE MySchema.MyTable (i INT)');
          
  SELECT CleanSchemaName, CleanTableName
    INTO #actual
    FROM tSQLt.Private_ResolveFakeTableNamesForBackwardCompatibility('MySchema','MyTable');
  
  SELECT TOP(0) * INTO #expected FROM #actual;
  
  INSERT INTO #expected (CleanSchemaName, CleanTableName) VALUES ('[MySchema]', '[MyTable]');
  
  EXEC tSQLt.AssertEqualsTable '#expected', '#actual';
END;
GO

CREATE PROCEDURE tSQLt_test.AssertTableIsNewObjectThatHasNoConstraints
@TableName NVARCHAR(MAX)
AS
BEGIN
  DECLARE @OldTableObjectId INT;

  IF OBJECT_ID(@TableName) IS NULL
    EXEC tSQLt.Fail 'Table ',@TableName,' does not exist!';

  SELECT @OldTableObjectId = OBJECT_ID(QUOTENAME(OBJECT_SCHEMA_NAME(major_id))+'.'+QUOTENAME(CAST(value AS NVARCHAR(4000))))
  FROM sys.extended_properties WHERE major_id = OBJECT_ID(@TableName) and name = 'tSQLt.FakeTable_OrgTableName'

  IF @OldTableObjectId IS NULL
    EXEC tSQLt.Fail 'Table ',@TableName,' is not a fake table!';
  
  IF OBJECT_ID(@TableName) = @OldTableObjectId
    EXEC tSQLt.Fail 'Table ',@TableName,' is not a new object!';
    
  SELECT QUOTENAME(OBJECT_SCHEMA_NAME(object_id))+'.'+QUOTENAME(OBJECT_NAME(object_id)) ReferencingObjectName 
  INTO #actual FROM sys.objects WHERE parent_object_id = OBJECT_ID(@TableName);
  
  SELECT TOP(0) * INTO #expected FROM #actual;
  
  EXEC tSQLt.AssertEqualsTable '#expected','#actual','Unexpected referencing objects found!';
END
GO

CREATE PROC tSQLt_test.[test FakeTable works with 2 part names in first parameter]
AS
BEGIN
  CREATE TABLE tSQLt_test.TempTable1(i INT);
  
  EXEC tSQLt.FakeTable 'tSQLt_test.TempTable1';
  
  EXEC tSQLt_test.AssertTableIsNewObjectThatHasNoConstraints 'tSQLt_test.TempTable1';
END;
GO

CREATE PROC tSQLt_test.[test FakeTable takes 2 nameless parameters containing schema and table name]
AS
BEGIN
  CREATE TABLE tSQLt_test.TempTable1(i INT);
  
  EXEC tSQLt.FakeTable 'tSQLt_test','TempTable1';
  
  EXEC tSQLt_test.AssertTableIsNewObjectThatHasNoConstraints 'tSQLt_test.TempTable1';
END;
GO

CREATE PROC tSQLt_test.[test FakeTable raises appropriate error if table does not exist]
AS
BEGIN
    DECLARE @ErrorThrown BIT; SET @ErrorThrown = 0;

    EXEC ('CREATE SCHEMA schemaA');
    CREATE TABLE schemaA.tableA (constCol CHAR(3) );

    BEGIN TRY
      EXEC tSQLt.FakeTable 'schemaA', 'tableXYZ';
    END TRY
    BEGIN CATCH
      DECLARE @ErrorMessage NVARCHAR(MAX);
      SELECT @ErrorMessage = ERROR_MESSAGE()+'{'+ISNULL(ERROR_PROCEDURE(),'NULL')+','+ISNULL(CAST(ERROR_LINE() AS VARCHAR),'NULL')+'}';
      IF @ErrorMessage NOT LIKE '%FakeTable could not resolve the object name, ''schemaA.tableXYZ''. Be sure to call FakeTable and pass in a single parameter, such as: EXEC tSQLt.FakeTable ''MySchema.MyTable''%'
      BEGIN
          EXEC tSQLt.Fail 'tSQLt.FakeTable threw unexpected exception: ',@ErrorMessage;     
      END
      SET @ErrorThrown = 1;
    END CATCH;
    
    EXEC tSQLt.AssertEquals 1, @ErrorThrown,'tSQLt.FakeTable did not throw an error when the table does not exist.';
END;
GO

CREATE PROC tSQLt_test.[test FakeTable raises appropriate error if schema does not exist]
AS
BEGIN
    DECLARE @ErrorThrown BIT; SET @ErrorThrown = 0;

    BEGIN TRY
      EXEC tSQLt.FakeTable 'schemaB', 'tableXYZ';
    END TRY
    BEGIN CATCH
      DECLARE @ErrorMessage NVARCHAR(MAX);
      SELECT @ErrorMessage = ERROR_MESSAGE()+'{'+ISNULL(ERROR_PROCEDURE(),'NULL')+','+ISNULL(CAST(ERROR_LINE() AS VARCHAR),'NULL')+'}';
      IF @ErrorMessage NOT LIKE '%FakeTable could not resolve the object name, ''schemaB.tableXYZ''. Be sure to call FakeTable and pass in a single parameter, such as: EXEC tSQLt.FakeTable ''MySchema.MyTable''%'
      BEGIN
          EXEC tSQLt.Fail 'tSQLt.FakeTable threw unexpected exception: ',@ErrorMessage;     
      END
      SET @ErrorThrown = 1;
    END CATCH;
    
    EXEC tSQLt.AssertEquals 1, @ErrorThrown,'tSQLt.FakeTable did not throw an error when the table does not exist.';
END;
GO

CREATE PROC tSQLt_test.[test FakeTable raises appropriate error if called with NULL parameters]
AS
BEGIN
    DECLARE @ErrorThrown BIT; SET @ErrorThrown = 0;

    BEGIN TRY
      EXEC tSQLt.FakeTable NULL;
    END TRY
    BEGIN CATCH
      DECLARE @ErrorMessage NVARCHAR(MAX);
      SELECT @ErrorMessage = ERROR_MESSAGE()+'{'+ISNULL(ERROR_PROCEDURE(),'NULL')+','+ISNULL(CAST(ERROR_LINE() AS VARCHAR),'NULL')+'}';
      IF @ErrorMessage NOT LIKE '%FakeTable could not resolve the object name, ''(null)''. Be sure to call FakeTable and pass in a single parameter, such as: EXEC tSQLt.FakeTable ''MySchema.MyTable''%'
      BEGIN
          EXEC tSQLt.Fail 'tSQLt.FakeTable threw unexpected exception: ',@ErrorMessage;     
      END
      SET @ErrorThrown = 1;
    END CATCH;
    
    EXEC tSQLt.AssertEquals 1, @ErrorThrown,'tSQLt.FakeTable did not throw an error when the table does not exist.';
END;
GO

CREATE PROC tSQLt_test.[test FakeTable raises appropriate error if it was called with a single parameter]
AS
BEGIN
    DECLARE @ErrorThrown BIT; SET @ErrorThrown = 0;

    BEGIN TRY
      EXEC tSQLt.FakeTable 'schemaB.tableXYZ';
    END TRY
    BEGIN CATCH
      DECLARE @ErrorMessage NVARCHAR(MAX);
      SELECT @ErrorMessage = ERROR_MESSAGE()+'{'+ISNULL(ERROR_PROCEDURE(),'NULL')+','+ISNULL(CAST(ERROR_LINE() AS VARCHAR),'NULL')+'}';
      IF @ErrorMessage NOT LIKE '%FakeTable could not resolve the object name, ''schemaB.tableXYZ''. Be sure to call FakeTable and pass in a single parameter, such as: EXEC tSQLt.FakeTable ''MySchema.MyTable''%'
      BEGIN
          EXEC tSQLt.Fail 'tSQLt.FakeTable threw unexpected exception: ',@ErrorMessage;     
      END
      SET @ErrorThrown = 1;
    END CATCH;
    
    EXEC tSQLt.AssertEquals 1, @ErrorThrown,'tSQLt.FakeTable did not throw an error when the table does not exist.';
END;
GO

CREATE PROC tSQLt_test.[test a faked table has no primary key]
AS
BEGIN
  CREATE TABLE tSQLt_test.TempTable1(i INT PRIMARY KEY);
  
  EXEC tSQLt.FakeTable 'tSQLt_test','TempTable1';
  
  EXEC tSQLt_test.AssertTableIsNewObjectThatHasNoConstraints 'tSQLt_test.TempTable1';
  
  INSERT INTO tSQLt_test.TempTable1 (i) VALUES (1);
  INSERT INTO tSQLt_test.TempTable1 (i) VALUES (1);
END;
GO

CREATE PROC tSQLt_test.[test a faked table has no check constraints]
AS
BEGIN
  CREATE TABLE tSQLt_test.TempTable1(i INT CHECK(i > 5));
  
  EXEC tSQLt.FakeTable 'tSQLt_test','TempTable1';
  
  EXEC tSQLt_test.AssertTableIsNewObjectThatHasNoConstraints 'tSQLt_test.TempTable1';
  INSERT INTO tSQLt_test.TempTable1 (i) VALUES (5);
END;
GO

CREATE PROC tSQLt_test.[test a faked table has no foreign keys]
AS
BEGIN
  CREATE TABLE tSQLt_test.TempTable0(i INT PRIMARY KEY);
  CREATE TABLE tSQLt_test.TempTable1(i INT REFERENCES tSQLt_test.TempTable0(i));
  
  EXEC tSQLt.FakeTable 'tSQLt_test','TempTable1';
  
  EXEC tSQLt_test.AssertTableIsNewObjectThatHasNoConstraints 'tSQLt_test.TempTable1';
  INSERT INTO tSQLt_test.TempTable1 (i) VALUES (5);
END;
GO

CREATE PROC tSQLt_test.[test FakeTable: a faked table has any defaults removed]
AS
BEGIN
  CREATE TABLE tSQLt_test.TempTable1(i INT DEFAULT(77));
  
  EXEC tSQLt.FakeTable 'tSQLt_test','TempTable1';
  
  EXEC tSQLt_test.AssertTableIsNewObjectThatHasNoConstraints 'tSQLt_test.TempTable1';
  INSERT INTO tSQLt_test.TempTable1 (i) DEFAULT VALUES;
  
  DECLARE @value INT;
  SELECT @value = i
    FROM tSQLt_test.TempTable1;
    
  EXEC tSQLt.AssertEquals NULL, @value;
END;
GO

CREATE PROC tSQLt_test.[test FakeTable: a faked table has any unique constraints removed]
AS
BEGIN
  CREATE TABLE tSQLt_test.TempTable1(i INT UNIQUE);
  
  EXEC tSQLt.FakeTable 'tSQLt_test','TempTable1';
  
  EXEC tSQLt_test.AssertTableIsNewObjectThatHasNoConstraints 'tSQLt_test.TempTable1';
  INSERT INTO tSQLt_test.TempTable1 (i) VALUES (1);
  INSERT INTO tSQLt_test.TempTable1 (i) VALUES (1);
END;
GO

CREATE PROC tSQLt_test.[test FakeTable: a faked table has any unique indexes removed]
AS
BEGIN
  CREATE TABLE tSQLt_test.TempTable1(i INT);
  CREATE UNIQUE INDEX UQ_tSQLt_test_TempTable1_i ON tSQLt_test.TempTable1(i);
  
  EXEC tSQLt.FakeTable 'tSQLt_test','TempTable1';
  
  EXEC tSQLt_test.AssertTableIsNewObjectThatHasNoConstraints 'tSQLt_test.TempTable1';
  INSERT INTO tSQLt_test.TempTable1 (i) VALUES (1);
  INSERT INTO tSQLt_test.TempTable1 (i) VALUES (1);
END;
GO

CREATE PROC tSQLt_test.[test FakeTable: a faked table has any not null constraints removed]
AS
BEGIN
  CREATE TABLE tSQLt_test.TempTable1(i INT NOT NULL);
  
  EXEC tSQLt.FakeTable 'tSQLt_test','TempTable1';
  
  EXEC tSQLt_test.AssertTableIsNewObjectThatHasNoConstraints 'tSQLt_test.TempTable1';
  INSERT INTO tSQLt_test.TempTable1 (i) VALUES (NULL);
END;
GO

CREATE PROC tSQLt_test.[test FakeTable works on referencedTo tables]
AS
BEGIN
  IF OBJECT_ID('tSQLt_test.tst1') IS NOT NULL DROP TABLE tst1;
  IF OBJECT_ID('tSQLt_test.tst2') IS NOT NULL DROP TABLE tst2;

  CREATE TABLE tSQLt_test.tst1(i INT PRIMARY KEY);
  CREATE TABLE tSQLt_test.tst2(i INT PRIMARY KEY, tst1i INT REFERENCES tSQLt_test.tst1(i));
  
  BEGIN TRY
    EXEC tSQLt.FakeTable 'tSQLt_test', 'tst1';
  END TRY
  BEGIN CATCH
    DECLARE @ErrorMessage NVARCHAR(MAX);
    SELECT @ErrorMessage = ERROR_MESSAGE()+'{'+ISNULL(ERROR_PROCEDURE(),'NULL')+','+ISNULL(CAST(ERROR_LINE() AS VARCHAR),'NULL')+'}';

    EXEC tSQLt.Fail 'FakeTable threw unexpected error:', @ErrorMessage;
  END CATCH;
END;
GO

CREATE PROC tSQLt_test.[test FakeTable removes IDENTITY property from column]
AS
BEGIN
  IF OBJECT_ID('tst1') IS NOT NULL DROP TABLE tst1;

  CREATE TABLE tst1(i INT IDENTITY(1,1));
  
  EXEC tSQLt.FakeTable '', 'tst1';
  
  IF EXISTS(SELECT 1 FROM sys.columns WHERE OBJECT_ID = OBJECT_ID('tst1') AND is_identity = 1)
  BEGIN
    EXEC tSQLt.Fail 'Fake table has identity column!';
  END
END;
GO

CREATE PROC tSQLt_test.[test FakeTable doesn't produce output]
AS
BEGIN
  CREATE TABLE tSQLt_test.tst(i INT);
  
  EXEC tSQLt.CaptureOutput 'EXEC tSQLt.FakeTable ''tSQLt_test'', ''tst''';

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

CREATE PROC tSQLt_test.[test ApplyConstraint copies a check constraint to a fake table]
AS
BEGIN
    DECLARE @ActualDefinition VARCHAR(MAX);

    EXEC('CREATE SCHEMA schemaA;');
    CREATE TABLE schemaA.tableA (constCol CHAR(3) CONSTRAINT testConstraint CHECK (constCol = 'XYZ'));

    EXEC tSQLt.FakeTable 'schemaA.tableA';
    EXEC tSQLt.ApplyConstraint 'schemaA.tableA', 'testConstraint';

    SELECT @ActualDefinition = definition
      FROM sys.check_constraints
     WHERE parent_object_id = OBJECT_ID('schemaA.tableA') AND name = 'testConstraint';

    IF @@ROWCOUNT = 0
    BEGIN
        EXEC tSQLt.Fail 'Constraint, "testConstraint", was not copied to schemaA.tableA';
    END;

    EXEC tSQLt.AssertEqualsString '([constCol]=''XYZ'')', @ActualDefinition;

END;
GO

CREATE PROC tSQLt_test.[test ApplyConstraint can be called with 3 parameters]
AS
BEGIN
    DECLARE @ActualDefinition VARCHAR(MAX);

    EXEC('CREATE SCHEMA schemaA;');
    CREATE TABLE schemaA.tableA (constCol CHAR(3) CONSTRAINT testConstraint CHECK (constCol = 'XYZ'));

    EXEC tSQLt.FakeTable 'schemaA.tableA';
    EXEC tSQLt.ApplyConstraint 'schemaA', 'tableA', 'testConstraint';

    SELECT @ActualDefinition = definition
      FROM sys.check_constraints
     WHERE parent_object_id = OBJECT_ID('schemaA.tableA') AND name = 'testConstraint';

    IF @@ROWCOUNT = 0
    BEGIN
        EXEC tSQLt.Fail 'Constraint, "testConstraint", was not copied to schemaA.tableA';
    END;

    EXEC tSQLt.AssertEqualsString '([constCol]=''XYZ'')', @ActualDefinition;

END;
GO

CREATE PROC tSQLt_test.[test ApplyConstraint copies a check constraint to a fake table with schema]
AS
BEGIN
    DECLARE @ActualDefinition VARCHAR(MAX);

    EXEC ('CREATE SCHEMA schemaA');
    CREATE TABLE schemaA.tableA (constCol CHAR(3) CONSTRAINT testConstraint CHECK (constCol = 'XYZ'));

    EXEC tSQLt.FakeTable 'schemaA.tableA';
    EXEC tSQLt.ApplyConstraint 'schemaA.tableA', 'testConstraint';

    SELECT @ActualDefinition = definition
      FROM sys.check_constraints
     WHERE parent_object_id = OBJECT_ID('schemaA.tableA') AND name = 'testConstraint';

    IF @@ROWCOUNT = 0
    BEGIN
        EXEC tSQLt.Fail 'Constraint, "testConstraint", was not copied to tableA';
    END;

    EXEC tSQLt.AssertEqualsString '([constCol]=''XYZ'')', @ActualDefinition;

END;
GO


CREATE PROC tSQLt_test.[test ApplyConstraint can be called with 2 parameters]
AS
BEGIN
    DECLARE @ActualDefinition VARCHAR(MAX);

    EXEC ('CREATE SCHEMA schemaA');
    CREATE TABLE schemaA.tableA (constCol CHAR(3) CONSTRAINT testConstraint CHECK (constCol = 'XYZ'));

    EXEC tSQLt.FakeTable 'schemaA.tableA';
    EXEC tSQLt.ApplyConstraint 'schemaA.tableA', 'testConstraint';

    SELECT @ActualDefinition = definition
      FROM sys.check_constraints
     WHERE parent_object_id = OBJECT_ID('schemaA.tableA') AND name = 'testConstraint';

    IF @@ROWCOUNT = 0
    BEGIN
        EXEC tSQLt.Fail 'Constraint, "testConstraint", was not copied to tableA';
    END;

    EXEC tSQLt.AssertEqualsString '([constCol]=''XYZ'')', @ActualDefinition;

END;
GO


CREATE PROC tSQLt_test.[test ApplyConstraint copies a check constraint even if same table/constraint names exist on another schema]
AS
BEGIN
    DECLARE @ActualDefinition VARCHAR(MAX);

    EXEC ('CREATE SCHEMA schemaB');
    EXEC ('CREATE SCHEMA schemaA');
    CREATE TABLE schemaB.testTable (constCol CHAR(3) CONSTRAINT testConstraint CHECK (constCol = 'XYZ'));
    CREATE TABLE schemaA.testTable (constCol CHAR(3) CONSTRAINT testConstraint CHECK (constCol = 'XYZ'));

    EXEC tSQLt.FakeTable 'schemaB.testTable';
    EXEC tSQLt.FakeTable 'schemaA.testTable';
    EXEC tSQLt.ApplyConstraint 'schemaB.testTable', 'testConstraint';

    SELECT @ActualDefinition = definition
      FROM sys.check_constraints
     WHERE parent_object_id = OBJECT_ID('schemaB.testTable') AND name = 'testConstraint';

    IF @@ROWCOUNT = 0
    BEGIN
        EXEC tSQLt.Fail 'Constraint, "testConstraint", was not copied to schemaB.testTable';
    END;

    EXEC tSQLt.AssertEqualsString '([constCol]=''XYZ'')', @ActualDefinition;

END;
GO

CREATE PROC tSQLt_test.[test ApplyConstraint copies a check constraint even if same table/constraint names exist on multiple other schemata]
AS
BEGIN
  DECLARE @ActualDefinition VARCHAR(MAX);

  DECLARE @cmd NVARCHAR(MAX);

  SELECT @cmd = (
  SELECT REPLACE(
          'EXEC (''CREATE SCHEMA schema?'');CREATE TABLE schema?.testTable (constCol INT CONSTRAINT testConstraint CHECK (constCol = 42));EXEC tSQLt.FakeTable ''schema?.testTable'';',
          '?',
          CAST(no AS NVARCHAR(MAX))
         )
    FROM tSQLt.F_Num(10)
    FOR XML PATH(''),TYPE).value('.','NVARCHAR(MAX)');

  EXEC(@cmd);

  EXEC tSQLt.ApplyConstraint 'schema4.testTable', 'testConstraint';

  SELECT @ActualDefinition = definition
    FROM sys.check_constraints
   WHERE parent_object_id = OBJECT_ID('schema4.testTable') AND name = 'testConstraint';

  IF @@ROWCOUNT = 0
  BEGIN
      EXEC tSQLt.Fail 'Constraint, "testConstraint", was not copied to schema42.testTable';
  END;

  EXEC tSQLt.AssertEqualsString '([constCol]=(42))', @ActualDefinition;

END;
GO

CREATE PROC tSQLt_test.[test ApplyConstraint throws error if called with invalid constraint]
AS
BEGIN
    DECLARE @ErrorThrown BIT; SET @ErrorThrown = 0;

    EXEC ('CREATE SCHEMA schemaA');
    CREATE TABLE schemaA.tableA (constCol CHAR(3) );
    CREATE TABLE schemaA.thisIsNotAConstraint (constCol CHAR(3) );

    EXEC tSQLt.FakeTable 'schemaA.tableA';
    
    BEGIN TRY
      EXEC tSQLt.ApplyConstraint 'schemaA.tableA', 'thisIsNotAConstraint';
    END TRY
    BEGIN CATCH
      DECLARE @ErrorMessage NVARCHAR(MAX);
      SELECT @ErrorMessage = ERROR_MESSAGE()+'{'+ISNULL(ERROR_PROCEDURE(),'NULL')+','+ISNULL(CAST(ERROR_LINE() AS VARCHAR),'NULL')+'}';
      IF @ErrorMessage NOT LIKE '%ApplyConstraint could not resolve the object names, ''schemaA.tableA'', ''thisIsNotAConstraint''. Be sure to call ApplyConstraint and pass in two parameters, such as: EXEC tSQLt.ApplyConstraint ''MySchema.MyTable'', ''MyConstraint''%'
      BEGIN
          EXEC tSQLt.Fail 'tSQLt.ApplyConstraint threw unexpected exception: ',@ErrorMessage;     
      END
      SET @ErrorThrown = 1;
    END CATCH;
    
    EXEC tSQLt.AssertEquals 1,@ErrorThrown,'tSQLt.ApplyConstraint did not throw an error!';

END;
GO

CREATE PROC tSQLt_test.[test ApplyConstraint throws error if called with constraint existsing on different table]
AS
BEGIN
    DECLARE @ErrorThrown BIT; SET @ErrorThrown = 0;

    EXEC ('CREATE SCHEMA schemaA');
    CREATE TABLE schemaA.tableA (constCol CHAR(3) );
    CREATE TABLE schemaA.tableB (constCol CHAR(3) CONSTRAINT MyConstraint CHECK (1=0));

    EXEC tSQLt.FakeTable 'schemaA.tableA';
    
    BEGIN TRY
      EXEC tSQLt.ApplyConstraint 'schemaA.tableA', 'MyConstraint';
    END TRY
    BEGIN CATCH
      DECLARE @ErrorMessage NVARCHAR(MAX);
      SELECT @ErrorMessage = ERROR_MESSAGE()+'{'+ISNULL(ERROR_PROCEDURE(),'NULL')+','+ISNULL(CAST(ERROR_LINE() AS VARCHAR),'NULL')+'}';
      IF @ErrorMessage NOT LIKE '%ApplyConstraint could not resolve the object names%'
      BEGIN
          EXEC tSQLt.Fail 'tSQLt.ApplyConstraint threw unexpected exception: ',@ErrorMessage;     
      END
      SET @ErrorThrown = 1;
    END CATCH;
    
    EXEC tSQLt.AssertEquals 1,@ErrorThrown,'tSQLt.ApplyConstraint did not throw an error!';

END;
GO

CREATE PROC tSQLt_test.[test ApplyConstraint copies a foreign key to a fake table with referenced table not faked]
AS
BEGIN
    DECLARE @ActualDefinition VARCHAR(MAX);
    
    EXEC ('CREATE SCHEMA schemaA;');
    CREATE TABLE schemaA.tableA (id int PRIMARY KEY);
    CREATE TABLE schemaA.tableB (bid int, aid int CONSTRAINT testConstraint REFERENCES schemaA.tableA(id));

    EXEC tSQLt.FakeTable 'schemaA.tableB';

    EXEC tSQLt.ApplyConstraint 'schemaA.tableB', 'testConstraint';

    IF NOT EXISTS(SELECT 1 FROM sys.foreign_keys WHERE name = 'testConstraint' AND parent_object_id = OBJECT_ID('schemaA.tableB'))
    BEGIN
        EXEC tSQLt.Fail 'Constraint, "testConstraint", was not copied to tableB';
    END;
END;
GO

CREATE PROC tSQLt_test.[test ApplyConstraint copies a foreign key to a fake table with schema]
AS
BEGIN
    DECLARE @ActualDefinition VARCHAR(MAX);

    EXEC ('CREATE SCHEMA schemaA');
    CREATE TABLE schemaA.tableA (id int PRIMARY KEY);
    CREATE TABLE schemaA.tableB (bid int, aid int CONSTRAINT testConstraint REFERENCES schemaA.tableA(id));

    EXEC tSQLt.FakeTable 'schemaA.tableB';

    EXEC tSQLt.ApplyConstraint 'schemaA.tableB', 'testConstraint';

    IF NOT EXISTS(SELECT 1 FROM sys.foreign_keys WHERE name = 'testConstraint' AND parent_object_id = OBJECT_ID('schemaA.tableB'))
    BEGIN
        EXEC tSQLt.Fail 'Constraint, "testConstraint", was not copied to tableB';
    END;
END;
GO

CREATE PROC tSQLt_test.[test ApplyConstraint applies a foreign key between two faked tables and insert works]
AS
BEGIN
    DECLARE @ActualDefinition VARCHAR(MAX);

    EXEC ('CREATE SCHEMA schemaA');
    CREATE TABLE schemaA.tableA (aid int PRIMARY KEY);
    CREATE TABLE schemaA.tableB (bid int, aid int CONSTRAINT testConstraint REFERENCES schemaA.tableA(aid));

    EXEC tSQLt.FakeTable 'schemaA.tableA';
    EXEC tSQLt.FakeTable 'schemaA.tableB';

    EXEC tSQLt.ApplyConstraint 'schemaA.tableB', 'testConstraint';
    
    INSERT INTO schemaA.tableA (aid) VALUES (13);
    INSERT INTO schemaA.tableB (aid) VALUES (13);
END;
GO

CREATE PROC tSQLt_test.[test ApplyConstraint applies a foreign key between two faked tables and insert fails]
AS
BEGIN
    DECLARE @ActualDefinition VARCHAR(MAX);

    EXEC ('CREATE SCHEMA schemaA');
    CREATE TABLE schemaA.tableA (aid int PRIMARY KEY);
    CREATE TABLE schemaA.tableB (bid int, aid int CONSTRAINT testConstraint REFERENCES schemaA.tableA(aid));

    EXEC tSQLt.FakeTable 'schemaA.tableA';
    EXEC tSQLt.FakeTable 'schemaA.tableB';

    EXEC tSQLt.ApplyConstraint 'schemaA.tableB', 'testConstraint';
    
    DECLARE @msg NVARCHAR(MAX);
    SET @msg = 'No error message';
    
    BEGIN TRY
      INSERT INTO schemaA.tableB (aid) VALUES (13);
    END TRY
    BEGIN CATCH
      SET @msg = ERROR_MESSAGE();
    END CATCH
    
    IF @msg NOT LIKE '%testConstraint%'
    BEGIN
      EXEC tSQLt.Fail 'Expected Foreign Key to be applied, resulting in an FK error, however the actual error message was: ', @msg;
    END
END;
GO


CREATE PROC tSQLt_test.[test ApplyConstraint does not create additional unique index on unfaked table]
AS
BEGIN
    DECLARE @ActualDefinition VARCHAR(MAX);

    EXEC ('CREATE SCHEMA schemaA');
    CREATE TABLE schemaA.tableA (aid int PRIMARY KEY);
    CREATE TABLE schemaA.tableB (bid int, aid int CONSTRAINT testConstraint REFERENCES schemaA.tableA(aid));

    EXEC tSQLt.FakeTable 'schemaA.tableB';

    EXEC tSQLt.ApplyConstraint 'schemaA.tableB', 'testConstraint';
    
    DECLARE @NumberOfIndexes INT;
    SELECT @NumberOfIndexes = COUNT(1)
      FROM sys.indexes
     WHERE object_id = OBJECT_ID('schemaA.tableA');
     
    EXEC tSQLt.AssertEquals 1, @NumberOfIndexes;
END;
GO

CREATE PROC tSQLt_test.[test ApplyConstraint can apply two foreign keys]
AS
BEGIN
    DECLARE @ActualDefinition VARCHAR(MAX);

    EXEC ('CREATE SCHEMA schemaA');
    CREATE TABLE schemaA.tableA (aid int PRIMARY KEY);
    CREATE TABLE schemaA.tableB (bid int, 
           aid1 int CONSTRAINT testConstraint1 REFERENCES schemaA.tableA(aid), 
           aid2 int CONSTRAINT testConstraint2 REFERENCES schemaA.tableA(aid));

    EXEC tSQLt.FakeTable 'schemaA.tableA';
    EXEC tSQLt.FakeTable 'schemaA.tableB';

    EXEC tSQLt.ApplyConstraint 'schemaA.tableB', 'testConstraint1';
    EXEC tSQLt.ApplyConstraint 'schemaA.tableB', 'testConstraint2';
END;
GO

CREATE PROC tSQLt_test.[test ApplyConstraint for a foreign key can be called with quoted names]
AS
BEGIN
    DECLARE @ActualDefinition VARCHAR(MAX);

    EXEC ('CREATE SCHEMA [sche maA]');
    CREATE TABLE [sche maA].[tab leA] ([id col] int PRIMARY KEY);
    CREATE TABLE [sche maA].[tab leB] ([bid col] int, [aid col] int CONSTRAINT [test Constraint] REFERENCES [sche maA].[tab leA]([id col]));

    EXEC tSQLt.FakeTable '[sche maA].[tab leA]';
    EXEC tSQLt.FakeTable '[sche maA].[tab leB]';

    EXEC tSQLt.ApplyConstraint '[sche maA].[tab leB]', '[test Constraint]';

    IF NOT EXISTS(SELECT 1 FROM sys.foreign_keys WHERE name = 'test Constraint' AND parent_object_id = OBJECT_ID('[sche maA].[tab leB]'))
    BEGIN
        EXEC tSQLt.Fail 'Constraint, "test Constraint", was not copied to [tab leB]';
    END;
END;
GO

CREATE PROC tSQLt_test.[test ApplyConstraint for a check constraint can be called with quoted names]
AS
BEGIN
    DECLARE @ActualDefinition VARCHAR(MAX);

    EXEC ('CREATE SCHEMA [sche maA]');
    CREATE TABLE [sche maA].[tab leB] ([bid col] int CONSTRAINT [test Constraint] CHECK([bid col] > 5));

    EXEC tSQLt.FakeTable '[sche maA].[tab leB]';

    EXEC tSQLt.ApplyConstraint '[sche maA].[tab leB]', '[test Constraint]';

    IF NOT EXISTS(SELECT 1 FROM sys.check_constraints WHERE name = 'test Constraint' AND parent_object_id = OBJECT_ID('[sche maA].[tab leB]'))
    BEGIN
        EXEC tSQLt.Fail 'Constraint, "test Constraint", was not copied to [tab leB]';
    END;
END;
GO

CREATE PROC tSQLt_test.[test Private_GetOriginalTableInfo handles table existing in several schemata]
AS
BEGIN
  DECLARE @Actual INT;
  DECLARE @Expected INT;

  EXEC ('CREATE SCHEMA schemaA');
  EXEC ('CREATE SCHEMA schemaB');
  EXEC ('CREATE SCHEMA schemaC');
  EXEC ('CREATE SCHEMA schemaD');
  EXEC ('CREATE SCHEMA schemaE');
  CREATE TABLE schemaA.tableA (id INT);
  CREATE TABLE schemaB.tableA (id INT);
  CREATE TABLE schemaC.tableA (id INT);
  CREATE TABLE schemaD.tableA (id INT);
  CREATE TABLE schemaE.tableA (id INT);
  
  SET @Expected = OBJECT_ID('schemaC.tableA');
  
  EXEC tSQLt.FakeTable 'schemaA.tableA';
  EXEC tSQLt.FakeTable 'schemaB.tableA';
  EXEC tSQLt.FakeTable 'schemaC.tableA';
  EXEC tSQLt.FakeTable 'schemaD.tableA';
  EXEC tSQLt.FakeTable 'schemaE.tableA';

  SELECT @Actual = OrgTableObjectId 
    FROM tSQLt.Private_GetOriginalTableInfo(OBJECT_ID('schemaC.tableA'));
    
  EXEC tSQLt.AssertEquals @Expected,@Actual;
END;
GO

CREATE PROC tSQLt_test.[test Private_GetOriginalTableInfo handles funky schema name]
AS
BEGIN
  DECLARE @Actual INT;
  DECLARE @Expected INT;

  EXEC ('CREATE SCHEMA [s.c.h.e.m.a.A]');
  CREATE TABLE [s.c.h.e.m.a.A].tableA (id INT);
  
  SET @Expected = OBJECT_ID('[s.c.h.e.m.a.A].tableA');
  
  EXEC tSQLt.FakeTable '[s.c.h.e.m.a.A].tableA';

  SELECT @Actual = OrgTableObjectId 
    FROM tSQLt.Private_GetOriginalTableInfo(OBJECT_ID('[s.c.h.e.m.a.A].tableA'));
    
  EXEC tSQLt.AssertEquals @Expected,@Actual;
END;
GO

CREATE PROC tSQLt_test.[test Private_ResolveApplyConstraintParameters returns no record when constraint does not exist on given schema/table]
AS
BEGIN
  DECLARE @Actual INT;

  EXEC ('CREATE SCHEMA schemaA');
  CREATE TABLE schemaA.tableA (id INT);
  
  EXEC tSQLt.FakeTable 'schemaA.tableA';
  SELECT @Actual = ConstraintObjectId FROM tSQLt.Private_ResolveApplyConstraintParameters('schemaA.tableA', 'constraint_does_not_exist', NULL);
  
  EXEC tSQLt.AssertEquals NULL, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test Private_ResolveApplyConstraintParameters returns no record when constraint exists on different table in same schema]
AS
BEGIN
  DECLARE @Actual INT;

  EXEC ('CREATE SCHEMA schemaA');
  CREATE TABLE schemaA.tableA (id INT);
  CREATE TABLE schemaA.tableB (id INT CONSTRAINT testConstraint CHECK(id > 0));
  
  EXEC tSQLt.FakeTable 'schemaA.tableA';
 
  SELECT ConstraintObjectId 
    INTO #Actual
    FROM tSQLt.Private_ResolveApplyConstraintParameters('schemaA.tableA', 'testConstraint', NULL);
  
  SELECT TOP(0) * INTO #Expected FROM #Actual;
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO


CREATE PROC tSQLt_test.[test Private_ResolveApplyConstraintParameters returns correct id using 2 parameters]
AS
BEGIN
  DECLARE @Actual INT;
  DECLARE @Expected INT;

  EXEC ('CREATE SCHEMA schemaA');
  CREATE TABLE schemaA.tableA (id INT CONSTRAINT testConstraint CHECK(id > 0));
  
  EXEC tSQLt.FakeTable 'schemaA.tableA';
  
  SELECT @Actual = ConstraintObjectId FROM tSQLt.Private_ResolveApplyConstraintParameters('schemaA.tableA', 'testConstraint', NULL);
  
  SELECT @Expected = OBJECT_ID('schemaA.testConstraint');
  EXEC tSQLt.AssertEquals @Expected, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test Private_ResolveApplyConstraintParameters returns correct id using 2 parameters and different constraint]
AS
BEGIN
  DECLARE @Actual INT;
  DECLARE @Expected INT;

  EXEC ('CREATE SCHEMA schemaA');
  CREATE TABLE schemaA.tableA (id INT CONSTRAINT differentConstraint CHECK(id > 0));
  
  EXEC tSQLt.FakeTable 'schemaA.tableA';
  SELECT @Actual = ConstraintObjectId FROM tSQLt.Private_ResolveApplyConstraintParameters('schemaA.tableA', 'differentConstraint', NULL);
  
  SELECT @Expected = OBJECT_ID('schemaA.differentConstraint');
  EXEC tSQLt.AssertEquals @Expected, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test Private_ResolveApplyConstraintParameters returns correct id using 3 parameters (Schema, Table, Constraint)]
AS
BEGIN
  DECLARE @Actual INT;
  DECLARE @Expected INT;

  EXEC ('CREATE SCHEMA schemaA');
  CREATE TABLE schemaA.tableA (id INT CONSTRAINT testConstraint2 CHECK(id > 0));
  
  EXEC tSQLt.FakeTable 'schemaA.tableA';
  SELECT @Actual = ConstraintObjectId FROM tSQLt.Private_ResolveApplyConstraintParameters('schemaA', 'tableA', 'testConstraint2');
  
  SELECT @Expected = OBJECT_ID('schemaA.testConstraint2');
  EXEC tSQLt.AssertEquals @Expected, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test Private_ResolveApplyConstraintParameters returns correct id using 3 parameters (Table, Constraint, Schema)]
AS
BEGIN
  DECLARE @Actual INT;
  DECLARE @Expected INT;

  EXEC ('CREATE SCHEMA schemaA');
  CREATE TABLE schemaA.tableA (id INT CONSTRAINT testConstraint2 CHECK(id > 0));
  
  EXEC tSQLt.FakeTable 'schemaA.tableA';
  SELECT @Actual = ConstraintObjectId FROM tSQLt.Private_ResolveApplyConstraintParameters('tableA', 'testConstraint2', 'schemaA');
  
  SELECT @Expected = OBJECT_ID('schemaA.testConstraint2');
  EXEC tSQLt.AssertEquals @Expected, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test Private_ResolveApplyConstraintParameters returns no record using 3 parameters in different orders]
AS
BEGIN
  DECLARE @Actual INT;

  EXEC ('CREATE SCHEMA schemaA');
  CREATE TABLE schemaA.tableA (id INT CONSTRAINT testConstraint2 CHECK(id > 0));
  
  EXEC tSQLt.FakeTable 'schemaA.tableA';
  
  SELECT parms.id,result.ConstraintObjectId
  INTO #Actual
  FROM ( 
         SELECT 'SCT', 'schemaA', 'testConstraint2', 'tableA' UNION ALL
         SELECT 'TSC', 'tableA', 'schemaA', 'testConstraint2' UNION ALL
         SELECT 'CST', 'testConstraint2', 'schemaA', 'tableA' UNION ALL
         SELECT 'CTS', 'testConstraint2', 'tableA', 'schemaA' UNION ALL
         SELECT 'FNC', 'schemaA.tableA', NULL, 'testConstraint2' UNION ALL
         SELECT 'CFN', 'testConstraint2', 'schemaA.tableA', NULL UNION ALL
         SELECT 'CNF', 'testConstraint2', NULL, 'schemaA.tableA' UNION ALL
         SELECT 'NCF', NULL, 'testConstraint2', 'schemaA.tableA' UNION ALL
         SELECT 'NFC', NULL, 'schemaA.tableA', 'testConstraint2'
       )parms(id,p1,p2,p3)
  CROSS APPLY tSQLt.Private_ResolveApplyConstraintParameters(p1,p2,p3) result;

  SELECT TOP(0) *
  INTO #Expected
  FROM #Actual;
  
  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROC tSQLt_test.[test Private_ResolveApplyConstraintParameters returns two records when names are reused]
-- this test is to document that users with weirdly reused names will have problems...
AS
BEGIN
  EXEC ('CREATE SCHEMA nameA');
  EXEC ('CREATE SCHEMA nameC');
  CREATE TABLE nameA.nameB (id INT CONSTRAINT nameC CHECK (id > 0));
  CREATE TABLE nameC.nameA (id INT CONSTRAINT nameB CHECK (id > 0));

  SELECT *
    INTO #Expected
    FROM (
           SELECT OBJECT_ID('nameA.nameC')
           UNION ALL
           SELECT OBJECT_ID('nameC.nameB')
         )X(ConstraintObjectId);
  
  EXEC tSQLt.FakeTable 'nameA.nameB';
  EXEC tSQLt.FakeTable 'nameC.nameA';
  
  SELECT ConstraintObjectId
    INTO #Actual
    FROM tSQLt.Private_ResolveApplyConstraintParameters('nameA', 'nameB', 'nameC');

  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROC tSQLt_test.[test Private_ResolveApplyConstraintParameters returns correct id using 2 parameters with quoted table name]
AS
BEGIN
  DECLARE @Actual INT;
  DECLARE @Expected INT;

  EXEC ('CREATE SCHEMA [sch emaA]');
  CREATE TABLE [sch emaA].[tab leA] (id INT CONSTRAINT testConstraint CHECK(id > 0));
  
  EXEC tSQLt.FakeTable '[sch emaA].[tab leA]';
  
  SELECT @Actual = ConstraintObjectId FROM tSQLt.Private_ResolveApplyConstraintParameters('[sch emaA].[tab leA]', 'testConstraint', NULL);
  
  SELECT @Expected = OBJECT_ID('[sch emaA].testConstraint');
  EXEC tSQLt.AssertEquals @Expected, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test Private_ResolveApplyConstraintParameters returns correct id using 2 parameters with quoted constraint name]
AS
BEGIN
  DECLARE @Actual INT;
  DECLARE @Expected INT;

  EXEC ('CREATE SCHEMA schemaA');
  CREATE TABLE schemaA.tableA (id INT CONSTRAINT [test constraint] CHECK(id > 0));
  
  EXEC tSQLt.FakeTable 'schemaA.tableA';
  
  SELECT @Actual = ConstraintObjectId FROM tSQLt.Private_ResolveApplyConstraintParameters('schemaA.tableA', '[test constraint]', NULL);
  
  SELECT @Expected = OBJECT_ID('schemaA.[test constraint]');
  EXEC tSQLt.AssertEquals @Expected, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test Private_FindConstraint returns only one row]
AS
BEGIN
  DECLARE @Actual INT;

  EXEC ('CREATE SCHEMA schemaA');
  CREATE TABLE schemaA.tableA (id INT CONSTRAINT [test constraint] CHECK(id > 0),idx INT CONSTRAINT [[test constraint]]] CHECK(idx > 0));
  
  EXEC tSQLt.FakeTable 'schemaA.tableA';
  
  SELECT @Actual = COUNT(1) FROM tSQLt.Private_FindConstraint(OBJECT_ID('schemaA.tableA'), '[test constraint]');
  
  EXEC tSQLt.AssertEquals 1, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test Private_FindConstraint allows constraints to be found despite seeming ambiguity in quoting (1/3)]
AS
BEGIN
  DECLARE @Actual INT;
  DECLARE @Expected INT;

  EXEC ('CREATE SCHEMA schemaA');
  CREATE TABLE schemaA.tableA (id INT CONSTRAINT [test constraint] CHECK(id > 0),
                               idx INT CONSTRAINT [[test constraint]]] CHECK(idx > 0));
  
  EXEC tSQLt.FakeTable 'schemaA.tableA';
  
  SELECT @Actual = ConstraintObjectId FROM tSQLt.Private_FindConstraint(OBJECT_ID('schemaA.tableA'), '[test constraint]');
  
  SELECT @Expected = OBJECT_ID('schemaA.[test constraint]');
  EXEC tSQLt.AssertEquals @Expected, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test Private_FindConstraint allows constraints to be found despite seeming ambiguity in quoting (2/3)]
AS
BEGIN
  DECLARE @Actual INT;
  DECLARE @Expected INT;

  EXEC ('CREATE SCHEMA schemaA');
  CREATE TABLE schemaA.tableA (id INT CONSTRAINT [test constraint] CHECK(id > 0),
                               idx INT CONSTRAINT [[test constraint]]] CHECK(idx > 0));
  
  EXEC tSQLt.FakeTable 'schemaA.tableA';
  
  SELECT @Actual = ConstraintObjectId FROM tSQLt.Private_FindConstraint(OBJECT_ID('schemaA.tableA'), '[[test constraint]]]');
  
  SELECT @Expected = OBJECT_ID('schemaA.[[test constraint]]]');
  EXEC tSQLt.AssertEquals @Expected, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test Private_FindConstraint allows constraints to be found despite seeming ambiguity in quoting (3/3)]
AS
BEGIN
  DECLARE @Actual INT;
  DECLARE @Expected INT;

  EXEC ('CREATE SCHEMA schemaA');
  CREATE TABLE schemaA.tableA (id INT CONSTRAINT [test constraint] CHECK(id > 0),
                               idx INT CONSTRAINT [[test constraint]]] CHECK(idx > 0));
  
  EXEC tSQLt.FakeTable 'schemaA.tableA';
  
  SELECT @Actual = ConstraintObjectId FROM tSQLt.Private_FindConstraint(OBJECT_ID('schemaA.tableA'), 'test constraint');
  
  SELECT @Expected = OBJECT_ID('schemaA.[test constraint]');
  EXEC tSQLt.AssertEquals @Expected, @Actual;
END;
GO
----------------------------------------------------

CREATE PROC tSQLt_test.test_assertEqualsTable_raises_appropriate_error_if_expected_table_does_not_exist
AS
BEGIN
    DECLARE @ErrorThrown BIT; SET @ErrorThrown = 0;

    EXEC ('CREATE SCHEMA schemaA');
    CREATE TABLE schemaA.actual (constCol CHAR(3) );

    DECLARE @Command NVARCHAR(MAX);
    SET @Command = 'EXEC tSQLt.AssertEqualsTable ''schemaA.expected'', ''schemaA.actual'';';
    EXEC tSQLt_testutil.assertFailCalled @Command, 'assertEqualsTable did not call Fail when expected table does not exist';
END;
GO


CREATE PROC tSQLt_test.test_assertEqualsTable_raises_appropriate_error_if_actual_table_does_not_exist
AS
BEGIN
    DECLARE @ErrorThrown BIT; SET @ErrorThrown = 0;

    EXEC ('CREATE SCHEMA schemaA');
    CREATE TABLE schemaA.expected (constCol CHAR(3) );
    
    DECLARE @Command NVARCHAR(MAX);
    SET @Command = 'EXEC tSQLt.AssertEqualsTable ''schemaA.expected'', ''schemaA.actual'';';
    EXEC tSQLt_testutil.assertFailCalled @Command, 'assertEqualsTable did not call Fail when actual table does not exist';
END;
GO

CREATE PROC tSQLt_test.test_AssertEqualsTable_works_with_temptables
AS
BEGIN
    DECLARE @ErrorThrown BIT; SET @ErrorThrown = 0;

    CREATE TABLE #T1(I INT)
    INSERT INTO #T1 SELECT 1
    CREATE TABLE #T2(I INT)
    INSERT INTO #T2 SELECT 2

    DECLARE @Command NVARCHAR(MAX);
    SET @Command = 'EXEC tSQLt.AssertEqualsTable ''#T1'', ''#T2'';';
    EXEC tSQLt_testutil.assertFailCalled @Command, 'assertEqualsTable did not call Fail when comparing temp tables';
END;
GO

CREATE PROC tSQLt_test.test_AssertEqualsTable_works_with_equal_temptables
AS
BEGIN
    DECLARE @ErrorRaised INT; SET @ErrorRaised = 0;

    EXEC('CREATE SCHEMA MyTestClass;');
    CREATE TABLE #T1(I INT)
    INSERT INTO #T1 SELECT 42
    CREATE TABLE #T2(I INT)
    INSERT INTO #T2 SELECT 42
    EXEC('CREATE PROC MyTestClass.TestCaseA AS EXEC tSQLt.AssertEqualsTable ''#T1'', ''#T2'';');
    
    BEGIN TRY
        EXEC tSQLt.Run 'MyTestClass.TestCaseA';
    END TRY
    BEGIN CATCH
        SET @ErrorRaised = 1;
    END CATCH
    SELECT Class, TestCase, Result
      INTO actual
      FROM tSQLt.TestResult;
    SELECT 'MyTestClass' Class, 'TestCaseA' TestCase, 'Success' Result
      INTO expected;
    
    EXEC tSQLt.AssertEqualsTable 'expected', 'actual';
END;
GO

CREATE PROC tSQLt_test.test_AssertEqualsTable_works_with_actual_having_identity_column
AS
BEGIN
    DECLARE @ErrorRaised INT; SET @ErrorRaised = 0;

    EXEC('CREATE SCHEMA MyTestClass;');
    CREATE TABLE #T1(I INT IDENTITY(1,1));
    INSERT INTO #T1 DEFAULT VALUES;
    CREATE TABLE #T2(I INT);
    INSERT INTO #T2 VALUES(1);
    EXEC('CREATE PROC MyTestClass.TestCaseA AS EXEC tSQLt.AssertEqualsTable ''#T1'', ''#T2'';');
    
    BEGIN TRY
        EXEC tSQLt.Run 'MyTestClass.TestCaseA';
    END TRY
    BEGIN CATCH
        SET @ErrorRaised = 1;
    END CATCH
    SELECT Class, TestCase, Result
      INTO actual
      FROM tSQLt.TestResult;
    SELECT 'MyTestClass' Class, 'TestCaseA' TestCase, 'Success' Result
      INTO expected;
    
    EXEC tSQLt.AssertEqualsTable 'expected', 'actual';
END;
GO

CREATE PROC tSQLt_test.test_AssertEqualsTable_works_with_expected_having_identity_column
AS
BEGIN
    DECLARE @ErrorRaised INT; SET @ErrorRaised = 0;

    EXEC('CREATE SCHEMA MyTestClass;');
    CREATE TABLE #T1(I INT);
    INSERT INTO #T1 VALUES(1);
    CREATE TABLE #T2(I INT IDENTITY(1,1));
    INSERT INTO #T2 DEFAULT VALUES;
    EXEC('CREATE PROC MyTestClass.TestCaseA AS EXEC tSQLt.AssertEqualsTable ''#T1'', ''#T2'';');
    
    BEGIN TRY
        EXEC tSQLt.Run 'MyTestClass.TestCaseA';
    END TRY
    BEGIN CATCH
        SET @ErrorRaised = 1;
    END CATCH
    SELECT Class, TestCase, Result
      INTO actual
      FROM tSQLt.TestResult;
    SELECT 'MyTestClass' Class, 'TestCaseA' TestCase, 'Success' Result
      INTO expected;
    
    EXEC tSQLt.AssertEqualsTable 'expected', 'actual';
END;
GO

CREATE PROC tSQLt_test.test_AssertObjectExists_raises_appropriate_error_if_table_does_not_exist
AS
BEGIN
    DECLARE @ErrorThrown BIT; SET @ErrorThrown = 0;

    EXEC ('CREATE SCHEMA schemaA');
    
    DECLARE @Command NVARCHAR(MAX);
    SET @Command = 'EXEC tSQLt.AssertObjectExists ''schemaA.expected''';
    EXEC tSQLt_testutil.assertFailCalled @Command, 'AssertObjectExists did not call Fail when table does not exist';
END;
GO

CREATE PROC tSQLt_test.test_AssertObjectExists_does_not_call_fail_when_table_exists
AS
BEGIN
    DECLARE @ErrorRaised INT; SET @ErrorRaised = 0;

    EXEC('CREATE SCHEMA MyTestClass;');
    EXEC('CREATE TABLE MyTestClass.tbl(i int);');
    EXEC('CREATE PROC MyTestClass.TestCaseA AS EXEC tSQLt.AssertObjectExists ''MyTestClass.tbl'';');
    
    BEGIN TRY
        EXEC tSQLt.Run 'MyTestClass.TestCaseA';
    END TRY
    BEGIN CATCH
        SET @ErrorRaised = 1;
    END CATCH
    SELECT Class, TestCase, Result 
      INTO actual
      FROM tSQLt.TestResult;
    SELECT 'MyTestClass' Class, 'TestCaseA' TestCase, 'Success' Result
      INTO expected;
    
    EXEC tSQLt.AssertEqualsTable 'expected', 'actual';
END;
GO

CREATE PROC tSQLt_test.test_AssertObjectExists_does_not_call_fail_when_table_is_temp_table
AS
BEGIN
    DECLARE @ErrorRaised INT; SET @ErrorRaised = 0;

    EXEC('CREATE SCHEMA MyTestClass;');
    CREATE TABLE #Tbl(i int);
    EXEC('CREATE PROC MyTestClass.TestCaseA AS EXEC tSQLt.AssertObjectExists ''#Tbl'';');
    
    BEGIN TRY
        EXEC tSQLt.Run 'MyTestClass.TestCaseA';
    END TRY
    BEGIN CATCH
        SET @ErrorRaised = 1;
    END CATCH
    SELECT Class, TestCase, Result
      INTO actual
      FROM tSQLt.TestResult;
    SELECT 'MyTestClass' Class, 'TestCaseA' TestCase, 'Success' Result
      INTO expected;
    
    EXEC tSQLt.AssertEqualsTable 'expected', 'actual';
END;
GO

CREATE PROC tSQLt_test.test_dropClass_does_not_error_if_testcase_name_contains_spaces
AS
BEGIN
    DECLARE @ErrorRaised INT; SET @ErrorRaised = 0;

    EXEC('CREATE SCHEMA MyTestClass;');
    EXEC('CREATE PROC MyTestClass.[Test Case A ] AS RETURN 0;');
    
    BEGIN TRY
        EXEC tSQLt.DropClass 'MyTestClass';
    END TRY
    BEGIN CATCH
        SET @ErrorRaised = 1;
    END CATCH

    EXEC tSQLt.AssertEquals 0,@ErrorRaised,'Unexpected error during execution of DropClass'
    
    IF(SCHEMA_ID('MyTestClass') IS NOT NULL)
    BEGIN    
      EXEC tSQLt.Fail 'DropClass did not drop MyTestClass';
    END
END;
GO

CREATE PROC tSQLt_test.[test that tSQLt.Run executes all tests in test class when called with class name]
AS
BEGIN
    EXEC('EXEC tSQLt.DropClass innertest;');
    EXEC('CREATE SCHEMA innertest;');
    EXEC('CREATE PROC innertest.testMe as RETURN 0;');
    EXEC('CREATE PROC innertest.testMeToo as RETURN 0;');

    EXEC tSQLt.Run 'innertest';

    SELECT Class, TestCase 
      INTO #Expected
      FROM tSQLt.TestResult
     WHERE 1=0;
     
    INSERT INTO #Expected(Class, TestCase)
    SELECT Class = 'innertest', TestCase = 'testMe' UNION ALL
    SELECT Class = 'innertest', TestCase = 'testMeToo';

    SELECT Class, TestCase
      INTO #Actual
      FROM tSQLt.TestResult;
      
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';    
END;
GO

CREATE PROC tSQLt_test.[test that tSQLt.Run executes single test when called with test case name]
AS
BEGIN
    EXEC('EXEC tSQLt.DropClass innertest;');
    EXEC('CREATE SCHEMA innertest;');
    EXEC('CREATE PROC innertest.testMe as RETURN 0;');
    EXEC('CREATE PROC innertest.testNotMe as RETURN 0;');

    EXEC tSQLt.Run 'innertest.testMe';

    SELECT Class, TestCase 
      INTO #Expected
      FROM tSQLt.TestResult
     WHERE 1=0;
     
    INSERT INTO #Expected(Class, TestCase)
    SELECT class = 'innertest', TestCase = 'testMe';

    SELECT Class, TestCase
      INTO #Actual
      FROM tSQLt.TestResult;
      
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';    
END;
GO

CREATE PROC tSQLt_test.[test that tSQLt.Run re-executes single test when called without parameter]
AS
BEGIN
    EXEC('EXEC tSQLt.DropClass innertest;');
    EXEC('CREATE SCHEMA innertest;');
    EXEC('CREATE PROC innertest.testMe as RETURN 0;');
    EXEC('CREATE PROC innertest.testNotMe as RETURN 0;');

    TRUNCATE TABLE tSQLt.Run_LastExecution;
    
    EXEC tSQLt.Run 'innertest.testMe';
    DELETE FROM tSQLt.TestResult;
    
    EXEC tSQLt.Run;

    SELECT Class, TestCase 
      INTO #Expected
      FROM tSQLt.TestResult
     WHERE 1=0;
     
    INSERT INTO #Expected(Class, TestCase)
    SELECT Class = 'innertest', TestCase = 'testMe';

    SELECT Class, TestCase
      INTO #Actual
      FROM tSQLt.TestResult;
      
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';    
END;
GO

CREATE PROC tSQLt_test.[test that tSQLt.Run re-executes testClass when called without parameter]
AS
BEGIN
    EXEC('EXEC tSQLt.DropClass innertest;');
    EXEC('CREATE SCHEMA innertest;');
    EXEC('CREATE PROC innertest.testMe as RETURN 0;');
    EXEC('CREATE PROC innertest.testMeToo as RETURN 0;');

    TRUNCATE TABLE tSQLt.Run_LastExecution;
    
    EXEC tSQLt.Run 'innertest';
    DELETE FROM tSQLt.TestResult;
    
    EXEC tSQLt.Run;

    SELECT Class, TestCase
      INTO #Expected
      FROM tSQLt.TestResult
     WHERE 1=0;
     
    INSERT INTO #Expected(Class, TestCase)
    SELECT Class = 'innertest', TestCase = 'testMe' UNION ALL
    SELECT Class = 'innertest', TestCase = 'testMeToo';

    SELECT Class, TestCase
      INTO #Actual
      FROM tSQLt.TestResult;
      
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';    
END;
GO

CREATE PROC tSQLt_test.[test that tSQLt.Run deletes all entries from tSQLt.Run_LastExecution with same SPID]
AS
BEGIN
    EXEC tSQLt.FakeTable 'tSQLt', 'Run_LastExecution';
    
    EXEC('EXEC tSQLt.DropClass New;');
    EXEC('CREATE SCHEMA New;');

    TRUNCATE TABLE tSQLt.Run_LastExecution;
    
    INSERT tSQLt.Run_LastExecution(SessionId, LoginTime, TestName)
    SELECT @@SPID, '2009-09-09', '[Old1]' UNION ALL
    SELECT @@SPID, '2010-10-10', '[Old2]' UNION ALL
    SELECT @@SPID+10, '2011-11-11', '[Other]';   

    EXEC tSQLt.Run '[New]';
    
    SELECT TestName 
      INTO #Expected
      FROM tSQLt.Run_LastExecution
     WHERE 1=0;
     
    INSERT INTO #Expected(testName)
    SELECT '[Other]' UNION ALL
    SELECT '[New]';

    SELECT TestName
      INTO #Actual
      FROM tSQLt.Run_LastExecution;
      
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';    
END;
GO

CREATE PROC tSQLt_test.test_SpyProcedure_handles_procedure_names_with_spaces
AS
BEGIN
    DECLARE @ErrorRaised INT; SET @ErrorRaised = 0;

    EXEC('CREATE PROC tSQLt_test.[Spyee Proc] AS RETURN 0;');

    EXEC tSQLt.SpyProcedure 'tSQLt_test.[Spyee Proc]'
    
    EXEC tSQLt_test.[Spyee Proc];
    
    SELECT *
      INTO #Actual
      FROM tSQLt_test.[Spyee Proc_SpyProcedureLog];
    
    SELECT 1 _id_
      INTO #Expected
     WHERE 0=1;

    INSERT #Expected
    SELECT 1;
    
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROC tSQLt_test.test_RunTestClass_handles_test_names_with_spaces
AS
BEGIN
    DECLARE @ErrorRaised INT; SET @ErrorRaised = 0;

    EXEC('CREATE SCHEMA MyTestClass;');
    EXEC('CREATE PROC MyTestClass.[Test Case A] AS RETURN 0;');

    EXEC tSQLt.RunTestClass MyTestClass;
    
    SELECT Class, TestCase 
      INTO actual
      FROM tSQLt.TestResult;
      
    SELECT 'MyTestClass' Class, 'Test Case A' TestCase
      INTO expected;
    
    EXEC tSQLt.AssertEqualsTable 'expected', 'actual';
END;
GO

CREATE PROC tSQLt_test.[test NewTestClass creates a new schema]
AS
BEGIN
    EXEC tSQLt.NewTestClass 'MyTestClass';
    
    IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'MyTestClass')
    BEGIN
        EXEC tSQLt.Fail 'Should have created schema: MyTestClass';
    END;
END;
GO

CREATE PROC tSQLt_test.[test NewTestClass calls tSQLt.DropClass]
AS
BEGIN
    EXEC tSQLt.SpyProcedure 'tSQLt.DropClass';
    
    EXEC tSQLt.NewTestClass 'MyTestClass';
    
    IF NOT EXISTS(SELECT * FROM tSQLt.DropClass_SpyProcedureLog WHERE ClassName = 'MyTestClass') 
    BEGIN
        EXEC tSQLt.Fail 'Should have called tSQLt.DropClass ''MyTestClass''';
    END
END;
GO

CREATE PROCEDURE tSQLt_test.[test NewTestClass should throw an error if the schema exists and is not a test schema]
AS
BEGIN
    DECLARE @Err NVARCHAR(MAX); SET @Err = 'NO ERROR';
    EXEC('CREATE SCHEMA MySchema;');

    BEGIN TRY
      EXEC tSQLt.NewTestClass 'MySchema';
    END TRY
    BEGIN CATCH
      SET @Err = ERROR_MESSAGE();
    END CATCH
    
    IF @Err NOT LIKE '%Attempted to execute tSQLt.NewTestClass on ''MySchema''. However, ''MySchema'' is an existing schema and not a test class%'
    BEGIN
        EXEC tSQLt.Fail 'Unexpected error message was: ', @Err;
    END;
END;
GO

CREATE PROCEDURE tSQLt_test.[test NewTestClass should not drop an existing schema if it was not a test class]
AS
BEGIN
    EXEC('CREATE SCHEMA MySchema;');
    EXEC tSQLt.SpyProcedure 'tSQLt.DropClass';

    BEGIN TRY
      EXEC tSQLt.NewTestClass 'MySchema';
    END TRY
    BEGIN CATCH
    END CATCH
    
    IF EXISTS(SELECT * FROM tSQLt.DropClass_SpyProcedureLog WHERE ClassName = 'MySchema') 
    BEGIN
        EXEC tSQLt.Fail 'Should not have called tSQLt.DropClass ''MySchema''';
    END
END;
GO

CREATE PROCEDURE tSQLt_test.[test NewTestClass can create schemas with the space character]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'My Test Class';
  
  IF SCHEMA_ID('My Test Class') IS NULL
  BEGIN
    EXEC tSQLt.Fail 'Should be able to create test class: My Test Class';
  END;
END;
GO

CREATE PROCEDURE tSQLt_test.[test NewTestClass can create schemas with the other special characters]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'My!@#$%^&*()Test-+=|\<>,.?/Class';
  
  IF SCHEMA_ID('My!@#$%^&*()Test-+=|\<>,.?/Class') IS NULL
  BEGIN
    EXEC tSQLt.Fail 'Should be able to create test class: My!@#$%^&*()Test-+=|\<>,.?/Class';
  END;
END;
GO

CREATE PROCEDURE tSQLt_test.[test NewTestClass can create schemas when the name is already quoted]
AS
BEGIN
  EXEC tSQLt.NewTestClass '[My Test Class]';
  
  IF SCHEMA_ID('My Test Class') IS NULL
  BEGIN
    EXEC tSQLt.Fail 'Should be able to create test class: My Test Class';
  END;
END;
GO

CREATE PROC tSQLt_test.[test SpyProcedure works if spyee has 100 parameters with 8000 bytes each]
AS
BEGIN
  IF OBJECT_ID('dbo.InnerProcedure') IS NOT NULL DROP PROCEDURE dbo.InnerProcedure;
  DECLARE @Cmd VARCHAR(MAX);
  SELECT @Cmd = 'CREATE PROC dbo.InnerProcedure('+
                (SELECT CASE WHEN no = 1 THEN '' ELSE ',' END +'@P'+CAST(no AS VARCHAR)+' CHAR(8000)' [text()]
                   FROM tSQLt.F_Num(100)
                    FOR XML PATH('')
                )+
                ') AS BEGIN RETURN 0; END;';
  EXEC(@Cmd);

  SELECT name, parameter_id, system_type_id, user_type_id, max_length, precision, scale 
    INTO #ExpectedM
    FROM sys.parameters
   WHERE object_id = OBJECT_ID('dbo.InnerProcedure');

  EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure'

  SELECT name, parameter_id, system_type_id, user_type_id, max_length, precision, scale 
    INTO #ActualM
    FROM sys.parameters
   WHERE object_id = OBJECT_ID('dbo.InnerProcedure');

  SELECT * 
    INTO #Actual1
    FROM #ActualM
   WHERE parameter_id<511;
  SELECT * 
    INTO #Expected1
    FROM #ExpectedM
   WHERE parameter_id<511;
   
  EXEC tSQLt.AssertEqualsTable '#Expected1','#Actual1';

  SELECT * 
    INTO #Actual2
    FROM #ActualM
   WHERE parameter_id>510;
  SELECT * 
    INTO #Expected2
    FROM #ExpectedM
   WHERE parameter_id>510;
   
  EXEC tSQLt.AssertEqualsTable '#Expected2','#Actual2';
END
GO
CREATE PROC tSQLt_test.[test SpyProcedure creates char parameters correctly]
AS
BEGIN
    EXEC('CREATE PROC dbo.InnerProcedure(
             @CHAR1 CHAR(1),
             @CHAR8000 CHAR(8000),
             @VARCHAR1 VARCHAR(1),
             @VARCHAR8000 VARCHAR(8000),
             @VARCHARMAX VARCHAR(MAX)
          )
          AS BEGIN RETURN 0; END');
    SELECT name, parameter_id, system_type_id, user_type_id, max_length, precision, scale 
      INTO #Expected
      FROM sys.parameters
     WHERE object_id = OBJECT_ID('dbo.InnerProcedure');

    EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure'

    SELECT name, parameter_id, system_type_id, user_type_id, max_length, precision, scale 
      INTO #Actual
      FROM sys.parameters
     WHERE object_id = OBJECT_ID('dbo.InnerProcedure');

    EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROC tSQLt_test.[test SpyProcedure creates binary parameters correctly]
AS
BEGIN
    EXEC('CREATE PROC dbo.InnerProcedure(
             @BINARY1 BINARY(1) =NULL,
             @BINARY8000 BINARY(8000) =NULL,
             @VARBINARY1 VARBINARY(1) =NULL,
             @VARBINARY8000 VARBINARY(8000) =NULL,
             @VARBINARYMAX VARBINARY(MAX) =NULL
          )
          AS BEGIN RETURN 0; END');
    SELECT name, parameter_id, system_type_id, user_type_id, max_length, precision, scale 
      INTO #Expected
      FROM sys.parameters
     WHERE object_id = OBJECT_ID('dbo.InnerProcedure');

    EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure'

    SELECT name, parameter_id, system_type_id, user_type_id, max_length, precision, scale 
      INTO #Actual
      FROM sys.parameters
     WHERE object_id = OBJECT_ID('dbo.InnerProcedure');

     EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROC tSQLt_test.[test SpyProcedure creates log which handles binary columns]
AS
BEGIN
    EXEC('CREATE PROC dbo.InnerProcedure(
             @VARBINARY8000 VARBINARY(8000) =NULL
          )
          AS BEGIN RETURN 0; END');

    EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure'
     
    EXEC dbo.InnerProcedure @VARBINARY8000=0x111122223333444455556666777788889999;

    DECLARE @Actual VARBINARY(8000);
    SELECT @Actual = VARBINARY8000 FROM dbo.InnerProcedure_SpyProcedureLog;
    
    EXEC tSQLt.AssertEquals 0x111122223333444455556666777788889999, @Actual;
END;
GO


CREATE PROC tSQLt_test.[test SpyProcedure creates nchar parameters correctly]
AS
BEGIN
    EXEC('CREATE PROC dbo.InnerProcedure(
             @NCHAR1 NCHAR(1),
             @NCHAR4000 NCHAR(4000),
             @NVARCHAR1 NVARCHAR(1),
             @NVARCHAR4000 NVARCHAR(4000),
             @NVARCHARMAX NVARCHAR(MAX)
          )
          AS BEGIN RETURN 0; END');
    SELECT name, parameter_id, system_type_id, user_type_id, max_length, precision, scale 
      INTO #Expected
      FROM sys.parameters
     WHERE object_id = OBJECT_ID('dbo.InnerProcedure');

    EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure'

    SELECT name, parameter_id, system_type_id, user_type_id, max_length, precision, scale 
      INTO #Actual
      FROM sys.parameters
     WHERE object_id = OBJECT_ID('dbo.InnerProcedure');

    EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROC tSQLt_test.[test SpyProcedure creates other parameters correctly]
AS
BEGIN
    EXEC('CREATE PROC dbo.InnerProcedure(
             @TINYINT TINYINT,
             @SMALLINT SMALLINT,
             @INT INT,
             @BIGINT BIGINT
          )
          AS BEGIN RETURN 0; END');
    SELECT name, parameter_id, system_type_id, user_type_id, max_length, precision, scale 
      INTO #Expected
      FROM sys.parameters
     WHERE object_id = OBJECT_ID('dbo.InnerProcedure');

    EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure'

    SELECT name, parameter_id, system_type_id, user_type_id, max_length, precision, scale 
      INTO #Actual
      FROM sys.parameters
     WHERE object_id = OBJECT_ID('dbo.InnerProcedure');

    EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROC tSQLt_test.[test SpyProcedure fails with error if spyee has more than 1020 parameters]
AS
BEGIN
  IF OBJECT_ID('dbo.Spyee') IS NOT NULL DROP PROCEDURE dbo.Spyee;
  DECLARE @Cmd VARCHAR(MAX);
  SELECT @Cmd = 'CREATE PROC dbo.Spyee('+
                (SELECT CASE WHEN no = 1 THEN '' ELSE ',' END +'@P'+CAST(no AS VARCHAR)+' INT' [text()]
                   FROM tSQLt.F_Num(1021)
                    FOR XML PATH('')
                )+
                ') AS BEGIN RETURN 0; END;';
  EXEC(@Cmd);
  DECLARE @Err VARCHAR(MAX);SET @Err = 'NO ERROR';
  BEGIN TRY
    EXEC tSQLt.SpyProcedure 'dbo.Spyee';
  END TRY
  BEGIN CATCH
    SET @Err = ERROR_MESSAGE();
  END CATCH
  
  IF @Err NOT LIKE '%dbo.Spyee%' AND @Err NOT LIKE '%1020 parameters%'
  BEGIN
      EXEC tSQLt.Fail 'Unexpected error message was: ', @Err;
  END;
  
END
GO
CREATE PROC tSQLt_test.[test f_Num(13) returns 13 rows]
AS
BEGIN
  SELECT no
    INTO #Actual
    FROM tSQLt.F_Num(13);
    
  SELECT * INTO #Expected FROM #Actual WHERE 1=0;
  
  INSERT #Expected(no)
  SELECT 1 no UNION ALL
  SELECT 2 no UNION ALL
  SELECT 3 no UNION ALL
  SELECT 4 no UNION ALL
  SELECT 5 no UNION ALL
  SELECT 6 no UNION ALL
  SELECT 7 no UNION ALL
  SELECT 8 no UNION ALL
  SELECT 9 no UNION ALL
  SELECT 10 no UNION ALL
  SELECT 11 no UNION ALL
  SELECT 12 no UNION ALL
  SELECT 13 no;
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END 
GO
CREATE PROC tSQLt_test.[test f_Num(0) returns 0 rows]
AS
BEGIN
  SELECT no
    INTO #Actual
    FROM tSQLt.F_Num(0);
    
  SELECT * INTO #Expected FROM #Actual WHERE 1=0;
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END 
GO
CREATE PROC tSQLt_test.[test f_Num(-11) returns 0 rows]
AS
BEGIN
  SELECT no
    INTO #Actual
    FROM tSQLt.F_Num(-11);
    
  SELECT * INTO #Expected FROM #Actual WHERE 1=0;
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END 
GO

CREATE PROC tSQLt_test.[test that Private_SetFakeViewOn_SingleView allows a non-updatable view to be faked using FakeTable and then inserted into]
AS
BEGIN
  EXEC('CREATE SCHEMA NewSchema;');

  EXEC('
      CREATE TABLE NewSchema.A (a1 int, a2 int);
      CREATE TABLE NewSchema.B (a1 int, b1 int, b2 int);
      CREATE TABLE NewSchema.C (b1 int, c1 int, c2 int);
      ');

  EXEC('      
      CREATE VIEW NewSchema.NewView AS
        SELECT A.a1, A.a2, B.b1, B.b2
          FROM NewSchema.A
          JOIN NewSchema.B ON A.a1 < B.a1
          JOIN NewSchema.C ON B.a1 > C.b1;
      ');
      
  -- SetFakeViewOn is executed in a separate batch (typically followed by a GO statement)
  -- than the code of the test case
  EXEC('    
      EXEC tSQLt.Private_SetFakeViewOn_SingleView @ViewName = ''NewSchema.NewView'';
      ');
      
  EXEC('
      EXEC tSQLt.FakeTable ''NewSchema'', ''NewView'';
      INSERT INTO NewSchema.NewView (a1, a2, b1, b2) VALUES (1, 2, 3, 4);
      ');

  SELECT a1, a2, b1, b2 INTO #Expected
    FROM (SELECT 1 AS a1, 2 AS a2, 3 AS b1, 4 AS b2) X;
    
  EXEC tSQLt.AssertEqualsTable '#Expected', 'NewSchema.NewView';
  
END
GO

CREATE PROC tSQLt_test.[test that not calling tSQLt.Private_SetFakeViewOff_SingleView before running tests causes an exception and tests not to be run]
AS
BEGIN
  DECLARE @ErrorMsg VARCHAR(MAX); SET @ErrorMsg = '';
  
  EXEC('CREATE SCHEMA NewSchema;');
  EXEC('CREATE VIEW NewSchema.NewView AS SELECT 1 AS a;');
  EXEC('EXEC tSQLt.Private_SetFakeViewOn_SingleView @ViewName = ''NewSchema.NewView'';');
  
  EXEC ('EXEC tSQLt.NewTestClass TestClass;');
  
  EXEC ('
    CREATE PROC TestClass.testExample
    AS
    BEGIN
      RETURN 0;
    END;
  ');
  
  BEGIN TRY
    EXEC tSQLt.Private_RunTest 'TestClass.testExample';
  END TRY
  BEGIN CATCH
    SET @ErrorMsg = ERROR_MESSAGE();
  END CATCH

  IF @ErrorMsg NOT LIKE '%SetFakeViewOff%'
  BEGIN
    EXEC tSQLt.Fail 'Expected RunTestClass to raise an error because SetFakeViewOff was not executed';
  END;
END
GO

CREATE PROC tSQLt_test.[test that calling tSQLt.Private_SetFakeViewOff_SingleView before running tests allows tests to be run]
AS
BEGIN
  EXEC('CREATE SCHEMA NewSchema;');
  EXEC('CREATE VIEW NewSchema.NewView AS SELECT 1 AS a;');
  EXEC('EXEC tSQLt.Private_SetFakeViewOn_SingleView @ViewName = ''NewSchema.NewView'';');
  
  EXEC ('EXEC tSQLt.NewTestClass TestClass;');
  
  EXEC ('
    CREATE PROC TestClass.testExample
    AS
    BEGIN
      RETURN 0;
    END;
  ');
  
  EXEC('EXEC tSQLt.Private_SetFakeViewOff_SingleView @ViewName = ''NewSchema.NewView'';');
  
  BEGIN TRY
    EXEC tSQLt.Run 'TestClass';
  END TRY
  BEGIN CATCH
    DECLARE @Msg VARCHAR(MAX);SET @Msg = ERROR_MESSAGE();
    EXEC tSQLt.Fail 'Expected RunTestClass to not raise an error because Private_SetFakeViewOff_SingleView was executed. Error was:',@Msg;
  END CATCH
END
GO

CREATE PROC tSQLt_test.CreateNonUpdatableView
  @SchemaName NVARCHAR(MAX),
  @ViewName NVARCHAR(MAX)
AS
BEGIN
  DECLARE @Cmd NVARCHAR(MAX);

  SET @Cmd = '
      CREATE TABLE $$SCHEMA_NAME$$.$$VIEW_NAME$$_A (a1 int, a2 int);
      CREATE TABLE $$SCHEMA_NAME$$.$$VIEW_NAME$$_B (a1 int, b1 int, b2 int);';
  SET @Cmd = REPLACE(REPLACE(@Cmd, '$$SCHEMA_NAME$$', @SchemaName), '$$VIEW_NAME$$', @ViewName);
  EXEC (@Cmd);

  SET @Cmd = '
    CREATE VIEW $$SCHEMA_NAME$$.$$VIEW_NAME$$ AS 
      SELECT A.a1, A.a2, B.b1, B.b2
        FROM $$SCHEMA_NAME$$.$$VIEW_NAME$$_A A
        JOIN $$SCHEMA_NAME$$.$$VIEW_NAME$$_B B ON A.a1 = B.a1;';
  SET @Cmd = REPLACE(REPLACE(@Cmd, '$$SCHEMA_NAME$$', @SchemaName), '$$VIEW_NAME$$', @ViewName);
  EXEC (@Cmd);

END
GO

CREATE PROC tSQLt_test.AssertViewCanBeUpdatedIfFaked
  @SchemaName NVARCHAR(MAX),
  @ViewName NVARCHAR(MAX)
AS
BEGIN
  DECLARE @Cmd NVARCHAR(MAX);

  SET @Cmd = '
      EXEC tSQLt.FakeTable ''$$SCHEMA_NAME$$'', ''$$VIEW_NAME$$'';
      INSERT INTO $$SCHEMA_NAME$$.$$VIEW_NAME$$ (a1, a2, b1, b2) VALUES (1, 2, 3, 4);';
  SET @Cmd = REPLACE(REPLACE(@Cmd, '$$SCHEMA_NAME$$', @SchemaName), '$$VIEW_NAME$$', @ViewName);
  EXEC (@Cmd);
  
  SET @Cmd = '
    SELECT a1, a2, b1, b2 INTO #Expected
    FROM (SELECT 1 AS a1, 2 AS a2, 3 AS b1, 4 AS b2) X;
    
    EXEC tSQLt.AssertEqualsTable ''#Expected'', ''$$SCHEMA_NAME$$.$$VIEW_NAME$$'';';
  SET @Cmd = REPLACE(REPLACE(@Cmd, '$$SCHEMA_NAME$$', @SchemaName), '$$VIEW_NAME$$', @ViewName);
  EXEC (@Cmd);
END;
GO

CREATE PROC tSQLt_test.[test that tSQLt.SetFakeViewOn @SchemaName applies to all views on a schema]
AS
BEGIN
  EXEC('CREATE SCHEMA NewSchema;');
  EXEC tSQLt_test.CreateNonUpdatableView 'NewSchema', 'View1';
  EXEC tSQLt_test.CreateNonUpdatableView 'NewSchema', 'View2';
  EXEC tSQLt_test.CreateNonUpdatableView 'NewSchema', 'View3';
  EXEC('EXEC tSQLt.SetFakeViewOn @SchemaName = ''NewSchema'';');
  
  EXEC tSQLt_test.AssertViewCanBeUpdatedIfFaked 'NewSchema', 'View1';
  EXEC tSQLt_test.AssertViewCanBeUpdatedIfFaked 'NewSchema', 'View2';
  EXEC tSQLt_test.AssertViewCanBeUpdatedIfFaked 'NewSchema', 'View3';
  
  -- Also check that triggers got created. Checking if a view is updatable is
  -- apparently unreliable, since SQL Server could have decided on this run
  -- that these views are updatable at compile time, even though they were not.
  IF (SELECT COUNT(*) FROM sys.triggers WHERE [name] LIKE 'View_[_]SetFakeViewOn') <> 3
  BEGIN
    EXEC tSQLt.Fail 'Expected _SetFakeViewOn triggers to be added.';
  END;
END
GO

CREATE PROC tSQLt_test.[test that tSQLt.SetFakeViewOff @SchemaName applies to all views on a schema]
AS
BEGIN
  EXEC('CREATE SCHEMA NewSchema;');
  EXEC tSQLt_test.CreateNonUpdatableView 'NewSchema', 'View1';
  EXEC tSQLt_test.CreateNonUpdatableView 'NewSchema', 'View2';
  EXEC tSQLt_test.CreateNonUpdatableView 'NewSchema', 'View3';
  EXEC('EXEC tSQLt.SetFakeViewOn @SchemaName = ''NewSchema'';');
  EXEC('EXEC tSQLt.SetFakeViewOff @SchemaName = ''NewSchema'';');
  
  IF EXISTS (SELECT 1 FROM sys.triggers WHERE [name] LIKE 'View_[_]SetFakeViewOn')
  BEGIN
    EXEC tSQLt.Fail 'Expected _SetFakeViewOn triggers to be removed.';
  END;
END
GO

CREATE PROC tSQLt_test.[test that tSQLt.SetFakeViewOff @SchemaName only removes triggers created by framework]
AS
BEGIN
  EXEC('CREATE SCHEMA NewSchema;');
  EXEC tSQLt_test.CreateNonUpdatableView 'NewSchema', 'View1';
  EXEC('CREATE TRIGGER NewSchema.View1_SetFakeViewOn ON NewSchema.View1 INSTEAD OF INSERT AS RETURN;');
  EXEC('EXEC tSQLt.SetFakeViewOff @SchemaName = ''NewSchema'';');
  
  IF NOT EXISTS (SELECT 1 FROM sys.triggers WHERE [name] = 'View1_SetFakeViewOn')
  BEGIN
    EXEC tSQLt.Fail 'Expected View1_SetFakeViewOn trigger not to be removed.';
  END;
END
GO

CREATE PROC tSQLt_test.[test that SetFakeViewOn trigger throws meaningful error on execution]
AS
BEGIN
  --This test also tests that tSQLt can handle test that leave the transaction open, but in an uncommitable state.
  DECLARE @Msg VARCHAR(MAX); SET @Msg = 'no error';
  
  EXEC('CREATE SCHEMA NewSchema;');
  EXEC tSQLt_test.CreateNonUpdatableView 'NewSchema', 'View1';
  EXEC('EXEC tSQLt.SetFakeViewOn @SchemaName = ''NewSchema'';');
  
  BEGIN TRY
    EXEC('INSERT NewSchema.View1 DEFAULT VALUES;');
  END TRY
  BEGIN CATCH
    SET @Msg = ERROR_MESSAGE();
  END CATCH;
  
  IF(@Msg NOT LIKE '%SetFakeViewOff%')
  BEGIN
    EXEC tSQLt.Fail 'Expected trigger to throw error. Got:',@Msg;
  END;
END
GO

CREATE PROC tSQLt_test.[test RunAll runs all test classes created with NewTestClass]
AS
BEGIN
    EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;

    EXEC tSQLt.NewTestClass 'A';
    EXEC tSQLt.NewTestClass 'B';
    EXEC tSQLt.NewTestClass 'C';
    
    EXEC ('CREATE PROC A.testA AS RETURN 0;');
    EXEC ('CREATE PROC B.testB AS RETURN 0;');
    EXEC ('CREATE PROC C.testC AS RETURN 0;');
    
    DELETE FROM tSQLt.TestResult;
    
    EXEC tSQLt.RunAll;

    SELECT Class, TestCase 
      INTO #Expected
      FROM tSQLt.TestResult
     WHERE 1=0;
     
    INSERT INTO #Expected (Class, TestCase)
    SELECT Class = 'A', TestCase = 'testA' UNION ALL
    SELECT Class = 'B', TestCase = 'testB' UNION ALL
    SELECT Class = 'C', TestCase = 'testC';

    SELECT Class, TestCase
      INTO #Actual
      FROM tSQLt.TestResult;
      
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual'; 
END;
GO

CREATE PROC tSQLt_test.[test RunAll runs all test classes created with NewTestClass when there are multiple tests in each class]
AS
BEGIN
    EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;

    EXEC tSQLt.NewTestClass 'A';
    EXEC tSQLt.NewTestClass 'B';
    EXEC tSQLt.NewTestClass 'C';
    
    EXEC ('CREATE PROC A.testA1 AS RETURN 0;');
    EXEC ('CREATE PROC A.testA2 AS RETURN 0;');
    EXEC ('CREATE PROC B.testB1 AS RETURN 0;');
    EXEC ('CREATE PROC B.testB2 AS RETURN 0;');
    EXEC ('CREATE PROC C.testC1 AS RETURN 0;');
    EXEC ('CREATE PROC C.testC2 AS RETURN 0;');
    
    DELETE FROM tSQLt.TestResult;
    
    EXEC tSQLt.RunAll;

    SELECT Class, TestCase
      INTO #Expected
      FROM tSQLt.TestResult
     WHERE 1=0;
     
    INSERT INTO #Expected (Class, TestCase)
    SELECT Class = 'A', TestCase = 'testA1' UNION ALL
    SELECT Class = 'A', TestCase = 'testA2' UNION ALL
    SELECT Class = 'B', TestCase = 'testB1' UNION ALL
    SELECT Class = 'B', TestCase = 'testB2' UNION ALL
    SELECT Class = 'C', TestCase = 'testC1' UNION ALL
    SELECT Class = 'C', TestCase = 'testC2';

    SELECT Class, TestCase
      INTO #Actual
      FROM tSQLt.TestResult;
      
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual'; 
END;
GO

CREATE PROC tSQLt_test.[test RunAll executes the SetUp for each test case]
AS
BEGIN
    EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;

    EXEC tSQLt.NewTestClass 'A';
    EXEC tSQLt.NewTestClass 'B';
    
    CREATE TABLE A.SetUpLog (i INT DEFAULT 1);
    CREATE TABLE B.SetUpLog (i INT DEFAULT 1);
    
    CREATE TABLE tSQLt_test.SetUpLog (i INT);
    INSERT INTO tSQLt_test.SetUpLog (i) VALUES (1);
    
    EXEC ('CREATE PROC A.SetUp AS INSERT INTO A.SetUpLog DEFAULT VALUES;');
    EXEC ('CREATE PROC A.testA AS EXEC tSQLt.AssertEqualsTable ''tSQLt_test.SetUpLog'', ''A.SetUpLog'';');
    EXEC ('CREATE PROC B.SetUp AS INSERT INTO B.SetUpLog DEFAULT VALUES;');
    EXEC ('CREATE PROC B.testB1 AS EXEC tSQLt.AssertEqualsTable ''tSQLt_test.SetUpLog'', ''B.SetUpLog'';');
    EXEC ('CREATE PROC B.testB2 AS EXEC tSQLt.AssertEqualsTable ''tSQLt_test.SetUpLog'', ''B.SetUpLog'';');
    
    DELETE FROM tSQLt.TestResult;
    
    EXEC tSQLt.RunAll;

    SELECT Class, TestCase, Result
      INTO #Expected
      FROM tSQLt.TestResult
     WHERE 1=0;
     
    INSERT INTO #Expected (Class, TestCase, Result)
    SELECT Class = 'A', TestCase = 'testA', Result = 'Success' UNION ALL
    SELECT Class = 'B', TestCase = 'testB1', Result = 'Success' UNION ALL
    SELECT Class = 'B', TestCase = 'testB2', Result = 'Success';

    SELECT Class, TestCase, Result
      INTO #Actual
      FROM tSQLt.TestResult;
      
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual'; 
END;
GO

CREATE PROC tSQLt_test.[test RunTestClass executes the SetUp for each test case]
AS
BEGIN
    EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;

    EXEC tSQLt.NewTestClass 'MyTestClass';
    
    CREATE TABLE MyTestClass.SetUpLog (i INT DEFAULT 1);
    
    CREATE TABLE tSQLt_test.SetUpLog (i INT);
    INSERT INTO tSQLt_test.SetUpLog (i) VALUES (1);
    
    EXEC ('CREATE PROC MyTestClass.SetUp AS INSERT INTO MyTestClass.SetUpLog DEFAULT VALUES;');
    EXEC ('CREATE PROC MyTestClass.test1 AS EXEC tSQLt.AssertEqualsTable ''tSQLt_test.SetUpLog'', ''MyTestClass.SetUpLog'';');
    EXEC ('CREATE PROC MyTestClass.test2 AS EXEC tSQLt.AssertEqualsTable ''tSQLt_test.SetUpLog'', ''MyTestClass.SetUpLog'';');
    
    DELETE FROM tSQLt.TestResult;
    
    EXEC tSQLt.RunTestClass 'MyTestClass';

    SELECT Class, TestCase, Result
      INTO #Expected
      FROM tSQLt.TestResult
     WHERE 1=0;
     
    INSERT INTO #Expected (Class, TestCase, Result)
    SELECT Class = 'MyTestClass', TestCase = 'test1', Result = 'Success' UNION ALL
    SELECT Class = 'MyTestClass', TestCase = 'test2', Result = 'Success';

    SELECT Class, TestCase, Result
      INTO #Actual
      FROM tSQLt.TestResult;
      
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual'; 
END;
GO

CREATE PROC tSQLt_test.[test TestResult record with Class and TestCase has Name value of quoted class name and test case name]
AS
BEGIN
    DELETE FROM tSQLt.TestResult;

    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName)
    VALUES ('MyClassName', 'MyTestCaseName', 'XYZ');
    
    SELECT Class, TestCase, Name
      INTO #Expected
      FROM tSQLt.TestResult
     WHERE 1=0;
    
    INSERT INTO #Expected (Class, TestCase, Name)
    VALUES ('MyClassName', 'MyTestCaseName', '[MyClassName].[MyTestCaseName]');
    
    SELECT Class, TestCase, Name
      INTO #Actual
      FROM tSQLt.TestResult;
    
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROC tSQLt_test.[test RunAll produces a test case summary]
AS
BEGIN
    EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;
    DELETE FROM tSQLt.TestResult;
    EXEC tSQLt.SpyProcedure 'tSQLt.Private_OutputTestResults';

    EXEC tSQLt.RunAll;

    DECLARE @CallCount INT;
    SELECT @CallCount = COUNT(1) FROM tSQLt.Private_OutputTestResults_SpyProcedureLog;
    EXEC tSQLt.AssertEquals 1, @CallCount;
END;
GO

CREATE PROC tSQLt_test.[test RunAll clears test results between each execution]
AS
BEGIN
    EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;
    DELETE FROM tSQLt.TestResult;
    
    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC ('CREATE PROC MyTestClass.test1 AS RETURN 0;');

    EXEC tSQLt.RunAll;
    EXEC tSQLt.RunAll;
    
    DECLARE @NumberOfTestResults INT;
    SELECT @NumberOfTestResults = COUNT(*)
      FROM tSQLt.TestResult;
    
    EXEC tSQLt.AssertEquals 1, @NumberOfTestResults;
END;
GO

CREATE PROC tSQLt_test.[test procedure can be injected to display test results]
AS
BEGIN
    EXEC ('CREATE SCHEMA MyFormatterSchema;');
    EXEC ('CREATE TABLE MyFormatterSchema.Log (i INT DEFAULT(1));');
    EXEC ('CREATE PROC MyFormatterSchema.MyFormatter AS INSERT INTO MyFormatterSchema.Log DEFAULT VALUES;');
    EXEC tSQLt.SetTestResultFormatter 'MyFormatterSchema.MyFormatter';
    
    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC ('CREATE PROC MyTestClass.testA AS RETURN 0;');
    
    EXEC tSQLt.Run 'MyTestClass';
    
    CREATE TABLE #Expected (i int DEFAULT(1));
    INSERT INTO #Expected DEFAULT VALUES;
    
    EXEC tSQLt.AssertEqualsTable 'MyFormatterSchema.Log', '#Expected';
END;
GO

CREATE PROC tSQLt_test.[test XmlResultFormatter creates <testsuites/> when no test cases in test suite]
AS
BEGIN
    EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;
    DELETE FROM tSQLt.TestResult;

    EXEC tSQLt.SetTestResultFormatter 'tSQLt.XmlResultFormatter';
    
    EXEC tSQLt.NewTestClass 'MyTestClass';
    
    EXEC tSQLt.RunAll;
    
    DECLARE @Actual NVARCHAR(MAX);
    SELECT @Actual = CAST(Message AS NVARCHAR(MAX)) FROM tSQLt.Private_PrintXML_SpyProcedureLog;

    EXEC tSQLt.AssertEqualsString '<testsuites/>', @Actual;
END;
GO

CREATE PROC tSQLt_test.[test XmlResultFormatter creates testsuite with test element when there is a passing test]
AS
BEGIN
    DECLARE @Actual NVARCHAR(MAX);
    DECLARE @XML XML;

    DELETE FROM tSQLt.TestResult;
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result)
    VALUES ('MyTestClass', 'testA', 'XYZ', 'Success');
    
    EXEC tSQLt.XmlResultFormatter;
    
    SELECT @XML = CAST(Message AS XML) FROM tSQLt.Private_PrintXML_SpyProcedureLog;
    SET @Actual = @XML.value('(/testsuites/testsuite/testcase/@name)[1]', 'NVARCHAR(MAX)');

    EXEC tSQLt.AssertEqualsString  'testA',@actual;
END;
GO   

CREATE PROC tSQLt_test.[test XmlResultFormatter handles even this:   ,/?'';:[o]]}\|{)(*&^%$#@""]
AS
BEGIN
    DECLARE @Actual NVARCHAR(MAX);
    DECLARE @XML XML;

    DELETE FROM tSQLt.TestResult;
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result)
    VALUES ('MyTestClass', ',/?'';:[o]}\|{)(*&^%$#@""', 'XYZ', 'Success');
    
    EXEC tSQLt.XmlResultFormatter;
    
    SELECT @XML = CAST(Message AS XML) FROM tSQLt.Private_PrintXML_SpyProcedureLog;
    SET @Actual = @XML.value('(/testsuites/testsuite/testcase/@name)[1]', 'NVARCHAR(MAX)');

    EXEC tSQLt.AssertEqualsString  ',/?'';:[o]}\|{)(*&^%$#@""',@actual;
END;
GO

CREATE PROC tSQLt_test.[test XmlResultFormatter creates testsuite with test element and failure element when there is a failing test]
AS
BEGIN
    DECLARE @Actual NVARCHAR(MAX);
    DECLARE @XML XML;

    DELETE FROM tSQLt.TestResult;
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result, Msg)
    VALUES ('MyTestClass', 'testA', 'XYZ', 'Failure', 'This test intentionally fails');
    
    EXEC tSQLt.XmlResultFormatter;
    
    SELECT @XML = CAST(Message AS XML) FROM tSQLt.Private_PrintXML_SpyProcedureLog;
    SET @Actual = @XML.value('(/testsuites/testsuite/testcase/failure/@message)[1]', 'NVARCHAR(MAX)');
    
    EXEC tSQLt.AssertEqualsString 'This test intentionally fails', @Actual;
END;
GO

CREATE PROC tSQLt_test.[test XmlResultFormatter creates testsuite with multiple test elements some with failures]
AS
BEGIN
    DECLARE @XML XML;

    DELETE FROM tSQLt.TestResult;
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result, Msg)
    VALUES ('MyTestClass', 'testA', 'XYZ', 'Failure', 'testA intentionally fails');
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result, Msg)
    VALUES ('MyTestClass', 'testB', 'XYZ', 'Success', NULL);
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result, Msg)
    VALUES ('MyTestClass', 'testC', 'XYZ', 'Failure', 'testC intentionally fails');
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result, Msg)
    VALUES ('MyTestClass', 'testD', 'XYZ', 'Success', NULL);
    
    EXEC tSQLt.XmlResultFormatter;
    
    SELECT @XML = CAST(Message AS XML) FROM tSQLt.Private_PrintXML_SpyProcedureLog;

    SELECT TestCase.value('@name','NVARCHAR(MAX)') AS TestCase, TestCase.value('failure[1]/@message','NVARCHAR(MAX)') AS Msg
    INTO #actual
    FROM @XML.nodes('/testsuites/testsuite/testcase') X(TestCase);
    
    
    SELECT TestCase,Msg
    INTO #expected
    FROM tSQLt.TestResult;
    
    EXEC tSQLt.AssertEqualsTable '#expected','#actual';
END;
GO

CREATE PROC tSQLt_test.[test XmlResultFormatter creates testsuite with multiple test elements some with failures or errors]
AS
BEGIN
    DECLARE @XML XML;

    DELETE FROM tSQLt.TestResult;
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result, Msg)
    VALUES ('MyTestClass', 'testA', 'XYZ', 'Failure', 'testA intentionally fails');
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result, Msg)
    VALUES ('MyTestClass', 'testB', 'XYZ', 'Success', NULL);
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result, Msg)
    VALUES ('MyTestClass', 'testC', 'XYZ', 'Failure', 'testC intentionally fails');
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result, Msg)
    VALUES ('MyTestClass', 'testD', 'XYZ', 'Error', 'testD intentionally errored');
    
    EXEC tSQLt.XmlResultFormatter;
    
    SELECT @XML = CAST(Message AS XML) FROM tSQLt.Private_PrintXML_SpyProcedureLog;

    SELECT 
      TestCase.value('@name','NVARCHAR(MAX)') AS Class,
      TestCase.value('@tests','NVARCHAR(MAX)') AS tests,
      TestCase.value('@failures','NVARCHAR(MAX)') AS failures,
      TestCase.value('@errors','NVARCHAR(MAX)') AS errors
    INTO #actual
    FROM @XML.nodes('/testsuites/testsuite') X(TestCase);
    
    
    SELECT N'MyTestClass' AS Class, 4 tests, 2 failures, 1 errors
    INTO #expected
    
    EXEC tSQLt.AssertEqualsTable '#expected','#actual';
END;
GO

CREATE PROC tSQLt_test.[test XmlResultFormatter sets correct counts in testsuite attributes]
AS
BEGIN
    DECLARE @XML XML;

    DELETE FROM tSQLt.TestResult;
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result, Msg)
    VALUES ('MyTestClass1', 'testA', 'XYZ', 'Failure', 'testA intentionally fails');
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result, Msg)
    VALUES ('MyTestClass1', 'testB', 'XYZ', 'Success', NULL);
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result, Msg)
    VALUES ('MyTestClass2', 'testC', 'XYZ', 'Failure', 'testC intentionally fails');
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result, Msg)
    VALUES ('MyTestClass2', 'testD', 'XYZ', 'Error', 'testD intentionally errored');
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result, Msg)
    VALUES ('MyTestClass2', 'testE', 'XYZ', 'Failure', 'testE intentionally fails');
    
    EXEC tSQLt.XmlResultFormatter;
    
    SELECT @XML = CAST(Message AS XML) FROM tSQLt.Private_PrintXML_SpyProcedureLog;

    SELECT 
      TestCase.value('@name','NVARCHAR(MAX)') AS Class,
      TestCase.value('@tests','NVARCHAR(MAX)') AS tests,
      TestCase.value('@failures','NVARCHAR(MAX)') AS failures,
      TestCase.value('@errors','NVARCHAR(MAX)') AS errors
    INTO #actual
    FROM @XML.nodes('/testsuites/testsuite') X(TestCase);
    
    
    SELECT *
    INTO #expected
    FROM (
      SELECT N'MyTestClass1' AS Class, 2 tests, 1 failures, 0 errors
      UNION ALL
      SELECT N'MyTestClass2' AS Class, 3 tests, 2 failures, 1 errors
    ) AS x;
    
    EXEC tSQLt.AssertEqualsTable '#expected','#actual';
END;
GO

CREATE PROC tSQLt_test.[test XmlResultFormatter arranges multiple test cases into testsuites]
AS
BEGIN
    DECLARE @XML XML;

    DELETE FROM tSQLt.TestResult;
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result, Msg)
    VALUES ('MyTestClass1', 'testA', 'XYZ', 'Failure', 'testA intentionally fails');
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result, Msg)
    VALUES ('MyTestClass1', 'testB', 'XYZ', 'Success', NULL);
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result, Msg)
    VALUES ('MyTestClass2', 'testC', 'XYZ', 'Failure', 'testC intentionally fails');
    INSERT INTO tSQLt.TestResult (Class, TestCase, TranName, Result, Msg)
    VALUES ('MyTestClass2', 'testD', 'XYZ', 'Error', 'testD intentionally errored');
    
    EXEC tSQLt.XmlResultFormatter;
    
    SELECT @XML = CAST(Message AS XML) FROM tSQLt.Private_PrintXML_SpyProcedureLog;

    SELECT 
      TestCase.value('../@name','NVARCHAR(MAX)') AS Class,
      TestCase.value('@name','NVARCHAR(MAX)') AS TestCase
    INTO #actual
    FROM @XML.nodes('/testsuites/testsuite/testcase') X(TestCase);
    
    
    SELECT Class,TestCase
    INTO #expected
    FROM tSQLt.TestResult;
    
    EXEC tSQLt.AssertEqualsTable '#expected','#actual';
END;
GO


CREATE PROC tSQLt_test.[test tSQLt.Private_GetSchemaId of schema name that does not exist returns null]
AS
BEGIN
	DECLARE @Actual INT;
	SELECT @Actual = tSQLt.Private_GetSchemaId('tSQLt_test my schema');

	EXEC tSQLt.AssertEquals NULL, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test tSQLt.Private_GetSchemaId of simple schema name returns id of schema]
AS
BEGIN
	DECLARE @Actual INT;
	DECLARE @Expected INT;
	SELECT @Expected = SCHEMA_ID('tSQLt_test');
	SELECT @Actual = tSQLt.Private_GetSchemaId('tSQLt_test');

	EXEC tSQLt.AssertEquals @Expected, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test tSQLt.Private_GetSchemaId of simple bracket quoted schema name returns id of schema]
AS
BEGIN
	DECLARE @Actual INT;
	DECLARE @Expected INT;
	SELECT @Expected = SCHEMA_ID('tSQLt_test');
	SELECT @Actual = tSQLt.Private_GetSchemaId('[tSQLt_test]');

	EXEC tSQLt.AssertEquals @Expected, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test tSQLt.Private_GetSchemaId returns id of schema with brackets in name if bracketed and unbracketed schema exists]
AS
BEGIN
	EXEC ('CREATE SCHEMA [[tSQLt_test]]];');

	DECLARE @Actual INT;
	DECLARE @Expected INT;
	SELECT @Expected = (SELECT schema_id FROM sys.schemas WHERE name='[tSQLt_test]');
	SELECT @Actual = tSQLt.Private_GetSchemaId('[tSQLt_test]');

	EXEC tSQLt.AssertEquals @Expected, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test tSQLt.Private_GetSchemaId returns id of schema without brackets in name if bracketed and unbracketed schema exists]
AS
BEGIN
	EXEC ('CREATE SCHEMA [[tSQLt_test]]];');

	DECLARE @Actual INT;
	DECLARE @Expected INT;
	SELECT @Expected = (SELECT schema_id FROM sys.schemas WHERE name='tSQLt_test');
	SELECT @Actual = tSQLt.Private_GetSchemaId('tSQLt_test');

	EXEC tSQLt.AssertEquals @Expected, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test tSQLt.Private_GetSchemaId returns id of schema without brackets in name if only unbracketed schema exists]
AS
BEGIN
	DECLARE @Actual INT;
	DECLARE @Expected INT;
	SELECT @Expected = (SELECT schema_id FROM sys.schemas WHERE name='tSQLt_test');
	SELECT @Actual = tSQLt.Private_GetSchemaId('[tSQLt_test]');

	EXEC tSQLt.AssertEquals @Expected, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test tSQLt.Private_GetSchemaId returns id of schema when quoted with double quotes]
AS
BEGIN
	DECLARE @Actual INT;
	DECLARE @Expected INT;
	SELECT @Expected = (SELECT schema_id FROM sys.schemas WHERE name='tSQLt_test');
	SELECT @Actual = tSQLt.Private_GetSchemaId('"tSQLt_test"');

	EXEC tSQLt.AssertEquals @Expected, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test tSQLt.Private_GetSchemaId returns id of double quoted schema when similar schema names exist]
AS
BEGIN
	EXEC ('CREATE SCHEMA [[tSQLt_test]]];');
	EXEC ('CREATE SCHEMA ["tSQLt_test"];');

	DECLARE @Actual INT;
	DECLARE @Expected INT;
	SELECT @Expected = (SELECT schema_id FROM sys.schemas WHERE name='"tSQLt_test"');
	SELECT @Actual = tSQLt.Private_GetSchemaId('"tSQLt_test"');

	EXEC tSQLt.AssertEquals @Expected, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test tSQLt.Private_GetSchemaId returns id of bracket quoted schema when similar schema names exist]
AS
BEGIN
	EXEC ('CREATE SCHEMA [[tSQLt_test]]];');
	EXEC ('CREATE SCHEMA ["tSQLt_test"];');

	DECLARE @Actual INT;
	DECLARE @Expected INT;
	SELECT @Expected = (SELECT schema_id FROM sys.schemas WHERE name='[tSQLt_test]');
	SELECT @Actual = tSQLt.Private_GetSchemaId('[tSQLt_test]');

	EXEC tSQLt.AssertEquals @Expected, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test tSQLt.Private_GetSchemaId returns id of unquoted schema when similar schema names exist]
AS
BEGIN
	EXEC ('CREATE SCHEMA [[tSQLt_test]]];');
	EXEC ('CREATE SCHEMA ["tSQLt_test"];');

	DECLARE @Actual INT;
	DECLARE @Expected INT;
	SELECT @Expected = (SELECT schema_id FROM sys.schemas WHERE name='tSQLt_test');
	SELECT @Actual = tSQLt.Private_GetSchemaId('tSQLt_test');

	EXEC tSQLt.AssertEquals @Expected, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test tSQLt.Private_GetSchemaId of schema name with spaces returns not null if not quoted]
AS
BEGIN
	EXEC ('CREATE SCHEMA [tSQLt_test my.schema];');
	DECLARE @Actual INT;
	DECLARE @Expected INT;
	SELECT @Expected = (SELECT schema_id FROM sys.schemas WHERE name='tSQLt_test my.schema');
	SELECT @Actual = tSQLt.Private_GetSchemaId('tSQLt_test my.schema');

	EXEC tSQLt.AssertEquals @Expected, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test Private_IsTestClass returns 0 if schema does not exist]
AS
BEGIN
	DECLARE @Actual BIT;
	SELECT @Actual = tSQLt.Private_IsTestClass('tSQLt_test_does_not_exist');
	EXEC tSQLt.AssertEquals 0, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test Private_IsTestClass returns 0 if schema does exist but is not a test class]
AS
BEGIN
	EXEC ('CREATE SCHEMA [tSQLt_test_notATestClass];');
	DECLARE @Actual BIT;
	SELECT @Actual = tSQLt.Private_IsTestClass('tSQLt_test_notATestClass');
	EXEC tSQLt.AssertEquals 0, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test Private_IsTestClass returns 1 if schema was created with NewTestClass]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'tSQLt_test_MyTestClass';
  DECLARE @Actual BIT;
  SELECT @Actual = tSQLt.Private_IsTestClass('tSQLt_test_MyTestClass');
  EXEC tSQLt.AssertEquals 1, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test Private_IsTestClass handles bracket quoted test class names]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'tSQLt_test_MyTestClass';
  DECLARE @Actual BIT;
  SELECT @Actual = tSQLt.Private_IsTestClass('[tSQLt_test_MyTestClass]');
  EXEC tSQLt.AssertEquals 1, @Actual;
END;
GO

CREATE PROC tSQLt_test.[test tSQLt.Run executes a test class even if there is a dbo owned object of the same name]
AS
BEGIN
  -- Assemble
  EXEC tSQLt.NewTestClass 'innertest';
  EXEC('CREATE PROC innertest.testMe as RETURN 0;');

  CREATE TABLE dbo.innertest(i INT);

  --Act
  EXEC tSQLt.Run 'innertest';

  --Assert
  SELECT Class, TestCase 
    INTO #Expected
    FROM tSQLt.TestResult
   WHERE 1=0;
   
  INSERT INTO #Expected(Class, TestCase)
  SELECT Class = 'innertest', TestCase = 'testMe';

  SELECT Class, TestCase
    INTO #Actual
    FROM tSQLt.TestResult;
    
  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';    
END;
GO

CREATE PROC tSQLt_test.[test tSQLt.Private_ResolveName returns mostly nulls if testname is null]
AS
BEGIN
  SELECT * --forcing this test to test all columns
    INTO #Actual 
    FROM tSQLt.Private_ResolveName(null);

  SELECT a.*
    INTO #Expected
    FROM #Actual a
   WHERE 0 = 1;

  INSERT INTO #Expected 
    (schemaId, objectId, quotedSchemaName, quotedObjectName, quotedFullName, isTestClass, isTestCase, isSchema)
  VALUES
    (NULL, NULL, NULL, NULL, NULL, 0, 0, 0);

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual'
END;
GO

CREATE PROC tSQLt_test.[test tSQLt.Private_ResolveName if testname does not exist returns same info as if testname was null]
AS
BEGIN
  SELECT *
    INTO #Actual 
    FROM tSQLt.Private_ResolveName('NeitherAnObjectNorASchema');

  SELECT *
    INTO #Expected
    FROM tSQLt.Private_ResolveName(null);

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual'
END;
GO

--tSQLt.Private_ResolveTestName(testname)
--returns table
--->bit(class or name),
--  schema_id,
--  object_id (null if testname is a class),
--  quoted schema name,
--  quoted object name (null if testname is a class),
--  quoted full name (quoted schema name if testname is a class)
  
  
--x testname is null
--x testname cannot be resolved
--x testname is a schema name created with NewTestClass
--x testname is a schema name not created with NewTestClass
--x testname is a quoted schema name
--x testname is an object name that is a procedure and a test
--x testname is an object name that is not a procedure
--x testname is an object name that is a procedure but not a test
--x testname is a schema.object name
--x testname is a schema.object name, quoted
--x testname is a [schema.object] name, where dbo.[schema.object] exists and [schema].[object] exists
--testname is a schema name but also an object of the same name exists in dbo
--name is [test schema].[no test]

CREATE PROC tSQLt_test.[test tSQLt.Private_ResolveName returns only schema info if testname is a schema created with CREATE SCHEMA]
AS
BEGIN
  EXEC ('CREATE SCHEMA InnerSchema');

  SELECT schemaId, objectId, quotedSchemaName, quotedObjectName, quotedFullName, isTestClass, isTestCase, isSchema
    INTO #Actual 
    FROM tSQLt.Private_ResolveName('InnerSchema');

  SELECT a.*
    INTO #Expected
    FROM #Actual a
   WHERE 0 = 1;

  INSERT INTO #Expected 
    (schemaId, objectId, quotedSchemaName, quotedObjectName, quotedFullName, isTestClass, isTestCase, isSchema)
  VALUES
    (SCHEMA_ID('InnerSchema'), NULL, '[InnerSchema]', NULL, '[InnerSchema]', 0, 0, 1);

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual'
END;
GO

CREATE PROC tSQLt_test.[test tSQLt.Private_ResolveName identifies a test class]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'InnerTest';

  SELECT isTestClass, isTestCase, isSchema
    INTO #Actual 
    FROM tSQLt.Private_ResolveName('InnerTest');

  SELECT a.*
    INTO #Expected
    FROM #Actual a
   WHERE 0 = 1;

  INSERT INTO #Expected 
    (isTestClass, isTestCase, isSchema)
  VALUES
    (1, 0, 1);

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual'
END;
GO

CREATE PROC tSQLt_test.[test tSQLt.Private_ResolveName identifies a quoted test class name]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'InnerTest';

  SELECT schemaId
    INTO #Actual 
    FROM tSQLt.Private_ResolveName('[InnerTest]');

  SELECT a.*
    INTO #Expected
    FROM #Actual a
   WHERE 0 = 1;

  INSERT INTO #Expected 
    (schemaId)
  VALUES
    (SCHEMA_ID('InnerTest'));

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual'
END;
GO

CREATE PROC tSQLt_test.[test tSQLt.Private_ResolveName return info for fully qualified object]
AS
BEGIN
  EXEC ('CREATE SCHEMA InnerSchema');
  EXEC ('CREATE TABLE InnerSchema.TestObject(i INT)');

  SELECT schemaId, objectId, quotedSchemaName, quotedObjectName, quotedFullName, isTestClass, isTestCase, isSchema
    INTO #Actual 
    FROM tSQLt.Private_ResolveName('InnerSchema.TestObject');

  SELECT a.*
    INTO #Expected
    FROM #Actual a
   WHERE 0 = 1;

  INSERT INTO #Expected 
    (schemaId, objectId, quotedSchemaName, quotedObjectName, quotedFullName, isTestClass, isTestCase, isSchema)
  VALUES
    (SCHEMA_ID('InnerSchema'), OBJECT_ID('InnerSchema.TestObject'), '[InnerSchema]', '[TestObject]', '[InnerSchema].[TestObject]', 0, 0, 0);

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual'
END;
GO

CREATE PROC tSQLt_test.[test tSQLt.Private_ResolveName interprets object name correctly if schema of same name exists]
AS
BEGIN
  EXEC ('CREATE SCHEMA InnerSchema1');
  EXEC ('CREATE SCHEMA InnerSchema2');
  EXEC ('CREATE TABLE InnerSchema1.InnerSchema2(i INT)');

  SELECT schemaId, objectId, quotedSchemaName, quotedObjectName, quotedFullName, isTestClass, isTestCase, isSchema
    INTO #Actual 
    FROM tSQLt.Private_ResolveName('InnerSchema1.InnerSchema2');

  SELECT a.*
    INTO #Expected
    FROM #Actual a
   WHERE 0 = 1;

  INSERT INTO #Expected 
    (schemaId, objectId, quotedSchemaName, quotedObjectName, quotedFullName, isTestClass, isTestCase, isSchema)
  VALUES
    (SCHEMA_ID('InnerSchema1'), OBJECT_ID('InnerSchema1.InnerSchema2'), '[InnerSchema1]', '[InnerSchema2]', '[InnerSchema1].[InnerSchema2]', 0, 0, 0);

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual'
END;
GO

CREATE PROC tSQLt_test.[test tSQLt.Private_ResolveName return info for fully qualified quoted object]
AS
BEGIN
  EXEC ('CREATE SCHEMA InnerSchema');
  EXEC ('CREATE TABLE InnerSchema.TestObject(i INT)');

  SELECT schemaId, objectId
    INTO #Actual 
    FROM tSQLt.Private_ResolveName('[InnerSchema].[TestObject]');

  SELECT a.*
    INTO #Expected
    FROM #Actual a
   WHERE 0 = 1;

  INSERT INTO #Expected 
    (schemaId, objectId)
  VALUES
    (SCHEMA_ID('InnerSchema'), OBJECT_ID('InnerSchema.TestObject'));

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual'
END;
GO

CREATE PROC tSQLt_test.[test tSQLt.Private_ResolveName for TestProcedure]
AS
BEGIN
  EXEC ('CREATE SCHEMA InnerSchema');
  EXEC ('CREATE Procedure InnerSchema.[test inside] AS RETURN 0;');

  SELECT isTestClass, isTestCase
    INTO #Actual 
    FROM tSQLt.Private_ResolveName('InnerSchema.[test inside]');

  SELECT a.*
    INTO #Expected
    FROM #Actual a
   WHERE 0 = 1;

  INSERT INTO #Expected 
    (isTestClass, isTestCase)
  VALUES
    (0, 1);

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual'
END;
GO

CREATE PROC tSQLt_test.[test tSQLt.Private_ResolveName for procedure that is not a test]
AS
BEGIN
  EXEC ('CREATE SCHEMA InnerSchema');
  EXEC ('CREATE Procedure InnerSchema.[NOtest inside] AS RETURN 0;');

  SELECT isTestCase
    INTO #Actual 
    FROM tSQLt.Private_ResolveName('InnerSchema.[NOtest inside]');

  SELECT a.*
    INTO #Expected
    FROM #Actual a
   WHERE 0 = 1;

  INSERT INTO #Expected 
    (isTestCase)
  VALUES
    (0);

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual'
END;
GO

CREATE PROC tSQLt_test.[test Private_ResolveName: name is a quoted {schema.object} name, where dbo.{schema.object} exists and {schema}.{object} exists]
AS
BEGIN
  EXEC ('CREATE SCHEMA InnerSchema');
  EXEC ('CREATE TABLE InnerSchema.TestObject(i INT)');
  EXEC ('CREATE TABLE dbo.[InnerSchema.TestObject](i INT)');

  SELECT schemaId, objectId
    INTO #Actual 
    FROM tSQLt.Private_ResolveName('[InnerSchema.TestObject]');

  SELECT a.*
    INTO #Expected
    FROM #Actual a
   WHERE 0 = 1;

  INSERT INTO #Expected 
    (schemaId, objectId)
  VALUES
    (SCHEMA_ID('dbo'), OBJECT_ID('dbo.[InnerSchema.TestObject]'));

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual'
END;
GO

CREATE PROC tSQLt_test.[test Private_ResolveName: name is a quoted {schema}.{object} name, where dbo.{schema.object} exists and {schema}.{object} exists]
AS
BEGIN
  EXEC ('CREATE SCHEMA InnerSchema');
  EXEC ('CREATE TABLE InnerSchema.TestObject(i INT)');
  EXEC ('CREATE TABLE dbo.[InnerSchema.TestObject](i INT)');

  SELECT schemaId, objectId
    INTO #Actual 
    FROM tSQLt.Private_ResolveName('[InnerSchema].[TestObject]');

  SELECT a.*
    INTO #Expected
    FROM #Actual a
   WHERE 0 = 1;

  INSERT INTO #Expected 
    (schemaId, objectId)
  VALUES
    (SCHEMA_ID('InnerSchema'), OBJECT_ID('[InnerSchema].[TestObject]'));

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual'
END;
GO

CREATE PROC tSQLt_test.[test Private_ResolveName: name is a schema name where an object of same name exists in dbo]
AS
BEGIN
  EXEC ('CREATE SCHEMA InnerSchema');
  EXEC ('CREATE TABLE dbo.InnerSchema(i INT)');

  SELECT schemaId, objectId
    INTO #Actual 
    FROM tSQLt.Private_ResolveName('InnerSchema');

  SELECT a.*
    INTO #Expected
    FROM #Actual a
   WHERE 0 = 1;

  INSERT INTO #Expected 
    (schemaId, objectId)
  VALUES
    (SCHEMA_ID('InnerSchema'), NULL);

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual'
END;
GO

CREATE PROC tSQLt_test.[test CreateUniqueObjectName creates a new object name that is not in sys.objects]
AS
BEGIN
  DECLARE @ObjectName NVARCHAR(MAX);
  SET @ObjectName = tSQLt.Private::CreateUniqueObjectName();
  
  IF EXISTS (SELECT 1 FROM sys.objects WHERE NAME = @ObjectName)
  BEGIN
    EXEC tSQLt.Fail 'Created object name already exists in sys.objects, object name: ', @ObjectName;
  END
END;
GO

CREATE PROC tSQLt_test.[test CreateUniqueObjectName creates a new object name that has not been previously generated]
AS
BEGIN
  DECLARE @ObjectName NVARCHAR(MAX);
  SET @ObjectName = tSQLt.Private::CreateUniqueObjectName();
  
  IF (@ObjectName = tSQLt.Private::CreateUniqueObjectName())
  BEGIN
    EXEC tSQLt.Fail 'Created object name was created twice, object name: ', @ObjectName;
  END
END;
GO

CREATE PROC tSQLt_test.[test CreateUniqueObjectName creates a name which can be used to create a table]
AS
BEGIN
  DECLARE @ObjectName NVARCHAR(MAX);
  SELECT @ObjectName = tSQLt.Private::CreateUniqueObjectName();
  
  EXEC ('CREATE TABLE tSQLt_test.' + @ObjectName + '(i INT);');
END
GO

CREATE PROC tSQLt_test.[test Private_Print handles % signs]
AS
BEGIN
  DECLARE @msg NVARCHAR(MAX);
  SET @msg = 'No Message';
  BEGIN TRY
    EXEC tSQLt.Private_Print 'hello % goodbye', 16;
  END TRY
  BEGIN CATCH
    SET @msg = ERROR_MESSAGE();
  END CATCH
  
  EXEC tSQLt.AssertEqualsString 'hello % goodbye', @msg;
END;
GO

CREATE PROCEDURE tSQLt_test.[test Fail places parameters in correct order]
AS
BEGIN
    BEGIN TRY
        EXEC tSQLt.Fail 1, 2, 3, 4, 5, 6, 7, 8, 9, 0;
    END TRY
    BEGIN CATCH
    END CATCH
    
    SELECT '{' + Msg + '}' AS BracedMsg
      INTO #actual
      FROM tSQLt.TestMessage;
      
    SELECT TOP(0) *
      INTO #expected
      FROM #actual;
      
    INSERT INTO #expected (BracedMsg) VALUES ('{1234567890}');
    
    EXEC tSQLt.AssertEqualsTable '#expected', '#actual';
END;
GO

CREATE PROCEDURE tSQLt_test.[test Fail handles NULL parameters]
AS
BEGIN
    BEGIN TRY
        EXEC tSQLt.Fail NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL;
    END TRY
    BEGIN CATCH
    END CATCH
    
    SELECT '{' + Msg + '}' AS BracedMsg
      INTO #actual
      FROM tSQLt.TestMessage;
      
    SELECT TOP(0) *
      INTO #expected
      FROM #actual;
      
    INSERT INTO #expected (BracedMsg) VALUES ('{!NULL!!NULL!!NULL!!NULL!!NULL!!NULL!!NULL!!NULL!!NULL!!NULL!}');
    
    EXEC tSQLt.AssertEqualsTable '#expected', '#actual';
END;
GO

CREATE PROCEDURE tSQLt_test.[test tSQLt.TestClasses returns no test classes when there are no test classes]
AS
BEGIN
  EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;

  SELECT *
    INTO #Actual
    FROM tSQLt.TestClasses;
    
  SELECT TOP(0) * 
    INTO #Expected
    FROM #Actual;
    
  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE tSQLt_test.[test tSQLt.TestClasses returns single test class]
AS
BEGIN
  EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;
  EXEC tSQLt.NewTestClass 'tSQLt_test_dummy_A';

  SELECT Name
    INTO #Actual
    FROM tSQLt.TestClasses;
    
  SELECT TOP(0) * 
    INTO #Expected
    FROM #Actual;
  
  INSERT INTO #Expected(Name) VALUES ('tSQLt_test_dummy_A');
    
  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE tSQLt_test.[test tSQLt.TestClasses returns multiple test classes]
AS
BEGIN
  EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;
  EXEC tSQLt.NewTestClass 'tSQLt_test_dummy_A';
  EXEC tSQLt.NewTestClass 'tSQLt_test_dummy_B';

  SELECT Name
    INTO #Actual
    FROM tSQLt.TestClasses;
    
  SELECT TOP(0) * 
    INTO #Expected
    FROM #Actual;
  
  INSERT INTO #Expected(Name) VALUES ('tSQLt_test_dummy_A');
  INSERT INTO #Expected(Name) VALUES ('tSQLt_test_dummy_B');
    
  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE tSQLt_test.[test tSQLt.TestClasses returns other important columns]
AS
BEGIN
  EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;
  EXEC tSQLt.NewTestClass 'tSQLt_test_dummy_A';

  SELECT Name,SchemaId
    INTO #Actual
    FROM tSQLt.TestClasses;
    
  SELECT TOP(0) * 
    INTO #Expected
    FROM #Actual;
  
  INSERT INTO #Expected(Name, SchemaId) VALUES ('tSQLt_test_dummy_A',SCHEMA_ID('tSQLt_test_dummy_A'));
    
  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE tSQLt_test.[test tSQLt.Tests returns no tests when there are no test classes]
AS
BEGIN
  EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;

  SELECT *
    INTO #Actual
    FROM tSQLt.Tests;
    
  SELECT TOP(0) * 
    INTO #Expected
    FROM #Actual;
    
  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE tSQLt_test.[test tSQLt.Tests returns one test on a test class]
AS
BEGIN
  EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;
  
  EXEC tSQLt.NewTestClass 'tSQLt_test_dummy_A';
  EXEC ('CREATE PROCEDURE tSQLt_test_dummy_A.testA AS RETURN 0;');

  SELECT Name
    INTO #Actual
    FROM tSQLt.Tests;
    
  SELECT TOP(0) * 
    INTO #Expected
    FROM #Actual;
    
  INSERT INTO #Expected (Name) VALUES ('testA');
    
  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE tSQLt_test.[test tSQLt.Tests returns no test on an empty test class]
AS
BEGIN
  EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;
  
  EXEC tSQLt.NewTestClass 'tSQLt_test_dummy_A';

  SELECT Name
    INTO #Actual
    FROM tSQLt.Tests;
    
  SELECT TOP(0) * 
    INTO #Expected
    FROM #Actual;
        
  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE tSQLt_test.[test tSQLt.Tests returns no tests when there is only a helper procedure]
AS
BEGIN
  EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;
  
  EXEC tSQLt.NewTestClass 'tSQLt_test_dummy_A';
  EXEC ('CREATE PROCEDURE tSQLt_test_dummy_A.xyz AS RETURN 0;');

  SELECT Name
    INTO #Actual
    FROM tSQLt.Tests;
    
  SELECT TOP(0) * 
    INTO #Expected
    FROM #Actual;
        
  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE tSQLt_test.[test tSQLt.Tests recognizes all TeSt spellings]
AS
BEGIN
  EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;
  
  EXEC tSQLt.NewTestClass 'tSQLt_test_dummy_A';
  EXEC ('CREATE PROCEDURE tSQLt_test_dummy_A.Test AS RETURN 0;');
  EXEC ('CREATE PROCEDURE tSQLt_test_dummy_A.TEST AS RETURN 0;');
  EXEC ('CREATE PROCEDURE tSQLt_test_dummy_A.tEsT AS RETURN 0;');

  SELECT Name
    INTO #Actual
    FROM tSQLt.Tests;
    
  SELECT TOP(0) * 
    INTO #Expected
    FROM #Actual;

  INSERT INTO #Expected (Name) VALUES ('Test');
  INSERT INTO #Expected (Name) VALUES ('TEST');
  INSERT INTO #Expected (Name) VALUES ('tEsT');
        
  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE tSQLt_test.[test tSQLt.Tests returns tests from multiple test classes]
AS
BEGIN
  EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;
  
  EXEC tSQLt.NewTestClass 'tSQLt_test_dummy_A';
  EXEC ('CREATE PROCEDURE tSQLt_test_dummy_A.test AS RETURN 0;');

  EXEC tSQLt.NewTestClass 'tSQLt_test_dummy_B';
  EXEC ('CREATE PROCEDURE tSQLt_test_dummy_B.test AS RETURN 0;');

  SELECT TestClassName, Name
    INTO #Actual
    FROM tSQLt.Tests;
    
  SELECT TOP(0) * 
    INTO #Expected
    FROM #Actual;

  INSERT INTO #Expected (TestClassName, Name) VALUES ('tSQLt_test_dummy_A', 'test');
  INSERT INTO #Expected (TestClassName, Name) VALUES ('tSQLt_test_dummy_B', 'test');
        
  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE tSQLt_test.[test tSQLt.Tests returns multiple tests from multiple test classes]
AS
BEGIN
  EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;
  
  EXEC tSQLt.NewTestClass 'tSQLt_test_dummy_A';
  EXEC ('CREATE PROCEDURE tSQLt_test_dummy_A.test1 AS RETURN 0;');
  EXEC ('CREATE PROCEDURE tSQLt_test_dummy_A.test2 AS RETURN 0;');

  EXEC tSQLt.NewTestClass 'tSQLt_test_dummy_B';
  EXEC ('CREATE PROCEDURE tSQLt_test_dummy_B.test3 AS RETURN 0;');
  EXEC ('CREATE PROCEDURE tSQLt_test_dummy_B.test4 AS RETURN 0;');
  EXEC ('CREATE PROCEDURE tSQLt_test_dummy_B.test5 AS RETURN 0;');

  SELECT TestClassName, Name
    INTO #Actual
    FROM tSQLt.Tests;
    
  SELECT TOP(0) * 
    INTO #Expected
    FROM #Actual;

  INSERT INTO #Expected (TestClassName, Name) VALUES ('tSQLt_test_dummy_A', 'test1');
  INSERT INTO #Expected (TestClassName, Name) VALUES ('tSQLt_test_dummy_A', 'test2');
  INSERT INTO #Expected (TestClassName, Name) VALUES ('tSQLt_test_dummy_B', 'test3');
  INSERT INTO #Expected (TestClassName, Name) VALUES ('tSQLt_test_dummy_B', 'test4');
  INSERT INTO #Expected (TestClassName, Name) VALUES ('tSQLt_test_dummy_B', 'test5');
        
  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO


CREATE PROCEDURE tSQLt_test.[test tSQLt.Tests returns relevant ids with tests]
AS
BEGIN
  EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;
  
  EXEC tSQLt.NewTestClass 'tSQLt_test_dummy_A';
  EXEC ('CREATE PROCEDURE tSQLt_test_dummy_A.test1 AS RETURN 0;');

  SELECT SchemaId, ObjectId
    INTO #Actual
    FROM tSQLt.Tests;
    
  SELECT TOP(0) * 
    INTO #Expected
    FROM #Actual;

  INSERT INTO #Expected (SchemaId, ObjectId) VALUES (SCHEMA_ID('tSQLt_test_dummy_A'), OBJECT_ID('tSQLt_test_dummy_A.test1'));
        
  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE tSQLt_test.[test Uninstall removes schema tSQLt]
AS
BEGIN
  EXEC tSQLt.Uninstall;
  
  IF SCHEMA_ID('tSQLt') IS NOT NULL
  BEGIN
    RAISERROR ('tSQLt schema not removed', 16, 10);
  END;
END;
GO

CREATE PROCEDURE tSQLt_test.[test Uninstall removes data type tSQLt.Private]
AS
BEGIN
  EXEC tSQLt.Uninstall;
  
  IF TYPE_ID('tSQLt.Private') IS NOT NULL
  BEGIN
    RAISERROR ('tSQLt.Private data type not removed', 16, 10);
  END;
END;
GO

CREATE PROCEDURE tSQLt_test.[test Uninstall removes the tSQLt Assembly]
AS
BEGIN
  EXEC tSQLt.Uninstall;
  
  IF EXISTS (SELECT 1 FROM sys.assemblies WHERE name = 'tSQLtCLR')
  BEGIN
    RAISERROR ('tSQLtCLR assembly not removed', 16, 10);
  END;
END;
GO

CREATE PROCEDURE tSQLt_test.[test Run calls Private_Run with configured Test Result Formatter]
AS
BEGIN
  EXEC tSQLt.SpyProcedure 'tSQLt.Private_Run';
  EXEC tSQLt.Private_RenameObjectToUniqueName @SchemaName='tSQLt',@ObjectName='GetTestResultFormatter';
  EXEC('CREATE FUNCTION tSQLt.GetTestResultFormatter() RETURNS NVARCHAR(MAX) AS BEGIN RETURN ''CorrectResultFormatter''; END;');
 
  EXEC tSQLt.Run 'SomeTest';
  
  SELECT TestName,TestResultFormatter
    INTO #Actual
    FROM tSQLt.Private_Run_SpyProcedureLog;
    
  SELECT TOP(0) * INTO #Expected FROM #Actual;
  INSERT INTO #expected(TestName,TestResultFormatter)VALUES('SomeTest','CorrectResultFormatter');
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

CREATE PROCEDURE tSQLt_test.[test Private_Run calls tSQLt.Private_OutputTestResults with passed in TestResultFormatter]
AS
BEGIN
  EXEC tSQLt.SpyProcedure 'tSQLt.Private_OutputTestResults';
  
  EXEC tSQLt.Private_Run 'NoTestSchema.NoTest','SomeTestResultFormatter';
  
  SELECT TestResultFormatter
    INTO #Actual
    FROM tSQLt.Private_OutputTestResults_SpyProcedureLog;
    
  SELECT TOP(0) * INTO #Expected FROM #Actual;
  INSERT INTO #Expected(TestResultFormatter)VALUES('SomeTestResultFormatter');
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

CREATE PROCEDURE tSQLt_test.[test Private_OutputTestResults uses the TestResultFormatter parameter]
AS
BEGIN
  EXEC('CREATE PROC tSQLt_test.TemporaryTestResultFormatter AS RAISERROR(''GotHere'',16,10);');
  
  BEGIN TRY
    EXEC tSQLt.Private_OutputTestResults 'tSQLt_test.TemporaryTestResultFormatter';
  END TRY
  BEGIN CATCH
    IF(ERROR_MESSAGE() LIKE '%GotHere%') RETURN 0;
  END CATCH
  EXEC tSQLt.Fail 'tSQLt_test.TemporaryTestResultFormatter did not get called correctly';
END;
GO

CREATE PROCEDURE tSQLt_test.[test RunAll calls Private_RunAll with configured Test Result Formatter]
AS
BEGIN
  EXEC tSQLt.SpyProcedure 'tSQLt.Private_RunAll';
  EXEC tSQLt.Private_RenameObjectToUniqueName @SchemaName='tSQLt',@ObjectName='GetTestResultFormatter';
  EXEC('CREATE FUNCTION tSQLt.GetTestResultFormatter() RETURNS NVARCHAR(MAX) AS BEGIN RETURN ''CorrectResultFormatter''; END;');
 
  EXEC tSQLt.RunAll;
  
  SELECT TestResultFormatter
    INTO #Actual
    FROM tSQLt.Private_RunAll_SpyProcedureLog;
    
  SELECT TOP(0) * INTO #Expected FROM #Actual;
  INSERT INTO #Expected(TestResultFormatter) VALUES ('CorrectResultFormatter');
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

CREATE PROCEDURE tSQLt_test.[test Private_RunAll calls tSQLt.Private_OutputTestResults with passed in TestResultFormatter]
AS
BEGIN
  EXEC tSQLt.SpyProcedure 'tSQLt.Private_OutputTestResults';
  EXEC tSQLt.SpyProcedure 'tSQLt.Private_RunTestClass';
  
  EXEC tSQLt.Private_RunAll 'SomeTestResultFormatter';
  
  SELECT TestResultFormatter
    INTO #Actual
    FROM tSQLt.Private_OutputTestResults_SpyProcedureLog;
    
  SELECT TOP(0) * INTO #Expected FROM #Actual;
  INSERT INTO #Expected(TestResultFormatter)VALUES('SomeTestResultFormatter');
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

CREATE PROCEDURE tSQLt_test.[test RunWithXmlResults calls Private_Run with XmlTestResultFormatter]
AS
BEGIN
  EXEC tSQLt.SpyProcedure 'tSQLt.Private_Run';
 
  EXEC tSQLt.RunWithXmlResults 'SomeTest';
  
  SELECT TestName,TestResultFormatter
    INTO #Actual
    FROM tSQLt.Private_Run_SpyProcedureLog;
    
  SELECT TOP(0) * INTO #Expected FROM #Actual;
  INSERT INTO #expected(TestName,TestResultFormatter)VALUES('SomeTest','tSQLt.XmlResultFormatter');
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

CREATE PROCEDURE tSQLt_test.[test RunWithXmlResults passes NULL as TestName if called without parmameters]
AS
BEGIN
  EXEC tSQLt.SpyProcedure 'tSQLt.Private_Run';
 
  EXEC tSQLt.RunWithXmlResults;
  
  SELECT TestName
    INTO #Actual
    FROM tSQLt.Private_Run_SpyProcedureLog;
    
  SELECT TOP(0) * INTO #Expected FROM #Actual;
  INSERT INTO #expected(TestName)VALUES(NULL);
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO

--ROLLBACK
--tSQLt_test