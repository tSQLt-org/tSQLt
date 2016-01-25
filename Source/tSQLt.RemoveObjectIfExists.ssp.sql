IF OBJECT_ID('tSQLt.RemoveObjectIfExists') IS NOT NULL DROP PROCEDURE tSQLt.RemoveObjectIfExists;
GO
---Build+
GO
CREATE PROCEDURE tSQLt.RemoveObjectIfExists 
    @ObjectName NVARCHAR(MAX),
    @NewName NVARCHAR(MAX) = NULL OUTPUT
AS
BEGIN
  EXEC tSQLt.RemoveObject @ObjectName = @ObjectName, @NewName = @NewName OUT, @IfExists = 1;
END;
GO