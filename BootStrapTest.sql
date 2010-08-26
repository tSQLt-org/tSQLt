/*
TODO
====
- Test SCHEMA name same as existing dbo. procedure name prevents running test cases! ->Rule: SCHEMA wins
- table compare of table compare result fails???
- inject code in spyproc and store all execs for all spys in one table (NO XML :( )
- cleanup hanging transactions on start???
- asserSpyProc[Not]Called
- applyConstraint and triggers
- make parameters for procedures consistent (either always pass schema name or pass schema.object)See: select OBJECT_NAME(id) ProcName,* from syscolumns where id in (select object_id from sys.procedures where schema_id = SCHEMA_ID('tSQLt')) ORDER BY ProcName

-- rewrite AssertEqualsTable
  - varbinary
  - large number of rows
-- AssertLike
-- TryBlockHelperProcedure
-- DropObject
-- UndoLog
-- Create Class should add extended property
*/

DECLARE @msg VARCHAR(MAX);SELECT @msg = 'Executed at '+CONVERT(VARCHAR,GETDATE(),121);RAISERROR(@msg,0,1);
GO
SET NOCOUNT ON
WHILE @@TRANCOUNT>0 ROLLBACK;
GO

EXEC tSQLt.RunTestClass 'tSQLt_test';
EXEC tSQLt.RunTestClass 'tSQLtclr_test';
EXEC tSQLt.RunTestClass 'tSQLtPrivate_test';
GO

WHILE @@TRANCOUNT>0 ROLLBACK;
-------------------------------------------------------------------------------------------------------
RAISERROR('',0,1) WITH NOWAIT;
RAISERROR('------------------------------------------------------------------------',0,1) WITH NOWAIT;
RAISERROR('---------- The following are the BootStrapTestCases --------------------',0,1) WITH NOWAIT;
RAISERROR('------------------------------------------------------------------------',0,1) WITH NOWAIT;
IF OBJECT_ID('BootStrapTestCaseFailures') IS NOT NULL DROP TABLE BootStrapTestCaseFailures;
CREATE TABLE BootStrapTestCaseFailures(c CHAR(1));

-- Test case can be executed
RAISERROR('------------------------------------------------------------------------',0,1) WITH NOWAIT;
RAISERROR('---------- Test case can be executed',0,1) WITH NOWAIT;

DECLARE @Failed INT;SET @Failed = 0;
BEGIN TRAN
EXEC('CREATE PROCEDURE TestCase AS
       DECLARE @m VARCHAR(MAX);
       SET @m=''TestCase was executed! (42)'';
       RAISERROR(@m,16,10);');

EXEC tSQLt.RunTest 'TestCase';

BEGIN TRY
    IF NOT EXISTS(SELECT 1 FROM tSQLt.TestResult WHERE msg LIKE 'TestCase was executed! (42)%')
        RAISERROR('TestCase was not executed',16,10);

    PRINT 'Test passed';
END TRY
BEGIN CATCH
    DECLARE @msg VARCHAR(MAX);SET @msg='Test failed:'+ERROR_MESSAGE();
    RAISERROR(@msg,16,10);
    SET @Failed = 1;
END CATCH
ROLLBACK
INSERT BootStrapTestCaseFailures SELECT CASE WHEN @Failed = 1 THEN 'F' ELSE 'P' END;
GO

-- Test case execution reports success of the test
RAISERROR('------------------------------------------------------------------------',0,1) WITH NOWAIT;
RAISERROR('---------- Test case execution reports success of the test',0,1) WITH NOWAIT;

DECLARE @Failed INT;SET @Failed = 0;
BEGIN TRAN
EXEC('CREATE PROCEDURE dbo.SucceedingTestCase AS RETURN 0;');

EXEC tSQLt.RunTest 'dbo.SucceedingTestCase';

BEGIN TRY
    IF NOT EXISTS(SELECT 1 FROM tSQLt.TestResult WHERE TestCase = 'SucceedingTestCase' AND result = 'Success')
          RAISERROR('SucceedingTestCase was not logged correctly in TestResult Table.',16,10);

    PRINT 'Test Passed';
END TRY
BEGIN CATCH
    DECLARE @msg VARCHAR(MAX);SET @msg='Test failed:'+ERROR_MESSAGE();
    RAISERROR(@msg,16,10);
    SET @Failed = 1;
END CATCH

ROLLBACK
INSERT BootStrapTestCaseFailures SELECT CASE WHEN @Failed = 1 THEN 'F' ELSE 'P' END;
GO

-- Test case execution reports failure of the test
RAISERROR('------------------------------------------------------------------------',0,1) WITH NOWAIT;
RAISERROR('---------- Test case execution reports failure of the test',0,1) WITH NOWAIT;

DECLARE @Failed INT;SET @Failed = 0;
BEGIN TRAN
EXEC('CREATE PROCEDURE dbo.FailingTestCase AS EXEC tSQLt.Fail; RETURN 0;');

EXEC tSQLt.RunTest 'dbo.FailingTestCase';

BEGIN TRY
    IF NOT EXISTS(SELECT 1 FROM tSQLt.TestResult WHERE TestCase = 'FailingTestCase' AND result = 'Failure')
          RAISERROR('FailingTestCase was not logged correctly in TestResult Table.',16,10);

    PRINT 'Test Passed';
END TRY
BEGIN CATCH
    DECLARE @msg VARCHAR(MAX);SET @msg='Test failed:'+ERROR_MESSAGE();
    RAISERROR(@msg,16,10);
    SET @Failed = 1;
END CATCH

ROLLBACK
INSERT BootStrapTestCaseFailures SELECT CASE WHEN @Failed = 1 THEN 'F' ELSE 'P' END;
GO

-- Test case execution reports only one result record when it fails
RAISERROR('------------------------------------------------------------------------',0,1) WITH NOWAIT;
RAISERROR('---------- Test case execution reports only one result record when it fails',0,1) WITH NOWAIT;

DECLARE @Failed INT;SET @Failed = 0;
BEGIN TRAN

EXEC('CREATE PROCEDURE dbo.FailingTestCase AS EXEC tSQLt.Fail; RETURN 0;');

EXEC tSQLt.RunTest 'dbo.FailingTestCase';

BEGIN TRY
    DECLARE @actualCount INT;
    SELECT @actualCount = COUNT(*) FROM tSQLt.TestResult WHERE TestCase = 'FailingTestCase';

    IF 1 <> @actualCount
        RAISERROR('FailingTestCase was not logged exactly once in TestResult Table. (%i)', 16, 10, @actualCount);

    PRINT 'Test Passed';
END TRY
BEGIN CATCH
    DECLARE @msg VARCHAR(MAX);SET @msg='Test failed:'+ERROR_MESSAGE();
    RAISERROR(@msg,16,10);
    SET @Failed = 1;
END CATCH

ROLLBACK
INSERT BootStrapTestCaseFailures SELECT CASE WHEN @Failed = 1 THEN 'F' ELSE 'P' END;
GO

-- Test case execution reports error when it errors
RAISERROR('------------------------------------------------------------------------',0,1) WITH NOWAIT;
RAISERROR('---------- Test case execution reports error when it errors',0,1) WITH NOWAIT;

DECLARE @Failed INT;SET @Failed = 0;
BEGIN TRAN

EXEC('CREATE PROCEDURE dbo.ErroringTestCase AS SELECT 1/0 col INTO #tmp; RETURN 0;');

EXEC tSQLt.RunTest 'dbo.ErroringTestCase';

BEGIN TRY
    IF NOT EXISTS(SELECT 1 FROM tSQLt.TestResult WHERE TestCase = 'ErroringTestCase' AND result = 'Error')
          RAISERROR('ErroringTestCase was not logged correctly in TestResult Table.',16,10);

    PRINT 'Test Passed';
END TRY
BEGIN CATCH
    DECLARE @msg VARCHAR(MAX);SET @msg='Test failed:'+ERROR_MESSAGE();
    RAISERROR(@msg,16,10);
    SET @Failed = 1;
END CATCH

ROLLBACK
INSERT BootStrapTestCaseFailures SELECT CASE WHEN @Failed = 1 THEN 'F' ELSE 'P' END;
GO

-- Test case can pass along a failure message
RAISERROR('------------------------------------------------------------------------',0,1) WITH NOWAIT;
RAISERROR('---------- Test case can pass along a failure message',0,1) WITH NOWAIT;

DECLARE @Failed INT;SET @Failed = 0;
BEGIN TRAN
DECLARE @errorMessage VARCHAR(MAX); SET @errorMessage = 'There is a reason I failed' + REPLICATE('*', 2400);

EXEC('CREATE PROCEDURE dbo.FailingTestCase AS EXEC tSQLt.Fail ''' + @errorMessage + '''; RETURN 0;');

EXEC tSQLt.RunTest 'dbo.FailingTestCase';

BEGIN TRY
    DECLARE @actualMessage VARCHAR(MAX);

    SELECT @actualMessage = Msg
      FROM tSQLt.TestResult
     WHERE TestCase = 'FailingTestCase';

    IF @actualMessage = @errorMessage
        PRINT 'Test Passed';
    ELSE
        RAISERROR('FailingTestCase did not log the correct message in TestResult Table. Expected: <%s>, but was: <%s>', 16, 10, @errorMessage, @actualMessage);

END TRY
BEGIN CATCH
    DECLARE @msg VARCHAR(MAX);SET @msg='Test failed:'+ERROR_MESSAGE();
    RAISERROR(@msg,16,10);
    SET @Failed = 1;
END CATCH

ROLLBACK
INSERT BootStrapTestCaseFailures SELECT CASE WHEN @Failed = 1 THEN 'F' ELSE 'P' END;
GO

-- All TestCases of a TestClass can be executed
RAISERROR('------------------------------------------------------------------------',0,1) WITH NOWAIT;
RAISERROR('---------- All TestCases of a TestClass can be executed',0,1) WITH NOWAIT;

DECLARE @Failed INT;SET @Failed = 0;
BEGIN TRAN
EXEC('CREATE SCHEMA MyTestClass');
EXEC('CREATE PROCEDURE MyTestClass.TestCaseA AS RETURN 0;');
EXEC('CREATE PROCEDURE MyTestClass.TestCaseB AS RETURN 0;');

EXEC tSQLt.RunTestClass 'MyTestClass';

DECLARE @xml VARCHAR(MAX);
DECLARE @expected VARCHAR(MAX); SET @expected = '<Class>MyTestClass</Class><TestCase>TestCaseA</TestCase><Class>MyTestClass</Class><TestCase>TestCaseB</TestCase>';
BEGIN TRY
    SELECT @xml = (SELECT Class, TestCase FROM tSQLt.TestResult ORDER BY TestCase FOR XML PATH(''));
    IF @xml = @expected
        PRINT 'Test passed';
    ELSE
        RAISERROR('FailingTestCase did not log the correct message in TestResult Table. Expected: <%s>, but was: <%s>', 16, 10, @expected, @xml);
END TRY
BEGIN CATCH
    DECLARE @msg VARCHAR(MAX);SET @msg='Test failed:'+ERROR_MESSAGE();
    RAISERROR(@msg,16,10);
    SET @Failed = 1;
END CATCH
ROLLBACK
INSERT BootStrapTestCaseFailures SELECT CASE WHEN @Failed = 1 THEN 'F' ELSE 'P' END;
GO


-- A single passing test should report an appropriate message
RAISERROR('------------------------------------------------------------------------',0,1) WITH NOWAIT;
RAISERROR('---------- A single passing test should report an appropriate message',0,1) WITH NOWAIT;

DECLARE @Failed INT;SET @Failed = 0;
BEGIN TRAN
EXEC('CREATE TABLE tSQLt.private_Print_Log (message VARCHAR(MAX));');
EXEC('ALTER PROCEDURE tSQLt.private_Print @message VARCHAR(MAX) AS INSERT INTO tSQLt.private_Print_Log (message) VALUES (@message);');

EXEC('CREATE PROCEDURE TestCaseA AS RETURN 0;');

EXEC tSQLt.RunTest 'TestCaseA';

DECLARE @expected VARCHAR(MAX); SET @expected = 'Test Case Summary: 1 test case(s) executed, 1 succeeded, 0 failed, 0 errored.';

DECLARE @actual VARCHAR(MAX);
SELECT @actual = message
  FROM tSQLt.private_Print_Log
 WHERE message LIKE 'Test Case Summary%'

BEGIN TRY
    IF (@actual = @expected)
        PRINT 'Test passed';
    ELSE
        RAISERROR('Expected message not sent to private_Print method. Expected <%s>, but was <%s>', 16, 10, @expected, @actual);
END TRY
BEGIN CATCH
    DECLARE @msg VARCHAR(MAX);SET @msg='Test failed:'+ERROR_MESSAGE();
    RAISERROR(@msg,16,10);
    SET @Failed = 1;
END CATCH
ROLLBACK
INSERT BootStrapTestCaseFailures SELECT CASE WHEN @Failed = 1 THEN 'F' ELSE 'P' END;
GO

-- A single failing test should report an appropriate message
RAISERROR('------------------------------------------------------------------------',0,1) WITH NOWAIT;
RAISERROR('---------- A single failing test should report an appropriate message',0,1) WITH NOWAIT;

DECLARE @Failed INT;SET @Failed = 0;
BEGIN TRAN
EXEC('CREATE TABLE tSQLt.private_Print_Log (message VARCHAR(MAX));');
EXEC('ALTER PROCEDURE tSQLt.private_Print @message VARCHAR(MAX), @severity INT = NULL AS INSERT INTO tSQLt.private_Print_Log (message) VALUES (@message);');

EXEC('CREATE PROCEDURE TestCaseA AS EXEC tSQLt.Fail ''I failed'';');

EXEC tSQLt.RunTest 'TestCaseA';

DECLARE @expected VARCHAR(MAX); SET @expected = 'Test Case Summary: 1 test case(s) executed, 0 succeeded, 1 failed, 0 errored.';

DECLARE @actual VARCHAR(MAX);
SELECT @actual = message
  FROM tSQLt.private_Print_Log
 WHERE message LIKE 'Test Case Summary%'

BEGIN TRY
    IF (@actual = @expected)
        PRINT 'Test passed';
    ELSE
        RAISERROR('Expected message not sent to private_Print method. Expected <%s>, but was <%s>', 16, 10, @expected, @actual);
END TRY
BEGIN CATCH
    DECLARE @msg VARCHAR(MAX);SET @msg='Test failed:'+ERROR_MESSAGE();
    RAISERROR(@msg,16,10);
    SET @Failed = 1;
END CATCH
ROLLBACK
INSERT BootStrapTestCaseFailures SELECT CASE WHEN @Failed = 1 THEN 'F' ELSE 'P' END;
GO

-- A single erroring test should report an appropriate message
RAISERROR('------------------------------------------------------------------------',0,1) WITH NOWAIT;
RAISERROR('---------- A single erroring test should report an appropriate message',0,1) WITH NOWAIT;

DECLARE @Failed INT;SET @Failed = 0;
BEGIN TRAN
EXEC('CREATE TABLE tSQLt.private_Print_Log (message VARCHAR(MAX));');
EXEC('ALTER PROCEDURE tSQLt.private_Print @message VARCHAR(MAX), @severity INT = NULL AS INSERT INTO tSQLt.private_Print_Log (message) VALUES (@message);');

EXEC('CREATE PROCEDURE TestCaseA AS SELECT 1/0 col INTO #tmp;');

EXEC tSQLt.RunTest 'TestCaseA';

DECLARE @expected VARCHAR(MAX); SET @expected = 'Test Case Summary: 1 test case(s) executed, 0 succeeded, 0 failed, 1 errored.';

DECLARE @actual VARCHAR(MAX);
SELECT @actual = message
  FROM tSQLt.private_Print_Log
 WHERE message LIKE 'Test Case Summary%'

BEGIN TRY
    IF (@actual = @expected)
        PRINT 'Test passed';
    ELSE
        RAISERROR('Expected message not sent to private_Print method. Expected <%s>, but was <%s>', 16, 10, @expected, @actual);
END TRY
BEGIN CATCH
    DECLARE @msg VARCHAR(MAX);SET @msg='Test failed:'+ERROR_MESSAGE();
    RAISERROR(@msg,16,10);
    SET @Failed = 1;
END CATCH
ROLLBACK
INSERT BootStrapTestCaseFailures SELECT CASE WHEN @Failed = 1 THEN 'F' ELSE 'P' END;
GO

-- Multiple passing tests in a class should report an appropriate message
RAISERROR('------------------------------------------------------------------------',0,1) WITH NOWAIT;
RAISERROR('---------- Multiple passing tests in a class should report an appropriate message',0,1) WITH NOWAIT;

DECLARE @Failed INT;SET @Failed = 0;
BEGIN TRAN
EXEC('CREATE TABLE tSQLt.private_Print_Log (message VARCHAR(MAX));');
EXEC('ALTER PROCEDURE tSQLt.private_Print @message VARCHAR(MAX), @severity INT AS INSERT INTO tSQLt.private_Print_Log (message) VALUES (@message);');

EXEC('CREATE SCHEMA MyTestClass;');
EXEC('CREATE PROCEDURE MyTestClass.TestCaseA AS RETURN 0;');
EXEC('CREATE PROCEDURE MyTestClass.TestCaseB AS RETURN 0;');

EXEC tSQLt.RunTestClass 'MyTestClass';

DECLARE @expected VARCHAR(MAX); SET @expected = 'Test Case Summary: 2 test case(s) executed, 2 succeeded, 0 failed, 0 errored.';

DECLARE @actual VARCHAR(MAX);
SELECT @actual = message
  FROM tSQLt.private_Print_Log
 WHERE message LIKE 'Test Case Summary%'

BEGIN TRY
    IF (@actual = @expected)
        PRINT 'Test passed';
    ELSE
        RAISERROR('Expected message not sent to private_Print method. Expected <%s>, but was <%s>', 16, 10, @expected, @actual);
END TRY
BEGIN CATCH
    DECLARE @msg VARCHAR(MAX);SET @msg='Test failed:'+ERROR_MESSAGE();
    RAISERROR(@msg,16,10);
    SET @Failed = 1;
END CATCH
ROLLBACK
INSERT BootStrapTestCaseFailures SELECT CASE WHEN @Failed = 1 THEN 'F' ELSE 'P' END;
GO

-- Passing and failing tests in a class should report an appropriate message
RAISERROR('------------------------------------------------------------------------',0,1) WITH NOWAIT;
RAISERROR('---------- Passing and failing tests in a class should report an appropriate message',0,1) WITH NOWAIT;

DECLARE @Failed INT;SET @Failed = 0;
BEGIN TRAN
EXEC('CREATE TABLE tSQLt.private_Print_Log (message VARCHAR(MAX));');
EXEC('ALTER PROCEDURE tSQLt.private_Print @message VARCHAR(MAX), @severity INT AS INSERT INTO tSQLt.private_Print_Log (message) VALUES (@message);');

EXEC('CREATE SCHEMA MyTestClass;');
EXEC('CREATE PROCEDURE MyTestClass.TestCaseA AS RETURN 0;');
EXEC('CREATE PROCEDURE MyTestClass.TestCaseB AS EXEC tSQLt.Fail;');

EXEC tSQLt.RunTestClass 'MyTestClass';

DECLARE @expected VARCHAR(MAX); SET @expected = 'Test Case Summary: 2 test case(s) executed, 1 succeeded, 1 failed, 0 errored.';

DECLARE @actual VARCHAR(MAX);
SELECT @actual = message
  FROM tSQLt.private_Print_Log
 WHERE message LIKE 'Test Case Summary%'

BEGIN TRY
    IF (@actual = @expected)
        PRINT 'Test passed';
    ELSE
        RAISERROR('Expected message not sent to private_Print method. Expected <%s>, but was <%s>', 16, 10, @expected, @actual);
END TRY
BEGIN CATCH
    DECLARE @msg VARCHAR(MAX);SET @msg='Test failed:'+ERROR_MESSAGE();
    RAISERROR(@msg,16,10);
    SET @Failed = 1;
END CATCH
ROLLBACK
INSERT BootStrapTestCaseFailures SELECT CASE WHEN @Failed = 1 THEN 'F' ELSE 'P' END;
GO

-- tSQLt.DropClass removes SCHEMA with procedure
RAISERROR('------------------------------------------------------------------------',0,1) WITH NOWAIT;
RAISERROR('---------- tSQLt.DropClass removes SCHEMA with procedure',0,1) WITH NOWAIT;

DECLARE @Failed INT;SET @Failed = 0;
BEGIN TRAN
EXEC('CREATE SCHEMA MyTestClass;');
EXEC('CREATE PROCEDURE MyTestClass.TestCaseA AS RETURN 0;');

BEGIN TRY
    EXEC tSQLt.DropClass 'MyTestClass'

    IF EXISTS(SELECT 1 FROM sys.schemas WHERE name = 'MyTestClass') 
        RAISERROR('DropClass did not drop the complete schema.', 16, 10);
       
    PRINT 'Test passed';
END TRY
BEGIN CATCH
    DECLARE @msg VARCHAR(MAX);SET @msg='Test failed:'+ERROR_MESSAGE();
    RAISERROR(@msg,16,10);
    SET @Failed = 1;
END CATCH
ROLLBACK
INSERT BootStrapTestCaseFailures SELECT CASE WHEN @Failed = 1 THEN 'F' ELSE 'P' END;
GO

-- tSQLt.DropClass removes SCHEMA with table
RAISERROR('------------------------------------------------------------------------',0,1) WITH NOWAIT;
RAISERROR('---------- tSQLt.DropClass removes SCHEMA with table',0,1) WITH NOWAIT;

DECLARE @Failed INT;SET @Failed = 0;
BEGIN TRAN
EXEC('CREATE SCHEMA MyTestClass;');
EXEC('CREATE TABLE MyTestClass.TestTable(a INT);');

BEGIN TRY
    EXEC tSQLt.DropClass 'MyTestClass'

    IF EXISTS(SELECT 1 FROM sys.schemas WHERE name = 'MyTestClass') 
        RAISERROR('DropClass did not drop the complete schema.', 16, 10);
       
    PRINT 'Test passed';
END TRY
BEGIN CATCH
    DECLARE @msg VARCHAR(MAX);SET @msg='Test failed:'+ERROR_MESSAGE();
    RAISERROR(@msg,16,10);
    SET @Failed = 1;
END CATCH
ROLLBACK
INSERT BootStrapTestCaseFailures SELECT CASE WHEN @Failed = 1 THEN 'F' ELSE 'P' END;
GO

-- tSQLt.DropClass removes SCHEMA with view
RAISERROR('------------------------------------------------------------------------',0,1) WITH NOWAIT;
RAISERROR('---------- tSQLt.DropClass removes SCHEMA with view',0,1) WITH NOWAIT;

DECLARE @Failed INT;SET @Failed = 0;
BEGIN TRAN
EXEC('CREATE SCHEMA MyTestClass;');
EXEC('CREATE VIEW MyTestClass.TestView AS SELECT 0 x;');

BEGIN TRY
    EXEC tSQLt.DropClass 'MyTestClass'

    IF EXISTS(SELECT 1 FROM sys.schemas WHERE name = 'MyTestClass') 
        RAISERROR('DropClass did not drop the complete schema.', 16, 10);
       
    PRINT 'Test passed';
END TRY
BEGIN CATCH
    DECLARE @msg VARCHAR(MAX);SET @msg='Test failed:'+ERROR_MESSAGE();
    RAISERROR(@msg,16,10);
    SET @Failed = 1;
END CATCH
ROLLBACK
INSERT BootStrapTestCaseFailures SELECT CASE WHEN @Failed = 1 THEN 'F' ELSE 'P' END;
GO

-- tSQLt.DropClass removes SCHEMA with function
RAISERROR('------------------------------------------------------------------------',0,1) WITH NOWAIT;
RAISERROR('---------- tSQLt.DropClass removes SCHEMA with function',0,1) WITH NOWAIT;

DECLARE @Failed INT;SET @Failed = 0;
BEGIN TRAN
EXEC('CREATE SCHEMA MyTestClass;');
EXEC('CREATE FUNCTION MyTestClass.TestFunction() RETURNS INT AS BEGIN RETURN 0; END;');

BEGIN TRY
    EXEC tSQLt.DropClass 'MyTestClass'

    IF EXISTS(SELECT 1 FROM sys.schemas WHERE name = 'MyTestClass') 
        RAISERROR('DropClass did not drop the complete schema.', 16, 10);
       
    PRINT 'Test passed';
END TRY
BEGIN CATCH
    DECLARE @msg VARCHAR(MAX);SET @msg='Test failed:'+ERROR_MESSAGE();
    RAISERROR(@msg,16,10);
    SET @Failed = 1;
END CATCH
ROLLBACK
INSERT BootStrapTestCaseFailures SELECT CASE WHEN @Failed = 1 THEN 'F' ELSE 'P' END;
GO

-- tSQLt.DropClass quietly ignores missing schema
RAISERROR('------------------------------------------------------------------------',0,1) WITH NOWAIT;
RAISERROR('---------- tSQLt.DropClass quietly ignores missing schema',0,1) WITH NOWAIT;

DECLARE @Failed INT;SET @Failed = 0;
BEGIN TRAN

BEGIN TRY
    EXEC tSQLt.DropClass 'MyTestClass'

    PRINT 'Test passed';
END TRY
BEGIN CATCH
    DECLARE @msg VARCHAR(MAX);SET @msg='Test failed:'+ERROR_MESSAGE();
    RAISERROR(@msg,16,10);
    SET @Failed = 1;
END CATCH
ROLLBACK
INSERT BootStrapTestCaseFailures SELECT CASE WHEN @Failed = 1 THEN 'F' ELSE 'P' END;
GO

RAISERROR('------------------------------------------------------------------------',0,1) WITH NOWAIT;
RAISERROR('---------- End of BootStrapTestCases -----------------------------------',0,1) WITH NOWAIT;
RAISERROR('------------------------------------------------------------------------',0,1) WITH NOWAIT;

SELECT COUNT(1) NoOfTestCases, COUNT(CASE WHEN c = 'P' THEN 1 END) PassingTests, COUNT(CASE WHEN c = 'F' THEN 1 END) FailingTests
  FROM BootStrapTestCaseFailures;

DROP TABLE BootStrapTestCaseFailures;