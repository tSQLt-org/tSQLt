EXEC tSQLt.NewTestClass 'AssertObjectExistsTests';
GO
CREATE PROC AssertObjectExistsTests.test_AssertObjectExists_raises_appropriate_error_if_table_does_not_exist
AS
BEGIN
    DECLARE @ErrorThrown BIT; SET @ErrorThrown = 0;

    EXEC ('CREATE SCHEMA schemaA');
    
    DECLARE @Command NVARCHAR(MAX);
    SET @Command = 'EXEC tSQLt.AssertObjectExists ''schemaA.expected''';
    EXEC tSQLt_testutil.assertFailCalled @Command, 'AssertObjectExists did not call Fail when table does not exist';
END;
GO

CREATE PROC AssertObjectExistsTests.test_AssertObjectExists_does_not_call_fail_when_table_exists
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

CREATE PROC AssertObjectExistsTests.test_AssertObjectExists_does_not_call_fail_when_table_is_temp_table
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

CREATE PROC AssertObjectExistsTests.test_AssertObjectExists_does_not_call_fail_when_table_exists_with_correct_type
AS
BEGIN
    DECLARE @ErrorRaised INT; SET @ErrorRaised = 0;

    EXEC('CREATE SCHEMA MyTestClass;');
    EXEC('CREATE TABLE MyTestClass.tbl(i int);');
    EXEC('CREATE PROC MyTestClass.TestCaseA AS EXEC tSQLt.AssertObjectExists ''MyTestClass.tbl'', '''', ''USER_TABLE'';');

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

CREATE PROC AssertObjectExistsTests.test_AssertObjectExists_fails_when_object_exists_but_wrong_type
AS
BEGIN
    EXEC('CREATE SCHEMA schemaA');
    EXEC('CREATE VIEW schemaA.myView AS SELECT 1 AS col;');

    DECLARE @Command NVARCHAR(MAX);
    SET @Command = 'EXEC tSQLt.AssertObjectExists ''schemaA.myView'', '''', ''USER_TABLE''';
    EXEC tSQLt_testutil.assertFailCalled @Command, 'AssertObjectExists did not call Fail when object type was incorrect';
END;
GO

CREATE PROC AssertObjectExistsTests.test_AssertObjectExists_error_message_includes_expected_and_actual_type
AS
BEGIN
    EXEC('CREATE SCHEMA schemaA');
    EXEC('CREATE VIEW schemaA.myView AS SELECT 1 AS col;');

    DECLARE @Command NVARCHAR(MAX);
    DECLARE @ActualMessage NVARCHAR(MAX);

    BEGIN TRY
        EXEC tSQLt.AssertObjectExists 'schemaA.myView', '', 'USER_TABLE';
    END TRY
    BEGIN CATCH
        SET @ActualMessage = ERROR_MESSAGE();
    END CATCH;

    IF @ActualMessage NOT LIKE '%schemaA.myView%exists but is not of type%USER_TABLE%'
    BEGIN
        EXEC tSQLt.Fail 'Error message did not contain expected information. Actual: ', @ActualMessage;
    END;

    IF @ActualMessage NOT LIKE '%found type:%VIEW%'
    BEGIN
        EXEC tSQLt.Fail 'Error message did not contain actual type information. Actual: ', @ActualMessage;
    END;
END;
GO

CREATE PROC AssertObjectExistsTests.test_AssertObjectExists_works_with_view_type
AS
BEGIN
    DECLARE @ErrorRaised INT; SET @ErrorRaised = 0;

    EXEC('CREATE SCHEMA MyTestClass;');
    EXEC('CREATE VIEW MyTestClass.myView AS SELECT 1 AS col;');
    EXEC('CREATE PROC MyTestClass.TestCaseA AS EXEC tSQLt.AssertObjectExists ''MyTestClass.myView'', '''', ''VIEW'';');

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

CREATE PROC AssertObjectExistsTests.test_AssertObjectExists_works_with_stored_procedure_type
AS
BEGIN
    DECLARE @ErrorRaised INT; SET @ErrorRaised = 0;

    EXEC('CREATE SCHEMA MyTestClass;');
    EXEC('CREATE PROC MyTestClass.myProc AS SELECT 1;');
    EXEC('CREATE PROC MyTestClass.TestCaseA AS EXEC tSQLt.AssertObjectExists ''MyTestClass.myProc'', '''', ''SQL_STORED_PROCEDURE'';');

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

CREATE PROC AssertObjectExistsTests.test_AssertObjectExists_type_comparison_is_case_insensitive
AS
BEGIN
    DECLARE @ErrorRaised INT; SET @ErrorRaised = 0;

    EXEC('CREATE SCHEMA MyTestClass;');
    EXEC('CREATE TABLE MyTestClass.tbl(i int);');
    EXEC('CREATE PROC MyTestClass.TestCaseA AS EXEC tSQLt.AssertObjectExists ''MyTestClass.tbl'', '''', ''user_table'';');

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

CREATE PROC AssertObjectExistsTests.test_AssertObjectExists_temp_table_with_correct_type
AS
BEGIN
    DECLARE @ErrorRaised INT; SET @ErrorRaised = 0;

    EXEC('CREATE SCHEMA MyTestClass;');
    CREATE TABLE #TempTbl(i int);
    EXEC('CREATE PROC MyTestClass.TestCaseA AS EXEC tSQLt.AssertObjectExists ''#TempTbl'', '''', ''USER_TABLE'';');

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

CREATE PROC AssertObjectExistsTests.test_AssertObjectExists_fails_when_expecting_procedure_but_got_table
AS
BEGIN
    EXEC('CREATE SCHEMA schemaA');
    EXEC('CREATE TABLE schemaA.myTable(i int);');

    DECLARE @Command NVARCHAR(MAX);
    SET @Command = 'EXEC tSQLt.AssertObjectExists ''schemaA.myTable'', '''', ''SQL_STORED_PROCEDURE''';
    EXEC tSQLt_testutil.assertFailCalled @Command, 'AssertObjectExists did not call Fail when expecting procedure but found table';
END;
GO
