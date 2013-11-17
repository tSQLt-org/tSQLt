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
       ' RETURNS TABLE AS RETURN SELECT ''NUMERIC(25,7)'' AS TypeName WHERE @TypeId = 108 AND @Length = 17 AND @Precision = 30 AND @Scale = 2;');
  
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
       'SELECT ''NUMERIC(25,7)'' AS TypeName WHERE @TypeId = 108 AND @Precision = 10 AND @Scale = 1'+
       ' UNION ALL '+
       'SELECT ''VARCHAR(19)'' AS TypeName WHERE @TypeId = 231 AND @Length = -1 ;'
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
  EXEC('CREATE FUNCTION FakeFunctionTests.AFakeFunction(@p1 NVARCHAR(MAX),@p2 NVARCHAR(MAX)) RETURNS @r TABLE(id INT, val NVARCHAR(MAX)) BEGIN INSERT INTO @r VALUES(1,@p1),(2,@p2); RETURN; END;');

  EXEC FakeFunctionTests.[Assert TVF can be faked] @FunctionName = 'FakeFunctionTests.AFunction', @FakeFunctionName = 'FakeFunctionTests.AFakeFunction';
  END;
GO
CREATE PROCEDURE FakeFunctionTests.[test can fake MSTVF WITH ITVF]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.AFunction(@p1 NVARCHAR(MAX),@p2 NVARCHAR(MAX)) RETURNS @r TABLE(id INT,val NVARCHAR(MAX)) BEGIN RETURN; END;');
  EXEC('CREATE FUNCTION FakeFunctionTests.AFakeFunction(@p1 NVARCHAR(MAX),@p2 NVARCHAR(MAX)) RETURNS TABLE AS RETURN SELECT * FROM(VALUES(1,@p1),(2,@p2))r(id,val);');
  
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
  EXEC('CREATE FUNCTION FakeFunctionTests.AFunction(@p1 NVARCHAR(MAX),@p2 NVARCHAR(MAX)) RETURNS TABLE AS RETURN SELECT * FROM(VALUES(1,@p1))r(id,val) WHERE 1=0;');
  EXEC('CREATE FUNCTION FakeFunctionTests.AFakeFunction(@p1 NVARCHAR(MAX),@p2 NVARCHAR(MAX)) RETURNS @r TABLE(id INT, val NVARCHAR(MAX)) BEGIN INSERT INTO @r VALUES(1,@p1),(2,@p2); RETURN; END;');

  EXEC FakeFunctionTests.[Assert TVF can be faked] @FunctionName = 'FakeFunctionTests.AFunction', @FakeFunctionName = 'FakeFunctionTests.AFakeFunction';
  END;
GO
CREATE PROCEDURE FakeFunctionTests.[test can fake ITVF WITH ITVF]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.AFunction(@p1 NVARCHAR(MAX),@p2 NVARCHAR(MAX)) RETURNS TABLE AS RETURN SELECT * FROM(VALUES(1,@p1))r(id,val) WHERE 1=0;');
  EXEC('CREATE FUNCTION FakeFunctionTests.AFakeFunction(@p1 NVARCHAR(MAX),@p2 NVARCHAR(MAX)) RETURNS TABLE AS RETURN SELECT * FROM(VALUES(1,@p1),(2,@p2))r(id,val);');
  
  EXEC FakeFunctionTests.[Assert TVF can be faked] @FunctionName = 'FakeFunctionTests.AFunction', @FakeFunctionName = 'FakeFunctionTests.AFakeFunction';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test can fake ITVF WITH CLR TVF]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.AFunction(@p1 NVARCHAR(MAX),@p2 NVARCHAR(MAX)) RETURNS TABLE AS RETURN SELECT * FROM(VALUES(1,@p1))r(id,val) WHERE 1=0;');
  
  EXEC FakeFunctionTests.[Assert TVF can be faked] @FunctionName = 'FakeFunctionTests.AFunction', @FakeFunctionName = 'tSQLt_testutil.AClrTvf';
END;
GO
CREATE PROCEDURE FakeFunctionTests.[test can fake CLR TVF with MSTVF]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.AFakeFunction(@p1 NVARCHAR(MAX),@p2 NVARCHAR(MAX)) RETURNS @r TABLE(id INT, val NVARCHAR(MAX)) BEGIN INSERT INTO @r VALUES(1,@p1),(2,@p2); RETURN; END;');

  EXEC FakeFunctionTests.[Assert TVF can be faked] @FunctionName = 'tSQLt_testutil.AnEmptyClrTvf', @FakeFunctionName = 'FakeFunctionTests.AFakeFunction';
  END;
GO
CREATE PROCEDURE FakeFunctionTests.[test can fake CLR TVF WITH ITVF]
AS
BEGIN
  EXEC('CREATE FUNCTION FakeFunctionTests.AFakeFunction(@p1 NVARCHAR(MAX),@p2 NVARCHAR(MAX)) RETURNS TABLE AS RETURN SELECT * FROM(VALUES(1,@p1),(2,@p2))r(id,val);');
  
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

