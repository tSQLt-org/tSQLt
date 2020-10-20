EXEC tSQLt.NewTestClass 'RemoveExternalAccessKeyTests';
GO
CREATE PROCEDURE RemoveExternalAccessKeyTests.[test calls tSQLt.RemoveAssemblyKey]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.RemoveAssemblyKey';

  EXEC tSQLt.RemoveExternalAccessKey;

  SELECT _id_ INTO #Actual FROM tSQLt.RemoveAssemblyKey_SpyProcedureLog;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  
  INSERT INTO #Expected VALUES (1);

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
  
END;
GO

CREATE PROCEDURE RemoveExternalAccessKeyTests.[test prints sensible deprecation warning]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.RemoveAssemblyKey';
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_Print';

  EXEC tSQLt.RemoveExternalAccessKey;

  SELECT Message INTO #Actual FROM tSQLt.Private_Print_SpyProcedureLog ;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected VALUES('tSQLt.RemoveExternalAccessKey is deprecated. Please use tSQLt.RemoveAssemblyKey instead.');

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
  
END;
GO
