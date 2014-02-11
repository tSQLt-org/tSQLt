EXEC tSQLt.NewTestClass 'AssertObjectDoesNotExistTests';
GO
CREATE PROCEDURE AssertObjectDoesNotExistTests.[test calls fail if object exists]
AS
BEGIN
    EXEC ('CREATE SCHEMA schemaA');
    CREATE TABLE schemaA.aTable(id INT);
    
    DECLARE @Command NVARCHAR(MAX);
    SET @Command = 'EXEC tSQLt.AssertObjectDoesNotExist ''schemaA.aTable''';
    EXEC tSQLt_testutil.assertFailCalled @Command, 'AssertObjectDoesNotExist did not call Fail on existing object';
END;
GO
CREATE PROCEDURE AssertObjectDoesNotExistTests.[test calls fail if object exists and is not a table]
AS
BEGIN
    EXEC ('CREATE SCHEMA schemaA');
    EXEC ('CREATE VIEW schemaA.aView AS SELECT 1 x;');
    
    DECLARE @Command NVARCHAR(MAX);
    SET @Command = 'EXEC tSQLt.AssertObjectDoesNotExist ''schemaA.aView''';
    EXEC tSQLt_testutil.assertFailCalled @Command, 'AssertObjectDoesNotExist did not call Fail on existing object';
END;
GO
CREATE PROCEDURE AssertObjectDoesNotExistTests.[test does not call fail if object does not exist]
AS
BEGIN
    EXEC ('CREATE SCHEMA schemaA');
    EXEC tSQLt.AssertObjectDoesNotExist 'schemaA.doesNotExist';
END;
GO
CREATE PROCEDURE AssertObjectDoesNotExistTests.[test calls fail if object is #temp object]
AS
BEGIN
    EXEC ('CREATE PROCEDURE #aTempObject AS SELECT 1 x;');
    
    DECLARE @Command NVARCHAR(MAX);
    SET @Command = 'EXEC tSQLt.AssertObjectDoesNotExist ''#aTempObject''';
    EXEC tSQLt_testutil.assertFailCalled @Command, 'AssertObjectDoesNotExist did not call Fail on existing object';
END;
GO
CREATE PROCEDURE AssertObjectDoesNotExistTests.[test uses appropriate fail message]
AS
BEGIN
    EXEC ('CREATE PROCEDURE #aTempObject AS SELECT 1 x;');
    
    DECLARE @Command NVARCHAR(MAX);
    SET @Command = 'EXEC tSQLt.AssertObjectDoesNotExist ''#aTempObject''';
    EXEC tSQLt_testutil.AssertFailMessageEquals @Command = @Command, @ExpectedMessage = '''#aTempObject'' does exist!'
END;
GO
CREATE PROCEDURE AssertObjectDoesNotExistTests.[test allows for additional @Message]
AS
BEGIN
    EXEC ('CREATE PROCEDURE #aTempObject AS SELECT 1 x;');
    
    DECLARE @Command NVARCHAR(MAX);
    SET @Command = 'EXEC tSQLt.AssertObjectDoesNotExist @ObjectName = ''#aTempObject'', @Message = ''Some additional message!''';
    EXEC tSQLt_testutil.AssertFailMessageLike @Command = @Command, @ExpectedMessage = 'Some additional message!%'
END;
GO
