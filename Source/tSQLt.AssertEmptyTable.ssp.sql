IF OBJECT_ID('tSQLt.AssertEmptyTable') IS NOT NULL DROP PROCEDURE tSQLt.AssertEmptyTable;
GO
---Build+
CREATE PROCEDURE tSQLt.AssertEmptyTable
  @TableName NVARCHAR(MAX)
AS
BEGIN
  EXEC tSQLt.AssertObjectExists @TableName;

  DECLARE @FullName NVARCHAR(MAX);
  IF(OBJECT_ID(@TableName) IS NULL AND OBJECT_ID('tempdb..'+@TableName) IS NOT NULL)
  BEGIN
    SET @FullName = CASE WHEN LEFT(@TableName,1) = '[' THEN @TableName ELSE QUOTENAME(@TableName)END;
  END;
  ELSE
  BEGIN
    SET @FullName = tSQLt.Private_GetQuotedFullName(OBJECT_ID(@TableName));
  END;

  DECLARE @cmd NVARCHAR(MAX);
  DECLARE @exists INT;
  SET @cmd = 'SELECT @exists = CASE WHEN EXISTS(SELECT 1 FROM '+@FullName+') THEN 1 ELSE 0 END;'
  EXEC sp_executesql @cmd,N'@exists INT OUTPUT', @exists OUTPUT;
  
  IF(@exists = 1)
  BEGIN
    DECLARE @TableToText NVARCHAR(MAX);
    EXEC tSQLt.TableToText @TableName = @FullName,@txt = @TableToText OUTPUT;
    DECLARE @Message NVARCHAR(MAX);
    SET @Message = @FullName + ' was not empty:' + CHAR(13) + CHAR(10)+ @TableToText;
    EXEC tSQLt.Fail @Message;
  END
END