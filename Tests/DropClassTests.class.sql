EXEC tSQLt.NewTestClass 'DropClassTests';
GO
CREATE PROC DropClassTests.test_dropClass_does_not_error_if_testcase_name_contains_spaces
AS
BEGIN
    DECLARE @ErrorRaised INT; SET @ErrorRaised = 0;

    EXEC('CREATE SCHEMA MyTestClass;');
    EXEC('CREATE PROC MyTestClass.[Test Case A ] AS RETURN 0;');
    
    BEGIN TRY
        EXEC tSQLt.DropClass 'MyTestClass';
    END TRY
    BEGIN CATCH
        SET @ErrorRaised = 1;
    END CATCH

    EXEC tSQLt.AssertEquals 0,@ErrorRaised,'Unexpected error during execution of DropClass'
    
    IF(SCHEMA_ID('MyTestClass') IS NOT NULL)
    BEGIN    
      EXEC tSQLt.Fail 'DropClass did not drop MyTestClass';
    END
END;
GO
CREATE PROC DropClassTests.[test removes UDDTs]
AS
BEGIN

    EXEC('CREATE SCHEMA MyTestClass;');
    EXEC('CREATE TYPE MyTestClass.UDT FROM INT;');

    EXEC tSQLt.ExpectNoException;
    
    EXEC tSQLt.DropClass 'MyTestClass';
    
    IF(SCHEMA_ID('MyTestClass') IS NOT NULL)
    BEGIN    
      EXEC tSQLt.Fail 'DropClass did not drop MyTestClass';
    END
END;
GO
CREATE PROC DropClassTests.[test removes UDDTs after tables]
AS
BEGIN

    EXEC('CREATE SCHEMA MyTestClass;');
    EXEC('CREATE TYPE MyTestClass.UDT FROM INT;');
    EXEC('CREATE TABLE MyTestClass.tbl(i MyTestClass.UDT);');

    EXEC tSQLt.ExpectNoException;
    
    EXEC tSQLt.DropClass 'MyTestClass';
    
    IF(SCHEMA_ID('MyTestClass') IS NOT NULL)
    BEGIN    
      EXEC tSQLt.Fail 'DropClass did not drop MyTestClass';
    END
END;
GO


