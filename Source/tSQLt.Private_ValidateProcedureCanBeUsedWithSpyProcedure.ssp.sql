IF OBJECT_ID('tSQLt.Private_ValidateProcedureCanBeUsedWithSpyProcedure') IS NOT NULL DROP PROCEDURE tSQLt.Private_ValidateProcedureCanBeUsedWithSpyProcedure;
GO
---Build+
GO
CREATE PROCEDURE tSQLt.Private_ValidateProcedureCanBeUsedWithSpyProcedure
    @ProcedureName NVARCHAR(MAX)
AS
BEGIN
	DECLARE @ResolvedProcedureName NVARCHAR(MAX) = @ProcedureName;

	IF (OBJECT_ID(@ProcedureName, 'SN') IS NOT NULL ) 
	BEGIN
		SET @ResolvedProcedureName = (SELECT s.base_object_name FROM sys.synonyms AS s WHERE object_id = OBJECT_ID(@ProcedureName, 'SN'));

		IF (OBJECT_ID(@ResolvedProcedureName, 'P') IS NULL)
		BEGIN
		  RAISERROR('Cannot use SpyProcedure on synonym %s because it does not point to a procedure', 16, 10, @ProcedureName) WITH NOWAIT;
		END;

	END
	ELSE
	BEGIN
		IF NOT EXISTS(SELECT 1 FROM sys.procedures WHERE object_id = OBJECT_ID(@ResolvedProcedureName))
		BEGIN
		  RAISERROR('Cannot use SpyProcedure on %s because the procedure does not exist', 16, 10, @ResolvedProcedureName) WITH NOWAIT;
		END;
    END;
    
    IF (1020 < (SELECT COUNT(*) FROM sys.parameters WHERE object_id = OBJECT_ID(@ResolvedProcedureName)))
    BEGIN
      RAISERROR('Cannot use SpyProcedure on procedure %s because it contains more than 1020 parameters', 16, 10, @ResolvedProcedureName) WITH NOWAIT;
    END;
END;
GO
