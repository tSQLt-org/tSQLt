GO
/*******************************************************************************************/
/*******************************************************************************************/
/*******************************************************************************************/
GO
CREATE PROCEDURE tSQLt.StubRecord(@SnTableName AS NVARCHAR(MAX), @BintObjId AS BIGINT)  
AS   
BEGIN  

    RAISERROR('Warning, tSQLt.StubRecord is not currently supported. Use at your own risk!', 0, 1) WITH NOWAIT;

    DECLARE @VcInsertStmt NVARCHAR(MAX),  
            @VcInsertValues NVARCHAR(MAX);  
    DECLARE @SnColumnName NVARCHAR(MAX); 
    DECLARE @SintDataType SMALLINT; 
    DECLARE @NvcFKCmd NVARCHAR(MAX);  
    DECLARE @VcFKVal NVARCHAR(MAX); 
  
    SET @VcInsertStmt = 'INSERT INTO ' + @SnTableName + ' ('  
      
    DECLARE curColumns CURSOR  
        LOCAL FAST_FORWARD  
    FOR  
    SELECT syscolumns.name,  
           syscolumns.xtype,  
           cmd.cmd  
    FROM syscolumns  
        LEFT OUTER JOIN dbo.sysconstraints ON syscolumns.id = sysconstraints.id  
                                      AND syscolumns.colid = sysconstraints.colid  
                                      AND sysconstraints.status = 1    -- Primary key constraints only  
        LEFT OUTER JOIN (select fkeyid id,fkey colid,N'select @V=cast(min('+syscolumns.name+') as NVARCHAR) from '+sysobjects.name cmd  
                        from sysforeignkeys   
                        join sysobjects on sysobjects.id=sysforeignkeys.rkeyid  
                        join syscolumns on sysobjects.id=syscolumns.id and syscolumns.colid=rkey) cmd  
            on cmd.id=syscolumns.id and cmd.colid=syscolumns.colid  
    WHERE syscolumns.id = OBJECT_ID(@SnTableName)  
      AND (syscolumns.isnullable = 0 )  
    ORDER BY ISNULL(sysconstraints.status, 9999), -- Order Primary Key constraints first  
             syscolumns.colorder  
  
    OPEN curColumns  
  
    FETCH NEXT FROM curColumns  
    INTO @SnColumnName, @SintDataType, @NvcFKCmd  
  
    -- Treat the first column retrieved differently, no commas need to be added  
    -- and it is the ObjId column  
    IF @@FETCH_STATUS = 0  
    BEGIN  
        SET @VcInsertStmt = @VcInsertStmt + @SnColumnName  
        SELECT @VcInsertValues = ')VALUES(' + ISNULL(CAST(@BintObjId AS nvarchar), 'NULL')  
  
        FETCH NEXT FROM curColumns  
        INTO @SnColumnName, @SintDataType, @NvcFKCmd  
    END  
    ELSE  
    BEGIN  
        -- No columns retrieved, we need to insert into any first column  
        SELECT @VcInsertStmt = @VcInsertStmt + syscolumns.name  
        FROM syscolumns  
        WHERE syscolumns.id = OBJECT_ID(@SnTableName)  
          AND syscolumns.colorder = 1  
  
        SELECT @VcInsertValues = ')VALUES(' + ISNULL(CAST(@BintObjId AS nvarchar), 'NULL')  
  
    END  
  
    WHILE @@FETCH_STATUS = 0  
    BEGIN  
        SET @VcInsertStmt = @VcInsertStmt + ',' + @SnColumnName  
        SET @VcFKVal=',0'  
        if @NvcFKCmd is not null  
        BEGIN  
            set @VcFKVal=null  
            exec sp_executesql @NvcFKCmd,N'@V NVARCHAR(MAX) output',@VcFKVal output  
            set @VcFKVal=isnull(','''+@VcFKVal+'''',',NULL')  
        END  
        SET @VcInsertValues = @VcInsertValues + @VcFKVal  
  
        FETCH NEXT FROM curColumns  
        INTO @SnColumnName, @SintDataType, @NvcFKCmd  
    END  
      
    CLOSE curColumns  
    DEALLOCATE curColumns  
  
    SET @VcInsertStmt = @VcInsertStmt + @VcInsertValues + ')'  
  
    IF EXISTS (SELECT 1   
               FROM syscolumns  
               WHERE status = 128   
                 AND id = OBJECT_ID(@SnTableName))  
    BEGIN  
        SET @VcInsertStmt = 'SET IDENTITY_INSERT ' + @SnTableName + ' ON ' + CHAR(10) +   
                             @VcInsertStmt + CHAR(10) +   
                             'SET IDENTITY_INSERT ' + @SnTableName + ' OFF '  
    END  
  
    EXEC (@VcInsertStmt)    -- Execute the actual INSERT statement  
  
END  

GO