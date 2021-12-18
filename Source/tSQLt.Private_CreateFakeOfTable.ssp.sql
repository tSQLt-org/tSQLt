IF OBJECT_ID('tSQLt.Private_CreateFakeOfTable') IS NOT NULL DROP PROCEDURE tSQLt.Private_CreateFakeOfTable;
GO
---Build+
CREATE PROCEDURE tSQLt.Private_CreateFakeOfTable
  @SchemaName NVARCHAR(MAX),
  @TableName NVARCHAR(MAX),
  @OrigTableObjectId INT,
  @Identity BIT,
  @ComputedColumns BIT,
  @Defaults BIT
AS
BEGIN
   DECLARE @cmd NVARCHAR(MAX) =
     (SELECT CreateTableStatement 
        FROM tSQLt.Private_CreateFakeTableStatement(@OrigTableObjectId, @SchemaName+'.'+@TableName,@Identity,@ComputedColumns,@Defaults,0));
   EXEC (@cmd);
END;
---Build-
GO
