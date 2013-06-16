IF OBJECT_ID('tSQLt.Private_GetSetupProcedureName') IS NOT NULL DROP PROCEDURE tSQLt.Private_GetSetupProcedureName;
IF OBJECT_ID('tSQLt.Private_CleanTestResult') IS NOT NULL DROP PROCEDURE tSQLt.Private_CleanTestResult;
IF OBJECT_ID('tSQLt.Private_RunTest') IS NOT NULL DROP PROCEDURE tSQLt.Private_RunTest;
IF OBJECT_ID('tSQLt.Private_RunTestClass') IS NOT NULL DROP PROCEDURE tSQLt.Private_RunTestClass;
IF OBJECT_ID('tSQLt.Private_Run') IS NOT NULL DROP PROCEDURE tSQLt.Private_Run;
IF OBJECT_ID('tSQLt.Private_RunAll') IS NOT NULL DROP PROCEDURE tSQLt.Private_RunAll;
IF OBJECT_ID('tSQLt.RunAll') IS NOT NULL DROP PROCEDURE tSQLt.RunAll;
IF OBJECT_ID('tSQLt.RunTest') IS NOT NULL DROP PROCEDURE tSQLt.RunTest;
IF OBJECT_ID('tSQLt.Run') IS NOT NULL DROP PROCEDURE tSQLt.Run;
IF OBJECT_ID('tSQLt.RunWithXmlResults') IS NOT NULL DROP PROCEDURE tSQLt.RunWithXmlResults;
IF OBJECT_ID('tSQLt.RunWithNullResults') IS NOT NULL DROP PROCEDURE tSQLt.RunWithNullResults;
IF OBJECT_ID('tSQLt.DefaultResultFormatter') IS NOT NULL DROP PROCEDURE tSQLt.DefaultResultFormatter;
IF OBJECT_ID('tSQLt.XmlResultFormatter') IS NOT NULL DROP PROCEDURE tSQLt.XmlResultFormatter;
IF OBJECT_ID('tSQLt.NullTestResultFormatter') IS NOT NULL DROP PROCEDURE tSQLt.NullTestResultFormatter;
IF OBJECT_ID('tSQLt.RunTestClass') IS NOT NULL DROP PROCEDURE tSQLt.RunTestClass;
GO
---Build+

CREATE PROCEDURE tSQLt.Private_GetSetupProcedureName
  @TestClassId INT = NULL,
  @SetupProcName NVARCHAR(MAX) OUTPUT
AS
BEGIN
    SELECT @SetupProcName = tSQLt.Private_GetQuotedFullName(object_id)
      FROM sys.procedures
     WHERE schema_id = @TestClassId
       AND LOWER(name) = 'setup';
END;
GO

CREATE PROCEDURE tSQLt.Private_CleanTestResult
AS
BEGIN
   DELETE FROM tSQLt.TestResult;
END;
GO

CREATE PROCEDURE tSQLt.Private_RunTest
   @TestName NVARCHAR(MAX),
   @SetUp NVARCHAR(MAX) = NULL
AS
BEGIN
    DECLARE @Msg NVARCHAR(MAX); SET @Msg = '';
    DECLARE @Msg2 NVARCHAR(MAX); SET @Msg2 = '';
    DECLARE @Cmd NVARCHAR(MAX); SET @Cmd = '';
    DECLARE @TestClassName NVARCHAR(MAX); SET @TestClassName = '';
    DECLARE @TestProcName NVARCHAR(MAX); SET @TestProcName = '';
    DECLARE @Result NVARCHAR(MAX); SET @Result = 'Success';
    DECLARE @TranName CHAR(32); EXEC tSQLt.GetNewTranName @TranName OUT;
    DECLARE @TestResultId INT;
    DECLARE @PreExecTrancount INT;
    
    TRUNCATE TABLE tSQLt.CaptureOutputLog;
    CREATE TABLE #ExpectException(ExpectedMessage NVARCHAR(MAX), ExpectedSeverity INT, ExpectedState INT);

    IF EXISTS (SELECT 1 FROM sys.extended_properties WHERE name = N'SetFakeViewOnTrigger')
    BEGIN
      RAISERROR('Test system is in an invalid state. SetFakeViewOff must be called if SetFakeViewOn was called. Call SetFakeViewOff after creating all test case procedures.', 16, 10) WITH NOWAIT;
      RETURN -1;
    END;

    SELECT @Cmd = 'EXEC ' + @TestName;
    
    SELECT @TestClassName = OBJECT_SCHEMA_NAME(OBJECT_ID(@TestName)), --tSQLt.Private_GetCleanSchemaName('', @TestName),
           @TestProcName = tSQLt.Private_GetCleanObjectName(@TestName);
           
    INSERT INTO tSQLt.TestResult(Class, TestCase, TranName, Result) 
        SELECT @TestClassName, @TestProcName, @TranName, 'A severe error happened during test execution. Test did not finish.'
        OPTION(MAXDOP 1);
    SELECT @TestResultId = SCOPE_IDENTITY();


    BEGIN TRAN;
    SAVE TRAN @TranName;

    SET @PreExecTrancount = @@TRANCOUNT;
    
    TRUNCATE TABLE tSQLt.TestMessage;

    BEGIN TRY
        IF (@SetUp IS NOT NULL) EXEC @SetUp;
        EXEC (@Cmd);
        IF(EXISTS(SELECT 1 FROM #ExpectException))
        BEGIN
          EXEC tSQLt.Fail 'Expected an error to be raised.';
        END
    END TRY
    BEGIN CATCH
        IF ERROR_MESSAGE() LIKE '%tSQLt.Failure%'
        BEGIN
            SELECT @Msg = Msg FROM tSQLt.TestMessage;
            SET @Result = 'Failure';
        END
        ELSE
        BEGIN
          IF(EXISTS(SELECT 1 FROM #ExpectException))
          BEGIN
            DECLARE @ExpectedMessage NVARCHAR(MAX);
            DECLARE @ExpectedSeverity INT;
            DECLARE @ExpectedState INT;
            SELECT @ExpectedMessage = ExpectedMessage, 
                   @ExpectedSeverity = ExpectedSeverity,
                   @ExpectedState = ExpectedState 
              FROM #ExpectException;
            SET @Result = 'Success';
            DECLARE @TmpMsg NVARCHAR(MAX);
            SET @TmpMsg = 'Exception did not match expectation!';
            IF(ERROR_MESSAGE() NOT LIKE @ExpectedMessage)
            BEGIN
              SET @TmpMsg = @TmpMsg +CHAR(13)+CHAR(10)+
                         'Expected Message: <'+@ExpectedMessage+'>'+CHAR(13)+CHAR(10)+
                         'Actual Message  : <'+ERROR_MESSAGE()+'>';
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
            SELECT @Msg = COALESCE(ERROR_MESSAGE(), '<ERROR_MESSAGE() is NULL>') + '{' + COALESCE(ERROR_PROCEDURE(), '<ERROR_PROCEDURE() is NULL>') + ',' + COALESCE(CAST(ERROR_LINE() AS NVARCHAR), '<ERROR_LINE() is NULL>') + '}';
            SET @Result = 'Error';
          END  
        END;
    END CATCH

    BEGIN TRY
        ROLLBACK TRAN @TranName;
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
        END
    END CATCH    

    If(@Result <> 'Success') 
    BEGIN
      SET @Msg2 = @TestName + ' failed: (' + @Result + ') ' + @Msg;
      EXEC tSQLt.Private_Print @Message = @Msg2, @Severity = 0;
    END

    IF EXISTS(SELECT 1 FROM tSQLt.TestResult WHERE Id = @TestResultId)
    BEGIN
        UPDATE tSQLt.TestResult SET
            Result = @Result,
            Msg = @Msg
         WHERE Id = @TestResultId;
    END
    ELSE
    BEGIN
        INSERT tSQLt.TestResult(Class, TestCase, TranName, Result, Msg)
        SELECT @TestClassName, 
               @TestProcName,  
               '?', 
               'Error', 
               'TestResult entry is missing; Original outcome: ' + @Result + ', ' + @Msg;
    END    
      

    COMMIT;
END;
GO

CREATE PROCEDURE tSQLt.Private_RunTestClass
  @TestClassName NVARCHAR(MAX)
AS
BEGIN
    DECLARE @TestCaseName NVARCHAR(MAX);
    DECLARE @TestClassId INT; SET @TestClassId = tSQLt.Private_GetSchemaId(@TestClassName);
    DECLARE @SetupProcName NVARCHAR(MAX);
    EXEC tSQLt.Private_GetSetupProcedureName @TestClassId, @SetupProcName OUTPUT;
    
    DECLARE testCases CURSOR LOCAL FAST_FORWARD 
        FOR
     SELECT tSQLt.Private_GetQuotedFullName(object_id)
       FROM sys.procedures
      WHERE schema_id = @TestClassId
        AND LOWER(name) LIKE 'test%';

    OPEN testCases;
    
    FETCH NEXT FROM testCases INTO @TestCaseName;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC tSQLt.Private_RunTest @TestCaseName, @SetupProcName;

        FETCH NEXT FROM testCases INTO @TestCaseName;
    END;

    CLOSE testCases;
    DEALLOCATE testCases;
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
    
    SELECT @TestName = tSQLt.Private_GetLastTestNameIfNotProvided(@TestName);
    EXEC tSQLt.Private_SaveTestNameForSession @TestName;
    
    SELECT @TestClassId = schemaId,
           @FullName = quotedFullName,
           @IsTestClass = isTestClass,
           @IsSchema = isSchema,
           @IsTestCase = isTestCase
      FROM tSQLt.Private_ResolveName(@TestName);
     
    EXEC tSQLt.Private_CleanTestResult;

    IF @IsSchema = 1
    BEGIN
        EXEC tSQLt.Private_RunTestClass @FullName;
    END
    
    IF @IsTestCase = 1
    BEGIN
      DECLARE @SetupProcName NVARCHAR(MAX);
      EXEC tSQLt.Private_GetSetupProcedureName @TestClassId, @SetupProcName OUTPUT;

      EXEC tSQLt.Private_RunTest @FullName, @SetupProcName;
    END;

    EXEC tSQLt.Private_OutputTestResults @TestResultFormatter;
END;
GO

CREATE PROCEDURE tSQLt.Private_RunAll
  @TestResultFormatter NVARCHAR(MAX)
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @TestClassName NVARCHAR(MAX);
  DECLARE @TestProcName NVARCHAR(MAX);

  EXEC tSQLt.Private_CleanTestResult;

  DECLARE tests CURSOR LOCAL FAST_FORWARD FOR
   SELECT Name
     FROM tSQLt.TestClasses;

  OPEN tests;
  
  FETCH NEXT FROM tests INTO @TestClassName;
  WHILE @@FETCH_STATUS = 0
  BEGIN
    EXEC tSQLt.Private_RunTestClass @TestClassName;
    
    FETCH NEXT FROM tests INTO @TestClassName;
  END;
  
  CLOSE tests;
  DEALLOCATE tests;
  
  EXEC tSQLt.Private_OutputTestResults @TestResultFormatter;
END;
GO

--------------------------------------------------------------------------------

CREATE PROCEDURE tSQLt.RunAll
AS
BEGIN
  DECLARE @TestResultFormatter NVARCHAR(MAX);
  SELECT @TestResultFormatter = tSQLt.GetTestResultFormatter();
  
  EXEC tSQLt.Private_RunAll @TestResultFormatter;
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
   @TestName NVARCHAR(MAX) = NULL
AS
BEGIN
  DECLARE @TestResultFormatter NVARCHAR(MAX);
  SELECT @TestResultFormatter = tSQLt.GetTestResultFormatter();
  
  EXEC tSQLt.Private_Run @TestName, @TestResultFormatter;
END;
GO

CREATE PROCEDURE tSQLt.RunWithXmlResults
   @TestName NVARCHAR(MAX) = NULL
AS
BEGIN
  EXEC tSQLt.Private_Run @TestName, 'tSQLt.XmlResultFormatter';
END;
GO

CREATE PROCEDURE tSQLt.RunWithNullResults
    @TestName NVARCHAR(MAX) = NULL
AS
BEGIN
  EXEC tSQLt.Private_Run @TestName, 'tSQLt.NullTestResultFormatter';
END;
GO

CREATE PROCEDURE tSQLt.DefaultResultFormatter
AS
BEGIN
    DECLARE @Msg1 NVARCHAR(MAX);
    DECLARE @Msg2 NVARCHAR(MAX);
    DECLARE @Msg3 NVARCHAR(MAX);
    DECLARE @Msg4 NVARCHAR(MAX);
    DECLARE @IsSuccess INT;
    DECLARE @SuccessCnt INT;
    DECLARE @Severity INT;
    
    SELECT ROW_NUMBER() OVER(ORDER BY Result DESC, Name ASC) No,Name [Test Case Name], Result
      INTO #Tmp
      FROM tSQLt.TestResult;
    
    EXEC tSQLt.TableToText @Msg1 OUTPUT, '#Tmp', 'No';

    SELECT @Msg3 = Msg, 
           @IsSuccess = 1 - SIGN(FailCnt + ErrorCnt),
           @SuccessCnt = SuccessCnt
      FROM tSQLt.TestCaseSummary();
      
    SELECT @Severity = 16*(1-@IsSuccess);
    
    SELECT @Msg2 = REPLICATE('-',LEN(@Msg3)),
           @Msg4 = CHAR(13)+CHAR(10);
    
    
    EXEC tSQLt.Private_Print @Msg4,0;
    EXEC tSQLt.Private_Print '+----------------------+',0;
    EXEC tSQLt.Private_Print '|Test Execution Summary|',0;
    EXEC tSQLt.Private_Print '+----------------------+',0;
    EXEC tSQLt.Private_Print @Msg4,0;
    EXEC tSQLt.Private_Print @Msg1,0;
    EXEC tSQLt.Private_Print @Msg2,0;
    EXEC tSQLt.Private_Print @Msg3, @Severity;
    EXEC tSQLt.Private_Print @Msg2,0;
END;
GO

CREATE PROCEDURE tSQLt.XmlResultFormatter
AS
BEGIN
    DECLARE @XmlOutput XML;

    SELECT @XmlOutput = (
      SELECT Tag, Parent, [testsuites!1!hide!hide], [testsuite!2!name], [testsuite!2!tests], [testsuite!2!errors], [testsuite!2!failures], [testcase!3!classname], [testcase!3!name], [failure!4!message]  FROM (
        SELECT 1 AS Tag,
               NULL AS Parent,
               'root' AS [testsuites!1!hide!hide],
               NULL AS [testsuite!2!name],
               NULL AS [testsuite!2!tests],
               NULL AS [testsuite!2!errors],
               NULL AS [testsuite!2!failures],
               NULL AS [testcase!3!classname],
               NULL AS [testcase!3!name],
               NULL AS [failure!4!message]
        UNION ALL
        SELECT 2 AS Tag, 
               1 AS Parent,
               'root',
               Class AS [testsuite!2!name],
               COUNT(1) AS [testsuite!2!tests],
               SUM(CASE Result WHEN 'Error' THEN 1 ELSE 0 END) AS [testsuite!2!errors],
               SUM(CASE Result WHEN 'Failure' THEN 1 ELSE 0 END) AS [testsuite!2!failures],
               NULL AS [testcase!3!classname],
               NULL AS [testcase!3!name],
               NULL AS [failure!4!message]
          FROM tSQLt.TestResult
        GROUP BY Class
        UNION ALL
        SELECT 3 AS Tag,
               2 AS Parent,
               'root',
               Class,
               NULL,
               NULL,
               NULL,
               Class,
               TestCase,
               NULL
          FROM tSQLt.TestResult
        UNION ALL
        SELECT 4 AS Tag,
               3 AS Parent,
               'root',
               Class,
               NULL,
               NULL,
               NULL,
               Class,
               TestCase,
               Msg
          FROM tSQLt.TestResult
         WHERE Result IN ('Failure', 'Error')) AS X
       ORDER BY [testsuite!2!name], [testcase!3!name], Tag
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
