GO
EXEC tSQLt.NewTestClass 'tSQLt_testutil_test_SA';
GO
CREATE PROCEDURE tSQLt_testutil_test_SA.[Create and fake tSQLt_testutil.PrepMultiRunLogTable]
AS
BEGIN
  EXEC tSQLt_testutil.PrepMultiRunLogTable
  EXEC tSQLt.FakeTable @TableName = 'tSQLt_testutil.MultiRunLog', @Identity = 1, @ComputedColumns = 0, @Defaults = 0;
END;
GO
CREATE PROCEDURE tSQLt_testutil_test_SA.[test BuildTestLog creates table with correct columns]
AS
BEGIN
  DECLARE @TableName NVARCHAR(MAX) = 'dbo.['+CAST(NEWID() AS NVARCHAR(MAX))+']';
  EXEC tSQLt_testutil.CreateBuildLog @TableName = @TableName;

  CREATE TABLE tSQLt_testutil_test_SA.[testtable for comparison Expected]
  (
    [id] [int] NOT NULL IDENTITY(1, 1),
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

  EXEC('SELECT TOP(0) * INTO tSQLt_testutil_test_SA.[testtable for comparison Actual] FROM '+@TableName+';')

  EXEC tSQLt.AssertEqualsTableSchema @Expected='tSQLt_testutil_test_SA.[testtable for comparison Expected]', @Actual = 'tSQLt_testutil_test_SA.[testtable for comparison Actual]';
END;
GO
CREATE PROCEDURE tSQLt_testutil_test_SA.[test StoreBuildLog transfers data from MultiRunLog and values RunGroup, DatabaseName]
AS
BEGIN
  DECLARE @TableName NVARCHAR(MAX) = 'dbo.['+CAST(NEWID() AS NVARCHAR(MAX))+']';
  EXEC tSQLt_testutil.CreateBuildLog @TableName = @TableName;

  EXEC tSQLt_testutil_test_SA.[Create and fake tSQLt_testutil.PrepMultiRunLogTable];
  SET IDENTITY_INSERT tSQLt_testutil.MultiRunLog ON;
  INSERT INTO tSQLt_testutil.MultiRunLog(id,Success,Skipped,Failure,Error,TestCaseSet)
  VALUES (101,123,456,678,101112,'testcaseset-101'),(102,98,76,54,32,'testcaseset-102'),(103,398,376,354,332,'testcaseset-103');

  EXEC tSQLt_testutil.StoreBuildLog @TableName = @TableName, @RunGroup = 'SomeRunGroup';

  SELECT ROW_NUMBER()OVER(ORDER BY MRL.id) AS id,
         MRL.Success,
         MRL.Skipped,
         MRL.Failure,
         MRL.Error,
         MRL.TestCaseSet,
         'SomeRunGroup' RunGroup,
         DB_NAME() DatabaseName
    INTO tSQLt_testutil_test_SA.[testtable for comparison Expected]
    FROM tSQLt_testutil.MultiRunLog AS MRL;

  EXEC('  SELECT ROW_NUMBER()OVER(ORDER BY MRL.id) AS id,
         MRL.Success,
         MRL.Skipped,
         MRL.Failure,
         MRL.Error,
         MRL.TestCaseSet,
         MRL.RunGroup,
         MRL.DatabaseName
    INTO tSQLt_testutil_test_SA.[testtable for comparison Actual]
    FROM '+@TableName+' AS MRL;')
  
  EXEC tSQLt.AssertEqualsTable 'tSQLt_testutil_test_SA.[testtable for comparison Expected]','tSQLt_testutil_test_SA.[testtable for comparison Actual]';
  
END;
GO
CREATE PROCEDURE tSQLt_testutil_test_SA.[test StoreBuildLog creates row if MultiRunLog is empty]
AS
BEGIN
  DECLARE @TableName NVARCHAR(MAX) = 'dbo.['+CAST(NEWID() AS NVARCHAR(MAX))+']';
  EXEC tSQLt_testutil.CreateBuildLog @TableName = @TableName;

  EXEC tSQLt_testutil_test_SA.[Create and fake tSQLt_testutil.PrepMultiRunLogTable];

  EXEC tSQLt_testutil.StoreBuildLog @TableName = @TableName, @RunGroup = 'AnotherRunGroup';

  SELECT 1  id,
         NULL Success,
         NULL Skipped,
         NULL Failure,
         NULL Error,
         NULL TestCaseSet,
         'AnotherRunGroup' RunGroup,
         DB_NAME() DatabaseName
    INTO tSQLt_testutil_test_SA.[testtable for comparison Expected];

  EXEC('  SELECT ROW_NUMBER()OVER(ORDER BY MRL.id) AS id,
         MRL.Success,
         MRL.Skipped,
         MRL.Failure,
         MRL.Error,
         MRL.TestCaseSet,
         MRL.RunGroup,
         MRL.DatabaseName
    INTO tSQLt_testutil_test_SA.[testtable for comparison Actual]
    FROM '+@TableName+' AS MRL;')

  EXEC tSQLt.AssertEqualsTable 'tSQLt_testutil_test_SA.[testtable for comparison Expected]','tSQLt_testutil_test_SA.[testtable for comparison Actual]';
  
END;
GO
-------------------------------------------------------------------------
GO
CREATE PROCEDURE tSQLt_testutil_test_SA.[test CheckBuildLog throws error if a test error exists in the log]
AS
BEGIN
  EXEC tSQLt_testutil_test_SA.[Create and fake tSQLt_testutil.PrepMultiRunLogTable];
  INSERT INTO tSQLt_testutil.MultiRunLog(Error)VALUES(1);

  EXEC tSQLt_testutil.CreateBuildLog @TableName = 'tSQLt_testutil_test_SA.[Temp BuildLog Table]';
  EXEC tSQLt_testutil.StoreBuildLog @TableName = 'tSQLt_testutil_test_SA.[Temp BuildLog Table]',@RunGroup='ATest';

  SELECT TOP(0)MRL.*
  INTO #ignore
  FROM tSQLt_testutil_test_SA.[Temp BuildLog Table] X LEFT JOIN tSQLt_testutil_test_SA.[Temp BuildLog Table] AS MRL ON 0=1;   

  EXEC tSQLt.ExpectException @ExpectedMessage = 'tSQLt execution with failures or errors detected.', @ExpectedSeverity = 16, @ExpectedState = 10;
  
  INSERT INTO #ignore
  EXEC tSQLt_testutil.CheckBuildLog @TableName = 'tSQLt_testutil_test_SA.[Temp BuildLog Table]';
  
END
GO
CREATE PROCEDURE tSQLt_testutil_test_SA.[test CheckBuildLog throws error if a test failure exists in the log]
AS
BEGIN
  EXEC tSQLt_testutil_test_SA.[Create and fake tSQLt_testutil.PrepMultiRunLogTable];
  INSERT INTO tSQLt_testutil.MultiRunLog(Failure)VALUES(1);

  EXEC tSQLt_testutil.CreateBuildLog @TableName = 'tSQLt_testutil_test_SA.[Temp BuildLog Table]';
  EXEC tSQLt_testutil.StoreBuildLog @TableName = 'tSQLt_testutil_test_SA.[Temp BuildLog Table]',@RunGroup='ATest';

  SELECT TOP(0)MRL.*
  INTO #ignore
  FROM tSQLt_testutil_test_SA.[Temp BuildLog Table] X LEFT JOIN tSQLt_testutil_test_SA.[Temp BuildLog Table] AS MRL ON 0=1;   

  EXEC tSQLt.ExpectException @ExpectedMessage = 'tSQLt execution with failures or errors detected.', @ExpectedSeverity = 16, @ExpectedState = 10;
  
  INSERT INTO #ignore
  EXEC tSQLt_testutil.CheckBuildLog @TableName = 'tSQLt_testutil_test_SA.[Temp BuildLog Table]';
  
END
GO
CREATE PROCEDURE tSQLt_testutil_test_SA.[test CheckBuildLog throws no error if all tests in the log succeeded]
AS
BEGIN
  EXEC tSQLt_testutil_test_SA.[Create and fake tSQLt_testutil.PrepMultiRunLogTable];
  INSERT INTO tSQLt_testutil.MultiRunLog(Success)VALUES(1);

  EXEC tSQLt_testutil.CreateBuildLog @TableName = 'tSQLt_testutil_test_SA.[Temp BuildLog Table]';
  EXEC tSQLt_testutil.StoreBuildLog @TableName = 'tSQLt_testutil_test_SA.[Temp BuildLog Table]',@RunGroup='ATest';

  SELECT TOP(0)MRL.*
  INTO #ignore
  FROM tSQLt_testutil_test_SA.[Temp BuildLog Table] X LEFT JOIN tSQLt_testutil_test_SA.[Temp BuildLog Table] AS MRL ON 0=1;   

  EXEC tSQLt.ExpectNoException;
  
  INSERT INTO #ignore
  EXEC tSQLt_testutil.CheckBuildLog @TableName = 'tSQLt_testutil_test_SA.[Temp BuildLog Table]';
  
END
GO
CREATE PROCEDURE tSQLt_testutil_test_SA.[test CheckBuildLog can be called twice]
AS
BEGIN
  EXEC tSQLt_testutil_test_SA.[Create and fake tSQLt_testutil.PrepMultiRunLogTable];
  INSERT INTO tSQLt_testutil.MultiRunLog(Success)VALUES(1);

  EXEC tSQLt_testutil.CreateBuildLog @TableName = 'tSQLt_testutil_test_SA.[Temp BuildLog Table]';
  EXEC tSQLt_testutil.StoreBuildLog @TableName = 'tSQLt_testutil_test_SA.[Temp BuildLog Table]',@RunGroup='ATest';

  SELECT TOP(0)MRL.*
  INTO #ignore
  FROM tSQLt_testutil_test_SA.[Temp BuildLog Table] X LEFT JOIN tSQLt_testutil_test_SA.[Temp BuildLog Table] AS MRL ON 0=1;   

  EXEC tSQLt.ExpectNoException;

  INSERT INTO #ignore
  EXEC tSQLt_testutil.CheckBuildLog @TableName = 'tSQLt_testutil_test_SA.[Temp BuildLog Table]';
  
  INSERT INTO #ignore
  EXEC tSQLt_testutil.CheckBuildLog @TableName = 'tSQLt_testutil_test_SA.[Temp BuildLog Table]';
  
END
GO

CREATE PROCEDURE tSQLt_testutil_test_SA.[test CheckBuildLog Private_Print is called with the result of TableToText]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_Print';
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.TableToText', @CommandToExecute = 'SET @txt=''<recognizable text goes here>'';';

  EXEC tSQLt_testutil.CreateBuildLog @TableName = 'tSQLt_testutil_test_SA.[Temp BuildLog Table]';

  EXEC tSQLt_testutil.CheckBuildLog @TableName = 'tSQLt_testutil_test_SA.[Temp BuildLog Table]';

  IF NOT EXISTS(SELECT 1 FROM tSQLt.Private_Print_SpyProcedureLog WHERE Message = '<recognizable text goes here>')
  BEGIN
    EXEC tSQLt.Fail 'tSQLt.Private_Print was not called with the output of tSQLt.TableToText';
  END;

END;
GO

--TODO: This really needs an "undo" on the tSQLt.SpyProcedure, but we don't have time for it.
CREATE PROCEDURE tSQLt_testutil_test_SA.[test CheckBuildLog prints contents of Log]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_Print';
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.TableToText';

  EXEC tSQLt_testutil.CreateBuildLog @TableName = 'tSQLt_testutil_test_SA.[Temp BuildLog Table]';
  EXEC tSQLt.FakeTable @TableName = 'tSQLt_testutil_test_SA.[Temp BuildLog Table]';
  INSERT INTO tSQLt_testutil_test_SA.[Temp BuildLog Table](id, Success, Skipped, Failure, Error, TestCaseSet, RunGroup, DatabaseName)
  VALUES
    (101,17,9,1,3,'row 1','RG1','DB1'),(102,4,6,7,5,'row 2','RG2','DB2');

  EXEC tSQLt_testutil.CheckBuildLog @TableName = 'tSQLt_testutil_test_SA.[Temp BuildLog Table]';

  DECLARE @TableName NVARCHAR(MAX) = (SELECT TableName FROM tSQLt.TableToText_SpyProcedureLog);

  SELECT CAST (MRL.id AS NVARCHAR(MAX)) AS id,
         CAST (MRL.Success AS NVARCHAR(MAX)) AS Success,
         CAST (MRL.Skipped AS NVARCHAR(MAX)) AS Skipped,
         CAST (MRL.Failure AS NVARCHAR(MAX)) AS Failure,
         CAST (MRL.Error AS NVARCHAR(MAX)) AS Error,
         CAST (MRL.TestCaseSet AS NVARCHAR(MAX)) AS TestCaseSet,
         CAST (RunGroup AS NVARCHAR(MAX)) AS RunGroup,
         CAST (DatabaseName AS NVARCHAR(MAX)) AS DatabaseName
    INTO tSQLt_testutil_test_SA.[testtable for comparison Expected]
    FROM tSQLt_testutil_test_SA.[Temp BuildLog Table] AS MRL

  EXEC('SELECT * INTO tSQLt_testutil_test_SA.[testtable for comparison Hold] FROM ' + @TableName + ';');

  SELECT LTRIM(RTRIM(CAST (MRL.id AS NVARCHAR(MAX)))) AS id,
         LTRIM(RTRIM(CAST (MRL.Success AS NVARCHAR(MAX)))) AS Success,
         LTRIM(RTRIM(CAST (MRL.Skipped AS NVARCHAR(MAX)))) AS Skipped,
         LTRIM(RTRIM(CAST (MRL.Failure AS NVARCHAR(MAX)))) AS Failure,
         LTRIM(RTRIM(CAST (MRL.Error AS NVARCHAR(MAX)))) AS Error,
         LTRIM(RTRIM(CAST (MRL.TestCaseSet AS NVARCHAR(MAX)))) AS TestCaseSet,
         LTRIM(RTRIM(CAST (RunGroup AS NVARCHAR(MAX)))) AS RunGroup,
         LTRIM(RTRIM(CAST (DatabaseName AS NVARCHAR(MAX)))) AS DatabaseName
    INTO tSQLt_testutil_test_SA.[testtable for comparison Actual]
    FROM tSQLt_testutil_test_SA.[testtable for comparison Hold] AS MRL


  EXEC tSQLt.AssertEqualsTable 'tSQLt_testutil_test_SA.[testtable for comparison Expected]','tSQLt_testutil_test_SA.[testtable for comparison Actual]';  
END
GO
CREATE PROCEDURE tSQLt_testutil_test_SA.[test CheckBuildLog throws error if the log is empty]
AS
BEGIN
  EXEC tSQLt_testutil_test_SA.[Create and fake tSQLt_testutil.PrepMultiRunLogTable];

  EXEC tSQLt_testutil.CreateBuildLog @TableName = 'tSQLt_testutil_test_SA.[Temp BuildLog Table]';

  SELECT TOP(0)MRL.*
  INTO #ignore
  FROM tSQLt_testutil_test_SA.[Temp BuildLog Table] X LEFT JOIN tSQLt_testutil_test_SA.[Temp BuildLog Table] AS MRL ON 0=1;   

  EXEC tSQLt.ExpectException @ExpectedMessage = 'BuildLog is empty.', @ExpectedSeverity = 16, @ExpectedState = 10;
  
  INSERT INTO #ignore
  EXEC tSQLt_testutil.CheckBuildLog @TableName = 'tSQLt_testutil_test_SA.[Temp BuildLog Table]';
  
END
GO
CREATE PROCEDURE tSQLt_testutil_test_SA.[test CheckBuildLog throws error if the log contains empty run]
AS
BEGIN
  EXEC tSQLt_testutil_test_SA.[Create and fake tSQLt_testutil.PrepMultiRunLogTable];
  INSERT INTO tSQLt_testutil.MultiRunLog(Success,Skipped,Failure,Error,TestCaseSet)
  VALUES(0,0,0,0,'some run');

  EXEC tSQLt_testutil.CreateBuildLog @TableName = 'tSQLt_testutil_test_SA.[Temp BuildLog Table]';
  EXEC tSQLt_testutil.StoreBuildLog @TableName = 'tSQLt_testutil_test_SA.[Temp BuildLog Table]',@RunGroup='ATest';

  SELECT TOP(0)MRL.*
  INTO #ignore
  FROM tSQLt_testutil_test_SA.[Temp BuildLog Table] X LEFT JOIN tSQLt_testutil_test_SA.[Temp BuildLog Table] AS MRL ON 0=1;   

  EXEC tSQLt.ExpectException @ExpectedMessage = 'BuildLog contains Run without tests.', @ExpectedSeverity = 16, @ExpectedState = 10;
  
  INSERT INTO #ignore
  EXEC tSQLt_testutil.CheckBuildLog @TableName = 'tSQLt_testutil_test_SA.[Temp BuildLog Table]';
  
END
GO
CREATE PROCEDURE tSQLt_testutil_test_SA.[ptest CheckBuildLog doesn't throw error if]
  @success INT = 0,
  @skipped INT = 0,
  @failed INT = 0,
  @errored INT = 0
AS
BEGIN
  EXEC tSQLt_testutil_test_SA.[Create and fake tSQLt_testutil.PrepMultiRunLogTable];
  INSERT INTO tSQLt_testutil.MultiRunLog(Success,Skipped,Failure,Error)
  VALUES(@success,@skipped,@failed,@errored);
  
  EXEC tSQLt_testutil.CreateBuildLog @TableName = 'tSQLt_testutil_test_SA.[Temp BuildLog Table]';
  EXEC tSQLt_testutil.StoreBuildLog @TableName = 'tSQLt_testutil_test_SA.[Temp BuildLog Table]',@RunGroup='ATest';
  
  SELECT TOP(0)MRL.*
  INTO #Actual
  FROM tSQLt_testutil_test_SA.[Temp BuildLog Table] X LEFT JOIN tSQLt_testutil_test_SA.[Temp BuildLog Table] AS MRL ON 0=1;   

  EXEC tSQLt.ExpectNoException;
  
  INSERT INTO #Actual
  EXEC tSQLt_testutil.CheckBuildLog @TableName = 'tSQLt_testutil_test_SA.[Temp BuildLog Table]';
    
END
GO
CREATE PROCEDURE tSQLt_testutil_test_SA.[test CheckBuildLog doesn't throw error if a success exists]
AS
BEGIN
  EXEC tSQLt_testutil_test_SA.[ptest CheckBuildLog doesn't throw error if] @success=1;
END
GO
CREATE PROCEDURE tSQLt_testutil_test_SA.[test CheckBuildLog doesn't throw error if a skip exists]
AS
BEGIN
  EXEC tSQLt_testutil_test_SA.[ptest CheckBuildLog doesn't throw error if] @skipped=1;
END
GO
