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
EXEC tSQLt.NewTestClass 'tSQLtclr_test';
GO

CREATE PROC tSQLtclr_test.[test AssertResultSetsHaveSameMetaData does not fail for two single bigint column result sets]
AS
BEGIN
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(1 AS BIGINT) A', 
        'SELECT CAST(1 AS BIGINT) A'; 
END;
GO

CREATE PROC tSQLtclr_test.[test AssertResultSetsHaveSameMetaData fails for a schema with integer and another with bigint]
AS
BEGIN
    EXEC tSQLt_testutil.assertFailCalled 
        'EXEC tSQLt.AssertResultSetsHaveSameMetaData ''SELECT CAST(1 AS INT) A'', ''SELECT CAST(1 AS BIGINT) A'';',
        'Expected tSQLt.Fail to be called when result sets have different meta data';
END;
GO

CREATE PROC tSQLtclr_test.[test AssertResultSetsHaveSameMetaData does not fail for identical single column result sets]
AS
BEGIN
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(1 AS INT) A', 
        'SELECT CAST(3 AS INT) A';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(1.02 AS DECIMAL(10,2)) A', 
        'SELECT CAST(3.05 AS DECIMAL(10,2)) A';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''ABC'' AS VARCHAR(15)) A', 
        'SELECT CAST(''XYZ'' AS VARCHAR(15)) A';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(''ABC'' AS VARCHAR(MAX)) A', 
        'SELECT CAST(''XYZ'' AS VARCHAR(MAX)) A';
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT NULL A', 
        'SELECT NULL A';
END;
GO

CREATE PROC tSQLtclr_test.[test AssertResultSetsHaveSameMetaData does not fail for identical multiple column result sets]
AS
BEGIN
    EXEC tSQLt.AssertResultSetsHaveSameMetaData
        'SELECT CAST(1 AS INT) A, CAST(''ABC'' AS VARCHAR(MAX)) B, CAST(13.9 AS DECIMAL(10,1)) C', 
        'SELECT CAST(3 AS INT) A, CAST(''DEFGH'' AS VARCHAR(MAX)) B, CAST(197.8 AS DECIMAL(10,1)) C';
END;
GO

CREATE PROC tSQLtclr_test.[test AssertResultSetsHaveSameMetaData fails when one result set has no rows]
AS
BEGIN
    EXEC tSQLt_testutil.assertFailCalled 
        'EXEC tSQLt.AssertResultSetsHaveSameMetaData
            ''SELECT CAST(1 AS INT) A'', 
            ''SELECT CAST(A AS INT) A FROM (SELECT CAST(3 AS INT) A) X WHERE 1 = 0''',
            'Expected tSQLt.Fail called when AssertResultSetsHaveSameMetaData called with result set which returns no metadata';
END;
GO

CREATE PROC tSQLtclr_test.[test AssertResultSetsHaveSameMetaData fails for differing single column result sets]
AS
BEGIN
    EXEC tSQLt_testutil.assertFailCalled 
        'EXEC tSQLt.AssertResultSetsHaveSameMetaData 
            ''SELECT CAST(1 AS INT) A'', 
            ''SELECT CAST(3 AS BIGINT) A'';',
            'Expected tSQLt.Fail called when AssertResultSetsHaveSameMetaData called with differing resultsets [INT and BIGINT]';
    EXEC tSQLt_testutil.assertFailCalled 
        'EXEC tSQLt.AssertResultSetsHaveSameMetaData 
            ''SELECT CAST(1.02 AS DECIMAL(10,2)) A'', 
            ''SELECT CAST(3.05 AS DECIMAL(10,9)) A'';',
            'Expected tSQLt.Fail called when AssertResultSetsHaveSameMetaData called with differing resultsets [DECIMAL(10,2) and DECIMAL(10,9)]';
    EXEC tSQLt_testutil.assertFailCalled 
        'EXEC tSQLt.AssertResultSetsHaveSameMetaData 
            ''SELECT CAST(''''ABC'''' AS VARCHAR(15)) A'', 
            ''SELECT CAST(''''XYZ'''' AS VARCHAR(23)) A'';',
            'Expected tSQLt.Fail called when AssertResultSetsHaveSameMetaData called with differing resultsets [VARCHAR(15) and VARCHAR(23)]';
    EXEC tSQLt_testutil.assertFailCalled 
        'EXEC tSQLt.AssertResultSetsHaveSameMetaData 
            ''SELECT CAST(''''ABC'''' AS VARCHAR(12)) A'', 
            ''SELECT CAST(''''XYZ'''' AS VARCHAR(MAX)) A'';',
            'Expected tSQLt.Fail called when AssertResultSetsHaveSameMetaData called with differing resultsets [VARCHAR(12) and VARCHAR(MAX)]';
    EXEC tSQLt_testutil.assertFailCalled 
        'EXEC tSQLt.AssertResultSetsHaveSameMetaData 
            ''SELECT CAST(''''ABC'''' AS VARCHAR(MAX)) A'', 
            ''SELECT CAST(''''XYZ'''' AS NVARCHAR(MAX)) A'';',
            'Expected tSQLt.Fail called when AssertResultSetsHaveSameMetaData called with differing resultsets [VARCHAR(MAX) and NVARCHAR(MAX)]';
    EXEC tSQLt_testutil.assertFailCalled 
        'EXEC tSQLt.AssertResultSetsHaveSameMetaData 
            ''SELECT NULL A'', 
            ''SELECT CAST(3 AS BIGINT) A'';',
            'Expected tSQLt.Fail called when AssertResultSetsHaveSameMetaData called with differing resultsets [NULL(INT) and BIGINT]';
END;
GO

CREATE PROC tSQLtclr_test.[test AssertResultSetsHaveSameMetaData fails for result sets with different number of columns]
AS
BEGIN
    EXEC tSQLt_testutil.assertFailCalled 
        'EXEC tSQLt.AssertResultSetsHaveSameMetaData 
            ''SELECT CAST(1 AS INT) A, CAST(''''ABC'''' AS VARCHAR(MAX)) B'', 
            ''SELECT CAST(1 AS INT) A'';',
            'Expected tSQLt.Fail called when AssertResultSetsHaveSameMetaData called with differing resultsets [INT,VARCHAR(MAX) and INT]';
    EXEC tSQLt_testutil.assertFailCalled 
        'EXEC tSQLt.AssertResultSetsHaveSameMetaData 
            ''SELECT CAST(1 AS INT) A'',
            ''SELECT CAST(1 AS INT) A, CAST(''''ABC'''' AS VARCHAR(MAX)) B'';',
            'Expected tSQLt.Fail called when AssertResultSetsHaveSameMetaData called with differing resultsets [INT and INT,VARCHAR(MAX)]';
END;
GO

CREATE PROC tSQLtclr_test.[test AssertResultSetsHaveSameMetaData fails if either command produces no result set]
AS
BEGIN
    EXEC tSQLt_testutil.assertFailCalled 
        'EXEC tSQLt.AssertResultSetsHaveSameMetaData 
            ''EXEC('''''''')'', 
            ''SELECT CAST(1 AS INT) A'';',
            'Expected tSQLt.Fail called when AssertResultSetsHaveSameMetaData called with first command returning no result set';
    EXEC tSQLt_testutil.assertFailCalled 
        'EXEC tSQLt.AssertResultSetsHaveSameMetaData 
            ''SELECT CAST(1 AS INT) A'',
            ''EXEC('''''''')'';',
            'Expected tSQLt.Fail called when AssertResultSetsHaveSameMetaData called with second command returning no result set';
    EXEC tSQLt_testutil.assertFailCalled 
        'EXEC tSQLt.AssertResultSetsHaveSameMetaData 
            ''EXEC('''''''')'',
            ''EXEC('''''''')'';',
            'Expected tSQLt.Fail called when AssertResultSetsHaveSameMetaData called with both commands returning no result set';
END;
GO

CREATE PROC tSQLtclr_test.[test AssertResultSetsHaveSameMetaData throws an exception if a command produces an exception]
AS
BEGIN
    DECLARE @err NVARCHAR(MAX);
    
    BEGIN TRY
        EXEC tSQLt.AssertResultSetsHaveSameMetaData 
            'SELECT 1/0 AS A', 
            'SELECT CAST(1 AS INT) A';
    END TRY
    BEGIN CATCH
        SET @err = ERROR_MESSAGE();
    END CATCH
    
    IF @err NOT LIKE '%Divide by zero%'
    BEGIN
        EXEC tSQLt.Fail 'Unexpected error message was: ', @err;
    END;
END;
GO

CREATE PROC tSQLtclr_test.[test AssertResultSetsHaveSameMetaData throws an exception if either command has a syntax error]
AS
BEGIN
    DECLARE @err NVARCHAR(MAX);
    
    BEGIN TRY
        EXEC tSQLt.AssertResultSetsHaveSameMetaData 
            'SELECT FROM WHERE', 
            'SELECT CAST(1 AS INT) A';
    END TRY
    BEGIN CATCH
        SET @err = ERROR_MESSAGE();
    END CATCH
    
    IF @err NOT LIKE '%Incorrect syntax near the keyword ''FROM''%'
    BEGIN
        EXEC tSQLt.Fail 'Unexpected error message was: ', @err;
    END;
END;
GO


CREATE PROC tSQLtclr_test.[test NewConnection executes a command in a new process]
AS
BEGIN
    EXEC tSQLt.NewConnection 'IF OBJECT_ID(''tSQLtclr_test.[SpidTable for test NewConnection executes a command in a new process]'') IS NOT NULL DROP TABLE tSQLtclr_test.[SpidTable for test NewConnection executes a command in a new process];';

    EXEC tSQLt.NewConnection 'SELECT @@SPID spid INTO tSQLtclr_test.[SpidTable for test NewConnection executes a command in a new process];';
    
    EXEC tSQLt.AssertObjectExists 'tSQLtclr_test.[SpidTable for test NewConnection executes a command in a new process]';
    
    DECLARE @otherSpid INT;
    SELECT @otherSpid = spid
      FROM tSQLtclr_test.[SpidTable for test NewConnection executes a command in a new process];

    IF ISNULL(@otherSpid, -1) = @@SPID
    BEGIN
        EXEC tSQLt.Fail 'Expected otherSpid to be different than @@SPID.';
    END;
    
    EXEC tSQLt.NewConnection 'IF OBJECT_ID(''tSQLtclr_test.[SpidTable for test NewConnection executes a command in a new process]'') IS NOT NULL DROP TABLE tSQLtclr_test.[SpidTable for test NewConnection executes a command in a new process];';
END;
GO

CREATE PROC tSQLtclr_test.[test CaptureOutput places the console output of a command into the CaptureOutputLog]
AS
BEGIN

  EXEC tSQLt.CaptureOutput 'print ''Catch Me if You Can!''';
  
  SELECT OutputText
  INTO #actual
  FROM tSQLt.CaptureOutputLog;
  
  SELECT TOP(0) *
  INTO #expected 
  FROM #actual;
  
  INSERT INTO #expected(OutputText)VALUES('Catch Me if You Can!' + CHAR(13) + CHAR(10));
  
  EXEC tSQLt.AssertEqualsTable '#expected','#actual';
  
END;
GO

CREATE PROC tSQLtclr_test.[test CaptureOutput, called with a command that does not print, results in no messages captured]
AS
BEGIN

  EXEC tSQLt.CaptureOutput 'DECLARE @i INT;';
  
  SELECT OutputText
  INTO #actual
  FROM tSQLt.CaptureOutputLog;
  
  SELECT TOP(0) *
  INTO #expected 
  FROM #actual;
  
  INSERT INTO #expected(OutputText)VALUES(NULL);
  
  EXEC tSQLt.AssertEqualsTable '#expected','#actual';
  
END;
GO

CREATE PROC tSQLtclr_test.[test CaptureOutput captures output that happens in between resultsets]
AS
BEGIN

  EXEC tSQLt.CaptureOutput 'PRINT ''AAAAA'';SELECT 1 a;PRINT ''BBBBB'';SELECT 1 b;PRINT ''CCCCC'';';
  
  DECLARE @OutputText NVARCHAR(MAX);
  SELECT @OutputText = OutputText FROM tSQLt.CaptureOutputLog;
  
  IF(@OutputText NOT LIKE 'AAAAA%BBBBB%CCCCC%')
    EXEC tSQLt.Fail 'Unexpected OutputText Captured! Expected to match ''AAAAA%BBBBB%CCCCC%'', was: ''',@OutputText,'''!';
  
END;
GO

CREATE PROC tSQLtclr_test.[test CaptureOutput can be executed twice with the different output]
AS
BEGIN

  EXEC tSQLt.CaptureOutput 'print ''Catch Me if You Can!''';
  EXEC tSQLt.CaptureOutput 'print ''Oh, you got me!!''';
  
  SELECT Id+0 Id,OutputText
  INTO #actual
  FROM tSQLt.CaptureOutputLog;
  
  SELECT TOP(0) *
  INTO #expected 
  FROM #actual;
  
  INSERT INTO #expected(Id,OutputText)VALUES(1,'Catch Me if You Can!' + CHAR(13) + CHAR(10) );
  INSERT INTO #expected(Id,OutputText)VALUES(2,'Oh, you got me!!' + CHAR(13) + CHAR(10) );
  
  EXEC tSQLt.AssertEqualsTable '#expected','#actual';
  
END;
GO


CREATE PROC tSQLtclr_test.[test CaptureOutput propogates an error]
AS
BEGIN

  DECLARE @msg NVARCHAR(MAX);
  SELECT @msg = 'No error message';
  
  BEGIN TRY
    EXEC tSQLt.CaptureOutput 'RAISERROR(''hello'', 16, 10);';
  END TRY
  BEGIN CATCH
    SET @msg = ERROR_MESSAGE();
  END CATCH
  
  IF @msg NOT LIKE '%hello%'
    EXEC tSQLt.Fail 'Expected the error message to be propogated up to SQL, but the message was: ', @msg;
END;
GO

CREATE PROC tSQLtclr_test.[test CaptureOutput can capture raiserror output with low severity]
AS
BEGIN

  EXEC tSQLt.CaptureOutput 'RAISERROR(''Catch Me if You Can!'', 0, 1);';

  SELECT OutputText
  INTO #actual
  FROM tSQLt.CaptureOutputLog;
  
  SELECT TOP(0) *
  INTO #expected 
  FROM #actual;
  
  INSERT INTO #expected(OutputText)VALUES('Catch Me if You Can!' + CHAR(13) + CHAR(10));
  
  EXEC tSQLt.AssertEqualsTable '#expected','#actual';
  
END;
GO

CREATE PROC tSQLtclr_test.[test SuppressOutput causes no output to be produced]
AS
BEGIN
  EXEC tSQLt.CaptureOutput 'EXEC tSQLt.SuppressOutput ''print ''''hello'''';'';';

  SELECT OutputText
  INTO #actual
  FROM tSQLt.CaptureOutputLog;
  
  SELECT TOP(0) *
  INTO #expected 
  FROM #actual;
  
  INSERT INTO #expected(OutputText)VALUES(NULL);
  
  EXEC tSQLt.AssertEqualsTable '#expected','#actual';
END;
GO

CREATE PROC tSQLtclr_test.[test tSQLt.Info.Version and tSQLt.Private::info() return the same value]
AS
BEGIN
  DECLARE @tSQLtVersion NVARCHAR(MAX); SET @tSQLtVersion = (SELECT Version FROM tSQLt.Info());
  DECLARE @tSQLtPrivateVersion NVARCHAR(MAX); SET @tSQLtPrivateVersion = (SELECT tSQLt.Private::Info());
  EXEC tSQLt.AssertEqualsString @tSQLtVersion, @tSQLtPrivateVersion;
END;
GO

CREATE PROC tSQLtclr_test.[test tSQLt.Info.ClrVersion and tSQLt.Private::info() return the same value]
AS
BEGIN
  DECLARE @tSQLtClrVersion NVARCHAR(MAX); SET @tSQLtClrVersion = (SELECT ClrVersion FROM tSQLt.Info());
  DECLARE @tSQLtPrivateVersion NVARCHAR(MAX); SET @tSQLtPrivateVersion = (SELECT tSQLt.Private::Info());
  EXEC tSQLt.AssertEqualsString @tSQLtClrVersion, @tSQLtPrivateVersion;
END;
GO

CREATE PROC tSQLtclr_test.[test tSQLt.Info.ClrVersion uses tSQLt.Private::info()]
AS
BEGIN
  DECLARE @tSQLtInfoText NVARCHAR(MAX); SET @tSQLtInfoText = OBJECT_DEFINITION(OBJECT_ID('tSQLt.Info'));
  IF( @tSQLtInfoText NOT LIKE '%ClrVersion = (SELECT tSQLt.Private::Info())%')
  BEGIN
    EXEC tSQLt.Fail 'Expected @tSQLtInfoText LIKE ''ClrVersion = (SELECT tSQLt.Private::Info())'' but was:',@tSQLtInfoText;
  END;
END;
GO
--ROLLBACK
