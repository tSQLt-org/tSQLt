:SETVAR tSQLtFacade tSQLtFacade
GO
EXEC tSQLt.NewTestClass 'Facade_CreateFacadeDb_Tests';
GO
CREATE PROCEDURE Facade_CreateFacadeDb_Tests.[test CreateSSPFacade calls Private_GenerateCreateProcedureSpyStatement]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_GenerateCreateProcedureSpyStatement';

  EXEC('CREATE PROC dbo.AProc AS RETURN;'); 

  EXEC Facade.CreateSSPFacade @FacadeDbName = '$(tSQLtFacade)', @ProcedureName = 'dbo.AProc';

  SELECT 
      ProcedureObjectId,
      OriginalProcedureName,
      LogTableName,
      CommandToExecute
    INTO #Actual FROM tSQLt.Private_GenerateCreateProcedureSpyStatement_SpyProcedureLog;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  
  INSERT INTO #Expected
  VALUES(OBJECT_ID('dbo.AProc'),'dbo.AProc',NULL,NULL);

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
--CREATE PROCEDURE Facade_CreateFacadeDb_Tests.[test CreateSSPFacade executes @CreateProcedureStatement from Private_GenerateCreateProcedureSpyStatement in $(tSQLtFacade)]
--AS
--BEGIN
--  EXEC('CREATE PROC dbo.AProc AS RETURN;'); 
--  EXEC Facade.CreateSSPFacade @FacadeDbName = '$(tSQLtFacade)', @Name = 'dbo.AProc';
--  DECLARE @Actual NVARCHAR(MAX);
--  SELECT @Actual = definition FROM $(tSQLtFacade).sys.sql_modules WHERE object_id = OBJECT_ID('$(tSQLtFacade).dbo.AProc');
  
--  EXEC tSQLt.AssertEqualsString @Expected = 'dbo.', @Actual = @Actual;
--END;
--GO
