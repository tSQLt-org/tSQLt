IF OBJECT_ID('tSQLt.Private_CreateFakeOfTable') IS NOT NULL DROP PROCEDURE tSQLt.Private_CreateFakeOfTable;
GO
---Build+
CREATE PROCEDURE tSQLt.Private_CreateFakeOfTable
  @SchemaName NVARCHAR(MAX),
  @TableName NVARCHAR(MAX),
  @OrigTableFullName NVARCHAR(MAX),
  @Identity BIT,
  @ComputedColumns BIT,
  @Defaults BIT
AS
BEGIN
   DECLARE @cmd NVARCHAR(MAX) =
     (SELECT CreateTableStatement FROM tSQLt.Private_CreateFakeTableStatement(@SchemaName+'.'+@TableName,@OrigTableFullName,@Identity,@ComputedColumns,@Defaults,0));
   EXEC (@Cmd);
END;
---Build-
GO
