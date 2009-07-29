DECLARE @msg VARCHAR(MAX);SELECT @msg = 'Compiled at '+CONVERT(VARCHAR,GETDATE(),121);RAISERROR(@msg,0,1);
GO
--IF OBJECT_ID('tSQLt.TestCaseSummary') IS NOT NULL DROP FUNCTION tSQLt.TestCaseSummary;
--IF OBJECT_ID('tSQLt.RunTestClass') IS NOT NULL DROP PROCEDURE tSQLt.RunTestClass;
--IF OBJECT_ID('tSQLt.RunTest') IS NOT NULL DROP PROCEDURE tSQLt.RunTest;
--IF OBJECT_ID('tSQLt.private_RunTest') IS NOT NULL DROP PROCEDURE tSQLt.private_RunTest;
--IF OBJECT_ID('tSQLt.Fail') IS NOT NULL DROP PROCEDURE tSQLt.Fail;
--IF OBJECT_ID('tSQLt.private_Print') IS NOT NULL DROP PROCEDURE tSQLt.private_Print;
--IF OBJECT_ID('tSQLt.TestMessage') IS NOT NULL DROP TABLE tSQLt.TestMessage;
--IF OBJECT_ID('tSQLt.TestResult') IS NOT NULL DROP TABLE tSQLt.TestResult;
--IF OBJECT_ID('tSQLt.DropClass') IS NOT NULL DROP PROCEDURE tSQLt.DropClass;
--IF EXISTS(SELECT 1 FROM sys.schemas WHERE name = 'tSQLt') DROP SCHEMA tSQLt;
IF EXISTS(SELECT 1 FROM sys.schemas WHERE name = 'tSQLt') EXEC tSQLt.DropClass tSQLt;
GO
CREATE SCHEMA tSQLt;
GO
CREATE PROCEDURE tSQLt.DropClass
    @ClassName SYSNAME
AS
BEGIN
    DECLARE @cmd NVARCHAR(MAX);

    WITH A(name, type) AS
           (SELECT QUOTENAME(SCHEMA_NAME(schema_id))+'.'+QUOTENAME(name) , type
              FROM sys.objects
             WHERE schema_id = SCHEMA_ID(@ClassName)
          ),
         B(no,cmd) AS
           (SELECT 0,'DROP ' +
                    CASE type WHEN 'P' THEN 'PROCEDURE'
                              WHEN 'U' THEN 'TABLE'
                              WHEN 'IF' THEN 'FUNCTION'
                              WHEN 'TF' THEN 'FUNCTION'
                              WHEN 'FN' THEN 'FUNCTION'
                              WHEN 'V' THEN 'VIEW'
                     END +
                   ' ' + name + ';'
              FROM A
             UNION ALL
            SELECT -1,'DROP SCHEMA ' + QUOTENAME(name) +';'
              FROM sys.schemas
             WHERE schema_id = SCHEMA_ID(@ClassName)
           ),
         C(xml)AS
           (SELECT cmd [text()]
              FROM B
             ORDER BY no DESC
               FOR XML PATH(''), TYPE
           )
    SELECT @cmd = xml.value('/', 'NVARCHAR(MAX)') 
      FROM C;

    EXEC(@cmd);
END;
GO

CREATE FUNCTION tSQLt.private_getForeignKeyDefinition(
    @SchemaName SYSNAME,
    @ParentTableName SYSNAME,
    @ForeignKeyName SYSNAME
)
RETURNS TABLE
AS
RETURN SELECT 'CONSTRAINT ' + name + ' FOREIGN KEY (' +
              parCol + ') REFERENCES ' + refName + '(' + refCol + ')' cmd
         FROM (SELECT SCHEMA_NAME(k.schema_id) SchemaName,k.name, OBJECT_NAME(k.parent_object_id) parName,
                      SCHEMA_NAME(refTab.schema_id)+'.'+refTab.name refName,parCol.name parCol,refCol.name refCol
                 FROM sys.foreign_keys k
                 JOIN sys.foreign_key_columns c
                   ON k.object_id = c.constraint_object_id
                 JOIN sys.columns parCol
                   ON parCol.object_id = c.parent_object_id
                  AND parCol.column_id = c.parent_column_id
                 JOIN sys.columns refCol
                   ON refCol.object_id = c.referenced_object_id
                  AND refCol.column_id = c.referenced_column_id
                 JOIN sys.tables refTab
                   ON refCol.object_id = refTab.object_id
                WHERE k.parent_object_id = OBJECT_ID(@SchemaName + '.' + @ParentTableName)
                  AND k.object_id = OBJECT_ID(@SchemaName + '.' + @ForeignKeyName)
               )x;
GO

CREATE TABLE tSQLt.TestResult(
    ID INT IDENTITY(1,1) PRIMARY KEY CLUSTERED,
    Name VARCHAR(MAX) NOT NULL,
    TranName VARCHAR(MAX) NOT NULL,
    Result VARCHAR(MAX) NULL,
    Msg VARCHAR(MAX) NULL
);
GO
CREATE TABLE tSQLt.TestMessage(
    Msg VARCHAR(MAX)
);
GO
CREATE TABLE tSQLt.Run_LastExecution(
    testName VARCHAR(MAX),
    session_id INT,
    login_time DATETIME
);
GO

CREATE PROCEDURE tSQLt.private_Print 
    @message VARCHAR(MAX),
    @severity INT = 0
AS 
BEGIN
    DECLARE @sPos INT;SET @sPos = 1;
    DECLARE @ePos INT;
    DECLARE @len INT; SELECT @len = LEN(@message);
    DECLARE @subMsg VARCHAR(MAX);
    DECLARE @cmd NVARCHAR(MAX);
    
    WHILE (@sPos <= @len)
    BEGIN
      SELECT @ePos = CHARINDEX(CHAR(13)+CHAR(10),@message+CHAR(13)+CHAR(10),@sPos);
      SELECT @subMsg = SUBSTRING(@message, @sPos, @ePos - @sPos);
      SELECT @cmd = N'RAISERROR(@msg,@severity,10) WITH NOWAIT;';
      EXEC sp_executesql @cmd, 
                         N'@msg VARCHAR(MAX),@severity INT',
                         @subMsg,
                         @severity;
      SELECT @sPos = @ePos + 2,
             @severity = 0; --Print only first line with high severity
    END

    RETURN 0;
END;
GO


CREATE PROCEDURE tSQLt.getNewTranName
  @TranName CHAR(32) OUTPUT
AS
BEGIN
  SELECT @TranName = LEFT('tSQLtTran'+REPLACE(CAST(NEWID() AS VARCHAR(60)),'-',''),32);
END;
GO

CREATE PROCEDURE tSQLt.Fail
    @Message0 VARCHAR(MAX) = '',
    @Message1 VARCHAR(MAX) = '',
    @Message2 VARCHAR(MAX) = '',
    @Message3 VARCHAR(MAX) = '',
    @Message4 VARCHAR(MAX) = '',
    @Message5 VARCHAR(MAX) = '',
    @Message6 VARCHAR(MAX) = '',
    @Message7 VARCHAR(MAX) = '',
    @Message8 VARCHAR(MAX) = '',
    @Message9 VARCHAR(MAX) = ''
AS
BEGIN
   INSERT INTO tSQLt.TestMessage(Msg) SELECT @Message0+@Message1+@Message2+@Message3+@Message4+@Message5+@Message6+@Message7+@Message8+@Message9;
   RAISERROR('tSQLt.Failure',16,10);
END;
GO

CREATE PROCEDURE tSQLt.private_RunTest
   @testName VARCHAR(MAX),
   @SetUp NVARCHAR(MAX) = NULL
AS
BEGIN
    DECLARE @Msg VARCHAR(MAX); SET @Msg = '';
    DECLARE @Msg2 VARCHAR(MAX); SET @Msg2 = '';
    DECLARE @cmd VARCHAR(MAX); SET @cmd = '';
    DECLARE @Result VARCHAR(MAX); SET @Result = 'Success';
    DECLARE @TranName CHAR(32); EXEC tSQLt.getNewTranName @TranName OUT;
    DECLARE @TestResultID INT;

    SELECT @cmd = 'EXEC ' + @testName;

    INSERT INTO tSQLt.TestResult(Name, TranName) 
        SELECT @testName, @TranName;
    SELECT @TestResultID = SCOPE_IDENTITY();

    BEGIN TRAN;
    SAVE TRAN @TranName;

    TRUNCATE TABLE tSQLt.TestMessage;

    BEGIN TRY
        IF (@SetUp IS NOT NULL) EXEC @SetUp;
        EXEC (@cmd);
    END TRY
    BEGIN CATCH
        IF ERROR_MESSAGE() = 'tSQLt.Failure'
        BEGIN
            SELECT @Msg = Msg FROM tSQLt.TestMessage;
            SET @Result = 'Failure';
        END
        ELSE
        BEGIN
            SELECT @Msg = COALESCE(ERROR_MESSAGE(), '<ERROR_MESSAGE() is NULL>') + '{' + COALESCE(ERROR_PROCEDURE(), '<ERROR_PROCEDURE() is NULL>') + ',' + COALESCE(CAST(ERROR_LINE() AS VARCHAR), '<ERROR_LINE() is NULL>') + '}';
--RAISERROR(@Msg,16,10)WITH NOWAIT;
            SET @Result = 'Error';
        END;
    END CATCH

    BEGIN TRY
        ROLLBACK TRAN @TranName;
    END TRY
    BEGIN CATCH
        IF (@@TRANCOUNT > 0) ROLLBACK;

        BEGIN TRAN;
        SELECT @Msg = COALESCE(@Msg, '<NULL>') + ' (There was also a ROLLBACK ERROR --> ' + COALESCE(ERROR_MESSAGE(), '<ERROR_MESSAGE() is NULL>') + '{' + COALESCE(ERROR_PROCEDURE(), '<ERROR_PROCEDURE() is NULL>') + ',' + COALESCE(CAST(ERROR_LINE() AS VARCHAR), '<ERROR_LINE() is NULL>') + '})';
        SET @Result = 'Error';
    END CATCH    

-- delete this block soon!
If(@Result <> 'Success') 
BEGIN
  SET @Msg2 = @testName + ' failed: ' + @Msg;
  EXEC tSQLt.private_Print @message = @Msg2, @severity = 0;
END

    IF EXISTS(SELECT 1 FROM tSQLt.TestResult WHERE ID = @TestResultID)
    BEGIN
        UPDATE tSQLt.TestResult SET
            Result = @Result,
            Msg = @Msg
         WHERE ID = @TestResultID;
    END
    ELSE
    BEGIN
        INSERT tSQLt.TestResult(Name, TranName, Result, Msg)
        SELECT @testName, 
               '?', 
               'Error', 
               'TestResult entry is missing; Original outcome: ' + @Result + ', ' + @Msg;
    END    
      

    COMMIT;
END;
GO

CREATE PROCEDURE tSQLt.private_CleanTestResult
AS
BEGIN
   DELETE FROM tSQLt.TestResult;
END
GO

CREATE PROCEDURE tSQLt.RunTest
   @testName VARCHAR(MAX)
AS
BEGIN
SET NOCOUNT ON;
    DECLARE @Result VARCHAR(MAX); SET @Result = 'Success';
    DECLARE @msg VARCHAR(MAX);

    EXEC tSQLt.private_CleanTestResult;
    
    SELECT @testName = '['+OBJECT_SCHEMA_NAME(OBJECT_ID(@testName))+'].['+OBJECT_NAME(OBJECT_ID(@testName))+']';
    EXEC tSQLt.private_RunTest @testName

    SELECT @Result = Result
      FROM tSQLt.TestResult
     WHERE Name = @testName;

    SELECT @msg = Msg
      FROM tSQLt.TestCaseSummary();

    EXEC tSQLt.private_Print @msg;
END;
GO

CREATE PROCEDURE tSQLt.RunTestClassSummary
AS
BEGIN
    DECLARE @msg1 VARCHAR(MAX);
    DECLARE @msg2 VARCHAR(MAX);
    DECLARE @msg3 VARCHAR(MAX);
    DECLARE @msg4 VARCHAR(MAX);
    DECLARE @isSuccess INT;
    DECLARE @successCnt INT;
    DECLARE @severity INT;
    
    SELECT ROW_NUMBER() OVER(ORDER BY Result DESC, Name ASC) No,Name [Test Case Name], Result--, Msg
      INTO #tmp
      FROM tSQLt.TestResult;
    
    EXEC tSQLt.TableToText @msg1 OUTPUT, '#tmp', 'No';

    SELECT @msg3 = Msg, 
           @isSuccess = 1 - SIGN(FailCnt + ErrorCnt),
           @successCnt = successCnt
      FROM tSQLt.TestCaseSummary();
    
    SELECT @severity = 16*(1-@isSuccess),
           @msg2 = REPLICATE('-',LEN(@msg3)),
           @msg4 = CHAR(13)+CHAR(10);
    
    
    EXEC tSQLt.private_Print @msg4,0;
    EXEC tSQLt.private_Print '+---------------------+',0;
    EXEC tSQLt.private_Print '|Test Execution Sumary|',0;
    EXEC tSQLt.private_Print '+---------------------+',0;
    EXEC tSQLt.private_Print @msg4,0;
    EXEC tSQLt.private_Print @msg1,0;
    EXEC tSQLt.private_Print @msg2,0;
    EXEC tSQLt.private_Print @msg3, @severity;
    EXEC tSQLt.private_Print @msg2,0;
END
GO

CREATE PROCEDURE tSQLt.RunTestClass
   @testClassName sysname
AS
BEGIN
    EXEC tSQLt.Run @testClassName;
END
GO    

----------------------------------------------------------------------
CREATE PROCEDURE tSQLt.Run
   @testName sysname = NULL
AS
BEGIN
SET NOCOUNT ON;
    DECLARE @testCaseName NVARCHAR(MAX);
    DECLARE @testClassName NVARCHAR(MAX);
    DECLARE @fullName NVARCHAR(MAX);
    DECLARE @testCaseId INT;
    DECLARE @testClassId INT;

    DECLARE @msg VARCHAR(MAX);
    DECLARE @SetUp NVARCHAR(MAX);SET @SetUp = NULL;
    DECLARE @isSuccess INT;
    DECLARE @severity INT;

    IF(LTRIM(ISNULL(@testName,'')) = '')
    BEGIN
      SELECT @testName = testName 
        FROM tSQLt.Run_LastExecution le
        JOIN sys.dm_exec_sessions es
          ON le.session_id = es.session_id
         AND le.login_time = es.login_time
       WHERE es.session_id = @@SPID;
    END

    DELETE FROM tSQLt.Run_LastExecution
     WHERE session_id = @@SPID;

    SELECT @testName = CASE WHEN @testName LIKE '\[%\]' ESCAPE '\'
                             AND @testName NOT LIKE '\[%[^[]\].\[%\]' ESCAPE '\'
                            THEN SUBSTRING(@testName, 2, LEN(@testName) -2)
                            ELSE @testName
                       END; --UNQUOTENAME(@testName) for bug in SCHEMA_ID() function

    SELECT @testClassName = COALESCE(SCHEMA_NAME(SCHEMA_ID(@testName)),OBJECT_SCHEMA_NAME(OBJECT_ID(@testName))),
           @testCaseName = OBJECT_NAME(OBJECT_ID(@testName));

    SELECT @fullName = QUOTENAME(@testClassName) + 
                      COALESCE('.' + QUOTENAME(@testCaseName), '');

    INSERT INTO tSQLt.Run_LastExecution(testName, session_id, login_time)
    SELECT testName = @fullName,
           session_id,
           login_time
      FROM sys.dm_exec_sessions
     WHERE session_id = @@SPID;

    SELECT @testClassId = SCHEMA_ID(@testClassName),
           @testCaseId = OBJECT_ID(@testName);

    EXEC tSQLt.private_CleanTestResult;
    
    SELECT @SetUp = '['+SCHEMA_NAME(schema_id)+'].['+name+']'
      FROM sys.procedures
     WHERE schema_id = SCHEMA_ID(@testClassName)
       AND name = 'SetUp';

    DECLARE testCases CURSOR LOCAL FAST_FORWARD 
        FOR
     SELECT '['+SCHEMA_NAME(schema_id)+'].['+name+']'
       FROM sys.procedures
      WHERE schema_id = SCHEMA_ID(@testClassName)
        AND ((@testCaseId IS NULL AND name LIKE 'test%')
             OR
             object_id = @testCaseId
            );
    OPEN testCases;
    
    FETCH NEXT FROM testCases INTO @testCaseName;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC tSQLt.private_RunTest @testCaseName, @SetUp;

        FETCH NEXT FROM testCases INTO @testCaseName;
    END;

    CLOSE testCases;
    DEALLOCATE testCases;

    EXEC tSQLt.RunTestClassSummary;
END;
GO

CREATE FUNCTION tSQLt.TestCaseSummary()
RETURNS TABLE
AS
RETURN WITH A(Cnt, SuccessCnt, FailCnt, ErrorCnt) AS (
                SELECT COUNT(1),
                       ISNULL(SUM(CASE WHEN Result = 'Success' THEN 1 ELSE 0 END), 0),
                       ISNULL(SUM(CASE WHEN Result = 'Failure' THEN 1 ELSE 0 END), 0),
                       ISNULL(SUM(CASE WHEN Result = 'Error' THEN 1 ELSE 0 END), 0)
                  FROM tSQLt.TestResult
                  
                )
       SELECT 'Test Case Summary: ' + CAST(Cnt AS VARCHAR) + ' test case(s) executed, '+
                  CAST(SuccessCnt AS VARCHAR) + ' succeeded, '+
                  CAST(FailCnt AS VARCHAR) + ' failed, '+
                  CAST(ErrorCnt AS VARCHAR) + ' errored.' Msg,*
         FROM A;
GO

CREATE FUNCTION tSQLt.getFullTypeName(@TypeId INT, @Length INT, @Precision INT, @Scale INT )
RETURNS TABLE
AS
RETURN SELECT typeName = TYPE_NAME(@TypeId) +
              CASE WHEN @Length = -1
                    THEN '(MAX)'
                   WHEN TYPE_NAME(@TypeId) LIKE '%CHAR' OR TYPE_NAME(@TypeId) LIKE '%BINARY'
                    THEN '(' + CAST(@Length AS VARCHAR) + ')'
                   WHEN TYPE_NAME(@TypeId) IN ('DECIMAL', 'NUMERIC')
                    THEN '(' + CAST(@Precision AS VARCHAR) + ',' + CAST(@Scale AS VARCHAR) + ')'
                   ELSE ''
               END;

GO

CREATE PROCEDURE tSQLt.SpyProcedure
    @ProcedureName NVARCHAR(MAX)
AS
BEGIN
    DECLARE @Cmd NVARCHAR(MAX);
    DECLARE @LogTableName NVARCHAR(MAX); SET @LogTableName = @ProcedureName + '_SpyProcedureLog';
    DECLARE @ProcParmList NVARCHAR(MAX),
            @TableColList NVARCHAR(MAX),
            @ProcParmTypeList NVARCHAR(MAX),
            @TableColTypeList NVARCHAR(MAX);

    WITH A(no,pname, cname, type, sep)
           AS (SELECT p.parameter_id,
                      p.name,
                      '[' + STUFF(p.name,1,1,'') + ']',
                      t.typeName,
                      CASE p.parameter_id WHEN 1 THEN '' ELSE ',' END
                 FROM sys.parameters p
                 CROSS APPLY tSQLt.getFullTypeName(p.user_type_id,p.max_length,p.precision,p.scale) t
                WHERE object_id = OBJECT_ID(@ProcedureName)
              ),
         B(no,ProcParm,TableCol,ProcParmType,TableColType) 
           AS (SELECT no,
                      sep + pname,
                      sep + cname,
                      sep + pname + ' ' + type +' = NULL',
                      ',' + cname + ' ' + type
                 FROM A
              ),
         ProcParmList(xml) AS (SELECT ProcParm AS [text()] FROM B ORDER BY no FOR XML PATH(''), TYPE),
         TableColList(xml) AS (SELECT TableCol AS [text()] FROM B ORDER BY no FOR XML PATH(''), TYPE),
         ProcParmTypeList(xml) AS (SELECT ProcParmType AS [text()] FROM B ORDER BY no FOR XML PATH(''), TYPE),
         TableColTypeList(xml) AS (SELECT TableColType AS [text()] FROM B ORDER BY no FOR XML PATH(''), TYPE)
    SELECT @ProcParmList  = (SELECT xml.value('/','VARCHAR(MAX)') FROM ProcParmList),
           @TableColList  = (SELECT xml.value('/','VARCHAR(MAX)') FROM TableColList),
           @ProcParmTypeList = (SELECT xml.value('/','VARCHAR(MAX)') FROM ProcParmTypeList),
           @TableColTypeList = (SELECT xml.value('/','VARCHAR(MAX)') FROM TableColTypeList);

    SELECT @Cmd = 'CREATE TABLE ' + @LogTableName + ' (_id_ int IDENTITY(1,1) PRIMARY KEY CLUSTERED ' + ISNULL(@TableColTypeList,'') + ');';
--    RAISERROR(@Cmd,0,1)WITH NOWAIT;
    EXEC(@Cmd);

    SELECT @Cmd = 'DROP PROCEDURE ' + @ProcedureName +';';
--    RAISERROR(@Cmd,0,1)WITH NOWAIT;
    EXEC(@Cmd);

    SELECT @Cmd = 'CREATE PROCEDURE ' + @ProcedureName + ISNULL('(' + @ProcParmTypeList + ')', '') + 
                  ' AS BEGIN ' + 
                     'INSERT INTO ' + @LogTableName + 
                     ISNULL(' (' + @TableColList + ') SELECT ' + @ProcParmList, ' DEFAULT VALUES') + 
                  '; END;';
--    RAISERROR(@Cmd,0,1)WITH NOWAIT;
    EXEC(@Cmd);

    RETURN 0;
END;
GO

CREATE PROCEDURE tSQLt.AssertEquals
    @expected SQL_VARIANT,
    @actual SQL_VARIANT,
    @Message VARCHAR(MAX) = ''
AS
BEGIN
    IF ((@expected = @actual) OR (@actual IS NULL AND @expected IS NULL))
      RETURN 0;

    DECLARE @msg VARCHAR(MAX);
    SELECT @msg = 'Expected: <' + ISNULL(CAST(@expected AS VARCHAR(MAX)), 'NULL') + 
                  '> but was: <' + ISNULL(CAST(@actual AS VARCHAR(MAX)), 'NULL') + '>';
    IF((COALESCE(@Message,'') <> '') AND (@Message NOT LIKE '% ')) SET @Message = @Message + ' ';
    EXEC tSQLt.Fail @Message, @msg;
END;
GO

CREATE PROCEDURE tSQLt.AssertEqualsString
    @expected VARCHAR(MAX),
    @actual VARCHAR(MAX),
    @Message VARCHAR(MAX) = ''
AS
BEGIN
    IF ((@expected = @actual) OR (@actual IS NULL AND @expected IS NULL))
      RETURN 0;

    DECLARE @msg VARCHAR(MAX);
    SELECT @msg = 'Expected: <' + ISNULL(@expected, 'NULL') + 
                  '> but was: <' + ISNULL(@actual, 'NULL') + '>';
    EXEC tSQLt.Fail @Message, @msg;
END;
GO

CREATE PROCEDURE tSQLt.AssertObjectExists
    @objectName VARCHAR(MAX),
    @Message VARCHAR(MAX) = ''
AS
BEGIN
    DECLARE @msg VARCHAR(MAX);
    IF(@objectName LIKE '#%')
    BEGIN
     IF OBJECT_ID('tempdb..'+@objectName) IS NULL
     BEGIN
         SELECT @msg = '''' + COALESCE(@objectName, 'NULL') + ''' does not exist';
         EXEC tSQLt.Fail @Message, @msg;
         RETURN 1;
     END;
    END
    ELSE
    BEGIN
     IF OBJECT_ID(@objectName) IS NULL
     BEGIN
         SELECT @msg = '''' + COALESCE(@objectName, 'NULL') + ''' does not exist';
         EXEC tSQLt.Fail @Message, @msg;
         RETURN 1;
     END;
    END;
    RETURN 0;
END;
GO

--------------------------------------------------------------------------------------------------------------------------
--below is untested code
--------------------------------------------------------------------------------------------------------------------------
GO
/*******************************************************************************************/
/*******************************************************************************************/
/*******************************************************************************************/
GO
CREATE PROCEDURE tSQLt.StubRecord(@snTableName AS SYSNAME, @bintObjId AS BIGINT)  
AS   
BEGIN  
    DECLARE @vcInsertStmt varchar(8000),  
            @vcInsertValues varchar(8000)  
    DECLARE @snColumnName sysname  
    DECLARE @sintDataType smallint  
    declare @nvcFKCmd nvarchar(4000)  
    declare @vcFKVal varchar(1000)  
  
    SET @vcInsertStmt = 'INSERT INTO ' + @snTableName + ' ('  
      
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
        LEFT OUTER JOIN (select fkeyid id,fkey colid,N'select @v=cast(min('+syscolumns.name+') as varchar) from '+sysobjects.name cmd  
                        from sysforeignkeys   
                        join sysobjects on sysobjects.id=sysforeignkeys.rkeyid  
                        join syscolumns on sysobjects.id=syscolumns.id and syscolumns.colid=rkey) cmd  
            on cmd.id=syscolumns.id and cmd.colid=syscolumns.colid  
    WHERE syscolumns.id = OBJECT_ID(@snTableName)  
      AND (syscolumns.isnullable = 0 )  
    ORDER BY ISNULL(sysconstraints.status, 9999), -- Order Primary Key constraints first  
             syscolumns.colorder  
  
    OPEN curColumns  
  
    FETCH NEXT FROM curColumns  
    INTO @snColumnName, @sintDataType, @nvcFKCmd  
  
    -- Treat the first column retrieved differently, no commas need to be added  
    -- and it is the ObjId column  
    IF @@FETCH_STATUS = 0  
    BEGIN  
        SET @vcInsertStmt = @vcInsertStmt + @snColumnName  
        SELECT @vcInsertValues = ')VALUES(' + ISNULL(CAST(@bintObjId AS nvarchar), 'NULL')  
  
        FETCH NEXT FROM curColumns  
        INTO @snColumnName, @sintDataType, @nvcFKCmd  
    END  
    ELSE  
    BEGIN  
        -- No columns retrieved, we need to insert into any first column  
        SELECT @vcInsertStmt = @vcInsertStmt + syscolumns.name  
        FROM syscolumns  
        WHERE syscolumns.id = OBJECT_ID(@snTableName)  
          AND syscolumns.colorder = 1  
  
        SELECT @vcInsertValues = ')VALUES(' + ISNULL(CAST(@bintObjId AS nvarchar), 'NULL')  
  
    END  
  
    WHILE @@FETCH_STATUS = 0  
    BEGIN  
        SET @vcInsertStmt = @vcInsertStmt + ',' + @snColumnName  
        SET @vcFKVal=',0'  
        if @nvcFKCmd is not null  
        BEGIN  
            set @vcFKVal=null  
            exec sp_executesql @nvcFKCmd,N'@v varchar(1000) output',@vcFKVal output  
            set @vcFKVal=isnull(','''+@vcFKVal+'''',',NULL')  
        END  
        SET @vcInsertValues = @vcInsertValues + @vcFKVal  
  
        FETCH NEXT FROM curColumns  
        INTO @snColumnName, @sintDataType, @nvcFKCmd  
    END  
      
    CLOSE curColumns  
    DEALLOCATE curColumns  
  
    SET @vcInsertStmt = @vcInsertStmt + @vcInsertValues + ')'  
  
    IF EXISTS (SELECT 1   
               FROM syscolumns  
               WHERE status = 128   
                 AND id = OBJECT_ID(@snTableName))  
    BEGIN  
        SET @vcInsertStmt = 'SET IDENTITY_INSERT ' + @snTableName + ' ON ' + CHAR(10) +   
                             @vcInsertStmt + CHAR(10) +   
                             'SET IDENTITY_INSERT ' + @snTableName + ' OFF '  
    END  
  
    EXEC (@vcInsertStmt)    -- Execute the actual INSERT statement  
  
END  

GO

/*******************************************************************************************/
/*******************************************************************************************/
/*******************************************************************************************/
CREATE FUNCTION tSQLt.private_getCleanSchemaName(@schemaName SYSNAME, @objectName SYSNAME)
RETURNS SYSNAME
AS
BEGIN
    RETURN (SELECT SCHEMA_NAME(schema_id) 
              FROM sys.objects 
             WHERE object_id = CASE WHEN ISNULL(@schemaName,'') in ('','[]')
                                    THEN OBJECT_ID(@objectName)
                                    ELSE OBJECT_ID(@schemaName + '.' + @objectName)
                                END);
END;
GO

CREATE PROCEDURE tSQLt.private_RenameObjectToUniqueName
    @schemaName SYSNAME,
    @objectName SYSNAME,
    @newName NVARCHAR(MAX) = NULL OUTPUT
AS
BEGIN
   DECLARE @fullName SYSNAME;

   SET @fullName = @schemaName + '.' + @objectName;

   SET @newName=@objectName;  
   WHILE OBJECT_ID(@schemaName+'.'+@newName) IS NOT NULL  
       SELECT @newName=left(left(@objectName,150)+REPLACE(CAST(NEWID() AS NVARCHAR(200)),'-',''),256)  

   EXEC SP_RENAME @fullName, @newName;
END;
GO

CREATE PROCEDURE tSQLt.FakeTable
    @schemaName SYSNAME,
    @tableName SYSNAME
AS
BEGIN

   DECLARE @origSchemaName SYSNAME;
   DECLARE @newName SYSNAME;
   DECLARE @cmd VARCHAR(MAX);
   
   SET @origSchemaName = @schemaName;   
   SET @schemaName = tSQLt.private_getCleanSchemaName(@schemaName, @tableName);
   
   IF @schemaName IS NULL
   BEGIN
        DECLARE @errorMessage NVARCHAR(MAX);
        SET @errorMessage = 
            '''' + COALESCE(@origSchemaName, 'NULL') + '.' + COALESCE(@tableName, 'NULL') + 
            ''' does not exist.';
        RAISERROR (@errorMessage, 16, 10);
   END;

   EXEC tSQLt.private_RenameObjectToUniqueName @schemaName, @tableName, @newName OUTPUT

   SELECT @cmd = '
      SELECT Src.*
        INTO ' + QUOTENAME(@schemaName) + '.' + QUOTENAME(@tableName) + '
        FROM ' + QUOTENAME(@schemaName) + '.' + QUOTENAME(@newName) + ' Src
       RIGHT JOIN (SELECT 1 n)n
          ON n.n<>n.n
       WHERE n.n<>n.n
   ';
   EXEC (@cmd);

   EXEC sys.sp_addextendedproperty 
   @name = N'tSQLt.FakeTable_OrgTableName', 
   @value = @newName, 
   @level0type = N'SCHEMA', @level0name = @schemaName, 
   @level1type = N'TABLE',  @level1name = @tableName;
END
GO

CREATE PROCEDURE tSQLt.TableToText
    @txt VARCHAR(MAX) OUTPUT,
    @TableName SYSNAME,
    @OrderBy VARCHAR(MAX) = NULL
AS
BEGIN
    DECLARE @cmd NVARCHAR(MAX);
    DECLARE @FullTableName SYSNAME;
    DECLARE @isTempTable INT;
    SELECT @isTempTable = CASE WHEN @TableName LIKE '#%' OR @TableName LIKE '[[]#%' THEN 1 ELSE 0 END;
    SELECT @OrderBy = ISNULL('ROW_NUMBER() OVER(ORDER BY '+@OrderBy+')','2'),
           @FullTableName = CASE WHEN @isTempTable = 1 THEN 'tempdb..' ELSE '' END + @TableName;

    WITH S AS (SELECT * FROM SYS.COLUMNS WHERE @isTempTable <> 1
                UNION ALL
               SELECT * FROM tempdb.SYS.COLUMNS WHERE @isTempTable = 1),
         A AS (SELECT column_id,
                      A = CASE WHEN column_id = 1 THEN '' ELSE ',' END+
                         'CAST(MAX(ISNULL(LEN('+QUOTENAME(name)+'),6))AS VARCHAR(MAX))'+
                         ' AS '+QUOTENAME(name),
                      B = CASE WHEN column_id = 1 THEN '' ELSE ',' END+
                          'CONVERT(VARCHAR(MAX),'+QUOTENAME(name)+','+
                          CASE WHEN TYPE_NAME(user_type_id) LIKE '%datetime' THEN '121' ELSE '0' END+
                          ') AS '+QUOTENAME(name),
                      C = CASE WHEN column_id = 1 THEN '' ELSE ',' END+
                          ''''+name+'''',
                      D = CASE WHEN column_id = 1 THEN '' ELSE '+''+''+' END+
                          '''''''|''''+CAST('''''+name+''''' AS CHAR(''+A.'+QUOTENAME(name)+'+''))''',
                      E = CASE WHEN column_id = 1 THEN '' ELSE '+''+''+' END+
                          '''''''+''''+REPLICATE(''''-'''',''+A.'+QUOTENAME(name)+'+'') ''',
                      F = CASE WHEN column_id = 1 THEN '' ELSE '+''+''+' END+
                          '''''''|''''+ISNULL(CONVERT(CHAR(''+A.'+QUOTENAME(name)+'+''),'+QUOTENAME(name)+','+
                          CASE WHEN TYPE_NAME(user_type_id) LIKE '%datetime' THEN '121' ELSE '0' END+
                          '),CAST(''''!NULL!'''' AS CHAR(''+A.'+QUOTENAME(name)+'+'')))'''
                 FROM S
                WHERE object_id = OBJECT_ID(@FullTableName)),
         B(n) AS (SELECT 0 UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5),
         C(n,cmd) AS (SELECT 100+2000*B.n+column_id,
                             CASE B.n WHEN 0 THEN A
                                      WHEN 1 THEN B
                                      WHEN 2 THEN C
                                      WHEN 3 THEN D
                                      WHEN 4 THEN E
                                      WHEN 5 THEN F
                             END
                        FROM A
                       CROSS JOIN B),
         D(n,cmd) AS (SELECT * FROM C
                      UNION ALL
                      SELECT 1,'DECLARE @cmd NVARCHAR(MAX);WITH A AS (SELECT '
                      UNION ALL
                      SELECT 2000,' FROM(SELECT '
                      UNION ALL
                      SELECT 4000, 
                             ' FROM '+@TableName+
                             ' UNION ALL SELECT '
                      UNION ALL
                      SELECT 6000, 
                             ')x),B(n) AS (SELECT 0 UNION ALL SELECT 1 UNION ALL SELECT 2),C(n,cmd) AS (SELECT 100+2000*B.n,CASE B.n WHEN 0 THEN '
                      UNION ALL
                      SELECT 8000, 
                             '+''+''''|'''''' WHEN 1 THEN '
                      UNION ALL
                      SELECT 10000, 
                             '+''+''''+'''''' WHEN 2 THEN '
                      UNION ALL
                      SELECT 12000, 
                             '+''+''''|'''''' ELSE ''xx'' END FROM A CROSS JOIN B), '+
                             'D(n,cmd) AS (SELECT * FROM C'+
                             '             UNION ALL'+
                             '             SELECT 1,''DECLARE @cmd NVARCHAR(MAX);WITH A(n,txt) AS (SELECT -2,CAST('''''''' AS VARCHAR(MAX)) collate database_default+'''+
                             '             UNION ALL'+
                             '             SELECT 2000,'' UNION ALL SELECT -1,CAST('''''''' AS VARCHAR(MAX)) collate database_default+'''+
                             '             UNION ALL'+
                             '             SELECT 4000,'' UNION ALL SELECT '+@OrderBy+',CAST('''''''' AS VARCHAR(MAX)) collate database_default+'''+
                             '             UNION ALL'+
                             '             SELECT 6000,'' FROM '+@TableName+
                             '), E(xml) AS (SELECT CASE WHEN n = -2 THEN '''' '''' ELSE ''''+CHAR(13)+CHAR(10)+'''' END +'+
                             '''''''''''''''''+txt+'''''''''''''''' FROM A ORDER BY n FOR XML PATH(''''''''), TYPE)'+
                             'SELECT @cmd = ''''SELECT @txt = CAST('''''''''''''''' AS VARCHAR(MAX))+''''+xml.value(''''/'''', ''''varchar(max)'''') FROM E;'+
--                             'PRINT LEN(@cmd);PRINT @cmd;'+
                             'EXEC sp_executesql @cmd,N''''@txt VARCHAR(MAX) OUTPUT'''',@txt OUTPUT;'+
                             ' ''),E(xml) AS (SELECT cmd AS [text()]  FROM D ORDER BY n FOR XML PATH(''''), TYPE)'+
                             'SELECT @cmd=xml.value(''/'', ''varchar(max)'') FROM E;'+
--                             'PRINT LEN(@cmd);PRINT @cmd;'+
                             'EXEC sp_executesql @cmd,N''@txt VARCHAR(MAX) OUTPUT'',@txt OUTPUT;'
                     ),
         E(xml) AS (SELECT cmd AS [text()]  FROM D ORDER BY n FOR XML PATH(''), TYPE)
    select @cmd = xml.value('/', 'varchar(max)') from E
    ;

--    PRINT LEN(@cmd);PRINT @cmd;
    EXEC sp_executesql @cmd,N'@txt VARCHAR(MAX) OUTPUT',@txt OUTPUT;
--    PRINT LEN(@txt);PRINT @txt;
END;
GO

CREATE PROCEDURE tSQLt.TableCompare
       @expected SYSNAME,
       @actual SYSNAME,
       @txt VARCHAR(MAX) = NULL OUTPUT
AS
BEGIN
    DECLARE @cmd NVARCHAR(MAX);
    DECLARE @r INT;
    DECLARE @en SYSNAME;
    DECLARE @an SYSNAME;
    DECLARE @rn SYSNAME;
    SELECT @en = QUOTENAME('#tSQLt_TempTable'+CAST(NEWID() AS VARCHAR(100))),
           @an = QUOTENAME('#tSQLt_TempTable'+CAST(NEWID() AS VARCHAR(100))),
           @rn = QUOTENAME('#tSQLt_TempTable'+CAST(NEWID() AS VARCHAR(100)));

    WITH TA AS (SELECT column_id,name,is_identity
                  FROM SYS.COLUMNS 
                 WHERE object_id = OBJECT_ID(@actual)
                 UNION ALL
                SELECT column_id,name,is_identity
                  FROM tempdb.SYS.COLUMNS 
                 WHERE object_id = OBJECT_ID('tempdb..'+@actual)
               ),
         TB AS (SELECT column_id,name,is_identity
                  FROM SYS.COLUMNS 
                 WHERE object_id = OBJECT_ID(@expected)
                 UNION ALL
                SELECT column_id,name,is_identity
                  FROM tempdb.SYS.COLUMNS 
                 WHERE object_id = OBJECT_ID('tempdb..'+@expected)
               ),
         T AS (SELECT TA.column_id,TA.name,
                      CASE WHEN TA.is_identity = 1 THEN 1
                           WHEN TB.is_identity = 1 THEN 1
                           ELSE 0
                      END is_identity
                 FROM TA
                 LEFT JOIN TB
                   ON TA.column_id = TB.column_id
              ),
         A AS (SELECT column_id,
                      P0 = ', '+QUOTENAME(name)+
                           CASE WHEN is_identity = 1
                                THEN '*1'
                                ELSE ''
                           END+
                         ' AS C'+CAST(column_id AS VARCHAR),
                      P1 = CASE WHEN column_id = 1 THEN '' ELSE ' AND ' END+
                           '((A.C'+
                           CAST(column_id AS VARCHAR)+
                           '=E.C'+
                           CAST(column_id AS VARCHAR)+
                           ') OR (COALESCE(A.C'+ 
                           CAST(column_id AS VARCHAR)+
                           ',E.C'+
                           CAST(column_id AS VARCHAR)+
                           ') IS NULL))',
                      P2 = ', COALESCE(E.C'+
                           CAST(column_id AS VARCHAR)+
                           ',A.C'+
                           CAST(column_id AS VARCHAR)+
                           ') AS '+
                           QUOTENAME(name)
                 FROM T),
         B(m,p) AS (SELECT 0,0 UNION ALL 
                    SELECT 1,0 UNION ALL 
                    SELECT 2,1 UNION ALL 
                    SELECT 3,2),
         C(n,cmd) AS (SELECT 100+2000*B.m+column_id,
                             CASE B.p WHEN 0 THEN P0
                                      WHEN 1 THEN P1
                                      WHEN 2 THEN P2
                             END
                        FROM A
                       CROSS JOIN B),
         D(n,cmd) AS (SELECT * FROM C
                      UNION ALL
                      SELECT 1,'SELECT IDENTITY(INT,1,1) no'
                      UNION ALL
                      SELECT 2001,' INTO '+@an+' FROM '+@actual+';SELECT IDENTITY(INT,1,1) no'
                      UNION ALL
                      SELECT 4001,' INTO '+@en+' FROM '+
                                  @expected+';'+
                                  'WITH Match AS (SELECT A.no Ano, E.no Eno FROM '+@an+' A FULL OUTER JOIN '+@en+' E ON '
                      UNION ALL
                      SELECT 6001,'),MatchWithRowNo AS (SELECT Ano, Eno, r1=ROW_NUMBER() OVER(PARTITION BY Ano ORDER BY Eno), r2=ROW_NUMBER() OVER(PARTITION BY Eno ORDER BY Ano) FROM Match)'+
                                  ',CleanMatch AS (SELECT Ano,Eno FROM MatchWithRowNo WHERE r1 = r2)'+
                                  'SELECT CASE WHEN A.no IS NULL THEN ''<'' WHEN E.no IS NULL THEN ''>'' ELSE ''='' END AS _m_'
                      UNION ALL
                      SELECT 8001,' INTO '+@rn+' FROM CleanMatch FULL JOIN '+@en+' E ON E.no = CleanMatch.Eno FULL JOIN '+@an+' A ON A.no = CleanMatch.Ano;'+
                                  ' SELECT @r = CASE WHEN EXISTS(SELECT 1 FROM '+@rn+' WHERE _m_<>''='') THEN -1 ELSE 0 END;'+
--' SELECT * FROM '+@rn+';'+
                                  ' EXEC tSQLt.TableToText @txt OUTPUT,'''+@rn+''',''_m_'';'+
--' PRINT @txt;'+
                                  ' DROP TABLE '+@an+'; DROP TABLE '+@en+'; DROP TABLE '+@rn+';'
                     ),
         E(xml) AS (SELECT cmd AS [data()]  FROM D ORDER BY n FOR XML PATH(''), TYPE)
    select @cmd = xml.value( '/', 'varchar(max)' ) from E;

--    PRINT @cmd;
    EXEC sp_executesql @cmd, N'@r INT OUTPUT, @txt VARCHAR(MAX) OUTPUT', @r OUTPUT, @txt OUTPUT;;

--    PRINT 'Outcome:'+CAST(@r AS VARCHAR);
--    PRINT @txt; 
    RETURN @r;
END;
GO

/*******************************************************************************************/
/*******************************************************************************************/
/*******************************************************************************************/
CREATE PROCEDURE tSQLt.AssertEqualsTable
    @Expected SYSNAME,
    @Actual SYSNAME,
    @FailMsg VARCHAR(4000) = 'unexpected/missing resultset rows!'
AS
BEGIN
    DECLARE @TblMsg VARCHAR(MAX);
    DECLARE @r INT;
    DECLARE @errorMessage NVARCHAR(MAX);
    DECLARE @failureOccurred BIT;
    SET @failureOccurred = 0;

    EXEC @failureOccurred = tSQLt.AssertObjectExists @Actual;
    IF @failureOccurred = 1 RETURN 1;
    EXEC @failureOccurred = tSQLt.AssertObjectExists @Expected;
    IF @failureOccurred = 1 RETURN 1;
        
    EXEC @r = tSQLt.TableCompare @Expected, @Actual, @TblMsg OUT;

    IF (@r <> 0)
    BEGIN
        IF ISNULL(@FailMsg,'')<>'' SET @FailMsg = @FailMsg + CHAR(13) + CHAR(10);
        EXEC tSQLt.Fail @FailMsg, @TblMsg;
    END;
    
END;
GO
/*******************************************************************************************/
/*******************************************************************************************/
/*******************************************************************************************/

CREATE PROCEDURE tSQLt.ApplyConstraint
       @schemaName SYSNAME,
       @tableName SYSNAME,
       @constraintName SYSNAME
AS
BEGIN
  DECLARE @orgTableName NVARCHAR(MAX);
  DECLARE @cmd NVARCHAR(MAX);

  SELECT @orgTableName = CAST(value AS NVARCHAR(300))
    FROM sys.extended_properties
   WHERE class_desc = 'OBJECT_OR_COLUMN'
     AND major_id = OBJECT_ID(@schemaName + '.' + @tableName)
     AND minor_id = 0
     AND name = 'tSQLt.FakeTable_OrgTableName';

  SELECT @cmd = 'CONSTRAINT ' + name + ' CHECK' + definition 
    FROM sys.check_constraints
   WHERE object_id = OBJECT_ID(@schemaName + '.' + @constraintName)
     AND parent_object_id = OBJECT_ID(@schemaName + '.' + @orgTableName);

  IF @cmd IS NOT NULL
  BEGIN
     EXEC tSQLt.private_RenameObjectToUniqueName @schemaName, @constraintName;
     SELECT @cmd = 'ALTER TABLE ' + @schemaName + '.' + @tableName + ' ADD ' + @cmd;

     EXEC (@cmd);
  END
  ELSE
  BEGIN
     SELECT @cmd = cmd 
       FROM tSQLt.private_getForeignKeyDefinition(@schemaName, @orgTableName, @constraintName);

     IF @cmd IS NOT NULL
     BEGIN
        EXEC tSQLt.private_RenameObjectToUniqueName @schemaName, @constraintName;
        SELECT @cmd = 'ALTER TABLE ' + @schemaName + '.' + @tableName + ' ADD ' + @cmd;

        EXEC (@cmd);
     END
     ELSE
     BEGIN
        DECLARE @errorMessage NVARCHAR(MAX);
        SET @errorMessage = '''' + @schemaName + '.' + @ConstraintName + 
            ''' is not a valid constraint on table ''' + @schemaName + '.' + @tableName + 
            ''' for the tSQLt.ApplyConstraint procedure';
        RAISERROR (@errorMessage, 16, 10);
     END;
  END;

  RETURN 0;
END;
GO
