IF(SCHEMA_ID('Facade') IS NULL)EXEC('CREATE SCHEMA Facade;');
GO
CREATE OR ALTER PROCEDURE Facade.CreateSSPFacade
  @FacadeDbName NVARCHAR(MAX), 
  @ProcedureName NVARCHAR(MAX)
AS
BEGIN
  DECLARE @ProcedureObjectId INT = OBJECT_ID(@ProcedureName);
  DECLARE @CreateProcedureStatement NVARCHAR(MAX);

  EXEC tSQLt.Private_GenerateCreateProcedureSpyStatement 
         @ProcedureObjectId = @ProcedureObjectId,
         @OriginalProcedureName = @ProcedureName,
         @CreateProcedureStatement = @CreateProcedureStatement OUT;

  DECLARE @ExecIn NVARCHAR(MAX) = QUOTENAME(@FacadeDbName)+'.sys.sp_executesql';
  DECLARE @WrappedStatement NVARCHAR(MAX) = 'EXEC('''+@CreateProcedureStatement+''');';
  EXEC @ExecIn @WrappedStatement,N'';

  RETURN;
END;
GO
CREATE VIEW Facade.[sys.procedures] AS SELECT * FROM sys.procedures AS P;
GO
