IF OBJECT_ID('tSQLt.Private_CreateFakeOfTable') IS NOT NULL DROP PROCEDURE tSQLt.Private_CreateFakeOfTable;
IF OBJECT_ID('tSQLt.Private_CreateFakeCloneOfTable') IS NOT NULL DROP PROCEDURE tSQLt.Private_CreateFakeCloneOfTable;
GO
---Build+
CREATE PROCEDURE tSQLt.Private_CreateFakeOfTable
  @SchemaName NVARCHAR(MAX),
  @TableName NVARCHAR(MAX),
  @OrigTableFullName NVARCHAR(MAX),
  @Identity BIT,
  @ComputedColumns BIT,
  @Defaults BIT
AS
BEGIN
   DECLARE @Cmd NVARCHAR(MAX);
   DECLARE @Cols NVARCHAR(MAX);
   
   SELECT @Cols = 
   (
    SELECT
       ',' +
       QUOTENAME(name) + 
       cc.ColumnDefinition +
       dc.DefaultDefinition + 
       id.IdentityDefinition +
       CASE WHEN cc.IsComputedColumn = 1 OR id.IsIdentityColumn = 1 
            THEN ''
            ELSE ' NULL'
       END
      FROM sys.columns c
     CROSS APPLY tSQLt.Private_GetDataTypeOrComputedColumnDefinition(c.user_type_id, c.max_length, c.precision, c.scale, c.collation_name, c.object_id, c.column_id, @ComputedColumns) cc
     CROSS APPLY tSQLt.Private_GetDefaultConstraintDefinition(c.object_id, c.column_id, @Defaults) AS dc
     CROSS APPLY tSQLt.Private_GetIdentityDefinition(c.object_id, c.column_id, @Identity) AS id
     WHERE object_id = OBJECT_ID(@OrigTableFullName)
     ORDER BY column_id
     FOR XML PATH(''), TYPE
    ).value('.', 'NVARCHAR(MAX)');
    
   SELECT @Cmd = 'CREATE TABLE ' + @SchemaName + '.' + @TableName + '(' + STUFF(@Cols,1,1,'') + ')';
   
   EXEC (@Cmd);
END;
GO

CREATE PROCEDURE tSQLt.Private_CreateFakeCloneOfTable
  @SchemaName NVARCHAR(MAX),
  @TableName NVARCHAR(MAX),
  @OrigTableFullName NVARCHAR(MAX)
AS
BEGIN
   DECLARE @name		SYSNAME;
   DECLARE @Cmd			NVARCHAR(MAX);
   DECLARE @Cols		NVARCHAR(MAX);
   DECLARE @Constraint	NVARCHAR(MAX);
   DECLARE @Verbose     BIT;
   SET @Verbose = ISNULL((SELECT CAST(Value AS BIT) FROM tSQLt.Private_GetConfiguration('Verbose')),0);
   SET @name = tSQLt.Private::CreateUniqueObjectName() + '_'

   DECLARE @Constraints TABLE (
      SourceObjectId    INT
     ,object_id			INT
     ,ConstraintType	SYSNAME
     ,name				SYSNAME
     ,index_id			SMALLINT
     ,sql				NVARCHAR(MAX)
   );

   INSERT
     INTO @Constraints
   SELECT OBJECT_ID(@OrigTableFullName) as SourceObjectId
         ,*
         ,NULL as sql
     FROM tSQLt.Private_FindAllConstraints(OBJECT_ID(@OrigTableFullName));
   
   SELECT @Cols = 
     (
         SELECT  ','+ QUOTENAME(columns.name)
                +cc.ColumnDefinition
                +id.IdentityDefinition
                +CASE WHEN cc.IsComputedColumn = 1 OR id.IsIdentityColumn = 1 
                      THEN ''
                      WHEN columns.is_nullable = 0
                      THEN ' NOT NULL'
                      ELSE ' NULL'
                END
                +ISNULL(' CONSTRAINT ' + QUOTENAME(RIGHT(@name + default_constraints.name,255))
                +' DEFAULT ' + default_constraints.definition+' ','')
           FROM sys.columns
           JOIN (
                   SELECT SourceObjectId
                     FROM @Constraints
                 GROUP BY SourceObjectId
                ) Src
             ON Src.SourceObjectId = columns.object_id
           LEFT
           JOIN sys.default_constraints
             ON default_constraints.parent_object_id = columns.object_id
            AND default_constraints.parent_column_id = columns.column_id
          CROSS
          APPLY tSQLt.Private_GetDataTypeOrComputedColumnDefinition(columns.user_type_id, columns.max_length, columns.precision, columns.scale, columns.collation_name, columns.object_id, columns.column_id, 1) cc
          CROSS
          APPLY tSQLt.Private_GetIdentityDefinition(columns.object_id, columns.column_id, 1) AS id
       ORDER BY column_id
         FOR XML PATH(''), TYPE
        ).value('.', 'NVARCHAR(MAX)'
    );

  UPDATE Constraints
     SET sql =
         ',CONSTRAINT '
        +QUOTENAME(RIGHT(@name + Constraints.name,255))
        +' '
        +CASE key_constraints.type_desc 
               WHEN 'UNIQUE_CONSTRAINT' 
              THEN 'UNIQUE'
              ELSE 'PRIMARY KEY'
          END
        +'('
        +STUFF((
                  SELECT ','+QUOTENAME(columns.name)+CASE index_columns.is_descending_key WHEN 1 THEN ' DESC' ELSE ' ASC' END
                    FROM sys.index_columns
                    JOIN sys.columns
                      ON index_columns.object_id = columns.object_id
                     AND index_columns.column_id = columns.column_id
                   WHERE key_constraints.unique_index_id = index_columns.index_id
                     AND key_constraints.parent_object_id = index_columns.object_id
                     FOR XML PATH(''),TYPE
                ).value('.','NVARCHAR(MAX)'),
                1,
                1,
                ''
               )
          +')' 
    FROM sys.key_constraints
    JOIN @Constraints Constraints
      ON Constraints.object_id = key_constraints.object_id;

  UPDATE Constraints
     SET sql =
         ',CONSTRAINT ' + QUOTENAME(RIGHT(@name + Constraints.name,255)) + ' CHECK ' + definition 
   FROM sys.check_constraints
   JOIN @Constraints Constraints
     ON Constraints.object_id = check_constraints.object_id;


  UPDATE Constraints
     SET sql =
          ',CONSTRAINT ' + QUOTENAME(RIGHT(@name + Constraints.name,255))
         +' FOREIGN KEY (' + parCol.ColNames + ')' 
         +' REFERENCES ' 
         + ISNULL(QUOTENAME(OBJECT_SCHEMA_NAME(renamed.ObjectId)) + '.' + renamed.OriginalName
                 ,QUOTENAME(OBJECT_SCHEMA_NAME(foreign_keys.referenced_object_id)) + '.' + QUOTENAME(OBJECT_NAME(foreign_keys.referenced_object_id))
                 )
         +'(' + refCol.ColNames + ')'
         +'ON DELETE '
         +CASE foreign_keys.delete_referential_action
               WHEN 0 THEN 'NO ACTION'
               WHEN 1 THEN 'CASCADE'
               WHEN 2 THEN 'SET NULL'
               WHEN 3 THEN 'SET DEFAULT'
          END
         +' '
         +'ON UPDATE '
         +CASE foreign_keys.update_referential_action
               WHEN 0 THEN 'NO ACTION'
               WHEN 1 THEN 'CASCADE'
               WHEN 2 THEN 'SET NULL'
               WHEN 3 THEN 'SET DEFAULT'
          END
     FROM sys.foreign_keys
     JOIN @Constraints Constraints
       ON Constraints.object_id = foreign_keys.object_id
     LEFT
     JOIN tSQLt.Private_RenamedObjectLog renamed
       ON renamed.ObjectId = foreign_keys.referenced_object_id
    CROSS
    APPLY tSQLt.Private_GetForeignKeyParColumns(foreign_keys.object_id) AS parCol
    CROSS
    APPLY tSQLt.Private_GetForeignKeyRefColumns(foreign_keys.object_id) AS refCol;

  UPDATE Constraints
     SET sql =
          ',CONSTRAINT ' + QUOTENAME(RIGHT(@name + Constraints.name,255))
         +' FOREIGN KEY (' + parCol.ColNames + ')' 
         +' REFERENCES ' + QUOTENAME(OBJECT_SCHEMA_NAME(renamed.ObjectId)) + '.' + renamed.OriginalName
         +'(' + refCol.ColNames + ')'
         +'ON DELETE '
         +CASE foreign_keys.delete_referential_action
               WHEN 0 THEN 'NO ACTION'
               WHEN 1 THEN 'CASCADE'
               WHEN 2 THEN 'SET NULL'
               WHEN 3 THEN 'SET DEFAULT'
          END
         +' '
         +'ON UPDATE '
         +CASE foreign_keys.update_referential_action
               WHEN 0 THEN 'NO ACTION'
               WHEN 1 THEN 'CASCADE'
               WHEN 2 THEN 'SET NULL'
               WHEN 3 THEN 'SET DEFAULT'
          END
     FROM sys.foreign_keys
     JOIN @Constraints Constraints
       ON Constraints.object_id = foreign_keys.object_id
     JOIN tSQLt.Private_RenamedObjectLog renamed
       ON renamed.ObjectId = foreign_keys.referenced_object_id
    CROSS
    APPLY tSQLt.Private_GetForeignKeyParColumns(foreign_keys.object_id) AS parCol
    CROSS
    APPLY tSQLt.Private_GetForeignKeyRefColumns(foreign_keys.object_id) AS refCol;

  UPDATE Constraints
     SET sql =
          ',INDEX '
         +QUOTENAME(RIGHT(@name + Constraints.name,255))
         +' '
         +CASE WHEN indexes.is_unique = 1 THEN 'UNIQUE ' ELSE '' END + indexes.type_desc
         +' ('
         +STUFF((
                  SELECT ','+QUOTENAME(columns.name)+CASE index_columns.is_descending_key WHEN 1 THEN ' DESC' ELSE ' ASC' END
                    FROM sys.index_columns
                    JOIN sys.columns
                      ON index_columns.object_id = columns.object_id
                     AND index_columns.column_id = columns.column_id
                   WHERE indexes.index_id = index_columns.index_id
                     AND indexes.object_id = index_columns.object_id
                     FOR XML PATH(''),TYPE
                ).value('.','NVARCHAR(MAX)'),
                1,
                1,
                ''
               )
         +')' 
         +ISNULL(' WHERE ' + indexes.filter_definition,'') 
    FROM sys.indexes
    JOIN @Constraints Constraints
      ON Constraints.object_id = indexes.object_id
     AND Constraints.index_id = indexes.index_id
   WHERE indexes.is_unique_constraint = 0
     AND indexes.is_primary_key = 0;
 
   SELECT @Constraint = 
   (
      SELECT sql
        FROM @Constraints
      FOR XML PATH(''), TYPE
   ).value('.', 'NVARCHAR(MAX)');
 
   SELECT @Cmd = 
     'CREATE TABLE ' 
   + @SchemaName 
   + '.' 
   + @TableName 
   + '(' 
   + STUFF(@Cols,1,1,'') 
   + ISNULL(STUFF(@Constraint,1,0,''),'')
   + ')';

   IF @Verbose = 1
     SELECT @cmd;

   EXEC (@Cmd);
END;
GO
---Build-
GO
