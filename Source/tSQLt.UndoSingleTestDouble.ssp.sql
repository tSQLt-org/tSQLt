IF OBJECT_ID('tSQLt.UndoSingleTestDouble') IS NOT NULL DROP PROCEDURE tSQLt.UndoSingleTestDouble;
GO
---Build+
GO
CREATE PROCEDURE tSQLt.UndoSingleTestDouble
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
