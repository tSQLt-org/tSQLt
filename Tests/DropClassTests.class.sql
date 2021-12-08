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
CREATE PROC DropClassTests.[test removes UDDTs after the objects that use them]
AS
BEGIN

    EXEC('CREATE SCHEMA MyTestClass;');
    EXEC('CREATE TYPE MyTestClass.UDT FROM INT;');
    EXEC('CREATE TABLE MyTestClass.tbl(i MyTestClass.UDT);');
    EXEC('CREATE PROCEDURE MyTestClass.ssp @i MyTestClass.UDT AS RETURN;');
    EXEC('CREATE FUNCTION MyTestClass.[IF](@i MyTestClass.UDT) RETURNS TABLE AS RETURN SELECT 0 X;');

    EXEC tSQLt.ExpectNoException;
    
    EXEC tSQLt.DropClass 'MyTestClass';
    
    IF(SCHEMA_ID('MyTestClass') IS NOT NULL)
    BEGIN    
      EXEC tSQLt.Fail 'DropClass did not drop MyTestClass';
    END
END;
GO
CREATE PROC DropClassTests.[test removes XML Schemata]
AS
BEGIN

    EXEC('CREATE SCHEMA MyTestClass;');
    EXEC('CREATE XML SCHEMA COLLECTION MyTestClass.TestXMLSchema
    AS''<xsd:schema xmlns:xsd="http://www.w3.org/2001/XMLSchema"><xsd:element name="testelement" /></xsd:schema>'';');

    EXEC tSQLt.ExpectNoException;
    
    EXEC tSQLt.DropClass 'MyTestClass';
    
    IF(SCHEMA_ID('MyTestClass') IS NOT NULL)
    BEGIN    
      EXEC tSQLt.Fail 'DropClass did not drop MyTestClass';
    END
END;
GO

CREATE PROC DropClassTests.[test removes class with spaces in name]
AS
BEGIN
    EXEC('CREATE SCHEMA [My Test Class];');

    EXEC tSQLt.ExpectNoException;
        EXEC tSQLt.DropClass 'My Test Class';
    
    IF(SCHEMA_ID('My Test Class') IS NOT NULL)
    BEGIN    
      EXEC tSQLt.Fail 'DropClass did not drop [My Test Class]';
    END
END;
GO

CREATE PROC DropClassTests.[test removes class if name is passed quoted]
AS
BEGIN
    EXEC('CREATE SCHEMA [My Test Class];');

    EXEC tSQLt.ExpectNoException;
        EXEC tSQLt.DropClass '[My Test Class]';
    
    IF(SCHEMA_ID('My Test Class') IS NOT NULL)
    BEGIN    
      EXEC tSQLt.Fail 'DropClass did not drop [My Test Class]';
    END
END;
GO

CREATE PROC DropClassTests.[test removes class if it contains a CLR TVF]
AS
BEGIN
    EXEC('CREATE SCHEMA MyTestClass;');

    EXEC('
CREATE FUNCTION MyTestClass.AClrTvf(@p1 NVARCHAR(MAX), @p2 NVARCHAR(MAX))
       RETURNS TABLE(id INT, val NVARCHAR(MAX))
       AS EXTERNAL NAME tSQLtTestUtilCLR.[tSQLtTestUtilCLR.ClrFunctions].AClrTvf;
    ');

    EXEC tSQLt.ExpectNoException;
        EXEC tSQLt.DropClass 'MyTestClass';
    
    IF(SCHEMA_ID('MyTestClass') IS NOT NULL)
    BEGIN    
      EXEC tSQLt.Fail 'DropClass did not drop MyTestClass';
    END
END;
GO
CREATE PROC DropClassTests.[test removes SSPs]
AS
BEGIN

    EXEC('CREATE SCHEMA MyTestClass;');
    EXEC('CREATE PROC MyTestClass.P AS RETURN;');

    EXEC tSQLt.ExpectNoException;
    
    EXEC tSQLt.DropClass 'MyTestClass';
    
    IF(SCHEMA_ID('MyTestClass') IS NOT NULL)
    BEGIN    
      EXEC tSQLt.Fail 'DropClass did not drop MyTestClass';
    END
END;
GO
CREATE PROC DropClassTests.[test removes VIEWs]
AS
BEGIN

    EXEC('CREATE SCHEMA MyTestClass;');
    EXEC('CREATE VIEW MyTestClass.V AS SELECT 0 X;');

    EXEC tSQLt.ExpectNoException;
    
    EXEC tSQLt.DropClass 'MyTestClass';
    
    IF(SCHEMA_ID('MyTestClass') IS NOT NULL)
    BEGIN    
      EXEC tSQLt.Fail 'DropClass did not drop MyTestClass';
    END
END;
GO
CREATE PROC DropClassTests.[test removes CLR SSPs]
AS
BEGIN

    EXEC('CREATE SCHEMA MyTestClass;');
    EXEC('CREATE PROC MyTestClass.CLRProcedure @expectedCommand NVARCHAR(MAX), @actualCommand NVARCHAR(MAX) AS EXTERNAL NAME tSQLtCLR.[tSQLtCLR.StoredProcedures].AssertResultSetsHaveSameMetaData;');

    EXEC tSQLt.ExpectNoException;
    
    EXEC tSQLt.DropClass 'MyTestClass';
    
    IF(SCHEMA_ID('MyTestClass') IS NOT NULL)
    BEGIN    
      EXEC tSQLt.Fail 'DropClass did not drop MyTestClass';
    END
END;
GO
CREATE PROC DropClassTests.[test removes Tables]
AS
BEGIN

    EXEC('CREATE SCHEMA MyTestClass;');
    EXEC('CREATE TABLE MyTestClass.U(i INT);');

    EXEC tSQLt.ExpectNoException;
    
    EXEC tSQLt.DropClass 'MyTestClass';
    
    IF(SCHEMA_ID('MyTestClass') IS NOT NULL)
    BEGIN    
      EXEC tSQLt.Fail 'DropClass did not drop MyTestClass';
    END
END;
GO
CREATE PROC DropClassTests.[test removes Inline Table-Valued Functions]
AS
BEGIN

    EXEC('CREATE SCHEMA MyTestClass;');
    EXEC('CREATE FUNCTION MyTestClass.[IF]() RETURNS TABLE AS RETURN SELECT 0 X;');

    EXEC tSQLt.ExpectNoException;
    
    EXEC tSQLt.DropClass 'MyTestClass';
    
    IF(SCHEMA_ID('MyTestClass') IS NOT NULL)
    BEGIN    
      EXEC tSQLt.Fail 'DropClass did not drop MyTestClass';
    END
END;
GO
CREATE PROC DropClassTests.[test removes Multi-Statement Table-Valued Functions]
AS
BEGIN

    EXEC('CREATE SCHEMA MyTestClass;');
    EXEC('CREATE FUNCTION MyTestClass.[TF]() RETURNS @T TABLE (i INT) BEGIN RETURN; END;');

    EXEC tSQLt.ExpectNoException;
    
    EXEC tSQLt.DropClass 'MyTestClass';
    
    IF(SCHEMA_ID('MyTestClass') IS NOT NULL)
    BEGIN    
      EXEC tSQLt.Fail 'DropClass did not drop MyTestClass';
    END
END;
GO
CREATE PROC DropClassTests.[test removes Scalar Functions]
AS
BEGIN

    EXEC('CREATE SCHEMA MyTestClass;');
    EXEC('CREATE FUNCTION MyTestClass.[FN]() RETURNS INT BEGIN RETURN 0; END;');

    EXEC tSQLt.ExpectNoException;
    
    EXEC tSQLt.DropClass 'MyTestClass';
    
    IF(SCHEMA_ID('MyTestClass') IS NOT NULL)
    BEGIN    
      EXEC tSQLt.Fail 'DropClass did not drop MyTestClass';
    END
END;
GO
    
CREATE PROC DropClassTests.[test removes tables referencing each other]
AS
BEGIN

    EXEC('CREATE SCHEMA MyTestClass;');
    EXEC('CREATE TABLE MyTestClass.TableA(I INT PRIMARY KEY);');
    EXEC('CREATE TABLE MyTestClass.TableB(I INT PRIMARY KEY REFERENCES MyTestClass.TableA(I));');
    EXEC('ALTER TABLE MyTestClass.TableA ADD FOREIGN KEY (I) REFERENCES MyTestClass.TableB(I);');

    EXEC tSQLt.ExpectNoException;
    
    EXEC tSQLt.DropClass 'MyTestClass';
    
    IF(SCHEMA_ID('MyTestClass') IS NOT NULL)
    BEGIN    
      EXEC tSQLt.Fail 'DropClass did not drop MyTestClass';
    END
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO

CREATE PROC DropClassTests.[test removes tables referencing each other with names that require quoting ( .')]
AS
BEGIN

    EXEC('CREATE SCHEMA [My.Tes''t Class];');
    EXEC('CREATE TABLE [My.Tes''t Class].[Ta.b''le A](I INT PRIMARY KEY);');
    EXEC('CREATE TABLE [My.Tes''t Class].[Ta.b''le B](I INT PRIMARY KEY CONSTRAINT [FK: Ta.b''le B] REFERENCES [My.Tes''t Class].[Ta.b''le A](I));');
    EXEC('ALTER TABLE [My.Tes''t Class].[Ta.b''le A] ADD CONSTRAINT [FK: Ta.b''le A] FOREIGN KEY (I) REFERENCES [My.Tes''t Class].[Ta.b''le B](I);');

    EXEC tSQLt.ExpectNoException;
    
    EXEC tSQLt.DropClass 'My.Tes''t Class';
    
    IF(SCHEMA_ID('My.Tes''t Class') IS NOT NULL)
    BEGIN    
      EXEC tSQLt.Fail 'DropClass did not drop [My.Tes''t Class]';
    END
END;
GO
CREATE PROC DropClassTests.[test drop class works if schema name is passed in unquoted]
AS
BEGIN

    EXEC('CREATE SCHEMA [My.Tes''t Class];');
    EXEC('CREATE TYPE [My.Tes''t Class].UDT FROM INT;');
    EXEC('CREATE TABLE [My.Tes''t Class].[Ta.b''le A](I INT PRIMARY KEY, OO [My.Tes''t Class].UDT);');
    EXEC('CREATE TABLE [My.Tes''t Class].[Ta.b''le B](I INT PRIMARY KEY CONSTRAINT [FK: Ta.b''le B] REFERENCES [My.Tes''t Class].[Ta.b''le A](I));');
    EXEC('CREATE XML SCHEMA COLLECTION [My.Tes''t Class].TestXMLSchema
    AS''<xsd:schema xmlns:xsd="http://www.w3.org/2001/XMLSchema"><xsd:element name="testelement" /></xsd:schema>'';');

    EXEC tSQLt.ExpectNoException;
    
    EXEC tSQLt.DropClass 'My.Tes''t Class';
    
    IF(SCHEMA_ID('My.Tes''t Class') IS NOT NULL)
    BEGIN    
      EXEC tSQLt.Fail 'DropClass did not drop [My.Tes''t Class]';
    END
END;
GO
CREATE PROC DropClassTests.[test drop class works if schema name is passed in quoted]
AS
BEGIN

    EXEC('CREATE SCHEMA [My.Tes''t Class];');
    EXEC('CREATE TYPE [My.Tes''t Class].UDT FROM INT;');
    EXEC('CREATE TABLE [My.Tes''t Class].[Ta.b''le A](I INT PRIMARY KEY, OO [My.Tes''t Class].UDT);');
    EXEC('CREATE TABLE [My.Tes''t Class].[Ta.b''le B](I INT PRIMARY KEY CONSTRAINT [FK: Ta.b''le B] REFERENCES [My.Tes''t Class].[Ta.b''le A](I));');
    EXEC('CREATE XML SCHEMA COLLECTION [My.Tes''t Class].TestXMLSchema
    AS''<xsd:schema xmlns:xsd="http://www.w3.org/2001/XMLSchema"><xsd:element name="testelement" /></xsd:schema>'';');

    EXEC tSQLt.ExpectNoException;
    
    EXEC tSQLt.DropClass '[My.Tes''t Class]';
    
    IF(SCHEMA_ID('My.Tes''t Class') IS NOT NULL)
    BEGIN    
      EXEC tSQLt.Fail 'DropClass did not drop [My.Tes''t Class]';
    END
END;
GO


