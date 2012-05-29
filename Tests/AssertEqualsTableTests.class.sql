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
   INSERT INTO AssertEqualsTableTests.LeftTable VALUES (1);

   CREATE TABLE AssertEqualsTableTests.RightTable (i INT);
   INSERT INTO AssertEqualsTableTests.RightTable VALUES (2);
   
   CREATE TABLE AssertEqualsTableTests.ResultTable ([_m_] CHAR(1),i INT);
   INSERT INTO AssertEqualsTableTests.ResultTable ([_m_],i)
   SELECT '<',1;
   
   INSERT INTO AssertEqualsTableTests.ResultTable ([_m_],i)
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
   
   CREATE TABLE AssertEqualsTableTests.ResultTable ([_m_] CHAR(1),i INT);
   INSERT INTO AssertEqualsTableTests.ResultTable ([_m_],i)
   SELECT '=',1 UNION ALL
   SELECT '>',2 UNION ALL
   SELECT '<',3 UNION ALL
   SELECT '>',4 UNION ALL
   SELECT '<',5;
   
   DECLARE @ExpectedMessage NVARCHAR(MAX);
   EXEC tSQLt.TableToText @TableName = 'AssertEqualsTableTests.ResultTable', @OrderBy = '_m_',@txt = @ExpectedMessage OUTPUT;
   SET @ExpectedMessage = 'unexpected/missing resultset rows!'+CHAR(13)+CHAR(10)+@ExpectedMessage;

   EXEC tSQLt_testutil.AssertFailMessageEquals 
     'EXEC tSQLt.AssertEqualsTable ''AssertEqualsTableTests.LeftTable'', ''AssertEqualsTableTests.RightTable'';',
     @ExpectedMessage,
     'Fail was not called with expected message:';
END;
GO

CREATE PROCEDURE AssertEqualsTableTests.[test multiple ]
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


