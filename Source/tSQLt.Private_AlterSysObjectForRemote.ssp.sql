IF OBJECT_ID('tSQLt.Private_AlterSysObjectForRemote') IS NOT NULL
    DROP PROCEDURE tSQLt.Private_AlterSysObjectForRemote;
GO
---Build+
CREATE PROCEDURE tSQLt.Private_AlterSysObjectForRemote
    @Instance NVARCHAR(MAX) ,
    @Database NVARCHAR(MAX) ,
    @SysObject NVARCHAR(MAX) ,
    @PrivateViewName NVARCHAR(MAX)
AS
    BEGIN
        DECLARE @sql NVARCHAR(MAX); 
        SET @sql = 'ALTER VIEW tSQLt.' + @PrivateViewName + ' AS 
                SELECT ' +
                CASE WHEN @SysObject = 'types' THEN '
  name ,
        system_type_id ,
        user_type_id ,
        CASE WHEN is_user_defined = 1 THEN 1
             ELSE schema_id
        END AS schema_id ,
        principal_id ,
        max_length ,
        precision ,
        scale ,
        collation_name ,
        is_nullable ,
        is_user_defined ,
        is_assembly_type ,
        default_object_id ,
        rule_object_id ,
        is_table_type
                ' ELSE '* ' END
            + CASE WHEN CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(MAX)) LIKE '9.%'
                        AND @SysObject = 'types' THEN ',0 is_table_type'
                   ELSE ''
              END + ' FROM ' + COALESCE(QUOTENAME(@Instance) + '.', '')
            + COALESCE(QUOTENAME(@Database) + '.', '') + 'sys.' + @SysObject
            + ';';
        
        
        
        
        EXEC (@sql);

        RETURN 0;
    END;
---Build-
GO