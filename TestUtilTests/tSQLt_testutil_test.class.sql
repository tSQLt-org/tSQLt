GO
EXEC tSQLt.NewTestClass 'tSQLt_testutil_test';
GO
CREATE PROCEDURE tSQLt_testutil_test.[test DataTypeNoEqual can be serialized]
AS
BEGIN
  DECLARE @inst1 tSQLt_testutil.DataTypeNoEqual;
  DECLARE @inst1bin BINARY(5);
  DECLARE @inst2 tSQLt_testutil.DataTypeNoEqual;
  DECLARE @inst2bin BINARY(5);

  SET @inst1 = '1';
  SET @inst1bin = CAST(@inst1 AS BINARY(5));
  EXEC tSQLt.AssertEquals 0x0001000000, @inst1bin;

  SET @inst2 = CAST(@inst1bin AS tSQLt_testutil.DataTypeNoEqual);
  SET @inst2bin = CAST(@inst2 AS BINARY(5));
  EXEC tSQLt.AssertEquals 0x0001000000, @inst2bin;
  
END
GO
CREATE PROCEDURE tSQLt_testutil_test.[test DataTypeNoEqual has constant ToString()]
AS
BEGIN
  DECLARE @inst1 tSQLt_testutil.DataTypeNoEqual;
  DECLARE @inst1str NVARCHAR(MAX);
  DECLARE @inst2 tSQLt_testutil.DataTypeNoEqual;
  DECLARE @inst2str NVARCHAR(MAX);

  SET @inst1 = '1';
  SET @inst2 = '2';
  
  SET @inst1str = @inst1.ToString();
  SET @inst2str = @inst2.ToString();
  
  EXEC tSQLt.AssertEqualsString @inst1str,@inst2str;
END
GO
CREATE PROCEDURE tSQLt_testutil_test.[test DataTypeNoEqual cannot compare]
AS
BEGIN
  DECLARE @Message NVARCHAR(MAX);
  SET @Message = '<No Error>';
  
  BEGIN TRY
    EXEC('IF(CAST( ''1'' AS tSQLt_testutil.DataTypeNoEqual) = CAST( ''2'' AS tSQLt_testutil.DataTypeNoEqual)) PRINT 1;')
  END TRY  
  BEGIN CATCH
  SELECT @Message = ERROR_MESSAGE()
  END CATCH
  
  EXEC tSQLt.AssertEqualsString 'Invalid operator for data type. Operator equals equal to, type equals DataTypeNoEqual.',@Message;
  
END
GO
CREATE PROCEDURE tSQLt_testutil_test.[test DataTypeNoEqual cannot GROUP BY]
AS
BEGIN
  DECLARE @Message NVARCHAR(MAX);
  SET @Message = '<No Error>';
  
  CREATE TABLE tSQLt_testutil_test.tmp1(
    id INT IDENTITY(1,1) PRIMARY KEY CLUSTERED,
    dtne tSQLt_testutil.DataTypeNoEqual NULL
  );
  
  INSERT INTO tSQLt_testutil_test.tmp1(dtne)VALUES('1');
  INSERT INTO tSQLt_testutil_test.tmp1(dtne)VALUES('1');

  BEGIN TRY
    EXEC('SELECT dtne,COUNT(1) Cnt FROM tSQLt_testutil_test.tmp1 GROUP BY dtne;');
  END TRY  
  BEGIN CATCH
  SELECT @Message = ERROR_MESSAGE()
  END CATCH
  
  EXEC tSQLt.AssertEqualsString 'The type "DataTypeNoEqual" is not comparable. It cannot be used in the GROUP BY clause.',@Message;
  
END
GO
------------------------------------------------------------------------------------------------------------
GO
CREATE PROCEDURE tSQLt_testutil_test.[test DataTypeWithEqual can be serialized]
AS
BEGIN
  DECLARE @inst1 tSQLt_testutil.DataTypeWithEqual;
  DECLARE @inst1bin BINARY(5);
  DECLARE @inst2 tSQLt_testutil.DataTypeWithEqual;
  DECLARE @inst2bin BINARY(5);

  SET @inst1 = '1';
  SET @inst1bin = CAST(@inst1 AS BINARY(5));
  EXEC tSQLt.AssertEquals 0x0001000000, @inst1bin;

  SET @inst2 = CAST(@inst1bin AS tSQLt_testutil.DataTypeWithEqual);
  SET @inst2bin = CAST(@inst2 AS BINARY(5));
  EXEC tSQLt.AssertEquals 0x0001000000, @inst2bin;
  
END
GO
CREATE PROCEDURE tSQLt_testutil_test.[test DataTypeWithEqual has constant ToString()]
AS
BEGIN
  DECLARE @inst1 tSQLt_testutil.DataTypeWithEqual;
  DECLARE @inst1str NVARCHAR(MAX);
  DECLARE @inst2 tSQLt_testutil.DataTypeWithEqual;
  DECLARE @inst2str NVARCHAR(MAX);

  SET @inst1 = '1';
  SET @inst2 = '2';
  
  SET @inst1str = @inst1.ToString();
  SET @inst2str = @inst2.ToString();
  
  EXEC tSQLt.AssertEqualsString @inst1str,@inst2str;
END
GO
CREATE PROCEDURE tSQLt_testutil_test.[test DataTypeWithEqual has CompareTo (but we can't use it...)]
AS
BEGIN
  DECLARE @Message NVARCHAR(MAX);
  SET @Message = '<No Error>';
  DECLARE @inst1 tSQLt_testutil.DataTypeWithEqual;

  SET @inst1 = '1';
  
  BEGIN TRY
    PRINT @inst1.CompareTo(CAST(@inst1 AS BINARY(5)));
  END TRY  
  BEGIN CATCH
    SELECT @Message = ERROR_MESSAGE()
  END CATCH
  
  EXEC tSQLt.AssertLike '%Object is not a DataTypeWithEqual.%',@Message;

END
GO
CREATE PROCEDURE tSQLt_testutil_test.[test DataTypeWithEqual cannot compare]
AS
BEGIN
  DECLARE @Message NVARCHAR(MAX);
  SET @Message = '<No Error>';
  
  BEGIN TRY
    EXEC('IF(CAST( ''1'' AS tSQLt_testutil.DataTypeWithEqual) = CAST( ''2'' AS tSQLt_testutil.DataTypeWithEqual)) PRINT 1;')
  END TRY  
  BEGIN CATCH
  SELECT @Message = ERROR_MESSAGE()
  END CATCH
  
  EXEC tSQLt.AssertEqualsString 'Invalid operator for data type. Operator equals equal to, type equals DataTypeWithEqual.',@Message;
  
END
GO
CREATE PROCEDURE tSQLt_testutil_test.[test DataTypeWithEqual cannot GROUP BY]
AS
BEGIN
  DECLARE @Message NVARCHAR(MAX);
  SET @Message = '<No Error>';
  
  CREATE TABLE tSQLt_testutil_test.tmp1(
    id INT IDENTITY(1,1) PRIMARY KEY CLUSTERED,
    dtne tSQLt_testutil.DataTypeWithEqual NULL
  );
  
  INSERT INTO tSQLt_testutil_test.tmp1(dtne)VALUES('1');
  INSERT INTO tSQLt_testutil_test.tmp1(dtne)VALUES('1');

  BEGIN TRY
    EXEC('SELECT dtne,COUNT(1) Cnt FROM tSQLt_testutil_test.tmp1 GROUP BY dtne;');
  END TRY  
  BEGIN CATCH
  SELECT @Message = ERROR_MESSAGE()
  END CATCH
  
  EXEC tSQLt.AssertEqualsString 'The type "DataTypeWithEqual" is not comparable. It cannot be used in the GROUP BY clause.',@Message;
  
END
GO
------------------------------------------------------------------------------------------------------------
GO
CREATE PROCEDURE tSQLt_testutil_test.[test DataTypeByteOrdered can be serialized]
AS
BEGIN
  DECLARE @inst1 tSQLt_testutil.DataTypeByteOrdered;
  DECLARE @inst1bin BINARY(5);
  DECLARE @inst2 tSQLt_testutil.DataTypeByteOrdered;
  DECLARE @inst2bin BINARY(5);

  SET @inst1 = '1';
  SET @inst1bin = CAST(@inst1 AS BINARY(5));
  EXEC tSQLt.AssertEquals 0x0001000000, @inst1bin;

  SET @inst2 = CAST(@inst1bin AS tSQLt_testutil.DataTypeByteOrdered);
  SET @inst2bin = CAST(@inst2 AS BINARY(5));
  EXEC tSQLt.AssertEquals 0x0001000000, @inst2bin;
  
END
GO
CREATE PROCEDURE tSQLt_testutil_test.[test DataTypeByteOrdered has ToString()]
AS
BEGIN
  DECLARE @inst1 tSQLt_testutil.DataTypeByteOrdered;
  DECLARE @inst1str NVARCHAR(MAX);
  DECLARE @inst2 tSQLt_testutil.DataTypeByteOrdered;
  DECLARE @inst2str NVARCHAR(MAX);

  SET @inst1 = '13';
  
  SET @inst1str = @inst1.ToString();
  
  EXEC tSQLt.AssertEqualsString '<<DataTypeByteOrdered:13>>',@inst1str;
END
GO
CREATE PROCEDURE tSQLt_testutil_test.[test DataTypeByteOrdered has CompareTo (but we can't use it...)]
AS
BEGIN
  DECLARE @Message NVARCHAR(MAX);
  SET @Message = '<No Error>';
  DECLARE @inst1 tSQLt_testutil.DataTypeByteOrdered;

  SET @inst1 = '1';
  
  BEGIN TRY
    PRINT @inst1.CompareTo(CAST(@inst1 AS BINARY(5)));
  END TRY  
  BEGIN CATCH
    SELECT @Message = ERROR_MESSAGE()
  END CATCH
  
  EXEC tSQLt.AssertLike '%Object is not a DataTypeByteOrdered.%',@Message;

END
GO
CREATE PROCEDURE tSQLt_testutil_test.[test DataTypeByteOrdered can compare]
AS
BEGIN
  DECLARE @Message NVARCHAR(MAX);
  SET @Message = '<No Error>';
  
  IF(CAST( '1' AS tSQLt_testutil.DataTypeByteOrdered) = CAST( '2' AS tSQLt_testutil.DataTypeByteOrdered))
  BEGIN
    EXEC tSQLt.Fail '1 and 2 should not be equal...';
  END  
  
END
GO
CREATE PROCEDURE tSQLt_testutil_test.[test DataTypeByteOrdered can GROUP BY]
AS
BEGIN
  DECLARE @Message NVARCHAR(MAX);
  SET @Message = '<No Error>';
  
  CREATE TABLE tSQLt_testutil_test.tmp1(
    id INT IDENTITY(1,1) PRIMARY KEY CLUSTERED,
    dtne tSQLt_testutil.DataTypeByteOrdered NULL
  );
  
  INSERT INTO tSQLt_testutil_test.tmp1(dtne)VALUES('1');
  INSERT INTO tSQLt_testutil_test.tmp1(dtne)VALUES('1');
  INSERT INTO tSQLt_testutil_test.tmp1(dtne)VALUES('2');
  INSERT INTO tSQLt_testutil_test.tmp1(dtne)VALUES('2');
  INSERT INTO tSQLt_testutil_test.tmp1(dtne)VALUES('2');

  SELECT CAST(dtne AS BINARY(5)) dtne,COUNT(1) cnt 
  INTO #actual
  FROM tSQLt_testutil_test.tmp1 GROUP BY dtne;
  
  SELECT TOP(0)* INTO #expected FROM #actual;
  INSERT INTO #expected(dtne, cnt)
  SELECT 0x0001000000, 2
  UNION ALL
  SELECT 0x0002000000, 3;
  
  EXEC tSQLt.AssertEqualsTable '#expected','#actual';
END
GO
CREATE PROCEDURE tSQLt_testutil_test.[Create and fake tSQLt_testutil.PrepMultiRunLogTable]
  @identity INT = 0
AS
BEGIN
  EXEC tSQLt_testutil.PrepMultiRunLogTable
  EXEC tSQLt.FakeTable @TableName = 'tSQLt_testutil.MultiRunLog', @Identity = @identity, @ComputedColumns = 0, @Defaults = 0;
END;
GO
CREATE PROCEDURE tSQLt_testutil_test.[test CheckMultiRunResults throws error if a test error exists in the log]
AS
BEGIN
  EXEC tSQLt_testutil_test.[Create and fake tSQLt_testutil.PrepMultiRunLogTable];
  INSERT INTO tSQLt_testutil.MultiRunLog(Error)VALUES(1);

  SELECT TOP(0)*
  INTO #Actual
  FROM tSQLt_testutil.MultiRunLog AS MRL;

  EXEC tSQLt.ExpectException @ExpectedMessage = 'tSQLt execution with failures or errors detected.', @ExpectedSeverity = 16, @ExpectedState = 10;
  
  INSERT INTO #Actual
  EXEC tSQLt_testutil.CheckMultiRunResults;
  
END
GO
CREATE PROCEDURE tSQLt_testutil_test.[test CheckMultiRunResults throws error if a test failure exists in the log]
AS
BEGIN
  EXEC tSQLt_testutil_test.[Create and fake tSQLt_testutil.PrepMultiRunLogTable];
  INSERT INTO tSQLt_testutil.MultiRunLog(Failure)VALUES(1);

  SELECT TOP(0)*
  INTO #Actual
  FROM tSQLt_testutil.MultiRunLog AS MRL;

  EXEC tSQLt.ExpectException @ExpectedMessage = 'tSQLt execution with failures or errors detected.', @ExpectedSeverity = 16, @ExpectedState = 10;
  
  INSERT INTO #Actual
  EXEC tSQLt_testutil.CheckMultiRunResults;
  
END
GO
CREATE PROCEDURE tSQLt_testutil_test.[test CheckMultiRunResults throws no error if all tests in the log succeeded]
AS
BEGIN
  EXEC tSQLt_testutil_test.[Create and fake tSQLt_testutil.PrepMultiRunLogTable];
  INSERT INTO tSQLt_testutil.MultiRunLog(Success)VALUES(1);

  SELECT TOP(0)*
  INTO #Actual
  FROM tSQLt_testutil.MultiRunLog AS MRL;

  EXEC tSQLt.ExpectNoException;
  
  INSERT INTO #Actual
  EXEC tSQLt_testutil.CheckMultiRunResults;
  
END
GO
CREATE PROCEDURE tSQLt_testutil_test.[test CheckMultiRunResults returns contents of Log as resultset]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_Print';
  EXEC tSQLt_testutil_test.[Create and fake tSQLt_testutil.PrepMultiRunLogTable];
  INSERT INTO tSQLt_testutil.MultiRunLog(id,Success,Skipped,Failure,Error,TestCaseSet)
  VALUES
    (1,17,9,1,3,'row 1'),(2,4,6,7,5,'row 2');

  SELECT TOP(0)*
  INTO #Actual
  FROM tSQLt_testutil.MultiRunLog AS MRL;

  INSERT INTO #Actual
  EXEC tSQLt_testutil.CheckMultiRunResults;

  EXEC tSQLt.AssertEqualsTable 'tSQLt_testutil.MultiRunLog','#Actual';  
END
GO
CREATE PROCEDURE tSQLt_testutil_test.[test CheckMultiRunResults throws error if the log is empty]
AS
BEGIN
  EXEC tSQLt_testutil_test.[Create and fake tSQLt_testutil.PrepMultiRunLogTable];

  SELECT TOP(0)*
  INTO #Actual
  FROM tSQLt_testutil.MultiRunLog AS MRL;

  EXEC tSQLt.ExpectException @ExpectedMessage = 'MultiRunLog is empty.', @ExpectedSeverity = 16, @ExpectedState = 10;
  
  INSERT INTO #Actual
  EXEC tSQLt_testutil.CheckMultiRunResults;
  
END
GO
CREATE PROCEDURE tSQLt_testutil_test.[test CheckMultiRunResults throws error if the log contains empty run]
AS
BEGIN
  EXEC tSQLt_testutil_test.[Create and fake tSQLt_testutil.PrepMultiRunLogTable];
  INSERT INTO tSQLt_testutil.MultiRunLog(id,Success,Skipped,Failure,Error,TestCaseSet)
  VALUES(42,0,0,0,0,'some run');

  SELECT TOP(0)*
  INTO #Actual
  FROM tSQLt_testutil.MultiRunLog AS MRL;

  EXEC tSQLt.ExpectException @ExpectedMessage = 'MultiRunLog contains Run without tests.', @ExpectedSeverity = 16, @ExpectedState = 10;
  
  INSERT INTO #Actual
  EXEC tSQLt_testutil.CheckMultiRunResults;
  
END
GO
CREATE PROCEDURE tSQLt_testutil_test.[test CheckMultiRunResults doesn't throw error if @noError=1]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_Print';
  EXEC tSQLt_testutil_test.[Create and fake tSQLt_testutil.PrepMultiRunLogTable];

  SELECT TOP(0)*
  INTO #Ignore
  FROM tSQLt_testutil.MultiRunLog AS MRL;

  
  INSERT INTO #Ignore
  EXEC tSQLt_testutil.CheckMultiRunResults;

  INSERT INTO tSQLt_testutil.MultiRunLog(Success,Skipped,Failure,Error)
  VALUES(0,0,0,0);

  INSERT INTO #Ignore
  EXEC tSQLt_testutil.CheckMultiRunResults;

  INSERT INTO tSQLt_testutil.MultiRunLog(Success,Skipped,Failure,Error)
  VALUES(0,0,2,3);

  INSERT INTO #Ignore
  EXEC tSQLt_testutil.CheckMultiRunResults;

  SELECT Message, Severity INTO #Actual FROM tSQLt.Private_Print_SpyProcedureLog;
  
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES('tSQLt execution with failures or errors detected.',0),
        ('MultiRunLog is empty.',0),
        ('MultiRunLog contains Run without tests.',0);
END
GO
CREATE PROCEDURE tSQLt_testutil_test.[ptest CheckMultiRunResults doesn't throw error if]
  @success INT = 0,
  @skipped INT = 0,
  @failed INT = 0,
  @errored INT = 0
AS
BEGIN
  EXEC tSQLt_testutil_test.[Create and fake tSQLt_testutil.PrepMultiRunLogTable];
  INSERT INTO tSQLt_testutil.MultiRunLog(Success,Skipped,Failure,Error)
  VALUES(@success,@skipped,@failed,@errored);

  SELECT TOP(0)*
  INTO #Actual
  FROM tSQLt_testutil.MultiRunLog AS MRL;

  EXEC tSQLt.ExpectNoException;
  
  INSERT INTO #Actual
  EXEC tSQLt_testutil.CheckMultiRunResults;
  
END
GO
CREATE PROCEDURE tSQLt_testutil_test.[test CheckMultiRunResults doesn't throw error if a success exists]
AS
BEGIN
  EXEC tSQLt_testutil_test.[ptest CheckMultiRunResults doesn't throw error if] @success=1;
END
GO
CREATE PROCEDURE tSQLt_testutil_test.[test CheckMultiRunResults doesn't throw error if a skip exists]
AS
BEGIN
  EXEC tSQLt_testutil_test.[ptest CheckMultiRunResults doesn't throw error if] @skipped=1;
END
GO
CREATE PROCEDURE tSQLt_testutil_test.[test LogMultiRunResult captures all results]
AS
BEGIN
  EXEC tSQLt_testutil_test.[Create and fake tSQLt_testutil.PrepMultiRunLogTable];
  EXEC tSQLt.FakeTable @TableName = 'tSQLt.TestResult', @Identity = 0, @ComputedColumns = 0, @Defaults = 0;
  INSERT INTO tSQLt.TestResult(Result)
  VALUES('Success'),('Success'),('Success'),('Success'),
        ('Skipped'),('Skipped'),('Skipped'),
        ('Failure'),('Failure'),
        ('Error');

  EXEC tSQLt.SuppressOutput @command = 'EXEC tSQLt_testutil.LogMultiRunResult @TestCaseSet=''MyTestingSet'';';

  SELECT *
  INTO #Actual
  FROM tSQLt_testutil.MultiRunLog AS MRL;

  SELECT TOP(0) 
      A.Success,
      A.Skipped,
      A.Failure,
      A.Error,
      A.TestCaseSet 
    INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  
  INSERT INTO #Expected
  VALUES(4,3,2,1,'MyTestingSet');

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROCEDURE tSQLt_testutil_test.[test tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses removes TestClass classifications]
AS
BEGIN
  EXEC ('CREATE SCHEMA tSQLtTestDummyA AUTHORIZATION [tSQLt.TestClass];');
  EXEC ('CREATE SCHEMA tSQLtTestDummyB AUTHORIZATION [tSQLt.TestClass];');
  EXEC ('CREATE SCHEMA tSQLtTestDummyC AUTHORIZATION [tSQLt.TestClass];');
  EXEC tSQLt.NewTestClass 'tSQLtTestDummyD';
  EXEC tSQLt.NewTestClass 'tSQLtTestDummyE';

  EXEC tSQLt_testutil.RemoveTestClassPropertyFromAllExistingClasses;

  SELECT Name
    INTO #Actual
    FROM tSQLt.TestClasses;
    
  EXEC tSQLt.AssertEmptyTable @TableName = '#Actual';
END;
GO
