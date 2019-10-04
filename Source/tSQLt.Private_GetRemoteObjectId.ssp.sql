IF OBJECT_ID('tSQLt.Private_GetRemoteObjectId') IS NOT NULL
    DROP PROCEDURE tSQLt.Private_GetRemoteObjectId;
GO
---Build+
GO
CREATE PROCEDURE tSQLt.Private_GetRemoteObjectId
    @OrigTableFullName NVARCHAR(MAX) ,
    @RemoteObjectId INT OUTPUT
AS
    BEGIN
        DECLARE @RemotePath NVARCHAR(MAX) = COALESCE(QUOTENAME(PARSENAME(@OrigTableFullName, 4))+ '.', '')
            + QUOTENAME(PARSENAME(@OrigTableFullName, 3));
        DECLARE @Cmd NVARCHAR(MAX);
        DECLARE @params NVARCHAR(MAX) = '@RemoteObjectID INT OUT, @OrigTableFullName NVARCHAR(MAX)';
        SET @Cmd = '
        SELECT  @RemoteObjectID = o.object_id
        FROM    ' + @RemotePath + '.sys.objects o
                JOIN ' + @RemotePath
            + '.sys.schemas s ON s.schema_id = o.schema_id
        WHERE   s.name = PARSENAME(@OrigTableFullName, 2)
                AND o.name = PARSENAME(@OrigTableFullName, 1)
                AND o.type IN ( ''U'', ''V'' );';

        EXEC sp_executesql @Cmd, @params, @RemoteObjectID OUT,
            @OrigTableFullName;
    END;
GO
---Build-
GO
