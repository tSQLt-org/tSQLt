DECLARE @msg VARCHAR(MAX);SELECT @msg = 'Compiled at '+CONVERT(VARCHAR,GETDATE(),121);RAISERROR(@msg,0,1);
GO
EXEC tSQLt.DropClass tSQLt_testutil;
GO

CREATE SCHEMA tSQLt_testutil;
GO

CREATE PROC tSQLt_testutil.assertFailCalled
    @command NVARCHAR(MAX),
    @message VARCHAR(MAX)
AS
BEGIN
    DECLARE @CallCount INT;
    BEGIN TRAN;
    DECLARE @TranName CHAR(32); EXEC tSQLt.getNewTranName @TranName OUT;
    SAVE TRAN @TranName;
      EXEC tSQLt.SpyProcedure 'tSQLt.Fail';
      EXEC (@command);
      SELECT @CallCount = COUNT(1) FROM tSQLt.Fail_SpyProcedureLog;
    ROLLBACK TRAN @TranName;
    COMMIT TRAN;

    IF (@CallCount = 0)
    BEGIN
      EXEC tSQLt.Fail @message;
    END;
END;
GO
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
EXEC tSQLt.DropClass tSQLt_test;
GO

CREATE SCHEMA tSQLt_test;
GO

CREATE PROC tSQLt_test.test_TestCasesAreWrappedInTransactions
AS
BEGIN
    DECLARE @actualTranCount INT;

    BEGIN TRAN;
    DECLARE @TranName CHAR(32); EXEC tSQLt.getNewTranName @TranName OUT;
    SAVE TRAN @TranName;

    EXEC ('CREATE PROC TestCaseA AS IF(@@TRANCOUNT < 2) RAISERROR(''TranCountMisMatch:%i'',16,10,@@TRANCOUNT);');

    EXEC tSQLt.private_RunTest TestCaseA;

    SELECT @actualTranCount=CAST(SUBSTRING(Msg,19,100) AS INT) FROM tSQLt.TestResult WHERE Msg LIKE 'TranCountMisMatch:%';

    ROLLBACK TRAN @TranName;
    COMMIT;

    IF (@actualTranCount IS NOT NULL)
    BEGIN
        DECLARE @message VARCHAR(MAX);
        SET @message = 'Expected 2 transactions but was '+CAST(@actualTranCount AS VARCHAR);

        EXEC tSQLt.Fail @message;
    END;
END;
GO

CREATE PROC tSQLt_test.test_RunTest_truncates_TestResult_table
AS
BEGIN
    INSERT tSQLt.TestResult(Name, TranName) VALUES('TestCaseDummy','');

    EXEC ('CREATE PROC TestCaseA AS IF(EXISTS(SELECT 1 FROM tSQLt.TestResult WHERE Name = ''TestCaseDummy'')) RAISERROR(''NoTruncationError'',16,10);');

    EXEC tSQLt.RunTest TestCaseA;

    IF(EXISTS(SELECT 1 FROM tSQLt.TestResult WHERE Msg LIKE '%NoTruncationError%'))
    BEGIN
        EXEC tSQLt.Fail 'tSQLt.RunTest did not truncate tSQLt.TestResult!';
    END;
END;
GO

CREATE PROC tSQLt_test.test_RunTestClass_truncates_TestResult_table
AS
BEGIN
    INSERT tSQLt.TestResult(Name, TranName) VALUES('TestCaseDummy','');

    EXEC('CREATE SCHEMA MyTestClass;');
    EXEC('CREATE PROC MyTestClass.TestCaseA AS IF(EXISTS(SELECT 1 FROM tSQLt.TestResult WHERE Name = ''TestCaseDummy'')) RAISERROR(''NoTruncationError'',16,10);');

    EXEC tSQLt.RunTestClass MyTestClass;
   
    IF(EXISTS(SELECT 1 FROM tSQLt.TestResult WHERE Msg LIKE '%NoTruncationError%'))
    BEGIN
        EXEC tSQLt.Fail 'tSQLt.RunTest did not truncate tSQLt.TestResult!';
    END;
END;
GO

CREATE PROC tSQLt_test.test_RunTestClass_raises_error_if_failure
AS
BEGIN
    DECLARE @errorRaised INT; SET @errorRaised = 0;

    EXEC('CREATE SCHEMA MyTestClass;');
    EXEC('CREATE PROC MyTestClass.TestCaseA AS EXEC tSQLt.fail ''This is an expected failure''');
    
    BEGIN TRY
        EXEC tSQLt.RunTestClass MyTestClass;
    END TRY
    BEGIN CATCH
        SET @errorRaised = 1;
    END CATCH
    IF(@errorRaised = 0)
    BEGIN
        EXEC tSQLt.Fail 'tSQLt.RunTestClass did not raise an error!';
    END
END;
GO

CREATE PROC tSQLt_test.test_RunTestClass_raises_error_if_error
AS
BEGIN
    DECLARE @errorRaised INT; SET @errorRaised = 0;

    EXEC('CREATE SCHEMA MyTestClass;');
    EXEC('CREATE PROC MyTestClass.TestCaseA AS RETURN 1/0;');
    
    BEGIN TRY
        EXEC tSQLt.RunTestClass MyTestClass;
    END TRY
    BEGIN CATCH
        SET @errorRaised = 1;
    END CATCH
    IF(@errorRaised = 0)
    BEGIN
        EXEC tSQLt.Fail 'tSQLt.RunTestClass did not raise an error!';
    END
END;
GO

CREATE PROC tSQLt_test.test_RunTestClass_returns_resultset_with_failing_testcase_names
AS
BEGIN
    DECLARE @errorRaised INT; SET @errorRaised = 0;

    --EXEC('CREATE SCHEMA MyTestClass;');
    --EXEC('CREATE PROC MyTestClass.TestCaseA AS RAISERROR(''GotHere'',16,10);');
    
    --SELECT Name, Result, Msg
    --  INTO #tmp
    --  FROM tSQLt.TestResult
    -- WHERE 1=0;
     
    --BEGIN TRY
    --    INSERT INTO #tmp(Name, Result, Msg)
    --      EXEC tSQLt.RunTestClass MyTestClass;
    --END TRY
    --BEGIN CATCH
    --    SET @errorRaised = 1;
    --END CATCH

    --SELECT Name, Result--, Msg
    --  INTO actual
    --  FROM #tmp;

    --SELECT '[MyTestClass].[TestCaseA]' Name, 'Error' Result--, 'GotHere{Test Case A,1}' Msg
    --  INTO expected;
    
    --EXEC tSQLt.AssertEqualsTable 'expected', 'actual';
END;
GO

CREATE PROC tSQLt_test.test_RunTest_handles_test_names_with_spaces
AS
BEGIN
    DECLARE @errorRaised INT; SET @errorRaised = 0;

    EXEC('CREATE SCHEMA MyTestClass;');
    EXEC('CREATE PROC MyTestClass.[Test Case A] AS RAISERROR(''GotHere'',16,10);');
    
    BEGIN TRY
        EXEC tSQLt.RunTest 'MyTestClass.Test Case A';
    END TRY
    BEGIN CATCH
        SET @errorRaised = 1;
    END CATCH
    SELECT Name, Msg 
      INTO actual
      FROM tSQLt.TestResult;
    SELECT '[MyTestClass].[Test Case A]' Name, 'GotHere{Test Case A,1}' Msg
      INTO expected;
    
    EXEC tSQLt.AssertEqualsTable 'expected', 'actual';
END;
GO


CREATE PROC tSQLt_test.test_SpyProcedure_shouldAllowTesterToNotExecuteBehaviorOfProcedure
AS
BEGIN

    EXEC('CREATE PROC dbo.InnerProcedure AS EXEC tSQLt.Fail ''Original InnerProcedure was executed'';');

    EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure';

    EXEC dbo.InnerProcedure;

END;
GO

CREATE PROC tSQLt_test.test_SpyProcedure_shouldAllowTesterToNotExecuteBehaviorOfProcedureWithAParameter
AS
BEGIN

    EXEC('CREATE PROC dbo.InnerProcedure @p1 VARCHAR(MAX) AS EXEC tSQLt.Fail ''InnerProcedure was executed '',@p1;');

    EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure';

    EXEC dbo.InnerProcedure 'with a parameter';

END;
GO

CREATE PROC tSQLt_test.test_SpyProcedure_shouldAllowTesterToNotExecuteBehaviorOfProcedureWithMultipleParameters
AS
BEGIN

    EXEC('CREATE PROC dbo.InnerProcedure @p1 VARCHAR(MAX), @p2 VARCHAR(MAX), @p3 VARCHAR(MAX) ' +
         'AS EXEC tSQLt.Fail ''InnerProcedure was executed '',@p1,@p2,@p3;');

    EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure';

    EXEC dbo.InnerProcedure 'with', 'multiple', 'parameters';

END;
GO

CREATE PROC tSQLt_test.test_SpyProcedure_shouldLogCalls
AS
BEGIN

    EXEC('CREATE PROC dbo.InnerProcedure @p1 VARCHAR(MAX), @p2 VARCHAR(MAX), @p3 VARCHAR(MAX) ' +
         'AS EXEC tSQLt.Fail ''InnerProcedure was executed '',@p1,@p2,@p3;');

    EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure';

    EXEC dbo.InnerProcedure 'with', 'multiple', 'parameters';

    IF NOT EXISTS(SELECT 1 FROM dbo.InnerProcedure_SpyProcedureLog)
    BEGIN
        EXEC tSQLt.Fail 'InnerProcedure call was not logged!';
    END;

END;
GO

CREATE PROC tSQLt_test.test_SpyProcedure_shouldLogCallsWithVarcharParameters
AS
BEGIN

    EXEC('CREATE PROC dbo.InnerProcedure @p1 VARCHAR(MAX), @p2 VARCHAR(10), @p3 VARCHAR(8000) ' +
         'AS EXEC tSQLt.Fail ''InnerProcedure was executed '',@p1,@p2,@p3;');

    EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure';

    EXEC dbo.InnerProcedure 'with', 'multiple', 'parameters';


    IF NOT EXISTS(SELECT 1
                   FROM dbo.InnerProcedure_SpyProcedureLog
                  WHERE p1 = 'with'
                    AND p2 = 'multiple'
                    AND p3 = 'parameters')
    BEGIN
        EXEC tSQLt.Fail 'InnerProcedure call was not logged correctly!';
    END;

END;
GO

CREATE PROC tSQLt_test.test_getFullTypeName_shouldProperlyReturnIntParameters
AS
BEGIN
    DECLARE @result VARCHAR(MAX);

    SELECT @result = typeName
     FROM tSQLt.getFullTypeName(TYPE_ID('INT'), NULL, NULL, NULL);

    IF ISNULL(@result,'') <> 'INT'
    BEGIN
        EXEC tSQLt.Fail 'getFullTypeName should have returned int, but returned ', @result, ' instead';
    END
END
GO

CREATE PROC tSQLt_test.test_getFullTypeName_should_properly_return_VARCHAR_with_length_parameters
AS
BEGIN
    DECLARE @result VARCHAR(MAX);

    SELECT @result = typeName
     FROM tSQLt.getFullTypeName(TYPE_ID('VARCHAR'), 8, NULL, NULL);

    IF ISNULL(@result,'') <> 'VARCHAR(8)'
    BEGIN
        EXEC tSQLt.Fail 'getFullTypeName should have returned VARCHAR(8), but returned ', @result, ' instead';
    END
END
GO

CREATE PROC tSQLt_test.test_getFullTypeName_should_properly_return_NVARCHAR_with_length_parameters
AS
BEGIN
    DECLARE @result VARCHAR(MAX);

    SELECT @result = typeName
     FROM tSQLt.getFullTypeName(TYPE_ID('NVARCHAR'), 8, NULL, NULL);

    IF ISNULL(@result,'') <> 'NVARCHAR(4)'
    BEGIN
        EXEC tSQLt.Fail 'getFullTypeName should have returned NVARCHAR(4), but returned ', @result, ' instead';
    END
END
GO

CREATE PROC tSQLt_test.test_getFullTypeName_should_properly_return_VARCHAR_MAX_parameters
AS
BEGIN
    DECLARE @result VARCHAR(MAX);

    SELECT @result = typeName
     FROM tSQLt.getFullTypeName(TYPE_ID('VARCHAR'), -1, NULL, NULL);

    IF ISNULL(@result,'') <> 'VARCHAR(MAX)'
    BEGIN
        EXEC tSQLt.Fail 'getFullTypeName should have returned VARCHAR(MAX), but returned ', @result, ' instead';
    END
END
GO

CREATE PROC tSQLt_test.test_getFullTypeName_should_properly_return_VARBINARY_MAX_parameters
AS
BEGIN
    DECLARE @result VARCHAR(MAX);

    SELECT @result = typeName
     FROM tSQLt.getFullTypeName(TYPE_ID('VARBINARY'), -1, NULL, NULL);

    IF ISNULL(@result,'') <> 'VARBINARY(MAX)'
    BEGIN
        EXEC tSQLt.Fail 'getFullTypeName should have returned VARBINARY(MAX), but returned ', @result, ' instead';
    END
END
GO

CREATE PROC tSQLt_test.test_getFullTypeName_should_properly_return_DECIMAL_parameters
AS
BEGIN
    DECLARE @result VARCHAR(MAX);

    SELECT @result = typeName
     FROM tSQLt.getFullTypeName(TYPE_ID('DECIMAL'), NULL, 12,13);

    IF ISNULL(@result,'') <> 'DECIMAL(12,13)'
    BEGIN
        EXEC tSQLt.Fail 'getFullTypeName should have returned DECIMAL(12,13), but returned ', @result, ' instead';
    END
END
GO

CREATE PROC tSQLt_test.test_getFullTypeName_should_properly_return_typeName_when_all_parameters_are_valued
AS
BEGIN
    DECLARE @result VARCHAR(MAX);

    SELECT @result = typeName
     FROM tSQLt.getFullTypeName(TYPE_ID('INT'), 1, 1,1);

    IF ISNULL(@result,'') <> 'INT'
    BEGIN
        EXEC tSQLt.Fail 'getFullTypeName should have returned INT, but returned ', @result, ' instead';
    END
END
GO

CREATE PROC tSQLt_test.test_assertEquals_should_do_nothing_with_two_equal_ints
AS
BEGIN
    EXEC tSQLt.assertEquals 1, 1;
END
GO

CREATE PROC tSQLt_test.test_assertEquals_should_do_nothing_with_two_NULLs
AS
BEGIN
    EXEC tSQLt.assertEquals NULL, NULL;
END
GO

CREATE PROC tSQLt_test.test_assertEquals_should_call_fail_with_nonequal_ints
AS
BEGIN
    DECLARE @command VARCHAR(MAX); SET @command = 'EXEC tSQLt.assertEquals 1, 2;';
    EXEC tSQLt_testutil.assertFailCalled @command, 'assertEquals did not call Fail';
END
GO

CREATE PROC tSQLt_test.test_assertEquals_should_call_fail_with_one_value_null
AS
BEGIN
    DECLARE @command VARCHAR(MAX); SET @command = 'EXEC tSQLt.assertEquals 1, NULL;';
    EXEC tSQLt_testutil.assertFailCalled @command, 'assertEquals did not call Fail';
END
GO

CREATE PROC tSQLt_test.test_getNewTranName_should_generate_a_name
AS
BEGIN
   DECLARE @value CHAR(32)

   EXEC tSQLt.getNewTranName @value OUT;

   IF @value IS NULL OR @value = ''
   BEGIN
      EXEC tSQLt.Fail 'getNewTranName should have returned a name';
   END
END;
GO

CREATE PROC tSQLt_test.test_assertEqualsString_should_do_nothing_with_two_equal_VARCHAR_Max_Values
AS
BEGIN
    DECLARE @TestString VARCHAR(Max);
    SET @TestString = REPLICATE(CAST('TestString' AS VARCHAR(MAX)),1000);
    EXEC tSQLt.assertEqualsString @TestString, @TestString;
END
GO

CREATE PROC tSQLt_test.test_assertEqualsString_should_do_nothing_with_two_NULLs
AS
BEGIN
    EXEC tSQLt.assertEqualsString NULL, NULL;
END
GO

CREATE PROC tSQLt_test.test_assertEqualsString_should_call_fail_with_nonequal_VARCHAR_MAX
AS
BEGIN
    DECLARE @TestString1 VARCHAR(MAX);
    SET @TestString1 = REPLICATE(CAST('TestString' AS VARCHAR(MAX)),1000)+'1';
    DECLARE @TestString2 VARCHAR(MAX);
    SET @TestString2 = REPLICATE(CAST('TestString' AS VARCHAR(MAX)),1000)+'2';

    DECLARE @command VARCHAR(MAX); SET @command = 'EXEC tSQLt.assertEqualsString ''' + @TestString1 + ''', ''' + @TestString2 + ''';';
    EXEC tSQLt_testutil.assertFailCalled @command, 'assertEqualsString did not call Fail';
END;
GO

CREATE PROC tSQLt_test.test_assertEqualsString_should_call_fail_with_one_value_null
AS
BEGIN
    DECLARE @command VARCHAR(MAX); SET @command = 'EXEC tSQLt.assertEqualsString ''1'', NULL;';
    EXEC tSQLt_testutil.assertFailCalled @command, 'assertEqualsString did not call Fail';
END;
GO

CREATE PROC tSQLt_test.test_that_tests_in_testclasses_get_executed
AS
BEGIN
    EXEC('EXEC tSQLt.DropClass innertest;');
    EXEC('CREATE SCHEMA innertest;');
    EXEC('CREATE PROC innertest.testMe as RETURN 0;');

    EXEC tSQLt.RunTestClass 'innertest';

    IF NOT EXISTS(SELECT 1 FROM tSQLt.TestResult WHERE name = '[innertest].[testMe]')
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

    IF EXISTS(SELECT 1 FROM tSQLt.TestResult WHERE name = 'innertest.do_not_test_me')
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

    IF NOT EXISTS(SELECT 1 FROM tSQLt.TestResult WHERE name = '[innertest].[test]' AND Result = 'Failure')
    BEGIN
       EXEC tSQLt.Fail 'failing innertest.SetUp did not cause innertest.test to fail.';
   END;
END;
GO

--    EXEC('CREATE TABLE innertest.SetUpLog(i INT IDENTITY(0,1));');
--
--    EXEC('CREATE PROC innertest.SetUp AS INSERT innertest.SetUpLog DEFAULT VALUES;');
--    EXEC('CREATE PROC innertest.test AS IF NOT EXISTS(SELECT 1 FROM innertest.SetUpLog)EXEC tSQLt.Fail''innertest.SetUp did not get executed.'';');
--    
--    IF NOT EXISTS(SELECT 1 FROM tSQLt.TestResult WHERE name = 'innertest.test' AND Result = 'Success')
--    BEGIN
--       EXEC tSQLt.Fail

--CREATE PROC tSQLt_test.test_setup_should_be_executed_before_each_test_case
--AS
--BEGIN
--    EXEC('EXEC tSQLt.DropClass innertest;');
--    EXEC('CREATE SCHEMA innertest;');
--    EXEC('CREATE TABLE innertest.SetUpLog(i INT IDENTITY(0,1));INSERT innertest.SetUpLog DEFAULT VALUES;');
--
--    EXEC('CREATE PROC innertest.SetUp AS INSERT innertest.SetUpLog DEFAULT VALUES;');
--
--    EXEC('CREATE PROC innertest.testA AS 
--          BEGIN
--            DECLARE @testResultsRecorded int; SELECT @testResultsRecorded = COUNT(*) FROM tSQLt.TestResult;
--            DECLARE @currentSetUpLogIdentValue int; SELECT @currentSetUpLogIdentValue = IDENT_CURRENT(''innertest.SetUpLog'');
--
--            IF @currentSetUpLogIdentValue <> @testResultsRecorded - 1
--               EXEC tSQLt.Fail ''Setup and test case not executed in correct order or within correct transaction wrapping.'';
--          END;');
--    EXEC('CREATE PROC innertest.testB AS 
--          BEGIN
--            DECLARE @testResultsRecorded int; SELECT @testResultsRecorded = COUNT(*) FROM tSQLt.TestResult;
--            DECLARE @currentSetUpLogIdentValue int; SELECT @currentSetUpLogIdentValue = IDENT_CURRENT(''innertest.SetUpLog'');
--
--            IF @currentSetUpLogIdentValue <> @testResultsRecorded - 1
--               EXEC tSQLt.Fail ''Setup and test case not executed in correct order or within correct transaction wrapping.'';
--          END;');
--
--    TRUNCATE TABLE tSQLt.TestResult;
--    EXEC tSQLt.RunTestClass 'innertest';
--
--END;
GO

CREATE PROCEDURE tSQLt_test.test_RunTest_handles_uncommitable_transaction
AS
BEGIN
    DECLARE @TranName SYSNAME; 
    SELECT TOP(1) @TranName = TranName FROM tSQLt.TestResult WHERE Name = '[tSQLt_test].[test_RunTest_handles_uncommitable_transaction]' ORDER BY ID DESC;
    EXEC ('CREATE PROCEDURE testUncommitable AS BEGIN CREATE TABLE t1 (i int); CREATE TABLE t1 (i int); END;');

    BEGIN TRY
        EXEC tSQLt.RunTest 'testUncommitable';
    END TRY
    BEGIN CATCH
      IF NOT EXISTS(SELECT 1
                      FROM tSQLt.TestResult
                     WHERE Name = '[dbo].[testUncommitable]'
                       AND Result = 'Error'
                       AND Msg LIKE '%There is already an object named ''t1'' in the database.{testUncommitable,1}%'
                       AND Msg LIKE '%The current transaction cannot be committed and cannot be rolled back to a savepoint.%'
                   )
      BEGIN
        EXEC tSQLt.Fail 'runTest ''testUncommitable'' did not error correctly';
      END;
      IF(@@TRANCOUNT > 0)
      BEGIN
        EXEC tSQLt.Fail 'runTest ''testUncommitable'' did not rollback the transactions';
      END
      DELETE FROM tSQLt.TestResult
             WHERE Name = '[dbo].[testUncommitable]'
               AND Result = 'Error'
               AND Msg LIKE '%There is already an object named ''t1'' in the database.{testUncommitable,1}%'
               AND Msg LIKE '%The current transaction cannot be committed and cannot be rolled back to a savepoint.%'
      BEGIN TRAN
      SAVE TRAN @TranName
    END CATCH
END;
GO


CREATE PROCEDURE tSQLt_test.test_FakeTable_works_on_referencedTo_tables
AS
BEGIN
  IF OBJECT_ID('tst1') IS NOT NULL DROP TABLE tst1;
  IF OBJECT_ID('tst2') IS NOT NULL DROP TABLE tst2;

  CREATE TABLE tst1(i INT PRIMARY KEY);
  CREATE TABLE tst2(i INT PRIMARY KEY, tst1i INT REFERENCES tst1(i));
  
  BEGIN TRY
    EXEC tSQLt.FakeTable '', 'tst1';
  END TRY
  BEGIN CATCH
    DECLARE @errorMessage NVARCHAR(MAX);
    SELECT @errorMessage = ERROR_MESSAGE()+'{'+ISNULL(ERROR_PROCEDURE(),'NULL')+','+ISNULL(CAST(ERROR_LINE() AS VARCHAR),'NULL')+'}';

    EXEC tSQLt.Fail 'FakeTable threw unexpected error:', @errorMessage;
  END CATCH;
END;
GO

CREATE PROCEDURE tSQLt_test.test_ApplyConstraint_copies_a_check_constraint_to_a_fake_table
AS
BEGIN
    DECLARE @actualDefinition VARCHAR(MAX);

    CREATE TABLE tableA (constCol CHAR(3) CONSTRAINT testConstraint CHECK (constCol = 'XYZ'));

    EXEC tSQLt.FakeTable '', 'tableA';
    EXEC tSQLt.ApplyConstraint '', 'tableA', 'testConstraint';

    SELECT @actualDefinition = definition
      FROM sys.check_constraints
     WHERE parent_object_id = OBJECT_ID('tableA') AND name = 'testConstraint';

    IF @@ROWCOUNT = 0
    BEGIN
        EXEC tSQLt.Fail 'Constraint, "testConstraint", was not copied to tableA';
    END;

    EXEC tSQLt.AssertEqualsString '([constCol]=''XYZ'')', @actualDefinition;

END;
GO


CREATE PROCEDURE tSQLt_test.test_ApplyConstraint_copies_a_check_constraint_to_a_fake_table_with_schema
AS
BEGIN
    DECLARE @actualDefinition VARCHAR(MAX);

    EXEC ('CREATE SCHEMA schemaA');
    CREATE TABLE schemaA.tableA (constCol CHAR(3) CONSTRAINT testConstraint CHECK (constCol = 'XYZ'));

    EXEC tSQLt.FakeTable 'schemaA', 'tableA';
    EXEC tSQLt.ApplyConstraint 'schemaA', 'tableA', 'testConstraint';

    SELECT @actualDefinition = definition
      FROM sys.check_constraints
     WHERE parent_object_id = OBJECT_ID('schemaA.tableA') AND name = 'testConstraint';

    IF @@ROWCOUNT = 0
    BEGIN
        EXEC tSQLt.Fail 'Constraint, "testConstraint", was not copied to tableA';
    END;

    EXEC tSQLt.AssertEqualsString '([constCol]=''XYZ'')', @actualDefinition;

END;
GO

CREATE PROCEDURE tSQLt_test.test_ApplyConstraint_throws_error_if_called_with_invalid_constraint
AS
BEGIN
    DECLARE @errorThrown BIT; SET @errorThrown = 0;

    EXEC ('CREATE SCHEMA schemaA');
    CREATE TABLE schemaA.tableA (constCol CHAR(3) );
    CREATE TABLE schemaA.thisIsNotAConstraint (constCol CHAR(3) );

    EXEC tSQLt.FakeTable 'schemaA', 'tableA';
    
    BEGIN TRY
      EXEC tSQLt.ApplyConstraint 'schemaA', 'tableA', 'thisIsNotAConstraint';
    END TRY
    BEGIN CATCH
      DECLARE @errorMessage NVARCHAR(MAX);
      SELECT @errorMessage = ERROR_MESSAGE()+'{'+ISNULL(ERROR_PROCEDURE(),'NULL')+','+ISNULL(CAST(ERROR_LINE() AS VARCHAR),'NULL')+'}';
      IF @errorMessage NOT LIKE '%''schemaA.thisIsNotAConstraint'' is not a valid constraint on table ''schemaA.tableA'' for the tSQLt.ApplyConstraint procedure%'
      BEGIN
          EXEC tSQLt.Fail 'tSQLt.ApplyConstraint threw unexpected exception: ',@errorMessage;     
      END
      SET @errorThrown = 1;
    END CATCH;
    
    EXEC tSQLt.AssertEquals 1,@errorThrown,'tSQLt.ApplyConstraint did not throw an error!';

END;
GO

CREATE PROCEDURE tSQLt_test.test_ApplyConstraint_throws_error_if_called_with_constraint_existsing_on_different_table
AS
BEGIN
    DECLARE @errorThrown BIT; SET @errorThrown = 0;

    EXEC ('CREATE SCHEMA schemaA');
    CREATE TABLE schemaA.tableA (constCol CHAR(3) );
    CREATE TABLE schemaA.tableB (constCol CHAR(3) CONSTRAINT MyConstraint CHECK (1=0));

    EXEC tSQLt.FakeTable 'schemaA', 'tableA';
    
    BEGIN TRY
      EXEC tSQLt.ApplyConstraint 'schemaA', 'tableA', 'MyConstraint';
    END TRY
    BEGIN CATCH
      DECLARE @errorMessage NVARCHAR(MAX);
      SELECT @errorMessage = ERROR_MESSAGE()+'{'+ISNULL(ERROR_PROCEDURE(),'NULL')+','+ISNULL(CAST(ERROR_LINE() AS VARCHAR),'NULL')+'}';
      IF @errorMessage NOT LIKE '%''schemaA.MyConstraint'' is not a valid constraint on table ''schemaA.tableA'' for the tSQLt.ApplyConstraint procedure%'
      BEGIN
          EXEC tSQLt.Fail 'tSQLt.ApplyConstraint threw unexpected exception: ',@errorMessage;     
      END
      SET @errorThrown = 1;
    END CATCH;
    
    EXEC tSQLt.AssertEquals 1,@errorThrown,'tSQLt.ApplyConstraint did not throw an error!';

END;
GO

CREATE PROCEDURE tSQLt_test.test_ApplyConstraint_copies_a_foreign_key_to_a_fake_table
AS
BEGIN
    DECLARE @actualDefinition VARCHAR(MAX);

    CREATE TABLE tableA (id int PRIMARY KEY);
    CREATE TABLE tableB (bid int, aid int CONSTRAINT testConstraint REFERENCES tableA(id));

    EXEC tSQLt.FakeTable '', 'tableB';

    EXEC tSQLt.ApplyConstraint '', 'tableB', 'testConstraint';

    IF NOT EXISTS(SELECT 1 FROM sys.foreign_keys WHERE name = 'testConstraint' AND parent_object_id = OBJECT_ID('tableB'))
    BEGIN
        EXEC tSQLt.Fail 'Constraint, "testConstraint", was not copied to tableB';
    END;
END;
GO

CREATE PROCEDURE tSQLt_test.test_ApplyConstraint_copies_a_foreign_key_to_a_fake_table_with_schema
AS
BEGIN
    DECLARE @actualDefinition VARCHAR(MAX);

    EXEC ('CREATE SCHEMA schemaA');
    CREATE TABLE schemaA.tableA (id int PRIMARY KEY);
    CREATE TABLE schemaA.tableB (bid int, aid int CONSTRAINT testConstraint REFERENCES schemaA.tableA(id));

    EXEC tSQLt.FakeTable 'schemaA', 'tableB';

    EXEC tSQLt.ApplyConstraint 'schemaA', 'tableB', 'testConstraint';

    IF NOT EXISTS(SELECT 1 FROM sys.foreign_keys WHERE name = 'testConstraint' AND parent_object_id = OBJECT_ID('schemaA.tableB'))
    BEGIN
        EXEC tSQLt.Fail 'Constraint, "testConstraint", was not copied to tableB';
    END;
END;
GO

CREATE PROCEDURE tSQLt_test.test_FakeTable_raises_appropriate_error_if_table_does_not_exist
AS
BEGIN
    DECLARE @errorThrown BIT; SET @errorThrown = 0;

    EXEC ('CREATE SCHEMA schemaA');
    CREATE TABLE schemaA.tableA (constCol CHAR(3) );

    BEGIN TRY
      EXEC tSQLt.FakeTable 'schemaA', 'tableXYZ';
    END TRY
    BEGIN CATCH
      DECLARE @errorMessage NVARCHAR(MAX);
      SELECT @errorMessage = ERROR_MESSAGE()+'{'+ISNULL(ERROR_PROCEDURE(),'NULL')+','+ISNULL(CAST(ERROR_LINE() AS VARCHAR),'NULL')+'}';
      IF @errorMessage NOT LIKE '%''schemaA.tableXYZ'' does not exist%'
      BEGIN
          EXEC tSQLt.Fail 'tSQLt.FakeTable threw unexpected exception: ',@errorMessage;     
      END
      SET @errorThrown = 1;
    END CATCH;
    
    EXEC tSQLt.AssertEquals 1, @errorThrown,'tSQLt.FakeTable did not throw an error when the table does not exist.';
END;
GO

CREATE PROCEDURE tSQLt_test.test_assertEqualsTable_raises_appropriate_error_if_expected_table_does_not_exist
AS
BEGIN
    DECLARE @errorThrown BIT; SET @errorThrown = 0;

    EXEC ('CREATE SCHEMA schemaA');
    CREATE TABLE schemaA.actual (constCol CHAR(3) );

    DECLARE @command NVARCHAR(MAX);
    SET @command = 'EXEC tSQLt.AssertEqualsTable ''schemaA.expected'', ''schemaA.actual'';';
    EXEC tSQLt_testutil.assertFailCalled @command, 'assertEqualsTable did not call Fail when expected table does not exist';
END;
GO


CREATE PROCEDURE tSQLt_test.test_assertEqualsTable_raises_appropriate_error_if_actual_table_does_not_exist
AS
BEGIN
    DECLARE @errorThrown BIT; SET @errorThrown = 0;

    EXEC ('CREATE SCHEMA schemaA');
    CREATE TABLE schemaA.expected (constCol CHAR(3) );
    
    DECLARE @command NVARCHAR(MAX);
    SET @command = 'EXEC tSQLt.AssertEqualsTable ''schemaA.expected'', ''schemaA.actual'';';
    EXEC tSQLt_testutil.assertFailCalled @command, 'assertEqualsTable did not call Fail when actual table does not exist';
END;
GO

CREATE PROCEDURE tSQLt_test.test_AssertEqualsTable_works_with_temptables
AS
BEGIN
    DECLARE @errorThrown BIT; SET @errorThrown = 0;

    CREATE TABLE #t1(I INT)
    INSERT INTO #t1 SELECT 1
    CREATE TABLE #t2(I INT)
    INSERT INTO #t2 SELECT 2

    DECLARE @command NVARCHAR(MAX);
    SET @command = 'EXEC tSQLt.AssertEqualsTable ''#t1'', ''#t2'';';
    EXEC tSQLt_testutil.assertFailCalled @command, 'assertEqualsTable did not call Fail when comparing temp tables';
END;
GO

CREATE PROC tSQLt_test.test_AssertEqualsTable_works_with_equal_temptables
AS
BEGIN
    DECLARE @errorRaised INT; SET @errorRaised = 0;

    EXEC('CREATE SCHEMA MyTestClass;');
    CREATE TABLE #t1(I INT)
    INSERT INTO #t1 SELECT 42
    CREATE TABLE #t2(I INT)
    INSERT INTO #t2 SELECT 42
    EXEC('CREATE PROC MyTestClass.TestCaseA AS EXEC tSQLt.AssertEqualsTable ''#t1'', ''#t2'';');
    
    BEGIN TRY
        EXEC tSQLt.RunTest 'MyTestClass.TestCaseA';
    END TRY
    BEGIN CATCH
        SET @errorRaised = 1;
    END CATCH
    SELECT Name, Result
      INTO actual
      FROM tSQLt.TestResult;
    SELECT '[MyTestClass].[TestCaseA]' Name, 'Success' Result
      INTO expected;
    
    EXEC tSQLt.AssertEqualsTable 'expected', 'actual';
END;
GO

CREATE PROC tSQLt_test.test_AssertEqualsTable_works_with_actual_having_identity_column
AS
BEGIN
    DECLARE @errorRaised INT; SET @errorRaised = 0;

    EXEC('CREATE SCHEMA MyTestClass;');
    CREATE TABLE #t1(I INT IDENTITY(1,1));
    INSERT INTO #t1 DEFAULT VALUES;
    CREATE TABLE #t2(I INT);
    INSERT INTO #t2 VALUES(1);
    EXEC('CREATE PROC MyTestClass.TestCaseA AS EXEC tSQLt.AssertEqualsTable ''#t1'', ''#t2'';');
    
    BEGIN TRY
        EXEC tSQLt.RunTest 'MyTestClass.TestCaseA';
    END TRY
    BEGIN CATCH
        SET @errorRaised = 1;
    END CATCH
    SELECT Name, Result
      INTO actual
      FROM tSQLt.TestResult;
    SELECT '[MyTestClass].[TestCaseA]' Name, 'Success' Result
      INTO expected;
    
    EXEC tSQLt.AssertEqualsTable 'expected', 'actual';
END;
GO

CREATE PROC tSQLt_test.test_AssertEqualsTable_works_with_expected_having_identity_column
AS
BEGIN
    DECLARE @errorRaised INT; SET @errorRaised = 0;

    EXEC('CREATE SCHEMA MyTestClass;');
    CREATE TABLE #t1(I INT);
    INSERT INTO #t1 VALUES(1);
    CREATE TABLE #t2(I INT IDENTITY(1,1));
    INSERT INTO #t2 DEFAULT VALUES;
    EXEC('CREATE PROC MyTestClass.TestCaseA AS EXEC tSQLt.AssertEqualsTable ''#t1'', ''#t2'';');
    
    BEGIN TRY
        EXEC tSQLt.RunTest 'MyTestClass.TestCaseA';
    END TRY
    BEGIN CATCH
        SET @errorRaised = 1;
    END CATCH
    SELECT Name, Result
      INTO actual
      FROM tSQLt.TestResult;
    SELECT '[MyTestClass].[TestCaseA]' Name, 'Success' Result
      INTO expected;
    
    EXEC tSQLt.AssertEqualsTable 'expected', 'actual';
END;
GO

CREATE PROC tSQLt_test.test_AssertObjectExists_raises_appropriate_error_if_table_does_not_exist
AS
BEGIN
    DECLARE @errorThrown BIT; SET @errorThrown = 0;

    EXEC ('CREATE SCHEMA schemaA');
    
    DECLARE @command NVARCHAR(MAX);
    SET @command = 'EXEC tSQLt.AssertObjectExists ''schemaA.expected''';
    EXEC tSQLt_testutil.assertFailCalled @command, 'AssertObjectExists did not call Fail when table does not exist';
END;
GO

CREATE PROC tSQLt_test.test_AssertObjectExists_does_not_call_fail_when_table_exists
AS
BEGIN
    DECLARE @errorRaised INT; SET @errorRaised = 0;

    EXEC('CREATE SCHEMA MyTestClass;');
    EXEC('CREATE TABLE MyTestClass.tbl(i int);');
    EXEC('CREATE PROC MyTestClass.TestCaseA AS EXEC tSQLt.AssertObjectExists ''MyTestClass.tbl'';');
    
    BEGIN TRY
        EXEC tSQLt.RunTest 'MyTestClass.TestCaseA';
    END TRY
    BEGIN CATCH
        SET @errorRaised = 1;
    END CATCH
    SELECT Name, Result 
      INTO actual
      FROM tSQLt.TestResult;
    SELECT '[MyTestClass].[TestCaseA]' Name, 'Success' Result
      INTO expected;
    
    EXEC tSQLt.AssertEqualsTable 'expected', 'actual';
END;
GO

CREATE PROC tSQLt_test.test_AssertObjectExists_does_not_call_fail_when_table_is_temp_table
AS
BEGIN
    DECLARE @errorRaised INT; SET @errorRaised = 0;

    EXEC('CREATE SCHEMA MyTestClass;');
    CREATE TABLE #tbl(i int);
    EXEC('CREATE PROC MyTestClass.TestCaseA AS EXEC tSQLt.AssertObjectExists ''#tbl'';');
    
    BEGIN TRY
        EXEC tSQLt.RunTest 'MyTestClass.TestCaseA';
    END TRY
    BEGIN CATCH
        SET @errorRaised = 1;
    END CATCH
    SELECT Name, Result
      INTO actual
      FROM tSQLt.TestResult;
    SELECT '[MyTestClass].[TestCaseA]' Name, 'Success' Result
      INTO expected;
    
    EXEC tSQLt.AssertEqualsTable 'expected', 'actual';
END;
GO

CREATE PROC tSQLt_test.test_dropClass_does_not_error_if_testcase_name_contains_spaces
AS
BEGIN
    DECLARE @errorRaised INT; SET @errorRaised = 0;

    EXEC('CREATE SCHEMA MyTestClass;');
    EXEC('CREATE PROC MyTestClass.[Test Case A ] AS RETURN 0;');
    
    BEGIN TRY
        EXEC tSQLt.DropClass 'MyTestClass';
    END TRY
    BEGIN CATCH
        SET @errorRaised = 1;
    END CATCH

    EXEC tSQLt.AssertEquals 0,@errorRaised,'Unexpected error during execution of DropClass'
    
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

    SELECT name 
      INTO #Expected
      FROM tSQLt.TestResult
     WHERE 1=0;
     
    INSERT INTO #Expected(name)
    SELECT name = '[innertest].[testMe]' UNION ALL
    SELECT name = '[innertest].[testMeToo]';

    SELECT name
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

    SELECT name 
      INTO #Expected
      FROM tSQLt.TestResult
     WHERE 1=0;
     
    INSERT INTO #Expected(name)
    SELECT name = '[innertest].[testMe]';

    SELECT name
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

    SELECT name 
      INTO #Expected
      FROM tSQLt.TestResult
     WHERE 1=0;
     
    INSERT INTO #Expected(name)
    SELECT name = '[innertest].[testMe]';

    SELECT name
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

    SELECT name 
      INTO #Expected
      FROM tSQLt.TestResult
     WHERE 1=0;
     
    INSERT INTO #Expected(name)
    SELECT name = '[innertest].[testMe]' UNION ALL
    SELECT name = '[innertest].[testMeToo]';

    SELECT name
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
    
    INSERT tSQLt.Run_LastExecution(session_id, login_time, testName)
    SELECT @@SPID, '2009-09-09', '[Old1]' UNION ALL
    SELECT @@SPID, '2010-10-10', '[Old2]' UNION ALL
    SELECT @@SPID+10, '2011-11-11', '[Other]';   

    EXEC tSQLt.Run 'New';
    
    SELECT testName 
      INTO #Expected
      FROM tSQLt.Run_LastExecution
     WHERE 1=0;
     
    INSERT INTO #Expected(testName)
    SELECT '[Other]' UNION ALL
    SELECT '[New]';

    SELECT testName
      INTO #Actual
      FROM tSQLt.Run_LastExecution;
      
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';    
END;
GO

CREATE PROC tSQLt_test.test_SpyProcedure_handles_procedure_names_with_spaces
AS
BEGIN
    DECLARE @errorRaised INT; SET @errorRaised = 0;

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
    
    EXEC tSQLt.AssertEqualsTable '#expected', '#actual';
END;
GO

CREATE PROC tSQLt_test.test_RunTestClass_handles_test_names_with_spaces
AS
BEGIN
    DECLARE @errorRaised INT; SET @errorRaised = 0;

    EXEC('CREATE SCHEMA MyTestClass;');
    EXEC('CREATE PROC MyTestClass.[Test Case A] AS RETURN 0;');

    EXEC tSQLt.RunTestClass MyTestClass;
    
    SELECT Name 
      INTO actual
      FROM tSQLt.TestResult;
      
    SELECT '[MyTestClass].[Test Case A]' Name
      INTO expected;
    
    EXEC tSQLt.AssertEqualsTable 'expected', 'actual';
END;
GO

CREATE PROCEDURE tSQLt_test.[test NewTestClass creates a new schema]
AS
BEGIN
    EXEC tSQLt.NewTestClass 'MyTestClass';
    
    IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'MyTestClass')
    BEGIN
        EXEC tSQLt.Fail 'Should have created schema: MyTestClass';
    END;
END;
GO

CREATE PROCEDURE tSQLt_test.[test NewTestClass calls tSQLt.DropClass]
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
CREATE PROCEDURE tSQLt_test.[test SpyProcedure works if spyee has 100 parameters with 8000 bytes each]
AS
BEGIN
  IF OBJECT_ID('dbo.InnerProcedure') IS NOT NULL DROP PROCEDURE dbo.InnerProcedure;
  DECLARE @cmd VARCHAR(MAX);
  SELECT @cmd = 'CREATE PROCEDURE dbo.InnerProcedure('+
                (SELECT CASE WHEN no = 1 THEN '' ELSE ',' END +'@p'+CAST(no AS VARCHAR)+' CHAR(8000)' [text()]
                   FROM tSQLt.f_Num(1020)
                    FOR XML PATH('')
                )+
                ') AS BEGIN RETURN 0; END;';
  EXEC(@cmd);

  SELECT name, parameter_id, system_type_id, user_type_id, max_length, precision, scale 
    INTO #expectedM
    FROM sys.parameters
   WHERE object_id = OBJECT_ID('dbo.InnerProcedure');

  EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure'

  SELECT name, parameter_id, system_type_id, user_type_id, max_length, precision, scale 
    INTO #actualM
    FROM sys.parameters
   WHERE object_id = OBJECT_ID('dbo.InnerProcedure');

  SELECT * 
    INTO #actual1
    FROM #actualM
   WHERE parameter_id<511;
  SELECT * 
    INTO #expected1
    FROM #expectedM
   WHERE parameter_id<511;
   
  EXEC tSQLt.AssertEqualsTable '#expected1','#actual1';

  SELECT * 
    INTO #actual2
    FROM #actualM
   WHERE parameter_id>510;
  SELECT * 
    INTO #expected2
    FROM #expectedM
   WHERE parameter_id>510;
   
  EXEC tSQLt.AssertEqualsTable '#expected2','#actual2';
END
GO
CREATE PROCEDURE tSQLt_test.[test SpyProcedure creates char parameters correctly]
AS
BEGIN
    EXEC('CREATE PROCEDURE dbo.InnerProcedure(
             @CHAR1 CHAR(1),
             @CHAR8000 CHAR(8000),
             @VARCHAR1 VARCHAR(1),
             @VARCHAR8000 VARCHAR(8000),
             @VARCHARMAX VARCHAR(MAX)
          )
          AS BEGIN RETURN 0; END');
    SELECT name, parameter_id, system_type_id, user_type_id, max_length, precision, scale 
      INTO #expected
      FROM sys.parameters
     WHERE object_id = OBJECT_ID('dbo.InnerProcedure');

    EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure'

    SELECT name, parameter_id, system_type_id, user_type_id, max_length, precision, scale 
      INTO #actual
      FROM sys.parameters
     WHERE object_id = OBJECT_ID('dbo.InnerProcedure');

    EXEC tSQLt.AssertEqualsTable '#expected','#actual';
END;
GO
CREATE PROCEDURE tSQLt_test.[test SpyProcedure creates binary parameters correctly]
AS
BEGIN
    EXEC('CREATE PROCEDURE dbo.InnerProcedure(
             @BINARY1 BINARY(1) =NULL,
             @BINARY8000 BINARY(8000) =NULL,
             @VARBINARY1 VARBINARY(1) =NULL,
             @VARBINARY8000 VARBINARY(8000) =NULL,
             @VARBINARYMAX VARBINARY(MAX) =NULL
          )
          AS BEGIN RETURN 0; END');
    SELECT name, parameter_id, system_type_id, user_type_id, max_length, precision, scale 
      INTO #expected
      FROM sys.parameters
     WHERE object_id = OBJECT_ID('dbo.InnerProcedure');

    EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure'

    SELECT name, parameter_id, system_type_id, user_type_id, max_length, precision, scale 
      INTO #actual
      FROM sys.parameters
     WHERE object_id = OBJECT_ID('dbo.InnerProcedure');

     EXEC tSQLt.AssertEqualsTable '#expected', '#actual';
END;
GO

CREATE PROCEDURE tSQLt_test.[test SpyProcedure creates log which handles binary columns]
AS
BEGIN
    EXEC('CREATE PROCEDURE dbo.InnerProcedure(
             @VARBINARY8000 VARBINARY(8000) =NULL
          )
          AS BEGIN RETURN 0; END');

    EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure'
     
    EXEC dbo.InnerProcedure @VARBINARY8000=0x111122223333444455556666777788889999;

    DECLARE @actual VARBINARY(8000);
    SELECT @actual = VARBINARY8000 FROM dbo.InnerProcedure_SpyProcedureLog;
    
    EXEC tSQLt.AssertEquals 0x111122223333444455556666777788889999, @actual;
END;
GO


CREATE PROCEDURE tSQLt_test.[test SpyProcedure creates nchar parameters correctly]
AS
BEGIN
    EXEC('CREATE PROCEDURE dbo.InnerProcedure(
             @NCHAR1 NCHAR(1),
             @NCHAR4000 NCHAR(4000),
             @NVARCHAR1 NVARCHAR(1),
             @NVARCHAR4000 NVARCHAR(4000),
             @NVARCHARMAX NVARCHAR(MAX)
          )
          AS BEGIN RETURN 0; END');
    SELECT name, parameter_id, system_type_id, user_type_id, max_length, precision, scale 
      INTO #expected
      FROM sys.parameters
     WHERE object_id = OBJECT_ID('dbo.InnerProcedure');

    EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure'

    SELECT name, parameter_id, system_type_id, user_type_id, max_length, precision, scale 
      INTO #actual
      FROM sys.parameters
     WHERE object_id = OBJECT_ID('dbo.InnerProcedure');

    EXEC tSQLt.AssertEqualsTable '#expected','#actual';
END;
GO
CREATE PROCEDURE tSQLt_test.[test SpyProcedure creates other parameters correctly]
AS
BEGIN
    EXEC('CREATE PROCEDURE dbo.InnerProcedure(
             @TINYINT TINYINT,
             @SMALLINT SMALLINT,
             @INT INT,
             @BIGINT BIGINT
          )
          AS BEGIN RETURN 0; END');
    SELECT name, parameter_id, system_type_id, user_type_id, max_length, precision, scale 
      INTO #expected
      FROM sys.parameters
     WHERE object_id = OBJECT_ID('dbo.InnerProcedure');

    EXEC tSQLt.SpyProcedure 'dbo.InnerProcedure'

    SELECT name, parameter_id, system_type_id, user_type_id, max_length, precision, scale 
      INTO #actual
      FROM sys.parameters
     WHERE object_id = OBJECT_ID('dbo.InnerProcedure');

    EXEC tSQLt.AssertEqualsTable '#expected','#actual';
END;
GO
CREATE PROCEDURE tSQLt_test.[test SpyProcedure fails with error if spyee has more than 1020 parameters]
AS
BEGIN
  IF OBJECT_ID('dbo.Spyee') IS NOT NULL DROP PROCEDURE dbo.Spyee;
  DECLARE @cmd VARCHAR(MAX);
  SELECT @cmd = 'CREATE PROCEDURE dbo.Spyee('+
                (SELECT CASE WHEN no = 1 THEN '' ELSE ',' END +'@p'+CAST(no AS VARCHAR)+' INT' [text()]
                   FROM tSQLt.f_Num(1021)
                    FOR XML PATH('')
                )+
                ') AS BEGIN RETURN 0; END;';
  EXEC(@cmd);
  DECLARE @err VARCHAR(MAX);SET @err = 'NO ERROR';
  BEGIN TRY
    EXEC tSQLt.SpyProcedure 'dbo.Spyee';
  END TRY
  BEGIN CATCH
    SET @err = ERROR_MESSAGE();
  END CATCH
  
  IF @err NOT LIKE '%dbo.Spyee%' AND @err NOT LIKE '%1020 parameters%'
  BEGIN
      EXEC tSQLt.Fail 'Unexpected error message was: ', @err;
  END;
  
END
GO
CREATE PROCEDURE tSQLt_test.[test f_Num(13) returns 13 rows]
AS
BEGIN
  SELECT no
    INTO #actual
    FROM tSQLt.f_Num(13);
    
  SELECT * INTO #expected FROM #actual WHERE 1=0;
  
  INSERT #expected(no)
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
  
  EXEC tSQLt.AssertEqualsTable '#expected','#actual';
END 
GO
CREATE PROCEDURE tSQLt_test.[test f_Num(0) returns 0 rows]
AS
BEGIN
  SELECT no
    INTO #actual
    FROM tSQLt.f_Num(0);
    
  SELECT * INTO #expected FROM #actual WHERE 1=0;
  
  EXEC tSQLt.AssertEqualsTable '#expected','#actual';
END 
GO
CREATE PROCEDURE tSQLt_test.[test f_Num(-11) returns 0 rows]
AS
BEGIN
  SELECT no
    INTO #actual
    FROM tSQLt.f_Num(-11);
    
  SELECT * INTO #expected FROM #actual WHERE 1=0;
  
  EXEC tSQLt.AssertEqualsTable '#expected','#actual';
END 
GO

CREATE PROCEDURE tSQLt_test.[test that tSQLt.EnableViewFaking_SingleView allows a non-updatable view to be faked using tSQLt.FakeTable and then inserted into]
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
      
  -- EnableViewFaking is executed in a separate batch (typically followed by a GO statement)
  -- than the code of the test case
  EXEC('    
      EXEC tSQLt.EnableViewFaking_SingleView @ViewName = ''NewSchema.NewView'';
      ');
      
  EXEC('
      EXEC tSQLt.FakeTable ''NewSchema'', ''NewView'';
      INSERT INTO NewSchema.NewView (a1, a2, b1, b2) VALUES (1, 2, 3, 4);
      ');

  SELECT a1, a2, b1, b2 INTO #expected
    FROM (SELECT 1 AS a1, 2 AS a2, 3 AS b1, 4 AS b2) X;
    
  EXEC tSQLt.AssertEqualsTable '#expected', 'NewSchema.NewView';
  
END
GO

CREATE PROCEDURE tSQLt_test.[test that not calling tSQLt.ResetViewFaking_SingleView before running tests causes an exception and tests not to be run]
AS
BEGIN
  DECLARE @errorOccurred BIT; SET @errorOccurred = 0;
  
  EXEC('CREATE SCHEMA NewSchema;');
  EXEC('CREATE VIEW NewSchema.NewView AS SELECT 1 AS a;');
  EXEC('EXEC tSQLt.EnableViewFaking_SingleView @ViewName = ''NewSchema.NewView'';');
  
  EXEC ('EXEC tSQLt.NewTestClass TestClass;');
  
  EXEC ('
    CREATE PROCEDURE TestClass.testExample
    AS
    BEGIN
      RETURN 0;
    END;
  ');
  
  BEGIN TRY
    EXEC tSQLt.RunTestClass 'TestClass';
    SET @errorOccurred = 0;
  END TRY
  BEGIN CATCH
    SET @errorOccurred = 1;
  END CATCH
  
  IF @errorOccurred = 0
  BEGIN
    EXEC tSQLt.Fail 'Expected RunTestClass to raise an error because ResetViewFaking_SingleView was not executed';
  END;
END
GO

CREATE PROCEDURE tSQLt_test.[test that calling tSQLt.ResetViewFaking_SingleView before running tests allows tests to be run]
AS
BEGIN
  DECLARE @errorOccurred BIT; SET @errorOccurred = 0;
  
  EXEC('CREATE SCHEMA NewSchema;');
  EXEC('CREATE VIEW NewSchema.NewView AS SELECT 1 AS a;');
  EXEC('EXEC tSQLt.EnableViewFaking_SingleView @ViewName = ''NewSchema.NewView'';');
  
  EXEC ('EXEC tSQLt.NewTestClass TestClass;');
  
  EXEC ('
    CREATE PROCEDURE TestClass.testExample
    AS
    BEGIN
      RETURN 0;
    END;
  ');
  
  EXEC('EXEC tSQLt.ResetViewFaking_SingleView @ViewName = ''NewSchema.NewView'';');
  
  BEGIN TRY
    EXEC tSQLt.RunTestClass 'TestClass';
    SET @errorOccurred = 0;
  END TRY
  BEGIN CATCH
    SET @errorOccurred = 1;
  END CATCH
  
  IF @errorOccurred = 1
  BEGIN
    EXEC tSQLt.Fail 'Expected RunTestClass to not raise an error because ResetViewFaking_SingleView was executed';
  END;
END
GO


CREATE PROCEDURE tSQLt_test.[test that calling tSQLt.ResetViewFaking_SingleView removes trigger created by tSQLt.EnableViewFaking_SingleView]
AS
BEGIN
  EXEC('CREATE SCHEMA NewSchema;');
  EXEC('CREATE VIEW NewSchema.NewView AS SELECT 1 AS a;');
  EXEC('EXEC tSQLt.EnableViewFaking_SingleView @ViewName = ''NewSchema.NewView'';');
  EXEC('EXEC tSQLt.ResetViewFaking_SingleView @ViewName = ''NewSchema.NewView'';');
  
  IF EXISTS (SELECT 1 FROM sys.triggers WHERE [name] = 'NewView_EnableViewFaking')
  BEGIN
    EXEC tSQLt.Fail 'Expected NewView_EnableViewFaking to be removed.';
  END;
END
GO

CREATE PROCEDURE tSQLt_test.CreateNonUpdatableView
  @schemaName NVARCHAR(MAX),
  @viewName NVARCHAR(MAX)
AS
BEGIN
  DECLARE @cmd NVARCHAR(MAX);

  SET @cmd = '
      CREATE TABLE $$SCHEMA_NAME$$.$$VIEW_NAME$$_A (a1 int, a2 int);
      CREATE TABLE $$SCHEMA_NAME$$.$$VIEW_NAME$$_B (a1 int, b1 int, b2 int);';
  SET @cmd = REPLACE(REPLACE(@cmd, '$$SCHEMA_NAME$$', @schemaName), '$$VIEW_NAME$$', @viewName);
  EXEC (@cmd);

  SET @cmd = '
    CREATE VIEW $$SCHEMA_NAME$$.$$VIEW_NAME$$ AS 
      SELECT A.a1, A.a2, B.b1, B.b2
        FROM $$SCHEMA_NAME$$.$$VIEW_NAME$$_A A
        JOIN $$SCHEMA_NAME$$.$$VIEW_NAME$$_B B ON A.a1 = B.a1;';
  SET @cmd = REPLACE(REPLACE(@cmd, '$$SCHEMA_NAME$$', @schemaName), '$$VIEW_NAME$$', @viewName);
  EXEC (@cmd);

END
GO

CREATE PROCEDURE tSQLt_test.AssertViewCanBeUpdatedIfFaked
  @schemaName NVARCHAR(MAX),
  @viewName NVARCHAR(MAX)
AS
BEGIN
  DECLARE @cmd NVARCHAR(MAX);

  SET @cmd = '
      EXEC tSQLt.FakeTable ''$$SCHEMA_NAME$$'', ''$$VIEW_NAME$$'';
      INSERT INTO $$SCHEMA_NAME$$.$$VIEW_NAME$$ (a1, a2, b1, b2) VALUES (1, 2, 3, 4);';
  SET @cmd = REPLACE(REPLACE(@cmd, '$$SCHEMA_NAME$$', @schemaName), '$$VIEW_NAME$$', @viewName);
  EXEC (@cmd);
  
  SET @cmd = '
    SELECT a1, a2, b1, b2 INTO #expected
    FROM (SELECT 1 AS a1, 2 AS a2, 3 AS b1, 4 AS b2) X;
    
    EXEC tSQLt.AssertEqualsTable ''#expected'', ''$$SCHEMA_NAME$$.$$VIEW_NAME$$'';';
  SET @cmd = REPLACE(REPLACE(@cmd, '$$SCHEMA_NAME$$', @schemaName), '$$VIEW_NAME$$', @viewName);
  EXEC (@cmd);
END;
GO

CREATE PROCEDURE tSQLt_test.[test that tSQLt.EnableViewFaking @schemaName applies to all views on a schema]
AS
BEGIN
  EXEC('CREATE SCHEMA NewSchema;');
  EXEC tSQLt_test.CreateNonUpdatableView 'NewSchema', 'View1';
  EXEC tSQLt_test.CreateNonUpdatableView 'NewSchema', 'View2';
  EXEC tSQLt_test.CreateNonUpdatableView 'NewSchema', 'View3';
  EXEC('EXEC tSQLt.EnableViewFaking @schemaName = ''NewSchema'';');
  
  EXEC tSQLt_test.AssertViewCanBeUpdatedIfFaked 'NewSchema', 'View1';
  EXEC tSQLt_test.AssertViewCanBeUpdatedIfFaked 'NewSchema', 'View2';
  EXEC tSQLt_test.AssertViewCanBeUpdatedIfFaked 'NewSchema', 'View3';
  
  -- Also check that triggers got created. Checking if a view is updatable is
  -- apparently unreliable, since SQL Server could have decided on this run
  -- that these views are updatable at compile time, even though they were not.
  IF (SELECT COUNT(*) FROM sys.triggers WHERE [name] LIKE 'View_[_]EnableViewFaking') <> 3
  BEGIN
    EXEC tSQLt.Fail 'Expected _EnableViewFaking triggers to be added.';
  END;
END
GO


CREATE PROCEDURE tSQLt_test.[test that tSQLt.ResetViewFaking @schemaName applies to all views on a schema]
AS
BEGIN
  EXEC('CREATE SCHEMA NewSchema;');
  EXEC tSQLt_test.CreateNonUpdatableView 'NewSchema', 'View1';
  EXEC tSQLt_test.CreateNonUpdatableView 'NewSchema', 'View2';
  EXEC tSQLt_test.CreateNonUpdatableView 'NewSchema', 'View3';
  EXEC('EXEC tSQLt.EnableViewFaking @schemaName = ''NewSchema'';');
  EXEC('EXEC tSQLt.ResetViewFaking @schemaName = ''NewSchema'';');
  
  IF EXISTS (SELECT 1 FROM sys.triggers WHERE [name] LIKE 'View_[_]EnableViewFaking')
  BEGIN
    EXEC tSQLt.Fail 'Expected _EnableViewFaking triggers rto be removed.';
  END;
END
GO
--ROLLBACK
--tSQLt_test