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
CREATE PROCEDURE tSQLt_testutil_test.[test DataTypeByteOrdered has constant ToString()]
AS
BEGIN
  DECLARE @inst1 tSQLt_testutil.DataTypeByteOrdered;
  DECLARE @inst1str NVARCHAR(MAX);
  DECLARE @inst2 tSQLt_testutil.DataTypeByteOrdered;
  DECLARE @inst2str NVARCHAR(MAX);

  SET @inst1 = '1';
  SET @inst2 = '2';
  
  SET @inst1str = @inst1.ToString();
  SET @inst2str = @inst2.ToString();
  
  EXEC tSQLt.AssertEqualsString @inst1str,@inst2str;
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

