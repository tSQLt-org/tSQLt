IF OBJECT_ID('tSQLt.Private_GetClassHelperProcedureName') IS NOT NULL DROP PROCEDURE tSQLt.Private_GetClassHelperProcedureName;
IF OBJECT_ID('tSQLt.Private_RunTest') IS NOT NULL DROP PROCEDURE tSQLt.Private_RunTest;
IF OBJECT_ID('tSQLt.Private_RunTestClass') IS NOT NULL DROP PROCEDURE tSQLt.Private_RunTestClass;
IF OBJECT_ID('tSQLt.Private_Run') IS NOT NULL DROP PROCEDURE tSQLt.Private_Run;
IF OBJECT_ID('tSQLt.Private_RunCursor') IS NOT NULL DROP PROCEDURE tSQLt.Private_RunCursor;
IF OBJECT_ID('tSQLt.Private_RunAll') IS NOT NULL DROP PROCEDURE tSQLt.Private_RunAll;
IF OBJECT_ID('tSQLt.Private_RunNew') IS NOT NULL DROP PROCEDURE tSQLt.Private_RunNew;
IF OBJECT_ID('tSQLt.Private_GetCursorForRunAll') IS NOT NULL DROP PROCEDURE tSQLt.Private_GetCursorForRunAll;
IF OBJECT_ID('tSQLt.Private_GetCursorForRunNew') IS NOT NULL DROP PROCEDURE tSQLt.Private_GetCursorForRunNew;
IF OBJECT_ID('tSQLt.Private_RunMethodHandler') IS NOT NULL DROP PROCEDURE tSQLt.Private_RunMethodHandler;
IF OBJECT_ID('tSQLt.Private_InputBuffer') IS NOT NULL DROP PROCEDURE tSQLt.Private_InputBuffer;
IF OBJECT_ID('tSQLt.RunAll') IS NOT NULL DROP PROCEDURE tSQLt.RunAll;
IF OBJECT_ID('tSQLt.RunNew') IS NOT NULL DROP PROCEDURE tSQLt.RunNew;
IF OBJECT_ID('tSQLt.RunTest') IS NOT NULL DROP PROCEDURE tSQLt.RunTest;
IF OBJECT_ID('tSQLt.RunC') IS NOT NULL DROP PROCEDURE tSQLt.RunC;
IF OBJECT_ID('tSQLt.Run') IS NOT NULL DROP PROCEDURE tSQLt.Run;
IF OBJECT_ID('tSQLt.RunWithXmlResults') IS NOT NULL DROP PROCEDURE tSQLt.RunWithXmlResults;
IF OBJECT_ID('tSQLt.RunWithNullResults') IS NOT NULL DROP PROCEDURE tSQLt.RunWithNullResults;
IF OBJECT_ID('tSQLt.DefaultResultFormatter') IS NOT NULL DROP PROCEDURE tSQLt.DefaultResultFormatter;
IF OBJECT_ID('tSQLt.XmlResultFormatter') IS NOT NULL DROP PROCEDURE tSQLt.XmlResultFormatter;
IF OBJECT_ID('tSQLt.NullTestResultFormatter') IS NOT NULL DROP PROCEDURE tSQLt.NullTestResultFormatter;
IF OBJECT_ID('tSQLt.RunTestClass') IS NOT NULL DROP PROCEDURE tSQLt.RunTestClass;
IF OBJECT_ID('tSQLt.Private_PrepareTestResultForOutput') IS NOT NULL DROP FUNCTION tSQLt.Private_PrepareTestResultForOutput;
GO
---Build+

CREATE PROCEDURE tSQLt.Private_GetClassHelperProcedureName
  @TestClassId INT = NULL,
  @SetupProcName NVARCHAR(MAX) OUTPUT,
  @CleanUpProcName NVARCHAR(MAX) OUTPUT
AS
BEGIN
    SELECT @SetupProcName = tSQLt.Private_GetQuotedFullName(object_id)
      FROM sys.procedures
     WHERE schema_id = @TestClassId
       AND LOWER(name) = 'setup';
    SELECT @CleanUpProcName = tSQLt.Private_GetQuotedFullName(object_id)
      FROM sys.procedures
     WHERE schema_id = @TestClassId
       AND LOWER(name) = 'cleanup';
END;
GO

CREATE PROCEDURE tSQLt.Private_RunTest
   @TestName NVARCHAR(MAX),
   @SetUp NVARCHAR(MAX) = NULL,
   @CleanUp NVARCHAR(MAX) = NULL
AS
BEGIN
    DECLARE @OuterPerimeterTrancount INT = @@TRANCOUNT;

    DECLARE @Msg NVARCHAR(MAX); SET @Msg = '';
    DECLARE @Msg2 NVARCHAR(MAX); SET @Msg2 = '';
    DECLARE @Cmd NVARCHAR(MAX); SET @Cmd = '';
    DECLARE @TestClassName NVARCHAR(MAX); SET @TestClassName = '';
    DECLARE @TestProcName NVARCHAR(MAX); SET @TestProcName = '';
    DECLARE @Result NVARCHAR(MAX);
    DECLARE @TranName CHAR(32) = NULL;
    DECLARE @TestResultId INT;
    DECLARE @PreExecTrancount INT = NULL;
    DECLARE @TestObjectId INT;

    DECLARE @VerboseMsg NVARCHAR(MAX);
    DECLARE @Verbose BIT;
    SET @Verbose = ISNULL((SELECT CAST(Value AS BIT) FROM tSQLt.Private_GetConfiguration('Verbose')),0);
    
    TRUNCATE TABLE tSQLt.CaptureOutputLog;
    CREATE TABLE #TestMessage(Msg NVARCHAR(MAX));
    CREATE TABLE #ExpectException(ExpectException INT,ExpectedMessage NVARCHAR(MAX), ExpectedSeverity INT, ExpectedState INT, ExpectedMessagePattern NVARCHAR(MAX), ExpectedErrorNumber INT, FailMessage NVARCHAR(MAX));
    CREATE TABLE #SkipTest(SkipTestMessage NVARCHAR(MAX) DEFAULT '');
    CREATE TABLE #NoTransaction(OrderId INT IDENTITY(1,1),CleanUpProcedureName NVARCHAR(MAX));
    CREATE TABLE #TableBackupLog(OriginalName NVARCHAR(MAX), BackupName NVARCHAR(MAX));


    IF EXISTS (SELECT 1 FROM sys.extended_properties WHERE name = N'SetFakeViewOnTrigger')
    BEGIN
      RAISERROR('Test system is in an invalid state. SetFakeViewOff must be called if SetFakeViewOn was called. Call SetFakeViewOff after creating all test case procedures.', 16, 10) WITH NOWAIT;
      RETURN -1;
    END;

    SELECT @Cmd = 'EXEC ' + @TestName;
    
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
    DECLARE @NoTransactionTestCleanUpProcedureName NVARCHAR(MAX) = NULL;
    DECLARE @TransactionStartedFlag BIT = 0;
    BEGIN TRY

      EXEC tSQLt.Private_ProcessTestAnnotations @TestObjectId=@TestObjectId;
      SET @SkipTestFlag = CASE WHEN EXISTS(SELECT 1 FROM #SkipTest) THEN 1 ELSE 0 END;
      SET @NoTransactionFlag = CASE WHEN EXISTS(SELECT 1 FROM #NoTransaction) THEN 1 ELSE 0 END;

      IF(@NoTransactionFlag = 0)
      BEGIN
        EXEC tSQLt.GetNewTranName @TranName OUT;
        UPDATE tSQLt.TestResult SET TranName = @TranName WHERE Id = @TestResultId;
        BEGIN TRAN;
        SET @TransactionStartedFlag = 1;
        SAVE TRAN @TranName;
      END;
      ELSE
      BEGIN
        IF(@SkipTestFlag = 0)
        BEGIN
          EXEC tSQLt.Private_NoTransactionHandleTables @Action = 'Save';
        END;
      END;

      SET @PreExecTrancount = @@TRANCOUNT;
    
      DECLARE @TmpMsg NVARCHAR(MAX);
      DECLARE @TestEndTime DATETIME2; SET @TestEndTime = NULL;
      BEGIN TRY
        IF(@SkipTestFlag = 0)
        BEGIN
          IF (@SetUp IS NOT NULL)
          BEGIN
            EXEC @SetUp;
          END;
          EXEC (@Cmd);

    --TODO:NoTran
    ----EXEC @CleanUp --Probably further down, called "<TestClassName>.CleanUp"
          IF(EXISTS(SELECT 1 FROM #ExpectException WHERE ExpectException = 1))
          BEGIN
            SET @TmpMsg = COALESCE((SELECT FailMessage FROM #ExpectException)+' ','')+'Expected an error to be raised.';
            EXEC tSQLt.Fail @TmpMsg;
          END
        END;
        ELSE
        BEGIN
          SELECT 
              @Result = 'Skipped',
              @Msg = ST.SkipTestMessage 
            FROM #SkipTest AS ST;
          SET @TmpMsg = '-->'+@TestName+' skipped: '+@Msg;
          EXEC tSQLt.Private_Print @Message = @TmpMsg;
        END;
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
            SELECT @ErrorInfo = 
              COALESCE(ERROR_MESSAGE(), '<ERROR_MESSAGE() is NULL>') + 
              '[' +COALESCE(LTRIM(STR(ERROR_SEVERITY())), '<ERROR_SEVERITY() is NULL>') + ','+COALESCE(LTRIM(STR(ERROR_STATE())), '<ERROR_STATE() is NULL>') + ']' +
              '{' + COALESCE(ERROR_PROCEDURE(), '<ERROR_PROCEDURE() is NULL>') + ',' + COALESCE(CAST(ERROR_LINE() AS NVARCHAR), '<ERROR_LINE() is NULL>') + '}';

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
          SELECT @Msg = COALESCE(@Msg, '<NULL>') + ' (There was also a ROLLBACK ERROR --> ' + COALESCE(ERROR_MESSAGE(), '<ERROR_MESSAGE() is NULL>') + '{' + COALESCE(ERROR_PROCEDURE(), '<ERROR_PROCEDURE() is NULL>') + ',' + COALESCE(CAST(ERROR_LINE() AS NVARCHAR), '<ERROR_LINE() is NULL>') + '})';
          SET @Result = 'Error';
        END;
    END CATCH;  

    IF (@NoTransactionFlag = 1 AND @SkipTestFlag = 0)
    BEGIN
      SET @NoTransactionTestCleanUpProcedureName = (
        (
          SELECT 'EXEC '+ NT.CleanUpProcedureName +';'
            FROM #NoTransaction NT
           ORDER BY OrderId
             FOR XML PATH(''),TYPE
        ).value('.','NVARCHAR(MAX)')
      );
      EXEC(@NoTransactionTestCleanUpProcedureName);

      IF(@CleanUp IS NOT NULL)
      BEGIN
        EXEC @CleanUp;
      END;

      DECLARE @CleanUpErrorMsg NVARCHAR(MAX);
      EXEC tSQLt.Private_CleanUp @FullTestName = @TestName, @ErrorMsg = @CleanUpErrorMsg OUT;
      SET @Msg = @Msg + ISNULL(' ' + @CleanUpErrorMsg, '');
    END;

    If(@Result NOT IN ('Success','Skipped'))
    BEGIN
      SET @Msg2 = @TestName + ' failed: (' + @Result + ') ' + @Msg;
      EXEC tSQLt.Private_Print @Message = @Msg2, @Severity = 0;
    END;

    IF EXISTS(SELECT 1 FROM tSQLt.TestResult WHERE Id = @TestResultId)
    BEGIN
        UPDATE tSQLt.TestResult SET
            Result = @Result,
            Msg = @Msg,
            TestEndTime = @TestEndTime
         WHERE Id = @TestResultId;
    END;
    ELSE
    BEGIN
        INSERT tSQLt.TestResult(Class, TestCase, TranName, Result, Msg)
        SELECT @TestClassName, 
               @TestProcName,  
               '?', 
               'Error', 
               'TestResult entry is missing; Original outcome: ' + @Result + ', ' + @Msg;
    END;    

    IF(@TransactionStartedFlag = 1)
    BEGIN
      COMMIT;
    END;

    IF(@Verbose = 1)
    BEGIN
    SET @VerboseMsg = 'tSQLt.Run '''+@TestName+'''; --Finished';
      EXEC tSQLt.Private_Print @Message =@VerboseMsg, @Severity = 0;
    END;

    IF(@OuterPerimeterTrancount != @@TRANCOUNT) RAISERROR('tSQLt is in an invalid state: Stopping Execution. (Mismatching TRANCOUNT: %i <> %i))',16,10,@OuterPerimeterTrancount, @@TRANCOUNT);

END;
GO

CREATE PROCEDURE tSQLt.Private_RunTestClass
  @TestClassName NVARCHAR(MAX)
AS
BEGIN
    DECLARE @TestCaseName NVARCHAR(MAX);
    DECLARE @TestClassId INT; SET @TestClassId = tSQLt.Private_GetSchemaId(@TestClassName);
    DECLARE @SetupProcName NVARCHAR(MAX);
    DECLARE @CleanUpProcName NVARCHAR(MAX);
    EXEC tSQLt.Private_GetClassHelperProcedureName @TestClassId, @SetupProcName OUT, @CleanUpProcName OUT;
    
    DECLARE @cmd NVARCHAR(MAX) = (
      (
        SELECT 'EXEC tSQLt.Private_RunTest '''+REPLACE(tSQLt.Private_GetQuotedFullName(object_id),'''','''''')+''', '+ISNULL(''''+REPLACE(@SetupProcName,'''','''''')+'''','NULL')+', '+ISNULL(''''+REPLACE(@CleanUpProcName,'''','''''')+'''','NULL')+';'
          FROM sys.procedures
         WHERE schema_id = @TestClassId
           AND LOWER(name) LIKE 'test%'
         ORDER BY NEWID()
           FOR XML PATH(''),TYPE
      ).value('.','NVARCHAR(MAX)')
    );
    EXEC(@cmd);
END;
GO

CREATE PROCEDURE tSQLt.Private_Run
   @TestName NVARCHAR(MAX),
   @TestResultFormatter NVARCHAR(MAX)
AS
BEGIN
SET NOCOUNT ON;
    DECLARE @FullName NVARCHAR(MAX);
    DECLARE @TestClassId INT;
    DECLARE @IsTestClass BIT;
    DECLARE @IsTestCase BIT;
    DECLARE @IsSchema BIT;
    DECLARE @SetUp NVARCHAR(MAX);SET @SetUp = NULL;
    
    SELECT @TestName = TestName FROM tSQLt.Private_GetLastTestNameIfNotProvided(@TestName);
    EXEC tSQLt.Private_SaveTestNameForSession @TestName;
    
    SELECT @TestClassId = schemaId,
           @FullName = quotedFullName,
           @IsTestClass = isTestClass,
           @IsSchema = isSchema,
           @IsTestCase = isTestCase
      FROM tSQLt.Private_ResolveName(@TestName);

    IF @IsSchema = 1
    BEGIN
        EXEC tSQLt.Private_RunTestClass @FullName;
    END
    
    IF @IsTestCase = 1
    BEGIN
      DECLARE @SetupProcName NVARCHAR(MAX);
      DECLARE @CleanUpProcName NVARCHAR(MAX);
      EXEC tSQLt.Private_GetClassHelperProcedureName @TestClassId, @SetupProcName OUT, @CleanUpProcName OUT;

      EXEC tSQLt.Private_RunTest @FullName, @SetupProcName, @CleanUpProcName;
    END;

    EXEC tSQLt.Private_OutputTestResults @TestResultFormatter;
END;
GO


CREATE PROCEDURE tSQLt.Private_RunCursor
  @TestResultFormatter NVARCHAR(MAX),
  @GetCursorCallback NVARCHAR(MAX)
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @TestClassName NVARCHAR(MAX);
  DECLARE @TestProcName NVARCHAR(MAX);

  CREATE TABLE #TestClassesForRunCursor(Name NVARCHAR(MAX));
  EXEC @GetCursorCallback;
----  
  DECLARE @cmd NVARCHAR(MAX) = (
    (
      SELECT 'EXEC tSQLt.Private_RunTestClass '''+REPLACE(Name, '''' ,'''''')+''';'
        FROM #TestClassesForRunCursor
         FOR XML PATH(''),TYPE
    ).value('.','NVARCHAR(MAX)')
  );
  EXEC(@cmd);
  
  EXEC tSQLt.Private_OutputTestResults @TestResultFormatter;
END;
GO

CREATE PROCEDURE tSQLt.Private_GetCursorForRunAll
AS
BEGIN
  INSERT INTO #TestClassesForRunCursor
   SELECT Name
     FROM tSQLt.TestClasses;
END;
GO

CREATE PROCEDURE tSQLt.Private_RunAll
  @TestResultFormatter NVARCHAR(MAX)
AS
BEGIN
  EXEC tSQLt.Private_RunCursor @TestResultFormatter = @TestResultFormatter, @GetCursorCallback = 'tSQLt.Private_GetCursorForRunAll';
END;
GO

CREATE PROCEDURE tSQLt.Private_GetCursorForRunNew
AS
BEGIN
  INSERT INTO #TestClassesForRunCursor
   SELECT TC.Name
     FROM tSQLt.TestClasses AS TC
     JOIN tSQLt.Private_NewTestClassList AS PNTCL
       ON PNTCL.ClassName = TC.Name;
END;
GO

CREATE PROCEDURE tSQLt.Private_RunNew
  @TestResultFormatter NVARCHAR(MAX)
AS
BEGIN
  EXEC tSQLt.Private_RunCursor @TestResultFormatter = @TestResultFormatter, @GetCursorCallback = 'tSQLt.Private_GetCursorForRunNew';
END;
GO

CREATE PROCEDURE tSQLt.Private_RunMethodHandler
  @RunMethod NVARCHAR(MAX),
  @TestResultFormatter NVARCHAR(MAX) = NULL,
  @TestName NVARCHAR(MAX) = NULL
AS
BEGIN
  SELECT @TestResultFormatter = ISNULL(@TestResultFormatter,tSQLt.GetTestResultFormatter());

  EXEC tSQLt.Private_Init;
  IF(@@ERROR = 0)
  BEGIN  
    IF(EXISTS(SELECT * FROM sys.parameters AS P WHERE P.object_id = OBJECT_ID(@RunMethod) AND name = '@TestName'))
    BEGIN
      EXEC @RunMethod @TestName = @TestName, @TestResultFormatter = @TestResultFormatter;
    END;
    ELSE
    BEGIN  
      EXEC @RunMethod @TestResultFormatter = @TestResultFormatter;
    END;
  END;
END;
GO

--------------------------------------------------------------------------------

GO
CREATE PROCEDURE tSQLt.RunAll
AS
BEGIN
  EXEC tSQLt.Private_RunMethodHandler @RunMethod = 'tSQLt.Private_RunAll';
END;
GO

CREATE PROCEDURE tSQLt.RunNew
AS
BEGIN
  EXEC tSQLt.Private_RunMethodHandler @RunMethod = 'tSQLt.Private_RunNew';
END;
GO

CREATE PROCEDURE tSQLt.RunTest
   @TestName NVARCHAR(MAX)
AS
BEGIN
  RAISERROR('tSQLt.RunTest has been retired. Please use tSQLt.Run instead.', 16, 10);
END;
GO

CREATE PROCEDURE tSQLt.Run
   @TestName NVARCHAR(MAX) = NULL,
   @TestResultFormatter NVARCHAR(MAX) = NULL
AS
BEGIN
  EXEC tSQLt.Private_RunMethodHandler @RunMethod = 'tSQLt.Private_Run', @TestResultFormatter = @TestResultFormatter, @TestName = @TestName; 
END;
GO
CREATE PROCEDURE tSQLt.Private_InputBuffer
  @InputBuffer NVARCHAR(MAX) OUTPUT
AS
BEGIN
  CREATE TABLE #inputbuffer(EventType sysname, Parameters SMALLINT, EventInfo NVARCHAR(MAX));
  INSERT INTO #inputbuffer
  EXEC('DBCC INPUTBUFFER(@@SPID) WITH NO_INFOMSGS;');
  SELECT @InputBuffer = I.EventInfo FROM #inputbuffer AS I;
END;
GO
CREATE PROCEDURE tSQLt.RunC
AS
BEGIN
  DECLARE @TestName NVARCHAR(MAX);SET @TestName = NULL;
  DECLARE @InputBuffer NVARCHAR(MAX);
  EXEC tSQLt.Private_InputBuffer @InputBuffer = @InputBuffer OUT;
  IF(@InputBuffer LIKE 'EXEC tSQLt.RunC;--%')
  BEGIN
    SET @TestName = LTRIM(RTRIM(STUFF(@InputBuffer,1,18,'')));
  END;
  EXEC tSQLt.Run @TestName = @TestName;
END;
GO

CREATE PROCEDURE tSQLt.RunWithXmlResults
   @TestName NVARCHAR(MAX) = NULL
AS
BEGIN
  EXEC tSQLt.Run @TestName = @TestName, @TestResultFormatter = 'tSQLt.XmlResultFormatter';
END;
GO

CREATE PROCEDURE tSQLt.RunWithNullResults
    @TestName NVARCHAR(MAX) = NULL
AS
BEGIN
  EXEC tSQLt.Run @TestName = @TestName, @TestResultFormatter = 'tSQLt.NullTestResultFormatter';
END;
GO
CREATE FUNCTION tSQLt.Private_PrepareTestResultForOutput()
RETURNS TABLE
AS
RETURN
  SELECT ROW_NUMBER() OVER(ORDER BY Result DESC, Name ASC) No,Name [Test Case Name],
         RIGHT(SPACE(7)+CAST(DATEDIFF(MILLISECOND,TestStartTime,TestEndTime) AS VARCHAR(7)),7) AS [Dur(ms)], Result
    FROM tSQLt.TestResult;
GO
CREATE PROCEDURE tSQLt.DefaultResultFormatter
AS
BEGIN
    DECLARE @TestList NVARCHAR(MAX);
    DECLARE @Dashes NVARCHAR(MAX);
    DECLARE @CountSummaryMsg NVARCHAR(MAX);
    DECLARE @NewLine NVARCHAR(MAX);
    DECLARE @IsSuccess INT;
    DECLARE @SuccessCnt INT;
    DECLARE @Severity INT;
    DECLARE @SummaryError INT;
    
    SELECT *
      INTO #TestResultOutput
      FROM tSQLt.Private_PrepareTestResultForOutput() AS PTRFO;
    
    EXEC tSQLt.TableToText @TestList OUTPUT, '#TestResultOutput', 'No';

    SELECT @CountSummaryMsg = Msg, 
           @IsSuccess = 1 - SIGN(FailCnt + ErrorCnt),
           @SuccessCnt = SuccessCnt
      FROM tSQLt.TestCaseSummary();
      
    SELECT @SummaryError = CAST(PC.Value AS INT)
      FROM tSQLt.Private_Configurations AS PC
     WHERE PC.Name = 'SummaryError';

    SELECT @Severity = 16*(1-@IsSuccess);
    IF(@SummaryError = 0)
    BEGIN
      SET @Severity = 0;
    END;
    
    SELECT @Dashes = REPLICATE('-',LEN(@CountSummaryMsg)),
           @NewLine = CHAR(13)+CHAR(10);
    
    
    EXEC tSQLt.Private_Print @NewLine,0;
    EXEC tSQLt.Private_Print '+----------------------+',0;
    EXEC tSQLt.Private_Print '|Test Execution Summary|',0;
    EXEC tSQLt.Private_Print '+----------------------+',0;
    EXEC tSQLt.Private_Print @NewLine,0;
    EXEC tSQLt.Private_Print @TestList,0;
    EXEC tSQLt.Private_Print @Dashes,0;
    EXEC tSQLt.Private_Print @CountSummaryMsg, @Severity;
    EXEC tSQLt.Private_Print @Dashes,0;
END;
GO

CREATE PROCEDURE tSQLt.XmlResultFormatter
AS
BEGIN
    DECLARE @XmlOutput XML;

    SELECT @XmlOutput = (
      SELECT *--Tag, Parent, [testsuites!1!hide!hide], [testsuite!2!name], [testsuite!2!tests], [testsuite!2!errors], [testsuite!2!failures], [testsuite!2!timestamp], [testsuite!2!time], [testcase!3!classname], [testcase!3!name], [testcase!3!time], [failure!4!message]  
        FROM (
          SELECT 1 AS Tag,
                 NULL AS Parent,
                 'root' AS [testsuites!1!hide!hide],
                 NULL AS [testsuite!2!id],
                 NULL AS [testsuite!2!name],
                 NULL AS [testsuite!2!tests],
                 NULL AS [testsuite!2!errors],
                 NULL AS [testsuite!2!failures],
                 NULL AS [testsuite!2!skipped],
                 NULL AS [testsuite!2!timestamp],
                 NULL AS [testsuite!2!time],
                 NULL AS [testsuite!2!hostname],
                 NULL AS [testsuite!2!package],
                 NULL AS [properties!3!hide!hide],
                 NULL AS [testcase!4!classname],
                 NULL AS [testcase!4!name],
                 NULL AS [testcase!4!time],
                 NULL AS [failure!5!message],
                 NULL AS [failure!5!type],
                 NULL AS [error!6!message],
                 NULL AS [error!6!type],
                 NULL AS [skipped!7!message],
                 NULL AS [skipped!7!type],
                 NULL AS [system-out!8!hide],
                 NULL AS [system-err!9!hide]
          UNION ALL
          SELECT 2 AS Tag, 
                 1 AS Parent,
                 'root',
                 ROW_NUMBER()OVER(ORDER BY Class),
                 Class,
                 COUNT(1),
                 SUM(CASE Result WHEN 'Error' THEN 1 ELSE 0 END),
                 SUM(CASE Result WHEN 'Failure' THEN 1 ELSE 0 END),
                 SUM(CASE Result WHEN 'Skipped' THEN 1 ELSE 0 END),
                 CONVERT(VARCHAR(19),MIN(TestResult.TestStartTime),126),
                 CAST(CAST(DATEDIFF(MILLISECOND,MIN(TestResult.TestStartTime),MAX(TestResult.TestEndTime))/1000.0 AS NUMERIC(20,3))AS VARCHAR(MAX)),
                 CAST(SERVERPROPERTY('ServerName') AS NVARCHAR(MAX)),
                 'tSQLt',
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL
            FROM tSQLt.TestResult
          GROUP BY Class
          UNION ALL
          SELECT 3 AS Tag,
                 2 AS Parent,
                 'root',
                 NULL,
                 Class,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 Class,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL
            FROM tSQLt.TestResult
           GROUP BY Class
          UNION ALL
          SELECT 4 AS Tag,
                 2 AS Parent,
                 'root',
                 NULL,
                 Class,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 Class,
                 TestCase,
                 CAST(CAST(DATEDIFF(MILLISECOND,TestResult.TestStartTime,TestResult.TestEndTime)/1000.0 AS NUMERIC(20,3))AS VARCHAR(MAX)),
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL
            FROM tSQLt.TestResult
          UNION ALL
          SELECT 5 AS Tag,
                 4 AS Parent,
                 'root',
                 NULL,
                 Class,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 Class,
                 TestCase,
                 CAST(CAST(DATEDIFF(MILLISECOND,TestResult.TestStartTime,TestResult.TestEndTime)/1000.0 AS NUMERIC(20,3))AS VARCHAR(MAX)),
                 Msg,
                 'tSQLt.Fail',
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL
            FROM tSQLt.TestResult
           WHERE Result IN ('Failure')
          UNION ALL
          SELECT 6 AS Tag,
                 4 AS Parent,
                 'root',
                 NULL,
                 Class,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 Class,
                 TestCase,
                 CAST(CAST(DATEDIFF(MILLISECOND,TestResult.TestStartTime,TestResult.TestEndTime)/1000.0 AS NUMERIC(20,3))AS VARCHAR(MAX)),
                 NULL,
                 NULL,
                 Msg,
                 'SQL Error',
                 NULL,
                 NULL,
                 NULL,
                 NULL
            FROM tSQLt.TestResult
           WHERE Result IN ( 'Error')
          UNION ALL
          SELECT 7 AS Tag,
                 4 AS Parent,
                 'root',
                 NULL,
                 Class,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 Class,
                 TestCase,
                 CAST(CAST(DATEDIFF(MILLISECOND,TestResult.TestStartTime,TestResult.TestEndTime)/1000.0 AS NUMERIC(20,3))AS VARCHAR(MAX)),
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 Msg,
                 NULL,
                 NULL,
                 NULL
            FROM tSQLt.TestResult
           WHERE Result IN ( 'Skipped')
          UNION ALL
          SELECT 8 AS Tag,
                 2 AS Parent,
                 'root',
                 NULL,
                 Class,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 Class,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL
            FROM tSQLt.TestResult
           GROUP BY Class
          UNION ALL
          SELECT 9 AS Tag,
                 2 AS Parent,
                 'root',
                 NULL,
                 Class,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 Class,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL
            FROM tSQLt.TestResult
           GROUP BY Class
        ) AS X
       ORDER BY [testsuite!2!name],CASE WHEN Tag IN (8,9) THEN 1 ELSE 0 END, [testcase!4!name], Tag
       FOR XML EXPLICIT
       );

    EXEC tSQLt.Private_PrintXML @XmlOutput;
END;
GO

CREATE PROCEDURE tSQLt.NullTestResultFormatter
AS
BEGIN
  RETURN 0;
END;
GO

CREATE PROCEDURE tSQLt.RunTestClass
   @TestClassName NVARCHAR(MAX)
AS
BEGIN
    EXEC tSQLt.Run @TestClassName;
END
GO    
--Build-



      --SELECT 3 X, @SkipTestFlag SkipTestFlag, 
      --       @NoTransactionFlag NoTransactionFlag,
      --       @TransactionStartedFlag TransactionStartedFlag,
      --       @PreExecTrancount PreExecTrancount,
      --       @@TRANCOUNT Trancount,
      --       @TestName TestName,
      --       @Result Result,
      --       @Msg Msg;
