EXEC tSQLt.NewTestClass 'DropAllClassesTests';
GO

CREATE PROC DropAllClassesTests.[test DropClass not called if no test classes exist]
AS
BEGIN
    EXEC tSQLt.FakeTable 'tSQLt.TestClasses';
    EXEC tSQLt.SpyProcedure 'tSQLt.DropClass';

    EXEC tSQLt.DropAllClasses;
    
    EXEC tSQLt.AssertEmptyTable 'tSQLt.DropClass_SpyProcedureLog';
END;
GO
CREATE PROC DropAllClassesTests.[test that one test class results in one call to DropClass]
AS
BEGIN
    EXEC tSQLt.FakeTable 'tSQLt.TestClasses';
    EXEC tSQLt.SpyProcedure 'tSQLt.DropClass';
    EXEC('INSERT INTO tSQLt.TestClasses (Name)
          VALUES  (''MyTestClass'');');

    SELECT ClassName = Name INTO #expected FROM tSQLt.TestClasses;

    EXEC tSQLt.DropAllClasses;

    SELECT ClassName INTO #actual FROM tSQLt.DropClass_SpyProcedureLog;

    EXEC tSQLt.AssertEqualsTable '#expected', '#actual';
END;
GO
CREATE PROC DropAllClassesTests.[test that multiple test classes are all sent to DropClass]
AS
BEGIN
    EXEC tSQLt.FakeTable 'tSQLt.TestClasses';
    EXEC tSQLt.SpyProcedure 'tSQLt.DropClass';
    EXEC('INSERT INTO tSQLt.TestClasses (Name)
          VALUES  (''MyTestClass1''),
                  (''MyTestClass2''),
                  (''MyTestClass3'');');

    SELECT ClassName = Name INTO #expected FROM tSQLt.TestClasses;

    EXEC tSQLt.DropAllClasses;

    SELECT ClassName INTO #actual FROM tSQLt.DropClass_SpyProcedureLog;

    EXEC tSQLt.AssertEqualsTable '#expected', '#actual';
END;
GO
