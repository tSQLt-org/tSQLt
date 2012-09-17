GO
EXEC tSQLt.NewTestClass 'AssertEqualsTableTests';
GO

CREATE PROCEDURE AssertEqualsTableTests.[test left table doesn't exist results in failure]
AS
BEGIN
  CREATE TABLE AssertEqualsTableTests.RightTable (i INT);
  
  EXEC tSQLt_testutil.AssertFailMessageEquals
   'EXEC tSQLt.AssertEqualsTable ''AssertEqualsTableTests.DoesNotExist'', ''AssertEqualsTableTests.RightTable''',
   '''AssertEqualsTableTests.DoesNotExist'' does not exist',
   'Expected AssertEqualsTable to fail.';
END;
GO

CREATE PROCEDURE AssertEqualsTableTests.[test right table doesn't exist results in failure]
AS
BEGIN
  CREATE TABLE AssertEqualsTableTests.LeftTable (i INT);
  
  EXEC tSQLt_testutil.AssertFailMessageEquals
   'EXEC tSQLt.AssertEqualsTable ''AssertEqualsTableTests.LeftTable'', ''AssertEqualsTableTests.DoesNotExist''',
   '''AssertEqualsTableTests.DoesNotExist'' does not exist',
   'Expected AssertEqualsTable to fail.';
END;
GO

CREATE PROCEDURE AssertEqualsTableTests.[test two tables with no rows and same schema are equal]
AS
BEGIN
   CREATE TABLE AssertEqualsTableTests.LeftTable (i INT);
   CREATE TABLE AssertEqualsTableTests.RightTable (i INT);
   
   EXEC tSQLt.AssertEqualsTable 'AssertEqualsTableTests.LeftTable', 'AssertEqualsTableTests.RightTable';
END;
GO
 
CREATE PROCEDURE AssertEqualsTableTests.CopyResultTable
@InResultTableName NVARCHAR(MAX)
AS
BEGIN
  DECLARE @cmd NVARCHAR(MAX);
  SET @cmd = 'INSERT INTO AssertEqualsTableTests.ResultTable SELECT * FROM '+@InResultTableName;
  EXEC(@cmd);
END
GO
 
CREATE PROCEDURE AssertEqualsTableTests.[test left 1 row, right table 0 rows are not equal]
AS
BEGIN
   CREATE TABLE AssertEqualsTableTests.LeftTable (i INT);
   INSERT INTO AssertEqualsTableTests.LeftTable VALUES (1);
   CREATE TABLE AssertEqualsTableTests.RightTable (i INT);
   
   CREATE TABLE AssertEqualsTableTests.ResultTable ([_m_] CHAR(1),i INT);
   INSERT INTO AssertEqualsTableTests.ResultTable ([_m_],i)
   SELECT '<',1;
   DECLARE @ExpectedMessage NVARCHAR(MAX);
   EXEC tSQLt.TableToText @TableName = 'AssertEqualsTableTests.ResultTable', @OrderBy = '_m_',@txt = @ExpectedMessage OUTPUT;
   SET @ExpectedMessage = 'unexpected/missing resultset rows!'+CHAR(13)+CHAR(10)+@ExpectedMessage;

   EXEC tSQLt_testutil.AssertFailMessageEquals 
     'EXEC tSQLt.AssertEqualsTable ''AssertEqualsTableTests.LeftTable'', ''AssertEqualsTableTests.RightTable'';',
     @ExpectedMessage,
     'Fail was not called with expected message:';
   
END;
GO

CREATE PROCEDURE AssertEqualsTableTests.[test right table 1 row, left table 0 rows are not equal]
AS
BEGIN
   CREATE TABLE AssertEqualsTableTests.LeftTable (i INT);
   CREATE TABLE AssertEqualsTableTests.RightTable (i INT);
   INSERT INTO AssertEqualsTableTests.RightTable VALUES (1);
   
   CREATE TABLE AssertEqualsTableTests.ResultTable ([_m_] CHAR(1),i INT);
   INSERT INTO AssertEqualsTableTests.ResultTable ([_m_],i)
   SELECT '>',1;
   DECLARE @ExpectedMessage NVARCHAR(MAX);
   EXEC tSQLt.TableToText @TableName = 'AssertEqualsTableTests.ResultTable', @OrderBy = '_m_',@txt = @ExpectedMessage OUTPUT;
   SET @ExpectedMessage = 'unexpected/missing resultset rows!'+CHAR(13)+CHAR(10)+@ExpectedMessage;

   EXEC tSQLt_testutil.AssertFailMessageEquals 
     'EXEC tSQLt.AssertEqualsTable ''AssertEqualsTableTests.LeftTable'', ''AssertEqualsTableTests.RightTable'';',
     @ExpectedMessage,
     'Fail was not called with expected message:';
   
END;
GO

CREATE PROCEDURE AssertEqualsTableTests.[test one row in each table, but row is different]
AS
BEGIN
   CREATE TABLE AssertEqualsTableTests.LeftTable (i INT);
   INSERT INTO AssertEqualsTableTests.LeftTable VALUES (13);

   CREATE TABLE AssertEqualsTableTests.RightTable (i INT);
   INSERT INTO AssertEqualsTableTests.RightTable VALUES (42);
   
   CREATE TABLE AssertEqualsTableTests.ResultTable ([_m_] CHAR(1),i INT);
   INSERT INTO AssertEqualsTableTests.ResultTable ([_m_],i)
   SELECT '<',13;
   
   INSERT INTO AssertEqualsTableTests.ResultTable ([_m_],i)
   SELECT '>',42;
   DECLARE @ExpectedMessage NVARCHAR(MAX);
   EXEC tSQLt.TableToText @TableName = 'AssertEqualsTableTests.ResultTable', @OrderBy = '_m_',@txt = @ExpectedMessage OUTPUT;
   SET @ExpectedMessage = 'unexpected/missing resultset rows!'+CHAR(13)+CHAR(10)+@ExpectedMessage;

   EXEC tSQLt_testutil.AssertFailMessageEquals 
     'EXEC tSQLt.AssertEqualsTable ''AssertEqualsTableTests.LeftTable'', ''AssertEqualsTableTests.RightTable'';',
     @ExpectedMessage,
     'Fail was not called with expected message:';
   
END;
GO

CREATE PROCEDURE AssertEqualsTableTests.[test same single row in each table]
AS
BEGIN
   CREATE TABLE AssertEqualsTableTests.LeftTable (i INT);
   INSERT INTO AssertEqualsTableTests.LeftTable VALUES (1);

   CREATE TABLE AssertEqualsTableTests.RightTable (i INT);
   INSERT INTO AssertEqualsTableTests.RightTable VALUES (1);
   
   EXEC tSQLt.AssertEqualsTable 'AssertEqualsTableTests.LeftTable', 'AssertEqualsTableTests.RightTable';
   
END;
GO

CREATE PROCEDURE AssertEqualsTableTests.[test same multiple rows in each table]
AS
BEGIN
   CREATE TABLE AssertEqualsTableTests.LeftTable (i INT);
   INSERT INTO AssertEqualsTableTests.LeftTable VALUES (1);
   INSERT INTO AssertEqualsTableTests.LeftTable VALUES (2);

   CREATE TABLE AssertEqualsTableTests.RightTable (i INT);
   INSERT INTO AssertEqualsTableTests.RightTable VALUES (1);
   INSERT INTO AssertEqualsTableTests.RightTable VALUES (2);
   
   EXEC tSQLt.AssertEqualsTable 'AssertEqualsTableTests.LeftTable', 'AssertEqualsTableTests.RightTable';
   
END;
GO

CREATE PROCEDURE AssertEqualsTableTests.[test multiple rows with one mismatching row]
AS
BEGIN
   CREATE TABLE AssertEqualsTableTests.LeftTable (i INT);
   INSERT INTO AssertEqualsTableTests.LeftTable VALUES (1);
   INSERT INTO AssertEqualsTableTests.LeftTable VALUES (3);

   CREATE TABLE AssertEqualsTableTests.RightTable (i INT);
   INSERT INTO AssertEqualsTableTests.RightTable VALUES (1);
   INSERT INTO AssertEqualsTableTests.RightTable VALUES (2);
   
   CREATE TABLE AssertEqualsTableTests.ResultTable ([_m_] CHAR(1),i INT);
   INSERT INTO AssertEqualsTableTests.ResultTable ([_m_],i)
   SELECT '=',1 UNION ALL
   SELECT '<',3 UNION ALL
   SELECT '>',2;
   
   DECLARE @ExpectedMessage NVARCHAR(MAX);
   EXEC tSQLt.TableToText @TableName = 'AssertEqualsTableTests.ResultTable', @OrderBy = '_m_',@txt = @ExpectedMessage OUTPUT;
   SET @ExpectedMessage = 'unexpected/missing resultset rows!'+CHAR(13)+CHAR(10)+@ExpectedMessage;

   EXEC tSQLt_testutil.AssertFailMessageEquals 
     'EXEC tSQLt.AssertEqualsTable ''AssertEqualsTableTests.LeftTable'', ''AssertEqualsTableTests.RightTable'';',
     @ExpectedMessage,
     'Fail was not called with expected message:';
END;
GO

CREATE PROCEDURE AssertEqualsTableTests.[test compare table with two columns and no rows]
AS
BEGIN
   CREATE TABLE AssertEqualsTableTests.LeftTable (a INT, b INT);

   CREATE TABLE AssertEqualsTableTests.RightTable (a INT, b INT);
   
   CREATE TABLE AssertEqualsTableTests.ResultTable ([_m_] CHAR(1), a INT, b INT);
   EXEC tSQLt.AssertEqualsTable 'AssertEqualsTableTests.LeftTable', 'AssertEqualsTableTests.RightTable';
END;
GO

CREATE PROCEDURE AssertEqualsTableTests.[test same single row in each table with two columns]
AS
BEGIN
   CREATE TABLE AssertEqualsTableTests.LeftTable (a INT, b INT);
   INSERT INTO AssertEqualsTableTests.LeftTable VALUES (1, 2);

   CREATE TABLE AssertEqualsTableTests.RightTable (a INT, b INT);
   INSERT INTO AssertEqualsTableTests.RightTable VALUES (1, 2);
   
   EXEC tSQLt.AssertEqualsTable 'AssertEqualsTableTests.LeftTable', 'AssertEqualsTableTests.RightTable';
   
END;
GO

CREATE PROCEDURE AssertEqualsTableTests.[test same multiple rows in each table with two columns]
AS
BEGIN
   CREATE TABLE AssertEqualsTableTests.LeftTable (a INT, b INT);
   INSERT INTO AssertEqualsTableTests.LeftTable VALUES (1, 2);
   INSERT INTO AssertEqualsTableTests.LeftTable VALUES (3, 4);

   CREATE TABLE AssertEqualsTableTests.RightTable (a INT, b INT);
   INSERT INTO AssertEqualsTableTests.RightTable VALUES (1, 2);
   INSERT INTO AssertEqualsTableTests.RightTable VALUES (3, 4);
   
   EXEC tSQLt.AssertEqualsTable 'AssertEqualsTableTests.LeftTable', 'AssertEqualsTableTests.RightTable';
   
END;
GO

CREATE PROCEDURE AssertEqualsTableTests.[test multiple rows with one mismatching row with two columns]
AS
BEGIN
   CREATE TABLE AssertEqualsTableTests.LeftTable (a INT, b INT);
   INSERT INTO AssertEqualsTableTests.LeftTable VALUES (11, 12);
   INSERT INTO AssertEqualsTableTests.LeftTable VALUES (31, 32);

   CREATE TABLE AssertEqualsTableTests.RightTable (a INT, b INT);
   INSERT INTO AssertEqualsTableTests.RightTable VALUES (11, 12);
   INSERT INTO AssertEqualsTableTests.RightTable VALUES (21, 22);
   
   CREATE TABLE AssertEqualsTableTests.ResultTable ([_m_] CHAR(1), a INT, b INT);
   INSERT INTO AssertEqualsTableTests.ResultTable ([_m_], a, b)
   SELECT '=', 11, 12 UNION ALL
   SELECT '<', 31, 32 UNION ALL
   SELECT '>', 21, 22;
   
   DECLARE @ExpectedMessage NVARCHAR(MAX);
   EXEC tSQLt.TableToText @TableName = 'AssertEqualsTableTests.ResultTable', @OrderBy = '_m_',@txt = @ExpectedMessage OUTPUT;
   SET @ExpectedMessage = 'unexpected/missing resultset rows!'+CHAR(13)+CHAR(10)+@ExpectedMessage;

   EXEC tSQLt_testutil.AssertFailMessageEquals 
     'EXEC tSQLt.AssertEqualsTable ''AssertEqualsTableTests.LeftTable'', ''AssertEqualsTableTests.RightTable'';',
     @ExpectedMessage,
     'Fail was not called with expected message:';
END;
GO

CREATE PROCEDURE AssertEqualsTableTests.[test multiple rows with one mismatching row with mismatching column values in last column]
AS
BEGIN
   CREATE TABLE AssertEqualsTableTests.LeftTable (a INT, b INT);
   INSERT INTO AssertEqualsTableTests.LeftTable VALUES (11, 199);

   CREATE TABLE AssertEqualsTableTests.RightTable (a INT, b INT);
   INSERT INTO AssertEqualsTableTests.RightTable VALUES (11, 12);
   
   CREATE TABLE AssertEqualsTableTests.ResultTable ([_m_] CHAR(1), a INT, b INT);
   INSERT INTO AssertEqualsTableTests.ResultTable ([_m_], a, b)
   SELECT '<', 11, 199 UNION ALL
   SELECT '>', 11, 12;
   
   DECLARE @ExpectedMessage NVARCHAR(MAX);
   EXEC tSQLt.TableToText @TableName = 'AssertEqualsTableTests.ResultTable', @OrderBy = '_m_',@txt = @ExpectedMessage OUTPUT;
   SET @ExpectedMessage = 'unexpected/missing resultset rows!'+CHAR(13)+CHAR(10)+@ExpectedMessage;

   EXEC tSQLt_testutil.AssertFailMessageEquals 
     'EXEC tSQLt.AssertEqualsTable ''AssertEqualsTableTests.LeftTable'', ''AssertEqualsTableTests.RightTable'';',
     @ExpectedMessage,
     'Fail was not called with expected message:';
END;
GO

CREATE PROCEDURE AssertEqualsTableTests.[test multiple rows with one mismatching row with mismatching column values in first column]
AS
BEGIN
   CREATE TABLE AssertEqualsTableTests.LeftTable (a INT, b INT);
   INSERT INTO AssertEqualsTableTests.LeftTable VALUES (199, 12);

   CREATE TABLE AssertEqualsTableTests.RightTable (a INT, b INT);
   INSERT INTO AssertEqualsTableTests.RightTable VALUES (11, 12);
   
   CREATE TABLE AssertEqualsTableTests.ResultTable ([_m_] CHAR(1), a INT, b INT);
   INSERT INTO AssertEqualsTableTests.ResultTable ([_m_], a, b)
   SELECT '<', 199, 12 UNION ALL
   SELECT '>', 11, 12;
   
   DECLARE @ExpectedMessage NVARCHAR(MAX);
   EXEC tSQLt.TableToText @TableName = 'AssertEqualsTableTests.ResultTable', @OrderBy = '_m_',@txt = @ExpectedMessage OUTPUT;
   SET @ExpectedMessage = 'unexpected/missing resultset rows!'+CHAR(13)+CHAR(10)+@ExpectedMessage;

   EXEC tSQLt_testutil.AssertFailMessageEquals 
     'EXEC tSQLt.AssertEqualsTable ''AssertEqualsTableTests.LeftTable'', ''AssertEqualsTableTests.RightTable'';',
     @ExpectedMessage,
     'Fail was not called with expected message:';
END;
GO

--- At this point, AssertEqualsTable is tested enough we feel confident in using it in the remaining tests ---

CREATE PROCEDURE AssertEqualsTableTests.[test multiple rows with multiple mismatching rows]
AS
BEGIN
   CREATE TABLE AssertEqualsTableTests.LeftTable (i INT);
   INSERT INTO AssertEqualsTableTests.LeftTable VALUES (1);
   INSERT INTO AssertEqualsTableTests.LeftTable VALUES (3);
   INSERT INTO AssertEqualsTableTests.LeftTable VALUES (5);

   CREATE TABLE AssertEqualsTableTests.RightTable (i INT);
   INSERT INTO AssertEqualsTableTests.RightTable VALUES (1);
   INSERT INTO AssertEqualsTableTests.RightTable VALUES (2);
   INSERT INTO AssertEqualsTableTests.RightTable VALUES (4);
   
   CREATE TABLE AssertEqualsTableTests.ExpectedResultTable ([_m_] CHAR(1),i INT);
   INSERT INTO AssertEqualsTableTests.ExpectedResultTable ([_m_],i)
   SELECT '=',1 UNION ALL
   SELECT '>',2 UNION ALL
   SELECT '<',3 UNION ALL
   SELECT '>',4 UNION ALL
   SELECT '<',5;
   
   CREATE TABLE AssertEqualsTableTests.ActualResultTable ([_m_] CHAR(1),i INT);
   EXEC tSQLt.Private_CompareTables 'AssertEqualsTableTests.LeftTable', 'AssertEqualsTableTests.RightTable', 'AssertEqualsTableTests.ActualResultTable', 'i', '_m_';
   
   EXEC tSQLt.AssertEqualsTable 'AssertEqualsTableTests.ExpectedResultTable', 'AssertEqualsTableTests.ActualResultTable';
END;
GO

CREATE PROCEDURE AssertEqualsTableTests.[test same row in each table but different row counts]
AS
BEGIN
   CREATE TABLE AssertEqualsTableTests.LeftTable (i INT);
   INSERT INTO AssertEqualsTableTests.LeftTable VALUES (1);
   INSERT INTO AssertEqualsTableTests.LeftTable VALUES (3);
   INSERT INTO AssertEqualsTableTests.LeftTable VALUES (3);

   CREATE TABLE AssertEqualsTableTests.RightTable (i INT);
   INSERT INTO AssertEqualsTableTests.RightTable VALUES (1);
   INSERT INTO AssertEqualsTableTests.RightTable VALUES (3);
   
   CREATE TABLE AssertEqualsTableTests.ResultTable ([_m_] CHAR(1),i INT);
   INSERT INTO AssertEqualsTableTests.ResultTable ([_m_],i)
   SELECT '=',1 UNION ALL
   SELECT '=',3 UNION ALL
   SELECT '<',3;
   
   DECLARE @ExpectedMessage NVARCHAR(MAX);
   EXEC tSQLt.TableToText @TableName = 'AssertEqualsTableTests.ResultTable', @OrderBy = '_m_',@txt = @ExpectedMessage OUTPUT;
   SET @ExpectedMessage = 'unexpected/missing resultset rows!'+CHAR(13)+CHAR(10)+@ExpectedMessage;

   EXEC tSQLt_testutil.AssertFailMessageEquals 
     'EXEC tSQLt.AssertEqualsTable ''AssertEqualsTableTests.LeftTable'', ''AssertEqualsTableTests.RightTable'';',
     @ExpectedMessage,
     'Fail was not called with expected message:';
END;
GO

CREATE PROCEDURE AssertEqualsTableTests.[test same row in each table but different row counts with more rows]
AS
BEGIN
   CREATE TABLE AssertEqualsTableTests.LeftTable (i INT);
   INSERT INTO AssertEqualsTableTests.LeftTable VALUES (1);
   INSERT INTO AssertEqualsTableTests.LeftTable VALUES (1);
   INSERT INTO AssertEqualsTableTests.LeftTable VALUES (3);
   INSERT INTO AssertEqualsTableTests.LeftTable VALUES (3);
   INSERT INTO AssertEqualsTableTests.LeftTable VALUES (3);
   INSERT INTO AssertEqualsTableTests.LeftTable VALUES (3);
   INSERT INTO AssertEqualsTableTests.LeftTable VALUES (3);

   CREATE TABLE AssertEqualsTableTests.RightTable (i INT);
   INSERT INTO AssertEqualsTableTests.RightTable VALUES (1);
   INSERT INTO AssertEqualsTableTests.RightTable VALUES (1);
   INSERT INTO AssertEqualsTableTests.RightTable VALUES (1);
   INSERT INTO AssertEqualsTableTests.RightTable VALUES (1);
   INSERT INTO AssertEqualsTableTests.RightTable VALUES (3);
   INSERT INTO AssertEqualsTableTests.RightTable VALUES (3);
   INSERT INTO AssertEqualsTableTests.RightTable VALUES (3);
   
   CREATE TABLE AssertEqualsTableTests.ResultTable ([_m_] CHAR(1),i INT);
   INSERT INTO AssertEqualsTableTests.ResultTable ([_m_],i)
   SELECT '=',1 UNION ALL
   SELECT '=',1 UNION ALL
   SELECT '>',1 UNION ALL
   SELECT '>',1 UNION ALL
   SELECT '=',3 UNION ALL
   SELECT '=',3 UNION ALL
   SELECT '=',3 UNION ALL
   SELECT '<',3 UNION ALL
   SELECT '<',3;
   
   DECLARE @ExpectedMessage NVARCHAR(MAX);
   EXEC tSQLt.TableToText @TableName = 'AssertEqualsTableTests.ResultTable', @OrderBy = '_m_',@txt = @ExpectedMessage OUTPUT;
   SET @ExpectedMessage = 'unexpected/missing resultset rows!'+CHAR(13)+CHAR(10)+@ExpectedMessage;

   EXEC tSQLt_testutil.AssertFailMessageEquals 
     'EXEC tSQLt.AssertEqualsTable ''AssertEqualsTableTests.LeftTable'', ''AssertEqualsTableTests.RightTable'';',
     @ExpectedMessage,
     'Fail was not called with expected message:';
END;
GO


CREATE PROCEDURE AssertEqualsTableTests.[Create tables to compare]
 @DataType NVARCHAR(MAX),
 @Values NVARCHAR(MAX)
AS
BEGIN
  DECLARE @cmd NVARCHAR(MAX);
  
  SET @Cmd = '
   CREATE TABLE AssertEqualsTableTests.ResultTable ([_m_] CHAR(1), a <<DATATYPE>>);
   CREATE TABLE AssertEqualsTableTests.LeftTable (a <<DATATYPE>>);
   CREATE TABLE AssertEqualsTableTests.RightTable (a <<DATATYPE>>);

   INSERT INTO AssertEqualsTableTests.ResultTable ([_m_], a)
   SELECT e,v FROM(
    SELECT <<VALUES>>
   )X([=],[<],[>])
   UNPIVOT (v FOR e IN ([=],[<],[>])) AS u;
   ';
   
   SET @Cmd = REPLACE(@Cmd, '<<DATATYPE>>', @DataType);
   SET @Cmd = REPLACE(@Cmd, '<<VALUES>>', @Values);
   
   EXEC(@Cmd);
   
   
   INSERT INTO AssertEqualsTableTests.LeftTable (a)
   SELECT a FROM AssertEqualsTableTests.ResultTable WHERE [_m_] <> '>';

   INSERT INTO AssertEqualsTableTests.RightTable (a)
   SELECT a FROM AssertEqualsTableTests.ResultTable WHERE [_m_] <> '<';
END;
GO


CREATE PROCEDURE AssertEqualsTableTests.[Drop tables to compare]
AS
BEGIN
   DROP TABLE AssertEqualsTableTests.ResultTable;  
   DROP TABLE AssertEqualsTableTests.LeftTable;  
   DROP TABLE AssertEqualsTableTests.RightTable;  
END;
GO


CREATE PROCEDURE AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype]
 @DataType NVARCHAR(MAX),
 @Values NVARCHAR(MAX)
AS
BEGIN
   EXEC AssertEqualsTableTests.[Create tables to compare] @DataType, @Values;
   
   DECLARE @ExpectedMessage NVARCHAR(MAX);
   EXEC tSQLt.TableToText @TableName = 'AssertEqualsTableTests.ResultTable', @OrderBy = '_m_',@txt = @ExpectedMessage OUTPUT;
   SET @ExpectedMessage = 'unexpected/missing resultset rows!'+CHAR(13)+CHAR(10)+@ExpectedMessage;

   EXEC tSQLt_testutil.AssertFailMessageEquals 
     'EXEC tSQLt.AssertEqualsTable ''AssertEqualsTableTests.LeftTable'', ''AssertEqualsTableTests.RightTable'';',
     @ExpectedMessage,
     'Fail was not called with expected message for datatype ',
     @DataType,
     ':';
   
   EXEC AssertEqualsTableTests.[Drop tables to compare];
END;
GO

CREATE PROCEDURE AssertEqualsTableTests.[test considers NULL values identical]
AS
BEGIN
  SELECT *
    INTO AssertEqualsTableTests.NullCellTableCopy
    FROM tSQLt.Private_NullCellTable;
  
  EXEC tSQLt.AssertEqualsTable 'tSQLt.Private_NullCellTable', 'AssertEqualsTableTests.NullCellTableCopy';
END;
GO

CREATE PROCEDURE AssertEqualsTableTests.[test can handle integer data types]
AS
BEGIN
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'BIT', '1,1,0';
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'TINYINT', '10,11,12';
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'SMALLINT', '10,11,12';
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'INT', '10,11,12';
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'BIGINT', '10,11,12';
END;
GO

CREATE PROCEDURE AssertEqualsTableTests.[test can handle binary data types]
AS
BEGIN
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'BINARY(1)', '0x10,0x11,0x12';
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'VARBINARY(2)', '0x10,0x11,0x12';
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'VARBINARY(MAX)', '0x10,0x11,0x12';
END;
GO

CREATE PROCEDURE AssertEqualsTableTests.[test can handle char data types]
AS
BEGIN
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'CHAR(2)', '''10'',''11'',''12''';
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'NCHAR(2)', '''10'',''11'',''12''';
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'VARCHAR(2)', '''10'',''11'',''12''';
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'NVARCHAR(2)', '''10'',''11'',''12''';
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'VARCHAR(MAX)', '''10'',''11'',''12''';
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'NVARCHAR(MAX)', '''10'',''11'',''12''';
END;
GO

CREATE PROCEDURE AssertEqualsTableTests.[test can handle decimal data types]
AS
BEGIN
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'DECIMAL(10,2)', '0.10, 0.11, 0.12';
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'NUMERIC(10,2)', '0.10, 0.11, 0.12';
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'SMALLMONEY', '0.10, 0.11, 0.12';
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'MONEY', '0.10, 0.11, 0.12';
END;
GO

CREATE PROCEDURE AssertEqualsTableTests.[test can handle floating point data types]
AS
BEGIN
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'FLOAT', '1E-10, 1E-11, 1E-12';
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'REAL', '1E-10, 1E-11, 1E-12';
END;
GO

CREATE PROCEDURE AssertEqualsTableTests.[test can handle date data types]
AS
BEGIN
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'SMALLDATETIME', '''2012-01-01 12:00'',''2012-06-19 12:00'',''2012-10-25 12:00''';
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'DATETIME', '''2012-01-01 12:00'',''2012-06-19 12:00'',''2012-10-25 12:00''';
END;
GO

CREATE PROCEDURE AssertEqualsTableTests.[test can handle uniqueidentifier data type]
AS
BEGIN
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'UNIQUEIDENTIFIER', '''10101010-1010-1010-1010-101010101010'',''11111111-1111-1111-1111-111111111111'',''12121212-1212-1212-1212-121212121212''';
END;
GO

CREATE PROCEDURE AssertEqualsTableTests.[test can handle sql_variant data type]
AS
BEGIN
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'SQL_VARIANT', '10,11,12';
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'SQL_VARIANT', '''A'',''B'',''C''';
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'SQL_VARIANT', 'CAST(''2010-10-10'' AS DATETIME),CAST(''2011-11-11'' AS DATETIME),CAST(''2012-12-12'' AS DATETIME)';
END;
GO

CREATE PROCEDURE AssertEqualsTableTests.[test can handle byte ordered comparable CLR data type]
AS
BEGIN
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'tSQLt_testutil.DataTypeByteOrdered', '''10'',''11'',''12''';
END;
GO

CREATE PROCEDURE AssertEqualsTableTests.[Assert that AssertEqualsTable can NOT handle a datatype]
 @DataType NVARCHAR(MAX),
 @Values NVARCHAR(MAX)
AS
BEGIN
   EXEC AssertEqualsTableTests.[Create tables to compare] @DataType, @Values;
   
   DECLARE @Message NVARCHAR(MAX);
   SET @Message = 'No Error';

   BEGIN TRY
     EXEC tSQLt.AssertEqualsTable 'AssertEqualsTableTests.LeftTable', 'AssertEqualsTableTests.RightTable';
   END TRY
   BEGIN CATCH
     SELECT @Message = ERROR_MESSAGE();
   END CATCH
   
   EXEC tSQLt_testutil.AssertLike '%The table contains a datatype that is not supported for tSQLt.AssertEqualsTable%Please refer to http://tsqlt.org/user-guide/assertions/assertequalstable/ for a list of unsupported datatypes%',@Message;

   EXEC AssertEqualsTableTests.[Drop tables to compare];
END;
GO

CREATE PROCEDURE AssertEqualsTableTests.[test all unsupported data types]
AS
BEGIN
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can NOT handle a datatype] 'tSQLt_testutil.DataTypeNoEqual', '''10'',''11'',''12''';
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can NOT handle a datatype] 'tSQLt_testutil.DataTypeWithEqual', '''10'',''11'',''12''';
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can NOT handle a datatype] 'TEXT', '''10'',''11'',''12''';
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can NOT handle a datatype] 'NTEXT', '''10'',''11'',''12''';
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can NOT handle a datatype] 'IMAGE', '0x10,0x11,0x12';
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can NOT handle a datatype] 'XML', '''<X1 />'',''<X2 />'',''<X3 />''';
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can NOT handle a datatype] 'INT, c ROWVERSION', '0,0,0';--ROWVERSION is automatically valued
END;
GO

CREATE PROC AssertEqualsTableTests.[-test TODO]
AS
BEGIN
  EXEC tSQLt.Fail '
  
  - NTH: move tSQLt_testutil.AssertLike to tSQLt.AssertLike. Needs Tests...
  
  - !! needs now v4.0.30319 compiler!
  
  -- feature: open more than 1 tran before test execution
  ';
END;