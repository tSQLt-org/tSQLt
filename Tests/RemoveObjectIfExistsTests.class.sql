EXEC tSQLt.NewTestClass 'RemoveObjectIfExistsTests';
GO
CREATE PROCEDURE RemoveObjectIfExistsTests.[test calls tSQLt.RemoveObject with @IfExists = 1]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.RemoveObject', @CommandToExecute = NULL;

  EXEC tSQLt.RemoveObjectIfExists @ObjectName = 'some.name';
  
  SELECT ObjectName,IfExists
    INTO #Actual
    FROM tSQLt.RemoveObject_SpyProcedureLog;
    
  SELECT TOP(0) *
  INTO #Expected
  FROM #Actual;
  
  INSERT INTO #Expected
  VALUES('some.name',1);
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
  
END;
GO
CREATE PROCEDURE RemoveObjectIfExistsTests.[test calls tSQLt.RemoveObject passes @NewName back]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.RemoveObject', @CommandToExecute = 'SET @NewName = ''new.name'';';

  DECLARE @ActualNewName NVARCHAR(MAX); SET @ActualNewName = 'No value was returned!';
  
  EXEC tSQLt.RemoveObjectIfExists @ObjectName = 'some.name',@NewName = @ActualNewName OUT;
  
  EXEC tSQLt.AssertEqualsString @Expected = 'new.name', @Actual = @ActualNewName;
  
END;
GO
