IF OBJECT_ID('tSQLt.Private_CreateRemoteSysObjects') IS NOT NULL
    DROP PROCEDURE tSQLt.Private_CreateRemoteSysObjects;
GO
---Build+
CREATE PROCEDURE tSQLt.Private_CreateRemoteSysObjects
    @Instance NVARCHAR(MAX) ,
    @Database NVARCHAR(MAX)
AS
    BEGIN
        DECLARE @SysObject NVARCHAR(MAX);
        DECLARE @ViewName NVARCHAR(MAX);


        DECLARE @SysObjects AS TABLE
            (
              SysObject NVARCHAR(MAX) ,
              ViewName NVARCHAR(MAX)
            );
        INSERT  INTO @SysObjects
        VALUES  ( 'types', 'Private_SysTypes' ),
                ( 'computed_columns', 'Private_SysComputedColumns' ),
                ( 'default_constraints', 'Private_SysDefaultConstraints' ),
                ( 'identity_columns', 'Private_SysIdentityColumns' ),
                ( 'columns', 'Private_SysColumns' ),
                ( 'objects', 'Private_SysObjects' );

        DECLARE @cursor AS CURSOR;
 
        SET @cursor = CURSOR FOR
SELECT SysObject, ViewName
 FROM @SysObjects;
 
        OPEN @cursor;
        FETCH NEXT FROM @cursor INTO @SysObject, @ViewName;
 
        WHILE @@FETCH_STATUS = 0
            BEGIN
                EXEC tSQLt.Private_AlterSysObjectForRemote @Instance = @Instance,
                    @Database = @Database, @SysObject = @SysObject,
                    @PrivateViewName = @ViewName;

                FETCH NEXT FROM @cursor INTO @SysObject, @ViewName;
            END;
 
        CLOSE @cursor;
        DEALLOCATE @cursor;

        RETURN 0;
    END;
---Build-
GO
