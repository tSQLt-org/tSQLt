IF OBJECT_ID('tSQLt.Private_GenerateCreateProcedureSpyStatement') IS NOT NULL DROP PROCEDURE tSQLt.Private_GenerateCreateProcedureSpyStatement;
GO
---Build+
CREATE PROCEDURE tSQLt.Private_GenerateCreateProcedureSpyStatement
    @ProcedureObjectId INT,
    @OriginalProcedureName NVARCHAR(MAX),
    @UnquotedNewNameOfProcedure NVARCHAR(MAX) = NULL,
    @LogTableName NVARCHAR(MAX),
    @CommandToExecute NVARCHAR(MAX),
    @CallOriginal BIT,
    @CreateProcedureStatement NVARCHAR(MAX) OUTPUT,
    @CreateLogTableStatement NVARCHAR(MAX) OUTPUT
AS
BEGIN
    DECLARE @ProcParmListForInsert NVARCHAR(MAX) = '';
    DECLARE @ProcParmListForCall NVARCHAR(MAX) = '';
    DECLARE @TableColList NVARCHAR(MAX) = '';
    DECLARE @ProcParmTypeList NVARCHAR(MAX) = '';
    DECLARE @TableColTypeList NVARCHAR(MAX) = '';

    DECLARE @SeparatorWithoutCursor CHAR(1) = '';
    DECLARE @SeparatorWithCursor CHAR(1) = '';
    DECLARE @ParamName sysname;
    DECLARE @TypeName sysname;
    DECLARE @IsOutput BIT;
    DECLARE @IsCursorRef BIT;
    DECLARE @IsTableType BIT;
            
    DECLARE Parameters CURSOR FOR
     SELECT p.name, t.TypeName, p.is_output, p.is_cursor_ref, t.IsTableType
       FROM sys.parameters p
       CROSS APPLY tSQLt.Private_GetFullTypeName(p.user_type_id,p.max_length,p.precision,p.scale,NULL) t
      WHERE object_id = @ProcedureObjectId;
    
    OPEN Parameters;
    
    FETCH NEXT FROM Parameters INTO @ParamName, @TypeName, @IsOutput, @IsCursorRef, @IsTableType;
    WHILE (@@FETCH_STATUS = 0)
    BEGIN
        IF @IsCursorRef = 0
        BEGIN
            SELECT @ProcParmListForInsert = @ProcParmListForInsert + @SeparatorWithoutCursor + 
                                   CASE WHEN @IsTableType = 1 
                                     THEN '(SELECT * FROM '+@ParamName+' FOR XML PATH(''row''),TYPE,ROOT('''+STUFF(@ParamName,1,1,'')+'''))' 
                                     ELSE @ParamName 
                                   END, 
                   @TableColList = @TableColList + @SeparatorWithoutCursor + '[' + STUFF(@ParamName,1,1,'') + ']', 
                   @ProcParmTypeList = @ProcParmTypeList + @SeparatorWithCursor + @ParamName + ' ' + @TypeName + 
                                       CASE WHEN @IsTableType = 1 THEN ' READONLY' ELSE ' = NULL ' END+ 
                                       CASE WHEN @IsOutput = 1 THEN ' OUT' ELSE '' END, 
                   @TableColTypeList = @TableColTypeList + ',[' + STUFF(@ParamName,1,1,'') + '] ' + 
                          CASE 
                               WHEN @IsTableType = 1
                               THEN 'XML'
                               WHEN @TypeName LIKE '%nchar%'
                                 OR @TypeName LIKE '%nvarchar%'
                               THEN 'NVARCHAR(MAX)'
                               WHEN @TypeName LIKE '%char%'
                               THEN 'VARCHAR(MAX)'
                               ELSE @TypeName
                          END + ' NULL';

            SELECT @SeparatorWithoutCursor = ',';        
        END
        ELSE
        BEGIN
            SELECT @ProcParmTypeList = @ProcParmTypeList + @SeparatorWithCursor + @ParamName + ' CURSOR VARYING OUTPUT';
        END;
        SELECT 
            @ProcParmListForCall = @ProcParmListForCall + @SeparatorWithCursor + @ParamName + 
            CASE 
              WHEN @IsOutput = 1 AND @IsCursorRef <> 1
                THEN ' OUT' 
              ELSE '' 
            END;
        SELECT @SeparatorWithCursor = ',';

        FETCH NEXT FROM Parameters INTO @ParamName, @TypeName, @IsOutput, @IsCursorRef, @IsTableType;
    END;
    
    CLOSE Parameters;
    DEALLOCATE Parameters;
    
    DECLARE @InsertStmt NVARCHAR(MAX);
    SELECT @InsertStmt = 'INSERT INTO ' + @LogTableName + 
                         CASE WHEN @TableColList = '' THEN ' DEFAULT VALUES'
                              ELSE ' (' + @TableColList + ') SELECT ' + @ProcParmListForInsert
                         END + ';';
                         
    SELECT @CreateLogTableStatement = 'CREATE TABLE ' + @LogTableName + ' (_id_ int IDENTITY(1,1) PRIMARY KEY CLUSTERED ' + @TableColTypeList + ');';

    SELECT @CreateProcedureStatement = 
             'CREATE PROCEDURE ' + @OriginalProcedureName + ' ' + @ProcParmTypeList + 
             ' AS BEGIN ' + 
                ISNULL(@InsertStmt,'') + 
                ISNULL('DECLARE @SpyProcedureOriginalObjectName NVARCHAR(MAX) = '''+REPLACE(QUOTENAME(OBJECT_SCHEMA_NAME(@ProcedureObjectId))+'.'+QUOTENAME(@UnquotedNewNameOfProcedure),'''','''''')+''';','')+
                ISNULL(@CommandToExecute + ';', '') +
                CHAR(13)+CHAR(10)+/*CR,LF*/
                CASE WHEN @CallOriginal = 1 
                     THEN 'EXEC @SpyProcedureOriginalObjectName ' + @ProcParmListForCall + ';'
                     ELSE ''
                END +
             ' RETURN;' +
             ' END;';
    --RAISERROR(@CreateProcedureStatement, 0, 1) WITH NOWAIT;

    RETURN;
END;
---Build-
GO
