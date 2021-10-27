IF OBJECT_ID('tSQLt.Private_GenerateCreateProcedureSpyStatement') IS NOT NULL DROP PROCEDURE tSQLt.Private_GenerateCreateProcedureSpyStatement;
GO
---Build+
CREATE PROCEDURE tSQLt.Private_GenerateCreateProcedureSpyStatement
    @ProcedureObjectId INT,
    @OriginalProcedureName NVARCHAR(MAX),
    @LogTableName NVARCHAR(MAX),
    @CommandToExecute NVARCHAR(MAX),
	@RemoteObjectName NVARCHAR(MAX),
    @CreateProcedureStatement NVARCHAR(MAX) OUTPUT,
    @CreateLogTableStatement NVARCHAR(MAX) OUTPUT
AS
BEGIN
    DECLARE @ProcParmList NVARCHAR(MAX),
            @TableColList NVARCHAR(MAX),
            @ProcParmTypeList NVARCHAR(MAX),
            @TableColTypeList NVARCHAR(MAX);
            
    DECLARE @Separator CHAR(1),
            @ProcParmTypeListSeparator CHAR(1),
            @ParamName sysname,
            @TypeName sysname,
            @IsOutput BIT,
            @IsCursorRef BIT,
            @IsTableType BIT;
      
    SELECT @Separator = '', @ProcParmTypeListSeparator = '', 
           @ProcParmList = '', @TableColList = '', @ProcParmTypeList = '', @TableColTypeList = '';
     
	DECLARE @RemoteDatabaseName NVARCHAR(MAX) =ISNULL(PARSENAME(@RemoteObjectName,3),'');
    DECLARE @cmd NVARCHAR(MAX) = 
    'DECLARE Parameters CURSOR FOR 
       SELECT p.name, t.TypeName, p.is_output, p.is_cursor_ref, t.IsTableType
       FROM '+@RemoteDatabaseName+'.sys.parameters p
       CROSS APPLY ('+ (SELECT cmd FROM tSQLt.Private_GetFullTypeNameStatement(@RemoteDatabaseName,'p.user_type_id','p.max_length','p.precision','p.scale','NULL')) +')t
      WHERE object_id = '+CAST(@ProcedureObjectId AS NVARCHAR(MAX))+';'

	EXEC(@cmd);

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
                   @ProcParmTypeList = @ProcParmTypeList + @ProcParmTypeListSeparator + @ParamName + ' ' + @TypeName + 
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

            SELECT @Separator = ',';        
            SELECT @ProcParmTypeListSeparator = ',';
        END
        ELSE
        BEGIN
            SELECT @ProcParmTypeList = @ProcParmTypeListSeparator + @ParamName + ' CURSOR VARYING OUTPUT';
            SELECT @ProcParmTypeListSeparator = ',';
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
