EXEC tSQLt.NewTestClass 'FakeFunctionTests_2008';
GO
CREATE TYPE FakeFunctionTests_2008.TableType1001 AS TABLE(SomeInt INT);
GO
CREATE PROCEDURE FakeFunctionTests_2008.[test can fake funktion with table-type parameter]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.AFunction(@p1 int, @p2 FakeFunctionTests_2008.TableType1001 READONLY, @p3 INT) RETURNS INT AS BEGIN RETURN 0; END;');
  EXEC('CREATE FUNCTION FakeFunctionTests.Fake(@p1 INT,@p2 FakeFunctionTests_2008.TableType1001 READONLY,@p3 INT) RETURNS INT AS BEGIN RETURN (SELECT SUM(SomeInt)+@p1+@p3 FROM @p2); END;');
  
  EXEC tSQLt.FakeFunction @FunctionName = 'FakeFunctionTests.AFunction', @FakeFunctionName = 'FakeFunctionTests.Fake';

  DECLARE @Actual INT;
  DECLARE @TableParameter FakeFunctionTests_2008.TableType1001;
  INSERT INTO @TableParameter(SomeInt)VALUES(10);
  INSERT INTO @TableParameter(SomeInt)VALUES(202);
  INSERT INTO @TableParameter(SomeInt)VALUES(3303);

  SET @Actual = FakeFunctionTests.AFunction(10000,@TableParameter,220000);
  EXEC tSQLt.AssertEqualsString @Expected = 233515, @Actual = @Actual;
END;
GO
