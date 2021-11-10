IF OBJECT_ID('tSQLt.Private_MarktSQLtTempObject') IS NOT NULL DROP PROCEDURE tSQLt.Private_MarktSQLtTempObject;
GO
---Build+
CREATE PROCEDURE tSQLt.Private_MarktSQLtTempObject
  @ObjectName NVARCHAR(MAX),
  @ObjectType NVARCHAR(MAX),
  @NewNameOfOriginalObject NVARCHAR(4000) = NULL
AS
BEGIN
  DECLARE @UnquotedSchemaName NVARCHAR(MAX);
  DECLARE @UnquotedObjectName NVARCHAR(MAX);
  DECLARE @UnquotedParentName NVARCHAR(MAX);
  DECLARE @TempObjectFlagOn BIT = 1;
  SELECT 
      @UnquotedSchemaName = SCHEMA_NAME(O.schema_id),
      @UnquotedObjectName = O.name,
      @UnquotedParentName = OBJECT_NAME(O.parent_object_id)
    FROM sys.objects O 
   WHERE O.object_id = OBJECT_ID(@ObjectName);

  IF(@UnquotedParentName IS NULL)
  BEGIN
    EXEC sys.sp_addextendedproperty 
       @name = N'tSQLt.IsTempObject',
       @value = @TempObjectFlagOn, 
       @level0type = N'SCHEMA', @level0name = @UnquotedSchemaName, 
       @level1type = @ObjectType,  @level1name = @UnquotedObjectName;   

    IF(@NewNameOfOriginalObject IS NOT NULL)
    BEGIN
      EXEC sys.sp_addextendedproperty 
         @name = N'tSQLt.Private_TestDouble_OrgObjectName', 
         @value = @NewNameOfOriginalObject, 
         @level0type = N'SCHEMA', @level0name = @UnquotedSchemaName, 
         @level1type = @ObjectType,  @level1name = @UnquotedObjectName;
    END;
  END;
  ELSE
  BEGIN
    EXEC sys.sp_addextendedproperty 
       @name = N'tSQLt.IsTempObject',
       @value = @TempObjectFlagOn, 
       @level0type = N'SCHEMA', @level0name = @UnquotedSchemaName, 
       @level1type = N'TABLE',  @level1name = @UnquotedParentName,
       @level2type = @ObjectType,  @level2name = @UnquotedObjectName;

    IF(@NewNameOfOriginalObject IS NOT NULL)
    BEGIN
      EXEC sys.sp_addextendedproperty 
         @name = N'tSQLt.Private_TestDouble_OrgObjectName', 
         @value = @NewNameOfOriginalObject, 
         @level0type = N'SCHEMA', @level0name = @UnquotedSchemaName, 
         @level1type = N'TABLE',  @level1name = @UnquotedParentName,
         @level2type = @ObjectType,  @level2name = @UnquotedObjectName;
    END;
  END;
END;
---Build-
GO