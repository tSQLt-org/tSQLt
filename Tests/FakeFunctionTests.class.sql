EXEC tSQLt.NewTestClass 'FakeFunctionTests';
GO
CREATE PROCEDURE FakeFunctionTests.[test scalar function can be faked]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.AFunction() RETURNS INT AS BEGIN RETURN 13; END;');
  EXEC('CREATE FUNCTION FakeFunctionTests.Fake() RETURNS INT AS BEGIN RETURN 42; END;');
  
  EXEC tSQLt.FakeFunction @FunctionName = 'FakeFunctionTests.AFunction', @FakeFunctionName = 'FakeFunctionTests.Fake';
  
  DECLARE @Actual INT;SET @Actual = FakeFunctionTests.AFunction();
  
  EXEC tSQLt.AssertEquals @Expected = 42, @Actual = @Actual;
  
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test tSQLt.Private_GetFullTypeName is used for return type]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.AFunction() RETURNS NUMERIC(30,2) AS BEGIN RETURN 30.2; END;');
  EXEC('CREATE FUNCTION FakeFunctionTests.Fake() RETURNS NUMERIC(30,2) AS BEGIN RETURN 29.3; END;');
  
  EXEC tSQLt.RemoveObject @ObjectName = 'tSQLt.Private_GetFullTypeName';
  EXEC('CREATE FUNCTION tSQLt.Private_GetFullTypeName(@TypeId INT, @Length INT, @Precision INT, @Scale INT, @CollationName NVARCHAR(MAX))'+
       ' RETURNS TABLE AS RETURN SELECT ''NUMERIC(25,7)'' AS TypeName, 0 AS IsTableType WHERE @TypeId = 108 AND @Length = 17 AND @Precision = 30 AND @Scale = 2;');
  
  EXEC tSQLt.FakeFunction @FunctionName = 'FakeFunctionTests.AFunction', @FakeFunctionName = 'FakeFunctionTests.Fake';

  SELECT user_type_id, precision, scale 
    INTO #Actual
    FROM sys.parameters
   WHERE object_id = OBJECT_ID('FakeFunctionTests.AFunction')
     AND parameter_id = 0;

  SELECT TOP(0) *
  INTO #Expected
  FROM #Actual;
  
  INSERT INTO #Expected
  VALUES(108,25,7);
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
  
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test tSQLt.Private_GetFullTypeName is used to build parameter list]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.AFunction(@p1 NUMERIC(10,1),@p2 NVARCHAR(MAX)) RETURNS NVARCHAR(MAX) AS BEGIN RETURN ''''; END;');
  EXEC('CREATE FUNCTION FakeFunctionTests.Fake(@p1 NUMERIC(10,1),@p2 VARCHAR(MAX)) RETURNS VARCHAR(MAX) AS BEGIN RETURN ''''; END;');
  
  EXEC tSQLt.RemoveObject @ObjectName = 'tSQLt.Private_GetFullTypeName';
  EXEC('CREATE FUNCTION tSQLt.Private_GetFullTypeName(@TypeId INT, @Length INT, @Precision INT, @Scale INT, @CollationName NVARCHAR(MAX))'+
       ' RETURNS TABLE AS RETURN '+
       'SELECT ''NUMERIC(25,7)'' AS TypeName, 0 AS IsTableType WHERE @TypeId = 108 AND @Precision = 10 AND @Scale = 1'+
       ' UNION ALL '+
       'SELECT ''VARCHAR(19)'' AS TypeName, 0 AS IsTableType WHERE @TypeId = 231 AND @Length = -1 ;'
       );
  
  EXEC tSQLt.FakeFunction @FunctionName = 'FakeFunctionTests.AFunction', @FakeFunctionName = 'FakeFunctionTests.Fake';

  SELECT parameter_id,user_type_id,max_length,precision, scale 
    INTO #Actual
    FROM sys.parameters
   WHERE object_id = OBJECT_ID('FakeFunctionTests.AFunction')
     AND parameter_id > 0;

  SELECT TOP(0) *
  INTO #Expected
  FROM #Actual;
  
  INSERT INTO #Expected VALUES(1,108,13,25,7);
  INSERT INTO #Expected VALUES(2,167,19,0,0);
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
  
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test Parameters are passed through to fake funktion]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.AFunction(@p1 INT,@p2 NVARCHAR(MAX),@p3 DATETIME) RETURNS NVARCHAR(MAX) AS BEGIN RETURN ''''; END;');
  EXEC('CREATE FUNCTION FakeFunctionTests.Fake(@p1 INT,@p2 NVARCHAR(MAX),@p3 DATETIME) RETURNS NVARCHAR(MAX) AS BEGIN RETURN '+
                                              '''|''+CAST(@p1 AS NVARCHAR(MAX))+''|''+@p2+''|''+CONVERT(NVARCHAR(MAX),@p3,121)+''|''; END;');
  
  EXEC tSQLt.FakeFunction @FunctionName = 'FakeFunctionTests.AFunction', @FakeFunctionName = 'FakeFunctionTests.Fake';
  
  DECLARE @Actual NVARCHAR(MAX);
  SET @Actual = FakeFunctionTests.AFunction(392844,'AString','2013-12-11 10:09:08.070');
  
  EXEC tSQLt.AssertEqualsString @Expected = '|392844|AString|2013-12-11 10:09:08.070|', @Actual = @Actual;
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test errors when function doesn't exist]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.Fake() RETURNS NVARCHAR(MAX) AS BEGIN RETURN ''''; END;');

  EXEC tSQLt.ExpectException @ExpectedMessage = 'FakeFunctionTests.ANotExistingFunction does not exist!', @ExpectedSeverity = 16, @ExpectedState = 10;  

  EXEC tSQLt.FakeFunction @FunctionName = 'FakeFunctionTests.ANotExistingFunction', @FakeFunctionName = 'FakeFunctionTests.Fake';
  
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test errors when fake function doesn't exist]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.AFunction() RETURNS NVARCHAR(MAX) AS BEGIN RETURN ''''; END;');

  EXEC tSQLt.ExpectException @ExpectedMessage = 'FakeFunctionTests.ANotExistingFakeFunction does not exist!', @ExpectedSeverity = 16, @ExpectedState = 10;  

  EXEC tSQLt.FakeFunction @FunctionName = 'FakeFunctionTests.AFunction', @FakeFunctionName = 'FakeFunctionTests.ANotExistingFakeFunction';
  
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test Fake can be CLR function]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.AFunction(@p1 NVARCHAR(MAX), @p2 NVARCHAR(MAX)) RETURNS NVARCHAR(MAX) AS BEGIN RETURN ''''; END;');
  
  EXEC tSQLt.FakeFunction @FunctionName = 'FakeFunctionTests.AFunction', @FakeFunctionName = 'tSQLt_testutil.AClrSvf';
  
  DECLARE @Actual NVARCHAR(MAX);
  SET @Actual = FakeFunctionTests.AFunction('ABC','DEF');
  
  EXEC tSQLt.AssertEqualsString @Expected = 'AClrSvf:[ABC|DEF]', @Actual = @Actual;
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test Fakee can be CLR function]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.AFakeFunction(@p1 NVARCHAR(MAX), @p2 NVARCHAR(MAX)) RETURNS NVARCHAR(MAX) AS BEGIN RETURN @p1+''<fake>''+@p2; END;');
  
  EXEC tSQLt.FakeFunction @FunctionName = 'tSQLt_testutil.AClrSvf', @FakeFunctionName = 'FakeFunctionTests.AFakeFunction';
  
  DECLARE @Actual NVARCHAR(MAX);
  SET @Actual = tSQLt_testutil.AClrSvf('ABC','DEF');
  
  EXEC tSQLt.AssertEqualsString @Expected = 'ABC<fake>DEF', @Actual = @Actual;
END;
GO
CREATE FUNCTION FakeFunctionTests.[An SVF]() RETURNS NVARCHAR(MAX) AS BEGIN RETURN ''; END;
GO
CREATE FUNCTION FakeFunctionTests.[A MSTVF]() RETURNS @r TABLE(r NVARCHAR(MAX)) AS BEGIN RETURN; END;
GO
CREATE FUNCTION FakeFunctionTests.[An ITVF]() RETURNS TABLE AS RETURN SELECT ''r;
GO
CREATE TABLE FakeFunctionTests.[A Table] (id INT);
GO
CREATE PROCEDURE FakeFunctionTests.[Assert errors on function type mismatch]
  @FunctionName NVARCHAR(MAX),
  @FakeFunctionName NVARCHAR(MAX)
AS
BEGIN
  EXEC tSQLt.ExpectException @ExpectedMessage = 'Both parameters must contain the name of either scalar or table valued functions!', @ExpectedSeverity = 16, @ExpectedState = 10;  

  EXEC tSQLt.FakeFunction @FunctionName = @FunctionName, @FakeFunctionName = @FakeFunctionName;  
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test errors when function is SVF and fake is MSTVF]
AS
BEGIN
  EXEC FakeFunctionTests.[Assert errors on function type mismatch] 'FakeFunctionTests.[An SVF]', 'FakeFunctionTests.[A MSTVF]';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test errors when function is SVF and fake is ITVF]
AS
BEGIN
  EXEC FakeFunctionTests.[Assert errors on function type mismatch] 'FakeFunctionTests.[An SVF]', 'FakeFunctionTests.[An ITVF]';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test errors when function is SVF and fake is CLRTVF]
AS
BEGIN
  EXEC FakeFunctionTests.[Assert errors on function type mismatch] 'FakeFunctionTests.[An SVF]', 'tSQLt_testutil.AClrTvf';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test errors when function is SVF and fake is not a function]
AS
BEGIN
  EXEC FakeFunctionTests.[Assert errors on function type mismatch] 'FakeFunctionTests.[An SVF]', 'FakeFunctionTests.[A Table]';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[Assert TVF can be faked]
  @FunctionName NVARCHAR(MAX),
  @FakeFunctionName NVARCHAR(MAX)
AS
BEGIN
  EXEC tSQLt.FakeFunction @FunctionName = @FunctionName, @FakeFunctionName = @FakeFunctionName;

  CREATE TABLE #Actual(id INT, val NVARCHAR(MAX))
  
  EXEC('INSERT INTO #Actual SELECT * FROM '+@FunctionName+'(''ABC'',''DEF'');')
  
  SELECT TOP(0) *
  INTO #Expected
  FROM #Actual;
  
  INSERT INTO #Expected VALUES(1,'ABC');
  INSERT INTO #Expected VALUES(2,'DEF');
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test can fake MSTVF with MSTVF]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.AFunction(@p1 NVARCHAR(MAX),@p2 NVARCHAR(MAX)) RETURNS @r TABLE(id INT,val NVARCHAR(MAX)) BEGIN RETURN; END;');
  EXEC('CREATE FUNCTION FakeFunctionTests.AFakeFunction(@p1 NVARCHAR(MAX),@p2 NVARCHAR(MAX)) RETURNS @r TABLE(id INT, val NVARCHAR(MAX)) BEGIN INSERT INTO @r VALUES(1,@p1);INSERT INTO @r VALUES(2,@p2); RETURN; END;');

  EXEC FakeFunctionTests.[Assert TVF can be faked] @FunctionName = 'FakeFunctionTests.AFunction', @FakeFunctionName = 'FakeFunctionTests.AFakeFunction';
  END;
GO
CREATE PROCEDURE FakeFunctionTests.[test can fake MSTVF WITH ITVF]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.AFunction(@p1 NVARCHAR(MAX),@p2 NVARCHAR(MAX)) RETURNS @r TABLE(id INT,val NVARCHAR(MAX)) BEGIN RETURN; END;');
  EXEC('CREATE FUNCTION FakeFunctionTests.AFakeFunction(@p1 NVARCHAR(MAX),@p2 NVARCHAR(MAX)) RETURNS TABLE AS RETURN SELECT 1 id,@p1 val UNION ALL SELECT 2,@p2;');
  
  EXEC FakeFunctionTests.[Assert TVF can be faked] @FunctionName = 'FakeFunctionTests.AFunction', @FakeFunctionName = 'FakeFunctionTests.AFakeFunction';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test can fake MSTVF WITH CLR TVF]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.AFunction(@p1 NVARCHAR(MAX),@p2 NVARCHAR(MAX)) RETURNS @r TABLE(id INT,val NVARCHAR(MAX)) BEGIN RETURN; END;');
  
  EXEC FakeFunctionTests.[Assert TVF can be faked] @FunctionName = 'FakeFunctionTests.AFunction', @FakeFunctionName = 'tSQLt_testutil.AClrTvf';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test can fake ITVF with MSTVF]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.AFunction(@p1 NVARCHAR(MAX),@p2 NVARCHAR(MAX)) RETURNS TABLE AS RETURN  SELECT 1 id,@p1 val WHERE 1=0;');
  EXEC('CREATE FUNCTION FakeFunctionTests.AFakeFunction(@p1 NVARCHAR(MAX),@p2 NVARCHAR(MAX)) RETURNS @r TABLE(id INT, val NVARCHAR(MAX)) BEGIN INSERT INTO @r VALUES(1,@p1);INSERT INTO @r VALUES(2,@p2); RETURN; END;');

  EXEC FakeFunctionTests.[Assert TVF can be faked] @FunctionName = 'FakeFunctionTests.AFunction', @FakeFunctionName = 'FakeFunctionTests.AFakeFunction';
  END;
GO
CREATE PROCEDURE FakeFunctionTests.[test can fake ITVF WITH ITVF]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.AFunction(@p1 NVARCHAR(MAX),@p2 NVARCHAR(MAX)) RETURNS TABLE AS RETURN  SELECT 1 id,@p1 val WHERE 1=0;');
  EXEC('CREATE FUNCTION FakeFunctionTests.AFakeFunction(@p1 NVARCHAR(MAX),@p2 NVARCHAR(MAX)) RETURNS TABLE AS RETURN SELECT 1 id,@p1 val UNION ALL SELECT 2,@p2;');
  
  EXEC FakeFunctionTests.[Assert TVF can be faked] @FunctionName = 'FakeFunctionTests.AFunction', @FakeFunctionName = 'FakeFunctionTests.AFakeFunction';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test can fake ITVF WITH CLR TVF]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.AFunction(@p1 NVARCHAR(MAX),@p2 NVARCHAR(MAX)) RETURNS TABLE AS RETURN  SELECT 1 id,@p1 val WHERE 1=0;');
  
  EXEC FakeFunctionTests.[Assert TVF can be faked] @FunctionName = 'FakeFunctionTests.AFunction', @FakeFunctionName = 'tSQLt_testutil.AClrTvf';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test can fake CLR TVF with MSTVF]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.AFakeFunction(@p1 NVARCHAR(MAX),@p2 NVARCHAR(MAX)) RETURNS @r TABLE(id INT, val NVARCHAR(MAX)) BEGIN INSERT INTO @r VALUES(1,@p1);INSERT INTO @r VALUES(2,@p2); RETURN; END;');

  EXEC FakeFunctionTests.[Assert TVF can be faked] @FunctionName = 'tSQLt_testutil.AnEmptyClrTvf', @FakeFunctionName = 'FakeFunctionTests.AFakeFunction';
  END;
GO
CREATE PROCEDURE FakeFunctionTests.[test can fake CLR TVF WITH ITVF]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.AFakeFunction(@p1 NVARCHAR(MAX),@p2 NVARCHAR(MAX)) RETURNS TABLE AS RETURN  SELECT 1 id,@p1 val UNION ALL SELECT 2,@p2;');
  
  EXEC FakeFunctionTests.[Assert TVF can be faked] @FunctionName = 'tSQLt_testutil.AnEmptyClrTvf', @FakeFunctionName = 'FakeFunctionTests.AFakeFunction';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test can fake CLR TVF WITH CLR TVF]
AS
BEGIN
  EXEC FakeFunctionTests.[Assert TVF can be faked] @FunctionName = 'tSQLt_testutil.AnEmptyClrTvf', @FakeFunctionName = 'tSQLt_testutil.AClrTvf';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test errors when function is CLR SVF and fake is MSTVF]
AS
BEGIN
  EXEC FakeFunctionTests.[Assert errors on function type mismatch] 'tSQLt_testutil.AClrSvf', 'FakeFunctionTests.[A MSTVF]';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test errors when function is CLR SVF and fake is ITVF]
AS
BEGIN
  EXEC FakeFunctionTests.[Assert errors on function type mismatch] 'tSQLt_testutil.AClrSvf', 'FakeFunctionTests.[An ITVF]';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test errors when function is CLR SVF and fake is CLRTVF]
AS
BEGIN
  EXEC FakeFunctionTests.[Assert errors on function type mismatch] 'tSQLt_testutil.AClrSvf', 'tSQLt_testutil.AClrTvf';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test errors when function is CLR SVF and fake is not a function]
AS
BEGIN
  EXEC FakeFunctionTests.[Assert errors on function type mismatch] 'tSQLt_testutil.AClrSvf', 'FakeFunctionTests.[A Table]';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test errors when function is MSTVF and fake is SVF]
AS
BEGIN
  EXEC FakeFunctionTests.[Assert errors on function type mismatch] 'FakeFunctionTests.[A MSTVF]', 'FakeFunctionTests.[An SVF]';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test errors when function is MSTVF and fake is CLRSVF]
AS
BEGIN
  EXEC FakeFunctionTests.[Assert errors on function type mismatch] 'FakeFunctionTests.[A MSTVF]', 'tSQLt_testutil.AClrSvf';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test errors when function is MSTVF and fake is not a function]
AS
BEGIN
  EXEC FakeFunctionTests.[Assert errors on function type mismatch] 'FakeFunctionTests.[A MSTVF]', 'FakeFunctionTests.[A Table]';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test errors when function is ITVF and fake is SVF]
AS
BEGIN
  EXEC FakeFunctionTests.[Assert errors on function type mismatch] 'FakeFunctionTests.[An ITVF]', 'FakeFunctionTests.[An SVF]';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test errors when function is ITVF and fake is CLRSVF]
AS
BEGIN
  EXEC FakeFunctionTests.[Assert errors on function type mismatch] 'FakeFunctionTests.[An ITVF]', 'tSQLt_testutil.AClrSvf';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test errors when function is ITVF and fake is not a function]
AS
BEGIN
  EXEC FakeFunctionTests.[Assert errors on function type mismatch] 'FakeFunctionTests.[An ITVF]', 'FakeFunctionTests.[A Table]';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test errors when function is CLR TVF and fake is SVF]
AS
BEGIN
  EXEC FakeFunctionTests.[Assert errors on function type mismatch] 'tSQLt_testutil.AClrTvf', 'FakeFunctionTests.[An SVF]';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test errors when function is CLR TVF and fake is CLRSVF]
AS
BEGIN
  EXEC FakeFunctionTests.[Assert errors on function type mismatch] 'tSQLt_testutil.AClrTvf', 'tSQLt_testutil.AClrSvf';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test errors when function is CLR TVF and fake is not a function]
AS
BEGIN
  EXEC FakeFunctionTests.[Assert errors on function type mismatch] 'tSQLt_testutil.AClrTvf', 'FakeFunctionTests.[A Table]';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test errors when fakee is not a function]
AS
BEGIN
  EXEC FakeFunctionTests.[Assert errors on function type mismatch] 'FakeFunctionTests.[A Table]','FakeFunctionTests.[An SVF]';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[assert parameter missmatch causes error]
AS
BEGIN
  EXEC tSQLt.ExpectException @ExpectedMessage = 'Parameters of both functions must match! (This includes the return type for scalar functions.)', @ExpectedSeverity = 16, @ExpectedState = 10;  

  EXEC tSQLt.FakeFunction @FunctionName = 'FakeFunctionTests.AFunction', @FakeFunctionName = 'FakeFunctionTests.AFakeFunction';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test errors when parameters of the functions don't match in name]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.AFunction(@id INT) RETURNS NVARCHAR(MAX) AS BEGIN RETURN ''''; END;');
  EXEC('CREATE FUNCTION FakeFunctionTests.AFakeFunction(@di INT) RETURNS NVARCHAR(MAX) AS BEGIN RETURN ''''; END;');

  EXEC FakeFunctionTests.[assert parameter missmatch causes error];
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test errors when parameters of the functions don't match in max_length]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.AFunction(@id CHAR(2)) RETURNS NVARCHAR(MAX) AS BEGIN RETURN ''''; END;');
  EXEC('CREATE FUNCTION FakeFunctionTests.AFakeFunction(@id CHAR(3)) RETURNS NVARCHAR(MAX) AS BEGIN RETURN ''''; END;');

  EXEC FakeFunctionTests.[assert parameter missmatch causes error];
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test errors when parameters of the functions don't match in precision]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.AFunction(@id NUMERIC(10,1)) RETURNS NVARCHAR(MAX) AS BEGIN RETURN ''''; END;');
  EXEC('CREATE FUNCTION FakeFunctionTests.AFakeFunction(@id NUMERIC(11,1)) RETURNS NVARCHAR(MAX) AS BEGIN RETURN ''''; END;');

  EXEC FakeFunctionTests.[assert parameter missmatch causes error];
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test errors when parameters of the functions don't match in scale]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.AFunction(@id NUMERIC(10,1)) RETURNS NVARCHAR(MAX) AS BEGIN RETURN ''''; END;');
  EXEC('CREATE FUNCTION FakeFunctionTests.AFakeFunction(@id NUMERIC(10,2)) RETURNS NVARCHAR(MAX) AS BEGIN RETURN ''''; END;');

  EXEC FakeFunctionTests.[assert parameter missmatch causes error];
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test errors when parameters of the functions don't match in their order]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.AFunction(@id1 INT, @id2 INT) RETURNS NVARCHAR(MAX) AS BEGIN RETURN ''''; END;');
  EXEC('CREATE FUNCTION FakeFunctionTests.AFakeFunction(@id2 INT, @id1 INT) RETURNS NVARCHAR(MAX) AS BEGIN RETURN ''''; END;');

  EXEC FakeFunctionTests.[assert parameter missmatch causes error];
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test errors when type of return value for scalar functions doesn't match]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.AFunction() RETURNS NVARCHAR(10) AS BEGIN RETURN ''''; END;');
  EXEC('CREATE FUNCTION FakeFunctionTests.AFakeFunction() RETURNS NVARCHAR(20) AS BEGIN RETURN ''''; END;');

  EXEC FakeFunctionTests.[assert parameter missmatch causes error];
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test errors when both @FakeFunctionName and @FakeDataSource are passed]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.AFunction(@a int, @b int) RETURNS TABLE AS RETURN (SELECT @a AS one);');
  EXEC tSQLt.ExpectException @ExpectedMessage = 'Both @FakeFunctionName and @FakeDataSource are valued. Please use only one.', @ExpectedSeverity = 16, @ExpectedState = 10;
  EXEC tSQLt.FakeFunction @FunctionName = 'FakeFunctionTests.AFunction', @FakeFunctionName = 'FakeFunctionTests.AFunction', @FakeDataSource = 'select 1 one';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test errors when neither @FakeFunctionName nor @FakeDataSource are passed]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.AFunction(@a int, @b int) RETURNS TABLE AS RETURN (SELECT @a AS one);');
  EXEC tSQLt.ExpectException @ExpectedMessage = 'Either @FakeFunctionName or @FakeDataSource must be provided', @ExpectedSeverity = 16, @ExpectedState = 10;
  EXEC tSQLt.FakeFunction @FunctionName = 'FakeFunctionTests.AFunction';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test errors if function is a SVF and @FakeDataSource is used]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.AFunction() RETURNS NVARCHAR(10) AS BEGIN RETURN ''''; END;');

  EXEC tSQLt.ExpectException @ExpectedMessage = 'You can use @FakeDataSource only with Inline, Multi-Statement or CLR Table-Valued functions.', 
                             @ExpectedSeverity = 16, 
                             @ExpectedState = 10;  

  EXEC tSQLt.FakeFunction @FunctionName = 'FakeFunctionTests.AFunction', @FakeDataSource = 'select 1 as a';

END;
GO
CREATE PROCEDURE FakeFunctionTests.[test errors if function is a CLR SVF and @FakeDataSource is used]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.AFunction() RETURNS NVARCHAR(10) AS BEGIN RETURN ''''; END;');

  EXEC tSQLt.ExpectException @ExpectedMessage = 'You can use @FakeDataSource only with Inline, Multi-Statement or CLR Table-Valued functions.', 
                             @ExpectedSeverity = 16, 
                             @ExpectedState = 10;  

  EXEC tSQLt.FakeFunction @FunctionName = 'FakeFunctionTests.AFunction', @FakeDataSource = 'select 1 as a';

END;
GO
CREATE PROCEDURE FakeFunctionTests.[test can fake Inline table function using a temp table as fake data source]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.AFunction() RETURNS TABLE AS RETURN (SELECT  1 AS one);');

  CREATE TABLE #expected (a CHAR(1));
  INSERT INTO #expected VALUES('a');

  EXEC tSQLt.FakeFunction @FunctionName = 'FakeFunctionTests.AFunction', @FakeDataSource = '#expected';

  SELECT * INTO #actual FROM FakeFunctionTests.AFunction();

  EXEC tSQLt.AssertEqualsTable '#expected', '#actual';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test can fake multi-statement table function using a temp table as fake data source]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.AFunction(@a int) RETURNS @t TABLE (a int) AS BEGIN;
 INSERT INTO @t (a) VALUES (0) RETURN; END;');

  CREATE TABLE #expected (a CHAR(1));
  INSERT INTO #expected VALUES('a');

  EXEC tSQLt.FakeFunction @FunctionName = 'FakeFunctionTests.AFunction', @FakeDataSource = '#expected';

  SELECT * INTO #actual FROM FakeFunctionTests.AFunction(123);

  EXEC tSQLt.AssertEqualsTable '#expected', '#actual';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test can fake CLR table function using a temp table as fake data source]
AS
BEGIN

  CREATE TABLE #expected (a CHAR(1));
  INSERT INTO #expected VALUES('a');

  EXEC tSQLt.FakeFunction @FunctionName = 'tSQLt_testutil.AClrTvf', @FakeDataSource = '#expected';

  SELECT * INTO #actual FROM tSQLt_testutil.AClrTvf('', '');

  EXEC tSQLt.AssertEqualsTable '#expected', '#actual';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test can fake function with one parameter]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.AFunction(@a int) RETURNS TABLE AS RETURN (SELECT @a AS one);');

  CREATE TABLE #expected (a INT);
  INSERT INTO #expected VALUES(1);

  EXEC tSQLt.FakeFunction @FunctionName = 'FakeFunctionTests.AFunction', @FakeDataSource = '#expected';

  SELECT * INTO #actual FROM FakeFunctionTests.AFunction(123);

  EXEC tSQLt.AssertEqualsTable '#expected', '#actual';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test can fake function with multiple parameters]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.AFunction(@a int, @b int, @c char(1)) RETURNS TABLE AS RETURN (SELECT @a AS one);');

  CREATE TABLE #expected (a INT);
  INSERT INTO #expected VALUES(1);

  EXEC tSQLt.FakeFunction @FunctionName = 'FakeFunctionTests.AFunction', @FakeDataSource = '#expected';

  SELECT * INTO #actual FROM FakeFunctionTests.AFunction(123, 321, 'a');

  EXEC tSQLt.AssertEqualsTable '#expected', '#actual';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test can fake function with VALUES clause as fake data source]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.AFunction() RETURNS TABLE AS RETURN (SELECT 777 AS a);');

  CREATE TABLE #expected (a INT);
  INSERT INTO #expected VALUES(1);

  EXEC tSQLt.FakeFunction @FunctionName = 'FakeFunctionTests.AFunction', @FakeDataSource = '(VALUES(1)) a(a)';

  SELECT * INTO #actual FROM FakeFunctionTests.AFunction();

  EXEC tSQLt.AssertEqualsTable '#expected', '#actual';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test can fake function with two part named table as fake data source]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.AFunction() RETURNS TABLE AS RETURN (SELECT 777 AS a);');

  CREATE TABLE #expected (a INT);
  INSERT INTO #expected VALUES(1);

  SELECT * INTO FakeFunctionTests.SomeTable FROM #expected;


  EXEC tSQLt.FakeFunction @FunctionName = 'FakeFunctionTests.AFunction', @FakeDataSource = 'FakeFunctionTests.SomeTable';

  SELECT * INTO #actual FROM FakeFunctionTests.AFunction();

  EXEC tSQLt.AssertEqualsTable '#expected', '#actual';
END;
GO
CREATE TYPE FakeFunctionTests.TableType1001 AS TABLE(SomeInt INT);
GO
CREATE PROCEDURE FakeFunctionTests.[test can fake function with table-type parameter]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.AFunction(@p1 int, @p2 FakeFunctionTests.TableType1001 READONLY, @p3 INT) RETURNS INT AS BEGIN RETURN 0; END;');
  EXEC('CREATE FUNCTION FakeFunctionTests.Fake(@p1 INT,@p2 FakeFunctionTests.TableType1001 READONLY,@p3 INT) RETURNS INT AS BEGIN RETURN (SELECT SUM(SomeInt)+@p1+@p3 FROM @p2); END;');
  
  EXEC tSQLt.FakeFunction @FunctionName = 'FakeFunctionTests.AFunction', @FakeFunctionName = 'FakeFunctionTests.Fake';

  DECLARE @Actual INT;
  DECLARE @TableParameter FakeFunctionTests.TableType1001;
  INSERT INTO @TableParameter(SomeInt)VALUES(10);
  INSERT INTO @TableParameter(SomeInt)VALUES(202);
  INSERT INTO @TableParameter(SomeInt)VALUES(3303);

  SET @Actual = FakeFunctionTests.AFunction(10000,@TableParameter,220000);
  EXEC tSQLt.AssertEqualsString @Expected = 233515, @Actual = @Actual;
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test can fake with derived table]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.AFunction() RETURNS TABLE AS RETURN (SELECT 777 AS a);');

  CREATE TABLE #expected (a INT);
  INSERT INTO #expected VALUES(1);

  CREATE TABLE #actual (a INT)

  EXEC tSQLt.FakeFunction @FunctionName = 'FakeFunctionTests.AFunction', @FakeDataSource = 'select 1 as a';

  INSERT INTO #actual SELECT * FROM FakeFunctionTests.AFunction();

  EXEC tSQLt.AssertEqualsTable '#expected', '#actual';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test can fake with data source table that starts with select]
AS
BEGIN
  DECLARE @Expected INT = 1;
  DECLARE @Actual INT = 0;

  EXEC('CREATE FUNCTION FakeFunctionTests.AFunction() RETURNS TABLE AS RETURN (SELECT 777 AS a);');

  CREATE TABLE SelectFakeFunctionTestsTable (a int);
  INSERT INTO SelectFakeFunctionTestsTable VALUES (@Expected);

  EXEC tSQLt.FakeFunction @FunctionName = 'FakeFunctionTests.AFunction', 
                         @FakeDataSource = N'SelectFakeFunctionTestsTable';
  
  SELECT @Actual = a FROM FakeFunctionTests.AFunction()
  EXEC tSQLt.AssertEquals @Expected, @Actual;

END;
GO
CREATE PROCEDURE FakeFunctionTests.[test Private_PrepareFakeFunctionOutputTable returns table with VALUES]
AS
BEGIN

  DECLARE @NewTable sysname;

  CREATE TABLE #Expected (a int);
  INSERT INTO #Expected VALUES(1);
  
  EXEC tSQLt.Private_PrepareFakeFunctionOutputTable '(VALUES (1)) a(a)', @NewTable OUTPUT;

  EXEC tSQLt.AssertEqualsTable '#Expected', @NewTable;

END;
GO
CREATE PROCEDURE FakeFunctionTests.[test Private_PrepareFakeFunctionOutputTable returns table with SELECT query]
AS
BEGIN

  DECLARE @NewTable NVARCHAR(MAX);

  EXEC tSQLt.Private_PrepareFakeFunctionOutputTable 'SELECT 1013 AS a', @NewTable OUTPUT;

  EXEC('SELECT TOP(0)A.* INTO FakeFunctionTests.Expected FROM '+@NewTable+' A RIGHT JOIN '+@NewTable+' ON 0=1;'); 
  INSERT INTO FakeFunctionTests.Expected VALUES(1013);

  EXEC tSQLt.AssertEqualsTable 'FakeFunctionTests.Expected', @NewTable;
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test Private_PrepareFakeFunctionOutputTable creates snapshot table in passed in schema]
AS
BEGIN
  DECLARE @NewTable NVARCHAR(MAX);

  EXEC('CREATE SCHEMA [a random schema];');

  EXEC tSQLt.Private_PrepareFakeFunctionOutputTable @FakeDataSource = 'SELECT 1013 AS a',@SchemaName = 'a random schema', @NewTableName = @NewTable OUT;

  SELECT SCHEMA_NAME(O.schema_id) SchemaName INTO #Actual FROM sys.objects O WHERE O.object_id = OBJECT_ID(@NewTable);

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES('a random schema');

  EXEC tSQLt.AssertEqualsTable #Expected, #Actual
END;
GO
