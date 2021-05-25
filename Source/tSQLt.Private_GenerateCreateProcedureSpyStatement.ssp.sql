IF OBJECT_ID('tSQLt.Private_GenerateCreateProcedureSpyStatement') IS NOT NULL DROP PROCEDURE tSQLt.Private_GenerateCreateProcedureSpyStatement;
GO
---Build+
CREATE PROCEDURE tSQLt.Private_GenerateCreateProcedureSpyStatement
    @ProcedureObjectId INT,
    @OriginalProcedureName NVARCHAR(MAX),
    @LogTableName NVARCHAR(MAX),
    @CommandToExecute NVARCHAR(MAX),
    @CreateProcedureStatement NVARCHAR(MAX) OUTPUT,
    @CreateLogTableStatement NVARCHAR(MAX) OUTPUT
AS
BEGIN
    DECLARE @ProcParmList NVARCHAR(MAX),
            @TableColList NVARCHAR(MAX),
            @ProcParmTypeList NVARCHAR(MAX),
            @TableColTypeList NVARCHAR(MAX);
            
    DECLARE @Separator CHAR(1),
            @ProcParmTypeListSeparater CHAR(1),
            @ParamName sysname,
            @TypeName sysname,
            @IsOutput BIT,
            @IsCursorRef BIT,
            @IsTableType BIT;
      
    SELECT @Separator = '', @ProcParmTypeListSeparater = '', 
           @ProcParmList = '', @TableColList = '', @ProcParmTypeList = '', @TableColTypeList = '';
      
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
            SELECT @ProcParmList = @ProcParmList + @Separator + 
                                   CASE WHEN @IsTableType = 1 
                                     THEN '(SELECT * FROM '+@ParamName+' FOR XML PATH(''row''),TYPE,ROOT('''+STUFF(@ParamName,1,1,'')+'''))' 
                                     ELSE @ParamName 
                                   END, 
                   @TableColList = @TableColList + @Separator + '[' + STUFF(@ParamName,1,1,'') + ']', 
                   @ProcParmTypeList = @ProcParmTypeList + @ProcParmTypeListSeparater + @ParamName + ' ' + @TypeName + 
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

            SELECT @Seperator = ',';        
            SELECT @ProcParmTypeListSeparater = ',';
        END
        ELSE
        BEGIN
            SELECT @ProcParmTypeList = @ProcParmTypeListSeparater + @ParamName + ' CURSOR VARYING OUTPUT';
            SELECT @ProcParmTypeListSeparater = ',';
        END;
        
        FETCH NEXT FROM Parameters INTO @ParamName, @TypeName, @IsOutput, @IsCursorRef, @IsTableType;
    END;
    
    CLOSE Parameters;
    DEALLOCATE Parameters;
    
    DECLARE @InsertStmt NVARCHAR(MAX);
    SELECT @InsertStmt = 'INSERT INTO ' + @LogTableName + 
                         CASE WHEN @TableColList = '' THEN ' DEFAULT VALUES'
                              ELSE ' (' + @TableColList + ') SELECT ' + @ProcParmList
                         END + ';';
                         
    SELECT @CreateLogTableStatement = 'CREATE TABLE ' + @LogTableName + ' (_id_ int IDENTITY(1,1) PRIMARY KEY CLUSTERED ' + @TableColTypeList + ');';

    SELECT @CreateProcedureStatement = 
             'CREATE PROCEDURE ' + @OriginalProcedureName + ' ' + @ProcParmTypeList + 
             ' AS BEGIN ' + 
                ISNULL(@InsertStmt,'') + 
                ISNULL(@CommandToExecute + ';', '') +
             ' RETURN;' +
             ' END;';

    RETURN;
END;
---Build-
GO
