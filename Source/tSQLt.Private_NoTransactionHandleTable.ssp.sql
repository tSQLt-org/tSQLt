IF OBJECT_ID('tSQLt.Private_NoTransactionHandleTable') IS NOT NULL DROP PROCEDURE tSQLt.Private_NoTransactionHandleTable;
GO
---Build+
GO
CREATE PROCEDURE tSQLt.Private_NoTransactionHandleTable
@Action NVARCHAR(MAX),
@FullTableName NVARCHAR(MAX),
@TableAction NVARCHAR(MAX)
AS
BEGIN
  IF (@Action = 'Save')
  BEGIN
    IF (@TableAction = 'Restore')
    BEGIN
      DECLARE @NewQuotedNameForBackupTable NVARCHAR(MAX) = '[tSQLt].'+QUOTENAME(tSQLt.Private::CreateUniqueObjectName());
      DECLARE @Cmd NVARCHAR(MAX) = 'SELECT * INTO '+@NewQuotedNameForBackupTable+' FROM '+@FullTableName+';';
      EXEC (@Cmd);
      INSERT INTO #TableBackupLog (OriginalName, BackupName) VALUES (@FullTableName, @NewQuotedNameForBackupTable);
      EXEC tSQLt.Private_MarktSQLtTempObject @ObjectName = @NewQuotedNameForBackupTable, @ObjectType = N'TABLE', @NewNameOfOriginalObject = NULL; 
    END;
    ELSE IF (@TableAction = 'Remove')
    BEGIN
      EXEC tSQLt.RemoveObject @ObjectName = @FullTableName;
    END;
    ELSE IF (@TableAction IN ('Truncate', 'Ignore'))
    BEGIN
      RETURN;
    END;
    ELSE
    BEGIN
      RAISERROR('Invalid @TableAction parameter value. tSQLt is in an unknown state: Stopping execution.',16,10);
    END;
  END;
  ELSE IF (@Action = 'Reset')
  BEGIN
    PRINT 'Reset!';
  END;
  ELSE
  BEGIN
    RAISERROR('Invalid @Action parameter value. tSQLt is in an unknown state: Stopping execution.',16,10);
  END;
END;
GO
