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

-- we need the MinSqlServerVersion annotation
-- we need a test that runs on all versions testing conclusively without using the logic it is testing.
-- put version info into tSQLt.info
-- write three tests 
-- add readableSqlVersion to tSQLt.info and write tests for it
-- write two pass-through tests for tSQLt.Private_SqlVersion
-- is there a CLR library that can get us the readable Sql Version?
-- require major.minor
-- reject %.%.%

SELECT CASE WHEN 'a' LIKE '%[^0-9.]%' THEN 1 ELSE 0 END