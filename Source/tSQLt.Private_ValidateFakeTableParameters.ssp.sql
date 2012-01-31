IF OBJECT_ID('tSQLt.Private_ValidateFakeTableParameters') IS NOT NULL DROP PROCEDURE tSQLt.Private_ValidateFakeTableParameters;
GO
---Build+
CREATE PROCEDURE tSQLt.Private_ValidateFakeTableParameters
  @SchemaName NVARCHAR(MAX),
  @OrigTableName NVARCHAR(MAX),
  @OrigSchemaName NVARCHAR(MAX)
AS
BEGIN
   IF @SchemaName IS NULL
   BEGIN
        DECLARE @FullName NVARCHAR(MAX); SET @FullName = @OrigTableName + COALESCE('.' + @OrigSchemaName, '');
        
        RAISERROR ('FakeTable could not resolve the object name, ''%s''. Be sure to call FakeTable and pass in a single parameter, such as: EXEC tSQLt.FakeTable ''MySchema.MyTable''', 
                   16, 10, @FullName);
   END;
END;
---Build-
GO

