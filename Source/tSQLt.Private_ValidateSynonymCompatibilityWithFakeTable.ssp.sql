IF OBJECT_ID('tSQLt.Private_ValidateSynonymCompatibilityWithFakeTable') IS NOT NULL
    DROP PROCEDURE tSQLt.Private_ValidateSynonymCompatibilityWithFakeTable;
GO
---Build+
GO
CREATE PROCEDURE tSQLt.Private_ValidateSynonymCompatibilityWithFakeTable
    @TableName sysname ,
    @SchemaName sysname ,
    @OrigTableFullName sysname
AS
    BEGIN
         
        IF NOT EXISTS ( SELECT  1
                        FROM    tSQLt.Private_SysObjects o
                                JOIN tSQLt.Private_SysSchemas s ON s.schema_id = o.schema_id
                        WHERE   o.type IN ( 'U', 'V' )
                                AND o.name = PARSENAME(@OrigTableFullName, 1)
                                AND s.name = PARSENAME(@OrigTableFullName, 2) )
            BEGIN
                RAISERROR('Cannot fake synonym %s.%s as it is pointing to %s, which is not a table or view!',16,10,@SchemaName,@TableName,@OrigTableFullName);
            END;
    END;
GO
  