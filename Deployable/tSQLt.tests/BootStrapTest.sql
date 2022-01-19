/*
   Copyright 2011 tSQLt

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/

DECLARE @msg VARCHAR(MAX);SELECT @msg = 'Executed at '+CONVERT(VARCHAR,GETDATE(),121);RAISERROR(@msg,0,1);
GO
SET NOCOUNT ON
WHILE @@TRANCOUNT>0 ROLLBACK;
GO
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
EXEC tSQLt.NewTestClass 'MyTestClass';

EXEC('CREATE PROCEDURE MyTestClass.TestCase AS
       DECLARE @m VARCHAR(MAX);
       SET @m=''TestCase was executed! (42)'';
       RAISERROR(@m,16,10);');
BEGIN TRY
  EXEC tSQLt.Run 'MyTestClass.TestCase';
END TRY
BEGIN CATCH
  DECLARE @m NVARCHAR(MAX);
  SET @m=ERROR_MESSAGE();
  RAISERROR(@m,0,1);
END CATCH;

BEGIN TRY
    IF NOT EXISTS(SELECT 1 FROM tSQLt.TestResult WHERE Msg LIKE 'TestCase was executed! (42)%')
        RAISERROR('TestCase was not executed',16,10);

    PRINT 'Test passed';
END TRY
BEGIN CATCH
    DECLARE @msg VARCHAR(MAX);SET @msg='Test failed:'+ERROR_Message();
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
EXEC tSQLt.NewTestClass 'MyTestClass';
EXEC('CREATE PROCEDURE MyTestClass.testSucceedingTestCase AS RETURN 0;');

BEGIN TRY
  EXEC tSQLt.Run 'MyTestClass.testSucceedingTestCase';
END TRY
BEGIN CATCH
  DECLARE @m NVARCHAR(MAX);
  SET @m=ERROR_MESSAGE();
  RAISERROR(@m,0,1);
END CATCH;

BEGIN TRY
    IF NOT EXISTS(SELECT 1 FROM tSQLt.TestResult WHERE TestCase = 'testSucceedingTestCase' AND Result = 'Success')
          RAISERROR('testSucceedingTestCase was not logged correctly in TestResult Table.',16,10);

    PRINT 'Test Passed';
END TRY
BEGIN CATCH
    DECLARE @msg VARCHAR(MAX);SET @msg='Test failed:'+ERROR_Message();
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
EXEC tSQLt.NewTestClass 'MyTestClass';
EXEC('CREATE PROCEDURE MyTestClass.testFailingTestCase AS EXEC tSQLt.Fail; RETURN 0;');

BEGIN TRY
  EXEC tSQLt.Run 'MyTestClass.testFailingTestCase';
END TRY
BEGIN CATCH
  DECLARE @m NVARCHAR(MAX);
  SET @m=ERROR_MESSAGE();
  RAISERROR(@m,0,1);
END CATCH;

BEGIN TRY
    IF NOT EXISTS(SELECT 1 FROM tSQLt.TestResult WHERE TestCase = 'testFailingTestCase' AND Result = 'Failure')
          RAISERROR('testFailingTestCase was not logged correctly in TestResult Table.',16,10);

    PRINT 'Test Passed';
END TRY
BEGIN CATCH
    DECLARE @msg VARCHAR(MAX);SET @msg='Test failed:'+ERROR_Message();
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
EXEC tSQLt.NewTestClass 'MyTestClass';

EXEC('CREATE PROCEDURE MyTestClass.testFailingTestCase AS EXEC tSQLt.Fail; RETURN 0;');

BEGIN TRY
  EXEC tSQLt.Run 'MyTestClass.testFailingTestCase';
END TRY
BEGIN CATCH
  DECLARE @m NVARCHAR(MAX);
  SET @m=ERROR_MESSAGE();
  RAISERROR(@m,0,1);
END CATCH;

BEGIN TRY
    DECLARE @actualCount INT;
    SELECT @actualCount = COUNT(*) FROM tSQLt.TestResult WHERE TestCase = 'testFailingTestCase';

    IF 1 <> @actualCount
        RAISERROR('testFailingTestCase was not logged exactly once in TestResult Table. (%i)', 16, 10, @actualCount);

    PRINT 'Test Passed';
END TRY
BEGIN CATCH
    DECLARE @msg VARCHAR(MAX);SET @msg='Test failed:'+ERROR_Message();
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
EXEC tSQLt.NewTestClass 'MyTestClass';

EXEC('CREATE PROCEDURE MyTestClass.testErroringTestCase AS SELECT 1/0 col INTO #tmp; RETURN 0;');

BEGIN TRY
  EXEC tSQLt.Run 'MyTestClass.testErroringTestCase';
END TRY
BEGIN CATCH
  DECLARE @m NVARCHAR(MAX);
  SET @m=ERROR_MESSAGE();
  RAISERROR(@m,0,1);
END CATCH;

BEGIN TRY
    IF NOT EXISTS(SELECT 1 FROM tSQLt.TestResult WHERE TestCase = 'testErroringTestCase' AND Result = 'Error')
          RAISERROR('testErroringTestCase was not logged correctly in TestResult Table.',16,10);

    PRINT 'Test Passed';
END TRY
BEGIN CATCH
    DECLARE @msg VARCHAR(MAX);SET @msg='Test failed:'+ERROR_Message();
    RAISERROR(@msg,16,10);
    SET @Failed = 1;
END CATCH

ROLLBACK
INSERT BootStrapTestCaseFailures SELECT CASE WHEN @Failed = 1 THEN 'F' ELSE 'P' END;
GO

-- Test case can pass along a failure Message
RAISERROR('------------------------------------------------------------------------',0,1) WITH NOWAIT;
RAISERROR('---------- Test case can pass along a failure Message',0,1) WITH NOWAIT;

DECLARE @Failed INT;SET @Failed = 0;
BEGIN TRAN
DECLARE @errorMessage VARCHAR(MAX); SET @errorMessage = 'There is a reason I failed' + REPLICATE('*', 2400);
EXEC tSQLt.NewTestClass 'MyTestClass';

EXEC('CREATE PROCEDURE MyTestClass.testFailingTestCase AS EXEC tSQLt.Fail ''' + @errorMessage + '''; RETURN 0;');

BEGIN TRY
  EXEC tSQLt.Run 'MyTestClass.testFailingTestCase';
END TRY
BEGIN CATCH
  DECLARE @m NVARCHAR(MAX);
  SET @m=ERROR_MESSAGE();
  RAISERROR(@m,0,1);
END CATCH;

BEGIN TRY
    DECLARE @actualMessage VARCHAR(MAX);

    SELECT @actualMessage = Msg
      FROM tSQLt.TestResult
     WHERE TestCase = 'testFailingTestCase';

    IF @actualMessage = @errorMessage
        PRINT 'Test Passed';
    ELSE
        RAISERROR('testFailingTestCase did not log the correct Message in TestResult Table. Expected: <%s>, but was: <%s>', 16, 10, @errorMessage, @actualMessage);

END TRY
BEGIN CATCH
    DECLARE @msg VARCHAR(MAX);SET @msg='Test failed:'+ERROR_Message();
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
EXEC('EXEC tSQLt.NewTestClass ''MyTestClass'';');
EXEC('CREATE PROCEDURE MyTestClass.TestCaseA AS RETURN 0;');
EXEC('CREATE PROCEDURE MyTestClass.TestCaseB AS RETURN 0;');

BEGIN TRY
  EXEC tSQLt.RunTestClass 'MyTestClass';
END TRY
BEGIN CATCH
  DECLARE @m NVARCHAR(MAX);
  SET @m=ERROR_MESSAGE();
  RAISERROR(@m,0,1);
END CATCH;

DECLARE @xml VARCHAR(MAX);
DECLARE @expected VARCHAR(MAX); SET @expected = '<Class>MyTestClass</Class><TestCase>TestCaseA</TestCase><Class>MyTestClass</Class><TestCase>TestCaseB</TestCase>';
BEGIN TRY
    SELECT @xml = (SELECT Class, TestCase FROM tSQLt.TestResult ORDER BY TestCase FOR XML PATH(''));
    IF @xml = @expected
        PRINT 'Test passed';
    ELSE
        RAISERROR('FailingTestCase did not log the correct Message in TestResult Table. Expected: <%s>, but was: <%s>', 16, 10, @expected, @xml);
END TRY
BEGIN CATCH
    DECLARE @msg VARCHAR(MAX);SET @msg='Test failed:'+ERROR_Message();
    RAISERROR(@msg,16,10);
    SET @Failed = 1;
END CATCH
ROLLBACK
INSERT BootStrapTestCaseFailures SELECT CASE WHEN @Failed = 1 THEN 'F' ELSE 'P' END;
GO


-- A single passing test should report an appropriate Message
RAISERROR('------------------------------------------------------------------------',0,1) WITH NOWAIT;
RAISERROR('---------- A single passing test should report an appropriate Message',0,1) WITH NOWAIT;

DECLARE @Failed INT;SET @Failed = 0;
BEGIN TRAN
EXEC('CREATE TABLE tSQLt.Private_Print_Log (Message VARCHAR(MAX));');
EXEC('ALTER PROCEDURE tSQLt.Private_Print @Message0 VARCHAR(MAX),  @Message1 VARCHAR(MAX) = NULL,  @Message2 VARCHAR(MAX) = NULL,  @Message3 VARCHAR(MAX) = NULL,  @Message4 VARCHAR(MAX) = NULL,  @Message5 VARCHAR(MAX) = NULL,  @Message6 VARCHAR(MAX) = NULL,  @Message7 VARCHAR(MAX) = NULL,  @Message8 VARCHAR(MAX) = NULL AS INSERT INTO tSQLt.Private_Print_Log (Message) VALUES (@Message0);');

EXEC tSQLt.NewTestClass 'MyTestClass';

EXEC('CREATE PROCEDURE MyTestClass.TestCaseA AS RETURN 0;');

BEGIN TRY
  EXEC tSQLt.Run 'MyTestClass.TestCaseA';
END TRY
BEGIN CATCH
  DECLARE @m NVARCHAR(MAX);
  SET @m=ERROR_MESSAGE();
  RAISERROR(@m,0,1);
END CATCH;

DECLARE @expected VARCHAR(MAX); SET @expected = 'Test Case Summary: 1 test case(s) executed, 1 succeeded, 0 failed, 0 errored.';

DECLARE @actual VARCHAR(MAX);
SELECT @actual = Message
  FROM tSQLt.Private_Print_Log
 WHERE Message LIKE 'Test Case Summary%'

BEGIN TRY
    IF (@actual = @expected)
        PRINT 'Test passed';
    ELSE
        RAISERROR('Expected Message not sent to Private_Print method. Expected <%s>, but was <%s>', 16, 10, @expected, @actual);
END TRY
BEGIN CATCH
    DECLARE @msg VARCHAR(MAX);SET @msg='Test failed:'+ERROR_Message();
    RAISERROR(@msg,16,10);
    SET @Failed = 1;
END CATCH
ROLLBACK
INSERT BootStrapTestCaseFailures SELECT CASE WHEN @Failed = 1 THEN 'F' ELSE 'P' END;
GO

-- A single failing test should report an appropriate Message
RAISERROR('------------------------------------------------------------------------',0,1) WITH NOWAIT;
RAISERROR('---------- A single failing test should report an appropriate Message',0,1) WITH NOWAIT;

DECLARE @Failed INT;SET @Failed = 0;
BEGIN TRAN
EXEC tSQLt.NewTestClass 'MyTestClass';
EXEC('CREATE TABLE tSQLt.Private_Print_Log (Message VARCHAR(MAX));');
EXEC('ALTER PROCEDURE tSQLt.Private_Print @Message VARCHAR(MAX), @Severity INT = NULL AS INSERT INTO tSQLt.Private_Print_Log (Message) VALUES (@Message);');

EXEC('CREATE PROCEDURE MyTestClass.TestCaseA AS EXEC tSQLt.Fail ''I failed'';');

BEGIN TRY
  EXEC tSQLt.Run 'MyTestClass.TestCaseA';
END TRY
BEGIN CATCH
  DECLARE @m NVARCHAR(MAX);
  SET @m=ERROR_MESSAGE();
  RAISERROR(@m,0,1);
END CATCH;

DECLARE @expected VARCHAR(MAX); SET @expected = 'Test Case Summary: 1 test case(s) executed, 0 succeeded, 1 failed, 0 errored.';

DECLARE @actual VARCHAR(MAX);
SELECT @actual = Message
  FROM tSQLt.Private_Print_Log
 WHERE Message LIKE 'Test Case Summary%'

BEGIN TRY
    IF (@actual = @expected)
        PRINT 'Test passed';
    ELSE
        RAISERROR('Expected Message not sent to Private_Print method. Expected <%s>, but was <%s>', 16, 10, @expected, @actual);
END TRY
BEGIN CATCH
    DECLARE @msg VARCHAR(MAX);SET @msg='Test failed:'+ERROR_Message();
    RAISERROR(@msg,16,10);
    SET @Failed = 1;
END CATCH
ROLLBACK
INSERT BootStrapTestCaseFailures SELECT CASE WHEN @Failed = 1 THEN 'F' ELSE 'P' END;
GO

-- A single erroring test should report an appropriate Message
RAISERROR('------------------------------------------------------------------------',0,1) WITH NOWAIT;
RAISERROR('---------- A single erroring test should report an appropriate Message',0,1) WITH NOWAIT;

DECLARE @Failed INT;SET @Failed = 0;
BEGIN TRAN
EXEC tSQLt.NewTestClass 'MyTestClass';
EXEC('CREATE TABLE tSQLt.Private_Print_Log (Message VARCHAR(MAX));');
EXEC('ALTER PROCEDURE tSQLt.Private_Print @Message VARCHAR(MAX), @Severity INT = NULL AS INSERT INTO tSQLt.Private_Print_Log (Message) VALUES (@Message);');

EXEC('CREATE PROCEDURE MyTestClass.TestCaseA AS SELECT 1/0 col INTO #tmp;');

BEGIN TRY
  EXEC tSQLt.Run 'MyTestClass.TestCaseA';
END TRY
BEGIN CATCH
  DECLARE @m NVARCHAR(MAX);
  SET @m=ERROR_MESSAGE();
  RAISERROR(@m,0,1);
END CATCH;

DECLARE @expected VARCHAR(MAX); SET @expected = 'Test Case Summary: 1 test case(s) executed, 0 succeeded, 0 failed, 1 errored.';

DECLARE @actual VARCHAR(MAX);
SELECT @actual = Message
  FROM tSQLt.Private_Print_Log
 WHERE Message LIKE 'Test Case Summary%'

BEGIN TRY
    IF (@actual = @expected)
        PRINT 'Test passed';
    ELSE
        RAISERROR('Expected Message not sent to Private_Print method. Expected <%s>, but was <%s>', 16, 10, @expected, @actual);
END TRY
BEGIN CATCH
    DECLARE @msg VARCHAR(MAX);SET @msg='Test failed:'+ERROR_Message();
    RAISERROR(@msg,16,10);
    SET @Failed = 1;
END CATCH
ROLLBACK
INSERT BootStrapTestCaseFailures SELECT CASE WHEN @Failed = 1 THEN 'F' ELSE 'P' END;
GO

-- Multiple passing tests in a class should report an appropriate Message
RAISERROR('------------------------------------------------------------------------',0,1) WITH NOWAIT;
RAISERROR('---------- Multiple passing tests in a class should report an appropriate Message',0,1) WITH NOWAIT;

DECLARE @Failed INT;SET @Failed = 0;
BEGIN TRAN

EXEC('CREATE TABLE tSQLt.Private_Print_Log (Message VARCHAR(MAX));');
EXEC('ALTER PROCEDURE tSQLt.Private_Print @Message VARCHAR(MAX), @Severity INT AS INSERT INTO tSQLt.Private_Print_Log (Message) VALUES (@Message);');

EXEC tSQLt.NewTestClass 'MyTestClass';
EXEC('CREATE PROCEDURE MyTestClass.TestCaseA AS RETURN 0;');
EXEC('CREATE PROCEDURE MyTestClass.TestCaseB AS RETURN 0;');

BEGIN TRY
  EXEC tSQLt.RunTestClass 'MyTestClass';
END TRY
BEGIN CATCH
  DECLARE @m NVARCHAR(MAX);
  SET @m=ERROR_MESSAGE();
  RAISERROR(@m,0,1);
END CATCH;

DECLARE @expected VARCHAR(MAX); SET @expected = 'Test Case Summary: 2 test case(s) executed, 2 succeeded, 0 failed, 0 errored.';

DECLARE @actual VARCHAR(MAX);
SELECT @actual = Message
  FROM tSQLt.Private_Print_Log
 WHERE Message LIKE 'Test Case Summary%'

BEGIN TRY
    IF (@actual = @expected)
        PRINT 'Test passed';
    ELSE
        RAISERROR('Expected Message not sent to Private_Print method. Expected <%s>, but was <%s>', 16, 10, @expected, @actual);
END TRY
BEGIN CATCH
    DECLARE @msg VARCHAR(MAX);SET @msg='Test failed:'+ERROR_Message();
    RAISERROR(@msg,16,10);
    SET @Failed = 1;
END CATCH
ROLLBACK
INSERT BootStrapTestCaseFailures SELECT CASE WHEN @Failed = 1 THEN 'F' ELSE 'P' END;
GO

-- Passing and failing tests in a class should report an appropriate Message
RAISERROR('------------------------------------------------------------------------',0,1) WITH NOWAIT;
RAISERROR('---------- Passing and failing tests in a class should report an appropriate Message',0,1) WITH NOWAIT;

DECLARE @Failed INT;SET @Failed = 0;
BEGIN TRAN
EXEC('CREATE TABLE tSQLt.Private_Print_Log (Message VARCHAR(MAX));');
EXEC('ALTER PROCEDURE tSQLt.Private_Print @Message VARCHAR(MAX), @Severity INT AS INSERT INTO tSQLt.Private_Print_Log (Message) VALUES (@Message);');

EXEC tSQLt.NewTestClass 'MyTestClass';
EXEC('CREATE PROCEDURE MyTestClass.TestCaseA AS RETURN 0;');
EXEC('CREATE PROCEDURE MyTestClass.TestCaseB AS EXEC tSQLt.Fail;');

BEGIN TRY
  EXEC tSQLt.RunTestClass 'MyTestClass';
END TRY
BEGIN CATCH
  DECLARE @m NVARCHAR(MAX);
  SET @m=ERROR_MESSAGE();
  RAISERROR(@m,0,1);
END CATCH;

DECLARE @expected VARCHAR(MAX); SET @expected = 'Test Case Summary: 2 test case(s) executed, 1 succeeded, 1 failed, 0 errored.';

DECLARE @actual VARCHAR(MAX);
SELECT @actual = Message
  FROM tSQLt.Private_Print_Log
 WHERE Message LIKE 'Test Case Summary%'

BEGIN TRY
    IF (@actual = @expected)
        PRINT 'Test passed';
    ELSE
        RAISERROR('Expected Message not sent to Private_Print method. Expected <%s>, but was <%s>', 16, 10, @expected, @actual);
END TRY
BEGIN CATCH
    DECLARE @msg VARCHAR(MAX);SET @msg='Test failed:'+ERROR_Message();
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
    DECLARE @msg VARCHAR(MAX);SET @msg='Test failed:'+ERROR_Message();
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
    DECLARE @msg VARCHAR(MAX);SET @msg='Test failed:'+ERROR_Message();
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
    DECLARE @msg VARCHAR(MAX);SET @msg='Test failed:'+ERROR_Message();
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
    DECLARE @msg VARCHAR(MAX);SET @msg='Test failed:'+ERROR_Message();
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
    DECLARE @msg VARCHAR(MAX);SET @msg='Test failed:'+ERROR_Message();
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

DECLARE @ExpectedNumberOfTests INT;SET @ExpectedNumberOfTests = 17;

IF (@ExpectedNumberOfTests != (SELECT COUNT(1) FROM BootStrapTestCaseFailures WHERE c = 'P'))
BEGIN
  RAISERROR('There was at least one test that did not (successfully) execute!',16,10);
END;

DROP TABLE BootStrapTestCaseFailures;