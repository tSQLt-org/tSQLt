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
    IF (OBJECT_ID(@FullTableName) IS NULL AND @TableAction <> 'Hide')
    BEGIN
      RAISERROR('Table %s does not exist.',16,10,@FullTableName);
    END;
    IF (@Action = 'Save')
    BEGIN
      IF (@TableAction = 'Restore')
      BEGIN
        IF(NOT EXISTS(SELECT 1 FROM #TableBackupLog TBL WHERE TBL.OriginalName = @FullTableName))
        BEGIN
          DECLARE @NewQuotedNameForBackupTable NVARCHAR(MAX) = '[tSQLt].'+QUOTENAME(tSQLt.Private::CreateUniqueObjectName());
          SET @cmd = 'SELECT * INTO '+@NewQuotedNameForBackupTable+' FROM '+@FullTableName+';';
          EXEC (@Cmd);
          INSERT INTO #TableBackupLog (OriginalName, BackupName) VALUES (@FullTableName, @NewQuotedNameForBackupTable);
          EXEC tSQLt.Private_MarktSQLtTempObject @ObjectName = @NewQuotedNameForBackupTable, @ObjectType = N'TABLE', @NewNameOfOriginalObject = NULL; 
        END;
      END;
      ELSE IF (@TableAction = 'Hide')
      BEGIN
        IF (NOT EXISTS (SELECT 1 FROM tSQLt.Private_RenamedObjectLog ROL WHERE QUOTENAME(OBJECT_SCHEMA_NAME(ROL.ObjectId))+'.'+OriginalName = @FullTableName))
        BEGIN
          IF(OBJECT_ID(@FullTableName) IS NULL)
          BEGIN
            RAISERROR('Table %s does not exist.',16,10,@FullTableName);
          END;
          EXEC tSQLt.RemoveObject @ObjectName = @FullTableName;
        END;
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
        BEGIN TRAN;
          DECLARE @BackupTableName TABLE(TableName NVARCHAR(MAX)); 
          DELETE FROM #TableBackupLog OUTPUT DELETED.BackupName INTO @BackupTableName WHERE OriginalName = @FullTableName;
          IF(EXISTS(SELECT 1 FROM @BackupTableName AS BTN))
          BEGIN
            SET @cmd = 'DELETE FROM ' + @FullTableName + ';';
            IF (EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(@FullTableName) AND is_identity = 1))
            BEGIN
              SET @cmd = @cmd + 'SET IDENTITY_INSERT ' + @FullTableName + ' ON;';
            END;
            SET @cmd = @cmd + 'INSERT INTO ' + @FullTableName +'(';
            DECLARE @ColumnList NVARCHAR(MAX) = STUFF((SELECT ','+QUOTENAME(name) FROM sys.columns WHERE object_id = OBJECT_ID(@FullTableName) AND is_computed = 0 ORDER BY column_id FOR XML PATH(''),TYPE).value('.','NVARCHAR(MAX)'),1,1,'');
            SET @cmd = @cmd + @ColumnList;
            SET @cmd = @cmd + ') SELECT ' + @ColumnList + ' FROM ' + (SELECT TableName FROM @BackupTableName)+';';
            EXEC(@cmd);
          END;
        COMMIT;
      END;
      ELSE IF (@TableAction = 'Truncate')
      BEGIN
        EXEC('DELETE FROM ' + @FullTableName +';');
      END;
      ELSE IF (@TableAction IN ('Ignore','Hide')) 
      BEGIN
        /* Hidden tables will be restored by UndoTestDoubles. */
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
--XX--XX--XX--XX--XX--XX--XX--XX--XX--XX--XX--XX--XX--XX--XX--XX--XX--XX--XX--XX--XX--XX--XX--XX--XX--XX--XX--XX--XX--XX--XX--XX--XX--XX--XX--XX--
--DECLARE @TempMsg58 NVARCHAR(MAX) = FORMATMESSAGE('HandleTable(58) - @BackupTableName = %s, @FullTableName = %s, XACT_STATE = %i, SummaryError = %i',(SELECT TableName FROM @BackupTableName), @FullTableName, XACT_STATE(), CAST((SELECT PGC.Value FROM tSQLt.Private_GetConfiguration('SummaryError') AS PGC) AS INT));RAISERROR(@TempMsg58, 0,1) WITH NOWAIT;
--XX--XX--XX--XX--XX--XX--XX--XX--XX--XX--XX--XX--XX--XX--XX--XX--XX--XX--XX--XX--XX--XX--XX--XX--XX--XX--XX--XX--XX--XX--XX--XX--XX--XX--XX--XX--

