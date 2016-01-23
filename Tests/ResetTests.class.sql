EXEC tSQLt.NewTestClass 'ResetTests';
GO
CREATE PROCEDURE ResetTests.[test calls tSQLt.Private_ResetNewTestClassList]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_ResetNewTestClassList';
  EXEC tSQLt.Reset;

  SELECT _id_
  INTO #Actual
  FROM tSQLt.Private_ResetNewTestClassList_SpyProcedureLog;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  
  INSERT INTO #Expected
  VALUES(1);
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
