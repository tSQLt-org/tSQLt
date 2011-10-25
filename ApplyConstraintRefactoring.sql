DROP FUNCTION tSQLt.Private_GetOriginalTableInfo;
GO
 
CREATE FUNCTION tSQLt.Private_GetOriginalTableInfo(@TableObjectId INT)
RETURNS TABLE
AS
  RETURN SELECT CAST(value AS NVARCHAR(4000)) OrgTableName,
                OBJECT_ID(QUOTENAME(OBJECT_SCHEMA_NAME(@TableObjectId)) + '.' + QUOTENAME(CAST(value AS NVARCHAR(4000)))) OrgTableObjectId
    FROM sys.extended_properties
   WHERE class_desc = 'OBJECT_OR_COLUMN'
     AND major_id = @TableObjectId
     AND minor_id = 0
     AND name = 'tSQLt.FakeTable_OrgTableName';
GO

DROP FUNCTION tSQLt.Private_GetQuotedTableNameForConstraint
GO
CREATE FUNCTION tSQLt.Private_GetQuotedTableNameForConstraint(@ConstraintObjectId INT)
RETURNS TABLE
AS
RETURN
  SELECT QUOTENAME(SCHEMA_NAME(newtbl.schema_id)) + '.' + QUOTENAME(OBJECT_NAME(newtbl.object_id)) QuotedTableName,
         SCHEMA_NAME(newtbl.schema_id) SchemaName,
         OBJECT_NAME(newtbl.object_id) TableName,
         OBJECT_NAME(constraints.parent_object_id) OrgTableName
      FROM sys.objects AS constraints
      JOIN sys.extended_properties AS p
      JOIN sys.objects AS newtbl
        ON newtbl.object_id = p.major_id
       AND p.minor_id = 0
       AND p.class_desc = 'OBJECT_OR_COLUMN'
       AND p.name = 'tSQLt.FakeTable_OrgTableName'
        ON OBJECT_NAME(constraints.parent_object_id) = CAST(p.value AS NVARCHAR(4000))
       AND constraints.schema_id = newtbl.schema_id
       AND constraints.object_id = @ConstraintObjectId;
GO

DROP FUNCTION tSQLt.Private_FindConstraint;
GO
CREATE FUNCTION tSQLt.Private_FindConstraint
(
  @TableObjectId INT,
  @ConstraintName NVARCHAR(MAX)
)
RETURNS TABLE
AS
RETURN
  SELECT TOP(1) constraints.object_id AS ConstraintObjectId, type_desc AS ConstraintType
    FROM sys.objects constraints
    CROSS JOIN tSQLt.Private_GetOriginalTableInfo(@TableObjectId) orgTbl
   WHERE @ConstraintName IN (constraints.name, QUOTENAME(constraints.name))
     AND constraints.parent_object_id = orgTbl.OrgTableObjectId
   ORDER BY LEN(constraints.name) ASC;
GO

DROP FUNCTION tSQLt.Private_ResolveApplyConstraintParameters;
GO
CREATE FUNCTION tSQLt.Private_ResolveApplyConstraintParameters
(
  @A NVARCHAR(MAX),
  @B NVARCHAR(MAX),
  @C NVARCHAR(MAX)
)
RETURNS TABLE
AS 
RETURN
  SELECT ConstraintObjectId, ConstraintType
    FROM tSQLt.Private_FindConstraint(OBJECT_ID(@A), @B)
   WHERE @C IS NULL
   UNION ALL
  SELECT *
    FROM tSQLt.Private_FindConstraint(OBJECT_ID(@A + '.' + @B), @C)
   UNION ALL
  SELECT *
    FROM tSQLt.Private_FindConstraint(OBJECT_ID(@C + '.' + @A), @B);
GO

DROP PROCEDURE tSQLt.Private_ApplyCheckConstraint;
GO
CREATE PROCEDURE tSQLt.Private_ApplyCheckConstraint
  @ConstraintObjectId INT
AS
BEGIN
  DECLARE @Cmd NVARCHAR(MAX);
  SELECT @Cmd = 'CONSTRAINT ' + QUOTENAME(name) + ' CHECK' + definition 
    FROM sys.check_constraints
   WHERE object_id = @ConstraintObjectId;
  
  DECLARE @QuotedTableName NVARCHAR(MAX);
  
  SELECT @QuotedTableName = QuotedTableName FROM tSQLt.Private_GetQuotedTableNameForConstraint(@ConstraintObjectId);

  EXEC tSQLt.Private_RenameObjectToUniqueNameUsingObjectId @ConstraintObjectId;
  SELECT @Cmd = 'ALTER TABLE ' + @QuotedTableName + ' ADD ' + @Cmd
    FROM sys.objects 
   WHERE object_id = @ConstraintObjectId;

  EXEC (@Cmd);

END; 
GO

DROP PROCEDURE tSQLt.Private_ApplyForeignKeyConstraint;
GO

CREATE PROCEDURE tSQLt.Private_ApplyForeignKeyConstraint 
  @ConstraintObjectId INT
AS
BEGIN
  DECLARE @SchemaName NVARCHAR(MAX);
  DECLARE @OrgTableName NVARCHAR(MAX);
  DECLARE @TableName NVARCHAR(MAX);
  DECLARE @ConstraintName NVARCHAR(MAX);
  DECLARE @CreateFkCmd NVARCHAR(MAX);
  DECLARE @AlterTableCmd NVARCHAR(MAX);
  DECLARE @CreateIndexCmd NVARCHAR(MAX);
  DECLARE @FinalCmd NVARCHAR(MAX);
  
  SELECT @SchemaName = SchemaName,
         @OrgTableName = OrgTableName,
         @TableName = TableName,
         @ConstraintName = OBJECT_NAME(@ConstraintObjectId)
    FROM tSQLt.Private_GetQuotedTableNameForConstraint(@ConstraintObjectId);
      
  SELECT @CreateFkCmd = cmd, @CreateIndexCmd = CreIdxCmd
    FROM tSQLt.Private_GetForeignKeyDefinition(@SchemaName, @OrgTableName, @ConstraintName);
  SELECT @AlterTableCmd = 'ALTER TABLE ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + 
                          ' ADD ' + @CreateFkCmd;
  SELECT @FinalCmd = @CreateIndexCmd + @AlterTableCmd;

  EXEC tSQLt.Private_RenameObjectToUniqueName @SchemaName, @ConstraintName;
  EXEC (@FinalCmd);
END;
GO

DROP FUNCTION tSQLt.Private_GetConstraintType;
GO
CREATE FUNCTION tSQLt.Private_GetConstraintType(@TableObjectId INT, @ConstraintName NVARCHAR(MAX))
RETURNS TABLE
AS
RETURN
  SELECT object_id,type,type_desc
    FROM sys.objects 
   WHERE object_id = OBJECT_ID(SCHEMA_NAME(schema_id)+'.'+@ConstraintName)
     AND parent_object_id = @TableObjectId;
GO


DROP PROCEDURE tSQLt.ApplyConstraint;
GO
CREATE PROCEDURE tSQLt.ApplyConstraint
       @TableName NVARCHAR(MAX),
       @ConstraintName NVARCHAR(MAX),
       @SchemaName NVARCHAR(MAX) = NULL --parameter preserved for backward compatibility. Do not use. Will be removed soon.
AS
BEGIN
  DECLARE @ConstraintType NVARCHAR(MAX);
  DECLARE @ConstraintObjectId INT;
  
  SELECT @ConstraintType = ConstraintType, @ConstraintObjectId = ConstraintObjectId
    FROM tSQLt.Private_ResolveApplyConstraintParameters (@TableName, @ConstraintName, @SchemaName);

  IF @ConstraintType = 'CHECK_CONSTRAINT'
  BEGIN
    EXEC tSQLt.Private_ApplyCheckConstraint @ConstraintObjectId;
    RETURN 0;
  END

  IF @ConstraintType = 'FOREIGN_KEY_CONSTRAINT'
  BEGIN
    EXEC tSQLt.Private_ApplyForeignKeyConstraint @ConstraintObjectId;
    RETURN 0;
  END;  
   
  RAISERROR ('ApplyConstraint could not resolve the object names, ''%s'', ''%s''. Be sure to call ApplyConstraint and pass in two parameters, such as: EXEC tSQLt.ApplyConstraint ''MySchema.MyTable'', ''MyConstraint''', 
             16, 10, @TableName, @ConstraintName);
  RETURN 0;
END;
GO