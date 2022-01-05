IF OBJECT_ID('tSQLt.Private_UndoSingleTestDouble') IS NOT NULL DROP PROCEDURE tSQLt.Private_UndoSingleTestDouble;
GO
---Build+
GO
CREATE PROCEDURE tSQLt.Private_UndoSingleTestDouble
    @SchemaName NVARCHAR(MAX),
    @ObjectName NVARCHAR(MAX),
    @OriginalName NVARCHAR(MAX)
AS
BEGIN
   

   EXEC tSQLt.Private_RenameObject @SchemaName = @SchemaName,
                                   @ObjectName = @ObjectName,
                                   @NewName = @OriginalName;

END;
GO
