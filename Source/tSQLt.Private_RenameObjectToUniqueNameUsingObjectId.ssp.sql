IF OBJECT_ID('tSQLt.Private_RenameObjectToUniqueNameUsingObjectId') IS NOT NULL DROP PROCEDURE tSQLt.Private_RenameObjectToUniqueNameUsingObjectId;
GO
---Build+
CREATE PROCEDURE tSQLt.Private_RenameObjectToUniqueNameUsingObjectId
    @ObjectId INT,
    @NewName NVARCHAR(MAX) = NULL OUTPUT
AS
BEGIN
   DECLARE @SchemaName NVARCHAR(MAX);
   DECLARE @ObjectName NVARCHAR(MAX);
   
   SELECT @SchemaName = QUOTENAME(OBJECT_SCHEMA_NAME(@ObjectId)), @ObjectName = QUOTENAME(OBJECT_NAME(@ObjectId));
   
   EXEC tSQLt.Private_RenameObjectToUniqueName @SchemaName,@ObjectName, @NewName OUTPUT;
END;
---Build-
GO
