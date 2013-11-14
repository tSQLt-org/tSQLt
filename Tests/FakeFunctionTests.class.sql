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
  EXEC('CREATE FUNCTION FakeFunctionTests.Fake() RETURNS NUMERIC(29,3) AS BEGIN RETURN 29.3; END;');
  
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
  EXEC('CREATE FUNCTION FakeFunctionTests.Fake(@p1 NUMERIC(10,2),@p2 VARCHAR(MAX)) RETURNS VARCHAR(MAX) AS BEGIN RETURN ''''; END;');
  
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
  
  INSERT INTO #Expected
  VALUES(1,108,13,25,7),(2,167,19,0,0);
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
  
END;



--TODO
-- passes parameters through
-- handles tvf and mstvf
-- errors if function not found
-- errors on parameter mismatch