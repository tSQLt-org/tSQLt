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
  DECLARE @cmd NVARCHAR(MAX);
  BEGIN TRY
    IF (OBJECT_ID(@FullTableName) IS NULL AND NOT(@Action='Reset' AND @TableAction='Remove'))
    BEGIN
      RAISERROR('Table %s does not exist.',16,10,@FullTableName);
    END;
    IF (@Action = 'Save')
    BEGIN
      IF (@TableAction = 'Restore')
      BEGIN
        DECLARE @NewQuotedNameForBackupTable NVARCHAR(MAX) = '[tSQLt].'+QUOTENAME(tSQLt.Private::CreateUniqueObjectName());
        SET @cmd = 'SELECT * INTO '+@NewQuotedNameForBackupTable+' FROM '+@FullTableName+';';
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
        RAISERROR('Invalid @TableAction parameter value.',16,10);
      END;
    END;
    ELSE IF (@Action = 'Reset')
    BEGIN
      IF (@TableAction = 'Restore')
      BEGIN
        DECLARE @BackupTableName NVARCHAR(MAX) =(SELECT BackupName FROM #TableBackupLog WHERE OriginalName = @FullTableName);
        SET @cmd = 'DELETE FROM ' + @FullTableName + ';';
        IF (EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(@FullTableName) AND is_identity = 1))
        BEGIN
          SET @cmd = @cmd + 'SET IDENTITY_INSERT ' + @FullTableName + ' ON;';
        END;
        SET @cmd = @cmd + 'INSERT INTO ' + @FullTableName +'(';
        SET @cmd = @cmd + STUFF((SELECT ','+QUOTENAME(name) FROM sys.columns WHERE object_id = OBJECT_ID(@FullTableName) ORDER BY column_id FOR XML PATH(''),TYPE).value('.','NVARCHAR(MAX)'),1,1,'');
        SET @cmd = @cmd + ') SELECT * FROM ' + @BackupTableName+';';
        EXEC(@cmd);
      END;
      ELSE IF (@TableAction = 'Truncate')
      BEGIN
        EXEC('DELETE FROM ' + @FullTableName +';');
      END;
      ELSE IF (@TableAction IN ('Ignore','Remove'))
      BEGIN
        RETURN;
      END;
      ELSE
      BEGIN
        RAISERROR('Invalid @TableAction parameter value.', 16, 10);
      END;
    END;
    ELSE
    BEGIN
      RAISERROR('Invalid @Action parameter value.',16,10);
    END;
  END TRY
  BEGIN CATCH
    DECLARE @ErrorLine INT = ERROR_LINE();
    DECLARE @ErrorProcedure NVARCHAR(MAX) = ERROR_PROCEDURE();
    DECLARE @ErrorMessage NVARCHAR(MAX) = ERROR_MESSAGE();
    DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
    DECLARE @ErrorState INT = ERROR_STATE();
    RAISERROR('tSQLt is in an unknown state: Stopping execution. (%s | Procedure: %s | Line: %i)', @ErrorSeverity, @ErrorState, @ErrorMessage, @ErrorProcedure, @ErrorLine);
  END CATCH;
END;
GO
