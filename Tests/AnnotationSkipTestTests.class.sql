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
CREATE PROCEDURE AnnotationSkipTestTests.[test inserts message into tSQLt.TestResult]
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
CREATE PROCEDURE AnnotationSkipTestTests.[test can handle ' in message]
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
--TODO:
-- SkipTestIf
-- test list order
-- build summary total (in build)
-- other resultsetformatters
-- duration
-- does not throw error if skipped tests

