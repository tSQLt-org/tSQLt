EXEC tSQLt.NewTestClass 'AnnotationSQLServerVersionTests';
GO
CREATE PROCEDURE AnnotationSQLServerVersionTests.[test go to bed and think]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:MinSQLServerVersion](''2016'')
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
SELECT *,@@VERSION FROM tSQLt.Info() AS I