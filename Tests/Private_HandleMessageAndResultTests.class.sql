EXEC tSQLt.NewTestClass 'Private_HandleMessageAndResultTests';
GO
CREATE PROCEDURE Private_HandleMessageAndResultTests.[test returns empty Message if all parameters are null]
AS
BEGIN
  DECLARE @Message NVARCHAR(MAX);
  SET @Message = (SELECT Message FROM tSQLt.Private_HandleMessageAndResult (NULL, NULL, NULL, NULL));

  EXEC tSQLt.AssertEqualsString @Expected = '', @Actual = @Message;
END;
GO
