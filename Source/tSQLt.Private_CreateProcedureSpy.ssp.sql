IF OBJECT_ID('tSQLt.Private_CreateProcedureSpy') IS NOT NULL DROP PROCEDURE tSQLt.Private_CreateProcedureSpy;
GO
---Build+
CREATE PROCEDURE tSQLt.Private_CreateProcedureSpy
    @ProcedureObjectId INT,
    @OriginalProcedureName NVARCHAR(MAX),
    @LogTableName NVARCHAR(MAX),
    @CommandToExecute NVARCHAR(MAX) = NULL
AS
BEGIN

    RETURN;
END;
---Build-
GO
