IF OBJECT_ID('tSQLt.Private_ValidateProcedureCanBeUsedWithSpyProcedure') IS NOT NULL DROP PROCEDURE tSQLt.Private_ValidateProcedureCanBeUsedWithSpyProcedure;
GO
---Build+
GO
CREATE PROCEDURE tSQLt.Private_ValidateProcedureCanBeUsedWithSpyProcedure
    @ProcedureName NVARCHAR(MAX)
AS
BEGIN
    IF NOT EXISTS(SELECT 1 FROM sys.procedures WHERE object_id = OBJECT_ID(@ProcedureName))
    BEGIN
      RAISERROR('Cannot use SpyProcedure on %s because the procedure does not exist', 16, 10, @ProcedureName) WITH NOWAIT;
    END;
    
    IF (1020 < (SELECT COUNT(*) FROM sys.parameters WHERE object_id = OBJECT_ID(@ProcedureName)))
    BEGIN
      RAISERROR('Cannot use SpyProcedure on procedure %s because it contains more than 1020 parameters', 16, 10, @ProcedureName) WITH NOWAIT;
    END;
END;
GO


