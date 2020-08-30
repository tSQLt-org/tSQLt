EXEC tSQLt.NewTestClass 'AnnotationSqlServerVersionTests';
GO
CREATE FUNCTION AnnotationSqlServerVersionTests.[42.17.1986.57]()
RETURNS TABLE
AS
RETURN SELECT CAST(N'42.17.1986.57' AS NVARCHAR(128)) AS ProductVersion, 'My Edition' AS Edition;
GO
CREATE FUNCTION AnnotationSqlServerVersionTests.[13.0.1986.57]()
RETURNS TABLE
AS
RETURN SELECT CAST(N'13.0.1986.57' AS NVARCHAR(128)) AS ProductVersion, 'My Edition' AS Edition;
GO
CREATE PROCEDURE AnnotationSqlServerVersionTests.[test MinSqlMajorVersion allows test to execute if actual version is larger]
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
CREATE PROCEDURE AnnotationSqlServerVersionTests.[test MinSqlMajorVersion doesn't allow test to execute if actual version is smaller]
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
CREATE PROCEDURE AnnotationSqlServerVersionTests.[test MinSqlMajorVersion doesn't allow test to execute if actual version is way smaller]
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
CREATE PROCEDURE AnnotationSqlServerVersionTests.[test MinSqlMajorVersion allows test to execute if actual version is equal]
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
CREATE PROCEDURE AnnotationSqlServerVersionTests.[test MinSqlMajorVersion provides a useful skip reason]
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
       @ExpectedMessage = 'Minimum required version is 43, but current version is 42.'
END;
GO
CREATE PROCEDURE AnnotationSqlServerVersionTests.[test MinSqlMajorVersion includes current and required min version in reason message]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:MinSqlMajorVersion](17)
CREATE PROCEDURE MyInnerTests.[test should not execute] AS RAISERROR(''test executed'',16,10);
  ');

  EXEC tSQLt.FakeFunction @FunctionName = 'tSQLt.Private_SqlVersion', @FakeFunctionName = 'AnnotationSqlServerVersionTests.[13.0.1986.57]';

  
  EXEC tSQLt_testutil.AssertTestSkipped
       @TestName = 'MyInnerTests.[test should not execute]',
       @ExpectedMessage = 'Minimum required version is 17, but current version is 13.'
END;
GO
CREATE PROCEDURE AnnotationSqlServerVersionTests.[test MaxSqlMajorVersion allows test to execute if actual version is smaller]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:MaxSqlMajorVersion](43)
CREATE PROCEDURE MyInnerTests.[test should not execute] AS RAISERROR(''test executed'',16,10);
  ');

  EXEC tSQLt.FakeFunction @FunctionName = 'tSQLt.Private_SqlVersion', @FakeFunctionName = 'AnnotationSqlServerVersionTests.[42.17.1986.57]';

  
  EXEC tSQLt_testutil.AssertTestErrors
       @TestName = 'MyInnerTests.[test should not execute]',
       @ExpectedMessage = 'test executed%';
END;
GO
CREATE PROCEDURE AnnotationSqlServerVersionTests.[test MaxSqlMajorVersion doesn't allow test to execute if actual version is larger]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:MaxSqlMajorVersion](41)
CREATE PROCEDURE MyInnerTests.[test should not execute] AS RAISERROR(''test executed'',16,10);
  ');

  EXEC tSQLt.FakeFunction @FunctionName = 'tSQLt.Private_SqlVersion', @FakeFunctionName = 'AnnotationSqlServerVersionTests.[42.17.1986.57]';

  
  EXEC tSQLt_testutil.AssertTestSkipped
       @TestName = 'MyInnerTests.[test should not execute]'
END;
GO
CREATE PROCEDURE AnnotationSqlServerVersionTests.[test MaxSqlMajorVersion doesn't allow test to execute if actual version is way larger]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:MaxSqlMajorVersion](13)
CREATE PROCEDURE MyInnerTests.[test should not execute] AS RAISERROR(''test executed'',16,10);
  ');

  EXEC tSQLt.FakeFunction @FunctionName = 'tSQLt.Private_SqlVersion', @FakeFunctionName = 'AnnotationSqlServerVersionTests.[42.17.1986.57]';

  
  EXEC tSQLt_testutil.AssertTestSkipped
       @TestName = 'MyInnerTests.[test should not execute]'
END;
GO
CREATE PROCEDURE AnnotationSqlServerVersionTests.[test MaxSqlMajorVersion allows test to execute if actual version is equal]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:MaxSqlMajorVersion](42)
CREATE PROCEDURE MyInnerTests.[test should not execute] AS RAISERROR(''test executed'',16,10);
  ');

  EXEC tSQLt.FakeFunction @FunctionName = 'tSQLt.Private_SqlVersion', @FakeFunctionName = 'AnnotationSqlServerVersionTests.[42.17.1986.57]';

  
  EXEC tSQLt_testutil.AssertTestErrors
       @TestName = 'MyInnerTests.[test should not execute]',
       @ExpectedMessage = 'test executed%';
END;
GO
CREATE PROCEDURE AnnotationSqlServerVersionTests.[test MaxSqlMajorVersion provides a useful skip reason]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:MaxSqlMajorVersion](41)
CREATE PROCEDURE MyInnerTests.[test should not execute] AS RAISERROR(''test executed'',16,10);
  ');

  EXEC tSQLt.FakeFunction @FunctionName = 'tSQLt.Private_SqlVersion', @FakeFunctionName = 'AnnotationSqlServerVersionTests.[42.17.1986.57]';

  
  EXEC tSQLt_testutil.AssertTestSkipped
       @TestName = 'MyInnerTests.[test should not execute]',
       @ExpectedMessage = 'Maximum allowed version is 41, but current version is 42.'
END;
GO
CREATE PROCEDURE AnnotationSqlServerVersionTests.[test MaxSqlMajorVersion includes current and required max version in reason message]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:MaxSqlMajorVersion](11)
CREATE PROCEDURE MyInnerTests.[test should not execute] AS RAISERROR(''test executed'',16,10);
  ');

  EXEC tSQLt.FakeFunction @FunctionName = 'tSQLt.Private_SqlVersion', @FakeFunctionName = 'AnnotationSqlServerVersionTests.[13.0.1986.57]';

  
  EXEC tSQLt_testutil.AssertTestSkipped
       @TestName = 'MyInnerTests.[test should not execute]',
       @ExpectedMessage = 'Maximum allowed version is 11, but current version is 13.'
END;
GO
