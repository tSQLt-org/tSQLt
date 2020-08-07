EXEC tSQLt.NewTestClass 'AnnotationsTests';
GO
CREATE FUNCTION AnnotationsTests.ReturnSQLVersion14()
RETURNS TABLE
AS
RETURN 
SELECT 14 Major;--,0 Minor,0 Build,0 Revision;
GO
CREATE PROCEDURE AnnotationsTests.[test tests runs on SQLServer Version > MinSQLServerVersion]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[tSQLt:MinSQLServerVersion(13)]
CREATE PROCEDURE MyInnerTests.[test will execute] AS EXEC tSQLt.Fail ''test executed'';
  ');
  EXEC tSQLt.FakeFunction @FunctionName = 'tSQLt.SQLServerVersion', @FakeFunctionName = 'AnnotationsTests.ReturnSQLVersion14';
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
