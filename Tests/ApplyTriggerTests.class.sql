EXEC tSQLt.NewTestClass 'ApplyTriggerTests';
GO

CREATE PROCEDURE ApplyTriggerTests.[test cannot apply trigger if table does not exist]
AS
BEGIN
  EXEC tSQLt.ExpectException @ExpectedMessage = 'ApplyTriggerTests.NotThere does not exist or was not faked by tSQLt.FakeTable.', @ExpectedSeverity = 16, @ExpectedState = NULL;

  EXEC tSQLt.ApplyTrigger @TableName = 'ApplyTriggerTests.NotThere', @TriggerName = 'AlsoNotThere';
END;
GO

CREATE PROCEDURE ApplyTriggerTests.[test cannot apply trigger if table is not a faked table]
AS
BEGIN
  CREATE TABLE ApplyTriggerTests.NotAFakeTable(i INT);
  
  EXEC tSQLt.ExpectException @ExpectedMessage = 'ApplyTriggerTests.NotAFakeTable does not exist or was not faked by tSQLt.FakeTable.', @ExpectedSeverity = 16, @ExpectedState = NULL;

  EXEC tSQLt.ApplyTrigger @TableName = 'ApplyTriggerTests.NotAFakeTable', @TriggerName = 'AlsoNotThere';
END;
GO

CREATE PROCEDURE ApplyTriggerTests.[test cannot apply trigger if trigger does not exist]
AS
BEGIN
  CREATE TABLE ApplyTriggerTests.TableWithoutTrigger(i INT);
  EXEC tSQLt.FakeTable @TableName = 'ApplyTriggerTests.TableWithoutTrigger';
  
  EXEC tSQLt.ExpectException @ExpectedMessage = 'AlsoNotThere is not a trigger on ApplyTriggerTests.TableWithoutTrigger', @ExpectedSeverity = 16, @ExpectedState = NULL;

  EXEC tSQLt.ApplyTrigger @TableName = 'ApplyTriggerTests.TableWithoutTrigger', @TriggerName = 'AlsoNotThere';
END;
GO

CREATE PROCEDURE ApplyTriggerTests.[test cannot apply trigger if trigger exist on wrong table]
AS
BEGIN
  CREATE TABLE ApplyTriggerTests.TableWithoutTrigger(i INT);
  CREATE TABLE ApplyTriggerTests.TableWithTrigger(i INT);
  EXEC('CREATE TRIGGER MyTrigger ON ApplyTriggerTests.TableWithTrigger FOR DELETE AS INSERT INTO #Actual DEFAULT VALUES;');
  EXEC tSQLt.FakeTable @TableName = 'ApplyTriggerTests.TableWithoutTrigger';
  
  EXEC tSQLt.ExpectException @ExpectedMessage = 'MyTrigger is not a trigger on ApplyTriggerTests.TableWithoutTrigger', @ExpectedSeverity = 16, @ExpectedState = NULL;

  EXEC tSQLt.ApplyTrigger @TableName = 'ApplyTriggerTests.TableWithoutTrigger', @TriggerName = 'MyTrigger';
END;
GO

CREATE PROCEDURE ApplyTriggerTests.[test trigger is applied to faked table]
AS
BEGIN
  CREATE TABLE ApplyTriggerTests.TableWithTrigger(i iNT);
  EXEC('CREATE TRIGGER MyTrigger ON ApplyTriggerTests.TableWithTrigger FOR DELETE AS INSERT INTO #Actual DEFAULT VALUES;');
  
  EXEC tSQLt.FakeTable @TableName = 'ApplyTriggerTests.TableWithTrigger';
  EXEC tSQLt.ApplyTrigger @TableName = 'ApplyTriggerTests.TableWithTrigger', @TriggerName = 'MyTrigger';
  
  CREATE TABLE #Actual(i INT IDENTITY(1,1));
  
  DELETE FROM ApplyTriggerTests.TableWithTrigger;
  
  SELECT TOP(0) 0 i
  INTO #Expected;
  
  INSERT INTO #Expected
  VALUES(1);
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual', 'Trigger was not called!';
  
END;
GO

CREATE PROCEDURE ApplyTriggerTests.[test trigger is applied to faked table if all names require quoting]
AS
BEGIN
  EXEC('CREATE SCHEMA [very, odd: Schema!];');
  CREATE TABLE [very, odd: Schema!].[very, odd: Table!](i iNT);
  EXEC('CREATE TRIGGER [very, odd: Trigger!] ON [very, odd: Schema!].[very, odd: Table!] FOR DELETE AS INSERT INTO #Actual DEFAULT VALUES;');
  
  EXEC tSQLt.FakeTable @TableName = '[very, odd: Schema!].[very, odd: Table!]';
  EXEC tSQLt.ApplyTrigger @TableName = '[very, odd: Schema!].[very, odd: Table!]', @TriggerName = '[very, odd: Trigger!]';
  
  CREATE TABLE #Actual(i INT IDENTITY(1,1));
  
  DELETE FROM [very, odd: Schema!].[very, odd: Table!];
  
  SELECT TOP(0) 0 i
  INTO #Expected;
  
  INSERT INTO #Expected
  VALUES(1);
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual', 'Trigger was not called!';
  
END;
GO

CREATE PROCEDURE ApplyTriggerTests.[test correct trigger is applied to faked table]
AS
BEGIN
  CREATE TABLE ApplyTriggerTests.TableWithTrigger(i iNT);
  EXEC('CREATE TRIGGER CorrectTrigger ON ApplyTriggerTests.TableWithTrigger FOR DELETE AS INSERT INTO #Actual VALUES(42);');
  EXEC('CREATE TRIGGER WrongTrigger ON ApplyTriggerTests.TableWithTrigger FOR DELETE AS INSERT INTO #Actual VALUES(13);');
  
  EXEC tSQLt.FakeTable @TableName = 'ApplyTriggerTests.TableWithTrigger';
  EXEC tSQLt.ApplyTrigger @TableName = 'ApplyTriggerTests.TableWithTrigger', @TriggerName = 'CorrectTrigger';
  
  CREATE TABLE #Actual(i INT);
  
  DELETE FROM ApplyTriggerTests.TableWithTrigger;
  
  SELECT TOP(0) 0 i
  INTO #Expected;
  
  INSERT INTO #Expected
  VALUES(42);
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual', 'CorrectTrigger was not called!';
  
END;
GO
CREATE PROC ApplyTriggerTests.[test ApplyTrigger calls tSQLt.Private_MarktSQLtTempObject on new check constraints]
AS
BEGIN
  CREATE TABLE ApplyTriggerTests.aSimpleTable ( Id INT);
  EXEC('CREATE TRIGGER ApplyTriggerTests.aSimpleTrigger ON ApplyTriggerTests.aSimpleTable FOR INSERT AS RETURN;'); 
  DECLARE @OriginalObjectId INT = OBJECT_ID('ApplyTriggerTests.aSimpleTrigger');

  EXEC tSQLt.FakeTable @TableName = 'ApplyTriggerTests.aSimpleTable';

  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_MarktSQLtTempObject';
  TRUNCATE TABLE tSQLt.Private_MarktSQLtTempObject_SpyProcedureLog;--Quirkiness of testing the framework that you use to run the test

  EXEC tSQLt.ApplyTrigger @TableName = 'ApplyTriggerTests.aSimpleTable', @TriggerName = 'aSimpleTrigger';

  SELECT ObjectName, ObjectType, NewNameOfOriginalObject 
    INTO #Actual 
    FROM tSQLt.Private_MarktSQLtTempObject_SpyProcedureLog;
  
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
    VALUES('[ApplyTriggerTests].[aSimpleTrigger]', N'TRIGGER', OBJECT_NAME(@OriginalObjectId));

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
  
END;
GO
