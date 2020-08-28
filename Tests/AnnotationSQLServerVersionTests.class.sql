EXEC tSQLt.NewTestClass 'AnnotationSQLServerVersionTests';
GO
CREATE FUNCTION AnnotationSQLServerVersionTests.[42.17.1986.57]()
RETURNS TABLE
AS
RETURN SELECT CAST(N'42.17.1986.57' AS NVARCHAR(128)) AS ProductVersion, 'My Edition' AS Edition;
GO

CREATE PROCEDURE AnnotationSQLServerVersionTests.[test TODO]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:MinSQLServerVersion](''13.0'')
CREATE PROCEDURE MyInnerTests.[test should not execute] AS RAISERROR(''test executed'',16,10);
  ');
  
  EXEC tSQLt.Fail 'TODO';
END;
GO

-- we need the MinSQLServerVersion annotation
-- we need a test that runs on all versions testing conclusively without using the logic it is testing.
-- put version info into tSQLt.info
-- write three tests 
-- add readableSqlVersion to tSQLt.info and write tests for it
-- write two pass-through tests for tSQLt.Private_SQLVersion
-- is there a CLR library that can get us the readable SQL Version?
-- require major.minor
-- reject %.%.%

SELECT CASE WHEN 'a' LIKE '%[^0-9.]%' THEN 1 ELSE 0 END