IF OBJECT_ID('tSQLt.Private_MarkObjectBeforeRename') IS NOT NULL DROP PROCEDURE tSQLt.Private_MarkObjectBeforeRename;
GO
---Build+
CREATE PROCEDURE tSQLt.Private_MarkObjectBeforeRename
    @SchemaName NVARCHAR(MAX), 
    @OriginalName NVARCHAR(MAX)
AS
BEGIN
  INSERT INTO tSQLt.Private_RenamedObjectLog (ObjectId, OriginalName) 
  VALUES (OBJECT_ID(@SchemaName + '.' + @OriginalName), @OriginalName);
END;
---Build-
GO
