EXEC tSQLt.NewTestClass 'ExpectExceptionTests';
GO
CREATE PROCEDURE ExpectExceptionTests.CaptureTestResult
  @TestName NVARCHAR(MAX),
  @Result NVARCHAR(MAX) OUTPUT,   
  @Msg NVARCHAR(MAX) OUTPUT    
AS
BEGIN
  DECLARE @Cmd NVARCHAR(MAX);    
  SELECT @Cmd = 'EXEC tSQLt.Private_RunTest '+
                QUOTENAME(
                   QUOTENAME(OBJECT_SCHEMA_NAME(OBJECT_ID(@TestName)))+'.'+
                   QUOTENAME(OBJECT_NAME(OBJECT_ID(@TestName))),'''')+';';
  BEGIN TRAN;
  DECLARE @TranName CHAR(32); EXEC tSQLt.GetNewTranName @TranName OUT;
  SAVE TRAN @TranName;
    TRUNCATE TABLE tSQLt.TestResult;
    EXEC tSQLt.SuppressOutput @Cmd
    SELECT @Result = Result, @Msg = Msg FROM tSQLt.TestResult;
  ROLLBACK TRAN @TranName;
  COMMIT TRAN;
END;
GO
CREATE PROCEDURE ExpectExceptionTests.AssertTestFails
  @TestName NVARCHAR(MAX),
  @ExpectedMessage NVARCHAR(MAX) = NULL
AS
BEGIN
    DECLARE @Result NVARCHAR(MAX);
    DECLARE @Msg NVARCHAR(MAX);
    
    EXEC ExpectExceptionTests.CaptureTestResult @TestName, @Result OUTPUT, @Msg OUTPUT;
    
    IF(@Result <> 'Failure')
    BEGIN
      EXEC tSQLt.Fail 'Expected test to fail. Instead it resulted in ',@Result,'. The Message is: "',@Msg,'"';
    END
    
    IF(@ExpectedMessage IS NOT NULL)
    BEGIN
      EXEC tSQLt.AssertLike @ExpectedMessage,@Msg,'Incorrect Fail message used:';
    END
END;
GO
CREATE PROCEDURE ExpectExceptionTests.AssertTestSucceeds
  @TestName NVARCHAR(MAX)
AS
BEGIN
    DECLARE @Result NVARCHAR(MAX);
    DECLARE @Msg NVARCHAR(MAX);
    
    EXEC ExpectExceptionTests.CaptureTestResult @TestName, @Result OUTPUT, @Msg OUTPUT;
    
    IF(@Result <> 'Success')
    BEGIN
      EXEC tSQLt.Fail 'Expected test to succeed. Instead it resulted in ',@Result,'. The Message is: "',@Msg,'"';
    END
END;
GO
CREATE PROCEDURE ExpectExceptionTests.[test tSQLt.ExpectException causes test without exception to fail ]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingException AS EXEC tSQLt.ExpectException;');

    EXEC ExpectExceptionTests.AssertTestFails 'MyTestClass.TestExpectingException';
END;
GO
CREATE PROCEDURE ExpectExceptionTests.[test tSQLt.ExpectException with no parms produces default fail message ]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingException AS EXEC tSQLt.ExpectException;');

    EXEC ExpectExceptionTests.AssertTestFails 'MyTestClass.TestExpectingException','Expected an error to be raised.';
END;
GO
CREATE PROCEDURE ExpectExceptionTests.[test expecting exception passes when error is raised]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingException AS EXEC tSQLt.ExpectException;RAISERROR(''X'',16,10);');

    EXEC ExpectExceptionTests.AssertTestSucceeds 'MyTestClass.TestExpectingException';
END;
GO
CREATE PROCEDURE ExpectExceptionTests.[test expecting message fails when different message is raised]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingException AS EXEC tSQLt.ExpectException ''Correct Message'';RAISERROR(''Wrong Message'',16,10);');

    EXEC ExpectExceptionTests.AssertTestFails 'MyTestClass.TestExpectingException';
END;
GO
CREATE PROCEDURE ExpectExceptionTests.[test expecting message passes when correct message is raised]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingException AS EXEC tSQLt.ExpectException ''Correct Message'';RAISERROR(''Correct Message'',16,10);');

    EXEC ExpectExceptionTests.AssertTestSucceeds 'MyTestClass.TestExpectingException';
END;
GO
CREATE PROCEDURE ExpectExceptionTests.[test expecting message can contain wildcards]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingException AS EXEC tSQLt.ExpectException ''Correct [Msg]'';RAISERROR(''Correct [Msg]'',16,10);');

    EXEC ExpectExceptionTests.AssertTestSucceeds 'MyTestClass.TestExpectingException';
END;
GO
CREATE PROCEDURE ExpectExceptionTests.[test raising wrong message produces meaningful output]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingException AS EXEC tSQLt.ExpectException ''Correct Message'';RAISERROR(''Wrong Message'',16,10);');

    DECLARE @ExpectedMessage NVARCHAR(MAX);
    SET @ExpectedMessage = '%Expected Message: <Correct Message>'+CHAR(13)+CHAR(10)+
                           'Actual Message  : <Wrong Message>';
    EXEC ExpectExceptionTests.AssertTestFails 'MyTestClass.TestExpectingException',@ExpectedMessage;

END;
GO
CREATE PROCEDURE ExpectExceptionTests.[test expecting message fails when unexpected severity is used]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingException AS EXEC tSQLt.ExpectException @Severity = 13;RAISERROR(''Message'',15,10);');

    EXEC ExpectExceptionTests.AssertTestFails 'MyTestClass.TestExpectingException';
END;
GO
CREATE PROCEDURE ExpectExceptionTests.[test expecting message succeeds when expected severity is used]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingException AS EXEC tSQLt.ExpectException @Severity = 13;RAISERROR(''Message'',13,10);');

    EXEC ExpectExceptionTests.AssertTestSucceeds 'MyTestClass.TestExpectingException';
END;
GO
CREATE PROCEDURE ExpectExceptionTests.[test expecting message fails when unexpected state is used]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingException AS EXEC tSQLt.ExpectException @State = 7;RAISERROR(''Message'',15,6);');

    EXEC ExpectExceptionTests.AssertTestFails 'MyTestClass.TestExpectingException';
END;
GO
CREATE PROCEDURE ExpectExceptionTests.[test expecting message passes when expected state is used]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingException AS EXEC tSQLt.ExpectException @State = 7;RAISERROR(''Message'',15,7);');

    EXEC ExpectExceptionTests.AssertTestSucceeds 'MyTestClass.TestExpectingException';
END;
GO
CREATE PROCEDURE ExpectExceptionTests.[test raising wrong severity produces meaningful output]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingException AS EXEC tSQLt.ExpectException @Severity=13;RAISERROR('''',14,10);');

    DECLARE @ExpectedMessage NVARCHAR(MAX);
    SET @ExpectedMessage = '%Expected Severity: 13'+CHAR(13)+CHAR(10)+
                           'Actual Severity  : 14';

    EXEC ExpectExceptionTests.AssertTestFails 'MyTestClass.TestExpectingException',@ExpectedMessage;
END;
GO
CREATE PROCEDURE ExpectExceptionTests.[test raising wrong state produces meaningful output]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingException AS EXEC tSQLt.ExpectException @State=13;RAISERROR('''',14,10);');

    DECLARE @ExpectedMessage NVARCHAR(MAX);
    SET @ExpectedMessage = '%Expected State: 13'+CHAR(13)+CHAR(10)+
                           'Actual State  : 10';

    EXEC ExpectExceptionTests.AssertTestFails 'MyTestClass.TestExpectingException',@ExpectedMessage;
END;
GO
CREATE PROCEDURE ExpectExceptionTests.[test output includes every incorrect part]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingException AS EXEC tSQLt.ExpectException @Message=''Correct'',@Severity=11,@State=9;RAISERROR(''Wrong'',12,6);');

    DECLARE @ExpectedMessage NVARCHAR(MAX);
    SET @ExpectedMessage = 'Exception did not match expectation!'+CHAR(13)+CHAR(10)+
                           'Expected Message: <Correct>'+CHAR(13)+CHAR(10)+
                           'Actual Message  : <Wrong>'+CHAR(13)+CHAR(10)+
                           'Expected Severity: 11'+CHAR(13)+CHAR(10)+
                           'Actual Severity  : 12'+CHAR(13)+CHAR(10)+
                           'Expected State: 9'+CHAR(13)+CHAR(10)+
                           'Actual State  : 6';

    EXEC ExpectExceptionTests.AssertTestFails 'MyTestClass.TestExpectingException',@ExpectedMessage;
END;
GO
CREATE PROCEDURE ExpectExceptionTests.[test output includes every incorrect part including the MessagePattern]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingException AS EXEC tSQLt.ExpectException @MessagePattern=''Cor[rt]ect'',@Severity=11,@State=9;RAISERROR(''Wrong'',12,6);');

    DECLARE @ExpectedMessage NVARCHAR(MAX);
    SET @ExpectedMessage = 'Exception did not match expectation!'+CHAR(13)+CHAR(10)+
                           'Expected Message to be like <Cor[[]rt]ect>'+CHAR(13)+CHAR(10)+
                           'Actual Message            : <Wrong>'+CHAR(13)+CHAR(10)+
                           'Expected Severity: 11'+CHAR(13)+CHAR(10)+
                           'Actual Severity  : 12'+CHAR(13)+CHAR(10)+
                           'Expected State: 9'+CHAR(13)+CHAR(10)+
                           'Actual State  : 6';

    EXEC ExpectExceptionTests.AssertTestFails 'MyTestClass.TestExpectingException',@ExpectedMessage;
END;
GO
CREATE PROCEDURE ExpectExceptionTests.[test expecting MessagePattern handles wildcards]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'MyTestClass';
    EXEC('CREATE PROC MyTestClass.TestExpectingException AS EXEC tSQLt.ExpectException @MessagePattern = ''Cor[rt]ect%'';RAISERROR(''Correct [Msg]'',16,10);');

    EXEC ExpectExceptionTests.AssertTestSucceeds 'MyTestClass.TestExpectingException';
END;
GO
