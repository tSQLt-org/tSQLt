IF OBJECT_ID('tSQLt.Private_AssertNoSideEffects') IS NOT NULL DROP PROCEDURE tSQLt.Private_AssertNoSideEffects;
GO
---Build+
GO
CREATE PROCEDURE tSQLt.Private_AssertNoSideEffects
  @BeforeExecutionObjectSnapshotTableName NVARCHAR(MAX),
  @AfterExecutionObjectSnapshotTableName NVARCHAR(MAX),
  @TestResult NVARCHAR(MAX) OUTPUT,
  @TestMsg NVARCHAR(MAX) OUTPUT
AS
BEGIN
  DECLARE @cmd NVARCHAR(MAX) = '
    SELECT * INTO #ObjectDiscrepancies
      FROM(
        (SELECT ''Deleted'' [Status], B.* FROM '+@BeforeExecutionObjectSnapshotTableName+' AS B EXCEPT SELECT ''Deleted'' [Status],* FROM '+@AfterExecutionObjectSnapshotTableName+' AS A)
         UNION ALL
        (SELECT ''Added'' [Status], A.* FROM '+@AfterExecutionObjectSnapshotTableName+' AS A EXCEPT SELECT ''Added'' [Status], * FROM '+@BeforeExecutionObjectSnapshotTableName+' AS B)
      )D;
    IF(EXISTS(SELECT 1 FROM #ObjectDiscrepancies))
    BEGIN
      DECLARE @TableToText NVARCHAR(MAX);
      EXEC tSQLt.TableToText @TableName = ''#ObjectDiscrepancies'' ,@txt = @TableToText OUTPUT;
      RAISERROR(''After the test executed, there were unexpected or missing objects in the database: %s'',16,10,@TableToText);
    END;';
  EXEC tSQLt.Private_CleanUpCmdHandler @cmd, @TestResult OUT, @TestMsg OUT;
END;
GO
