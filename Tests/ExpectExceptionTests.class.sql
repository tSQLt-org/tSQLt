EXEC tSQLt.NewTestClass 'ExpectExceptionTests';
GO
CREATE PROCEDURE ExpectExceptionTests.[test tSQLt.ExpectException causes test without exception to fail ]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingException AS EXEC tSQLt.ExpectException;');

    EXEC tSQLt_testutil.AssertTestFails 'MyTestClass.TestExpectingException';
END;
GO
CREATE PROCEDURE ExpectExceptionTests.[test tSQLt.ExpectException with no parms produces default fail message ]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingException AS EXEC tSQLt.ExpectException;');

    EXEC tSQLt_testutil.AssertTestFails 'MyTestClass.TestExpectingException','Expected an error to be raised.';
END;
GO
CREATE PROCEDURE ExpectExceptionTests.[test expecting exception passes when error is raised]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingException AS EXEC tSQLt.ExpectException;RAISERROR(''X'',16,10);');

    EXEC tSQLt_testutil.AssertTestSucceeds 'MyTestClass.TestExpectingException';
END;
GO
CREATE PROCEDURE ExpectExceptionTests.[test expecting message fails when different message is raised]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingException AS EXEC tSQLt.ExpectException @ExpectedMessage = ''Correct Message'';RAISERROR(''Wrong Message'',16,10);');

    EXEC tSQLt_testutil.AssertTestFails 'MyTestClass.TestExpectingException';
END;
GO
CREATE PROCEDURE ExpectExceptionTests.[test expecting message passes when correct message is raised]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingException AS EXEC tSQLt.ExpectException @ExpectedMessage = ''Correct Message'';RAISERROR(''Correct Message'',16,10);');

    EXEC tSQLt_testutil.AssertTestSucceeds 'MyTestClass.TestExpectingException';
END;
GO
CREATE PROCEDURE ExpectExceptionTests.[test expecting message can contain wildcards]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingException AS EXEC tSQLt.ExpectException @ExpectedMessage = ''Correct [Msg]'';RAISERROR(''Correct [Msg]'',16,10);');

    EXEC tSQLt_testutil.AssertTestSucceeds 'MyTestClass.TestExpectingException';
END;
GO
CREATE PROCEDURE ExpectExceptionTests.[test raising wrong message produces meaningful output]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingException AS EXEC tSQLt.ExpectException @ExpectedMessage = ''Correct Message'';RAISERROR(''Wrong Message'',16,10);');

    DECLARE @ExpectedMessage NVARCHAR(MAX);
    SET @ExpectedMessage = '%Expected Message: <Correct Message>'+CHAR(13)+CHAR(10)+
                           'Actual Message  : <Wrong Message>';
    EXEC tSQLt_testutil.AssertTestFails 'MyTestClass.TestExpectingException',@ExpectedMessage;

END;
GO
CREATE PROCEDURE ExpectExceptionTests.[test expecting severity fails when unexpected severity is used]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingException AS EXEC tSQLt.ExpectException @ExpectedSeverity = 13;RAISERROR(''Message'',15,10);');

    EXEC tSQLt_testutil.AssertTestFails 'MyTestClass.TestExpectingException';
END;
GO
CREATE PROCEDURE ExpectExceptionTests.[test expecting severity succeeds when expected severity is used]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingException AS EXEC tSQLt.ExpectException @ExpectedSeverity = 13;RAISERROR(''Message'',13,10);');

    EXEC tSQLt_testutil.AssertTestSucceeds 'MyTestClass.TestExpectingException';
END;
GO
CREATE PROCEDURE ExpectExceptionTests.[test expecting state fails when unexpected state is used]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingException AS EXEC tSQLt.ExpectException @ExpectedState = 7;RAISERROR(''Message'',15,6);');

    EXEC tSQLt_testutil.AssertTestFails 'MyTestClass.TestExpectingException';
END;
GO
CREATE PROCEDURE ExpectExceptionTests.[test expecting state passes when expected state is used]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingException AS EXEC tSQLt.ExpectException @ExpectedState = 7;RAISERROR(''Message'',15,7);');

    EXEC tSQLt_testutil.AssertTestSucceeds 'MyTestClass.TestExpectingException';
END;
GO
CREATE PROCEDURE ExpectExceptionTests.[test raising wrong severity produces meaningful output]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingException AS EXEC tSQLt.ExpectException @ExpectedSeverity=13;RAISERROR('''',14,10);');

    DECLARE @ExpectedMessage NVARCHAR(MAX);
    SET @ExpectedMessage = '%Expected Severity: 13'+CHAR(13)+CHAR(10)+
                           'Actual Severity  : 14';

    EXEC tSQLt_testutil.AssertTestFails 'MyTestClass.TestExpectingException',@ExpectedMessage;
END;
GO
CREATE PROCEDURE ExpectExceptionTests.[test raising wrong state produces meaningful output]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingException AS EXEC tSQLt.ExpectException @ExpectedState=13;RAISERROR('''',14,10);');

    DECLARE @ExpectedMessage NVARCHAR(MAX);
    SET @ExpectedMessage = '%Expected State: 13'+CHAR(13)+CHAR(10)+
                           'Actual State  : 10';

    EXEC tSQLt_testutil.AssertTestFails 'MyTestClass.TestExpectingException',@ExpectedMessage;
END;
GO
CREATE PROCEDURE ExpectExceptionTests.[test expecting MessagePattern handles wildcards]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingException AS EXEC tSQLt.ExpectException @ExpectedMessagePattern = ''Cor[rt]ect%'';RAISERROR(''Correct [Msg]'',16,10);');

    EXEC tSQLt_testutil.AssertTestSucceeds 'MyTestClass.TestExpectingException';
END;
GO
CREATE PROCEDURE ExpectExceptionTests.[test output includes additional message]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingException AS EXEC tSQLt.ExpectException @ExpectedMessage=''Correct'', @Message=''Additional Fail Message.'';RAISERROR(''Wrong'',12,6);');

    DECLARE @ExpectedMessage NVARCHAR(MAX);
    SET @ExpectedMessage = 'Additional Fail Message. Exception did not match expectation!'+CHAR(13)+CHAR(10)+
                           'Expected Message: <Correct>'+CHAR(13)+CHAR(10)+
                           'Actual Message  : <Wrong>';

    EXEC tSQLt_testutil.AssertTestFails 'MyTestClass.TestExpectingException',@ExpectedMessage;
END;
GO
CREATE PROCEDURE ExpectExceptionTests.[test output includes additional message if no other expectations]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingException AS EXEC tSQLt.ExpectException @Message=''Additional Fail Message.'';');

    DECLARE @ExpectedMessage NVARCHAR(MAX);
    SET @ExpectedMessage = 'Additional Fail Message. Expected an error to be raised.';

    EXEC tSQLt_testutil.AssertTestFails 'MyTestClass.TestExpectingException',@ExpectedMessage;
END;
GO
CREATE PROCEDURE ExpectExceptionTests.[test fails if called more then once]
AS
BEGIN
  EXEC tSQLt.ExpectException @ExpectedMessage = 'Each test can only contain one call to tSQLt.ExpectException or tSQLt.ExpectNoException.', @ExpectedSeverity = 16, @ExpectedState = 10;
  EXEC tSQLt.ExpectException @ExpectedMessage = 'This call of tSQLt.ExpectException should have failed...';
  EXEC tSQLt.Fail 'This line in the test should not have been reached!';
END;
GO
CREATE PROCEDURE ExpectExceptionTests.[test expecting error number fails when unexpected error number is used]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingException AS EXEC tSQLt.ExpectException @ExpectedErrorNumber = 50001;RAISERROR(''Message'',16,10);');

    EXEC tSQLt_testutil.AssertTestFails 'MyTestClass.TestExpectingException';
END;
GO
CREATE PROCEDURE ExpectExceptionTests.[test expecting error number passes when expected error number is used]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingException AS EXEC tSQLt.ExpectException @ExpectedErrorNumber = 50000;RAISERROR(''Message'',16,10);');

    EXEC tSQLt_testutil.AssertTestSucceeds 'MyTestClass.TestExpectingException';
END;
GO
CREATE PROCEDURE ExpectExceptionTests.[test raising wrong error number produces meaningful output]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingException AS EXEC tSQLt.ExpectException @ExpectedErrorNumber = 50001;RAISERROR(''Message'',16,10);');

    DECLARE @ExpectedMessage NVARCHAR(MAX);
    SET @ExpectedMessage = '%Expected Error Number: 50001'+CHAR(13)+CHAR(10)+
                           'Actual Error Number  : 50000';

    EXEC tSQLt_testutil.AssertTestFails 'MyTestClass.TestExpectingException',@ExpectedMessage;
END;
GO
CREATE PROCEDURE ExpectExceptionTests.[test output includes every incorrect part]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingException AS EXEC tSQLt.ExpectException @ExpectedErrorNumber = 50001,@ExpectedMessage=''Correct'',@ExpectedSeverity=11,@ExpectedState=9;RAISERROR(''Wrong'',12,6);');

    DECLARE @ExpectedMessage NVARCHAR(MAX);
    SET @ExpectedMessage = 'Exception did not match expectation!'+CHAR(13)+CHAR(10)+
                           'Expected Message: <Correct>'+CHAR(13)+CHAR(10)+
                           'Actual Message  : <Wrong>'+CHAR(13)+CHAR(10)+
                           'Expected Error Number: 50001'+CHAR(13)+CHAR(10)+
                           'Actual Error Number  : 50000'+CHAR(13)+CHAR(10)+
                           'Expected Severity: 11'+CHAR(13)+CHAR(10)+
                           'Actual Severity  : 12'+CHAR(13)+CHAR(10)+
                           'Expected State: 9'+CHAR(13)+CHAR(10)+
                           'Actual State  : 6';

    EXEC tSQLt_testutil.AssertTestFails 'MyTestClass.TestExpectingException',@ExpectedMessage;
END;
GO
CREATE PROCEDURE ExpectExceptionTests.[test output includes every incorrect part including the MessagePattern]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingException AS EXEC tSQLt.ExpectException @ExpectedErrorNumber = 50001,@ExpectedMessagePattern=''Cor[rt]ect'',@ExpectedSeverity=11,@ExpectedState=9;RAISERROR(''Wrong'',12,6);');

    DECLARE @ExpectedMessage NVARCHAR(MAX);
    SET @ExpectedMessage = 'Exception did not match expectation!'+CHAR(13)+CHAR(10)+
                           'Expected Message to be like <Cor[[]rt]ect>'+CHAR(13)+CHAR(10)+
                           'Actual Message            : <Wrong>'+CHAR(13)+CHAR(10)+
                           'Expected Error Number: 50001'+CHAR(13)+CHAR(10)+
                           'Actual Error Number  : 50000'+CHAR(13)+CHAR(10)+
                           'Expected Severity: 11'+CHAR(13)+CHAR(10)+
                           'Actual Severity  : 12'+CHAR(13)+CHAR(10)+
                           'Expected State: 9'+CHAR(13)+CHAR(10)+
                           'Actual State  : 6';

    EXEC tSQLt_testutil.AssertTestFails 'MyTestClass.TestExpectingException',@ExpectedMessage;
END;
GO

