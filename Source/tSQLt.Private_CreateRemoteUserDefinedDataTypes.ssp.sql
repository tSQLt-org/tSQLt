IF OBJECT_ID('tSQLt.Private_CreateRemoteUserDefinedDataTypes') IS NOT NULL
    DROP PROCEDURE tSQLt.Private_CreateRemoteUserDefinedDataTypes;
GO
---Build+
CREATE PROCEDURE tSQLt.Private_CreateRemoteUserDefinedDataTypes @RemoteObjectID INT
AS
    BEGIN

        DECLARE @UDDTs NVARCHAR(MAX) = '';

        SELECT  @UDDTs = @UDDTs + N'CREATE TYPE ' + QUOTENAME(sch.[name])
                + N'.' + QUOTENAME(typ.[name]) + N' FROM ' + styp.[name]
                + CASE WHEN typ.[system_type_id] IN ( 41, 42, 43, 106, 108,
                                                      165, 167, 173, 175, 231,
                                                      239 )
                       THEN N'('
                            + CASE WHEN typ.[max_length] = -1 -- for: VARCHAR, NVARCHAR, VARBINARY
                                        THEN N'MAX'
                                   WHEN typ.[system_type_id] IN ( 165, 167,
                                                              173, 175 )
                          -- VARBINARY, VARCHAR, BINARY, CHAR
                                        THEN CONVERT(NVARCHAR(5), typ.[max_length])
                                   WHEN typ.[system_type_id] IN ( 231, 239 ) -- NVARCHAR, NCHAR
                                        THEN CONVERT(NVARCHAR(5), ( typ.[max_length]
                                                              / 2 ))
                                   WHEN typ.[system_type_id] IN ( 41, 42, 43 )
                          -- TIME, DATETIME2, DATETIMEOFFSET
                                        THEN CONVERT(NVARCHAR(5), typ.[scale])
                                   WHEN typ.[system_type_id] IN ( 106, 108 ) -- DECIMAL, NUMERIC
                                        THEN CONVERT(NVARCHAR(5), typ.[precision])
                                        + N', '
                                        + CONVERT(NVARCHAR(5), typ.[scale])
                              END + N')'
                       ELSE N''
                  END + CASE typ.[is_nullable]
                          WHEN 1 THEN N' NULL'
                          ELSE ' NOT NULL'
                        END + N';'
        FROM    tSQLt.Private_SysTypes typ
                INNER JOIN tSQLt.Private_SysSchemas sch ON sch.[schema_id] = typ.[schema_id]
                INNER JOIN tSQLt.Private_SysTypes styp ON styp.[user_type_id] = typ.[system_type_id]
                JOIN tSQLt.Private_SysColumns AS c ON c.user_type_id = typ.user_type_id
                JOIN tSQLt.Private_SysObjects t ON t.object_id = c.object_id
        WHERE   typ.[is_user_defined] = 1
                AND typ.[is_assembly_type] = 0
                AND typ.[is_table_type] = 0
                AND t.object_id = @RemoteObjectID
                AND NOT EXISTS ( SELECT 1
                                 FROM   sys.types t
                                        JOIN sys.schemas s ON s.schema_id = t.schema_id
                                                              AND t.[name] COLLATE SQL_Latin1_General_CP1_CI_AS = typ.[name] COLLATE SQL_Latin1_General_CP1_CI_AS
                                                              AND s.[name] COLLATE SQL_Latin1_General_CP1_CI_AS = sch.[name] COLLATE SQL_Latin1_General_CP1_CI_AS );

        EXEC (@UDDTs);   

    END;
---Build-
GO
