/*
   Copyright 2011 tSQLt

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/

tSQLt.DropClass
    WITH A(name, type) AS
           (SELECT QUOTENAME(SCHEMA_NAME(schema_id))+'.'+QUOTENAME(name) , type -- <use tSQLt.private_GetQuotedFullName>
              FROM sys.objects
             WHERE schema_id = SCHEMA_ID(@ClassName)
          ),

            SELECT -1,'DROP SCHEMA ' + QUOTENAME(name) +';' -- <use tSQLt.private_getCleanSchemaName>
              FROM sys.schemas
             WHERE schema_id = SCHEMA_ID(@ClassName)
             
             
             
tSQLt.NewTestClass
    EXEC ('CREATE SCHEMA ' + @ClassName); -- <use tSQLt.private_getCleanSchemaName>
    
    
tSQLt.private_getForeignKeyDefinition
                WHERE k.parent_object_id = OBJECT_ID(@SchemaName + '.' + @ParentTableName) -- <refactor to private_GetObjectId(@schemaName, @objectName)>
                  AND k.object_id = OBJECT_ID(@SchemaName + '.' + @ForeignKeyName) -- <refactor to private_GetObjectId(@schemaName, @objectName)>


tSQLt.private_RunTest
    SELECT @cmd = 'EXEC ' + @testName; -- <use tSQLt.private_GetQuotedFullName>

    SELECT @testClassName = tSQLt.private_getCleanSchemaName('', @testName),
           @testProcName = tSQLt.private_getCleanObjectName(@testName);

        INSERT tSQLt.TestResult(Class, TestCase, TranName, Result, Msg)
        SELECT @testClassName, 
               @testProcName,  
               '?', 
               'Error', 
               'TestResult entry is missing; Original outcome: ' + @Result + ', ' + @Msg;


tSQLt.RunTest
    SELECT @resolvedTestName = '['+OBJECT_SCHEMA_NAME(OBJECT_ID(@testName))+'].['+OBJECT_NAME(OBJECT_ID(@testName))+']'; -- <use tSQLt.private_GetQuotedFullName>


tSQLt.Run

  ----- There is some voodoo here because @testName could be a schema name or a procedure name ------
  ----- If we use tSQLt.private_GetQuotedFullName as indicated below, then we only need to decide if we were passed a schema or procedure name ? ------
    SELECT @testName = CASE WHEN @testName LIKE '\[%\]' ESCAPE '\'
                             AND @testName NOT LIKE '\[%[^[]\].\[%\]' ESCAPE '\'
                            THEN SUBSTRING(@testName, 2, LEN(@testName) -2)
                            ELSE @testName
                       END; --UNQUOTENAME(@testName) for bug in SCHEMA_ID() function

    SELECT @testClassName = COALESCE(SCHEMA_NAME(SCHEMA_ID(@testName)),OBJECT_SCHEMA_NAME(OBJECT_ID(@testName))),
           @testCaseName = OBJECT_NAME(OBJECT_ID(@testName));

    SELECT @fullName = QUOTENAME(@testClassName) + 
                      COALESCE('.' + QUOTENAME(@testCaseName), ''); -- <use tSQLt.private_GetQuotedFullName>


    INSERT INTO tSQLt.Run_LastExecution(testName, session_id, login_time)
    SELECT testName = @fullName,
           session_id,
           login_time
      FROM sys.dm_exec_sessions
     WHERE session_id = @@SPID;

    SELECT @testClassId = SCHEMA_ID(@testClassName),
           @testCaseId = OBJECT_ID(@testName);

    EXEC tSQLt.private_CleanTestResult;
    
    SELECT @SetUp = '['+SCHEMA_NAME(schema_id)+'].['+name+']' -- <use tSQLt.private_GetQuotedFullName>
      FROM sys.procedures
     WHERE schema_id = SCHEMA_ID(@testClassName)
       AND name = 'SetUp';

    DECLARE testCases CURSOR LOCAL FAST_FORWARD 
        FOR
     SELECT '['+SCHEMA_NAME(schema_id)+'].['+name+']' -- <use tSQLt.private_GetQuotedFullName>
       FROM sys.procedures
      WHERE schema_id = SCHEMA_ID(@testClassName)
        AND ((@testCaseId IS NULL AND name LIKE 'test%')
             OR
             object_id = @testCaseId
            );


tSQLt.private_RunTestClass
    SELECT @SetUp = tSQLt.private_GetQuotedFullName(object_id)
      FROM sys.procedures
     WHERE schema_id = SCHEMA_ID(@testClassName)
       AND name = 'SetUp';

    DECLARE testCases CURSOR LOCAL FAST_FORWARD 
        FOR
     SELECT tSQLt.private_GetQuotedFullName(object_id)
       FROM sys.procedures
      WHERE schema_id = SCHEMA_ID(@testClassName)
        AND name LIKE 'test%';


tSQLt.RunAll
   SELECT DISTINCT s.name AS testClassName  -- <eventually calls to tSQLt.private_RunTestClass which handles proper name resolution, I think this is OK>
     FROM sys.extended_properties ep
     JOIN sys.schemas s
       ON ep.major_id = s.schema_id
    WHERE ep.name = N'tSQLt.TestClass';


tSQLt.private_ValidateProcedureCanBeUsedWithSpyProcedure
    IF NOT EXISTS(SELECT 1 FROM sys.procedures WHERE object_id = OBJECT_ID(@ProcedureName)) -- <OK?>


tSQLt.SpyProcedure
    SELECT @LogTableName = QUOTENAME(OBJECT_SCHEMA_NAME(ObjId)) + '.' + QUOTENAME(OBJECT_NAME(ObjId)+'_SpyProcedureLog') -- <refactor this out to a new method, I believe similar things are done elsewhere>
      FROM (SELECT OBJECT_ID(@ProcedureName) AS ObjId)X;

    DECLARE Parameters CURSOR FOR
     SELECT p.name, t.TypeName, is_output, is_cursor_ref
       FROM sys.parameters p
       CROSS APPLY tSQLt.getFullTypeName(p.user_type_id,p.max_length,p.precision,p.scale) t
      WHERE object_id = OBJECT_ID(@ProcedureName);


tSQLt.AssertObjectExists
     IF OBJECT_ID(@objectName) -- <OK?>
     

tSQLt.StubRecord -- <this method should probably be deprecated>
    SET @vcInsertStmt = 'INSERT INTO ' + @snTableName + ' (' 
    
    WHERE syscolumns.id = OBJECT_ID(@snTableName)  

        SELECT @vcInsertStmt = @vcInsertStmt + syscolumns.name  
        FROM syscolumns  
        WHERE syscolumns.id = OBJECT_ID(@snTableName)  
          AND syscolumns.colorder = 1  

        SET @vcInsertStmt = 'SET IDENTITY_INSERT ' + @snTableName + ' ON ' + CHAR(10) +   
                             @vcInsertStmt + CHAR(10) +   
                             'SET IDENTITY_INSERT ' + @snTableName + ' OFF '  


tSQLt.private_RenameObjectToUniqueName
   SET @fullName = @schemaName + '.' + @objectName; -- <use tSQLt.private_GetQuotedFullName>

   SET @newName=@objectName;  -- <use [tSQLt].[private_getCleanObjectName](@objectName)?>
   WHILE OBJECT_ID(@schemaName+'.'+@newName) IS NOT NULL  -- <use tSQLt.private_getCleanSchemaName>
       SELECT @newName=left(left(@objectName,150)+REPLACE(CAST(NEWID() AS NVARCHAR(200)),'-',''),256)  -- <use QUOTENAME>

   EXEC SP_RENAME @fullName, @newName;


tSQLt.FakeTable
   SET @schemaName = tSQLt.private_getCleanSchemaName(@schemaName, @tableName);

  -- <use tSQLt.private_GetQuotedFullName>
   SELECT @cmd = 'DECLARE @n TABLE(n INT IDENTITY(1,1));
      SELECT Src.*
        INTO ' + QUOTENAME(@schemaName) + '.' + QUOTENAME(@tableName) + '
        FROM ' + QUOTENAME(@schemaName) + '.' + QUOTENAME(@newName) + ' Src
       RIGHT JOIN @n AS n
          ON n.n<>n.n
       WHERE n.n<>n.n
   ';
   EXEC (@cmd);

   EXEC sys.sp_addextendedproperty 
   @name = N'tSQLt.FakeTable_OrgTableName', 
   @value = @newName, 
   @level0type = N'SCHEMA', @level0name = @schemaName, -- <use tSQLt.private_getCleanSchemaName>
   @level1type = N'TABLE',  @level1name = @tableName; -- <use tSQLt.[private_getCleanObjectName]>


tSQLt.TableCompare -- <make private>
-- <use private_GetQuotedFullName for @actual and @expected>
                      SELECT 2001,' INTO '+@an+' FROM '+@actual+';SELECT IDENTITY(INT,1,1) no'
                      UNION ALL
                      SELECT 4001,' INTO '+@en+' FROM '+
                                  @expected+';'+


tSQLt.AssertEqualsTable
-- <name resolutions should be handled in the called procedures>
    EXEC @failureOccurred = tSQLt.AssertObjectExists @Actual;
    IF @failureOccurred = 1 RETURN 1;
    EXEC @failureOccurred = tSQLt.AssertObjectExists @Expected;
    IF @failureOccurred = 1 RETURN 1;
        
    EXEC @r = tSQLt.TableCompare @Expected, @Actual, @TblMsg OUT;


tSQLt.ApplyConstraint
  SELECT @orgTableName = CAST(value AS NVARCHAR(4000))
    FROM sys.extended_properties
   WHERE class_desc = 'OBJECT_OR_COLUMN'
     AND major_id = OBJECT_ID(@schemaName + '.' + @tableName) -- <use tSQLt.private_GetQuotedFullName>
     AND minor_id = 0
     AND name = 'tSQLt.FakeTable_OrgTableName';

  SELECT @cmd = 'CONSTRAINT ' + name + ' CHECK' + definition 
    FROM sys.check_constraints
   WHERE object_id = OBJECT_ID(@schemaName + '.' + @constraintName) -- <refactor to private_GetObjectId(@schemaName, @objectName)>
     AND parent_object_id = OBJECT_ID(@schemaName + '.' + @orgTableName); -- <refactor to private_GetObjectId(@schemaName, @objectName)>

     EXEC tSQLt.private_RenameObjectToUniqueName @schemaName, @constraintName;
     SELECT @cmd = 'ALTER TABLE ' + @schemaName + '.' + @tableName + ' ADD ' + @cmd; -- <use tSQLt.private_GetQuotedFullName>

       FROM tSQLt.private_getForeignKeyDefinition(@schemaName, @orgTableName, @constraintName);

        EXEC tSQLt.private_RenameObjectToUniqueName @schemaName, @constraintName;
        SELECT @cmd = 'ALTER TABLE ' + @schemaName + '.' + @tableName + ' ADD ' + @cmd; -- <use tSQLt.private_GetQuotedFullName>


[tSQLt].[private_SetFakeViewOn_SingleView]
   SELECT @schemaName = OBJECT_SCHEMA_NAME(ObjId),
         @viewName = OBJECT_NAME(ObjId),
         @triggerName = OBJECT_NAME(ObjId) + '_SetFakeViewOn'
    FROM (SELECT OBJECT_ID(@ViewName) AS ObjId) X;

  SET @cmd = 
  -- <refactor so that names are properly resolved and quoted, may have to change replacement strategy>
     'CREATE TRIGGER $$SCHEMA_NAME$$.$$TRIGGER_NAME$$
      ON $$SCHEMA_NAME$$.$$VIEW_NAME$$ INSTEAD OF INSERT AS
      BEGIN
         RAISERROR(''Test system is in an invalid state. SetFakeViewOff must be called if SetFakeViewOn was called. Call SetFakeViewOff after creating all test case procedures.'', 16, 10) WITH NOWAIT;
         RETURN;
      END;
     ';
      
  SET @cmd = REPLACE(@cmd, '$$SCHEMA_NAME$$', QUOTENAME(@schemaName));
  SET @cmd = REPLACE(@cmd, '$$VIEW_NAME$$', QUOTENAME(@viewName));
  SET @cmd = REPLACE(@cmd, '$$TRIGGER_NAME$$', QUOTENAME(@triggerName));
  EXEC(@cmd);


[tSQLt].[SetFakeViewOn]
  DECLARE viewNames CURSOR LOCAL FAST_FORWARD FOR
  SELECT QUOTENAME(OBJECT_SCHEMA_NAME(object_id)) + '.' + QUOTENAME([name]) AS viewName -- <use tSQLt.private_GetQuotedFullName>
    FROM sys.objects
   WHERE type = 'V'
     AND schema_id = SCHEMA_ID(@schemaName);


[tSQLt].[SetFakeViewOff]
  DECLARE viewNames CURSOR LOCAL FAST_FORWARD FOR
   SELECT QUOTENAME(OBJECT_SCHEMA_NAME(t.parent_id)) + '.' + QUOTENAME(OBJECT_NAME(t.parent_id)) AS viewName -- <use tSQLt.private_GetQuotedFullName>
     FROM sys.extended_properties ep
     JOIN sys.triggers t
       on ep.major_id = t.object_id
     WHERE ep.name = N'SetFakeViewOnTrigger'  


[tSQLt].[private_SetFakeViewOff_SingleView]
-- <refactor so that names are properly resolved and quoted, may have to change replacement strategy>
  SELECT @schemaName = QUOTENAME(OBJECT_SCHEMA_NAME(ObjId)),
         @triggerName = QUOTENAME(OBJECT_NAME(ObjId) + '_SetFakeViewOn')
    FROM (SELECT OBJECT_ID(@ViewName) AS ObjId) X;
  
  SET @cmd = 'DROP TRIGGER %SCHEMA_NAME%.%TRIGGER_NAME%;';
      
  SET @cmd = REPLACE(@cmd, '%SCHEMA_NAME%', @schemaName);
  SET @cmd = REPLACE(@cmd, '%TRIGGER_NAME%', @triggerName);


tSQLt.private_GetQuotedFullName
    SELECT @quotedName = QUOTENAME(OBJECT_SCHEMA_NAME(@objectid)) + '.' + QUOTENAME(OBJECT_NAME(@objectid));


tSQLt.private_getCleanSchemaName -- <should use QUOTENAME?>
    RETURN (SELECT SCHEMA_NAME(schema_id) 
              FROM sys.objects 
             WHERE object_id = CASE WHEN ISNULL(@schemaName,'') in ('','[]')
                                    THEN OBJECT_ID(@objectName)
                                    ELSE OBJECT_ID(@schemaName + '.' + @objectName)
                                END);

[tSQLt].[private_getCleanObjectName] -- <should use QUOTENAME?>
    RETURN (SELECT OBJECT_NAME(OBJECT_ID(@objectName)));
