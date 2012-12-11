IF OBJECT_ID('tSQLt.Private_CompareTablesFailIfUnequalRowsExists') IS NOT NULL DROP PROCEDURE tSQLt.Private_CompareTablesFailIfUnequalRowsExists;
GO
---BUILD+
CREATE PROCEDURE tSQLt.Private_CompareTablesFailIfUnequalRowsExists
 @UnequalRowsExist INT,
 @ResultTable NVARCHAR(MAX),
 @ResultColumn NVARCHAR(MAX),
 @ColumnList NVARCHAR(MAX)
AS
BEGIN
  IF @UnequalRowsExist > 0
  BEGIN
   DECLARE @TableToTextResult NVARCHAR(MAX);
   DECLARE @OutputColumnList NVARCHAR(MAX);
   SELECT @OutputColumnList = '[_m_],' + @ColumnList;
   EXEC tSQLt.TableToText @TableName = @ResultTable, @OrderBy = @ResultColumn, @ColumnList = @OutputColumnList, @txt = @TableToTextResult OUTPUT;
   
   DECLARE @Message NVARCHAR(MAX);
   SELECT @Message = 'unexpected/missing resultset rows!' + CHAR(13) + CHAR(10);

    EXEC tSQLt.Fail @Message, @TableToTextResult;
  END;
END
---BUILD-
GO
