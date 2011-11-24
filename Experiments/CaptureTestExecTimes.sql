/*
   Copyright 2011 tSQLt

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/
GO
DROP TABLE tSQLt.TestResult;
GO
CREATE TABLE tSQLt.TestResult(
    Id INT IDENTITY(1,1) PRIMARY KEY CLUSTERED,
    Class NVARCHAR(MAX) NOT NULL,
    TestCase NVARCHAR(MAX) NOT NULL,
    Name AS (QUOTENAME(Class) + '.' + QUOTENAME(TestCase)),
    TranName NVARCHAR(MAX) NOT NULL,
    Result NVARCHAR(MAX) NULL,
    Msg NVARCHAR(MAX) NULL,
    TestStart DATETIME NOT NULL,
    TestEnd DATETIME NULL
);


DROP PROCEDURE tSQLt.Private_RunTest;
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

    IF EXISTS (SELECT 1 FROM sys.extended_properties WHERE name = N'SetFakeViewOnTrigger')
    BEGIN
      RAISERROR('Test system is in an invalid state. SetFakeViewOff must be called if SetFakeViewOn was called. Call SetFakeViewOff after creating all test case procedures.', 16, 10) WITH NOWAIT;
      RETURN -1;
    END;

    SELECT @Cmd = 'EXEC ' + @TestName;
    
    SELECT @TestClassName = OBJECT_SCHEMA_NAME(OBJECT_ID(@TestName)), --tSQLt.Private_GetCleanSchemaName('', @TestName),
           @TestProcName = tSQLt.Private_GetCleanObjectName(@TestName);
           
    INSERT INTO tSQLt.TestResult(Class, TestCase, TranName, Result, TestStart) 
        SELECT @TestClassName, @TestProcName, @TranName, 'A severe error happened during test execution. Test did not finish.', GETDATE()
        OPTION(MAXDOP 1);
    SELECT @TestResultId = SCOPE_IDENTITY();

    BEGIN TRAN;
    SAVE TRAN @TranName;

    SET @PreExecTrancount = @@TRANCOUNT;
    
    TRUNCATE TABLE tSQLt.TestMessage;

    BEGIN TRY
        IF (@SetUp IS NOT NULL) EXEC @SetUp;
        EXEC (@Cmd);
    END TRY
    BEGIN CATCH
        IF ERROR_MESSAGE() LIKE '%tSQLt.Failure%'
        BEGIN
            SELECT @Msg = Msg FROM tSQLt.TestMessage;
            SET @Result = 'Failure';
        END
        ELSE
        BEGIN
            SELECT @Msg = COALESCE(ERROR_MESSAGE(), '<ERROR_MESSAGE() is NULL>') + '{' + COALESCE(ERROR_PROCEDURE(), '<ERROR_PROCEDURE() is NULL>') + ',' + COALESCE(CAST(ERROR_LINE() AS NVARCHAR), '<ERROR_LINE() is NULL>') + '}';
            SET @Result = 'Error';
        END;
    END CATCH

    BEGIN TRY
        ROLLBACK TRAN @TranName;
    END TRY
    BEGIN CATCH
        SET @PreExecTrancount = @PreExecTrancount - @@TRANCOUNT;
        IF (@@TRANCOUNT > 0) ROLLBACK;
        BEGIN TRAN;
        IF(   @Result <> 'Success'
           OR @PreExecTrancount <> 0
          )
        BEGIN
          SELECT @Msg = COALESCE(@Msg, '<NULL>') + ' (There was also a ROLLBACK ERROR --> ' + COALESCE(ERROR_MESSAGE(), '<ERROR_MESSAGE() is NULL>') + '{' + COALESCE(ERROR_PROCEDURE(), '<ERROR_PROCEDURE() is NULL>') + ',' + COALESCE(CAST(ERROR_LINE() AS NVARCHAR), '<ERROR_LINE() is NULL>') + '})';
          SET @Result = 'Error';
        END
    END CATCH    

    If(@Result <> 'Success') 
    BEGIN
      SET @Msg2 = @TestName + ' failed: ' + @Msg;
      EXEC tSQLt.Private_Print @Message = @Msg2, @Severity = 0;
    END

    IF EXISTS(SELECT 1 FROM tSQLt.TestResult WHERE Id = @TestResultId)
    BEGIN
        UPDATE tSQLt.TestResult SET
            Result = @Result,
            Msg = @Msg,
            TestEnd = GETDATE()
         WHERE Id = @TestResultId;
    END
    ELSE
    BEGIN
        INSERT tSQLt.TestResult(Class, TestCase, TranName, Result, Msg, TestStart)
        SELECT @TestClassName, 
               @TestProcName,  
               '?', 
               'Error', 
               'TestResult entry is missing; Original outcome: ' + @Result + ', ' + @Msg,
               GETDATE();
    END    
      

    COMMIT;
END;
GO

DROP PROCEDURE tSQLt.DefaultResultFormatter;
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
    
    SELECT ROW_NUMBER() OVER(ORDER BY Result DESC, Name ASC) No,Name [Test Case Name], Result, DATEDIFF(MILLISECOND, TestStart, TestEnd) AS Duration
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
