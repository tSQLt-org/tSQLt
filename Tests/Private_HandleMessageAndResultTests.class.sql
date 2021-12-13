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
--CREATE PROCEDURE Private_HandleMessageAndResultTests.[test returns empty Message if the first three parameters are empty strings]
--AS
--BEGIN
--  DECLARE @Message NVARCHAR(MAX);
--  SET @Message = (SELECT Message FROM tSQLt.Private_HandleMessageAndResult ('', '', '', DEFAULT));
 
--  EXEC tSQLt.AssertEqualsString @Expected = '<empty> [Result: <empty>] || <empty>', @Actual = @Message;
--END;
--GO
--/*-----------------------------------------------------------------------------------------------*/
--GO
--CREATE PROCEDURE Private_HandleMessageAndResultTests.[test returns appropriate Message if only @PrevResult is valued]
--AS
--BEGIN
--  DECLARE @Message NVARCHAR(MAX);
--  SET @Message = (SELECT Message FROM tSQLt.Private_HandleMessageAndResult (NULL, 'ResultOne', NULL, DEFAULT));
--  EXEC tSQLt.AssertEqualsString @Expected = '<NULL> [Result: ResultOne] ||<NULL>', @Actual = @Message;
--END;
--GO
--/*-----------------------------------------------------------------------------------------------*/
--GO
--CREATE PROCEDURE Private_HandleMessageAndResultTests.[test returns empty Message if the first three parameters are white space only strings]
--AS
--BEGIN
--  DECLARE @Message NVARCHAR(MAX);
--  SET @Message = (SELECT Message FROM tSQLt.Private_HandleMessageAndResult (CHAR(9), ' ', ' '+CHAR(9)+' ', DEFAULT));
--  EXEC tSQLt.AssertEqualsString @Expected = '<empty> [Result: <empty>] || <empty>', @Actual = @Message;
--END;
--GO
--/*-----------------------------------------------------------------------------------------------*/
--GO


