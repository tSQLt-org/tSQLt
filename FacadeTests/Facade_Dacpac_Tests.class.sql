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
     AND O.type NOT IN ('D', 'PK')

  SELECT O.name, CASE WHEN O.type_desc LIKE '%STORED[_]PROCEDURE' THEN 'STORED_PROCEDURE' ELSE O.type_desc END type_desc
    INTO #Actual
    FROM $(DacpacTargetDb).sys.objects O 
   WHERE O.schema_id = SCHEMA_ID('tSQLt')
     AND UPPER(O.name) NOT LIKE 'PRIVATE%'
     AND O.type NOT IN ('D', 'PK')
     
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROCEDURE Facade_Dacpac_Tests.[test dacpac contains all tSQLt users]
AS
BEGIN
  SELECT SDP.name, SDP.authentication_type_desc
    INTO #Expected
    FROM sys.database_principals SDP
   WHERE UPPER(SDP.name) LIKE ('%TSQLT%')

  SELECT SDP.name, SDP.authentication_type_desc
    INTO #Actual
    FROM $(DacpacTargetDb).sys.database_principals SDP
   WHERE UPPER(SDP.name) LIKE ('%TSQLT%')

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
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
 



