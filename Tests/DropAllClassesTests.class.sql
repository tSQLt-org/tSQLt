EXEC tSQLt.NewTestClass 'DropAllClassesTests';
GO
CREATE PROC DropAllClassesTests.[SetUp]
AS
BEGIN
    EXEC tSQLt.FakeTable 'tSQLt.TestClasses';
    EXEC tSQLt.SpyProcedure 'tSQLt.DropClass';
END;
GO
CREATE PROC DropAllClassesTests.[test DropClass not called if no test classes exist]
AS
BEGIN
    EXEC tSQLt.DropAllClasses;
    
    EXEC tSQLt.AssertEmptyTable 'tSQLt.DropClass_SpyProcedureLog';

END;
GO
CREATE PROC DropAllClassesTests.[test that one test class results in one call to DropClass]
AS
BEGIN
    EXEC('INSERT INTO tSQLt.TestClasses (Name)
          VALUES  (''MyTestClass'');');

    EXEC tSQLt.DropAllClasses;

    SELECT TOP 0 * INTO #expected FROM tSQLt.DropClass_SpyProcedureLog;
    INSERT INTO #expected (ClassName)
    VALUES  ('MyTestClass');

    EXEC tSQLt.AssertEqualsTable '#expected', 'tSQLt.DropClass_SpyProcedureLog';
END;
GO
CREATE PROC DropAllClassesTests.[test that multiple test classes are all sent to DropClass]
AS
BEGIN
    EXEC('INSERT INTO tSQLt.TestClasses (Name)
          VALUES  (''MyTestClass1''),
                  (''MyTestClass2''),
                  (''MyTestClass3'');');

    EXEC tSQLt.DropAllClasses;

    SELECT TOP 0 * INTO #expected FROM tSQLt.DropClass_SpyProcedureLog;
    INSERT INTO #expected (ClassName)
    VALUES  ('MyTestClass1'),
            ('MyTestClass2'),
            ('MyTestClass3');

    EXEC tSQLt.AssertEqualsTable '#expected', 'tSQLt.DropClass_SpyProcedureLog';
END;
GO
