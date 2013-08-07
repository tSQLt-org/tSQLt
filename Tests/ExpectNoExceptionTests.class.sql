EXEC tSQLt.NewTestClass 'ExpectNoExceptionTests';
GO
CREATE PROCEDURE ExpectNoExceptionTests.[test does not fail if no exception is encountered]
AS
BEGIN
  EXEC tSQLt.ExpectNoException;
END;
GO
CREATE PROCEDURE ExpectNoExceptionTests.[test tSQLt.ExpectNoException causes test with exception to fail ]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingNoException AS EXEC tSQLt.ExpectNoException;RAISERROR(''testerror'',16,10);');

    EXEC tSQLt_testutil.AssertTestFails 'MyTestClass.TestExpectingNoException';
END;
GO
CREATE PROCEDURE ExpectNoExceptionTests.[test fails if called more then once]
AS
BEGIN
  EXEC tSQLt.ExpectException @ExpectedMessage = 'Each test can only contain one call to tSQLt.ExpectException or tSQLt.ExpectNoException.', @ExpectedSeverity = 16, @ExpectedState = 10;
  EXEC tSQLt.ExpectNoException;
  EXEC tSQLt.Fail 'This line in the test should not have been reached!';
END;
GO
CREATE PROCEDURE ExpectNoExceptionTests.[test tSQLt.ExpectNoException includes error information in fail message ]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingNoException AS EXEC tSQLt.ExpectNoException;RAISERROR(''test error message'',16,10);');

    DECLARE @ExpectedMessage NVARCHAR(MAX);
    SET @ExpectedMessage = 'Expected no error to be raised. Instead this error was encountered:'+CHAR(13)+CHAR(10)+
                           'test error message[[]16,10]{TestExpectingNoException,1}';
    EXEC tSQLt_testutil.AssertTestFails 'MyTestClass.TestExpectingNoException', @ExpectedMessage;
END;
GO

CREATE PROCEDURE ExpectNoExceptionTests.[test tSQLt.ExpectNoException includes additional message in fail message ]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingNoException AS EXEC tSQLt.ExpectNoException @Message=''Additional Fail Message.'';RAISERROR(''test error message'',16,10);');

    DECLARE @ExpectedMessage NVARCHAR(MAX);
    SET @ExpectedMessage = 'Additional Fail Message. Expected no error to be raised. Instead %';
    EXEC tSQLt_testutil.AssertTestFails 'MyTestClass.TestExpectingNoException', @ExpectedMessage;
END;
GO
