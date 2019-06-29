EXEC tSQLt.NewTestClass 'NewTestClassTests';
GO
CREATE PROC NewTestClassTests.[test NewTestClass creates a new schema]
AS
BEGIN
    EXEC tSQLt.NewTestClass 'MyTestClass';
    
    IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'MyTestClass')
    BEGIN
        EXEC tSQLt.Fail 'Should have created schema: MyTestClass';
    END;
END;
GO

CREATE PROC NewTestClassTests.[test NewTestClass calls tSQLt.DropClass]
AS
BEGIN
    EXEC tSQLt.SpyProcedure 'tSQLt.DropClass';
    
    EXEC tSQLt.NewTestClass 'MyTestClass';
    
    IF NOT EXISTS(SELECT * FROM tSQLt.DropClass_SpyProcedureLog WHERE ClassName = 'MyTestClass') 
    BEGIN
        EXEC tSQLt.Fail 'Should have called tSQLt.DropClass ''MyTestClass''';
    END
END;
GO

CREATE PROCEDURE NewTestClassTests.[test NewTestClass should throw an error if the schema exists and is not a test schema]
AS
BEGIN
    DECLARE @Err NVARCHAR(MAX); SET @Err = 'NO ERROR';
    EXEC('CREATE SCHEMA MySchema;');

    BEGIN TRY
      EXEC tSQLt.NewTestClass 'MySchema';
    END TRY
    BEGIN CATCH
      SET @Err = ERROR_MESSAGE();
    END CATCH
    
    DECLARE @ExpectedErr NVARCHAR(MAX) =
        '%Attempted to execute tSQLt.NewTestClass on ''MySchema'' which is an existing schema but not a test class%(Error originated in '+
        CASE WHEN CAST(SERVERPROPERTY('ProductMajorVersion')AS INT) >= 14 THEN 'tSQLt.' ELSE '' END+
        'Private_DisallowOverwritingNonTestSchema)%'
    IF @Err NOT LIKE @ExpectedErr
    BEGIN
        EXEC tSQLt.Fail 'Unexpected error message was: ', @Err;
    END;
END;
GO

CREATE PROCEDURE NewTestClassTests.[test the NewTestClass-"not a test class" error should be thrown by NewTestClass itself]
AS
BEGIN
    DECLARE @ErrProc NVARCHAR(MAX); SET @ErrProc = 'NO ERROR';
    EXEC('CREATE SCHEMA MySchema;');

    BEGIN TRY
      EXEC tSQLt.NewTestClass 'MySchema';
    END TRY
    BEGIN CATCH
      SET @ErrProc = ERROR_PROCEDURE();
    END CATCH
    
    DECLARE @ExpectedErrProc NVARCHAR(MAX) = CASE WHEN CAST(SERVERPROPERTY('ProductMajorVersion')AS INT) >= 14 THEN 'tSQLt.' ELSE '' END + 'NewTestClass'
    EXEC tSQLt.AssertEqualsString @ExpectedErrProc, @ErrProc;
END;
GO

CREATE PROCEDURE NewTestClassTests.[test NewTestClass should not drop an existing schema if it was not a test class]
AS
BEGIN
    EXEC('CREATE SCHEMA MySchema;');
    EXEC tSQLt.SpyProcedure 'tSQLt.DropClass';

    BEGIN TRY
      EXEC tSQLt.NewTestClass 'MySchema';
    END TRY
    BEGIN CATCH
    END CATCH
    
    IF EXISTS(SELECT * FROM tSQLt.DropClass_SpyProcedureLog WHERE ClassName = 'MySchema') 
    BEGIN
        EXEC tSQLt.Fail 'Should not have called tSQLt.DropClass ''MySchema''';
    END
END;
GO

CREATE PROCEDURE NewTestClassTests.[test NewTestClass can create schemas with the space character]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'My Test Class';
  
  IF SCHEMA_ID('My Test Class') IS NULL
  BEGIN
    EXEC tSQLt.Fail 'Should be able to create test class: My Test Class';
  END;
END;
GO

CREATE PROCEDURE NewTestClassTests.[test NewTestClass can create schemas with the other special characters]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'My!@#$%^&*()Test-+=|\<>,.?/Class';
  
  IF SCHEMA_ID('My!@#$%^&*()Test-+=|\<>,.?/Class') IS NULL
  BEGIN
    EXEC tSQLt.Fail 'Should be able to create test class: My!@#$%^&*()Test-+=|\<>,.?/Class';
  END;
END;
GO

CREATE PROCEDURE NewTestClassTests.[test NewTestClass can create schemas when the name is already quoted]
AS
BEGIN
  EXEC tSQLt.NewTestClass '[My Test Class]';
  
  IF SCHEMA_ID('My Test Class') IS NULL
  BEGIN
    EXEC tSQLt.Fail 'Should be able to create test class: My Test Class';
  END;
END;
GO

CREATE PROCEDURE NewTestClassTests.[test records a new test class in tSQLt.Private_NewTestClassList]
AS
BEGIN
  EXEC tSQLt.FakeTable @TableName = 'tSQLt.Private_NewTestClassList';
  EXEC tSQLt.NewTestClass 'My Test Class';

  SELECT ClassName
  INTO #Actual
  FROM tSQLt.Private_NewTestClassList;

  SELECT TOP(0) *
  INTO #Expected
  FROM #Actual;
  
  INSERT INTO #Expected
  VALUES('My Test Class');

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';    
END;
GO

CREATE PROCEDURE NewTestClassTests.[test records unquoted name in tSQLt.Private_NewTestClassList]
AS
BEGIN
  EXEC tSQLt.FakeTable @TableName = 'tSQLt.Private_NewTestClassList';
  EXEC tSQLt.NewTestClass '[My Test Class]';

  SELECT ClassName
  INTO #Actual
  FROM tSQLt.Private_NewTestClassList;

  SELECT TOP(0) *
  INTO #Expected
  FROM #Actual;
  
  INSERT INTO #Expected
  VALUES('My Test Class');

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';    
END;
GO

CREATE PROCEDURE NewTestClassTests.[test inserts name only once in tSQLt.Private_NewTestClassList]
AS
BEGIN
  EXEC tSQLt.FakeTable @TableName = 'tSQLt.Private_NewTestClassList';
  EXEC tSQLt.NewTestClass 'My Test Class';
  EXEC tSQLt.NewTestClass '[My Test Class]';
  EXEC tSQLt.NewTestClass 'My Test Class';
  EXEC tSQLt.NewTestClass '[My Test Class]';

  SELECT ClassName
  INTO #Actual
  FROM tSQLt.Private_NewTestClassList;

  SELECT TOP(0) *
  INTO #Expected
  FROM #Actual;
  
  INSERT INTO #Expected
  VALUES('My Test Class');

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';    
END;
GO

CREATE PROCEDURE NewTestClassTests.[test NewTestClass works if called on existing test class]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'My Test Class';
  EXEC tSQLt.NewTestClass 'My Test Class';
END;
GO

CREATE PROCEDURE NewTestClassTests.[test NewTestClass works if called on existing test class quoted]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'My Test Class';
  EXEC tSQLt.NewTestClass '[My Test Class]';
END;
GO

