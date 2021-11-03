IF OBJECT_ID('tSQLt.Private_MarktSQLtTempObject') IS NOT NULL DROP PROCEDURE tSQLt.Private_MarktSQLtTempObject;
GO
---Build+
CREATE PROCEDURE tSQLt.Private_MarktSQLtTempObject
  @ObjectName NVARCHAR(MAX),
  @ObjectType NVARCHAR(MAX),
  --@ParentObjectName NVARCHAR(MAX) = NULL,
  --@ParentObjectType NVARCHAR(MAX) = NULL,
  @NewNameOfOriginalObject NVARCHAR(4000)
AS
BEGIN
   DECLARE @UnquotedSchemaName NVARCHAR(MAX);
   DECLARE @UnquotedObjectName NVARCHAR(MAX);
   SELECT 
       @UnquotedSchemaName = SCHEMA_NAME(O.schema_id),
       @UnquotedObjectName = O.name
     FROM sys.objects O 
    WHERE O.object_id = OBJECT_ID(@ObjectName);

   EXEC sys.sp_addextendedproperty 
      @name = N'tSQLt.IsTempObject',
      @value = 1, 
      @level0type = N'SCHEMA', @level0name = @UnquotedSchemaName, 
      @level1type = @ObjectType,  @level1name = @UnquotedObjectName;   

   EXEC sys.sp_addextendedproperty 
      @name = N'tSQLt.Private_TestDouble_OrgObjectName', 
      @value = @NewNameOfOriginalObject, 
      @level0type = N'SCHEMA', @level0name = @UnquotedSchemaName, 
      @level1type = @ObjectType,  @level1name = @UnquotedObjectName;
END;
---Build-
GO