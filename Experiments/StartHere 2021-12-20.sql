
EXEC tSQLt.NewTestClass 'NotInnerTests';
GO
CREATE PROCEDURE NotInnerTests.[test brittle transaction test]
AS
BEGIN
  BEGIN TRAN;
END;
GO

--EXEC tSQLt.Private_RunTest @TestName = 'NotInnerTests.[test brittle transaction test]';


    DROP TABLE IF EXISTS #TestMessage;
    DROP TABLE IF EXISTS #ExpectException;
    DROP TABLE IF EXISTS #SkipTest;
    DROP TABLE IF EXISTS #NoTransaction;
    DROP TABLE IF EXISTS #TableBackupLog;
    GO

    DECLARE @TestName NVARCHAR(MAX) = 'NotInnerTests.[test brittle transaction test]';
    DECLARE @SetUp NVARCHAR(MAX) = NULL;
    DECLARE @CleanUp NVARCHAR(MAX) = NULL;

    DECLARE @OuterPerimeterTrancount INT = @@TRANCOUNT;

    DECLARE @Msg NVARCHAR(MAX); SET @Msg = '';
    DECLARE @Msg2 NVARCHAR(MAX); SET @Msg2 = '';
    DECLARE @TestClassName NVARCHAR(MAX); SET @TestClassName = '';
    DECLARE @TestProcName NVARCHAR(MAX); SET @TestProcName = '';
    DECLARE @Result NVARCHAR(MAX);
    DECLARE @TranName CHAR(32) = NULL;
    DECLARE @TestResultId INT;
    DECLARE @TestObjectId INT;
    DECLARE @TestEndTime DATETIME2 = NULL;

    DECLARE @VerboseMsg NVARCHAR(MAX);
    DECLARE @Verbose BIT;
    SET @Verbose = ISNULL((SELECT CAST(Value AS BIT) FROM tSQLt.Private_GetConfiguration('Verbose')),0);
    
    TRUNCATE TABLE tSQLt.CaptureOutputLog;
    CREATE TABLE #TestMessage(Msg NVARCHAR(MAX));
    CREATE TABLE #ExpectException(ExpectException INT,ExpectedMessage NVARCHAR(MAX), ExpectedSeverity INT, ExpectedState INT, ExpectedMessagePattern NVARCHAR(MAX), ExpectedErrorNumber INT, FailMessage NVARCHAR(MAX));
    CREATE TABLE #SkipTest(SkipTestMessage NVARCHAR(MAX) DEFAULT '');
    CREATE TABLE #NoTransaction(OrderId INT IDENTITY(1,1),CleanUpProcedureName NVARCHAR(MAX));
    CREATE TABLE #TableBackupLog(OriginalName NVARCHAR(MAX), BackupName NVARCHAR(MAX));

    
    SELECT @TestClassName = OBJECT_SCHEMA_NAME(OBJECT_ID(@TestName)),
           @TestProcName = tSQLt.Private_GetCleanObjectName(@TestName),
           @TestObjectId = OBJECT_ID(@TestName);
           
    INSERT INTO tSQLt.TestResult(Class, TestCase, TranName, Result) 
        SELECT @TestClassName, @TestProcName, @TranName, 'A severe error happened during test execution. Test did not finish.'
        OPTION(MAXDOP 1);
    SELECT @TestResultId = SCOPE_IDENTITY();

    IF(@Verbose = 1)
    BEGIN
      SET @VerboseMsg = 'tSQLt.Run '''+@TestName+'''; --Starting';
      EXEC tSQLt.Private_Print @Message =@VerboseMsg, @Severity = 0;
    END;


    SET @Result = 'Success';
    DECLARE @SkipTestFlag BIT = 0;
    DECLARE @NoTransactionFlag BIT = 0;

    --BEGIN TRY
      --EXEC tSQLt.Private_ProcessTestAnnotations @TestObjectId=@TestObjectId;
      --SET @SkipTestFlag = CASE WHEN EXISTS(SELECT 1 FROM #SkipTest) THEN 1 ELSE 0 END;
      --SET @NoTransactionFlag = CASE WHEN EXISTS(SELECT 1 FROM #NoTransaction) THEN 1 ELSE 0 END;

      --IF(@SkipTestFlag = 0)
      --BEGIN
      --  IF(@NoTransactionFlag = 0)
      --  BEGIN
      --    EXEC tSQLt.GetNewTranName @TranName OUT;
      --    UPDATE tSQLt.TestResult SET TranName = @TranName WHERE Id = @TestResultId;
      --  END;
        --EXEC tSQLt.Private_RunTest_TestExecution
        --  @TestName,
        --  @SetUp,
        --  @CleanUp,
        --  @NoTransactionFlag,
        --  @TranName,
        --  @Result OUT,
        --  @Msg OUT,
        --  @TestEndTime OUT;
IF (1=1)
BEGIN
  DECLARE @TransactionStartedFlag BIT = 0;
  DECLARE @PreExecTrancount INT = NULL;
  DECLARE @TestExecutionCmd NVARCHAR(MAX) = 'EXEC ' + @TestName;
  DECLARE @CleanUpProcedureExecutionCmd NVARCHAR(MAX) = NULL;

    BEGIN TRY

      IF(@NoTransactionFlag = 0)
      BEGIN
        BEGIN TRAN;
        SET @TransactionStartedFlag = 1;
        SAVE TRAN @TranName;
      END;
      ELSE
      BEGIN
        SELECT object_id ObjectId, SCHEMA_NAME(schema_id) SchemaName, name ObjectName, type_desc ObjectType INTO #BeforeExecutionObjectSnapshot FROM sys.objects;
        EXEC tSQLt.Private_NoTransactionHandleTables @Action = 'Save';
      END;

      SET @PreExecTrancount = @@TRANCOUNT;
    
      DECLARE @TmpMsg NVARCHAR(MAX);
      SET @TestEndTime = NULL;
      BEGIN TRY
        IF (@SetUp IS NOT NULL)
        BEGIN
          EXEC @SetUp;
        END;

        BEGIN TRY
          SELECT XACT_STATE(),@@TRANCOUNT,@TestExecutionCmd;
          EXEC (@TestExecutionCmd);
        END TRY
        BEGIN CATCH
        SELECT XACT_STATE(),@@TRANCOUNT,@TestExecutionCmd;
          THROW;
        END CATCH;

        IF(EXISTS(SELECT 1 FROM #ExpectException WHERE ExpectException = 1))
        BEGIN
          SET @TmpMsg = COALESCE((SELECT FailMessage FROM #ExpectException)+' ','')+'Expected an error to be raised.';
          EXEC tSQLt.Fail @TmpMsg;
        END
        SET @TestEndTime = SYSDATETIME();
      END TRY
      BEGIN CATCH
          SET @TestEndTime = ISNULL(@TestEndTime,SYSDATETIME());
          IF ERROR_MESSAGE() LIKE '%tSQLt.Failure%'
          BEGIN
              SELECT @Msg = Msg FROM #TestMessage;
              SET @Result = 'Failure';
          END
          ELSE
          BEGIN
            DECLARE @ErrorInfo NVARCHAR(MAX);
            SELECT @ErrorInfo = FormattedError FROM tSQLt.Private_GetFormattedErrorInfo();

            IF(EXISTS(SELECT 1 FROM #ExpectException))
            BEGIN
              DECLARE @ExpectException INT;
              DECLARE @ExpectedMessage NVARCHAR(MAX);
              DECLARE @ExpectedMessagePattern NVARCHAR(MAX);
              DECLARE @ExpectedSeverity INT;
              DECLARE @ExpectedState INT;
              DECLARE @ExpectedErrorNumber INT;
              DECLARE @FailMessage NVARCHAR(MAX);
              SELECT @ExpectException = ExpectException,
                     @ExpectedMessage = ExpectedMessage, 
                     @ExpectedSeverity = ExpectedSeverity,
                     @ExpectedState = ExpectedState,
                     @ExpectedMessagePattern = ExpectedMessagePattern,
                     @ExpectedErrorNumber = ExpectedErrorNumber,
                     @FailMessage = FailMessage
                FROM #ExpectException;

              IF(@ExpectException = 1)
              BEGIN
                SET @Result = 'Success';
                SET @TmpMsg = COALESCE(@FailMessage+' ','')+'Exception did not match expectation!';
                IF(ERROR_MESSAGE() <> @ExpectedMessage)
                BEGIN
                  SET @TmpMsg = @TmpMsg +CHAR(13)+CHAR(10)+
                             'Expected Message: <'+@ExpectedMessage+'>'+CHAR(13)+CHAR(10)+
                             'Actual Message  : <'+ERROR_MESSAGE()+'>';
                  SET @Result = 'Failure';
                END
                IF(ERROR_MESSAGE() NOT LIKE @ExpectedMessagePattern)
                BEGIN
                  SET @TmpMsg = @TmpMsg +CHAR(13)+CHAR(10)+
                             'Expected Message to be like <'+@ExpectedMessagePattern+'>'+CHAR(13)+CHAR(10)+
                             'Actual Message            : <'+ERROR_MESSAGE()+'>';
                  SET @Result = 'Failure';
                END
                IF(ERROR_NUMBER() <> @ExpectedErrorNumber)
                BEGIN
                  SET @TmpMsg = @TmpMsg +CHAR(13)+CHAR(10)+
                             'Expected Error Number: '+CAST(@ExpectedErrorNumber AS NVARCHAR(MAX))+CHAR(13)+CHAR(10)+
                             'Actual Error Number  : '+CAST(ERROR_NUMBER() AS NVARCHAR(MAX));
                  SET @Result = 'Failure';
                END
                IF(ERROR_SEVERITY() <> @ExpectedSeverity)
                BEGIN
                  SET @TmpMsg = @TmpMsg +CHAR(13)+CHAR(10)+
                             'Expected Severity: '+CAST(@ExpectedSeverity AS NVARCHAR(MAX))+CHAR(13)+CHAR(10)+
                             'Actual Severity  : '+CAST(ERROR_SEVERITY() AS NVARCHAR(MAX));
                  SET @Result = 'Failure';
                END
                IF(ERROR_STATE() <> @ExpectedState)
                BEGIN
                  SET @TmpMsg = @TmpMsg +CHAR(13)+CHAR(10)+
                             'Expected State: '+CAST(@ExpectedState AS NVARCHAR(MAX))+CHAR(13)+CHAR(10)+
                             'Actual State  : '+CAST(ERROR_STATE() AS NVARCHAR(MAX));
                  SET @Result = 'Failure';
                END
                IF(@Result = 'Failure')
                BEGIN
                  SET @Msg = @TmpMsg;
                END
              END 
              ELSE
              BEGIN
                  SET @Result = 'Failure';
                  SET @Msg = 
                    COALESCE(@FailMessage+' ','')+
                    'Expected no error to be raised. Instead this error was encountered:'+
                    CHAR(13)+CHAR(10)+
                    @ErrorInfo;
              END
            END;
            ELSE
            BEGIN
              SET @Result = 'Error';
              SET @Msg = @ErrorInfo;
            END; 
          END;
      END CATCH;
    END TRY
    BEGIN CATCH
        SET @Result = 'Error';
        SET @Msg = ERROR_MESSAGE();
    END CATCH

    --TODO:NoTran
    ---- Compare @@Trancount, throw up arms if it doesn't match
    --TODO:NoTran
    BEGIN TRY
      IF(@TransactionStartedFlag = 1)
      BEGIN
        ROLLBACK TRAN @TranName;
      END;
    END TRY
    BEGIN CATCH
        DECLARE @PostExecTrancount INT;
        SET @PostExecTrancount = @PreExecTrancount - @@TRANCOUNT;
        IF (@@TRANCOUNT > 0) ROLLBACK;
        BEGIN TRAN;
        IF(   @Result <> 'Success'
           OR @PostExecTrancount <> 0
          )
        BEGIN
          SELECT @Msg = COALESCE(@Msg, '<NULL>') + ' (There was also a ROLLBACK ERROR --> ' + FormattedError + ')' FROM tSQLt.Private_GetFormattedErrorInfo();
          SET @Result = 'Error';
        END;
    END CATCH;  
    IF (@NoTransactionFlag = 1)
    BEGIN
      SET @CleanUpProcedureExecutionCmd = (
        (
          SELECT 'EXEC tSQLt.Private_CleanUpCmdHandler ''EXEC '+ REPLACE(NT.CleanUpProcedureName,'''','''''') +';'', @Result OUT, @Msg OUT;'
            FROM #NoTransaction NT
           ORDER BY OrderId
             FOR XML PATH(''),TYPE
        ).value('.','NVARCHAR(MAX)')
      );
      IF(@CleanUpProcedureExecutionCmd IS NOT NULL)
      BEGIN
        EXEC sys.sp_executesql @CleanUpProcedureExecutionCmd, N'@Result NVARCHAR(MAX) OUTPUT, @Msg NVARCHAR(MAX) OUTPUT', @Result OUT, @Msg OUT;
      END;

      IF(@CleanUp IS NOT NULL)
      BEGIN
        EXEC tSQLt.Private_CleanUpCmdHandler @CleanUp, @Result OUT, @Msg OUT;
      END;

      DECLARE @CleanUpErrorMsg NVARCHAR(MAX);
      EXEC tSQLt.Private_CleanUp @FullTestName = @TestName, @Result = @Result OUT, @ErrorMsg = @CleanUpErrorMsg OUT;
      SET @Msg = @Msg + ISNULL(' ' + @CleanUpErrorMsg, '');

      SELECT object_id ObjectId, SCHEMA_NAME(schema_id) SchemaName, name ObjectName, type_desc ObjectType INTO #AfterExecutionObjectSnapshot FROM sys.objects;
      EXEC tSQLt.Private_AssertNoSideEffects
             @BeforeExecutionObjectSnapshotTableName ='#BeforeExecutionObjectSnapshot',
             @AfterExecutionObjectSnapshotTableName = '#AfterExecutionObjectSnapshot',
             @TestResult = @Result OUT,
             @TestMsg = @Msg OUT
    END;
    IF(@TransactionStartedFlag = 1)
    BEGIN
      COMMIT;
    END;
END;

      --END;
      --ELSE
      --BEGIN
      --  DECLARE @TmpMsg NVARCHAR(MAX);
      --  SELECT 
      --      @Result = 'Skipped',
      --      @Msg = ST.SkipTestMessage 
      --    FROM #SkipTest AS ST;
      --  SET @TmpMsg = '-->'+@TestName+' skipped: '+@Msg;
      --  EXEC tSQLt.Private_Print @Message = @TmpMsg;
      --  SET @TestEndTime = SYSDATETIME();
      --END;
    --END TRY
    --BEGIN CATCH
    --  SET @Result = 'Error';
    --  SET @Msg = ISNULL(NULLIF(@Msg,'') + ' ','')+ERROR_MESSAGE();
    --  --SET @TestEndTime = SYSDATETIME();
    --END CATCH;
------------------------------------------------------------------------------------------------
--    If(@Result NOT IN ('Success','Skipped'))
--    BEGIN
--      SET @Msg2 = @TestName + ' failed: (' + @Result + ') ' + @Msg;
--      EXEC tSQLt.Private_Print @Message = @Msg2, @Severity = 0;
--    END;
--    IF EXISTS(SELECT 1 FROM tSQLt.TestResult WHERE Id = @TestResultId)
--    BEGIN
--        UPDATE tSQLt.TestResult SET
--            Result = @Result,
--            Msg = @Msg,
--            TestEndTime = @TestEndTime
--         WHERE Id = @TestResultId;
--    END;
--    ELSE
--    BEGIN
--        INSERT tSQLt.TestResult(Class, TestCase, TranName, Result, Msg)
--        SELECT @TestClassName, 
--               @TestProcName,  
--               '?', 
--               'Error', 
--               'TestResult entry is missing; Original outcome: ' + @Result + ', ' + @Msg;
--    END;    

--    IF(@Verbose = 1)
--    BEGIN
--      SET @VerboseMsg = 'tSQLt.Run '''+@TestName+'''; --Finished';
--      EXEC tSQLt.Private_Print @Message =@VerboseMsg, @Severity = 0;
--      --DECLARE @AsciiArtLine NVARCHAR(MAX) = CASE WHEN @Result<>'Success' THEN REPLICATE(CHAR(168),150)+' '+CHAR(155)+CHAR(155)+' '+@Result + ' ' +CHAR(139)+CHAR(139) ELSE '' END + CHAR(13)+CHAR(10) + CHAR(173);
--      --EXEC tSQLt.Private_Print @Message = @AsciiArtLine, @Severity = 0;
--    END;

--    IF(@Result = 'FATAL')
--    BEGIN
--      INSERT INTO tSQLt.Private_Seize VALUES(1);   
--      RAISERROR('The last test has invalidated the current installation of tSQLt. Please reinstall tSQLt.',16,10);
--    END;
--    IF(@Result = 'Abort')
--    BEGIN
--      RAISERROR('Aborting the current execution of tSQLt due to a severe error.', 16, 10);
--    END;

--    IF(@OuterPerimeterTrancount != @@TRANCOUNT) RAISERROR('tSQLt is in an invalid state: Stopping Execution. (Mismatching TRANCOUNT: %i <> %i))',16,10,@OuterPerimeterTrancount, @@TRANCOUNT);
