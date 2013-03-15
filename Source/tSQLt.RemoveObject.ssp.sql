IF OBJECT_ID('tSQLt.RemoveObject') IS NOT NULL DROP PROCEDURE tSQLt.RemoveObject;
GO
---BUILD+
CREATE PROCEDURE tSQLt.RemoveObject 
    @ObjectName NVARCHAR(MAX),
    @NewName NVARCHAR(MAX) = NULL OUTPUT
AS
BEGIN
  DECLARE @ObjectId INT;
  SELECT @ObjectId = OBJECT_ID(@ObjectName);
  
  IF(@ObjectId IS NULL)
  BEGIN
    RAISERROR('%s does not exist!',16,10,@ObjectName);
  END;

  EXEC tSQLt.Private_RenameObjectToUniqueNameUsingObjectId @ObjectId, @NewName = @NewName OUTPUT;
END;
---Build-
GO