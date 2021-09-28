:SETVAR DacpacTargetDb tSQLt_dacpac
---Build+
GO
EXEC tSQLt.NewTestClass 'Facade_Dacpac_Tests';
GO
CREATE PROCEDURE Facade_Dacpac_Tests.[test dacpac contains all objects]
AS
BEGIN
  SELECT O.name, CASE WHEN O.type_desc LIKE '%STORED[_]PROCEDURE' THEN 'STORED_PROCEDURE' ELSE O.type_desc END type_desc
    INTO #Expected
    FROM sys.objects O 
   WHERE O.schema_id = SCHEMA_ID('tSQLt')
     AND UPPER(O.name) NOT LIKE 'PRIVATE%'
     AND O.type NOT IN ('D', 'PK','UQ')

  SELECT O.name, CASE WHEN O.type_desc LIKE '%STORED[_]PROCEDURE' THEN 'STORED_PROCEDURE' ELSE O.type_desc END type_desc
    INTO #Actual
    FROM $(DacpacTargetDb).sys.objects O 
   WHERE O.schema_id = SCHEMA_ID('tSQLt')
     AND UPPER(O.name) NOT LIKE 'PRIVATE%'
     AND O.type NOT IN ('D', 'PK','UQ')
     
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROCEDURE Facade_Dacpac_Tests.[test dacpac contains all tSQLt users]
AS
BEGIN
  SELECT SDP.name, SDP.type_desc
    INTO #Expected
    FROM sys.database_principals SDP
   WHERE UPPER(SDP.name) LIKE ('%TSQLT%')

  SELECT SDP.name, SDP.type_desc
    INTO #Actual
    FROM $(DacpacTargetDb).sys.database_principals SDP
   WHERE UPPER(SDP.name) LIKE ('%TSQLT%')

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
-- TODO: If we recommit to facades, we should ensure that the authentication_type_desc is in ('NONE','DATABASE') in the Facade_CreateFacadeDb_Tests and then enable and fix the test below.
-- CREATE PROCEDURE Facade_Dacpac_Tests.[test dacpac contains all tSQLt users for SQL Server 2012 (11.x) and later]
-- AS
-- BEGIN
--   SELECT SDP.name, SDP.type_desc, SDP.authentication_type_desc
--     INTO #Expected
--     FROM sys.database_principals SDP
--    WHERE UPPER(SDP.name) LIKE ('%TSQLT%')

--   SELECT SDP.name, SDP.type_desc, SDP.authentication_type_desc
--     INTO #Actual
--     FROM $(DacpacTargetDb).sys.database_principals SDP
--    WHERE UPPER(SDP.name) LIKE ('%TSQLT%')

--   EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
-- END;
-- GO
CREATE PROCEDURE Facade_Dacpac_Tests.[test dacpac contains all tSQLt datatypes]
AS
BEGIN
  SELECT ST.name
    INTO #Expected
    FROM sys.types ST
   WHERE ST.schema_id = SCHEMA_ID('tSQLt')
     AND UPPER(ST.name) NOT LIKE 'PRIVATE%'

  SELECT ST.name
    INTO #Actual
    FROM $(DacpacTargetDb).sys.types ST
   WHERE ST.schema_id = SCHEMA_ID('tSQLt')
     AND UPPER(ST.name) NOT LIKE 'PRIVATE%'

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
 



