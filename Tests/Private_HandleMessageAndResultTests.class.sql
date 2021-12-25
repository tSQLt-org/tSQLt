EXEC tSQLt.NewTestClass 'Private_HandleMessageAndResultTests';
GO
CREATE PROCEDURE Private_HandleMessageAndResultTests.[test returns appropriately formatted Message if the first three parameters are null]
AS
BEGIN 
  DECLARE @Message NVARCHAR(MAX);
  SET @Message = (SELECT Message FROM tSQLt.Private_HandleMessageAndResult (NULL, NULL, NULL, DEFAULT));

  EXEC tSQLt.AssertEqualsString @Expected = '<NULL> [Result: <NULL>] || <NULL>', @Actual = @Message;
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE Private_HandleMessageAndResultTests.[test returns @NewMessage in appropriately formatted Message if only @NewMessage is valued]
AS
BEGIN
  DECLARE @Message NVARCHAR(MAX);
  SET @Message = (SELECT Message FROM tSQLt.Private_HandleMessageAndResult (NULL, NULL, 'a random message', DEFAULT));

  EXEC tSQLt.AssertEqualsString @Expected = '<NULL> [Result: <NULL>] || a random message', @Actual = @Message;
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE Private_HandleMessageAndResultTests.[test returns @PrevMessage in appropriately formatted Message if only @PrevMessage is valued]
AS
BEGIN
  DECLARE @Message NVARCHAR(MAX);
  SET @Message = (SELECT Message FROM tSQLt.Private_HandleMessageAndResult ('another random message', NULL, NULL, DEFAULT));

  EXEC tSQLt.AssertEqualsString @Expected = 'another random message [Result: <NULL>] || <NULL>', @Actual = @Message;
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE Private_HandleMessageAndResultTests.[test returns appropriate Message if only @PrevResult is valued]
AS
BEGIN
  DECLARE @Message NVARCHAR(MAX);
  SET @Message = (SELECT Message FROM tSQLt.Private_HandleMessageAndResult (NULL, 'ResultOne', NULL, DEFAULT));
  EXEC tSQLt.AssertEqualsString @Expected = '<NULL> [Result: ResultOne] || <NULL>', @Actual = @Message;
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE Private_HandleMessageAndResultTests.[test returns <empty> in Message for each of the first three parameters if it is an empty string]
AS
BEGIN
  DECLARE @Message NVARCHAR(MAX);
  SET @Message = (SELECT Message FROM tSQLt.Private_HandleMessageAndResult ('', '', '', DEFAULT));
 
  EXEC tSQLt.AssertEqualsString @Expected = '<empty> [Result: <empty>] || <empty>', @Actual = @Message;
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO

CREATE PROCEDURE Private_HandleMessageAndResultTests.[test returns empty Message if the first three parameters are white space only strings]
AS
BEGIN
  DECLARE @Message NVARCHAR(MAX);
  SET @Message = (SELECT Message FROM tSQLt.Private_HandleMessageAndResult (CHAR(9), CHAR(9)+' '+CHAR(9), ' '+CHAR(9)+' ', DEFAULT));
  EXEC tSQLt.AssertEqualsString @Expected = '<empty> [Result: <empty>] || <empty>', @Actual = @Message;
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO

CREATE PROCEDURE Private_HandleMessageAndResultTests.[test returns @NewResult as Result]
AS
BEGIN
  EXEC tSQLt.FakeTable @TableName = 'tSQLt.Private_Results';
  EXEC ('INSERT INTO tSQLt.Private_Results(Result, Severity)VALUES(''SomeResult'',42)');

  DECLARE @Result NVARCHAR(MAX);
  SET @Result = (SELECT Result FROM tSQLt.Private_HandleMessageAndResult (DEFAULT, DEFAULT, DEFAULT, 'SomeResult'));
  EXEC tSQLt.AssertEqualsString @Expected = 'SomeResult', @Actual = @Result;
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO

CREATE PROCEDURE Private_HandleMessageAndResultTests.[test returns @PrevResult as Result if @NewResult is less severe]
AS
BEGIN
  EXEC tSQLt.FakeTable @TableName = 'tSQLt.Private_Results';
  EXEC ('INSERT INTO tSQLt.Private_Results(Result, Severity)VALUES(''SomeSevereResult'',7),(''SomeLessSevereResult'',3)');

  DECLARE @Result NVARCHAR(MAX);
  SET @Result = (SELECT Result FROM tSQLt.Private_HandleMessageAndResult (DEFAULT, 'SomeSevereResult', DEFAULT, 'SomeLessSevereResult'));
  EXEC tSQLt.AssertEqualsString @Expected = 'SomeSevereResult', @Actual = @Result;
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO

CREATE PROCEDURE Private_HandleMessageAndResultTests.[test returns @PrevResult as Result if @NewResult is less severe if there are other values in Private_Results]
AS
BEGIN
  EXEC tSQLt.FakeTable @TableName = 'tSQLt.Private_Results';
  EXEC ('INSERT INTO tSQLt.Private_Results(Result, Severity)VALUES(''aaa'',10),(''SomeSevereResult'',7),(''SomeLessSevereResult'',3)');

  DECLARE @Result NVARCHAR(MAX);
  SET @Result = (SELECT Result FROM tSQLt.Private_HandleMessageAndResult (DEFAULT, 'SomeSevereResult', DEFAULT, 'SomeLessSevereResult'));
  EXEC tSQLt.AssertEqualsString @Expected = 'SomeSevereResult', @Actual = @Result;
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO

CREATE PROCEDURE Private_HandleMessageAndResultTests.[test returns @PrevResult if @NewResult is not known]
AS
BEGIN
  EXEC tSQLt.FakeTable @TableName = 'tSQLt.Private_Results';
  EXEC ('INSERT INTO tSQLt.Private_Results(Result, Severity)VALUES(''SomePreviousResult'',3)');

  DECLARE @Result NVARCHAR(MAX);
  SET @Result = (SELECT Result FROM tSQLt.Private_HandleMessageAndResult (DEFAULT, 'SomePreviousResult', DEFAULT, 'SomeUnknownResult'));
  EXEC tSQLt.AssertEqualsString @Expected = 'SomePreviousResult', @Actual = @Result;
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO

CREATE PROCEDURE Private_HandleMessageAndResultTests.[test returns @NewResult if @PrevResult is not known]
AS
BEGIN
  EXEC tSQLt.FakeTable @TableName = 'tSQLt.Private_Results';
  EXEC ('INSERT INTO tSQLt.Private_Results(Result, Severity)VALUES(''SomeNewResult'',3)');

  DECLARE @Result NVARCHAR(MAX);
  SET @Result = (SELECT Result FROM tSQLt.Private_HandleMessageAndResult (DEFAULT, 'SomeUnknownResult', DEFAULT, 'SomeNewResult'));
  EXEC tSQLt.AssertEqualsString @Expected = 'SomeNewResult', @Actual = @Result;
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO

CREATE PROCEDURE Private_HandleMessageAndResultTests.[test returns only the @NewMessage if @PrevMessage is empty and @PrevResult is Success]
AS
BEGIN
  DECLARE @Message NVARCHAR(MAX);
  SET @Message = (SELECT Message FROM tSQLt.Private_HandleMessageAndResult ('', 'Success', 'this is the new message', DEFAULT));
  EXEC tSQLt.AssertEqualsString @Expected = 'this is the new message', @Actual = @Message;
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO

CREATE PROCEDURE Private_HandleMessageAndResultTests.[test returns only the @NewMessage if @PrevMessage is NULL and @PrevResult is Success]
AS
BEGIN
  DECLARE @Message NVARCHAR(MAX);
  SET @Message = (SELECT Message FROM tSQLt.Private_HandleMessageAndResult (NULL, 'Success', 'this is the new message', DEFAULT));
  EXEC tSQLt.AssertEqualsString @Expected = 'this is the new message', @Actual = @Message;
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO

CREATE PROCEDURE Private_HandleMessageAndResultTests.[test returns @NewResult if @PrevResult is NULL]
AS
BEGIN
  EXEC tSQLt.FakeTable @TableName = 'tSQLt.Private_Results';
  EXEC ('INSERT INTO tSQLt.Private_Results(Result, Severity)VALUES(''SomeNewResult'',3)');

  DECLARE @Result NVARCHAR(MAX);
  SET @Result = (SELECT Result FROM tSQLt.Private_HandleMessageAndResult (DEFAULT, NULL, DEFAULT, 'SomeNewResult'));
  EXEC tSQLt.AssertEqualsString @Expected = 'SomeNewResult', @Actual = @Result;
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO

