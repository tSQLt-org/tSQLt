EXEC tSQLt.NewTestClass 'AssertEmptyTableTests';
GO
CREATE TABLE AssertEmptyTableTests.TestTable(Id INT IDENTITY(1,1),Data1 VARCHAR(MAX));
GO
CREATE PROCEDURE AssertEmptyTableTests.[test fail is not called when table is empty]
AS
BEGIN
  EXEC tSQLt.FakeTable @TableName = 'AssertEmptyTableTests.TestTable', @Identity = 0, @ComputedColumns = 0, @Defaults = 0;
  
  EXEC tSQLt.AssertEmptyTable 'AssertEmptyTableTests.TestTable';
END;
GO
CREATE PROCEDURE AssertEmptyTableTests.[test handles odd names]
AS
BEGIN
  CREATE TABLE AssertEmptyTableTests.[TRANSACTION](Id INT);
  
  EXEC tSQLt.AssertEmptyTable 'AssertEmptyTableTests.TRANSACTION';
END;
GO
CREATE PROCEDURE AssertEmptyTableTests.[test fails if table does not exist]
AS
BEGIN
  EXEC tSQLt.RemoveObject @ObjectName = 'AssertEmptyTableTests.TestTable';
  EXEC tSQLt_testutil.AssertFailMessageEquals 'EXEC tSQLt.AssertEmptyTable ''AssertEmptyTableTests.TestTable'';', '''AssertEmptyTableTests.TestTable'' does not exist';
END;
GO
CREATE PROCEDURE AssertEmptyTableTests.[test fails if #table does not exist]
AS
BEGIN
  EXEC tSQLt_testutil.AssertFailMessageEquals 'EXEC tSQLt.AssertEmptyTable ''#doesnotexist'';', '''#doesnotexist'' does not exist';
END;
GO
CREATE PROCEDURE AssertEmptyTableTests.[test fails if table is not empty]
AS
BEGIN
  EXEC tSQLt.FakeTable @TableName = 'AssertEmptyTableTests.TestTable', @Identity = 0, @ComputedColumns = 0, @Defaults = 0;
  INSERT INTO AssertEmptyTableTests.TestTable(Data1)
  VALUES('testdata');

  EXEC tSQLt_testutil.assertFailCalled 'EXEC tSQLt.AssertEmptyTable ''AssertEmptyTableTests.TestTable'';';
END;
GO
CREATE PROCEDURE AssertEmptyTableTests.[test uses tSQLt.TableToText]
AS
BEGIN
  EXEC tSQLt.SpyProcedure 'tSQLt.TableToText','SET @txt = ''{TableToTextResult}'';';
  
  EXEC tSQLt.FakeTable @TableName = 'AssertEmptyTableTests.TestTable', @Identity = 0, @ComputedColumns = 0, @Defaults = 0;
  INSERT INTO AssertEmptyTableTests.TestTable(Data1)
  VALUES('testdata');

  DECLARE @ExpectedFailMessage NVARCHAR(MAX); 
  SET @ExpectedFailMessage =   
  '[AssertEmptyTableTests].[TestTable] was not empty:'+CHAR(13)+CHAR(10)+
  '{TableToTextResult}';

  EXEC tSQLt_testutil.AssertFailMessageEquals 'EXEC tSQLt.AssertEmptyTable ''AssertEmptyTableTests.TestTable'';', @ExpectedFailMessage;
END;
GO
CREATE PROCEDURE AssertEmptyTableTests.[test works with empty #temptable]
AS
BEGIN
  CREATE TABLE #actual(id INT IDENTITY(1,1),data1 NVARCHAR(MAX));

  EXEC tSQLt.AssertEmptyTable '#actual';
END;
GO
CREATE PROCEDURE AssertEmptyTableTests.[test works with non-empty #temptable]
AS
BEGIN
  CREATE TABLE #actual(id INT IDENTITY(1,1),data1 NVARCHAR(MAX));
  INSERT #actual(data1)
  VALUES('testdata');

  EXEC tSQLt_testutil.assertFailCalled 'EXEC tSQLt.AssertEmptyTable ''#actual'';';
END;
GO
--CREATE PROCEDURE AssertEmptyTableTests.[test works with empty quoted #temptable]
--AS
--BEGIN
--  CREATE TABLE #actual(id INT IDENTITY(1,1),data1 NVARCHAR(MAX));

--  EXEC tSQLt.AssertEmptyTable '[#actual]';
--END;
--GO
--CREATE PROCEDURE AssertEmptyTableTests.[test works with non-empty quoted #temptable]
--AS
--BEGIN
--  CREATE TABLE #actual(id INT IDENTITY(1,1),data1 NVARCHAR(MAX));
--  INSERT #actual(data1)
--  VALUES('testdata');

--  EXEC tSQLt_testutil.assertFailCalled 'EXEC tSQLt.AssertEmptyTable ''[#actual]'';';
--END;
--GO
CREATE PROCEDURE AssertEmptyTableTests.[test works with empty quotable #temptable]
AS
BEGIN
  CREATE TABLE [#act'l](id INT IDENTITY(1,1),data1 NVARCHAR(MAX));

  EXEC tSQLt.AssertEmptyTable '#act''l';
END;
GO
CREATE PROCEDURE AssertEmptyTableTests.[test works with non-empty quotable #temptable]
AS
BEGIN
  CREATE TABLE [#act'l](id INT IDENTITY(1,1),data1 NVARCHAR(MAX));
  INSERT [#act'l](data1)
  VALUES('testdata');

  EXEC tSQLt_testutil.assertFailCalled 'EXEC tSQLt.AssertEmptyTable ''#act''''l'';';
END;
GO
