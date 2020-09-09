EXEC tSQLt.NewTestClass 'AnnotationSkipTestTests';
GO
CREATE PROCEDURE AnnotationSkipTestTests.[test skips the test]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:SkipTest]('''')
CREATE PROCEDURE MyInnerTests.[test should not execute] AS RAISERROR(''test executed'',16,10);
  ');

  EXEC tSQLt_testutil.AssertTestSkipped 
       @TestName = 'MyInnerTests.[test should not execute]';
END;
GO
CREATE PROCEDURE AnnotationSkipTestTests.[test inserts @SkipReason message into tSQLt.TestResult]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:SkipTest](''AnImportantMessage'')
CREATE PROCEDURE MyInnerTests.[test should not execute] AS RAISERROR(''test executed'',16,10);
  ');

  EXEC tSQLt_testutil.AssertTestSkipped 
       @TestName = 'MyInnerTests.[test should not execute]',
       @ExpectedMessage = 'AnImportantMessage';
END;
GO
CREATE PROCEDURE AnnotationSkipTestTests.[test can handle ' in @SkipReason]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:SkipTest](''M''''essag''''e'')
CREATE PROCEDURE MyInnerTests.[test should not execute] AS RAISERROR(''test executed'',16,10);
  ');

  EXEC tSQLt_testutil.AssertTestSkipped 
       @TestName = 'MyInnerTests.[test should not execute]',
       @ExpectedMessage = 'M''essag''e';
END;
GO
CREATE PROCEDURE AnnotationSkipTestTests.[test skips when @SkipReason = '']
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:SkipTest]('''')
CREATE PROCEDURE MyInnerTests.[test should not execute] AS RAISERROR(''test executed'',16,10);
  ');

  EXEC tSQLt_testutil.AssertTestSkipped 
       @TestName = 'MyInnerTests.[test should not execute]',
       @ExpectedMessage = '<no reason provided>';
END;
GO
CREATE PROCEDURE AnnotationSkipTestTests.[test when @SkipReason IS NULL]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:SkipTest](NULL)
CREATE PROCEDURE MyInnerTests.[test should not execute] AS RAISERROR(''test executed'',16,10);
  ');

  EXEC tSQLt_testutil.AssertTestSkipped 
       @TestName = 'MyInnerTests.[test should not execute]',
       @ExpectedMessage = '<no reason provided>';
END;
GO
CREATE PROCEDURE AnnotationSkipTestTests.[test when @SkipReason is given as DEFAULT]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:SkipTest](DEFAULT)
CREATE PROCEDURE MyInnerTests.[test should not execute] AS RAISERROR(''test executed'',16,10);
  ');

  EXEC tSQLt_testutil.AssertTestSkipped 
       @TestName = 'MyInnerTests.[test should not execute]',
       @ExpectedMessage = '<no reason provided>';
END;
GO
CREATE PROCEDURE AnnotationSkipTestTests.[test tSQLt.TestCaseSummary() includes single skipped test in count]
AS
BEGIN
  EXEC tSQLt.FakeTable @TableName = 'tSQLt.TestResult';
  INSERT tSQLt.TestResult(Result) VALUES('Skipped');
  DECLARE @ActualMsg NVARCHAR(MAX) = (SELECT Msg FROM tSQLt.TestCaseSummary());
  EXEC tSQLt.AssertLike @ExpectedPattern = '%, 1 skipped,%', @Actual = @ActualMsg;
END;
GO
CREATE PROCEDURE AnnotationSkipTestTests.[test tSQLt.TestCaseSummary() includes several skipped tests in count]
AS
BEGIN
  EXEC tSQLt.FakeTable @TableName = 'tSQLt.TestResult';
  INSERT tSQLt.TestResult(Result) VALUES('Skipped'),('Skipped'),('Skipped');
  DECLARE @ActualMsg NVARCHAR(MAX) = (SELECT Msg FROM tSQLt.TestCaseSummary());
  EXEC tSQLt.AssertLike @ExpectedPattern = '%, 3 skipped,%', @Actual = @ActualMsg;
END;
GO
CREATE PROCEDURE AnnotationSkipTestTests.[test tSQLt.TestCaseSummary() correctly reports 0 skipped tests in count]
AS
BEGIN
  EXEC tSQLt.FakeTable @TableName = 'tSQLt.TestResult';
  INSERT tSQLt.TestResult(Result) VALUES('Success'),('Error'),('Failure');
  DECLARE @ActualMsg NVARCHAR(MAX) = (SELECT Msg FROM tSQLt.TestCaseSummary());
  EXEC tSQLt.AssertLike @ExpectedPattern = '%, 0 skipped,%', @Actual = @ActualMsg;
END;
GO
CREATE PROCEDURE AnnotationSkipTestTests.[test tSQLt.TestCaseSummary() returns skipped count]
AS
BEGIN
  EXEC tSQLt.FakeTable @TableName = 'tSQLt.TestResult';
  INSERT tSQLt.TestResult(Result) VALUES('Success'),('Error'),('Failure');
  INSERT tSQLt.TestResult(Result) VALUES('Skipped'),('Skipped'),('Skipped');
  SELECT SkippedCnt, Cnt INTO #Actual FROM tSQLt.TestCaseSummary();
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected VALUES(3,7);
END;
GO
CREATE PROCEDURE AnnotationSkipTestTests.[test TestEndTime IS NOT NULL if the test is skipped]
AS
BEGIN
    EXEC tSQLt.NewTestClass 'InnerTests';
    EXEC(
     '--[@'+'tSQLt:SkipTest]('''')
      CREATE PROC InnerTests.[test Me] AS RAISERROR(''Test should not execute'',16,10);'
    );
    DECLARE @RunTestCmd NVARCHAR(MAX) = 'EXEC tSQLt.Run @TestName = ''InnerTests.[test Me]'', @TestResultFormatter = ''tSQLt.NullTestResultFormatter'';';
    
    EXEC(@RunTestCmd);

    DECLARE @ActualTestEndTime DATETIME2 = (SELECT TR.TestEndTime FROM tSQLt.TestResult AS TR WHERE TR.Name = '[InnerTests].[test Me]');

    EXEC tSQLt.AssertNotEquals @Expected = NULL, @Actual = @ActualTestEndTime;
END;
GO
CREATE PROCEDURE AnnotationSkipTestTests.[test annotations listed after SkipTest are not processed]
AS
BEGIN
    EXEC tSQLt.NewTestClass 'InnerTests';
    EXEC(
     '--[@'+'tSQLt:SkipTest]('''')
      --[@'+'tSQLt:AnAnnotation]()
      CREATE PROC InnerTests.[test Me] AS RAISERROR(''test should not execute'',16,10);'
    );
    EXEC('CREATE FUNCTION tSQLt.[@'+'tSQLt:AnAnnotation]() RETURNS TABLE AS RETURN SELECT ''RAISERROR(''''this annotation should not execute'''',16,10);'' [AnnotationCmd];');

    EXEC tSQLt.SetSummaryError @SummaryError=1;

    DECLARE @RunTestCmd NVARCHAR(MAX) = 'EXEC tSQLt.Run @TestName = ''InnerTests.[test Me]'', @TestResultFormatter = ''tSQLt.DefaultResultFormatter'';';
    EXEC(@RunTestCmd);
END;
GO

