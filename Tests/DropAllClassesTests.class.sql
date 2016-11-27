EXEC tSQLt.NewTestClass 'DropAllClassesTests';
GO
CREATE PROC DropAllClassesTests.[test that all test classes are dropped]
AS
BEGIN
    EXEC tSQLt.NewTestClass 'MyTestClass1';
    EXEC tSQLt.NewTestClass 'MyTestClass2';

    EXEC tSQLt.ExpectNoException;
    
    EXEC tSQLt.DropAllClasses;
    
    IF(SCHEMA_ID('MyTestClass1') IS NOT NULL)
      EXEC tSQLt.Fail 'DropAllClasses did not drop MyTestClass1';
    IF(SCHEMA_ID('MyTestClass2') IS NOT NULL)
      EXEC tSQLt.Fail 'DropAllClasses did not drop MyTestClass2';
END;
GO
CREATE PROC DropAllClassesTests.[test that schemas that are not test classes are not dropped]
AS
BEGIN
    EXEC('CREATE SCHEMA MyGenericSchema;');

    EXEC tSQLt.ExpectNoException;
    
    EXEC tSQLt.DropAllClasses;
    
    IF(SCHEMA_ID('MyGenericSchema') IS NULL)
      EXEC tSQLt.Fail 'DropAllClasses dropped MyGenericSchema';
END;
GO
