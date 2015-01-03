EXEC tSQLt.NewTestClass 'Private_RemoveSchemBoundReferencesTests_2008';
GO
CREATE PROCEDURE Private_RemoveSchemBoundReferencesTests_2008.[test calls RemoveSchemaBinding for single view]
AS
BEGIN
  CREATE TABLE Private_RemoveSchemBoundReferencesTests_2008.T1(C1 INT);
  EXEC('CREATE VIEW Private_RemoveSchemBoundReferencesTests_2008.V1 WITH SCHEMABINDING AS SELECT T.C1 FROM Private_RemoveSchemBoundReferencesTests_2008.T1 AS T;');

  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_RemoveSchemaBinding';

  DECLARE @object_id INT;SET @object_id = OBJECT_ID('Private_RemoveSchemBoundReferencesTests_2008.T1');
  EXEC tSQLt.Private_RemoveSchemaBoundReferences @object_id = @object_id;

  SELECT object_id 
    INTO #Actual
    FROM tSQLt.Private_RemoveSchemaBinding_SpyProcedureLog;

  SELECT TOP(0) *
  INTO #Expected
  FROM #Actual;
  
  INSERT INTO #Expected
  VALUES(OBJECT_ID('Private_RemoveSchemBoundReferencesTests_2008.V1'));

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
  
END;
GO
CREATE PROCEDURE Private_RemoveSchemBoundReferencesTests_2008.[test calls RemoveSchemaBinding for multiple views]
AS
BEGIN
  CREATE TABLE Private_RemoveSchemBoundReferencesTests_2008.T1(C1 INT);
  EXEC('CREATE VIEW Private_RemoveSchemBoundReferencesTests_2008.V1 WITH SCHEMABINDING AS SELECT T.C1 FROM Private_RemoveSchemBoundReferencesTests_2008.T1 AS T;');
  EXEC('CREATE VIEW Private_RemoveSchemBoundReferencesTests_2008.V2 WITH SCHEMABINDING AS SELECT T.C1 FROM Private_RemoveSchemBoundReferencesTests_2008.T1 AS T;');
  EXEC('CREATE VIEW Private_RemoveSchemBoundReferencesTests_2008.V3 WITH SCHEMABINDING AS SELECT T.C1 FROM Private_RemoveSchemBoundReferencesTests_2008.T1 AS T;');

  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_RemoveSchemaBinding';

  DECLARE @object_id INT;SET @object_id = OBJECT_ID('Private_RemoveSchemBoundReferencesTests_2008.T1');
  EXEC tSQLt.Private_RemoveSchemaBoundReferences @object_id = @object_id;

  SELECT object_id 
    INTO #Actual
    FROM tSQLt.Private_RemoveSchemaBinding_SpyProcedureLog;

  SELECT TOP(0) *
  INTO #Expected
  FROM #Actual;
  
  INSERT INTO #Expected
  VALUES(OBJECT_ID('Private_RemoveSchemBoundReferencesTests_2008.V1'));
  INSERT INTO #Expected
  VALUES(OBJECT_ID('Private_RemoveSchemBoundReferencesTests_2008.V2'));
  INSERT INTO #Expected
  VALUES(OBJECT_ID('Private_RemoveSchemBoundReferencesTests_2008.V3'));

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
  
END;
GO
CREATE PROCEDURE Private_RemoveSchemBoundReferencesTests_2008.[test calls RemoveSchemaBinding for multiple recursive views]
AS
BEGIN
  CREATE TABLE Private_RemoveSchemBoundReferencesTests_2008.T1(C1 INT);
  EXEC('CREATE VIEW Private_RemoveSchemBoundReferencesTests_2008.V1 WITH SCHEMABINDING AS SELECT T.C1 FROM Private_RemoveSchemBoundReferencesTests_2008.T1 AS T;');
  EXEC('CREATE VIEW Private_RemoveSchemBoundReferencesTests_2008.V2 WITH SCHEMABINDING AS SELECT T.C1 FROM Private_RemoveSchemBoundReferencesTests_2008.V1 AS T;');
  EXEC('CREATE VIEW Private_RemoveSchemBoundReferencesTests_2008.V3 WITH SCHEMABINDING AS SELECT T.C1 FROM Private_RemoveSchemBoundReferencesTests_2008.V2 AS T;');

  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_RemoveSchemaBinding';

  DECLARE @object_id INT;SET @object_id = OBJECT_ID('Private_RemoveSchemBoundReferencesTests_2008.T1');
  EXEC tSQLt.Private_RemoveSchemaBoundReferences @object_id = @object_id;

  SELECT _id_*1 call_order,object_id 
    INTO #Actual
    FROM tSQLt.Private_RemoveSchemaBinding_SpyProcedureLog;

  SELECT TOP(0) *
  INTO #Expected
  FROM #Actual;
  
  INSERT INTO #Expected
  VALUES(1, OBJECT_ID('Private_RemoveSchemBoundReferencesTests_2008.V3'));
  INSERT INTO #Expected
  VALUES(2, OBJECT_ID('Private_RemoveSchemBoundReferencesTests_2008.V2'));
  INSERT INTO #Expected
  VALUES(3, OBJECT_ID('Private_RemoveSchemBoundReferencesTests_2008.V1'));

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
  
END;
GO
