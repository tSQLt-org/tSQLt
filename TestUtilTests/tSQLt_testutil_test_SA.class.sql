GO
EXEC tSQLt.NewTestClass 'tSQLt_testutil_test_SA';
GO
CREATE PROCEDURE tSQLt_testutil_test_SA.[Create and fake tSQLt_testutil.PrepMultiRunLogTable]
  @identity INT = 0
AS
BEGIN
  EXEC tSQLt_testutil.PrepMultiRunLogTable
  EXEC tSQLt.FakeTable @TableName = 'tSQLt_testutil.MultiRunLog', @Identity = @identity, @ComputedColumns = 0, @Defaults = 0;
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
    [DatabaseName] NVARCHAR(MAX) NULL
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

  EXEC tSQLt.FakeTable @TableName = 'tSQLt_testutil.MultiRunLog',@Identity = 1;
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

  EXEC tSQLt.FakeTable @TableName = 'tSQLt_testutil.MultiRunLog',@Identity = 1;

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

  SELECT TOP(0)*
  INTO #Actual
  FROM tSQLt_testutil_test_SA.[Temp BuildLog Table] AS MRL;

  EXEC tSQLt.ExpectException @ExpectedMessage = 'tSQLt execution with failures or errors detected.', @ExpectedSeverity = 16, @ExpectedState = 10;
  
  INSERT INTO #Actual
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

  SELECT TOP(0)*
  INTO #Actual
  FROM tSQLt_testutil_test_SA.[Temp BuildLog Table] AS MRL;

  EXEC tSQLt.ExpectException @ExpectedMessage = 'tSQLt execution with failures or errors detected.', @ExpectedSeverity = 16, @ExpectedState = 10;
  
  INSERT INTO #Actual
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

  SELECT TOP(0)*
  INTO #Actual
  FROM tSQLt_testutil_test_SA.[Temp BuildLog Table] AS MRL; 

  EXEC tSQLt.ExpectNoException;
  
  INSERT INTO #Actual
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

  SELECT TOP(0)*
  INTO #Actual
  FROM tSQLt_testutil_test_SA.[Temp BuildLog Table] AS MRL; 

  EXEC tSQLt.ExpectNoException;
  
  INSERT INTO #Actual
  EXEC tSQLt_testutil.CheckBuildLog @TableName = 'tSQLt_testutil_test_SA.[Temp BuildLog Table]';
  
  INSERT INTO #Actual
  EXEC tSQLt_testutil.CheckBuildLog @TableName = 'tSQLt_testutil_test_SA.[Temp BuildLog Table]';
  
END
GO
CREATE PROCEDURE tSQLt_testutil_test_SA.[test CheckBuildLog returns contents of Log as resultset]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_Print';
  EXEC tSQLt_testutil_test_SA.[Create and fake tSQLt_testutil.PrepMultiRunLogTable] @identity=1;
  SET IDENTITY_INSERT tSQLt_testutil.MultiRunLog ON;
  INSERT INTO tSQLt_testutil.MultiRunLog(id,Success,Skipped,Failure,Error,TestCaseSet)
  VALUES
    (101,17,9,1,3,'row 1'),(102,4,6,7,5,'row 2');

  EXEC tSQLt_testutil.CreateBuildLog @TableName = 'tSQLt_testutil_test_SA.[Temp BuildLog Table]';
  EXEC tSQLt_testutil.StoreBuildLog @TableName = 'tSQLt_testutil_test_SA.[Temp BuildLog Table]',@RunGroup='ATest1';
  EXEC tSQLt_testutil.StoreBuildLog @TableName = 'tSQLt_testutil_test_SA.[Temp BuildLog Table]',@RunGroup='ATest2';
  --SELECT * FROM tSQLt_testutil_test_SA.[Temp BuildLog Table];

  SELECT TOP(0)MRL.*
  INTO tSQLt_testutil_test_SA.[testtable for comparison Actual]
  FROM tSQLt_testutil_test_SA.[Temp BuildLog Table] X LEFT JOIN tSQLt_testutil_test_SA.[Temp BuildLog Table] AS MRL ON 0=1;   

  INSERT INTO tSQLt_testutil_test_SA.[testtable for comparison Actual]
  EXEC tSQLt_testutil.CheckBuildLog @TableName = 'tSQLt_testutil_test_SA.[Temp BuildLog Table]';



  SELECT ROW_NUMBER()OVER(ORDER BY XX.RunGroup,MRL.id) AS id,
         MRL.Success,
         MRL.Skipped,
         MRL.Failure,
         MRL.Error,
         MRL.TestCaseSet,
         RunGroup,
         DB_NAME() DatabaseName
    INTO tSQLt_testutil_test_SA.[testtable for comparison Expected]
    FROM tSQLt_testutil.MultiRunLog AS MRL
    CROSS JOIN (VALUES('ATest1'),('ATest2'))XX(RunGroup);

  EXEC tSQLt.AssertEqualsTable 'tSQLt_testutil_test_SA.[testtable for comparison Expected]','tSQLt_testutil_test_SA.[testtable for comparison Actual]';  
END
GO
CREATE PROCEDURE tSQLt_testutil_test_SA.[test CheckBuildLog throws error if the log is empty]
AS
BEGIN
  EXEC tSQLt_testutil_test_SA.[Create and fake tSQLt_testutil.PrepMultiRunLogTable];

  EXEC tSQLt_testutil.CreateBuildLog @TableName = 'tSQLt_testutil_test_SA.[Temp BuildLog Table]';

  SELECT TOP(0)*
  INTO #Actual
  FROM tSQLt_testutil_test_SA.[Temp BuildLog Table] AS MRL; 

  EXEC tSQLt.ExpectException @ExpectedMessage = 'BuildLog is empty.', @ExpectedSeverity = 16, @ExpectedState = 10;
  
  INSERT INTO #Actual
  EXEC tSQLt_testutil.CheckBuildLog @TableName = 'tSQLt_testutil_test_SA.[Temp BuildLog Table]';
  
END
GO
CREATE PROCEDURE tSQLt_testutil_test_SA.[test CheckBuildLog throws error if the log contains empty run]
AS
BEGIN
  EXEC tSQLt_testutil_test_SA.[Create and fake tSQLt_testutil.PrepMultiRunLogTable];
  INSERT INTO tSQLt_testutil.MultiRunLog(id,Success,Skipped,Failure,Error,TestCaseSet)
  VALUES(42,0,0,0,0,'some run');

  EXEC tSQLt_testutil.CreateBuildLog @TableName = 'tSQLt_testutil_test_SA.[Temp BuildLog Table]';
  EXEC tSQLt_testutil.StoreBuildLog @TableName = 'tSQLt_testutil_test_SA.[Temp BuildLog Table]',@RunGroup='ATest';

  SELECT TOP(0)*
  INTO #Actual
  FROM tSQLt_testutil_test_SA.[Temp BuildLog Table] AS MRL;

  EXEC tSQLt.ExpectException @ExpectedMessage = 'BuildLog contains Run without tests.', @ExpectedSeverity = 16, @ExpectedState = 10;
  
  INSERT INTO #Actual
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

  SELECT TOP(0)*
  INTO #Actual
  FROM tSQLt_testutil_test_SA.[Temp BuildLog Table] AS MRL; 

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
