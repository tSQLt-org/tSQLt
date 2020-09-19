EXEC tSQLt.NewTestClass 'PrepareServerTests';
GO
CREATE PROCEDURE PrepareServerTests.[test enables CLR]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_EnableCLR';
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.InstallAssemblyKey';


  EXEC tSQLt.PrepareServer;

  SELECT COUNT(1) NumberOfCalls
    INTO #Actual
    FROM tSQLt.Private_EnableCLR_SpyProcedureLog;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected VALUES(1);
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
  
END;
GO
CREATE PROCEDURE PrepareServerTests.[test calls tSQLt.InstallAssemblyKey]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_EnableCLR';
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.InstallAssemblyKey';

  EXEC tSQLt.PrepareServer;

  SELECT COUNT(1) NumberOfCalls
    INTO #Actual
    FROM tSQLt.InstallAssemblyKey_SpyProcedureLog;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected VALUES(1);
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
  
END;
GO
CREATE PROCEDURE PrepareServerTests.[test calls tSQLt.InstallAssemblyKey after tSQLt.Private_EnableCLR]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_EnableCLR', @CommandToExecute='INSERT INTO #Actual VALUES (''tSQLt.Private_EnableCLR'')';
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.InstallAssemblyKey', @CommandToExecute='INSERT INTO #Actual VALUES (''tSQLt.InstallAssemblyKey'')';

  CREATE TABLE #Actual ( OrderNo INT IDENTITY (1,1), ProcedureName NVARCHAR(Max));

  EXEC tSQLt.PrepareServer;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected VALUES(1,'tSQLt.Private_EnableCLR'),(2,'tSQLt.InstallAssemblyKey');
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
  
END;
GO