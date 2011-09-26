DROP FUNCTION tSQLt.Private_GetOriginalTableName;
GO
 
CREATE FUNCTION tSQLt.Private_GetOriginalTableName(@SchemaName NVARCHAR(MAX), @TableName NVARCHAR(MAX))
RETURNS TABLE
AS
  RETURN SELECT CAST(value AS NVARCHAR(4000)) OrgTableName
    FROM sys.extended_properties
   WHERE class_desc = 'OBJECT_OR_COLUMN'
     AND major_id = OBJECT_ID(@SchemaName + '.' + @TableName)
     AND minor_id = 0
     AND name = 'tSQLt.FakeTable_OrgTableName';
GO
DROP PROCEDURE tSQLt.Private_ApplyConstraint_CHECK_CONSTRAINT;
GO
CREATE PROCEDURE tSQLt.Private_ApplyConstraint_CHECK_CONSTRAINT
  @ConstraintObjectId INT
AS
BEGIN
  DECLARE @Cmd NVARCHAR(MAX);
  SELECT @Cmd = 'CONSTRAINT ' + name + ' CHECK' + definition 
    FROM sys.check_constraints
   WHERE object_id = @ConstraintObjectId;
  
  DECLARE @QuotedTableName NVARCHAR(MAX);
  
  SELECT @QuotedTableName =  QUOTENAME(SCHEMA_NAME(o.schema_id)) + '.' + QUOTENAME(OBJECT_NAME(o.object_id))
    FROM sys.objects AS constraints
    JOIN sys.extended_properties p
    JOIN sys.objects AS o
      ON o.object_id = p.major_id
     AND p.minor_id = 0
     AND p.class_desc = 'OBJECT_OR_COLUMN'
     AND p.name = 'tSQLt.FakeTable_OrgTableName'
      ON OBJECT_NAME(constraints.parent_object_id) = CAST(p.value AS NVARCHAR(4000))
     AND constraints.schema_id = o.schema_id
     AND constraints.object_id = @ConstraintObjectId;


  EXEC tSQLt.Private_RenameObjectToUniqueNameUsingObjectId @ConstraintObjectId;
  SELECT @Cmd = 'ALTER TABLE ' + @QuotedTableName + ' ADD ' + @Cmd
    FROM sys.objects 
   WHERE object_id = @ConstraintObjectId;

  EXEC (@Cmd);

END; 
GO


DROP FUNCTION tSQLt.Private_GetConstraintType;
GO
 
CREATE FUNCTION tSQLt.Private_GetConstraintType(@SchemaName NVARCHAR(MAX), @TableName NVARCHAR(MAX), @ConstraintName NVARCHAR(MAX))
RETURNS TABLE
AS
RETURN
  SELECT object_id,type,type_desc
    FROM sys.objects 
   WHERE object_id = OBJECT_ID(@SchemaName + '.' + @ConstraintName)
     AND parent_object_id = OBJECT_ID(@SchemaName + '.' + @TableName);
GO

DROP PROCEDURE tSQLt.ApplyConstraint;
GO
CREATE PROCEDURE tSQLt.ApplyConstraint
       @SchemaName NVARCHAR(MAX),
       @TableName NVARCHAR(MAX),
       @ConstraintName NVARCHAR(MAX)
AS
BEGIN
  DECLARE @OrgTableName NVARCHAR(MAX);
  DECLARE @Cmd NVARCHAR(MAX);
  DECLARE @ObjectType NVARCHAR(MAX);
  DECLARE @ConstraintObjectId INT;

  SELECT @OrgTableName = OrgTableName FROM tSQLt.Private_GetOriginalTableName(@SchemaName, @TableName);
  
  SELECT @ObjectType = type_desc, @ConstraintObjectId = object_id 
    FROM tSQLt.Private_GetConstraintType(@SchemaName, @OrgTableName, @ConstraintName);

  IF @ObjectType = 'CHECK_CONSTRAINT'
  BEGIN
    EXEC tSQLt.Private_ApplyConstraint_CHECK_CONSTRAINT @ConstraintObjectId;
    RETURN 0;
  END

  IF @ObjectType = 'FOREIGN_KEY_CONSTRAINT'
  BEGIN
     DECLARE @CreateIndexCmd NVARCHAR(MAX);
     SELECT @Cmd = cmd ,@CreateIndexCmd = CreIdxCmd
       FROM tSQLt.Private_GetForeignKeyDefinition(@SchemaName, @OrgTableName, @ConstraintName);

     EXEC tSQLt.Private_RenameObjectToUniqueName @SchemaName, @ConstraintName;
     SELECT @Cmd = @CreateIndexCmd + 'ALTER TABLE ' + @SchemaName + '.' + @TableName + ' ADD ' + @Cmd;

     EXEC (@Cmd);

    RETURN 0;
  END;


  DECLARE @ErrorMessage NVARCHAR(MAX);
  SET @ErrorMessage = '''' + @SchemaName + '.' + @ConstraintName + 
      ''' is not a valid constraint on table ''' + @SchemaName + '.' + @TableName + 
      ''' for the tSQLt.ApplyConstraint procedure';
  RAISERROR (@ErrorMessage, 16, 10);

  RETURN 0;
END;
GO
