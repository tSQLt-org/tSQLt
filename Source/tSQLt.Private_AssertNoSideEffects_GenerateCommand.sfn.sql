IF OBJECT_ID('tSQLt.Private_AssertNoSideEffects_GenerateCommand') IS NOT NULL DROP FUNCTION tSQLt.Private_AssertNoSideEffects_GenerateCommand;
GO
---Build+
GO
CREATE FUNCTION tSQLt.Private_AssertNoSideEffects_GenerateCommand(
  @BeforeExecutionObjectSnapshotTableName NVARCHAR(MAX),
  @AfterExecutionObjectSnapshotTableName NVARCHAR(MAX)
)
RETURNS TABLE
AS
RETURN
  SELECT '
    SELECT * INTO #ObjectDiscrepancies
      FROM(
        (SELECT ''Deleted'' [Status], B.* FROM '+@BeforeExecutionObjectSnapshotTableName+' AS B EXCEPT SELECT ''Deleted'' [Status],* FROM '+@AfterExecutionObjectSnapshotTableName+' AS A)
         UNION ALL
        (SELECT ''Added'' [Status], A.* FROM '+@AfterExecutionObjectSnapshotTableName+' AS A EXCEPT SELECT ''Added'' [Status], * FROM '+@BeforeExecutionObjectSnapshotTableName+' AS B)
      )D;
    IF(EXISTS(SELECT 1 FROM #ObjectDiscrepancies))
    BEGIN
      DECLARE @TableToText NVARCHAR(MAX);
      EXEC tSQLt.TableToText @TableName = ''#ObjectDiscrepancies'' ,@txt = @TableToText OUTPUT, @OrderBy = ''[Status] ASC, SchemaName ASC, ObjectName ASC'';
      RAISERROR(''After the test executed, there were unexpected or missing objects in the database: %s'',16,10,@TableToText);
    END;' Command;
GO
