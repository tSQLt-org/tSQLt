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
                SELECT * '
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