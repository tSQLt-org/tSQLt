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

CREATE PROCEDURE AssertEqualsTableTests.[test two tables with no rows are equal]
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
 
CREATE PROCEDURE AssertEqualsTableTests.[test left table 1 row, right table 0 rows are not equal]
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

