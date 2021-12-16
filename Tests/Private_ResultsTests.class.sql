EXEC tSQLt.NewTestClass 'Private_ResultsTests';
GO
CREATE PROCEDURE Private_ResultsTests.[test Contains all Result values (double ledger)]
AS
BEGIN
  SELECT Severity, Result INTO #Actual FROM tSQLt.Private_Results;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
    SELECT 1,'Success' UNION ALL
    SELECT 2,'Skipped' UNION ALL
    SELECT 3,'Failure' UNION ALL
    SELECT 4,'Error'   UNION ALL
    SELECT 5,'Abort'   UNION ALL
    SELECT 6,'FATAL'   ;
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';

END;
GO
