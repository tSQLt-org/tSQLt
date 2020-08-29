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
--TODO:
-- quotes in message
-- SkipTestIf
