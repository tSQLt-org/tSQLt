EXEC tSQLt.NewTestClass 'AnnotationSqlServerVersionTests';
GO
CREATE FUNCTION AnnotationSqlServerVersionTests.[42.17.1986.57]()
RETURNS TABLE
AS
RETURN SELECT CAST(N'42.17.1986.57' AS NVARCHAR(128)) AS ProductVersion, 'My Edition' AS Edition;
GO
CREATE PROCEDURE AnnotationSqlServerVersionTests.[test allows test to execute if actual version is larger]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:MinSqlMajorVersion](13)
CREATE PROCEDURE MyInnerTests.[test should not execute] AS RAISERROR(''test executed'',16,10);
  ');

  EXEC tSQLt.FakeFunction @FunctionName = 'tSQLt.Private_SqlVersion', @FakeFunctionName = 'AnnotationSqlServerVersionTests.[42.17.1986.57]';

  
  EXEC tSQLt_testutil.AssertTestErrors
       @TestName = 'MyInnerTests.[test should not execute]',
       @ExpectedMessage = 'test executed%';
END;
GO
CREATE PROCEDURE AnnotationSqlServerVersionTests.[test doesn't allow test to execute if actual version is smaller]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:MinSqlMajorVersion](43)
CREATE PROCEDURE MyInnerTests.[test should not execute] AS RAISERROR(''test executed'',16,10);
  ');

  EXEC tSQLt.FakeFunction @FunctionName = 'tSQLt.Private_SqlVersion', @FakeFunctionName = 'AnnotationSqlServerVersionTests.[42.17.1986.57]';

  
  EXEC tSQLt_testutil.AssertTestSkipped
       @TestName = 'MyInnerTests.[test should not execute]'
END;
GO
CREATE PROCEDURE AnnotationSqlServerVersionTests.[test doesn't allow test to execute if actual version is way smaller]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:MinSqlMajorVersion](93)
CREATE PROCEDURE MyInnerTests.[test should not execute] AS RAISERROR(''test executed'',16,10);
  ');

  EXEC tSQLt.FakeFunction @FunctionName = 'tSQLt.Private_SqlVersion', @FakeFunctionName = 'AnnotationSqlServerVersionTests.[42.17.1986.57]';

  
  EXEC tSQLt_testutil.AssertTestSkipped
       @TestName = 'MyInnerTests.[test should not execute]'
END;
GO
CREATE PROCEDURE AnnotationSqlServerVersionTests.[test allows test to execute if actual version is equal]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:MinSqlMajorVersion](42)
CREATE PROCEDURE MyInnerTests.[test should not execute] AS RAISERROR(''test executed'',16,10);
  ');

  EXEC tSQLt.FakeFunction @FunctionName = 'tSQLt.Private_SqlVersion', @FakeFunctionName = 'AnnotationSqlServerVersionTests.[42.17.1986.57]';

  
  EXEC tSQLt_testutil.AssertTestErrors
       @TestName = 'MyInnerTests.[test should not execute]',
       @ExpectedMessage = 'test executed%';
END;
GO
CREATE PROCEDURE AnnotationSqlServerVersionTests.[test provides a useful skip reason]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:MinSqlMajorVersion](43)
CREATE PROCEDURE MyInnerTests.[test should not execute] AS RAISERROR(''test executed'',16,10);
  ');

  EXEC tSQLt.FakeFunction @FunctionName = 'tSQLt.Private_SqlVersion', @FakeFunctionName = 'AnnotationSqlServerVersionTests.[42.17.1986.57]';

  
  EXEC tSQLt_testutil.AssertTestSkipped
       @TestName = 'MyInnerTests.[test should not execute]',
       @ExpectedMessage = 'asdasd'
END;
GO

-- message

SELECT CASE WHEN 'a' LIKE '%[^0-9.]%' THEN 1 ELSE 0 END