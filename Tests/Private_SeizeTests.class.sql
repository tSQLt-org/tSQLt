EXEC tSQLt.NewTestClass 'Private_SeizeTests';
GO
CREATE PROCEDURE Private_SeizeTests.[test can insert a 1]
AS
BEGIN
  INSERT INTO tSQLt.Private_Seize(Kaput) VALUES(1);

  SELECT Kaput INTO #Actual FROM tSQLt.Private_Seize;
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  
  INSERT INTO #Expected VALUES(1);

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
  
END;
GO
CREATE PROCEDURE Private_SeizeTests.[test cannot insert <> 1]
AS
BEGIN
  EXEC tSQLt.ExpectException @ExpectedMessagePattern = '%"CHK:Private_Seize"%';
  INSERT INTO tSQLt.Private_Seize(Kaput) VALUES(0);

END;
GO
CREATE PROCEDURE Private_SeizeTests.[test cannot insert NULL]
AS
BEGIN
  EXEC tSQLt.ExpectException @ExpectedMessagePattern = '%column does not allow nulls%';
  INSERT INTO tSQLt.Private_Seize(Kaput) VALUES(NULL);

END;
GO
CREATE PROCEDURE Private_SeizeTests.[test cannot delete row]
AS
BEGIN
  INSERT INTO tSQLt.Private_Seize(Kaput) VALUES(1);

  EXEC tSQLt.ExpectException @ExpectedMessage = 'This is a private table that you should not mess with!', @ExpectedSeverity = 16, @ExpectedState = 10;
  DELETE FROM tSQLt.Private_Seize;
END;
GO
CREATE PROCEDURE Private_SeizeTests.[test cannot update row (even to the same value)]
AS
BEGIN
  INSERT INTO tSQLt.Private_Seize(Kaput) VALUES(1);

  EXEC tSQLt.ExpectException @ExpectedMessage = 'This is a private table that you should not mess with!', @ExpectedSeverity = 16, @ExpectedState = 10;
  UPDATE tSQLt.Private_Seize SET Kaput = 1;
END;
GO
CREATE PROCEDURE Private_SeizeTests.[test cannot TRUNCATE]
AS
BEGIN
  INSERT INTO tSQLt.Private_Seize(Kaput) VALUES(1);

  EXEC tSQLt.ExpectException @ExpectedMessagePattern = 'Cannot truncate table _tSQLt.Private_Seize_%';
  TRUNCATE TABLE tSQLt.Private_Seize;
END;
GO
