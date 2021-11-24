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
DECLARE @Msg VARCHAR(MAX);SELECT @Msg = 'Compiled at '+CONVERT(VARCHAR,GETDATE(),121);RAISERROR(@Msg,0,1);
GO
IF OBJECT_ID('tSQLt_testutil.Private_Drop_tSQLtTestUtilCLR_objects') IS NOT NULL EXEC('EXEC tSQLt_testutil.Private_Drop_tSQLtTestUtilCLR_objects');
GO
EXEC tSQLt.DropClass tSQLt_testutil;
GO

CREATE SCHEMA tSQLt_testutil;
GO
CREATE PROC tSQLt_testutil.ReThrow @msg NVARCHAR(MAX) = '' AS SET @msg = @msg + '[Msg '+LTRIM(STR(ERROR_NUMBER()))+', Level '+LTRIM(STR(ERROR_SEVERITY()))+', State '+LTRIM(STR(ERROR_STATE()))+ISNULL(', Procedure '+ERROR_PROCEDURE(),'')+', Line '+LTRIM(STR(ERROR_LINE()))+']'+ERROR_MESSAGE();RAISERROR(@msg,16,10);
GO
CREATE PROC tSQLt_testutil.assertFailCalled
    @Command NVARCHAR(MAX),
    @Message VARCHAR(MAX) = NULL
AS
BEGIN
    IF(@Message IS NULL)
    BEGIN
      SET @Message = 'Fail not called when executing <' + @Command + '>';
    END
    DECLARE @CallCount INT;
    DECLARE @Error NVARCHAR(MAX);SET @Error = '';
    BEGIN TRAN;
    DECLARE @TranName CHAR(32); EXEC tSQLt.GetNewTranName @TranName OUT;
    SAVE TRAN @TranName;
      EXEC tSQLt.SpyProcedure 'tSQLt.Fail','RAISERROR(''tSQLt_testutil.assertFailCalled.INTERNAL'',16,10);';
      BEGIN TRY
        EXEC (@Command);
      END TRY
      BEGIN CATCH
        IF(ERROR_MESSAGE() NOT LIKE '%tSQLt_testutil.assertFailCalled.INTERNAL%')
        BEGIN
          ROLLBACK TRAN @TranName;
          COMMIT;
          EXEC tSQLt_testutil.ReThrow;
        END
      END CATCH;
      SELECT @CallCount = COUNT(1) FROM tSQLt.Fail_SpyProcedureLog;
    ROLLBACK TRAN @TranName;
    COMMIT TRAN;

    IF (@CallCount = 0)
    BEGIN
      EXEC tSQLt.Fail @Message,@Error;
    END;
END;
GO

CREATE PROCEDURE tSQLt_testutil.CaptureFailMessage
  @Command NVARCHAR(MAX),
  @FailMessage NVARCHAR(MAX) OUTPUT
AS
BEGIN
  BEGIN TRAN;
  DECLARE @TranName CHAR(32); EXEC tSQLt.GetNewTranName @TranName OUT;
  SAVE TRAN @TranName;
    EXEC tSQLt.SpyProcedure 'tSQLt.Fail','RAISERROR(''tSQLt_testutil.assertFailCalled.INTERNAL'',16,10);';
    BEGIN TRY
      EXEC (@Command);
    END TRY
    BEGIN CATCH
        IF(ERROR_MESSAGE() NOT LIKE '%tSQLt_testutil.assertFailCalled.INTERNAL%')
      BEGIN
        ROLLBACK TRAN @TranName;
        COMMIT;
        EXEC tSQLt_testutil.ReThrow;
      END
    END CATCH;
    SELECT @FailMessage = 
        COALESCE(Message0, '')--should be '!NULL!' but default parameters are not currently supported by SpyProcedure
      + COALESCE(Message1, '')
      + COALESCE(Message2, '')
      + COALESCE(Message3, '')
      + COALESCE(Message4, '')
      + COALESCE(Message5, '')
      + COALESCE(Message6, '')
      + COALESCE(Message7, '')
      + COALESCE(Message8, '')
      + COALESCE(Message9, '') FROM tSQLt.Fail_SpyProcedureLog;
  ROLLBACK TRAN @TranName;
  COMMIT TRAN;
END
GO

CREATE PROC tSQLt_testutil.AssertFailMessageEquals
    @Command NVARCHAR(MAX),
    @ExpectedMessage NVARCHAR(MAX),
    @Message0 VARCHAR(MAX) = NULL,
    @Message1 VARCHAR(MAX) = NULL,
    @Message2 VARCHAR(MAX) = NULL,
    @Message3 VARCHAR(MAX) = NULL,
    @Message4 VARCHAR(MAX) = NULL
AS
BEGIN
    DECLARE @Message VARCHAR(MAX);
    SELECT  @Message = 
        COALESCE(@Message0, '')
      + COALESCE(@Message1, '')
      + COALESCE(@Message2, '')
      + COALESCE(@Message3, '')
      + COALESCE(@Message4, '');

    DECLARE @ActualMessage NVARCHAR(MAX);

    EXEC tSQLt_testutil.CaptureFailMessage 
            @Command ,
            @ActualMessage OUTPUT;

    EXEC tSQLt.AssertEqualsString @ExpectedMessage, @ActualMessage, @Message;
END;
GO

CREATE PROC tSQLt_testutil.AssertFailMessageLike
    @Command NVARCHAR(MAX),
    @ExpectedMessage NVARCHAR(MAX),
    @Message0 VARCHAR(MAX) = NULL,
    @Message1 VARCHAR(MAX) = NULL,
    @Message2 VARCHAR(MAX) = NULL,
    @Message3 VARCHAR(MAX) = NULL,
    @Message4 VARCHAR(MAX) = NULL
AS
BEGIN
    DECLARE @Message VARCHAR(MAX);
    SELECT  @Message = 
        COALESCE(@Message0, '')
      + COALESCE(@Message1, '')
      + COALESCE(@Message2, '')
      + COALESCE(@Message3, '')
      + COALESCE(@Message4, '');

    DECLARE @ActualMessage NVARCHAR(MAX);

    EXEC tSQLt_testutil.CaptureFailMessage 
            @Command ,
            @ActualMessage OUTPUT;

    EXEC tSQLt.AssertLike @ExpectedMessage, @ActualMessage, @Message;
END;
GO

CREATE PROC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses
AS
BEGIN
  DECLARE @TestClassName NVARCHAR(MAX);
  DECLARE @TestProcName NVARCHAR(MAX);

  DECLARE testsWithExtendedProperty CURSOR LOCAL FAST_FORWARD FOR
   SELECT DISTINCT s.name AS testClassName
     FROM sys.extended_properties ep
     JOIN sys.schemas s
       ON ep.major_id = s.schema_id
    WHERE ep.name = N'tSQLt.TestClass';

  OPEN testsWithExtendedProperty;
  
  FETCH NEXT FROM testsWithExtendedProperty INTO @TestClassName;
  WHILE @@FETCH_STATUS = 0
  BEGIN
    EXEC sp_dropextendedproperty @name = 'tSQLt.TestClass',
                                 @level0type = 'SCHEMA',
                                 @level0name = @TestClassName;
    
    FETCH NEXT FROM testsWithExtendedProperty INTO @TestClassName;
  END;
  
  CLOSE testsWithExtendedProperty;
  DEALLOCATE testsWithExtendedProperty;

  DECLARE testsWithSchemaClassification CURSOR LOCAL FAST_FORWARD FOR
   SELECT DISTINCT s.name AS testClassName
     FROM sys.schemas s
    WHERE s.principal_id = USER_ID('tSQLt.TestClass');

  OPEN testsWithSchemaClassification;
  
  FETCH NEXT FROM testsWithSchemaClassification INTO @TestClassName;
  WHILE @@FETCH_STATUS = 0
  BEGIN
    DECLARE @cmd NVARCHAR(MAX) = 'ALTER AUTHORIZATION ON SCHEMA::'+QUOTENAME(@TestClassName)+' TO dbo;';
    EXEC(@cmd);
    FETCH NEXT FROM testsWithSchemaClassification INTO @TestClassName;
  END;
  
  CLOSE testsWithSchemaClassification;
  DEALLOCATE testsWithSchemaClassification;
END;
GO

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

CREATE PROCEDURE tSQLt_testutil.CaptureTestResult
  @TestName NVARCHAR(MAX),
  @Result NVARCHAR(MAX) OUTPUT,   
  @Msg NVARCHAR(MAX) OUTPUT    
AS
BEGIN
  DECLARE @Cmd NVARCHAR(MAX);    
  SELECT @Cmd = 'EXEC tSQLt.Private_RunTest '+
                QUOTENAME(
                   QUOTENAME(OBJECT_SCHEMA_NAME(OBJECT_ID(@TestName)))+'.'+
                   QUOTENAME(OBJECT_NAME(OBJECT_ID(@TestName))),'''')+';';
  BEGIN TRAN;
  DECLARE @TranName CHAR(32); EXEC tSQLt.GetNewTranName @TranName OUT;
  SAVE TRAN @TranName;
    TRUNCATE TABLE tSQLt.TestResult;
    EXEC tSQLt.SuppressOutput @Cmd
    SELECT @Result = Result, @Msg = Msg FROM tSQLt.TestResult;
  ROLLBACK TRAN @TranName;
  COMMIT TRAN;
END;
GO
CREATE PROCEDURE tSQLt_testutil.AssertTestFails
  @TestName NVARCHAR(MAX),
  @ExpectedMessage NVARCHAR(MAX) = NULL
AS
BEGIN
    DECLARE @Result NVARCHAR(MAX);
    DECLARE @Msg NVARCHAR(MAX);
    
    EXEC tSQLt_testutil.CaptureTestResult @TestName, @Result OUTPUT, @Msg OUTPUT;
    
    IF(@Result <> 'Failure')
    BEGIN
      EXEC tSQLt.Fail 'Expected test to fail. Instead it resulted in ',@Result,'. The Message is: "',@Msg,'"';
    END
    
    IF(@ExpectedMessage IS NOT NULL)
    BEGIN
      EXEC tSQLt.AssertLike @ExpectedMessage,@Msg,'Incorrect Fail message used:';
    END
END;
GO
CREATE PROCEDURE tSQLt_testutil.AssertTestSucceeds
  @TestName NVARCHAR(MAX)
AS
BEGIN
    DECLARE @Result NVARCHAR(MAX);
    DECLARE @Msg NVARCHAR(MAX);
    
    EXEC tSQLt_testutil.CaptureTestResult @TestName, @Result OUTPUT, @Msg OUTPUT;
    
    IF(@Result <> 'Success')
    BEGIN
      EXEC tSQLt.Fail 'Expected test to succeed. Instead it resulted in ',@Result,'. The Message is: "',@Msg,'"';
    END
END;
GO
CREATE PROCEDURE tSQLt_testutil.AssertTestErrors
  @TestName NVARCHAR(MAX),
  @ExpectedMessage NVARCHAR(MAX) = NULL
AS
BEGIN
    DECLARE @Result NVARCHAR(MAX);
    DECLARE @Msg NVARCHAR(MAX);
    
    EXEC tSQLt_testutil.CaptureTestResult @TestName, @Result OUTPUT, @Msg OUTPUT;
    
    IF(@Result <> 'Error')
    BEGIN
      EXEC tSQLt.Fail 'Expected test to error. Instead it resulted in ',@Result,'. The Message is: "',@Msg,'"';
    END
    
    IF(@ExpectedMessage IS NOT NULL)
    BEGIN
      EXEC tSQLt.AssertLike @ExpectedMessage,@Msg,'Incorrect Error Message:';
    END
END;
GO
CREATE PROCEDURE tSQLt_testutil.AssertTestSkipped
  @TestName NVARCHAR(MAX),
  @ExpectedMessage NVARCHAR(MAX) = NULL
AS
BEGIN
    DECLARE @Result NVARCHAR(MAX);
    DECLARE @Msg NVARCHAR(MAX);
    
    EXEC tSQLt_testutil.CaptureTestResult @TestName, @Result OUTPUT, @Msg OUTPUT;
    
    IF(@Result <> 'Skipped')
    BEGIN
      EXEC tSQLt.Fail 'Expected test to be skipped. Instead it resulted in ',@Result,'. The Message is: "',@Msg,'"';
    END
    
    IF(@ExpectedMessage IS NOT NULL)
    BEGIN
      EXEC tSQLt.AssertLike @ExpectedMessage,@Msg,'Incorrect Skip Message:';
    END
END;
GO
CREATE PROCEDURE tSQLt_testutil.LogMultiRunResult
  @TestCaseSet NVARCHAR(MAX)
AS
BEGIN
  SELECT 
      SUM(CASE WHEN Result = 'Success' THEN 1 ELSE 0 END) Success,
      SUM(CASE WHEN Result = 'Skipped' THEN 1 ELSE 0 END) Skipped,
      SUM(CASE WHEN Result = 'Failure' THEN 1 ELSE 0 END) Failure,
      SUM(CASE WHEN Result = 'Error' THEN 1 ELSE 0 END) [Error],
      @TestCaseSet TestCaseSet
    INTO #MRL
    FROM tSQLt.TestResult;
  SELECT * FROM #MRL AS M;
  INSERT INTO tSQLt_testutil.MultiRunLog(Success,Skipped,Failure,Error,TestCaseSet)
  SELECT * FROM #MRL AS M;
END;
GO
CREATE PROCEDURE tSQLt_testutil.CheckMultiRunResults
  @noError INT = 0
AS
BEGIN
  SELECT * FROM tSQLt_testutil.MultiRunLog AS MRL;
  DECLARE @Severity INT = CASE WHEN @noError <> 0 THEN 0 ELSE 16 END;
  IF(EXISTS(SELECT * FROM tSQLt_testutil.MultiRunLog AS MRL WHERE MRL.Failure<>0 OR MRL.Error<>0))
  BEGIN
    EXEC tSQLt.Private_Print @Message = 'tSQLt execution with failures or errors detected.', @Severity = @Severity
  END;
  IF(NOT EXISTS(SELECT * FROM tSQLt_testutil.MultiRunLog AS MRL))
  BEGIN
    EXEC tSQLt.Private_Print @Message = 'MultiRunLog is empty.', @Severity = @Severity
  END;
  IF(EXISTS(SELECT * FROM tSQLt_testutil.MultiRunLog AS MRL WHERE MRL.Success = 0 AND MRL.Skipped = 0))
  BEGIN
    EXEC tSQLt.Private_Print @Message = 'MultiRunLog contains Run without tests.', @Severity = @Severity
  END;
END;
GO
CREATE FUNCTION tSQLt_testutil.GenerateRandomPassword(@R UNIQUEIDENTIFIER)
RETURNS TABLE
AS
RETURN
SELECT CAST(@R AS NVARCHAR(MAX))+'[P0l1cyRe7u1r3mnt$]' PW;
GO
CREATE PROCEDURE tSQLt_testutil.AssertTableContainsString
  @Table NVARCHAR(MAX),
  @Column NVARCHAR(MAX),
  @Pattern NVARCHAR(MAX)
AS
BEGIN
 CREATE TABLE #TheRowExists(Yes INT);
 DECLARE @cmd NVARCHAR(MAX) =  N'INSERT INTO #TheRowExists SELECT 1 FROM '+@Table+' WHERE '+@Column+' LIKE @Pattern';
 EXEC sp_executesql @cmd,N'@Pattern NVARCHAR(MAX)',@Pattern;

 IF NOT EXISTS(SELECT 1 FROM #TheRowExists)
 BEGIN
   DECLARE @Msg NVARCHAR(MAX) = 'Expected to find '+@Pattern+' in '+@Table+' but didn''t.';
   EXEC tSQLt.AssertEmptyTable -- roundabout way to get the table content printed
     @TableName = @Table, 
     @Message = @Msg;
   EXEC tSQLt.Fail 'Expected to find ',@Pattern,' in ',@Table,' but didn''t. Table was empty.';
 END;
END;
GO
CREATE PROCEDURE tSQLt_testutil.WaitForMS
  @milliseconds INT
AS
BEGIN
  --WAITFOR DELAY might return significantly earlier than one would expect. Hence this workaround...
  DECLARE @EndTime DATETIME2 = DATEADD(MILLISECOND,@milliseconds,SYSDATETIME());
  WHILE(SYSDATETIME()<@EndTime)
  BEGIN
    WAITFOR DELAY '00:00:00.010';
  END;
END;
GO
CREATE PROCEDURE tSQLt_testutil.PrepMultiRunLogTable
AS
BEGIN
  IF OBJECT_ID('tSQLt_testutil.MultiRunLog') IS NOT NULL DROP TABLE tSQLt_testutil.MultiRunLog;
  CREATE TABLE tSQLt_testutil.MultiRunLog
  (
    id INT IDENTITY(1,1) PRIMARY KEY CLUSTERED,
    Success INT,
    Skipped INT,
    Failure INT,
    [Error] INT,
    TestCaseSet NVARCHAR(MAX)
  );
END;
GO
/*CreateBuildLogStart*/
GO
CREATE PROCEDURE tSQLt_testutil.CreateBuildLog
  @TableName NVARCHAR(MAX)
AS
BEGIN
  IF(OBJECT_ID(@TableName) IS NOT NULL)EXEC('DROP TABLE '+@TableName);
  DECLARE @cmd NVARCHAR(MAX) = 
  '
  CREATE TABLE '+@TableName+'
  (
    [id] [int] NOT NULL IDENTITY(1, 1) PRIMARY KEY CLUSTERED,
    [Success] [int] NULL,
    [Skipped] [int] NULL,
    [Failure] [int] NULL,
    [Error] [int] NULL,
    [TestCaseSet] NVARCHAR(MAX) NULL,
    [RunGroup] NVARCHAR(MAX) NULL,
    [DatabaseName] NVARCHAR(MAX) NULL,
    [Version] VARCHAR(14) NULL,
    [ClrVersion] NVARCHAR(4000) NULL,
    [ClrSigningKey] VARBINARY(8000) NULL,
    [InstalledOnSqlVersion] NUMERIC(10, 2) NULL,
    [SqlVersion] NUMERIC(10, 2) NULL,
    [SqlBuild] NUMERIC(10, 2) NULL,
    [SqlEdition] NVARCHAR(128) NULL,
    [HostPlatform] NVARCHAR(256) NULL
  );
  ';
  EXEC(@cmd);
  SET @cmd = 'GRANT INSERT ON '+@TableName+' TO PUBLIC;';
  IF(PARSENAME(@TableName,3) IS NOT NULL)
  BEGIN
    SET @cmd = PARSENAME(@TableName,3)+'.sys.sp_executesql N'''+@cmd+''',N''''';
  END;
  EXEC(@cmd);
END;
GO
/*CreateBuildLogEnd*/
GO
CREATE PROCEDURE tSQLt_testutil.StoreBuildLog
  @TableName NVARCHAR(MAX),
  @RunGroup NVARCHAR(MAX)
AS
BEGIN 
  DECLARE @cmd NVARCHAR(MAX) = 
   (SELECT QUOTENAME(C.name)+','
      FROM sys.columns AS C
     WHERE C.object_id = OBJECT_ID('tSQLt_testutil.MultiRunLog')
       AND C.is_identity = 0
     ORDER BY C.column_id
       FOR XML PATH,TYPE).value('.','NVARCHAR(MAX)');
  SET @cmd = 'INSERT INTO '+@TableName+' SELECT '+@cmd+'RG,DB,I.* FROM tSQLt_testutil.MultiRunLog CROSS JOIN tSQLt.Info() I RIGHT JOIN (VALUES('''+@RunGroup+''',DB_NAME()))XX(RG,DB) ON 1=1;'

  EXEC(@cmd);
END;
GO
CREATE PROCEDURE tSQLt_testutil.CheckBuildLog
  @TableName NVARCHAR(MAX)
AS
BEGIN
  IF OBJECT_ID('tSQLt_testutil.LocalBuildLogTemp') IS NOT NULL DROP TABLE tSQLt_testutil.LocalBuildLogTemp;
  EXEC('SELECT * INTO tSQLt_testutil.LocalBuildLogTemp FROM '+@TableName+';');

  IF OBJECT_ID('tSQLt_testutil.LocalBuildLogTempFormatted') IS NOT NULL DROP TABLE tSQLt_testutil.LocalBuildLogTempFormatted;
  DECLARE @cmd NVARCHAR(MAX) =
  (
    SELECT 'SELECT '+
               'CAST(REPLICATE('' '','+CAST(MAX(idML) AS NVARCHAR(MAX))+'-LEN(id))+CAST(id AS VARCHAR(MAX)) AS CHAR('+CAST(MAX(idML)+1 AS NVARCHAR(MAX))+'))id,'+
               'CAST(REPLICATE('' '','+CAST(MAX(SuccessML) AS NVARCHAR(MAX))+'-LEN(Success))+CAST(Success AS VARCHAR(MAX)) AS CHAR('+CAST(MAX(SuccessML)+1 AS NVARCHAR(MAX))+'))Success,'+
               'CAST(REPLICATE('' '','+CAST(MAX(SkippedML) AS NVARCHAR(MAX))+'-LEN(Skipped))+CAST(Skipped AS VARCHAR(MAX)) AS CHAR('+CAST(MAX(SkippedML)+1 AS NVARCHAR(MAX))+'))Skipped,'+
               'CAST(REPLICATE('' '','+CAST(MAX(FailureML) AS NVARCHAR(MAX))+'-LEN(Failure))+CAST(Failure AS VARCHAR(MAX)) AS CHAR('+CAST(MAX(FailureML)+1 AS NVARCHAR(MAX))+'))Failure,'+
               'CAST(REPLICATE('' '','+CAST(MAX(ErrorML) AS NVARCHAR(MAX))+'-LEN(Error))+CAST(Error AS VARCHAR(MAX)) AS CHAR('+CAST(MAX(ErrorML)+1 AS NVARCHAR(MAX))+'))Error,'+
               'CAST(TestCaseSet AS CHAR('+CAST(MAX(TestCaseSetML) AS NVARCHAR(MAX))+'))TestCaseSet,'+
               'CAST(RunGroup AS CHAR('+CAST(MAX(RunGroupML) AS NVARCHAR(MAX))+'))RunGroup,'+
               'CAST(DatabaseName AS CHAR('+CAST(MAX(DatabaseNameML) AS NVARCHAR(MAX))+'))DatabaseName, '+
               'CAST([Version] AS CHAR('+CAST(MAX(VersionML) AS NVARCHAR(MAX))+'))[Version], '+
               'CAST([ClrVersion] AS CHAR('+CAST(MAX(ClrVersionML) AS NVARCHAR(MAX))+'))[ClrVersion], '+
               'CONVERT(CHAR('+CAST(MAX(ClrSigningKeyML) AS NVARCHAR(MAX))+'),[ClrSigningKey],1)[ClrSigningKey], '+
               'CAST([InstalledOnSqlVersion] AS CHAR('+CAST(MAX(InstalledOnSqlVersionML) AS NVARCHAR(MAX))+'))[InstalledOnSqlVersion], '+
               'CAST([SqlVersion] AS CHAR('+CAST(MAX(SqlVersionML) AS NVARCHAR(MAX))+'))[SqlVersion], '+
               'CAST([SqlBuild] AS CHAR('+CAST(MAX(SqlBuildML) AS NVARCHAR(MAX))+'))[SqlBuild], '+
               'CAST([SqlEdition] AS CHAR('+CAST(MAX(SqlEditionML) AS NVARCHAR(MAX))+'))[SqlEdition], '+
               'CAST([HostPlatform] AS CHAR('+CAST(MAX(HostPlatformML) AS NVARCHAR(MAX))+'))[HostPlatform] '+
             'INTO tSQLt_testutil.LocalBuildLogTempFormatted FROM tSQLt_testutil.LocalBuildLogTemp'
      FROM 
      (
        SELECT 
            MAX(LEN(CAST(id AS VARCHAR(MAX)))) idML,
            MAX(LEN(CAST(Success AS VARCHAR(MAX)))) SuccessML,
            MAX(LEN(CAST(Skipped AS VARCHAR(MAX)))) SkippedML,
            MAX(LEN(CAST(Failure AS VARCHAR(MAX)))) FailureML,
            MAX(LEN(CAST(Error AS VARCHAR(MAX)))) ErrorML,
            2+MAX(LEN(TestCaseSet)) TestCaseSetML,
            2+MAX(LEN(RunGroup)) RunGroupML,
            2+MAX(LEN(DatabaseName)) DatabaseNameML,
            MAX(LEN(CAST([Version] AS VARCHAR(MAX)))) VersionML,
            MAX(LEN(CAST([ClrVersion] AS VARCHAR(MAX)))) ClrVersionML,
            MAX(LEN(CONVERT(NVARCHAR(MAX),[ClrSigningKey],1))) ClrSigningKeyML,
            MAX(LEN(CAST([InstalledOnSqlVersion] AS VARCHAR(MAX)))) InstalledOnSqlVersionML,
            MAX(LEN(CAST([SqlVersion] AS VARCHAR(MAX)))) SqlVersionML,
            MAX(LEN(CAST([SqlBuild] AS VARCHAR(MAX)))) SqlBuildML,
            MAX(LEN(CAST([SqlEdition] AS VARCHAR(MAX)))) SqlEditionML,
            MAX(LEN(CAST([HostPlatform] AS VARCHAR(MAX)))) HostPlatformML
          FROM tSQLt_testutil.LocalBuildLogTemp
          UNION ALL SELECT 2,7,7,7,5,11,8,12,1,1,1,1,1,1,1,1
      )X
  );
  EXEC(@cmd);
  DECLARE @BuildLog NVARCHAR(MAX);
  EXEC tSQLt.TableToText @txt = @BuildLog OUT, @TableName = 'tSQLt_testutil.LocalBuildLogTempFormatted',@OrderBy = 'id'
  EXEC tSQLt.Private_Print @Message = @BuildLog;

  IF(EXISTS(SELECT * FROM tSQLt_testutil.LocalBuildLogTemp AS MRL WHERE MRL.Failure<>0 OR MRL.Error<>0))
  BEGIN
    EXEC tSQLt.Private_Print @Message = 'tSQLt execution with failures or errors detected.', @Severity = 16
  END;
  IF(NOT EXISTS(SELECT * FROM tSQLt_testutil.LocalBuildLogTemp AS MRL))
  BEGIN
    EXEC tSQLt.Private_Print @Message = 'BuildLog is empty.', @Severity = 16
  END;
  IF(EXISTS(SELECT * FROM tSQLt_testutil.LocalBuildLogTemp AS MRL WHERE MRL.Success IS NULL))
  BEGIN
    EXEC tSQLt.Private_Print @Message = 'BuildLog contains Test Suite Group without tests.', @Severity = 16
  END;
  IF(EXISTS(SELECT * FROM tSQLt_testutil.LocalBuildLogTemp AS MRL WHERE MRL.Success = 0 AND MRL.Skipped = 0))
  BEGIN
    EXEC tSQLt.Private_Print @Message = 'BuildLog contains Run without tests.', @Severity = 16
  END;
END;
GO

CREATE VIEW tSQLt_testutil.Private_RemoteDatabaseInfo AS
SELECT '$(RemoteDbName)' AS RemoteDbName;

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
