IF(SCHEMA_ID('Facade') IS NULL)EXEC('CREATE SCHEMA Facade;');
GO
CREATE OR ALTER PROCEDURE Facade.CreateSSPFacade
  @FacadeDbName NVARCHAR(MAX), 
  @ProcedureName NVARCHAR(MAX)
AS
BEGIN
  EXEC tSQLt.Private_GenerateCreateProcedureSpyStatement 
         @ProcedureObjectId = 222,
         @OriginalProcedureName = @ProcedureName;
  RETURN;
END;
GO
