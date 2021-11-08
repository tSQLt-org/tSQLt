EXEC tSQLt.NewTestClass 'Private_MarktSQLtTempObjectTests';
GO
CREATE PROCEDURE Private_MarktSQLtTempObjectTests.[assert creates two extended properties on object]
  @ObjectName NVARCHAR(MAX),
  @ObjectType NVARCHAR(MAX)
AS
BEGIN
  EXEC tSQLt.Private_MarktSQLtTempObject
             @ObjectName = @ObjectName,
             @ObjectType = @ObjectType,
             @NewNameOfOriginalObject = 'ARandomString';

  SELECT name, CAST(value AS NVARCHAR(MAX)) value 
    INTO #Actual
    FROM sys.extended_properties
   WHERE class_desc = 'OBJECT_OR_COLUMN'
     AND major_id = OBJECT_ID(@ObjectName)
     AND name IN ('tSQLt.IsTempObject', 'tSQLt.Private_TestDouble_OrgObjectName')

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  
  INSERT INTO #Expected VALUES('tSQLt.IsTempObject',	'1'),
                              ('tSQLt.Private_TestDouble_OrgObjectName','ARandomString');

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROCEDURE Private_MarktSQLtTempObjectTests.[test can mark a table]
AS
BEGIN
  CREATE TABLE Private_MarktSQLtTempObjectTests.TempTable1(i INT NOT NULL);
  EXEC Private_MarktSQLtTempObjectTests.[assert creates two extended properties on object]
    @ObjectName = 'Private_MarktSQLtTempObjectTests.TempTable1',
    @ObjectType = N'TABLE';
END;
GO
CREATE PROCEDURE Private_MarktSQLtTempObjectTests.[test can mark a stored procedure]
AS
BEGIN
  EXEC('CREATE PROCEDURE Private_MarktSQLtTempObjectTests.TempProcedure1 AS RETURN;');
  EXEC Private_MarktSQLtTempObjectTests.[assert creates two extended properties on object]
    @ObjectName = 'Private_MarktSQLtTempObjectTests.TempProcedure1',
    @ObjectType = N'PROCEDURE';
END;
GO
CREATE PROCEDURE Private_MarktSQLtTempObjectTests.[test can mark a TV function]
AS
BEGIN
  EXEC('CREATE FUNCTION Private_MarktSQLtTempObjectTests.TempTVFunction1() RETURNS @X TABLE (i INT) AS BEGIN RETURN; END;');
  EXEC Private_MarktSQLtTempObjectTests.[assert creates two extended properties on object]
    @ObjectName = 'Private_MarktSQLtTempObjectTests.TempTVFunction1',
    @ObjectType = N'FUNCTION';
END;
GO
CREATE PROCEDURE Private_MarktSQLtTempObjectTests.[test can mark a ITV function]
AS
BEGIN
  EXEC('CREATE FUNCTION Private_MarktSQLtTempObjectTests.TempITVFunction1() RETURNS TABLE AS RETURN SELECT 1 X;');
  EXEC Private_MarktSQLtTempObjectTests.[assert creates two extended properties on object]
    @ObjectName = 'Private_MarktSQLtTempObjectTests.TempITVFunction1',
    @ObjectType = N'FUNCTION';
END;
GO
CREATE PROCEDURE Private_MarktSQLtTempObjectTests.[test can mark a SV function]
AS
BEGIN
  EXEC('CREATE FUNCTION Private_MarktSQLtTempObjectTests.TempSVFunction1() RETURNS INT AS BEGIN RETURN NULL; END;');
  EXEC Private_MarktSQLtTempObjectTests.[assert creates two extended properties on object]
    @ObjectName = 'Private_MarktSQLtTempObjectTests.TempSVFunction1',
    @ObjectType = N'FUNCTION';
END;
GO
CREATE PROCEDURE Private_MarktSQLtTempObjectTests.[test can mark a constraint]
AS
BEGIN
  CREATE TABLE Private_MarktSQLtTempObjectTests.TempTable1(i INT CONSTRAINT aSimpleTableConstraint CHECK(i > 0));

  EXEC Private_MarktSQLtTempObjectTests.[assert creates two extended properties on object]
    @ObjectName = 'Private_MarktSQLtTempObjectTests.aSimpleTableConstraint',
    @ObjectType = N'CONSTRAINT';
END;
GO
CREATE PROCEDURE Private_MarktSQLtTempObjectTests.[test can mark a trigger]
AS
BEGIN
  CREATE TABLE Private_MarktSQLtTempObjectTests.TempTable1(i INT);
  EXEC('CREATE TRIGGER Private_MarktSQLtTempObjectTests.TempTrigger ON Private_MarktSQLtTempObjectTests.TempTable1 FOR INSERT AS RETURN;');

  EXEC Private_MarktSQLtTempObjectTests.[assert creates two extended properties on object]
    @ObjectName = 'Private_MarktSQLtTempObjectTests.TempTrigger',
    @ObjectType = N'TRIGGER';
END;
GO
CREATE PROCEDURE Private_MarktSQLtTempObjectTests.[test tSQLt.IsTempObject Data Type is BIT]
AS
BEGIN
  CREATE TABLE Private_MarktSQLtTempObjectTests.TempTable1(i INT NOT NULL);
  EXEC Private_MarktSQLtTempObjectTests.[assert creates two extended properties on object]
    @ObjectName = 'Private_MarktSQLtTempObjectTests.TempTable1',
    @ObjectType = N'TABLE';
  
  SELECT UPPER(CAST(SQL_VARIANT_PROPERTY(EP.value,'BaseType') AS NVARCHAR(MAX))) IsTempObject_DataType
    INTO #Actual
    FROM sys.extended_properties AS EP
   WHERE EP.class_desc = 'OBJECT_OR_COLUMN'
     AND EP.major_id = OBJECT_ID('Private_MarktSQLtTempObjectTests.TempTable1')
     AND EP.name = 'tSQLt.IsTempObject';

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected VALUES('BIT');
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
  
END;
GO