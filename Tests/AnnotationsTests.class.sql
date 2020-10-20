EXEC tSQLt.NewTestClass 'AnnotationsTests';
GO
CREATE PROCEDURE AnnotationsTests.[test a test runs if single annotation indicates to run]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:MyTestAnnotation]()
CREATE PROCEDURE MyInnerTests.[test will execute] AS EXEC tSQLt.Fail ''test executed'';
  ');
  EXEC('CREATE FUNCTION tSQLt.[@'+'tSQLt:MyTestAnnotation]() RETURNS TABLE AS RETURN SELECT NULL [AnnotationCmd];');
  BEGIN TRY 
    EXEC tSQLt.Run 'MyInnerTests';
  END TRY
  BEGIN CATCH
    -- intentionally empty
  END CATCH;
  SELECT TestCase,Msg INTO #Actual FROM tSQLt.TestResult;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected VALUES('test will execute','test executed');
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';  
END;
GO
CREATE PROCEDURE AnnotationsTests.[test a test is skipped if single annotation indicates not to run]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:MyTestAnnotation]()
CREATE PROCEDURE MyInnerTests.[test should not execute] AS RAISERROR(''test executed'',16,10);
  ');
  EXEC('CREATE PROCEDURE tSQLt.[@'+'tSQLt:MyTestAnnotationProc] AS INSERT INTO #SkipTest DEFAULT VALUES;');
  EXEC('CREATE FUNCTION tSQLt.[@'+'tSQLt:MyTestAnnotation]() RETURNS TABLE AS RETURN SELECT ''EXEC tSQLt.[@'+'tSQLt:MyTestAnnotationProc]'' [AnnotationCmd];');

  EXEC tSQLt_testutil.AssertTestSkipped 
       @TestName = 'MyInnerTests.[test should not execute]';
END;
GO
CREATE PROCEDURE AnnotationsTests.[test a test is skipped if another single annotation indicates not to run]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
  /*
--[@'+'tSQLt:ADifferentAnnotation]()
*/
CREATE PROCEDURE MyInnerTests.[test should not execute] AS RAISERROR(''test executed'',16,10);
  ');
  EXEC('CREATE PROCEDURE tSQLt.[@'+'tSQLt:MyTestAnnotationProc] AS INSERT INTO #SkipTest DEFAULT VALUES;');
  EXEC('CREATE FUNCTION tSQLt.[@'+'tSQLt:ADifferentAnnotation]() RETURNS TABLE AS RETURN SELECT ''EXEC tSQLt.[@'+'tSQLt:MyTestAnnotationProc]'' [AnnotationCmd];');

  EXEC tSQLt_testutil.AssertTestSkipped 
       @TestName = 'MyInnerTests.[test should not execute]';
END;
GO
CREATE PROCEDURE AnnotationsTests.[test errors test with appropriate message if it encounters a nonexistent annotation]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:ANonexistentAnnotation]()
CREATE PROCEDURE MyInnerTests.[test should not execute] AS EXEC tSQLt.Fail ''test executed'';
  ');

  EXEC tSQLt_testutil.AssertTestErrors 
       @TestName = 'MyInnerTests.[test should not execute]', 
       @ExpectedMessage='There is a problem with the annotations:%';
END;
GO
CREATE PROCEDURE AnnotationsTests.[test errors test with appropriate message if a parameter is missing]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:A1ParameterAnnotation]()
CREATE PROCEDURE MyInnerTests.[test should not execute] AS EXEC tSQLt.Fail ''test executed'';
  ');
  EXEC('CREATE FUNCTION tSQLt.[@'+'tSQLt:A1ParameterAnnotation](@P1 INT) RETURNS TABLE AS RETURN SELECT NULL [AnnotationCmd];');

  EXEC tSQLt_testutil.AssertTestErrors 
       @TestName = 'MyInnerTests.[test should not execute]', 
       @ExpectedMessage='%@tSQLt:A1ParameterAnnotation%';
END;
GO
CREATE PROCEDURE AnnotationsTests.[test errors test with appropriate message if a parameter is superfluous]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:A1ParameterAnnotation](3,42)
CREATE PROCEDURE MyInnerTests.[test should not execute] AS EXEC tSQLt.Fail ''test executed'';
  ');
  EXEC('CREATE FUNCTION tSQLt.[@'+'tSQLt:A1ParameterAnnotation](@P1 INT) RETURNS TABLE AS RETURN SELECT NULL [AnnotationCmd];');

  EXEC tSQLt_testutil.AssertTestErrors 
       @TestName = 'MyInnerTests.[test should not execute]', 
       @ExpectedMessage='%@tSQLt:A1ParameterAnnotation%';

END;
GO
CREATE PROCEDURE AnnotationsTests.[test specifies details if there's an internal error in the annotation function]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:AnErroringAnnotation]()
CREATE PROCEDURE MyInnerTests.[test should not execute] AS EXEC tSQLt.Fail ''test executed'';
  ');
  EXEC('CREATE FUNCTION tSQLt.[@'+'tSQLt:AnErroringAnnotation]() RETURNS TABLE AS RETURN SELECT 1/0 [AnnotationCmd];');

  EXEC tSQLt_testutil.AssertTestErrors 
         @TestName = 'MyInnerTests.[test should not execute]', 
         @ExpectedMessage='%{16,10} There is an internal error for annotation: [[]@tSQLt:AnErroringAnnotation]()
  caused by {16,1} Divide by zero error encountered.%';

END;
GO
CREATE PROCEDURE AnnotationsTests.[test annotation error includes severity, and state]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  DECLARE @Cmd NVARCHAR(MAX) = '
--[@'+CAST(0x7400530051004C0074003A0041006E0041006E006E006F0074006100740069006F006E005D0028002900200041003B0052004100490053004500520052004F005200280027007800780027002C00310035002C00390029003B004400450043004C00410052004500200040007300200049004E0054003B002000530045004C00450043005400200054004F0050002800300029002000400073003D006F0062006A006500630074005F00690064002000660072006F006D0020007300790073002E006F0062006A006500630074007300 AS NVARCHAR(MAX))+'
CREATE PROCEDURE MyInnerTests.[test should not execute] AS EXEC tSQLt.Fail ''test executed'';';
  EXEC(@Cmd);
  EXEC('CREATE FUNCTION tSQLt.[@'+'tSQLt:AnAnnotation]() RETURNS TABLE AS RETURN SELECT NULL [AnnotationCmd];');

  EXEC tSQLt_testutil.AssertTestErrors 
         @TestName = 'MyInnerTests.[test should not execute]', 
         @ExpectedMessage='%{15,9}%';
END;
GO
CREATE PROCEDURE AnnotationsTests.[test can handle string as parameter]
AS
BEGIN
  DECLARE @AnnotationName NVARCHAR(MAX) = '[@tSQLt:AStringParameterAnnotation]';
  DECLARE @FullAnnotationName NVARCHAR(MAX) = 'tSQLt.'+@AnnotationName;
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--'+@AnnotationName+'(''SomeRandomString'')
CREATE PROCEDURE MyInnerTests.[test nothing] AS RETURN;
  ');
  EXEC('CREATE FUNCTION '+@FullAnnotationName+' (@P1 NVARCHAR(MAX))RETURNS TABLE AS RETURN SELECT ''RAISERROR(''''[%s]'''',16,10,''''''+@P1+'''''');'' AnnotationCmd;');

  EXEC tSQLt_testutil.AssertTestErrors @TestName = 'MyInnerTests.[test nothing]', @ExpectedMessage='%[[]SomeRandomString]%';
END;
GO
CREATE PROCEDURE AnnotationsTests.[test AnnotationCommand is executed]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:MyTestAnnotation]()
CREATE PROCEDURE MyInnerTests.[test should not execute] AS RAISERROR(''test executed'',16,10);
  ');
  EXEC('CREATE FUNCTION tSQLt.[@'+'tSQLt:MyTestAnnotation]() RETURNS TABLE AS RETURN SELECT ''RAISERROR(''''AnnotationCommand executed.'''',16,10);'' [AnnotationCmd];');

  EXEC tSQLt_testutil.AssertTestErrors 
         @TestName = 'MyInnerTests.[test should not execute]', 
         @ExpectedMessage='%AnnotationCommand executed.%';
END;
GO
--[@tSQLt:MaxSqlMajorVersion](13)
CREATE PROCEDURE AnnotationsTests.[test erroring AnnotationCommand produces helpful error message (Pre 2017)]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:MyTestAnnotation]()
CREATE PROCEDURE MyInnerTests.[test should not execute] AS RAISERROR(''test executed'',16,10);
  ');
  EXEC('CREATE PROCEDURE tSQLt.[@tSQLt:MyAnnotationHelper] AS RAISERROR(''AnnotationCommand executed.'',15,9);');
  EXEC('CREATE FUNCTION tSQLt.[@'+'tSQLt:MyTestAnnotation]() RETURNS TABLE AS RETURN SELECT ''EXEC tSQLt.[@tSQLt:MyAnnotationHelper];'' [AnnotationCmd];');

  DECLARE @ExpectedMessage NVARCHAR(MAX) = 
    'There is a problem with this annotation: [[]@tSQLt:MyTestAnnotation]()'+CHAR(13)+CHAR(10)+
    'Original Error: {15,9;@tSQLt:MyAnnotationHelper} AnnotationCommand executed.'

  EXEC tSQLt_testutil.AssertTestErrors 
         @TestName = 'MyInnerTests.[test should not execute]', 
         @ExpectedMessage=@ExpectedMessage;
END;
GO
--[@tSQLt:MinSqlMajorVersion](14)
CREATE PROCEDURE AnnotationsTests.[test erroring AnnotationCommand produces helpful error message (2017 or later)]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:MyTestAnnotation]()
CREATE PROCEDURE MyInnerTests.[test should not execute] AS RAISERROR(''test executed'',16,10);
  ');
  EXEC('CREATE PROCEDURE tSQLt.[@tSQLt:MyAnnotationHelper] AS RAISERROR(''AnnotationCommand executed.'',15,9);');
  EXEC('CREATE FUNCTION tSQLt.[@'+'tSQLt:MyTestAnnotation]() RETURNS TABLE AS RETURN SELECT ''EXEC tSQLt.[@tSQLt:MyAnnotationHelper];'' [AnnotationCmd];');

  DECLARE @ExpectedMessage NVARCHAR(MAX) = 
    'There is a problem with this annotation: [[]@tSQLt:MyTestAnnotation]()'+CHAR(13)+CHAR(10)+
    'Original Error: {15,9;tSQLt.@tSQLt:MyAnnotationHelper} AnnotationCommand executed.'

  EXEC tSQLt_testutil.AssertTestErrors 
         @TestName = 'MyInnerTests.[test should not execute]', 
         @ExpectedMessage=@ExpectedMessage;
END;
GO
CREATE PROCEDURE AnnotationsTests.[test Syntax Error produces helpful error message]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:MyTestAnnotation]()
CREATE PROCEDURE MyInnerTests.[test should not execute] AS RAISERROR(''test executed'',16,10);
  ');
  EXEC('CREATE PROCEDURE tSQLt.[@tSQLt:MyAnnotationHelper] AS EXEC(''Very Intentional Syntax_Error'');');
  EXEC('CREATE FUNCTION tSQLt.[@'+'tSQLt:MyTestAnnotation]() RETURNS TABLE AS RETURN SELECT ''EXEC tSQLt.[@tSQLt:MyAnnotationHelper];'' [AnnotationCmd];');

  DECLARE @ExpectedMessage NVARCHAR(MAX) = 
    '%Incorrect syntax near ''Syntax_Error''.'

  EXEC tSQLt_testutil.AssertTestErrors 
         @TestName = 'MyInnerTests.[test should not execute]', 
         @ExpectedMessage=@ExpectedMessage;
END;
GO
CREATE PROCEDURE AnnotationsTests.[test 1/0 produces helpful error message]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:MyTestAnnotation]()
CREATE PROCEDURE MyInnerTests.[test should not execute] AS RAISERROR(''test executed'',16,10);
  ');
  EXEC('CREATE PROCEDURE tSQLt.[@tSQLt:MyAnnotationHelper] AS PRINT 1/0;');
  EXEC('CREATE FUNCTION tSQLt.[@'+'tSQLt:MyTestAnnotation]() RETURNS TABLE AS RETURN SELECT ''EXEC tSQLt.[@tSQLt:MyAnnotationHelper];'' [AnnotationCmd];');

  DECLARE @ExpectedMessage NVARCHAR(MAX) = 
    '%Divide by zero error encountered.'

  EXEC tSQLt_testutil.AssertTestErrors 
         @TestName = 'MyInnerTests.[test should not execute]', 
         @ExpectedMessage=@ExpectedMessage;
END;
GO
CREATE PROCEDURE AnnotationsTests.[test nonexistingcolumn produces helpful error message]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:MyTestAnnotation]()
CREATE PROCEDURE MyInnerTests.[test should not execute] AS RAISERROR(''test executed'',16,10);
  ');
  EXEC('CREATE PROCEDURE tSQLt.[@tSQLt:MyAnnotationHelper] AS EXEC(''SELECT nonexistingcolumn FROM (VALUES(NULL))A(A);'');');
  EXEC('CREATE FUNCTION tSQLt.[@'+'tSQLt:MyTestAnnotation]() RETURNS TABLE AS RETURN SELECT ''EXEC tSQLt.[@tSQLt:MyAnnotationHelper];'' [AnnotationCmd];');

  DECLARE @ExpectedMessage NVARCHAR(MAX) = 
    '%Invalid column name ''nonexistingcolumn''.'

  EXEC tSQLt_testutil.AssertTestErrors 
         @TestName = 'MyInnerTests.[test should not execute]', 
         @ExpectedMessage=@ExpectedMessage;
END;
GO
CREATE PROCEDURE AnnotationsTests.[test can handle quotes in AnnotationCmd]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:MyTestAnnotation]()
CREATE PROCEDURE MyInnerTests.[test should not execute] AS RAISERROR(''test executed'',16,10);
  ');
  EXEC('CREATE FUNCTION tSQLt.[@'+'tSQLt:MyTestAnnotation]() RETURNS TABLE AS RETURN SELECT ''RAISERROR(''''got''''''''here'''',16,10);'' [AnnotationCmd];');

  EXEC tSQLt_testutil.AssertTestErrors 
         @TestName = 'MyInnerTests.[test should not execute]', 
         @ExpectedMessage='%got''here%';
END;
GO
CREATE PROCEDURE AnnotationsTests.[test identifies the annotation that causes the error]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:MyTestAnnotation1]()
--[@'+'tSQLt:MyTestAnnotation2]()
--[@'+'tSQLt:MyTestAnnotation3]()
CREATE PROCEDURE MyInnerTests.[test should not execute] AS RAISERROR(''test executed'',16,10);
  ');
  EXEC('CREATE FUNCTION tSQLt.[@'+'tSQLt:MyTestAnnotation1]() RETURNS TABLE AS RETURN SELECT ''DECLARE @i1 INT;'' [AnnotationCmd];');
  EXEC('CREATE FUNCTION tSQLt.[@'+'tSQLt:MyTestAnnotation2]() RETURNS TABLE AS RETURN SELECT ''DECLARE @i2 INT = 1/0;'' [AnnotationCmd];');
  EXEC('CREATE FUNCTION tSQLt.[@'+'tSQLt:MyTestAnnotation3]() RETURNS TABLE AS RETURN SELECT ''DECLARE @i3 INT;'' [AnnotationCmd];');

  EXEC tSQLt_testutil.AssertTestErrors 
         @TestName = 'MyInnerTests.[test should not execute]', 
         @ExpectedMessage='%[[]@tSQLt:MyTestAnnotation2]()%';
END;
GO
CREATE PROCEDURE AnnotationsTests.[test TestStartTime is captured before annotations are processed]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'InnerTests';
    EXEC(
     '--[@'+'tSQLt:AnAnnotation]()
      CREATE PROC InnerTests.[test Me] AS RETURN;'
    );
    EXEC('CREATE FUNCTION tSQLt.[@'+'tSQLt:AnAnnotation]() RETURNS TABLE AS RETURN SELECT ''WAITFOR DELAY ''''00:00:00.111'''';'' [AnnotationCmd];');

    DECLARE @RunTestCmd NVARCHAR(MAX) = 'EXEC tSQLt.Run @TestName = ''InnerTests.[test Me]'', @TestResultFormatter = ''tSQLt.NullTestResultFormatter'';';
    EXEC tSQLt.CaptureOutput @command= @RunTestCmd;

    DECLARE @actual DATETIME;
    DECLARE @after DATETIME;
    DECLARE @before DATETIME;
    
    SET @before = GETDATE();  
    
    EXEC(@RunTestCmd);
    
    SET @after = GETDATE();  
    
    SELECT  @actual = TestStartTime
    FROM tSQLt.TestResult AS TR   
    
    DECLARE @msg NVARCHAR(MAX);
    IF(@actual < @before OR @actual > DATEADD(MILLISECOND,-100,@after) OR @actual IS NULL)
    BEGIN
      SET @msg = 
        'Expected:'+
        CONVERT(NVARCHAR(MAX),@before,121)+
        ' <= '+
        ISNULL(CONVERT(NVARCHAR(MAX),@actual,121),'!NULL!')+
        ' <= '+
        CONVERT(NVARCHAR(MAX),DATEADD(MILLISECOND,-100,@after),121);
        EXEC tSQLt.Fail @msg;
    END;
END;
GO
CREATE PROCEDURE AnnotationsTests.[test TestEndTime is captured after annotations are processed]
AS
BEGIN

    EXEC tSQLt.NewTestClass 'InnerTests';
    EXEC(
     '--[@'+'tSQLt:AnAnnotation]()
      CREATE PROC InnerTests.[test Me] AS RETURN;'
    );
    EXEC('CREATE FUNCTION tSQLt.[@'+'tSQLt:AnAnnotation]() RETURNS TABLE AS RETURN SELECT ''WAITFOR DELAY ''''00:00:00.111'''';'' [AnnotationCmd];');

    DECLARE @RunTestCmd NVARCHAR(MAX) = 'EXEC tSQLt.Run @TestName = ''InnerTests.[test Me]'', @TestResultFormatter = ''tSQLt.NullTestResultFormatter'';';
    EXEC tSQLt.CaptureOutput @command= @RunTestCmd;

    DECLARE @actualEndTime DATETIME;
    DECLARE @after DATETIME;
    DECLARE @before DATETIME;
    
    SET @before = GETDATE();  
    
    EXEC(@RunTestCmd);
    
    SET @after = GETDATE();  
    
    SELECT  @actualEndTime = TestEndTime
    FROM tSQLt.TestResult AS TR   
    
    DECLARE @msg NVARCHAR(MAX);
    IF(@actualEndTime < DATEADD(MILLISECOND,100,@before) OR @actualEndTime > @after OR @actualEndTime IS NULL)
    BEGIN
      SET @msg = 
        'Expected:'+
        CONVERT(NVARCHAR(MAX),DATEADD(MILLISECOND,100,@before),121)+
        ' <= '+
        ISNULL(CONVERT(NVARCHAR(MAX),@actualEndTime,121),'!NULL!')+
        ' <= '+
        CONVERT(NVARCHAR(MAX),@after,121);
        EXEC tSQLt.Fail @msg;
    END;
END;
GO
CREATE PROCEDURE AnnotationsTests.[test Executes Annotations before test, no matter where they are located in test]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:MyTestAnnotation](1)
CREATE PROCEDURE MyInnerTests.[test inner test] 
--[@'+'tSQLt:MyTestAnnotation](2)
AS 
--[@'+'tSQLt:MyTestAnnotation](3)
EXEC tSQLt.AssertEqualsTable ''#Expected'',''#Actual'';
--[@'+'tSQLt:MyTestAnnotation](4)
  ');
  EXEC('CREATE FUNCTION tSQLt.[@'+'tSQLt:MyTestAnnotation](@id INT) RETURNS TABLE AS RETURN SELECT ''INSERT INTO #Actual VALUES(''+CAST(@id AS NVARCHAR(MAX))+'');'' [AnnotationCmd];');
 
  CREATE TABLE #Actual(id INT);
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected VALUES(1),(2),(3),(4);

  EXEC tSQLt.SetSummaryError @SummaryError = 1;
  EXEC tSQLt.ExpectNoException;  --<-- Assertion happens within [test inner test]
  EXEC tSQLt.Run @TestName = 'MyInnerTests.[test inner test]', 
                 @TestResultFormatter = 'tSQLt.DefaultResultFormatter';
END;

