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
USE tempdb;

IF(db_id('tSQLt_Example') IS NOT NULL)
EXEC('
ALTER DATABASE tSQLt_Example SET RESTRICTED_USER WITH ROLLBACK IMMEDIATE;
USE tSQLt_Example;
ALTER DATABASE tSQLt_Example SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
USE tempdb;
DROP DATABASE tSQLt_Example;
');

CREATE DATABASE tSQLt_Example WITH TRUSTWORTHY ON;
GO
USE tSQLt_Example;
GO


------------------------------------------------------------------------------------
CREATE SCHEMA Accelerator;
GO

IF OBJECT_ID('Accelerator.Particle') IS NOT NULL DROP TABLE Accelerator.Particle;
GO
CREATE TABLE Accelerator.Particle(
  Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Point_Id PRIMARY KEY,
  X DECIMAL(10,2) NOT NULL,
  Y DECIMAL(10,2) NOT NULL,
  Value NVARCHAR(MAX) NOT NULL,
  ColorId INT NOT NULL
);
GO

IF OBJECT_ID('Accelerator.Color') IS NOT NULL DROP TABLE Practice.Color;
GO
CREATE TABLE Accelerator.Color(
  Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Color_Id PRIMARY KEY,
  ColorName NVARCHAR(MAX) NOT NULL
);
GO


GO

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
DECLARE @Msg NVARCHAR(MAX);SELECT @Msg = 'Installed at '+CONVERT(NVARCHAR,GETDATE(),121);RAISERROR(@Msg,0,1);
GO

IF TYPE_ID('tSQLt.Private') IS NOT NULL DROP TYPE tSQLt.Private;
IF TYPE_ID('tSQLtPrivate') IS NOT NULL DROP TYPE tSQLtPrivate;
GO
IF OBJECT_ID('tSQLt.DropClass') IS NOT NULL
    EXEC tSQLt.DropClass tSQLt;
GO

IF EXISTS (SELECT 1 FROM sys.assemblies WHERE name = 'tSQLtCLR')
    DROP ASSEMBLY tSQLtCLR;
GO

CREATE SCHEMA tSQLt;
GO
SET QUOTED_IDENTIFIER ON;
GO


GO

CREATE PROCEDURE tSQLt.DropClass
    @ClassName NVARCHAR(MAX)
AS
BEGIN
    DECLARE @Cmd NVARCHAR(MAX);

    WITH ObjectInfo(name, type) AS
         (
           SELECT QUOTENAME(SCHEMA_NAME(O.schema_id))+'.'+QUOTENAME(O.name) , O.type
             FROM sys.objects AS O
            WHERE O.schema_id = SCHEMA_ID(@ClassName)
         ),
         TypeInfo(name) AS
         (
           SELECT QUOTENAME(SCHEMA_NAME(T.schema_id))+'.'+QUOTENAME(T.name)
             FROM sys.types AS T
            WHERE T.schema_id = SCHEMA_ID(@ClassName)
         ),
         XMLSchemaInfo(name) AS
         (
           SELECT QUOTENAME(SCHEMA_NAME(XSC.schema_id))+'.'+QUOTENAME(XSC.name)
             FROM sys.xml_schema_collections AS XSC
            WHERE XSC.schema_id = SCHEMA_ID(@ClassName)
         ),
         DropStatements(no,cmd) AS
         (
           SELECT 10,
                  'DROP ' +
                  CASE type WHEN 'P' THEN 'PROCEDURE'
                            WHEN 'PC' THEN 'PROCEDURE'
                            WHEN 'U' THEN 'TABLE'
                            WHEN 'IF' THEN 'FUNCTION'
                            WHEN 'TF' THEN 'FUNCTION'
                            WHEN 'FN' THEN 'FUNCTION'
                            WHEN 'V' THEN 'VIEW'
                   END +
                   ' ' + 
                   name + 
                   ';'
              FROM ObjectInfo
             UNION ALL
           SELECT 20,
                  'DROP TYPE ' +
                   name + 
                   ';'
              FROM TypeInfo
             UNION ALL
           SELECT 30,
                  'DROP XML SCHEMA COLLECTION ' +
                   name + 
                   ';'
              FROM XMLSchemaInfo
             UNION ALL
            SELECT 10000,'DROP SCHEMA ' + QUOTENAME(name) +';'
              FROM sys.schemas
             WHERE schema_id = SCHEMA_ID(PARSENAME(@ClassName,1))
         ),
         StatementBlob(xml)AS
         (
           SELECT cmd [text()]
             FROM DropStatements
            ORDER BY no
              FOR XML PATH(''), TYPE
         )
    SELECT @Cmd = xml.value('/', 'NVARCHAR(MAX)') 
      FROM StatementBlob;

    EXEC(@Cmd);
END;


GO

GO
CREATE FUNCTION tSQLt.Private_Bin2Hex(@vb VARBINARY(MAX))
RETURNS TABLE
AS
RETURN
  SELECT X.S AS bare, '0x'+X.S AS prefix
    FROM (SELECT LOWER(CAST('' AS XML).value('xs:hexBinary(sql:variable("@vb") )','VARCHAR(MAX)')))X(S);
GO


GO

CREATE TABLE tSQLt.Private_NewTestClassList (
  ClassName NVARCHAR(450) PRIMARY KEY CLUSTERED
);


GO

GO
CREATE PROCEDURE tSQLt.Private_ResetNewTestClassList
AS
BEGIN
  SET NOCOUNT ON;
  DELETE FROM tSQLt.Private_NewTestClassList;
END;
GO


GO

GO
CREATE VIEW tSQLt.Private_SysTypes AS SELECT * FROM sys.types AS T;
GO
IF(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(MAX)) LIKE '9.%')
BEGIN
  EXEC('ALTER VIEW tSQLt.Private_SysTypes AS SELECT *,0 is_table_type FROM sys.types AS T;');
END;
GO


GO

GO
CREATE FUNCTION tSQLt.Private_GetFullTypeName(@TypeId INT, @Length INT, @Precision INT, @Scale INT, @CollationName NVARCHAR(MAX))
RETURNS TABLE
AS
RETURN SELECT X.SchemaName + '.' + X.Name + X.Suffix + X.Collation AS TypeName, X.SchemaName, X.Name, X.Suffix, X.is_table_type AS IsTableType
FROM(
  SELECT QUOTENAME(SCHEMA_NAME(T.schema_id)) SchemaName, QUOTENAME(T.name) Name,
              CASE WHEN T.max_length = -1
                    THEN ''
                   WHEN @Length = -1
                    THEN '(MAX)'
                   WHEN T.name LIKE 'n%char'
                    THEN '(' + CAST(@Length / 2 AS NVARCHAR) + ')'
                   WHEN T.name LIKE '%char' OR T.name LIKE '%binary'
                    THEN '(' + CAST(@Length AS NVARCHAR) + ')'
                   WHEN T.name IN ('decimal', 'numeric')
                    THEN '(' + CAST(@Precision AS NVARCHAR) + ',' + CAST(@Scale AS NVARCHAR) + ')'
                   ELSE ''
               END Suffix,
              CASE WHEN @CollationName IS NULL OR T.is_user_defined = 1 THEN ''
                   ELSE ' COLLATE ' + @CollationName
               END Collation,
               T.is_table_type
          FROM tSQLt.Private_SysTypes AS T WHERE T.user_type_id = @TypeId
          )X;


GO

CREATE PROCEDURE tSQLt.Private_DisallowOverwritingNonTestSchema
  @ClassName NVARCHAR(MAX)
AS
BEGIN
  IF SCHEMA_ID(@ClassName) IS NOT NULL AND tSQLt.Private_IsTestClass(@ClassName) = 0
  BEGIN
    RAISERROR('Attempted to execute tSQLt.NewTestClass on ''%s'' which is an existing schema but not a test class', 16, 10, @ClassName);
  END
END;


GO

CREATE FUNCTION tSQLt.Private_QuoteClassNameForNewTestClass(@ClassName NVARCHAR(MAX))
  RETURNS NVARCHAR(MAX)
AS
BEGIN
  RETURN 
    CASE WHEN @ClassName LIKE '[[]%]' THEN @ClassName
         ELSE QUOTENAME(@ClassName)
     END;
END;


GO

CREATE PROCEDURE tSQLt.Private_MarkSchemaAsTestClass
  @QuotedClassName NVARCHAR(MAX)
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @UnquotedClassName NVARCHAR(MAX);

  SELECT @UnquotedClassName = name
    FROM sys.schemas
   WHERE QUOTENAME(name) = @QuotedClassName;

  EXEC sp_addextendedproperty @name = N'tSQLt.TestClass', 
                              @value = 1,
                              @level0type = 'SCHEMA',
                              @level0name = @UnquotedClassName;

  INSERT INTO tSQLt.Private_NewTestClassList(ClassName)
  SELECT @UnquotedClassName
   WHERE NOT EXISTS
             (
               SELECT * 
                 FROM tSQLt.Private_NewTestClassList AS NTC
                 WITH(UPDLOCK,ROWLOCK,HOLDLOCK)
                WHERE NTC.ClassName = @UnquotedClassName
             );
END;


GO

CREATE PROCEDURE tSQLt.NewTestClass
    @ClassName NVARCHAR(MAX)
AS
BEGIN
  BEGIN TRY
    EXEC tSQLt.Private_DisallowOverwritingNonTestSchema @ClassName;

    EXEC tSQLt.DropClass @ClassName = @ClassName;

    DECLARE @QuotedClassName NVARCHAR(MAX);
    SELECT @QuotedClassName = tSQLt.Private_QuoteClassNameForNewTestClass(@ClassName);

    EXEC ('CREATE SCHEMA ' + @QuotedClassName);  
    EXEC tSQLt.Private_MarkSchemaAsTestClass @QuotedClassName;
  END TRY
  BEGIN CATCH
    DECLARE @ErrMsg NVARCHAR(MAX);SET @ErrMsg = ERROR_MESSAGE() + ' (Error originated in ' + ERROR_PROCEDURE() + ')';
    DECLARE @ErrSvr INT;SET @ErrSvr = ERROR_SEVERITY();
    
    RAISERROR(@ErrMsg, @ErrSvr, 10);
  END CATCH;
END;


GO

CREATE PROCEDURE tSQLt.Fail
    @Message0 NVARCHAR(MAX) = '',
    @Message1 NVARCHAR(MAX) = '',
    @Message2 NVARCHAR(MAX) = '',
    @Message3 NVARCHAR(MAX) = '',
    @Message4 NVARCHAR(MAX) = '',
    @Message5 NVARCHAR(MAX) = '',
    @Message6 NVARCHAR(MAX) = '',
    @Message7 NVARCHAR(MAX) = '',
    @Message8 NVARCHAR(MAX) = '',
    @Message9 NVARCHAR(MAX) = ''
AS
BEGIN
   DECLARE @WarningMessage NVARCHAR(MAX);
   SET @WarningMessage = '';

   IF XACT_STATE() = -1
   BEGIN
     SET @WarningMessage = CHAR(13)+CHAR(10)+'Warning: Uncommitable transaction detected!';

     DECLARE @TranName NVARCHAR(MAX);
     SELECT @TranName = TranName
       FROM tSQLt.TestResult
      WHERE Id = (SELECT MAX(Id) FROM tSQLt.TestResult);

     DECLARE @TranCount INT;
     SET @TranCount = @@TRANCOUNT;
     ROLLBACK;
     WHILE(@TranCount>0)
     BEGIN
       BEGIN TRAN;
       SET @TranCount = @TranCount -1;
     END;
     SAVE TRAN @TranName;
   END;

   INSERT INTO tSQLt.TestMessage(Msg)
   SELECT COALESCE(@Message0, '!NULL!')
        + COALESCE(@Message1, '!NULL!')
        + COALESCE(@Message2, '!NULL!')
        + COALESCE(@Message3, '!NULL!')
        + COALESCE(@Message4, '!NULL!')
        + COALESCE(@Message5, '!NULL!')
        + COALESCE(@Message6, '!NULL!')
        + COALESCE(@Message7, '!NULL!')
        + COALESCE(@Message8, '!NULL!')
        + COALESCE(@Message9, '!NULL!')
        + @WarningMessage;
        
   RAISERROR('tSQLt.Failure',16,10);
END;


GO

GO
CREATE TABLE tSQLt.TestResult(
    Id INT IDENTITY(1,1) PRIMARY KEY CLUSTERED,
    Class NVARCHAR(MAX) NOT NULL,
    TestCase NVARCHAR(MAX) NOT NULL,
    Name AS (QUOTENAME(Class) + '.' + QUOTENAME(TestCase)),
    TranName NVARCHAR(MAX) NOT NULL,
    Result NVARCHAR(MAX) NULL,
    Msg NVARCHAR(MAX) NULL,
    TestStartTime DATETIME NOT NULL CONSTRAINT [DF:TestResult(TestStartTime)] DEFAULT GETDATE(),
    TestEndTime DATETIME NULL
);
GO
CREATE TABLE tSQLt.TestMessage(
    Msg NVARCHAR(MAX)
);
GO
CREATE TABLE tSQLt.Run_LastExecution(
    TestName NVARCHAR(MAX),
    SessionId INT,
    LoginTime DATETIME
);
GO
CREATE TABLE tSQLt.Private_ExpectException(i INT);
GO
CREATE PROCEDURE tSQLt.Private_Print 
    @Message NVARCHAR(MAX),
    @Severity INT = 0
AS 
BEGIN
    DECLARE @SPos INT;SET @SPos = 1;
    DECLARE @EPos INT;
    DECLARE @Len INT; SET @Len = LEN(@Message);
    DECLARE @SubMsg NVARCHAR(MAX);
    DECLARE @Cmd NVARCHAR(MAX);
    
    DECLARE @CleanedMessage NVARCHAR(MAX);
    SET @CleanedMessage = REPLACE(@Message,'%','%%');
    
    WHILE (@SPos <= @Len)
    BEGIN
      SET @EPos = CHARINDEX(CHAR(13)+CHAR(10),@CleanedMessage+CHAR(13)+CHAR(10),@SPos);
      SET @SubMsg = SUBSTRING(@CleanedMessage, @SPos, @EPos - @SPos);
      SET @Cmd = N'RAISERROR(@Msg,@Severity,10) WITH NOWAIT;';
      EXEC sp_executesql @Cmd, 
                         N'@Msg NVARCHAR(MAX),@Severity INT',
                         @SubMsg,
                         @Severity;
      SELECT @SPos = @EPos + 2,
             @Severity = 0; --Print only first line with high severity
    END

    RETURN 0;
END;
GO

CREATE PROCEDURE tSQLt.Private_PrintXML
    @Message XML
AS 
BEGIN
    SELECT @Message FOR XML PATH('');--Required together with ":XML ON" sqlcmd statement to allow more than 1mb to be returned
    RETURN 0;
END;
GO


CREATE PROCEDURE tSQLt.GetNewTranName
  @TranName CHAR(32) OUTPUT
AS
BEGIN
  SELECT @TranName = LEFT('tSQLtTran'+REPLACE(CAST(NEWID() AS NVARCHAR(60)),'-',''),32);
END;
GO



CREATE PROCEDURE tSQLt.SetTestResultFormatter
    @Formatter NVARCHAR(4000)
AS
BEGIN
    IF EXISTS (SELECT 1 FROM sys.extended_properties WHERE [name] = N'tSQLt.ResultsFormatter')
    BEGIN
        EXEC sp_dropextendedproperty @name = N'tSQLt.ResultsFormatter',
                                    @level0type = 'SCHEMA',
                                    @level0name = 'tSQLt',
                                    @level1type = 'PROCEDURE',
                                    @level1name = 'Private_OutputTestResults';
    END;

    EXEC sp_addextendedproperty @name = N'tSQLt.ResultsFormatter', 
                                @value = @Formatter,
                                @level0type = 'SCHEMA',
                                @level0name = 'tSQLt',
                                @level1type = 'PROCEDURE',
                                @level1name = 'Private_OutputTestResults';
END;
GO

CREATE FUNCTION tSQLt.GetTestResultFormatter()
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @FormatterName NVARCHAR(MAX);
    
    SELECT @FormatterName = CAST(value AS NVARCHAR(MAX))
    FROM sys.extended_properties
    WHERE name = N'tSQLt.ResultsFormatter'
      AND major_id = OBJECT_ID('tSQLt.Private_OutputTestResults');
      
    SELECT @FormatterName = COALESCE(@FormatterName, 'tSQLt.DefaultResultFormatter');
    
    RETURN @FormatterName;
END;
GO

CREATE PROCEDURE tSQLt.Private_OutputTestResults
  @TestResultFormatter NVARCHAR(MAX) = NULL
AS
BEGIN
    DECLARE @Formatter NVARCHAR(MAX);
    SELECT @Formatter = COALESCE(@TestResultFormatter, tSQLt.GetTestResultFormatter());
    EXEC (@Formatter);
END
GO

----------------------------------------------------------------------
CREATE FUNCTION tSQLt.Private_GetLastTestNameIfNotProvided(@TestName NVARCHAR(MAX))
RETURNS NVARCHAR(MAX)
AS
BEGIN
  IF(LTRIM(ISNULL(@TestName,'')) = '')
  BEGIN
    SELECT @TestName = TestName 
      FROM tSQLt.Run_LastExecution le
      JOIN sys.dm_exec_sessions es
        ON le.SessionId = es.session_id
       AND le.LoginTime = es.login_time
     WHERE es.session_id = @@SPID;
  END

  RETURN @TestName;
END
GO

CREATE PROCEDURE tSQLt.Private_SaveTestNameForSession 
  @TestName NVARCHAR(MAX)
AS
BEGIN
  DELETE FROM tSQLt.Run_LastExecution
   WHERE SessionId = @@SPID;  

  INSERT INTO tSQLt.Run_LastExecution(TestName, SessionId, LoginTime)
  SELECT TestName = @TestName,
         session_id,
         login_time
    FROM sys.dm_exec_sessions
   WHERE session_id = @@SPID;
END
GO

----------------------------------------------------------------------
CREATE VIEW tSQLt.TestClasses
AS
  SELECT s.name AS Name, s.schema_id AS SchemaId
    FROM sys.extended_properties ep
    JOIN sys.schemas s
      ON ep.major_id = s.schema_id
   WHERE ep.name = N'tSQLt.TestClass';
GO

CREATE VIEW tSQLt.Tests
AS
  SELECT classes.SchemaId, classes.Name AS TestClassName, 
         procs.object_id AS ObjectId, procs.name AS Name
    FROM tSQLt.TestClasses classes
    JOIN sys.procedures procs ON classes.SchemaId = procs.schema_id
   WHERE LOWER(procs.name) LIKE 'test%';
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
       SELECT 'Test Case Summary: ' + CAST(Cnt AS NVARCHAR) + ' test case(s) executed, '+
                  CAST(SuccessCnt AS NVARCHAR) + ' succeeded, '+
                  CAST(FailCnt AS NVARCHAR) + ' failed, '+
                  CAST(ErrorCnt AS NVARCHAR) + ' errored.' Msg,*
         FROM A;
GO

CREATE PROCEDURE tSQLt.Private_ValidateProcedureCanBeUsedWithSpyProcedure
    @ProcedureName NVARCHAR(MAX)
AS
BEGIN
    IF NOT EXISTS(SELECT 1 FROM sys.procedures WHERE object_id = OBJECT_ID(@ProcedureName))
    BEGIN
      RAISERROR('Cannot use SpyProcedure on %s because the procedure does not exist', 16, 10, @ProcedureName) WITH NOWAIT;
    END;
    
    IF (1020 < (SELECT COUNT(*) FROM sys.parameters WHERE object_id = OBJECT_ID(@ProcedureName)))
    BEGIN
      RAISERROR('Cannot use SpyProcedure on procedure %s because it contains more than 1020 parameters', 16, 10, @ProcedureName) WITH NOWAIT;
    END;
END;
GO


CREATE PROCEDURE tSQLt.AssertEquals
    @Expected SQL_VARIANT,
    @Actual SQL_VARIANT,
    @Message NVARCHAR(MAX) = ''
AS
BEGIN
    IF ((@Expected = @Actual) OR (@Actual IS NULL AND @Expected IS NULL))
      RETURN 0;

    DECLARE @Msg NVARCHAR(MAX);
    SELECT @Msg = 'Expected: <' + ISNULL(CAST(@Expected AS NVARCHAR(MAX)), 'NULL') + 
                  '> but was: <' + ISNULL(CAST(@Actual AS NVARCHAR(MAX)), 'NULL') + '>';
    IF((COALESCE(@Message,'') <> '') AND (@Message NOT LIKE '% ')) SET @Message = @Message + ' ';
    EXEC tSQLt.Fail @Message, @Msg;
END;
GO

/*******************************************************************************************/
/*******************************************************************************************/
/*******************************************************************************************/
CREATE FUNCTION tSQLt.Private_GetCleanSchemaName(@SchemaName NVARCHAR(MAX), @ObjectName NVARCHAR(MAX))
RETURNS NVARCHAR(MAX)
AS
BEGIN
    RETURN (SELECT SCHEMA_NAME(schema_id) 
              FROM sys.objects 
             WHERE object_id = CASE WHEN ISNULL(@SchemaName,'') in ('','[]')
                                    THEN OBJECT_ID(@ObjectName)
                                    ELSE OBJECT_ID(@SchemaName + '.' + @ObjectName)
                                END);
END;
GO

CREATE FUNCTION [tSQLt].[Private_GetCleanObjectName](@ObjectName NVARCHAR(MAX))
RETURNS NVARCHAR(MAX)
AS
BEGIN
    RETURN (SELECT OBJECT_NAME(OBJECT_ID(@ObjectName)));
END;
GO

CREATE FUNCTION tSQLt.Private_ResolveFakeTableNamesForBackwardCompatibility 
 (@TableName NVARCHAR(MAX), @SchemaName NVARCHAR(MAX))
RETURNS TABLE AS 
RETURN
  SELECT QUOTENAME(OBJECT_SCHEMA_NAME(object_id)) AS CleanSchemaName,
         QUOTENAME(OBJECT_NAME(object_id)) AS CleanTableName
     FROM (SELECT CASE
                    WHEN @SchemaName IS NULL THEN OBJECT_ID(@TableName)
                    ELSE COALESCE(OBJECT_ID(@SchemaName + '.' + @TableName),OBJECT_ID(@TableName + '.' + @SchemaName)) 
                  END object_id
          ) ids;
GO


/*******************************************************************************************/
/*******************************************************************************************/
/*******************************************************************************************/
CREATE FUNCTION tSQLt.Private_GetOriginalTableName(@SchemaName NVARCHAR(MAX), @TableName NVARCHAR(MAX)) --DELETE!!!
RETURNS NVARCHAR(MAX)
AS
BEGIN
  RETURN (SELECT CAST(value AS NVARCHAR(4000))
    FROM sys.extended_properties
   WHERE class_desc = 'OBJECT_OR_COLUMN'
     AND major_id = OBJECT_ID(@SchemaName + '.' + @TableName)
     AND minor_id = 0
     AND name = 'tSQLt.FakeTable_OrgTableName');
END;
GO

CREATE FUNCTION tSQLt.Private_GetOriginalTableInfo(@TableObjectId INT)
RETURNS TABLE
AS
  RETURN SELECT CAST(value AS NVARCHAR(4000)) OrgTableName,
                OBJECT_ID(QUOTENAME(OBJECT_SCHEMA_NAME(@TableObjectId)) + '.' + QUOTENAME(CAST(value AS NVARCHAR(4000)))) OrgTableObjectId
    FROM sys.extended_properties
   WHERE class_desc = 'OBJECT_OR_COLUMN'
     AND major_id = @TableObjectId
     AND minor_id = 0
     AND name = 'tSQLt.FakeTable_OrgTableName';
GO



CREATE FUNCTION [tSQLt].[F_Num](
       @N INT
)
RETURNS TABLE 
AS 
RETURN WITH C0(c) AS (SELECT 1 UNION ALL SELECT 1),
            C1(c) AS (SELECT 1 FROM C0 AS A CROSS JOIN C0 AS B),
            C2(c) AS (SELECT 1 FROM C1 AS A CROSS JOIN C1 AS B),
            C3(c) AS (SELECT 1 FROM C2 AS A CROSS JOIN C2 AS B),
            C4(c) AS (SELECT 1 FROM C3 AS A CROSS JOIN C3 AS B),
            C5(c) AS (SELECT 1 FROM C4 AS A CROSS JOIN C4 AS B),
            C6(c) AS (SELECT 1 FROM C5 AS A CROSS JOIN C5 AS B)
       SELECT TOP(CASE WHEN @N>0 THEN @N ELSE 0 END) ROW_NUMBER() OVER (ORDER BY c) no
         FROM C6;
GO

CREATE PROCEDURE [tSQLt].[Private_SetFakeViewOn_SingleView]
  @ViewName NVARCHAR(MAX)
AS
BEGIN
  DECLARE @Cmd NVARCHAR(MAX),
          @SchemaName NVARCHAR(MAX),
          @TriggerName NVARCHAR(MAX);
          
  SELECT @SchemaName = OBJECT_SCHEMA_NAME(ObjId),
         @ViewName = OBJECT_NAME(ObjId),
         @TriggerName = OBJECT_NAME(ObjId) + '_SetFakeViewOn'
    FROM (SELECT OBJECT_ID(@ViewName) AS ObjId) X;

  SET @Cmd = 
     'CREATE TRIGGER $$SCHEMA_NAME$$.$$TRIGGER_NAME$$
      ON $$SCHEMA_NAME$$.$$VIEW_NAME$$ INSTEAD OF INSERT AS
      BEGIN
         RAISERROR(''Test system is in an invalid state. SetFakeViewOff must be called if SetFakeViewOn was called. Call SetFakeViewOff after creating all test case procedures.'', 16, 10) WITH NOWAIT;
         RETURN;
      END;
     ';
      
  SET @Cmd = REPLACE(@Cmd, '$$SCHEMA_NAME$$', QUOTENAME(@SchemaName));
  SET @Cmd = REPLACE(@Cmd, '$$VIEW_NAME$$', QUOTENAME(@ViewName));
  SET @Cmd = REPLACE(@Cmd, '$$TRIGGER_NAME$$', QUOTENAME(@TriggerName));
  EXEC(@Cmd);

  EXEC sp_addextendedproperty @name = N'SetFakeViewOnTrigger', 
                               @value = 1,
                               @level0type = 'SCHEMA',
                               @level0name = @SchemaName, 
                               @level1type = 'VIEW',
                               @level1name = @ViewName,
                               @level2type = 'TRIGGER',
                               @level2name = @TriggerName;

  RETURN 0;
END;
GO

CREATE PROCEDURE [tSQLt].[SetFakeViewOn]
  @SchemaName NVARCHAR(MAX)
AS
BEGIN
  DECLARE @ViewName NVARCHAR(MAX);
    
  DECLARE viewNames CURSOR LOCAL FAST_FORWARD FOR
  SELECT QUOTENAME(OBJECT_SCHEMA_NAME(object_id)) + '.' + QUOTENAME([name]) AS viewName
    FROM sys.views
   WHERE schema_id = SCHEMA_ID(@SchemaName);
  
  OPEN viewNames;
  
  FETCH NEXT FROM viewNames INTO @ViewName;
  WHILE @@FETCH_STATUS = 0
  BEGIN
    EXEC tSQLt.Private_SetFakeViewOn_SingleView @ViewName;
    
    FETCH NEXT FROM viewNames INTO @ViewName;
  END;
  
  CLOSE viewNames;
  DEALLOCATE viewNames;
END;
GO

CREATE PROCEDURE [tSQLt].[Private_SetFakeViewOff_SingleView]
  @ViewName NVARCHAR(MAX)
AS
BEGIN
  DECLARE @Cmd NVARCHAR(MAX),
          @SchemaName NVARCHAR(MAX),
          @TriggerName NVARCHAR(MAX);
          
  SELECT @SchemaName = QUOTENAME(OBJECT_SCHEMA_NAME(ObjId)),
         @TriggerName = QUOTENAME(OBJECT_NAME(ObjId) + '_SetFakeViewOn')
    FROM (SELECT OBJECT_ID(@ViewName) AS ObjId) X;
  
  SET @Cmd = 'DROP TRIGGER %SCHEMA_NAME%.%TRIGGER_NAME%;';
      
  SET @Cmd = REPLACE(@Cmd, '%SCHEMA_NAME%', @SchemaName);
  SET @Cmd = REPLACE(@Cmd, '%TRIGGER_NAME%', @TriggerName);
  
  EXEC(@Cmd);
END;
GO

CREATE PROCEDURE [tSQLt].[SetFakeViewOff]
  @SchemaName NVARCHAR(MAX)
AS
BEGIN
  DECLARE @ViewName NVARCHAR(MAX);
    
  DECLARE viewNames CURSOR LOCAL FAST_FORWARD FOR
   SELECT QUOTENAME(OBJECT_SCHEMA_NAME(t.parent_id)) + '.' + QUOTENAME(OBJECT_NAME(t.parent_id)) AS viewName
     FROM sys.extended_properties ep
     JOIN sys.triggers t
       on ep.major_id = t.object_id
     WHERE ep.name = N'SetFakeViewOnTrigger'  
  OPEN viewNames;
  
  FETCH NEXT FROM viewNames INTO @ViewName;
  WHILE @@FETCH_STATUS = 0
  BEGIN
    EXEC tSQLt.Private_SetFakeViewOff_SingleView @ViewName;
    
    FETCH NEXT FROM viewNames INTO @ViewName;
  END;
  
  CLOSE viewNames;
  DEALLOCATE viewNames;
END;
GO

CREATE FUNCTION tSQLt.Private_GetQuotedFullName(@Objectid INT)
RETURNS NVARCHAR(517)
AS
BEGIN
    DECLARE @QuotedName NVARCHAR(517);
    SELECT @QuotedName = QUOTENAME(OBJECT_SCHEMA_NAME(@Objectid)) + '.' + QUOTENAME(OBJECT_NAME(@Objectid));
    RETURN @QuotedName;
END;
GO

CREATE FUNCTION tSQLt.Private_GetSchemaId(@SchemaName NVARCHAR(MAX))
RETURNS INT
AS
BEGIN
  RETURN (
    SELECT TOP(1) schema_id
      FROM sys.schemas
     WHERE @SchemaName IN (name, QUOTENAME(name), QUOTENAME(name, '"'))
     ORDER BY 
        CASE WHEN name = @SchemaName THEN 0 ELSE 1 END
  );
END;
GO

CREATE FUNCTION tSQLt.Private_IsTestClass(@TestClassName NVARCHAR(MAX))
RETURNS BIT
AS
BEGIN
  RETURN 
    CASE 
      WHEN EXISTS(
             SELECT 1 
               FROM tSQLt.TestClasses
              WHERE SchemaId = tSQLt.Private_GetSchemaId(@TestClassName)
            )
      THEN 1
      ELSE 0
    END;
END;
GO

CREATE FUNCTION tSQLt.Private_ResolveSchemaName(@Name NVARCHAR(MAX))
RETURNS TABLE 
AS
RETURN
  WITH ids(schemaId) AS
       (SELECT tSQLt.Private_GetSchemaId(@Name)
       ),
       idsWithNames(schemaId, quotedSchemaName) AS
        (SELECT schemaId,
         QUOTENAME(SCHEMA_NAME(schemaId))
         FROM ids
        )
  SELECT schemaId, 
         quotedSchemaName,
         CASE WHEN EXISTS(SELECT 1 FROM tSQLt.TestClasses WHERE TestClasses.SchemaId = idsWithNames.schemaId)
               THEN 1
              ELSE 0
         END AS isTestClass, 
         CASE WHEN schemaId IS NOT NULL THEN 1 ELSE 0 END AS isSchema
    FROM idsWithNames;
GO

CREATE FUNCTION tSQLt.Private_ResolveObjectName(@Name NVARCHAR(MAX))
RETURNS TABLE 
AS
RETURN
  WITH ids(schemaId, objectId) AS
       (SELECT SCHEMA_ID(OBJECT_SCHEMA_NAME(OBJECT_ID(@Name))),
               OBJECT_ID(@Name)
       ),
       idsWithNames(schemaId, objectId, quotedSchemaName, quotedObjectName) AS
        (SELECT schemaId, objectId,
         QUOTENAME(SCHEMA_NAME(schemaId)) AS quotedSchemaName, 
         QUOTENAME(OBJECT_NAME(objectId)) AS quotedObjectName
         FROM ids
        )
  SELECT schemaId, 
         objectId, 
         quotedSchemaName,
         quotedObjectName,
         quotedSchemaName + '.' + quotedObjectName AS quotedFullName, 
         CASE WHEN LOWER(quotedObjectName) LIKE '[[]test%]' 
               AND objectId = OBJECT_ID(quotedSchemaName + '.' + quotedObjectName,'P') 
              THEN 1 ELSE 0 END AS isTestCase
    FROM idsWithNames;
    
GO

CREATE FUNCTION tSQLt.Private_ResolveName(@Name NVARCHAR(MAX))
RETURNS TABLE 
AS
RETURN
  WITH resolvedNames(ord, schemaId, objectId, quotedSchemaName, quotedObjectName, quotedFullName, isTestClass, isTestCase, isSchema) AS
  (SELECT 1, schemaId, NULL, quotedSchemaName, NULL, quotedSchemaName, isTestClass, 0, 1
     FROM tSQLt.Private_ResolveSchemaName(@Name)
    UNION ALL
   SELECT 2, schemaId, objectId, quotedSchemaName, quotedObjectName, quotedFullName, 0, isTestCase, 0
     FROM tSQLt.Private_ResolveObjectName(@Name)
    UNION ALL
   SELECT 3, NULL, NULL, NULL, NULL, NULL, 0, 0, 0
   )
   SELECT TOP(1) schemaId, objectId, quotedSchemaName, quotedObjectName, quotedFullName, isTestClass, isTestCase, isSchema
     FROM resolvedNames
    WHERE schemaId IS NOT NULL 
       OR ord = 3
    ORDER BY ord
GO

CREATE PROCEDURE tSQLt.Uninstall
AS
BEGIN
  DROP TYPE tSQLt.Private;

  EXEC tSQLt.DropClass 'tSQLt';  
  
  DROP ASSEMBLY tSQLtCLR;
END;
GO


GO

GO
CREATE FUNCTION tSQLt.Private_GetExternalAccessKeyBytes()
RETURNS TABLE
AS
RETURN
  SELECT 0x4D5A90000300000004000000FFFF0000B800000000000000400000000000000000000000000000000000000000000000000000000000000000000000800000000E1FBA0E00B409CD21B8014CCD21546869732070726F6772616D2063616E6E6F742062652072756E20696E20444F53206D6F64652E0D0D0A2400000000000000504500004C0103005419AD560000000000000000E00002210B010B00000400000006000000000000CE2300000020000000400000000000100020000000020000040000000000000004000000000000000080000000020000817000000300408500001000001000000000100000100000000000001000000000000000000000007C2300004F00000000400000E002000000000000000000000000000000000000006000000C00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000200000080000000000000000000000082000004800000000000000000000002E74657874000000D4030000002000000004000000020000000000000000000000000000200000602E72737263000000E0020000004000000004000000060000000000000000000000000000400000402E72656C6F6300000C0000000060000000020000000A00000000000000000000000000004000004200000000000000000000000000000000B0230000000000004800000002000500D0200000AC0200000900000000000000000000000000000050200000800000000000000000000000000000000000000000000000000000000000000000000000213462F5B9EF260060DE50E40053E6687E4C3CB839148A25A72ED4644D1DB6A8835FE0C2D5FDD8B91073B9C39F7A8FCD4BE43786C9306E73D060E389A18E678E8BF334A1C46DCD33B21D6986A0DDEF92A7C1CD14E1D25582B177CF24DFBE14AB8845A657360F13F7E75792FFBC48D5C7FB979E2E480BFDB7B8AEEB16FB394A3A42534A4201000100000000000C00000076322E302E35303732370000000005006C0000009C000000237E000008010000AC00000023537472696E677300000000B40100000800000023555300BC010000100000002347554944000000CC010000E000000023426C6F620000000000000002000001071400000900000000FA2533001600000100000002000000010000000200000002000000010000000100000000000A0001000000000006004E002E00060074002E00000000000100000000000100010009006E000A0011006E000F002E000B00B5002E001300BE000480000000000000000000000100000013009200000002000000000000000000000001002500000000000000003C4D6F64756C653E007453514C7445787465726E616C4163636573734B65792E646C6C006D73636F726C69620053797374656D2E52756E74696D652E436F6D70696C6572536572766963657300436F6D70696C6174696F6E52656C61786174696F6E73417474726962757465002E63746F720052756E74696D65436F6D7061746962696C697479417474726962757465007453514C7445787465726E616C4163636573734B6579000000000003200000000000FA9D540989B0294FAE952438919E8F450008B77A5C561934E08904200101080320000180A00024000004800000940000000602000000240000525341310004000001000100F7D9A45F2B508C2887A8794B053CE5DEB28743B7C748FF545F1F51218B684454B785054629C1417D1D3542B095D80BA171294948FCF978A502AA03240C024746B563BC29B4D8DCD6956593C0C425446021D699EF6FB4DC2155DE7E393150AD6617EDC01216EA93FCE5F8F7BE9FF605AD2B8344E8CC01BEDB924ED06FD368D1D00801000800000000001E01000100540216577261704E6F6E457863657074696F6E5468726F777301000000A42300000000000000000000BE230000002000000000000000000000000000000000000000000000B0230000000000000000000000005F436F72446C6C4D61696E006D73636F7265652E646C6C0000000000FF2500200010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100100000001800008000000000000000000000000000000100010000003000008000000000000000000000000000000100000000004800000058400000840200000000000000000000840234000000560053005F00560045005200530049004F004E005F0049004E0046004F0000000000BD04EFFE00000100000000000000000000000000000000003F000000000000000400000002000000000000000000000000000000440000000100560061007200460069006C00650049006E0066006F00000000002400040000005400720061006E0073006C006100740069006F006E00000000000000B004E4010000010053007400720069006E006700460069006C00650049006E0066006F000000C001000001003000300030003000300034006200300000002C0002000100460069006C0065004400650073006300720069007000740069006F006E000000000020000000300008000100460069006C006500560065007200730069006F006E000000000030002E0030002E0030002E003000000058001B00010049006E007400650072006E0061006C004E0061006D00650000007400530051004C007400450078007400650072006E0061006C004100630063006500730073004B00650079002E0064006C006C00000000002800020001004C006500670061006C0043006F00700079007200690067006800740000002000000060001B0001004F0072006900670069006E0061006C00460069006C0065006E0061006D00650000007400530051004C007400450078007400650072006E0061006C004100630063006500730073004B00650079002E0064006C006C0000000000340008000100500072006F006400750063007400560065007200730069006F006E00000030002E0030002E0030002E003000000038000800010041007300730065006D0062006C0079002000560065007200730069006F006E00000030002E0030002E0030002E003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000000C000000D03300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000 AS ExternalAccessKeyBytes, 0x7722217D36028E4C AS ExternalAccessKeyThumbPrint;
GO



GO

GO
CREATE PROCEDURE tSQLt.RemoveExternalAccessKey
AS
BEGIN
  IF(NOT EXISTS(SELECT * FROM sys.fn_my_permissions(NULL,'server') AS FMP WHERE FMP.permission_name = 'CONTROL SERVER'))
  BEGIN
    RAISERROR('Only principals with CONTROL SERVER permission can execute this procedure.',16,10);
    RETURN -1;
  END;

  DECLARE @master_sys_sp_executesql NVARCHAR(MAX); SET @master_sys_sp_executesql = 'master.sys.sp_executesql';

  IF SUSER_ID('tSQLtExternalAccessKey') IS NOT NULL DROP LOGIN tSQLtExternalAccessKey;
  EXEC @master_sys_sp_executesql N'IF ASYMKEY_ID(''tSQLtExternalAccessKey'') IS NOT NULL DROP ASYMMETRIC KEY tSQLtExternalAccessKey;';
  EXEC @master_sys_sp_executesql N'IF EXISTS(SELECT * FROM sys.assemblies WHERE name = ''tSQLtExternalAccessKey'') DROP ASSEMBLY tSQLtExternalAccessKey;';
END;
GO


GO

GO
CREATE PROCEDURE tSQLt.InstallExternalAccessKey
AS
BEGIN
  IF(NOT EXISTS(SELECT * FROM sys.fn_my_permissions(NULL,'server') AS FMP WHERE FMP.permission_name = 'CONTROL SERVER'))
  BEGIN
    RAISERROR('Only principals with CONTROL SERVER permission can execute this procedure.',16,10);
    RETURN -1;
  END;

  DECLARE @cmd NVARCHAR(MAX);
  DECLARE @cmd2 NVARCHAR(MAX);
  DECLARE @master_sys_sp_executesql NVARCHAR(MAX); SET @master_sys_sp_executesql = 'master.sys.sp_executesql';

  SET @cmd = 'IF EXISTS(SELECT * FROM sys.assemblies WHERE name = ''tSQLtExternalAccessKey'') DROP ASSEMBLY tSQLtExternalAccessKey;';
  EXEC @master_sys_sp_executesql @cmd;

  SET @cmd2 = 'SELECT @cmd = ''DROP ASSEMBLY ''+QUOTENAME(A.name)+'';'''+ 
              '  FROM master.sys.assemblies AS A'+
              ' WHERE A.clr_name LIKE ''tsqltexternalaccesskey, %'';';
  EXEC sys.sp_executesql @cmd2,N'@cmd NVARCHAR(MAX) OUTPUT',@cmd OUT;
  EXEC @master_sys_sp_executesql @cmd;

  SELECT @cmd = 
         'CREATE ASSEMBLY tSQLtExternalAccessKey AUTHORIZATION dbo FROM ' +
         BH.prefix +
         ' WITH PERMISSION_SET = SAFE;'       
    FROM tSQLt.Private_GetExternalAccessKeyBytes() AS PGEAKB
   CROSS APPLY tSQLt.Private_Bin2Hex(PGEAKB.ExternalAccessKeyBytes) BH;
  EXEC @master_sys_sp_executesql @cmd;

  IF SUSER_ID('tSQLtExternalAccessKey') IS NOT NULL DROP LOGIN tSQLtExternalAccessKey;

  SET @cmd = N'IF ASYMKEY_ID(''tSQLtExternalAccessKey'') IS NOT NULL DROP ASYMMETRIC KEY tSQLtExternalAccessKey;';
  EXEC @master_sys_sp_executesql @cmd;

  SET @cmd2 = 'SELECT @cmd = ISNULL(''DROP LOGIN ''+QUOTENAME(SP.name)+'';'','''')+''DROP ASYMMETRIC KEY '' + QUOTENAME(AK.name) + '';'''+
              '  FROM master.sys.asymmetric_keys AS AK'+
              '  JOIN tSQLt.Private_GetExternalAccessKeyBytes() AS PGEAKB'+
              '    ON AK.thumbprint = PGEAKB.ExternalAccessKeyThumbPrint'+
              '  LEFT JOIN master.sys.server_principals AS SP'+
              '    ON AK.sid = SP.sid;';
  EXEC sys.sp_executesql @cmd2,N'@cmd NVARCHAR(MAX) OUTPUT',@cmd OUT;
  EXEC @master_sys_sp_executesql @cmd;

  SET @cmd = 'CREATE ASYMMETRIC KEY tSQLtExternalAccessKey FROM ASSEMBLY tSQLtExternalAccessKey;';
  EXEC @master_sys_sp_executesql @cmd;
 
  SET @cmd = 'CREATE LOGIN tSQLtExternalAccessKey FROM ASYMMETRIC KEY tSQLtExternalAccessKey;';
  EXEC @master_sys_sp_executesql @cmd;

  SET @cmd = 'DROP ASSEMBLY tSQLtExternalAccessKey;';
  EXEC @master_sys_sp_executesql @cmd;

  SET @cmd = 'GRANT EXTERNAL ACCESS ASSEMBLY TO tSQLtExternalAccessKey;';
  EXEC @master_sys_sp_executesql @cmd;

END;
GO


GO

GO
CREATE PROCEDURE tSQLt.EnableExternalAccess
  @try BIT = 0,
  @enable BIT = 1
AS
BEGIN
  BEGIN TRY
    IF @enable = 1
    BEGIN
      EXEC('ALTER ASSEMBLY tSQLtCLR WITH PERMISSION_SET = EXTERNAL_ACCESS;');
    END
    ELSE
    BEGIN
      EXEC('ALTER ASSEMBLY tSQLtCLR WITH PERMISSION_SET = SAFE;');
    END
  END TRY
  BEGIN CATCH
    IF(@try = 0)
    BEGIN
      DECLARE @Message NVARCHAR(4000);
      SET @Message = 'The attempt to ' +
                      CASE WHEN @enable = 1 THEN 'enable' ELSE 'disable' END +
                      ' tSQLt features requiring EXTERNAL_ACCESS failed' +
                      ': '+ERROR_MESSAGE();
      RAISERROR(@Message,16,10);
    END;
    RETURN -1;
  END CATCH;
  RETURN 0;
END;
GO


GO

CREATE TABLE tSQLt.Private_Configurations (
  Name NVARCHAR(100) PRIMARY KEY CLUSTERED,
  Value SQL_VARIANT
);


GO

GO
CREATE PROCEDURE tSQLt.Private_SetConfiguration
  @Name NVARCHAR(100),
  @Value SQL_VARIANT
AS
BEGIN
  IF(EXISTS(SELECT 1 FROM tSQLt.Private_Configurations WITH(ROWLOCK,UPDLOCK) WHERE Name = @Name))
  BEGIN
    UPDATE tSQLt.Private_Configurations SET
           Value = @Value
     WHERE Name = @Name;
  END;
  ELSE
  BEGIN
     INSERT tSQLt.Private_Configurations(Name,Value)
     VALUES(@Name,@Value);
  END;
END;
GO


GO

GO
CREATE FUNCTION tSQLt.Private_GetConfiguration(
  @Name NVARCHAR(100)
)
RETURNS TABLE
AS
RETURN
  SELECT PC.Name,
         PC.Value 
    FROM tSQLt.Private_Configurations AS PC
   WHERE PC.Name = @Name;
GO


GO

GO
CREATE PROCEDURE tSQLt.SetVerbose
  @Verbose BIT = 1
AS
BEGIN
  EXEC tSQLt.Private_SetConfiguration @Name = 'Verbose', @Value = @Verbose;
END;
GO


GO

CREATE TABLE tSQLt.CaptureOutputLog (
  Id INT IDENTITY(1,1) PRIMARY KEY CLUSTERED,
  OutputText NVARCHAR(MAX)
);


GO

CREATE PROCEDURE tSQLt.LogCapturedOutput @text NVARCHAR(MAX)
AS
BEGIN
  INSERT INTO tSQLt.CaptureOutputLog (OutputText) VALUES (@text);
END;


GO

GO
CREATE ASSEMBLY [tSQLtCLR] AUTHORIZATION [dbo] FROM 0x4D5A90000300000004000000FFFF0000B800000000000000400000000000000000000000000000000000000000000000000000000000000000000000800000000E1FBA0E00B409CD21B8014CCD21546869732070726F6772616D2063616E6E6F742062652072756E20696E20444F53206D6F64652E0D0D0A2400000000000000504500004C0103005219AD560000000000000000E00002210B010B00004A000000060000000000001E68000000200000008000000000001000200000000200000400000000000000040000000000000000C00000000200001F550000030040850000100000100000000010000010000000000000100000000000000000000000C86700005300000000800000F80300000000000000000000000000000000000000A000000C000000906600001C0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000200000080000000000000000000000082000004800000000000000000000002E746578740000002448000000200000004A000000020000000000000000000000000000200000602E72737263000000F80300000080000000040000004C0000000000000000000000000000400000402E72656C6F6300000C00000000A0000000020000005000000000000000000000000000004000004200000000000000000000000000000000006800000000000048000000020005003C3500005431000009000000000000000000000000000000502000008000000000000000000000000000000000000000000000000000000000000000000000009D63A517CED9D2CE805B163A00868E987936F818709CD02EE31F21244D8C9BA69ECF06878608961FBE7E9C5B009E4C7ACF794FE36C51E8C75909B8E31CFA047713754986E739D088652ADF79832925307B3F8F9953D425C7A3F29B7334245E5F0E98EA299D08D952730F071DD02A73DF0B645A801A953787753CA8109DF47E6A1B3002006D00000001000011140A18730F00000A0B28020000060C08731000000A0A066F1100000A731200000A0D09066F1300000A090F01FE16080000016F1400000A6F1500000A096F1600000A26DE0A072C06076F1700000ADCDE0F13047201000070110473060000067ADE0A062C06066F1800000ADC2A00000001280000020009003C45000A00000000000002004F51000F32000001020002006062000A00000000133003004E0000000200001173400000060A066F450000060B066F460000060C731900000A0D0972B6000070076F1A00000A0972CE000070178C350000016F1A00000A0972F6000070086F1A00000A096F1B00000A130411042A1E02281C00000A2A1E02281E00000A2A220203281F00000A2A26020304282000000A2A26020304282100000A2A3A02281C00000A02037D010000042A7A0203280B000006027B01000004027B010000046F420000066F4B0000062A220203280B0000062A0000133002001400000003000011027B01000004036F470000060A066F2200000A2A6A282500000A6F2600000A6F2700000A6F1400000A282800000A2A56282500000A6F2600000A6F2900000A282A00000A2A0000001330040032000000040000117216010070282C00000A0A1200FE16400000016F1400000A723A010070723E0100706F2D00000A282E00000A282800000A2A00001B3005002B020000050000110F00282F00000A2C0B7240010070731F00000A7A0F01282F00000A2C0C723E010070282800000A10010F02282F00000A2C0C723E010070282800000A100273400000060A0F000F0128150000060B0607282800000A6F470000060C080428160000060D16130409166F3000000A8E698D420000011305096F3100000A13102B3B1210283200000A13061613072B1F110511071105110794110611079A6F3300000A283400000A9E110717581307110711068E6932D91104175813041210283500000A2DBCDE0E1210FE160200001B6F1700000ADC1613082B1A110511081105110894209B000000283600000A9E110817581308110811058E6932DE161309110513111613122B161111111294130A110917110A58581309111217581312111211118E6932E21109175813091109110417585A130917130B1109733700000A130C096F3100000A131338B00000001213283200000A130D110B2D08110C6F3800000A2616130E2B2C110C72760100706F3900000A110D110E9A28140000061105110E9428130000066F3900000A26110E1758130E110E110D8E6932CC110C72760100706F3900000A26110B2C5116130B110C6F3800000A2616130F2B2C110C727A0100706F3900000A26110C110C6F3A00000A723A0100701105110F946F3B00000A26110F1758130F110F110D8E6932CC110C727A0100706F3900000A261213283500000A3A44FFFFFFDE0E1213FE160200001B6F1700000ADC110C6F1400000A282800000A733C00000A2A00011C000002007E0048C6000E0000000002004801C30B020E000000001330050039000000060000110228120000060A727E010070733D00000A0B070F00FE16080000016F1400000A72E201007017066F3E00000A0C08282800000A733C00000A2A327E04000004026F3F00000A2A000013300200FE000000070000110F00FE16080000016F1400000A6F4000000A0A150B160C160D16130438CD0000000813051105450600000005000000330000003F00000053000000760000008C00000038A00000000611049328110000063A92000000061104931F2D3307170C3883000000061104931F2F3304190C2B7711040B2B72061104931F2D336A180C2B66061104931F0D2E08061104931F0A3356160C2B52061104931F2A33081A0C0917580D2B42091631041A0C2B3A7200020070731F00000A7A061104931F2A33021B0C061104931F2F331D190C2B19061104931F2F330F0917590D092D04160C2B061A0C2B021A0C1104175813041104068E692F0707163F25FFFFFF072A9202734100000A16721A02007003026F3300000A59283B00000A6F1400000A282E00000A2AD2026F3300000A209B000000312502161F4B6F4200000A721E02007002026F3300000A1F4B591F4B6F4200000A284300000A2A022A133003004500000008000011722A02007002FE16080000016F1400000A282E00000A0A03FE16080000016F1400000A6F3300000A16311806724802007003FE16080000016F1400000A284300000A0A062A000000133004009202000009000011026F4400000A0A734500000A0B066F4600000A6F4700000A0C0F01FE16080000016F1400000A723E0100706F4800000A2C47088D410000010D1613042B2A066F4600000A11046F4900000A13050911041105725E0200706F4A00000A6F1400000AA211041758130411040832D107096F4B00000A380C0200000F0128170000061306734C00000A13071106130C16130D2B2E110C110D9A130811086F3300000A2C18110711087274020070727A0200706F2D00000A6F4D00000A110D1758130D110D110C8E6932CA0711076F4E00000A6F4B00000A38AB010000088D41000001130916130A388601000002110A6F4F00000A2C0F1109110A727E020070A23867010000066F4600000A110A6F4900000A728C0200706F4A00000AA549000001130B110B130E110E1F0F3024110E1A59450400000078000000BC000000DA00000000010000110E1F0F2E563809010000110E1F13594503000000DF000000F3000000DF000000110E1F1F59450400000005000000D9000000590000006D00000038D40000001109110A02110A6F5000000A285100000A2819000006A238CA0000001109110A02110A6F5000000A285100000A281B000006A238AE0000001109110A02110A6F5000000A285100000A281A000006A238920000001109110A02110A6F5000000A281C000006A22B7E1109110A02110A6F5200000A281D000006A22B6A1109110A02110A6F5300000A130F120FFE164A0000016F1400000AA22B4C1109110A02110A6F5400000A13101210285500000A1311121172A6020070285600000AA22B261109110A02110A6F5700000A281E000006A22B121109110A02110A6F5800000A6F1400000AA2110A1758130A110A026F5900000A3F6DFEFFFF0711096F4B00000A026F5A00000A3A4AFEFFFF072A000013300300280000000A00001172D002007002FE16080000016F1400000A72D6020070284300000A72DC020070285B00000A0A062A820272E8020070723E0100706F2D00000A727A020070723E0100706F2D00000A2A5E72EC0200700F00285C00000A8C11000001285D00000A2A5E720A0300700F00285C00000A8C11000001285D00000A2A5E72420300700F00285C00000A8C11000001285D00000A2A72726C0300700F00285E00000A735F00000A8C11000001285D00000A2A4672AC030070028C12000001285D00000A2A13300300440000000B000011734100000A72F4030070283900000A0A0F00286000000A0C160D2B1B0809910B06120172FA030070286100000A6F3900000A260917580D09088E6932DF066F1400000A2A2E7200040070731F00000A7A2E7200040070731F00000A7A2E7200040070731F00000A7A2E7200040070731F00000A7A1A736200000A7A1A736200000A7A000013300300430000000C000011736300000A0A061F20176F6400000A061F0A176F6400000A061F0D176F6400000A061F09176F6400000A061F0C176F6400000A061F0B176F6400000A0680040000042A1E02281E00000A2A220203281F00000A2A26020304282000000A2A26020304282100000A2A3A02281C00000A02037D0C0000042A001B300300340000000D0000110203282C0000060A0204282C0000060B027B0C00000406076F49000006DE140C027B0C000004086F6500000A6F4A000006DE002A01100000000000001F1F0014070000021B300200370000000E000011140A027B0C000004036F470000060A066F5A00000A260306282E0000060B0307282F0000060728300000060CDE0706282D000006DC082A0001100000020002002C2E0007000000002A022C06026F2200000A2A001B3003002F0000000F000011036F4400000A0BDE240A72740400700F00FE16080000016F1400000A7290040070284300000A0673280000067A072A00011000000000000009090024020000019A032D2272740400700F00FE16080000016F1400000A72D8040070284300000A73270000067A2A001B3004000F01000010000011723E0100700A026F4600000A6F6600000A0D38D5000000096F6700000A741B0000010B0772140500706F4A00000A6F1400000A7226050070286800000A39AA0000000672E8020070282E00000A0A026F6900000A6F6600000A13042B6311046F6700000A74160000010C0828310000062C4E0613051C8D0100000113061106161105A21106177230050070A2110618086F6A00000AA21106197234050070A211061A07086F6A00000A6F4A00000AA211061B7238050070A21106286B00000A0A11046F6C00000A2D94DE1511047507000001130711072C0711076F1700000ADC06727A020070282E00000A0A096F6C00000A3A20FFFFFFDE14097507000001130811082C0711086F1700000ADC062A00011C000002005B0070CB00150000000002001200E7F9001400000000AA026F6A00000A723C0500701B6F6D00000A2D15026F6A00000A72420500701B6F6D00000A16FE012A162A3A02281C00000A02037D0D0000042A000013300300A50000001100001102032834000006027B0D000004046F470000060A160B066F5900000A1631270717580B07286E00000A03286F00000A287000000A2C080628350000062B08066F7100000A2DD9066F2200000A07286E00000A03287200000A287000000A2C451B8D410000010C0816724C050070A208171201287300000AA20818727E050070A208190F01FE16170000016F1400000AA2081A72B0050070A208287400000A73270000067A2A000000033003004F000000000000000316286E00000A287200000A25287000000A2D110F01287500000A287600000A287700000A287000000A2C2272D40500700F01FE16170000016F1400000A7232060070284300000A73270000067A2A001330020029000000120000110228380000060A287800000A06737900000A6F7A00000A02062836000006287800000A6F7B00000A2A722B11287800000A020328370000066F7C00000A026F5A00000A2DE72A000013300200250000001300001103737900000A0A026F5900000A8D010000010B02076F7D00000A2606076F7E00000A26062A0000001B3003005800000014000011026F4400000A0A0628390000060B076F7F00000A8D180000010C160D076F8000000A13052B171205288100000A130408091104283A000006A20917580D1205288200000A2DE0DE0E1205FE160600001B6F1700000ADC082A01100000020024002448000E000000001B3002006600000015000011738300000A0A026F4600000A6F6600000A0C2B35086F6700000A741B0000010B0772140500706F4A00000A6F1400000A6F8400000A724E060070286800000A2C0806076F8500000A26086F6C00000A2DC3DE110875070000010D092C06096F1700000ADC062A000001100000020012004153001100000000133005006F0100001600001102728C0200706F4A00000AA5490000010A02725E0200706F4A00000A74410000010B0272580600706F4A00000A74570000010C06130411044523000000050000000D000000050000000D000000050000004B000000050000000500000005000000050000000D0000000500000026000000050000000500000005000000050000000500000005000000050000000500000026000000260000000500000086000000050000008600000086000000860000007D0000008600000005000000050000004B0000004B00000038810000000706738600000A2A070602726A0600706F4A00000AA5420000016A738700000A2A02726A0600706F4A00000AA5420000010D0920FF7F00003102150D0706096A738700000A2A07060272800600706F4A00000A288800000A288900000A0272A20600706F4A00000A288800000A288900000A738A00000A2A070608738B00000A2A72BC060070068C490000016F1400000A72D2060070284300000A738C00000A7A001330030014000000170000117340000006732A0000060A0602036F2B0000062A133003001400000018000011734000000673320000060A0602036F330000062A133002000E0000001900001173030000060A06026F010000062A000013300200130000001A000011734000000673080000060A06026F090000062A0013300200130000001A000011734000000673080000060A06026F0A0000062A3602281C00000A0228430000062A72027B100000042D0D02284400000602177D1000000402288D00000A2A1E027B0F0000042A9E02738E00000A7D0E000004027B0E000004721A0700706F8F00000A027B0E0000046F1100000A2A32027B0E0000046F9000000A2A0013300200280000001B00001102724C070070282800000A28470000060A066F5A00000A2606166F9100000A0B066F2200000A072A32027B0E0000046F9200000A2A00000013300300510000001C000011027E9300000A7D0F000004027B0E00000402FE0648000006739400000A6F9500000A731200000A0A06027B0E0000046F1300000A060F01FE16080000016F1400000A6F1500000A061A6F9600000A0B072A000000033004004400000000000000027C0F000004282F00000A2C1002723E010070282800000A7D0F00000402257B0F000004046F9700000A7296070070282E00000A282800000A289800000A7D0F0000042A13300300500000001D000011731200000A0A06027B0E0000046F1300000A06729C0700706F1500000A066F9900000A72CE070070036F9A00000A26066F9900000A72E0070070046F9A00000A26061A6F9B00000A066F1600000A262A133003003E0000001D000011731200000A0A06027B0E0000046F1300000A0672EE0700706F1500000A066F9900000A7204080070036F9A00000A26061A6F9B00000A066F1600000A262A000013300300430000001D000011731200000A0A06027B0E0000046F1300000A0672160800706F1500000A066F9900000A7246080070038C080000016F9A00000A26061A6F9B00000A066F1600000A262A0042534A4201000100000000000C00000076322E302E35303732370000000005006C000000D40E0000237E0000400F00002812000023537472696E677300000000682100005008000023555300B8290000100000002347554944000000C82900008C07000023426C6F620000000000000002000001579FA2090902000000FA25330016000001000000620000000B000000100000004B0000004C000000030000009B0000000800000010000000010000001D0000000200000005000000050000000600000001000000040000000100000000000A000100000000000600F100EA000600F800EA0006000201EA000A002D0118010A005201370106006301EA0006006801EA000A00740118010600D101B4010600E301B4010A005F0218010A008B0218010600E302C80206004703C8020A0064034E030A00A20318010600E803EA0006000604EA0006006E0464040600800464040A003D050C010A008F050C010A00C50518010A001D0637010A003E0637010E008506C8020A0092060C010A00E5064E030A006D074E0306006E095C09060085095C090600A2095C090600C1095C090600DA095C090600F3095C0906000E0A5C090600460A270A06005A0AEA000600700A5C090600890A5C090600B70AA40AA700CB0A00000600FA0ADA0A06001A0BDA0A12004C0B380B12005D0B380B0A00870B740B0A00990B4E030A00B30B740B0600F30BE30B0A00050C4E030A00200C740B0600430CEA000600600CEA000A00760C740B0A00830C37010A009F0C37010600A60C270A0600BC0C270A0600C70C5C090600E50C5C090600FA0CEA000A002C0D370106003F0DEA0006004C0DEA0006006B0DEA003B00710D00000600A10DEA000600C30DB70D0E00090EEA0D0A00400E0C010A005B0E0C010A009C0E0C010A00C40E18010A00DD0E18010600FE0EEA0006003A0FEA0006003F0FEA0006007D0F6A0F0A00970F0C010600C70FEA000A00E30F18010A00261037010A00311037016B00710D00000E009010C8020600A910EA000600C310AE100600E410EA000600EC10EA0006000311EA0006001511EA000E0054113E110A0075114E030A00A0110C010A00CA114E030A00F0114E030A000A120C01000000000100000000000100010000001000170027000500010001000120100030002700090001000400000010004900270005000100080009011000560027000D0002000C000301000063000000190005002600012010007A00270009000C002600000010009400270005000C002A0000001000AD00270005000D00320081011000BD00270005000E003B0000001000CE00270005000E0040000100F4012C0051803D0236005180490246003100F0026A0006069F0446005680A704E8005680AF04E8005680BE04E8005680CE04E8005680D904E8005680E804E8000100F4012C000100F4012C000100F3068C010100FE06900101000A079401D0200000000086007E010A0001007421000000009100860110000200CE21000000008618AE0114000200D621000000008618AE0114000200DE21000000008618AE0118000200E721000000008618AE011D000300F121000000008418AE0124000500FB21000000008618AE01300007000A2200000000830007020A00080029220000000083001F020A00090034220000000083002E020A000A0054220000000096005A024E000B006F22000000009600690253000B00882200000000960074024E000B00C822000000009600940258000B001C25000000009600A20263000E006125000000009100FB0272000F0070250000000091000C03770010007A260000000091001D037D0011009F26000000009100270383001300D4260000000091003703880014002827000000009100720392001600C82900000000910086039F001800FC290000000091009A03830019001D2A000000009100AE03A7001A00352A000000009100BE03A7001B004D2A000000009100D203A7001C00652A000000009100F103AD001D00822A0000000091001504B3001E00942A0000000091002F04B9001F00E42A0000000096084104BF002000F02A00000000E6094A04C4002000FC2A0000000096005504C8002000082B00000000C6005B04CF002100142B00000000E6017B04D30021001B2B00000000E6018D04D9002200242B000000009118570F15052300732B000000008618AE01140023007B2B000000008618AE0118002300842B000000008618AE011D0024008E2B000000008418AE0124002600982B000000008618AE0130002800A82B000000008600F2040A012900F82B000000008100130512012B004C2C000000009100310518012C00582C00000000910047051E012D00A42C0000000091005F0527012F00CC2C0000000091007D052F013100042E0000000091009A05350132002F2E000000008618AE0130003300402E000000008600CE053B013400F42E000000008100F00543013600502F000000009100080618013700852F000000009100290649013800A42F0000000091004C0652013A00D82F0000000091006A065C013C004C300000000091009A0664013D00D030000000009100AE066F013E004C32000000009600F20476013F006C32000000009600AD007E0141008C32000000009600C90686014300A832000000009600D70686014400C8320000000096001F0286014500E732000000008618AE0114004600F53200000000E60113071400460012330000000086081B07970146001A330000000081002B0714004600423300000000810033071400460050330000000086083E07CF00460084330000000086084D07CF00460094330000000086005E079C014600F4330000000084008507A301470044340000000086009307AA014900A034000000008600A00718004B00EC34000000008600BE070A004C0000000100F40700000100FC0700000100FC0700000200040800000100130800000200180800000100F40100000100F40700000100F40700000100F407000001002008000002002A08000003003608000001004108000001005108000001004108000001005308000002005908000001006008000001002008000002002A08000001006808000002006F08000001003608000001008C08000001009708000001009708000001009708000001009708000001009F0800000100A80800000100530800000100B20800000100B40800000100FC0700000100FC0700000200040800000100130800000200180800000100F40100000100B60800000200C60800000100F40700000100680800000100F40700000200680800000100F40700000200D40800000100D40800000100DB0800000100F40100000100E20800000200F40700000100E20800000100EE0800000100EE0800000200F90800000100EE0800000200F90800000100EE0800000100D40800000100FE0800000100B60800000200C608000001000C0900000200F40700000100F40700000100F40700000100F407000001001809000001002009000002002709000001002C09000002003B0900000100480900000100570905001100050015000B001D00F100AE011800F900AE0118000101AE0118000901AE0118001101AE0118001901AE0118002101AE0118002901AE01B9013101AE01B9013901AE0118004101AE0118004901AE01BE015901AE01C5016101AE0114006901AE016C02E100AE0118007901940B14008101AE0114008101A40B730209005B04CF008901BD0B18008901CD0B79023900130714007901DD0B14009901AE011400A1013A0C8C02A1014B0CCF000900AE011400B101AE0114001100AE0114001100AE0118001100AE011D001100AE012400B901DD0B1400C101AE01A202D101AE01D502E101D00CDC02E101F20CE202E901020DE80241000E0DEE02E9011A0DF40259000E0DF902F901AE0114000102440D91030902530D970309025B0D9D0341004A04C4000C00620DB0030C007C0DB60314008A0DC8030902960D79022102A60DCD031400AA0DC4002102B30DCD032902AE01C5012902D10DD3032902DC0DD9032902960D79022902E30DE0036100AE010A003102AE0118003102530D19041C000F0E300409021B0E36042902AE0114000902270E470409025B0D4D04B901310E58040C00AE011400A900520E5D044102760E79020902800E63043902620D6804D900620D6E040C00870E73042400AE0114002400870E730424008B0E7F04B901930E8504B901A60E8A0481000E0D90047900B20E97047900CF0E9D047900E70EA4045902F40EAB0461025B04AF047900050FB404B901120FBA04B9011B0F7902B9017B04C40031022A0FEB048100F40EF70409029F0CFC048900300F02058900AE0106055900F40EF40269025B04AF047102AE0114001C00AE0114001C00870E190511005E0FCF0041027C0D400579028A0D46050902890F4A05A900AC0F5005B100B80FCF0009025B0D56057902AA0DC4000902D80F7105B9000E0D7905B900EE0F7F059102FA0F8905B9010210C400B9000D107F0511025B04CF0009025B0D9005B9004A04C40091020E0D9E0591021910A50599023910B105C900AE01B705A1024210BE05A10253101400A1026210BE0579007110CA05C9007E10CA052C00760E79022C007C0DDE0534008A0DC8033400AA0DC4002C00AE01140009028810CF002C00A1100806C100AE012406C100AE012C06C102CF103506C902FC103B06C100AE014306C100AE014D06D902AE011800E10218117A06E100AE011400790129111800E90213071400B9015E117F0679016811CF00410093049001F102AE018A06E100901190068101B0119706E9005E0FCF004100BE11A7068101E111B0060103FD11B60689011612BE060E000800390008000C00490008001800EC0008001C00F10008002000F60008002400FB0008002800000108002C0005012E0023000E072E002B001E072E0073006B072E000B00CB062E001300D9062E001B0008072E004B0029072E006B0062072E00430008072E00330008072E005B002F072E0063005907A3001B01A902C0015B010003E0015B01000300025B01000300000100000005007D0292029D02A303E90321043B045404BF04F2040B0521052A05310539055C059605C405D005F0051406580666066B067006750684069F06C506050001000B00030000009304DF0000009804E4000000D007B0010000DC07B5010000E707B50102001F000300020020000500020042000700020045000900020046000B00A903C00329047904D705E8050480000001000000F116016B01000000CA01270000000200000000000000000000000100E1000000000002000000000000000000000001000C01000000000200000000000000000000000100EA00000000000200000000000000000000000100380B000000000600050000000000003C4D6F64756C653E007453514C74434C522E646C6C00436F6D6D616E644578656375746F72007453514C74434C5200436F6D6D616E644578656375746F72457863657074696F6E004F7574707574436170746F72007453514C7450726976617465004765745374617274506F736974696F6E53746174657300496E76616C6964526573756C74536574457863657074696F6E004D65746144617461457175616C697479417373657274657200526573756C7453657446696C7465720053746F72656450726F6365647572657300546573744461746162617365466163616465006D73636F726C69620053797374656D004F626A65637400457863657074696F6E0056616C7565547970650053797374656D2E446174610053797374656D2E446174612E53716C547970657300494E756C6C61626C65004D6963726F736F66742E53716C5365727665722E536572766572004942696E61727953657269616C697A6500456E756D0049446973706F7361626C650053716C537472696E67004578656375746500437265617465436F6E6E656374696F6E537472696E67546F436F6E746578744461746162617365002E63746F720053797374656D2E52756E74696D652E53657269616C697A6174696F6E0053657269616C697A6174696F6E496E666F0053747265616D696E67436F6E746578740074657374446174616261736546616361646500436170747572654F7574707574546F4C6F675461626C650053757070726573734F75747075740045786563757465436F6D6D616E64004E554C4C5F535452494E47004D41585F434F4C554D4E5F574944544800496E666F0053716C42696E617279005369676E696E674B657900437265617465556E697175654F626A6563744E616D650053716C4368617273005461626C65546F537472696E6700476574416C74657253746174656D656E74576974686F7574536368656D6142696E64696E670053797374656D2E436F6C6C656374696F6E732E47656E657269630044696374696F6E617279603200576869746573706163650049735768697465737061636543686172004765745374617274506F736974696F6E00506164436F6C756D6E005472696D546F4D61784C656E6774680067657453716C53746174656D656E74004C69737460310053797374656D2E446174612E53716C436C69656E740053716C44617461526561646572006765745461626C65537472696E6741727261790053706C6974436F6C756D6E4E616D654C69737400756E71756F74650053716C4461746554696D650053716C44617465546F537472696E670053716C4461746554696D65546F537472696E6700536D616C6C4461746554696D65546F537472696E67004461746554696D650053716C4461746554696D6532546F537472696E67004461746554696D654F66667365740053716C4461746554696D654F6666736574546F537472696E670053716C42696E617279546F537472696E67006765745F4E756C6C006765745F49734E756C6C00506172736500546F537472696E670053797374656D2E494F0042696E61727952656164657200526561640042696E617279577269746572005772697465004E756C6C0049734E756C6C0076616C75655F5F0044656661756C740041667465724669727374446173680041667465725365636F6E6444617368004166746572536C617368004166746572536C617368537461720041667465725374617200417373657274526573756C74536574734861766553616D654D6574614461746100637265617465536368656D61537472696E6746726F6D436F6D6D616E6400636C6F736552656164657200446174615461626C6500617474656D7074546F476574536368656D615461626C65007468726F77457863657074696F6E4966536368656D614973456D707479006275696C64536368656D61537472696E670044617461436F6C756D6E00636F6C756D6E50726F7065727479497356616C6964466F724D65746144617461436F6D70617269736F6E0053716C496E7433320073656E6453656C6563746564526573756C74536574546F53716C436F6E746578740076616C6964617465526573756C745365744E756D6265720073656E64526573756C747365745265636F7264730053716C4D657461446174610073656E64456163685265636F72644F66446174610053716C446174615265636F7264006372656174655265636F7264506F70756C617465645769746844617461006372656174654D65746144617461466F72526573756C74736574004C696E6B65644C69737460310044617461526F7700676574446973706C61796564436F6C756D6E730063726561746553716C4D65746144617461466F72436F6C756D6E004E6577436F6E6E656374696F6E00436170747572654F75747075740053716C436F6E6E656374696F6E00636F6E6E656374696F6E00696E666F4D65737361676500646973706F73656400446973706F7365006765745F496E666F4D65737361676500636F6E6E65637400646973636F6E6E656374006765745F5365727665724E616D65006765745F44617461626173654E616D650065786563757465436F6D6D616E640053716C496E666F4D6573736167654576656E7441726773004F6E496E666F4D65737361676500617373657274457175616C73006661696C5465737443617365416E645468726F77457863657074696F6E006C6F6743617074757265644F757470757400496E666F4D657373616765005365727665724E616D650044617461626173654E616D6500636F6D6D616E64006D65737361676500696E6E6572457863657074696F6E00696E666F00636F6E74657874005461626C654E616D65004F726465724F7074696F6E00436F6C756D6E4C6973740063726561746553746174656D656E74006300696E707574006C656E67746800726F774461746100726561646572005072696E744F6E6C79436F6C756D6E4E616D65416C6961734C69737400636F6C756D6E4E616D6500647456616C75650064746F56616C75650073716C42696E61727900720077006578706563746564436F6D6D616E640061637475616C436F6D6D616E6400736368656D6100636F6C756D6E00726573756C747365744E6F0064617461526561646572006D65746100636F6C756D6E44657461696C7300726573756C745365744E6F00436F6D6D616E640073656E6465720061726773006578706563746564537472696E670061637475616C537472696E67006661696C7572654D65737361676500746578740053797374656D2E5265666C656374696F6E00417373656D626C795469746C6541747472696275746500417373656D626C794465736372697074696F6E41747472696275746500417373656D626C79436F6E66696775726174696F6E41747472696275746500417373656D626C79436F6D70616E7941747472696275746500417373656D626C7950726F6475637441747472696275746500417373656D626C7954726164656D61726B41747472696275746500417373656D626C7943756C747572654174747269627574650053797374656D2E52756E74696D652E496E7465726F70536572766963657300436F6D56697369626C6541747472696275746500434C53436F6D706C69616E7441747472696275746500417373656D626C7956657273696F6E41747472696275746500417373656D626C79436F707972696768744174747269627574650053797374656D2E446961676E6F73746963730044656275676761626C6541747472696275746500446562756767696E674D6F6465730053797374656D2E52756E74696D652E436F6D70696C6572536572766963657300436F6D70696C6174696F6E52656C61786174696F6E734174747269627574650052756E74696D65436F6D7061746962696C6974794174747269627574650053797374656D2E5472616E73616374696F6E73005472616E73616374696F6E53636F7065005472616E73616374696F6E53636F70654F7074696F6E0053797374656D2E446174612E436F6D6D6F6E004462436F6E6E656374696F6E004F70656E0053716C436F6D6D616E64007365745F436F6E6E656374696F6E004462436F6D6D616E64007365745F436F6D6D616E645465787400457865637574654E6F6E517565727900436C6F73650053797374656D2E5365637572697479005365637572697479457863657074696F6E0053716C436F6E6E656374696F6E537472696E674275696C646572004462436F6E6E656374696F6E537472696E674275696C646572007365745F4974656D00426F6F6C65616E006765745F436F6E6E656374696F6E537472696E670053657269616C697A61626C65417474726962757465004462446174615265616465720053716C55736572446566696E65645479706541747472696275746500466F726D6174005374727563744C61796F7574417474726962757465004C61796F75744B696E6400417373656D626C7900476574457865637574696E67417373656D626C7900417373656D626C794E616D65004765744E616D650056657273696F6E006765745F56657273696F6E006F705F496D706C69636974004765745075626C69634B6579546F6B656E0053716C4D6574686F644174747269627574650047756964004E65774775696400537472696E67005265706C61636500436F6E636174006765745F4974656D00496E74333200456E756D657261746F7200476574456E756D657261746F72006765745F43757272656E74006765745F4C656E677468004D617468004D6178004D6F76654E657874004D696E0053797374656D2E5465787400537472696E674275696C64657200417070656E644C696E6500417070656E6400496E736572740053797374656D2E546578742E526567756C617245787072657373696F6E7300526567657800436F6E7461696E734B657900546F43686172417272617900537562737472696E6700476574536368656D615461626C650044617461526F77436F6C6C656374696F6E006765745F526F777300496E7465726E616C44617461436F6C6C656374696F6E42617365006765745F436F756E7400457175616C730041646400546F417272617900497344424E756C6C0053716C446254797065004765744461746554696D65004765744461746554696D654F66667365740053716C446563696D616C0047657453716C446563696D616C0053716C446F75626C650047657453716C446F75626C65006765745F56616C756500446F75626C650047657453716C42696E6172790047657456616C7565006765745F4669656C64436F756E740053706C6974006765745F5469636B730042797465004E6F74496D706C656D656E746564457863657074696F6E002E6363746F72006765745F4D6573736167650053797374656D2E436F6C6C656374696F6E730049456E756D657261746F72006F705F496E657175616C6974790044617461436F6C756D6E436F6C6C656374696F6E006765745F436F6C756D6E73006765745F436F6C756D6E4E616D6500537472696E67436F6D70617269736F6E00537461727473576974680053716C426F6F6C65616E006F705F457175616C697479006F705F54727565004E657874526573756C74006F705F4C6573735468616E006F705F426974776973654F720053716C436F6E746578740053716C50697065006765745F506970650053656E64526573756C747353746172740053656E64526573756C7473456E640053656E64526573756C7473526F770047657453716C56616C7565730053657456616C75657300546F4C6F776572004C696E6B65644C6973744E6F64656031004164644C61737400547970650053797374656D2E476C6F62616C697A6174696F6E0043756C74757265496E666F006765745F496E76617269616E7443756C7475726500436F6E766572740049466F726D617450726F766964657200546F4279746500417267756D656E74457863657074696F6E00474300537570707265737346696E616C697A65007365745F436F6E6E656374696F6E537472696E670053797374656D2E436F6D706F6E656E744D6F64656C00436F6D706F6E656E7400476574537472696E67006765745F44617461626173650053716C496E666F4D6573736167654576656E7448616E646C6572006164645F496E666F4D65737361676500436F6D6D616E644265686176696F720045786563757465526561646572006F705F4164646974696F6E0053716C506172616D65746572436F6C6C656374696F6E006765745F506172616D65746572730053716C506172616D65746572004164645769746856616C756500436F6D6D616E6454797065007365745F436F6D6D616E64547970650000000080B34500720072006F007200200063006F006E006E0065006300740069006E006700200074006F002000640061007400610062006100730065002E00200059006F00750020006D006100790020006E00650065006400200074006F00200063007200650061007400650020007400530051004C007400200061007300730065006D0062006C007900200077006900740068002000450058005400450052004E0041004C005F004100430043004500530053002E0000174400610074006100200053006F007500720063006500002749006E0074006500670072006100740065006400200053006500630075007200690074007900001F49006E0069007400690061006C00200043006100740061006C006F00670000237400530051004C0074005F00740065006D0070006F0062006A006500630074005F0000032D00010100354F0062006A0065006300740020006E0061006D0065002000630061006E006E006F00740020006200650020004E0055004C004C0000037C0000032B0000634300520045004100540045005C0073002B00560049004500570028005C0073002A002E002A003F005C0073002A00290057004900540048005C0073002B0053004300480045004D004100420049004E00440049004E0047005C0073002B0041005300001D41004C00540045005200200056004900450057002400310041005300001975006E006500780070006500630074006500640020002F0000032000000B3C002E002E002E003E00001D530045004C0045004300540020002A002000460052004F004D002000001520004F0052004400450052002000420059002000001543006F006C0075006D006E004E0061006D00650000055D005D0000035D00000D21004E0055004C004C0021000019500072006F00760069006400650072005400790070006500002930002E0030003000300030003000300030003000300030003000300030003000300045002B00300000055D002C0000052C005B00000B5C005D002C005C005B0000035B00001D7B0030003A0079007900790079002D004D004D002D00640064007D0001377B0030003A0079007900790079002D004D004D002D00640064002000480048003A006D006D003A00730073002E006600660066007D0001297B0030003A0079007900790079002D004D004D002D00640064002000480048003A006D006D007D00013F7B0030003A0079007900790079002D004D004D002D00640064002000480048003A006D006D003A00730073002E0066006600660066006600660066007D0001477B0030003A0079007900790079002D004D004D002D00640064002000480048003A006D006D003A00730073002E00660066006600660066006600660020007A007A007A007D0001053000780000055800320000737400530051004C007400500072006900760061007400650020006900730020006E006F007400200069006E00740065006E00640065006400200074006F002000620065002000750073006500640020006F0075007400730069006400650020006F00660020007400530051004C0074002100001B540068006500200063006F006D006D0061006E00640020005B0000475D00200064006900640020006E006F0074002000720065007400750072006E00200061002000760061006C0069006400200072006500730075006C0074002000730065007400003B5D00200064006900640020006E006F0074002000720065007400750072006E0020006100200072006500730075006C0074002000730065007400001149007300480069006400640065006E000009540072007500650000037B0000033A0000037D0000054900730000094200610073006500003145007800650063007500740069006F006E002000720065007400750072006E006500640020006F006E006C00790020000031200052006500730075006C00740053006500740073002E00200052006500730075006C00740053006500740020005B0000235D00200064006F006500730020006E006F0074002000650078006900730074002E00005D52006500730075006C007400530065007400200069006E00640065007800200062006500670069006E007300200061007400200031002E00200052006500730075006C007400530065007400200069006E0064006500780020005B00001B5D00200069007300200069006E00760061006C00690064002E0000097400720075006500001144006100740061005400790070006500001543006F006C0075006D006E00530069007A00650000214E0075006D00650072006900630050007200650063006900730069006F006E0000194E0075006D0065007200690063005300630061006C006500001541007200670075006D0065006E00740020005B0000475D0020006900730020006E006F0074002000760061006C0069006400200066006F007200200052006500730075006C007400530065007400460069006C007400650072002E00003143006F006E007400650078007400200043006F006E006E0065006300740069006F006E003D0074007200750065003B000049530045004C004500430054002000530045005200560045005200500052004F0050004500520054005900280027005300650072007600650072004E0061006D006500270029003B0001050D000A0000317400530051004C0074002E0041007300730065007200740045007100750061006C00730053007400720069006E006700001145007800700065006300740065006400000D410063007400750061006C0000157400530051004C0074002E004600610069006C0000114D006500730073006100670065003000002F7400530051004C0074002E004C006F006700430061007000740075007200650064004F0075007400700075007400000974006500780074000005DE9AFB029CE74BA9DC99DAF9484EAD0008B77A5C561934E0890520010111210300000E03200001042001010E062002010E120907200201122511290306122C05200101122C02060E0C21004E0055004C004C002100020608049B0000000400001121040000112D0A0003123111211121112106000112311121070615123502030204000102030500010811210500020E0E080400010E0E0900020E1011211011210C0002151239011D0E123D11210700011D0E1011210500010E11410500010E11450500010E11490500010E112D040000111403200002060001111411210320000E05200101124D0520010112510408001114032800020306111804000000000401000000040200000004030000000404000000040500000007200201112111210520010E112105000101123D08000212551121123D07000201112112550500010E125505000102125907200201115D112105200101115D08000201123D1D12610900021265123D1D12610700011D1261123D0A000115126901126D12550600011261126D070002011121112107000201115D112105000101112103061271030611210206020420001121062001123D1121062002011C1275052002010E0E04280011210328000E0420010102062001011180A9042001010880A00024000004800000940000000602000000240000525341310004000001000100F7D9A45F2B508C2887A8794B053CE5DEB28743B7C748FF545F1F51218B684454B785054629C1417D1D3542B095D80BA171294948FCF978A502AA03240C024746B563BC29B4D8DCD6956593C0C425446021D699EF6FB4DC2155DE7E393150AD6617EDC01216EA93FCE5F8F7BE9FF605AD2B8344E8CC01BEDB924ED06FD368D1D0062001011180B9052001011271032000080E070512711280B50E1280C11280C9052002010E1C0A0705122C0E0E1280CD0E040701123D062001011180E52B010002000000020054080B4D61784279746553697A650100000054020D497346697865644C656E67746801062001011180ED0500001280F10520001280F50520001280F905000111210E0420001D05060001112D1D05808F010001005455794D6963726F736F66742E53716C5365727665722E5365727665722E446174614163636573734B696E642C2053797374656D2E446174612C2056657273696F6E3D322E302E302E302C2043756C747572653D6E65757472616C2C205075626C69634B6579546F6B656E3D623737613563353631393334653038390A44617461416363657373010000000500001181010520020E0E0E0500020E0E0E05070111810106151239011D0E0520011300080920001511810D011300071511810D011D0E04200013000500020808080520001281150620011281150E082003128115080E082F0714122C0E123D151239011D0E081D081D0E08080808021281151D0E08081511810D011D0E1D08081511810D011D0E0720040E0E0E0808070703081281190E061512350203020520010213000420001D030B07061D03081118080811180520020E08080600030E0E0E0E0307010E042000125505200012811D042001020E052001126D080420011C0E05200101130005151239010E0520001D13000420010208052001114508060001114111450520011149080620011181290806200111812D080320000D0420010E0E052001112D080420011C082B07121255151239011D0E081D0E08126D1D0E151239010E0E1D0E081181251D0E0811812511812911812D0D0600021D0E0E0E0407011D0E04200011450500020E0E1C0320000A042001010A090704128115051D05080300000107200201130013010807011512350203020607030E0E121C070703123D12550E0607021209125505200012813D0320001C050002020E0E0520001281410500010E1D1C1407090E126D125912813D12813D1C1D1C121D121D072002020E118145050001115D08090002118149115D115D060001021181490500010E1D0E070703123D081D0E060001118149020B0002118149118149118149050000128151062001011D12610520010112650507011D1261052001081D1C06070212651D1C0615126901126D09200015118155011300071511815501126D170706125515126901126D1D126108126D1511815501126D0B20011512815901130013000F070415126901126D126D12813D121D072002010E118125082003010E1181250A050000128161070002051C128169092004010E11812505050A2003010E11812512815D0D07051181250E12815D081181250407011220040701122404070112080407011210040001011C0420010E08050702123D0E052002011C1806200101128179072001123D11817D0707021280C1123D0800021121112111210520001281810720021281850E1C062001011181890507011280C10D0100087453514C74434C5200002E010029434C527320666F7220746865207453514C7420756E69742074657374696E67206672616D65776F726B00000501000000000F01000A73716C6974792E6E657400000A0100057453514C74000005010001000029010024436F7079726967687420C2A9202073716C6974792E6E65742032303130202D203230313500000801000200000000000801000800000000001E01000100540216577261704E6F6E457863657074696F6E5468726F7773010000000000005219AD5600000000020000001C010000AC660000AC48000052534453683BAB7F3D6D534A9E23408F5CA7F1A701000000633A5C5465616D436974795C6275696C644167656E745C776F726B5C666264353737636331386432383966385C7453514C74434C525C7453514C74434C525C6F626A5C437275697365436F6E74726F6C5C7453514C74434C522E7064620000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000F067000000000000000000000E6800000020000000000000000000000000000000000000000000000068000000000000000000000000000000005F436F72446C6C4D61696E006D73636F7265652E646C6C0000000000FF2500200010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100100000001800008000000000000000000000000000000100010000003000008000000000000000000000000000000100000000004800000058800000A00300000000000000000000A00334000000560053005F00560045005200530049004F004E005F0049004E0046004F0000000000BD04EFFE0000010000000100016BF11600000100016BF1163F000000000000000400000002000000000000000000000000000000440000000100560061007200460069006C00650049006E0066006F00000000002400040000005400720061006E0073006C006100740069006F006E00000000000000B00400030000010053007400720069006E006700460069006C00650049006E0066006F000000DC02000001003000300030003000300034006200300000006C002A00010043006F006D006D0065006E0074007300000043004C0052007300200066006F007200200074006800650020007400530051004C007400200075006E00690074002000740065007300740069006E00670020006600720061006D00650077006F0072006B00000038000B00010043006F006D00700061006E0079004E0061006D00650000000000730071006C006900740079002E006E0065007400000000003C0009000100460069006C0065004400650073006300720069007000740069006F006E00000000007400530051004C00740043004C0052000000000040000F000100460069006C006500560065007200730069006F006E000000000031002E0030002E0035003800370033002E0032003700330039003300000000003C000D00010049006E007400650072006E0061006C004E0061006D00650000007400530051004C00740043004C0052002E0064006C006C00000000006C00240001004C006500670061006C0043006F007000790072006900670068007400000043006F0070007900720069006700680074002000A90020002000730071006C006900740079002E006E00650074002000320030003100300020002D0020003200300031003500000044000D0001004F0072006900670069006E0061006C00460069006C0065006E0061006D00650000007400530051004C00740043004C0052002E0064006C006C00000000002C0006000100500072006F0064007500630074004E0061006D006500000000007400530051004C007400000044000F000100500072006F006400750063007400560065007200730069006F006E00000031002E0030002E0035003800370033002E00320037003300390033000000000048000F00010041007300730065006D0062006C0079002000560065007200730069006F006E00000031002E0030002E0035003800370033002E0032003700330039003300000000000000000000000000006000000C000000203800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000 WITH PERMISSION_SET = SAFE;
GO



GO

GO

CREATE PROCEDURE tSQLt.ResultSetFilter @ResultsetNo INT, @Command NVARCHAR(MAX)
AS
EXTERNAL NAME tSQLtCLR.[tSQLtCLR.StoredProcedures].ResultSetFilter;
GO

CREATE PROCEDURE tSQLt.AssertResultSetsHaveSameMetaData @expectedCommand NVARCHAR(MAX), @actualCommand NVARCHAR(MAX)
AS
EXTERNAL NAME tSQLtCLR.[tSQLtCLR.StoredProcedures].AssertResultSetsHaveSameMetaData;
GO

CREATE TYPE tSQLt.[Private] EXTERNAL NAME tSQLtCLR.[tSQLtCLR.tSQLtPrivate];
GO

CREATE PROCEDURE tSQLt.NewConnection @command NVARCHAR(MAX)
AS
EXTERNAL NAME tSQLtCLR.[tSQLtCLR.StoredProcedures].NewConnection;
GO

CREATE PROCEDURE tSQLt.CaptureOutput @command NVARCHAR(MAX)
AS
EXTERNAL NAME tSQLtCLR.[tSQLtCLR.StoredProcedures].CaptureOutput;
GO

CREATE PROCEDURE tSQLt.SuppressOutput @command NVARCHAR(MAX)
AS
EXTERNAL NAME tSQLtCLR.[tSQLtCLR.StoredProcedures].SuppressOutput;
GO



GO

GO
CREATE PROCEDURE tSQLt.TableToText
    @txt NVARCHAR(MAX) OUTPUT,
    @TableName NVARCHAR(MAX),
    @OrderBy NVARCHAR(MAX) = NULL,
    @PrintOnlyColumnNameAliasList NVARCHAR(MAX) = NULL
AS
BEGIN
    SET @txt = tSQLt.Private::TableToString(@TableName, @OrderBy, @PrintOnlyColumnNameAliasList);
END;
GO


GO

CREATE TABLE tSQLt.Private_RenamedObjectLog (
  Id INT IDENTITY(1,1) CONSTRAINT PK__Private_RenamedObjectLog__Id PRIMARY KEY CLUSTERED,
  ObjectId INT NOT NULL,
  OriginalName NVARCHAR(MAX) NOT NULL
);


GO

CREATE PROCEDURE tSQLt.Private_MarkObjectBeforeRename
    @SchemaName NVARCHAR(MAX), 
    @OriginalName NVARCHAR(MAX)
AS
BEGIN
  INSERT INTO tSQLt.Private_RenamedObjectLog (ObjectId, OriginalName) 
  VALUES (OBJECT_ID(@SchemaName + '.' + @OriginalName), @OriginalName);
END;


GO

CREATE PROCEDURE tSQLt.Private_RenameObjectToUniqueName
    @SchemaName NVARCHAR(MAX),
    @ObjectName NVARCHAR(MAX),
    @NewName NVARCHAR(MAX) = NULL OUTPUT
AS
BEGIN
   SET @NewName=tSQLt.Private::CreateUniqueObjectName();

   DECLARE @RenameCmd NVARCHAR(MAX);
   SET @RenameCmd = 'EXEC sp_rename ''' + 
                          @SchemaName + '.' + @ObjectName + ''', ''' + 
                          @NewName + ''';';
   
   EXEC tSQLt.Private_MarkObjectBeforeRename @SchemaName, @ObjectName;


   EXEC tSQLt.SuppressOutput @RenameCmd;

END;


GO

CREATE PROCEDURE tSQLt.Private_RenameObjectToUniqueNameUsingObjectId
    @ObjectId INT,
    @NewName NVARCHAR(MAX) = NULL OUTPUT
AS
BEGIN
   DECLARE @SchemaName NVARCHAR(MAX);
   DECLARE @ObjectName NVARCHAR(MAX);
   
   SELECT @SchemaName = QUOTENAME(OBJECT_SCHEMA_NAME(@ObjectId)), @ObjectName = QUOTENAME(OBJECT_NAME(@ObjectId));
   
   EXEC tSQLt.Private_RenameObjectToUniqueName @SchemaName,@ObjectName, @NewName OUTPUT;
END;


GO

GO
CREATE PROCEDURE tSQLt.RemoveObject 
    @ObjectName NVARCHAR(MAX),
    @NewName NVARCHAR(MAX) = NULL OUTPUT,
    @IfExists INT = 0
AS
BEGIN
  DECLARE @ObjectId INT;
  SELECT @ObjectId = OBJECT_ID(@ObjectName);
  
  IF(@ObjectId IS NULL)
  BEGIN
    IF(@IfExists = 1) RETURN;
    RAISERROR('%s does not exist!',16,10,@ObjectName);
  END;

  EXEC tSQLt.Private_RenameObjectToUniqueNameUsingObjectId @ObjectId, @NewName = @NewName OUTPUT;
END;
GO


GO

GO
CREATE PROCEDURE tSQLt.RemoveObjectIfExists 
    @ObjectName NVARCHAR(MAX),
    @NewName NVARCHAR(MAX) = NULL OUTPUT
AS
BEGIN
  EXEC tSQLt.RemoveObject @ObjectName = @ObjectName, @NewName = @NewName OUT, @IfExists = 1;
END;
GO


GO

GO
CREATE PROCEDURE tSQLt.Private_CleanTestResult
AS
BEGIN
   DELETE FROM tSQLt.TestResult;
END;
GO


GO

GO
CREATE PROCEDURE tSQLt.Private_Init
AS
BEGIN
  EXEC tSQLt.Private_CleanTestResult;

  DECLARE @enable BIT; SET @enable = 1;
  DECLARE @version_match BIT;SET @version_match = 0;
  BEGIN TRY
    EXEC sys.sp_executesql N'SELECT @r = CASE WHEN I.Version = I.ClrVersion THEN 1 ELSE 0 END FROM tSQLt.Info() AS I;',N'@r BIT OUTPUT',@version_match OUT;
  END TRY
  BEGIN CATCH
    RAISERROR('Cannot access CLR. Assembly might be in an invalid state. Try running EXEC tSQLt.EnableExternalAccess @enable = 0; or reinstalling tSQLt.',16,10);
    RETURN;
  END CATCH;
  IF(@version_match = 0)
  BEGIN
    RAISERROR('tSQLt is in an invalid state. Please reinstall tSQLt.',16,10);
    RETURN;
  END;

  IF((SELECT SqlEdition FROM tSQLt.Info()) <> 'SQL Azure')
  BEGIN
    EXEC tSQLt.EnableExternalAccess @enable = @enable, @try = 1;
  END;
END;
GO


GO


CREATE PROCEDURE tSQLt.Private_GetSetupProcedureName
  @TestClassId INT = NULL,
  @SetupProcName NVARCHAR(MAX) OUTPUT
AS
BEGIN
    SELECT @SetupProcName = tSQLt.Private_GetQuotedFullName(object_id)
      FROM sys.procedures
     WHERE schema_id = @TestClassId
       AND LOWER(name) = 'setup';
END;
GO

CREATE PROCEDURE tSQLt.Private_RunTest
   @TestName NVARCHAR(MAX),
   @SetUp NVARCHAR(MAX) = NULL
AS
BEGIN
    DECLARE @Msg NVARCHAR(MAX); SET @Msg = '';
    DECLARE @Msg2 NVARCHAR(MAX); SET @Msg2 = '';
    DECLARE @Cmd NVARCHAR(MAX); SET @Cmd = '';
    DECLARE @TestClassName NVARCHAR(MAX); SET @TestClassName = '';
    DECLARE @TestProcName NVARCHAR(MAX); SET @TestProcName = '';
    DECLARE @Result NVARCHAR(MAX); SET @Result = 'Success';
    DECLARE @TranName CHAR(32); EXEC tSQLt.GetNewTranName @TranName OUT;
    DECLARE @TestResultId INT;
    DECLARE @PreExecTrancount INT;

    DECLARE @VerboseMsg NVARCHAR(MAX);
    DECLARE @Verbose BIT;
    SET @Verbose = ISNULL((SELECT CAST(Value AS BIT) FROM tSQLt.Private_GetConfiguration('Verbose')),0);
    
    TRUNCATE TABLE tSQLt.CaptureOutputLog;
    CREATE TABLE #ExpectException(ExpectException INT,ExpectedMessage NVARCHAR(MAX), ExpectedSeverity INT, ExpectedState INT, ExpectedMessagePattern NVARCHAR(MAX), ExpectedErrorNumber INT, FailMessage NVARCHAR(MAX));

    IF EXISTS (SELECT 1 FROM sys.extended_properties WHERE name = N'SetFakeViewOnTrigger')
    BEGIN
      RAISERROR('Test system is in an invalid state. SetFakeViewOff must be called if SetFakeViewOn was called. Call SetFakeViewOff after creating all test case procedures.', 16, 10) WITH NOWAIT;
      RETURN -1;
    END;

    SELECT @Cmd = 'EXEC ' + @TestName;
    
    SELECT @TestClassName = OBJECT_SCHEMA_NAME(OBJECT_ID(@TestName)), --tSQLt.Private_GetCleanSchemaName('', @TestName),
           @TestProcName = tSQLt.Private_GetCleanObjectName(@TestName);
           
    INSERT INTO tSQLt.TestResult(Class, TestCase, TranName, Result) 
        SELECT @TestClassName, @TestProcName, @TranName, 'A severe error happened during test execution. Test did not finish.'
        OPTION(MAXDOP 1);
    SELECT @TestResultId = SCOPE_IDENTITY();

    IF(@Verbose = 1)
    BEGIN
      SET @VerboseMsg = 'tSQLt.Run '''+@TestName+'''; --Starting';
      EXEC tSQLt.Private_Print @Message =@VerboseMsg, @Severity = 0;
    END;

    BEGIN TRAN;
    SAVE TRAN @TranName;

    SET @PreExecTrancount = @@TRANCOUNT;
    
    TRUNCATE TABLE tSQLt.TestMessage;

    DECLARE @TmpMsg NVARCHAR(MAX);
    DECLARE @TestEndTime DATETIME; SET @TestEndTime = NULL;
    BEGIN TRY
        IF (@SetUp IS NOT NULL) EXEC @SetUp;
        EXEC (@Cmd);
        SET @TestEndTime = GETDATE();
        IF(EXISTS(SELECT 1 FROM #ExpectException WHERE ExpectException = 1))
        BEGIN
          SET @TmpMsg = COALESCE((SELECT FailMessage FROM #ExpectException)+' ','')+'Expected an error to be raised.';
          EXEC tSQLt.Fail @TmpMsg;
        END
    END TRY
    BEGIN CATCH
        SET @TestEndTime = ISNULL(@TestEndTime,GETDATE());
        IF ERROR_MESSAGE() LIKE '%tSQLt.Failure%'
        BEGIN
            SELECT @Msg = Msg FROM tSQLt.TestMessage;
            SET @Result = 'Failure';
        END
        ELSE
        BEGIN
          DECLARE @ErrorInfo NVARCHAR(MAX);
          SELECT @ErrorInfo = 
            COALESCE(ERROR_MESSAGE(), '<ERROR_MESSAGE() is NULL>') + 
            '[' +COALESCE(LTRIM(STR(ERROR_SEVERITY())), '<ERROR_SEVERITY() is NULL>') + ','+COALESCE(LTRIM(STR(ERROR_STATE())), '<ERROR_STATE() is NULL>') + ']' +
            '{' + COALESCE(ERROR_PROCEDURE(), '<ERROR_PROCEDURE() is NULL>') + ',' + COALESCE(CAST(ERROR_LINE() AS NVARCHAR), '<ERROR_LINE() is NULL>') + '}';

          IF(EXISTS(SELECT 1 FROM #ExpectException))
          BEGIN
            DECLARE @ExpectException INT;
            DECLARE @ExpectedMessage NVARCHAR(MAX);
            DECLARE @ExpectedMessagePattern NVARCHAR(MAX);
            DECLARE @ExpectedSeverity INT;
            DECLARE @ExpectedState INT;
            DECLARE @ExpectedErrorNumber INT;
            DECLARE @FailMessage NVARCHAR(MAX);
            SELECT @ExpectException = ExpectException,
                   @ExpectedMessage = ExpectedMessage, 
                   @ExpectedSeverity = ExpectedSeverity,
                   @ExpectedState = ExpectedState,
                   @ExpectedMessagePattern = ExpectedMessagePattern,
                   @ExpectedErrorNumber = ExpectedErrorNumber,
                   @FailMessage = FailMessage
              FROM #ExpectException;

            IF(@ExpectException = 1)
            BEGIN
              SET @Result = 'Success';
              SET @TmpMsg = COALESCE(@FailMessage+' ','')+'Exception did not match expectation!';
              IF(ERROR_MESSAGE() <> @ExpectedMessage)
              BEGIN
                SET @TmpMsg = @TmpMsg +CHAR(13)+CHAR(10)+
                           'Expected Message: <'+@ExpectedMessage+'>'+CHAR(13)+CHAR(10)+
                           'Actual Message  : <'+ERROR_MESSAGE()+'>';
                SET @Result = 'Failure';
              END
              IF(ERROR_MESSAGE() NOT LIKE @ExpectedMessagePattern)
              BEGIN
                SET @TmpMsg = @TmpMsg +CHAR(13)+CHAR(10)+
                           'Expected Message to be like <'+@ExpectedMessagePattern+'>'+CHAR(13)+CHAR(10)+
                           'Actual Message            : <'+ERROR_MESSAGE()+'>';
                SET @Result = 'Failure';
              END
              IF(ERROR_NUMBER() <> @ExpectedErrorNumber)
              BEGIN
                SET @TmpMsg = @TmpMsg +CHAR(13)+CHAR(10)+
                           'Expected Error Number: '+CAST(@ExpectedErrorNumber AS NVARCHAR(MAX))+CHAR(13)+CHAR(10)+
                           'Actual Error Number  : '+CAST(ERROR_NUMBER() AS NVARCHAR(MAX));
                SET @Result = 'Failure';
              END
              IF(ERROR_SEVERITY() <> @ExpectedSeverity)
              BEGIN
                SET @TmpMsg = @TmpMsg +CHAR(13)+CHAR(10)+
                           'Expected Severity: '+CAST(@ExpectedSeverity AS NVARCHAR(MAX))+CHAR(13)+CHAR(10)+
                           'Actual Severity  : '+CAST(ERROR_SEVERITY() AS NVARCHAR(MAX));
                SET @Result = 'Failure';
              END
              IF(ERROR_STATE() <> @ExpectedState)
              BEGIN
                SET @TmpMsg = @TmpMsg +CHAR(13)+CHAR(10)+
                           'Expected State: '+CAST(@ExpectedState AS NVARCHAR(MAX))+CHAR(13)+CHAR(10)+
                           'Actual State  : '+CAST(ERROR_STATE() AS NVARCHAR(MAX));
                SET @Result = 'Failure';
              END
              IF(@Result = 'Failure')
              BEGIN
                SET @Msg = @TmpMsg;
              END
            END 
            ELSE
            BEGIN
                SET @Result = 'Failure';
                SET @Msg = 
                  COALESCE(@FailMessage+' ','')+
                  'Expected no error to be raised. Instead this error was encountered:'+
                  CHAR(13)+CHAR(10)+
                  @ErrorInfo;
            END
          END
          ELSE
          BEGIN
            SET @Result = 'Error';
            SET @Msg = @ErrorInfo;
          END  
        END;
    END CATCH

    BEGIN TRY
        ROLLBACK TRAN @TranName;
    END TRY
    BEGIN CATCH
        DECLARE @PostExecTrancount INT;
        SET @PostExecTrancount = @PreExecTrancount - @@TRANCOUNT;
        IF (@@TRANCOUNT > 0) ROLLBACK;
        BEGIN TRAN;
        IF(   @Result <> 'Success'
           OR @PostExecTrancount <> 0
          )
        BEGIN
          SELECT @Msg = COALESCE(@Msg, '<NULL>') + ' (There was also a ROLLBACK ERROR --> ' + COALESCE(ERROR_MESSAGE(), '<ERROR_MESSAGE() is NULL>') + '{' + COALESCE(ERROR_PROCEDURE(), '<ERROR_PROCEDURE() is NULL>') + ',' + COALESCE(CAST(ERROR_LINE() AS NVARCHAR), '<ERROR_LINE() is NULL>') + '})';
          SET @Result = 'Error';
        END
    END CATCH    

    If(@Result <> 'Success') 
    BEGIN
      SET @Msg2 = @TestName + ' failed: (' + @Result + ') ' + @Msg;
      EXEC tSQLt.Private_Print @Message = @Msg2, @Severity = 0;
    END

    IF EXISTS(SELECT 1 FROM tSQLt.TestResult WHERE Id = @TestResultId)
    BEGIN
        UPDATE tSQLt.TestResult SET
            Result = @Result,
            Msg = @Msg,
            TestEndTime = @TestEndTime
         WHERE Id = @TestResultId;
    END
    ELSE
    BEGIN
        INSERT tSQLt.TestResult(Class, TestCase, TranName, Result, Msg)
        SELECT @TestClassName, 
               @TestProcName,  
               '?', 
               'Error', 
               'TestResult entry is missing; Original outcome: ' + @Result + ', ' + @Msg;
    END    
      

    COMMIT;

    IF(@Verbose = 1)
    BEGIN
    SET @VerboseMsg = 'tSQLt.Run '''+@TestName+'''; --Finished';
      EXEC tSQLt.Private_Print @Message =@VerboseMsg, @Severity = 0;
    END;

END;
GO

CREATE PROCEDURE tSQLt.Private_RunTestClass
  @TestClassName NVARCHAR(MAX)
AS
BEGIN
    DECLARE @TestCaseName NVARCHAR(MAX);
    DECLARE @TestClassId INT; SET @TestClassId = tSQLt.Private_GetSchemaId(@TestClassName);
    DECLARE @SetupProcName NVARCHAR(MAX);
    EXEC tSQLt.Private_GetSetupProcedureName @TestClassId, @SetupProcName OUTPUT;
    
    DECLARE testCases CURSOR LOCAL FAST_FORWARD 
        FOR
     SELECT tSQLt.Private_GetQuotedFullName(object_id)
       FROM sys.procedures
      WHERE schema_id = @TestClassId
        AND LOWER(name) LIKE 'test%';

    OPEN testCases;
    
    FETCH NEXT FROM testCases INTO @TestCaseName;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC tSQLt.Private_RunTest @TestCaseName, @SetupProcName;

        FETCH NEXT FROM testCases INTO @TestCaseName;
    END;

    CLOSE testCases;
    DEALLOCATE testCases;
END;
GO

CREATE PROCEDURE tSQLt.Private_Run
   @TestName NVARCHAR(MAX),
   @TestResultFormatter NVARCHAR(MAX)
AS
BEGIN
SET NOCOUNT ON;
    DECLARE @FullName NVARCHAR(MAX);
    DECLARE @TestClassId INT;
    DECLARE @IsTestClass BIT;
    DECLARE @IsTestCase BIT;
    DECLARE @IsSchema BIT;
    DECLARE @SetUp NVARCHAR(MAX);SET @SetUp = NULL;
    
    SELECT @TestName = tSQLt.Private_GetLastTestNameIfNotProvided(@TestName);
    EXEC tSQLt.Private_SaveTestNameForSession @TestName;
    
    SELECT @TestClassId = schemaId,
           @FullName = quotedFullName,
           @IsTestClass = isTestClass,
           @IsSchema = isSchema,
           @IsTestCase = isTestCase
      FROM tSQLt.Private_ResolveName(@TestName);

    IF @IsSchema = 1
    BEGIN
        EXEC tSQLt.Private_RunTestClass @FullName;
    END
    
    IF @IsTestCase = 1
    BEGIN
      DECLARE @SetupProcName NVARCHAR(MAX);
      EXEC tSQLt.Private_GetSetupProcedureName @TestClassId, @SetupProcName OUTPUT;

      EXEC tSQLt.Private_RunTest @FullName, @SetupProcName;
    END;

    EXEC tSQLt.Private_OutputTestResults @TestResultFormatter;
END;
GO


CREATE PROCEDURE tSQLt.Private_RunCursor
  @TestResultFormatter NVARCHAR(MAX),
  @GetCursorCallback NVARCHAR(MAX)
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @TestClassName NVARCHAR(MAX);
  DECLARE @TestProcName NVARCHAR(MAX);

  DECLARE @TestClassCursor CURSOR;
  EXEC @GetCursorCallback @TestClassCursor = @TestClassCursor OUT;
----  
  WHILE(1=1)
  BEGIN
    FETCH NEXT FROM @TestClassCursor INTO @TestClassName;
    IF(@@FETCH_STATUS<>0)BREAK;

    EXEC tSQLt.Private_RunTestClass @TestClassName;
    
  END;
  
  CLOSE @TestClassCursor;
  DEALLOCATE @TestClassCursor;
  
  EXEC tSQLt.Private_OutputTestResults @TestResultFormatter;
END;
GO

CREATE PROCEDURE tSQLt.Private_GetCursorForRunAll
  @TestClassCursor CURSOR VARYING OUTPUT
AS
BEGIN
  SET @TestClassCursor = CURSOR LOCAL FAST_FORWARD FOR
   SELECT Name
     FROM tSQLt.TestClasses;

  OPEN @TestClassCursor;
END;
GO

CREATE PROCEDURE tSQLt.Private_RunAll
  @TestResultFormatter NVARCHAR(MAX)
AS
BEGIN
  EXEC tSQLt.Private_RunCursor @TestResultFormatter = @TestResultFormatter, @GetCursorCallback = 'tSQLt.Private_GetCursorForRunAll';
END;
GO

CREATE PROCEDURE tSQLt.Private_GetCursorForRunNew
  @TestClassCursor CURSOR VARYING OUTPUT
AS
BEGIN
  SET @TestClassCursor = CURSOR LOCAL FAST_FORWARD FOR
   SELECT TC.Name
     FROM tSQLt.TestClasses AS TC
     JOIN tSQLt.Private_NewTestClassList AS PNTCL
       ON PNTCL.ClassName = TC.Name;

  OPEN @TestClassCursor;
END;
GO

CREATE PROCEDURE tSQLt.Private_RunNew
  @TestResultFormatter NVARCHAR(MAX)
AS
BEGIN
  EXEC tSQLt.Private_RunCursor @TestResultFormatter = @TestResultFormatter, @GetCursorCallback = 'tSQLt.Private_GetCursorForRunNew';
END;
GO

CREATE PROCEDURE tSQLt.Private_RunMethodHandler
  @RunMethod NVARCHAR(MAX),
  @TestResultFormatter NVARCHAR(MAX) = NULL,
  @TestName NVARCHAR(MAX) = NULL
AS
BEGIN
  SELECT @TestResultFormatter = ISNULL(@TestResultFormatter,tSQLt.GetTestResultFormatter());

  EXEC tSQLt.Private_Init;
  IF(@@ERROR = 0)
  BEGIN  
    IF(EXISTS(SELECT * FROM sys.parameters AS P WHERE P.object_id = OBJECT_ID(@RunMethod) AND name = '@TestName'))
    BEGIN
      EXEC @RunMethod @TestName = @TestName, @TestResultFormatter = @TestResultFormatter;
    END;
    ELSE
    BEGIN  
      EXEC @RunMethod @TestResultFormatter = @TestResultFormatter;
    END;
  END;
END;
GO

--------------------------------------------------------------------------------

GO
CREATE PROCEDURE tSQLt.RunAll
AS
BEGIN
  EXEC tSQLt.Private_RunMethodHandler @RunMethod = 'tSQLt.Private_RunAll';
END;
GO

CREATE PROCEDURE tSQLt.RunNew
AS
BEGIN
  EXEC tSQLt.Private_RunMethodHandler @RunMethod = 'tSQLt.Private_RunNew';
END;
GO

CREATE PROCEDURE tSQLt.RunTest
   @TestName NVARCHAR(MAX)
AS
BEGIN
  RAISERROR('tSQLt.RunTest has been retired. Please use tSQLt.Run instead.', 16, 10);
END;
GO

CREATE PROCEDURE tSQLt.Run
   @TestName NVARCHAR(MAX) = NULL,
   @TestResultFormatter NVARCHAR(MAX) = NULL
AS
BEGIN
  EXEC tSQLt.Private_RunMethodHandler @RunMethod = 'tSQLt.Private_Run', @TestResultFormatter = @TestResultFormatter, @TestName = @TestName; 
END;
GO
CREATE PROCEDURE tSQLt.Private_InputBuffer
  @InputBuffer NVARCHAR(MAX) OUTPUT
AS
BEGIN
  CREATE TABLE #inputbuffer(EventType SYSNAME, Parameters SMALLINT, EventInfo NVARCHAR(MAX));
  INSERT INTO #inputbuffer
  EXEC('DBCC INPUTBUFFER(@@SPID) WITH NO_INFOMSGS;');
  SELECT @InputBuffer = I.EventInfo FROM #inputbuffer AS I;
END;
GO
CREATE PROCEDURE tSQLt.RunC
AS
BEGIN
  DECLARE @TestName NVARCHAR(MAX);SET @TestName = NULL;
  DECLARE @InputBuffer NVARCHAR(MAX);
  EXEC tSQLt.Private_InputBuffer @InputBuffer = @InputBuffer OUT;
  IF(@InputBuffer LIKE 'EXEC tSQLt.RunC;--%')
  BEGIN
    SET @TestName = LTRIM(RTRIM(STUFF(@InputBuffer,1,18,'')));
  END;
  EXEC tSQLt.Run @TestName = @TestName;
END;
GO

CREATE PROCEDURE tSQLt.RunWithXmlResults
   @TestName NVARCHAR(MAX) = NULL
AS
BEGIN
  EXEC tSQLt.Run @TestName = @TestName, @TestResultFormatter = 'tSQLt.XmlResultFormatter';
END;
GO

CREATE PROCEDURE tSQLt.RunWithNullResults
    @TestName NVARCHAR(MAX) = NULL
AS
BEGIN
  EXEC tSQLt.Run @TestName = @TestName, @TestResultFormatter = 'tSQLt.NullTestResultFormatter';
END;
GO

CREATE PROCEDURE tSQLt.DefaultResultFormatter
AS
BEGIN
    DECLARE @Msg1 NVARCHAR(MAX);
    DECLARE @Msg2 NVARCHAR(MAX);
    DECLARE @Msg3 NVARCHAR(MAX);
    DECLARE @Msg4 NVARCHAR(MAX);
    DECLARE @IsSuccess INT;
    DECLARE @SuccessCnt INT;
    DECLARE @Severity INT;
    
    SELECT ROW_NUMBER() OVER(ORDER BY Result DESC, Name ASC) No,Name [Test Case Name],
           RIGHT(SPACE(7)+CAST(DATEDIFF(MILLISECOND,TestStartTime,TestEndTime) AS VARCHAR(7)),7) AS [Dur(ms)], Result
      INTO #TestResultOutput
      FROM tSQLt.TestResult;
    
    EXEC tSQLt.TableToText @Msg1 OUTPUT, '#TestResultOutput', 'No';

    SELECT @Msg3 = Msg, 
           @IsSuccess = 1 - SIGN(FailCnt + ErrorCnt),
           @SuccessCnt = SuccessCnt
      FROM tSQLt.TestCaseSummary();
      
    SELECT @Severity = 16*(1-@IsSuccess);
    
    SELECT @Msg2 = REPLICATE('-',LEN(@Msg3)),
           @Msg4 = CHAR(13)+CHAR(10);
    
    
    EXEC tSQLt.Private_Print @Msg4,0;
    EXEC tSQLt.Private_Print '+----------------------+',0;
    EXEC tSQLt.Private_Print '|Test Execution Summary|',0;
    EXEC tSQLt.Private_Print '+----------------------+',0;
    EXEC tSQLt.Private_Print @Msg4,0;
    EXEC tSQLt.Private_Print @Msg1,0;
    EXEC tSQLt.Private_Print @Msg2,0;
    EXEC tSQLt.Private_Print @Msg3, @Severity;
    EXEC tSQLt.Private_Print @Msg2,0;
END;
GO

CREATE PROCEDURE tSQLt.XmlResultFormatter
AS
BEGIN
    DECLARE @XmlOutput XML;

    SELECT @XmlOutput = (
      SELECT *--Tag, Parent, [testsuites!1!hide!hide], [testsuite!2!name], [testsuite!2!tests], [testsuite!2!errors], [testsuite!2!failures], [testsuite!2!timestamp], [testsuite!2!time], [testcase!3!classname], [testcase!3!name], [testcase!3!time], [failure!4!message]  
        FROM (
          SELECT 1 AS Tag,
                 NULL AS Parent,
                 'root' AS [testsuites!1!hide!hide],
                 NULL AS [testsuite!2!id],
                 NULL AS [testsuite!2!name],
                 NULL AS [testsuite!2!tests],
                 NULL AS [testsuite!2!errors],
                 NULL AS [testsuite!2!failures],
                 NULL AS [testsuite!2!timestamp],
                 NULL AS [testsuite!2!time],
                 NULL AS [testsuite!2!hostname],
                 NULL AS [testsuite!2!package],
                 NULL AS [properties!3!hide!hide],
                 NULL AS [testcase!4!classname],
                 NULL AS [testcase!4!name],
                 NULL AS [testcase!4!time],
                 NULL AS [failure!5!message],
                 NULL AS [failure!5!type],
                 NULL AS [error!6!message],
                 NULL AS [error!6!type],
                 NULL AS [system-out!7!hide],
                 NULL AS [system-err!8!hide]
          UNION ALL
          SELECT 2 AS Tag, 
                 1 AS Parent,
                 'root',
                 ROW_NUMBER()OVER(ORDER BY Class),
                 Class,
                 COUNT(1),
                 SUM(CASE Result WHEN 'Error' THEN 1 ELSE 0 END),
                 SUM(CASE Result WHEN 'Failure' THEN 1 ELSE 0 END),
                 CONVERT(VARCHAR(19),MIN(TestResult.TestStartTime),126),
                 CAST(CAST(DATEDIFF(MILLISECOND,MIN(TestResult.TestStartTime),MAX(TestResult.TestEndTime))/1000.0 AS NUMERIC(20,3))AS VARCHAR(MAX)),
                 CAST(SERVERPROPERTY('ServerName') AS NVARCHAR(MAX)),
                 'tSQLt',
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL
            FROM tSQLt.TestResult
          GROUP BY Class
          UNION ALL
          SELECT 3 AS Tag,
                 2 AS Parent,
                 'root',
                 NULL,
                 Class,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 Class,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL
            FROM tSQLt.TestResult
           GROUP BY Class
          UNION ALL
          SELECT 4 AS Tag,
                 2 AS Parent,
                 'root',
                 NULL,
                 Class,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 Class,
                 TestCase,
                 CAST(CAST(DATEDIFF(MILLISECOND,TestResult.TestStartTime,TestResult.TestEndTime)/1000.0 AS NUMERIC(20,3))AS VARCHAR(MAX)),
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL
            FROM tSQLt.TestResult
          UNION ALL
          SELECT 5 AS Tag,
                 4 AS Parent,
                 'root',
                 NULL,
                 Class,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 Class,
                 TestCase,
                 CAST(CAST(DATEDIFF(MILLISECOND,TestResult.TestStartTime,TestResult.TestEndTime)/1000.0 AS NUMERIC(20,3))AS VARCHAR(MAX)),
                 Msg,
                 'tSQLt.Fail',
                 NULL,
                 NULL,
                 NULL,
                 NULL
            FROM tSQLt.TestResult
           WHERE Result IN ('Failure')
          UNION ALL
          SELECT 6 AS Tag,
                 4 AS Parent,
                 'root',
                 NULL,
                 Class,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 Class,
                 TestCase,
                 CAST(CAST(DATEDIFF(MILLISECOND,TestResult.TestStartTime,TestResult.TestEndTime)/1000.0 AS NUMERIC(20,3))AS VARCHAR(MAX)),
                 NULL,
                 NULL,
                 Msg,
                 'SQL Error',
                 NULL,
                 NULL
            FROM tSQLt.TestResult
           WHERE Result IN ( 'Error')
          UNION ALL
          SELECT 7 AS Tag,
                 2 AS Parent,
                 'root',
                 NULL,
                 Class,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 Class,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL
            FROM tSQLt.TestResult
           GROUP BY Class
          UNION ALL
          SELECT 8 AS Tag,
                 2 AS Parent,
                 'root',
                 NULL,
                 Class,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 Class,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL
            FROM tSQLt.TestResult
           GROUP BY Class
        ) AS X
       ORDER BY [testsuite!2!name],CASE WHEN Tag IN (7,8) THEN 1 ELSE 0 END, [testcase!4!name], Tag
       FOR XML EXPLICIT
       );

    EXEC tSQLt.Private_PrintXML @XmlOutput;
END;
GO

CREATE PROCEDURE tSQLt.NullTestResultFormatter
AS
BEGIN
  RETURN 0;
END;
GO

CREATE PROCEDURE tSQLt.RunTestClass
   @TestClassName NVARCHAR(MAX)
AS
BEGIN
    EXEC tSQLt.Run @TestClassName;
END
GO    
--Build-


GO

CREATE PROCEDURE tSQLt.ExpectException
@ExpectedMessage NVARCHAR(MAX) = NULL,
@ExpectedSeverity INT = NULL,
@ExpectedState INT = NULL,
@Message NVARCHAR(MAX) = NULL,
@ExpectedMessagePattern NVARCHAR(MAX) = NULL,
@ExpectedErrorNumber INT = NULL
AS
BEGIN
 IF(EXISTS(SELECT 1 FROM #ExpectException WHERE ExpectException = 1))
 BEGIN
   DELETE #ExpectException;
   RAISERROR('Each test can only contain one call to tSQLt.ExpectException.',16,10);
 END;
 
 INSERT INTO #ExpectException(ExpectException, ExpectedMessage, ExpectedSeverity, ExpectedState, ExpectedMessagePattern, ExpectedErrorNumber, FailMessage)
 VALUES(1, @ExpectedMessage, @ExpectedSeverity, @ExpectedState, @ExpectedMessagePattern, @ExpectedErrorNumber, @Message);
END;


GO

CREATE PROCEDURE tSQLt.ExpectNoException
  @Message NVARCHAR(MAX) = NULL
AS
BEGIN
 IF(EXISTS(SELECT 1 FROM #ExpectException WHERE ExpectException = 0))
 BEGIN
   DELETE #ExpectException;
   RAISERROR('Each test can only contain one call to tSQLt.ExpectNoException.',16,10);
 END;
 IF(EXISTS(SELECT 1 FROM #ExpectException WHERE ExpectException = 1))
 BEGIN
   DELETE #ExpectException;
   RAISERROR('tSQLt.ExpectNoException cannot follow tSQLt.ExpectException inside a single test.',16,10);
 END;
 
 INSERT INTO #ExpectException(ExpectException, FailMessage)
 VALUES(0, @Message);
END;


GO

GO
CREATE FUNCTION tSQLt.Private_SqlVersion()
RETURNS TABLE
AS
RETURN
  SELECT CAST(SERVERPROPERTY('ProductVersion')AS NVARCHAR(128)) ProductVersion,
         CAST(SERVERPROPERTY('Edition')AS NVARCHAR(128)) Edition;
GO


GO

CREATE FUNCTION tSQLt.Info()
RETURNS TABLE
AS
RETURN
SELECT Version = '1.0.5873.27393',
       ClrVersion = (SELECT tSQLt.Private::Info()),
       ClrSigningKey = (SELECT tSQLt.Private::SigningKey()),
       V.SqlVersion,
       V.SqlBuild,
       V.SqlEdition
  FROM
  (
    SELECT CAST(VI.major+'.'+VI.minor AS NUMERIC(10,2)) AS SqlVersion,
           CAST(VI.build+'.'+VI.revision AS NUMERIC(10,2)) AS SqlBuild,
           SqlEdition
      FROM
      (
        SELECT PARSENAME(PSV.ProductVersion,4) major,
               PARSENAME(PSV.ProductVersion,3) minor, 
               PARSENAME(PSV.ProductVersion,2) build,
               PARSENAME(PSV.ProductVersion,1) revision,
               Edition AS SqlEdition
          FROM tSQLt.Private_SqlVersion() AS PSV
      )VI
  )V;


GO

IF((SELECT SqlVersion FROM tSQLt.Info())>9)
BEGIN
  EXEC('CREATE VIEW tSQLt.Private_SysIndexes AS SELECT * FROM sys.indexes;');
END
ELSE
BEGIN
  EXEC('CREATE VIEW tSQLt.Private_SysIndexes AS SELECT *,0 AS has_filter,'''' AS filter_definition FROM sys.indexes;');
END;


GO

GO
CREATE FUNCTION tSQLt.Private_ScriptIndex
(
  @object_id INT,
  @index_id INT
)
RETURNS TABLE
AS
RETURN
  SELECT I.index_id,
         I.name AS index_name,
         I.is_primary_key,
         I.is_unique,
         I.is_disabled,
         'CREATE ' +
         CASE WHEN I.is_unique = 1 THEN 'UNIQUE ' ELSE '' END +
         CASE I.type
           WHEN 1 THEN 'CLUSTERED'
           WHEN 2 THEN 'NONCLUSTERED'
           WHEN 5 THEN 'CLUSTERED COLUMNSTORE'
           WHEN 6 THEN 'NONCLUSTERED COLUMNSTORE'
           ELSE '{Index Type Not Supported!}' 
         END +
         ' INDEX ' +
         QUOTENAME(I.name)+
         ' ON ' + QUOTENAME(OBJECT_SCHEMA_NAME(@object_id)) + '.' + QUOTENAME(OBJECT_NAME(@object_id)) +
         CASE WHEN I.type NOT IN (5)
           THEN
             '('+ 
             CL.column_list +
             ')'
           ELSE ''
         END +
         CASE WHEN I.has_filter = 1
           THEN 'WHERE' + I.filter_definition
           ELSE ''
         END +
         CASE WHEN I.is_hypothetical = 1
           THEN 'WITH(STATISTICS_ONLY = -1)'
           ELSE ''
         END +
         ';' AS create_cmd
    FROM tSQLt.Private_SysIndexes AS I
   CROSS APPLY
   (
     SELECT
      (
        SELECT 
          CASE WHEN OIC.rn > 1 THEN ',' ELSE '' END +
          CASE WHEN OIC.rn = 1 AND OIC.is_included_column = 1 AND I.type NOT IN (6) THEN ')INCLUDE(' ELSE '' END +
          QUOTENAME(OIC.name) +
          CASE WHEN OIC.is_included_column = 0
            THEN CASE WHEN OIC.is_descending_key = 1 THEN 'DESC' ELSE 'ASC' END
            ELSE ''
          END
          FROM
          (
            SELECT C.name,
                   IC.is_descending_key, 
                   IC.key_ordinal,
                   IC.is_included_column,
                   ROW_NUMBER()OVER(PARTITION BY IC.is_included_column ORDER BY IC.key_ordinal, IC.index_column_id) AS rn
              FROM sys.index_columns AS IC
              JOIN sys.columns AS C
                ON IC.column_id = C.column_id
               AND IC.object_id = C.object_id
             WHERE IC.object_id = I.object_id
               AND IC.index_id = I.index_id
          )OIC
         ORDER BY OIC.is_included_column, OIC.rn
           FOR XML PATH(''),TYPE
      ).value('.','NVARCHAR(MAX)') AS column_list
   )CL
   WHERE I.object_id = @object_id
     AND I.index_id = ISNULL(@index_id,I.index_id);
GO


GO

GO
CREATE PROCEDURE tSQLt.Private_RemoveSchemaBinding
  @object_id INT
AS
BEGIN
  DECLARE @cmd NVARCHAR(MAX);
  SELECT @cmd = tSQLt.[Private]::GetAlterStatementWithoutSchemaBinding(SM.definition)
    FROM sys.sql_modules AS SM
   WHERE SM.object_id = @object_id;
   EXEC(@cmd);
END;
GO


GO

GO
CREATE PROCEDURE tSQLt.Private_RemoveSchemaBoundReferences
  @object_id INT
AS
BEGIN
  DECLARE @cmd NVARCHAR(MAX);
  SELECT @cmd = 
  (
    SELECT 
      'EXEC tSQLt.Private_RemoveSchemaBoundReferences @object_id = '+STR(SED.referencing_id)+';'+
      'EXEC tSQLt.Private_RemoveSchemaBinding @object_id = '+STR(SED.referencing_id)+';'
      FROM
      (
        SELECT DISTINCT SEDI.referencing_id,SEDI.referenced_id 
          FROM sys.sql_expression_dependencies AS SEDI
         WHERE SEDI.is_schema_bound_reference = 1
      ) AS SED 
     WHERE SED.referenced_id = @object_id
       FOR XML PATH(''),TYPE
  ).value('.','NVARCHAR(MAX)');
  EXEC(@cmd);
END;
GO


GO

GO
CREATE FUNCTION tSQLt.Private_GetForeignKeyParColumns(
    @ConstraintObjectId INT
)
RETURNS TABLE
AS
RETURN SELECT STUFF((
                 SELECT ','+QUOTENAME(pci.name) FROM sys.foreign_key_columns c
                   JOIN sys.columns pci
                   ON pci.object_id = c.parent_object_id
                  AND pci.column_id = c.parent_column_id
                   WHERE @ConstraintObjectId = c.constraint_object_id
                   FOR XML PATH(''),TYPE
                   ).value('.','NVARCHAR(MAX)'),1,1,'')  AS ColNames
GO

CREATE FUNCTION tSQLt.Private_GetForeignKeyRefColumns(
    @ConstraintObjectId INT
)
RETURNS TABLE
AS
RETURN SELECT STUFF((
                 SELECT ','+QUOTENAME(rci.name) FROM sys.foreign_key_columns c
                   JOIN sys.columns rci
                  ON rci.object_id = c.referenced_object_id
                  AND rci.column_id = c.referenced_column_id
                   WHERE @ConstraintObjectId = c.constraint_object_id
                   FOR XML PATH(''),TYPE
                   ).value('.','NVARCHAR(MAX)'),1,1,'')  AS ColNames;
GO

CREATE FUNCTION tSQLt.Private_GetForeignKeyDefinition(
    @SchemaName NVARCHAR(MAX),
    @ParentTableName NVARCHAR(MAX),
    @ForeignKeyName NVARCHAR(MAX),
    @NoCascade BIT
)
RETURNS TABLE
AS
RETURN SELECT 'CONSTRAINT ' + name + ' FOREIGN KEY (' +
              parCols + ') REFERENCES ' + refName + '(' + refCols + ')'+
              CASE WHEN @NoCascade = 1 THEN ''
                ELSE delete_referential_action_cmd + ' ' + update_referential_action_cmd 
              END AS cmd,
              CASE 
                WHEN RefTableIsFakedInd = 1
                  THEN 'CREATE UNIQUE INDEX ' + tSQLt.Private::CreateUniqueObjectName() + ' ON ' + refName + '(' + refCols + ');' 
                ELSE '' 
              END CreIdxCmd
         FROM (SELECT QUOTENAME(SCHEMA_NAME(k.schema_id)) AS SchemaName,
                      QUOTENAME(k.name) AS name,
                      QUOTENAME(OBJECT_NAME(k.parent_object_id)) AS parName,
                      QUOTENAME(SCHEMA_NAME(refTab.schema_id)) + '.' + QUOTENAME(refTab.name) AS refName,
                      parCol.ColNames AS parCols,
                      refCol.ColNames AS refCols,
                      'ON UPDATE '+
                      CASE k.update_referential_action
                        WHEN 0 THEN 'NO ACTION'
                        WHEN 1 THEN 'CASCADE'
                        WHEN 2 THEN 'SET NULL'
                        WHEN 3 THEN 'SET DEFAULT'
                      END AS update_referential_action_cmd,
                      'ON DELETE '+
                      CASE k.delete_referential_action
                        WHEN 0 THEN 'NO ACTION'
                        WHEN 1 THEN 'CASCADE'
                        WHEN 2 THEN 'SET NULL'
                        WHEN 3 THEN 'SET DEFAULT'
                      END AS delete_referential_action_cmd,
                      CASE WHEN e.name IS NULL THEN 0
                           ELSE 1 
                       END AS RefTableIsFakedInd
                 FROM sys.foreign_keys k
                 CROSS APPLY tSQLt.Private_GetForeignKeyParColumns(k.object_id) AS parCol
                 CROSS APPLY tSQLt.Private_GetForeignKeyRefColumns(k.object_id) AS refCol
                 LEFT JOIN sys.extended_properties e
                   ON e.name = 'tSQLt.FakeTable_OrgTableName'
                  AND e.value = OBJECT_NAME(k.referenced_object_id)
                 JOIN sys.tables refTab
                   ON COALESCE(e.major_id,k.referenced_object_id) = refTab.object_id
                WHERE k.parent_object_id = OBJECT_ID(@SchemaName + '.' + @ParentTableName)
                  AND k.object_id = OBJECT_ID(@SchemaName + '.' + @ForeignKeyName)
               )x;
GO


GO

GO
CREATE FUNCTION tSQLt.Private_GetQuotedTableNameForConstraint(@ConstraintObjectId INT)
RETURNS TABLE
AS
RETURN
  SELECT QUOTENAME(SCHEMA_NAME(newtbl.schema_id)) + '.' + QUOTENAME(OBJECT_NAME(newtbl.object_id)) QuotedTableName,
         SCHEMA_NAME(newtbl.schema_id) SchemaName,
         OBJECT_NAME(newtbl.object_id) TableName,
         OBJECT_NAME(constraints.parent_object_id) OrgTableName
      FROM sys.objects AS constraints
      JOIN sys.extended_properties AS p
      JOIN sys.objects AS newtbl
        ON newtbl.object_id = p.major_id
       AND p.minor_id = 0
       AND p.class_desc = 'OBJECT_OR_COLUMN'
       AND p.name = 'tSQLt.FakeTable_OrgTableName'
        ON OBJECT_NAME(constraints.parent_object_id) = CAST(p.value AS NVARCHAR(4000))
       AND constraints.schema_id = newtbl.schema_id
       AND constraints.object_id = @ConstraintObjectId;
GO

CREATE FUNCTION tSQLt.Private_FindConstraint
(
  @TableObjectId INT,
  @ConstraintName NVARCHAR(MAX)
)
RETURNS TABLE
AS
RETURN
  SELECT TOP(1) constraints.object_id AS ConstraintObjectId, type_desc AS ConstraintType
    FROM sys.objects constraints
    CROSS JOIN tSQLt.Private_GetOriginalTableInfo(@TableObjectId) orgTbl
   WHERE @ConstraintName IN (constraints.name, QUOTENAME(constraints.name))
     AND constraints.parent_object_id = orgTbl.OrgTableObjectId
   ORDER BY LEN(constraints.name) ASC;
GO

CREATE FUNCTION tSQLt.Private_ResolveApplyConstraintParameters
(
  @A NVARCHAR(MAX),
  @B NVARCHAR(MAX),
  @C NVARCHAR(MAX)
)
RETURNS TABLE
AS 
RETURN
  SELECT ConstraintObjectId, ConstraintType
    FROM tSQLt.Private_FindConstraint(OBJECT_ID(@A), @B)
   WHERE @C IS NULL
   UNION ALL
  SELECT *
    FROM tSQLt.Private_FindConstraint(OBJECT_ID(@A + '.' + @B), @C)
   UNION ALL
  SELECT *
    FROM tSQLt.Private_FindConstraint(OBJECT_ID(@C + '.' + @A), @B);
GO

CREATE PROCEDURE tSQLt.Private_ApplyCheckConstraint
  @ConstraintObjectId INT
AS
BEGIN
  DECLARE @Cmd NVARCHAR(MAX);
  SELECT @Cmd = 'CONSTRAINT ' + QUOTENAME(name) + ' CHECK' + definition 
    FROM sys.check_constraints
   WHERE object_id = @ConstraintObjectId;
  
  DECLARE @QuotedTableName NVARCHAR(MAX);
  
  SELECT @QuotedTableName = QuotedTableName FROM tSQLt.Private_GetQuotedTableNameForConstraint(@ConstraintObjectId);

  EXEC tSQLt.Private_RenameObjectToUniqueNameUsingObjectId @ConstraintObjectId;
  SELECT @Cmd = 'ALTER TABLE ' + @QuotedTableName + ' ADD ' + @Cmd
    FROM sys.objects 
   WHERE object_id = @ConstraintObjectId;

  EXEC (@Cmd);

END; 
GO

CREATE PROCEDURE tSQLt.Private_ApplyForeignKeyConstraint 
  @ConstraintObjectId INT,
  @NoCascade BIT
AS
BEGIN
  DECLARE @SchemaName NVARCHAR(MAX);
  DECLARE @OrgTableName NVARCHAR(MAX);
  DECLARE @TableName NVARCHAR(MAX);
  DECLARE @ConstraintName NVARCHAR(MAX);
  DECLARE @CreateFkCmd NVARCHAR(MAX);
  DECLARE @AlterTableCmd NVARCHAR(MAX);
  DECLARE @CreateIndexCmd NVARCHAR(MAX);
  DECLARE @FinalCmd NVARCHAR(MAX);
  
  SELECT @SchemaName = SchemaName,
         @OrgTableName = OrgTableName,
         @TableName = TableName,
         @ConstraintName = OBJECT_NAME(@ConstraintObjectId)
    FROM tSQLt.Private_GetQuotedTableNameForConstraint(@ConstraintObjectId);
      
  SELECT @CreateFkCmd = cmd, @CreateIndexCmd = CreIdxCmd
    FROM tSQLt.Private_GetForeignKeyDefinition(@SchemaName, @OrgTableName, @ConstraintName, @NoCascade);
  SELECT @AlterTableCmd = 'ALTER TABLE ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + 
                          ' ADD ' + @CreateFkCmd;
  SELECT @FinalCmd = @CreateIndexCmd + @AlterTableCmd;

  EXEC tSQLt.Private_RenameObjectToUniqueName @SchemaName, @ConstraintName;
  EXEC (@FinalCmd);
END;
GO

CREATE PROCEDURE tSQLt.Private_ApplyUniqueConstraint 
  @ConstraintObjectId INT
AS
BEGIN
  DECLARE @SchemaName NVARCHAR(MAX);
  DECLARE @OrgTableName NVARCHAR(MAX);
  DECLARE @TableName NVARCHAR(MAX);
  DECLARE @ConstraintName NVARCHAR(MAX);
  DECLARE @CreateConstraintCmd NVARCHAR(MAX);
  DECLARE @AlterColumnsCmd NVARCHAR(MAX);
  
  SELECT @SchemaName = SchemaName,
         @OrgTableName = OrgTableName,
         @TableName = TableName,
         @ConstraintName = OBJECT_NAME(@ConstraintObjectId)
    FROM tSQLt.Private_GetQuotedTableNameForConstraint(@ConstraintObjectId);
      
  SELECT @AlterColumnsCmd = NotNullColumnCmd,
         @CreateConstraintCmd = CreateConstraintCmd
    FROM tSQLt.Private_GetUniqueConstraintDefinition(@ConstraintObjectId, QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName));

  EXEC tSQLt.Private_RenameObjectToUniqueName @SchemaName, @ConstraintName;
  EXEC (@AlterColumnsCmd);
  EXEC (@CreateConstraintCmd);
END;
GO

CREATE FUNCTION tSQLt.Private_GetConstraintType(@TableObjectId INT, @ConstraintName NVARCHAR(MAX))
RETURNS TABLE
AS
RETURN
  SELECT object_id,type,type_desc
    FROM sys.objects 
   WHERE object_id = OBJECT_ID(SCHEMA_NAME(schema_id)+'.'+@ConstraintName)
     AND parent_object_id = @TableObjectId;
GO

CREATE PROCEDURE tSQLt.ApplyConstraint
       @TableName NVARCHAR(MAX),
       @ConstraintName NVARCHAR(MAX),
       @SchemaName NVARCHAR(MAX) = NULL, --parameter preserved for backward compatibility. Do not use. Will be removed soon.
       @NoCascade BIT = 0
AS
BEGIN
  DECLARE @ConstraintType NVARCHAR(MAX);
  DECLARE @ConstraintObjectId INT;
  
  SELECT @ConstraintType = ConstraintType, @ConstraintObjectId = ConstraintObjectId
    FROM tSQLt.Private_ResolveApplyConstraintParameters (@TableName, @ConstraintName, @SchemaName);

  IF @ConstraintType = 'CHECK_CONSTRAINT'
  BEGIN
    EXEC tSQLt.Private_ApplyCheckConstraint @ConstraintObjectId;
    RETURN 0;
  END

  IF @ConstraintType = 'FOREIGN_KEY_CONSTRAINT'
  BEGIN
    EXEC tSQLt.Private_ApplyForeignKeyConstraint @ConstraintObjectId, @NoCascade;
    RETURN 0;
  END;  
   
  IF @ConstraintType IN('UNIQUE_CONSTRAINT', 'PRIMARY_KEY_CONSTRAINT')
  BEGIN
    EXEC tSQLt.Private_ApplyUniqueConstraint @ConstraintObjectId;
    RETURN 0;
  END;  
   
  RAISERROR ('ApplyConstraint could not resolve the object names, ''%s'', ''%s''. Be sure to call ApplyConstraint and pass in two parameters, such as: EXEC tSQLt.ApplyConstraint ''MySchema.MyTable'', ''MyConstraint''', 
             16, 10, @TableName, @ConstraintName);
  RETURN 0;
END;
GO


GO

CREATE PROCEDURE tSQLt.Private_ValidateFakeTableParameters
  @SchemaName NVARCHAR(MAX),
  @OrigTableName NVARCHAR(MAX),
  @OrigSchemaName NVARCHAR(MAX)
AS
BEGIN
   IF @SchemaName IS NULL
   BEGIN
        DECLARE @FullName NVARCHAR(MAX); SET @FullName = @OrigTableName + COALESCE('.' + @OrigSchemaName, '');
        
        RAISERROR ('FakeTable could not resolve the object name, ''%s''. (When calling tSQLt.FakeTable, avoid the use of the @SchemaName parameter, as it is deprecated.)', 
                   16, 10, @FullName);
   END;
END;


GO

GO
CREATE FUNCTION tSQLt.Private_GetDataTypeOrComputedColumnDefinition(@UserTypeId INT, @MaxLength INT, @Precision INT, @Scale INT, @CollationName NVARCHAR(MAX), @ObjectId INT, @ColumnId INT, @ReturnDetails BIT)
RETURNS TABLE
AS
RETURN SELECT 
              COALESCE(cc.IsComputedColumn, 0) AS IsComputedColumn,
              COALESCE(cc.ComputedColumnDefinition, GFTN.TypeName) AS ColumnDefinition
        FROM (SELECT @UserTypeId, @MaxLength, @Precision, @Scale, @CollationName, @ObjectId, @ColumnId, @ReturnDetails) 
             AS V(UserTypeId, MaxLength, Precision, Scale, CollationName, ObjectId, ColumnId, ReturnDetails)
       CROSS APPLY tSQLt.Private_GetFullTypeName(V.UserTypeId, V.MaxLength, V.Precision, V.Scale, V.CollationName) AS GFTN
        LEFT JOIN (SELECT 1 AS IsComputedColumn,
                          ' AS '+ cci.definition + CASE WHEN cci.is_persisted = 1 THEN ' PERSISTED' ELSE '' END AS ComputedColumnDefinition,
                          cci.object_id,
                          cci.column_id
                     FROM sys.computed_columns cci
                  )cc
               ON cc.object_id = V.ObjectId
              AND cc.column_id = V.ColumnId
              AND V.ReturnDetails = 1;               


GO

CREATE FUNCTION tSQLt.Private_GetIdentityDefinition(@ObjectId INT, @ColumnId INT, @ReturnDetails BIT)
RETURNS TABLE
AS
RETURN SELECT 
              COALESCE(IsIdentity, 0) AS IsIdentityColumn,
              COALESCE(IdentityDefinition, '') AS IdentityDefinition
        FROM (SELECT 1) X(X)
        LEFT JOIN (SELECT 1 AS IsIdentity,
                          ' IDENTITY(' + CAST(seed_value AS NVARCHAR(MAX)) + ',' + CAST(increment_value AS NVARCHAR(MAX)) + ')' AS IdentityDefinition, 
                          object_id, 
                          column_id
                     FROM sys.identity_columns
                  ) AS id
               ON id.object_id = @ObjectId
              AND id.column_id = @ColumnId
              AND @ReturnDetails = 1;               


GO

GO
CREATE FUNCTION tSQLt.Private_GetDefaultConstraintDefinition(@ObjectId INT, @ColumnId INT, @ReturnDetails BIT)
RETURNS TABLE
AS
RETURN SELECT 
              COALESCE(IsDefault, 0) AS IsDefault,
              COALESCE(DefaultDefinition, '') AS DefaultDefinition
        FROM (SELECT 1) X(X)
        LEFT JOIN (SELECT 1 AS IsDefault,' DEFAULT '+ definition AS DefaultDefinition,parent_object_id,parent_column_id
                     FROM sys.default_constraints
                  )dc
               ON dc.parent_object_id = @ObjectId
              AND dc.parent_column_id = @ColumnId
              AND @ReturnDetails = 1;               


GO

GO
CREATE FUNCTION tSQLt.Private_GetUniqueConstraintDefinition
(
    @ConstraintObjectId INT,
    @QuotedTableName NVARCHAR(MAX)
)
RETURNS TABLE
AS
RETURN
  SELECT 'ALTER TABLE '+
         @QuotedTableName +
         ' ADD CONSTRAINT ' +
         QUOTENAME(OBJECT_NAME(@ConstraintObjectId)) +
         ' ' +
         CASE WHEN KC.type_desc = 'UNIQUE_CONSTRAINT' 
              THEN 'UNIQUE'
              ELSE 'PRIMARY KEY'
           END +
         '(' +
         STUFF((
                 SELECT ','+QUOTENAME(C.name)
                   FROM sys.index_columns AS IC
                   JOIN sys.columns AS C
                     ON IC.object_id = C.object_id
                    AND IC.column_id = C.column_id
                  WHERE KC.unique_index_id = IC.index_id
                    AND KC.parent_object_id = IC.object_id
                    FOR XML PATH(''),TYPE
               ).value('.','NVARCHAR(MAX)'),
               1,
               1,
               ''
              ) +
         ');' AS CreateConstraintCmd,
         CASE WHEN KC.type_desc = 'UNIQUE_CONSTRAINT' 
              THEN ''
              ELSE (
                     SELECT 'ALTER TABLE ' +
                            @QuotedTableName +
                            ' ALTER COLUMN ' +
                            QUOTENAME(C.name)+
                            cc.ColumnDefinition +
                            ' NOT NULL;'
                       FROM sys.index_columns AS IC
                       JOIN sys.columns AS C
                         ON IC.object_id = C.object_id
                        AND IC.column_id = C.column_id
                      CROSS APPLY tSQLt.Private_GetDataTypeOrComputedColumnDefinition(C.user_type_id, C.max_length, C.precision, C.scale, C.collation_name, C.object_id, C.column_id, 0) cc
                      WHERE KC.unique_index_id = IC.index_id
                        AND KC.parent_object_id = IC.object_id
                        FOR XML PATH(''),TYPE
                   ).value('.','NVARCHAR(MAX)')
           END AS NotNullColumnCmd
    FROM sys.key_constraints AS KC
   WHERE KC.object_id = @ConstraintObjectId;
GO


GO

CREATE PROCEDURE tSQLt.Private_CreateFakeOfTable
  @SchemaName NVARCHAR(MAX),
  @TableName NVARCHAR(MAX),
  @OrigTableFullName NVARCHAR(MAX),
  @Identity BIT,
  @ComputedColumns BIT,
  @Defaults BIT
AS
BEGIN
   DECLARE @Cmd NVARCHAR(MAX);
   DECLARE @Cols NVARCHAR(MAX);
   
   SELECT @Cols = 
   (
    SELECT
       ',' +
       QUOTENAME(name) + 
       cc.ColumnDefinition +
       dc.DefaultDefinition + 
       id.IdentityDefinition +
       CASE WHEN cc.IsComputedColumn = 1 OR id.IsIdentityColumn = 1 
            THEN ''
            ELSE ' NULL'
       END
      FROM sys.columns c
     CROSS APPLY tSQLt.Private_GetDataTypeOrComputedColumnDefinition(c.user_type_id, c.max_length, c.precision, c.scale, c.collation_name, c.object_id, c.column_id, @ComputedColumns) cc
     CROSS APPLY tSQLt.Private_GetDefaultConstraintDefinition(c.object_id, c.column_id, @Defaults) AS dc
     CROSS APPLY tSQLt.Private_GetIdentityDefinition(c.object_id, c.column_id, @Identity) AS id
     WHERE object_id = OBJECT_ID(@OrigTableFullName)
     ORDER BY column_id
     FOR XML PATH(''), TYPE
    ).value('.', 'NVARCHAR(MAX)');
    
   SELECT @Cmd = 'CREATE TABLE ' + @SchemaName + '.' + @TableName + '(' + STUFF(@Cols,1,1,'') + ')';
   
   EXEC (@Cmd);
END;


GO

CREATE PROCEDURE tSQLt.Private_MarkFakeTable
  @SchemaName NVARCHAR(MAX),
  @TableName NVARCHAR(MAX),
  @NewNameOfOriginalTable NVARCHAR(4000)
AS
BEGIN
   DECLARE @UnquotedSchemaName NVARCHAR(MAX);SET @UnquotedSchemaName = OBJECT_SCHEMA_NAME(OBJECT_ID(@SchemaName+'.'+@TableName));
   DECLARE @UnquotedTableName NVARCHAR(MAX);SET @UnquotedTableName = OBJECT_NAME(OBJECT_ID(@SchemaName+'.'+@TableName));

   EXEC sys.sp_addextendedproperty 
      @name = N'tSQLt.FakeTable_OrgTableName', 
      @value = @NewNameOfOriginalTable, 
      @level0type = N'SCHEMA', @level0name = @UnquotedSchemaName, 
      @level1type = N'TABLE',  @level1name = @UnquotedTableName;
END;


GO

CREATE PROCEDURE tSQLt.FakeTable
    @TableName NVARCHAR(MAX),
    @SchemaName NVARCHAR(MAX) = NULL, --parameter preserved for backward compatibility. Do not use. Will be removed soon.
    @Identity BIT = NULL,
    @ComputedColumns BIT = NULL,
    @Defaults BIT = NULL
AS
BEGIN
   DECLARE @OrigSchemaName NVARCHAR(MAX);
   DECLARE @OrigTableName NVARCHAR(MAX);
   DECLARE @NewNameOfOriginalTable NVARCHAR(4000);
   DECLARE @OrigTableFullName NVARCHAR(MAX); SET @OrigTableFullName = NULL;
   
   SELECT @OrigSchemaName = @SchemaName,
          @OrigTableName = @TableName
   
   IF(@OrigTableName NOT IN (PARSENAME(@OrigTableName,1),QUOTENAME(PARSENAME(@OrigTableName,1)))
      AND @OrigSchemaName IS NOT NULL)
   BEGIN
     RAISERROR('When @TableName is a multi-part identifier, @SchemaName must be NULL!',16,10);
   END

   SELECT @SchemaName = CleanSchemaName,
          @TableName = CleanTableName
     FROM tSQLt.Private_ResolveFakeTableNamesForBackwardCompatibility(@TableName, @SchemaName);
   
   EXEC tSQLt.Private_ValidateFakeTableParameters @SchemaName,@OrigTableName,@OrigSchemaName;

   EXEC tSQLt.Private_RenameObjectToUniqueName @SchemaName, @TableName, @NewNameOfOriginalTable OUTPUT;

   SELECT @OrigTableFullName = S.base_object_name
     FROM sys.synonyms AS S 
    WHERE S.object_id = OBJECT_ID(@SchemaName + '.' + @NewNameOfOriginalTable);

   IF(@OrigTableFullName IS NOT NULL)
   BEGIN
     IF(COALESCE(OBJECT_ID(@OrigTableFullName,'U'),OBJECT_ID(@OrigTableFullName,'V')) IS NULL)
     BEGIN
       RAISERROR('Cannot fake synonym %s.%s as it is pointing to %s, which is not a table or view!',16,10,@SchemaName,@TableName,@OrigTableFullName);
     END;
   END;
   ELSE
   BEGIN
     SET @OrigTableFullName = @SchemaName + '.' + @NewNameOfOriginalTable;
   END;

   EXEC tSQLt.Private_CreateFakeOfTable @SchemaName, @TableName, @OrigTableFullName, @Identity, @ComputedColumns, @Defaults;

   EXEC tSQLt.Private_MarkFakeTable @SchemaName, @TableName, @NewNameOfOriginalTable;
END


GO

CREATE PROCEDURE tSQLt.Private_CreateProcedureSpy
    @ProcedureObjectId INT,
    @OriginalProcedureName NVARCHAR(MAX),
    @LogTableName NVARCHAR(MAX),
    @CommandToExecute NVARCHAR(MAX) = NULL
AS
BEGIN
    DECLARE @Cmd NVARCHAR(MAX);
    DECLARE @ProcParmList NVARCHAR(MAX),
            @TableColList NVARCHAR(MAX),
            @ProcParmTypeList NVARCHAR(MAX),
            @TableColTypeList NVARCHAR(MAX);
            
    DECLARE @Seperator CHAR(1),
            @ProcParmTypeListSeparater CHAR(1),
            @ParamName sysname,
            @TypeName sysname,
            @IsOutput BIT,
            @IsCursorRef BIT,
            @IsTableType BIT;
            

      
    SELECT @Seperator = '', @ProcParmTypeListSeparater = '', 
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
            SELECT @ProcParmList = @ProcParmList + @Seperator + 
                                   CASE WHEN @IsTableType = 1 
                                     THEN '(SELECT * FROM '+@ParamName+' FOR XML PATH(''row''),TYPE,ROOT('''+STUFF(@ParamName,1,1,'')+'''))' 
                                     ELSE @ParamName 
                                   END, 
                   @TableColList = @TableColList + @Seperator + '[' + STUFF(@ParamName,1,1,'') + ']', 
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
                         
    SELECT @Cmd = 'CREATE TABLE ' + @LogTableName + ' (_id_ int IDENTITY(1,1) PRIMARY KEY CLUSTERED ' + @TableColTypeList + ');';
    EXEC(@Cmd);

    SELECT @Cmd = 'CREATE PROCEDURE ' + @OriginalProcedureName + ' ' + @ProcParmTypeList + 
                  ' AS BEGIN ' + 
                     @InsertStmt + 
                     ISNULL(@CommandToExecute, '') + ';' +
                  ' END;';
    EXEC(@Cmd);

    RETURN 0;
END;


GO

CREATE PROCEDURE tSQLt.SpyProcedure
    @ProcedureName NVARCHAR(MAX),
    @CommandToExecute NVARCHAR(MAX) = NULL
AS
BEGIN
    DECLARE @ProcedureObjectId INT;
    SELECT @ProcedureObjectId = OBJECT_ID(@ProcedureName);

    EXEC tSQLt.Private_ValidateProcedureCanBeUsedWithSpyProcedure @ProcedureName;

    DECLARE @LogTableName NVARCHAR(MAX);
    SELECT @LogTableName = QUOTENAME(OBJECT_SCHEMA_NAME(@ProcedureObjectId)) + '.' + QUOTENAME(OBJECT_NAME(@ProcedureObjectId)+'_SpyProcedureLog');

    EXEC tSQLt.Private_RenameObjectToUniqueNameUsingObjectId @ProcedureObjectId;

    EXEC tSQLt.Private_CreateProcedureSpy @ProcedureObjectId, @ProcedureName, @LogTableName, @CommandToExecute;

    RETURN 0;
END;


GO

GO
CREATE FUNCTION tSQLt.Private_GetCommaSeparatedColumnList (@Table NVARCHAR(MAX), @ExcludeColumn NVARCHAR(MAX))
RETURNS NVARCHAR(MAX)
AS 
BEGIN
  RETURN STUFF((
     SELECT ',' + CASE WHEN system_type_id = TYPE_ID('timestamp') THEN ';TIMESTAMP columns are unsupported!;' ELSE QUOTENAME(name) END 
       FROM sys.columns 
      WHERE object_id = OBJECT_ID(@Table) 
        AND name <> @ExcludeColumn 
      ORDER BY column_id
     FOR XML PATH(''), TYPE).value('.','NVARCHAR(MAX)')
    ,1, 1, '');
        
END;
GO


GO

GO
CREATE PROCEDURE tSQLt.Private_CreateResultTableForCompareTables
 @ResultTable NVARCHAR(MAX),
 @ResultColumn NVARCHAR(MAX),
 @BaseTable NVARCHAR(MAX)
AS
BEGIN
  DECLARE @Cmd NVARCHAR(MAX);
  SET @Cmd = '
     SELECT ''='' AS ' + @ResultColumn + ', Expected.* INTO ' + @ResultTable + ' 
       FROM tSQLt.Private_NullCellTable N 
       LEFT JOIN ' + @BaseTable + ' AS Expected ON N.I <> N.I 
     TRUNCATE TABLE ' + @ResultTable + ';' --Need to insert an actual row to prevent IDENTITY property from transfering (IDENTITY_COL can't be NULLable);
  EXEC(@Cmd);
END
GO


GO

GO
CREATE PROCEDURE tSQLt.Private_ValidateThatAllDataTypesInTableAreSupported
 @ResultTable NVARCHAR(MAX),
 @ColumnList NVARCHAR(MAX)
AS
BEGIN
    BEGIN TRY
      EXEC('DECLARE @EatResult INT; SELECT @EatResult = COUNT(1) FROM ' + @ResultTable + ' GROUP BY ' + @ColumnList + ';');
    END TRY
    BEGIN CATCH
      RAISERROR('The table contains a datatype that is not supported for tSQLt.AssertEqualsTable. Please refer to http://tsqlt.org/user-guide/assertions/assertequalstable/ for a list of unsupported datatypes.',16,10);
    END CATCH
END;
GO


GO

GO
CREATE PROCEDURE tSQLt.Private_CompareTablesFailIfUnequalRowsExists
 @UnequalRowsExist INT,
 @ResultTable NVARCHAR(MAX),
 @ResultColumn NVARCHAR(MAX),
 @ColumnList NVARCHAR(MAX),
 @FailMsg NVARCHAR(MAX)
AS
BEGIN
  IF @UnequalRowsExist > 0
  BEGIN
   DECLARE @TableToTextResult NVARCHAR(MAX);
   DECLARE @OutputColumnList NVARCHAR(MAX);
   SELECT @OutputColumnList = '[_m_],' + @ColumnList;
   EXEC tSQLt.TableToText @TableName = @ResultTable, @OrderBy = @ResultColumn, @PrintOnlyColumnNameAliasList = @OutputColumnList, @txt = @TableToTextResult OUTPUT;
   
   DECLARE @Message NVARCHAR(MAX);
   SELECT @Message = @FailMsg + CHAR(13) + CHAR(10);

    EXEC tSQLt.Fail @Message, @TableToTextResult;
  END;
END
GO


GO

GO
CREATE PROCEDURE tSQLt.Private_CompareTables
    @Expected NVARCHAR(MAX),
    @Actual NVARCHAR(MAX),
    @ResultTable NVARCHAR(MAX),
    @ColumnList NVARCHAR(MAX),
    @MatchIndicatorColumnName NVARCHAR(MAX)
AS
BEGIN
    DECLARE @cmd NVARCHAR(MAX);
    DECLARE @RestoredRowIndexCounterColName NVARCHAR(MAX);
    SET @RestoredRowIndexCounterColName = @MatchIndicatorColumnName + '_RR';
    
    SELECT @cmd = 
    '
    INSERT INTO ' + @ResultTable + ' (' + @MatchIndicatorColumnName + ', ' + @ColumnList + ') 
    SELECT 
      CASE 
        WHEN RestoredRowIndex.'+@RestoredRowIndexCounterColName+' <= CASE WHEN [_{Left}_]<[_{Right}_] THEN [_{Left}_] ELSE [_{Right}_] END
         THEN ''='' 
        WHEN RestoredRowIndex.'+@RestoredRowIndexCounterColName+' <= [_{Left}_] 
         THEN ''<'' 
        ELSE ''>'' 
      END AS ' + @MatchIndicatorColumnName + ', ' + @ColumnList + '
    FROM(
      SELECT SUM([_{Left}_]) AS [_{Left}_], 
             SUM([_{Right}_]) AS [_{Right}_], 
             ' + @ColumnList + ' 
      FROM (
        SELECT 1 AS [_{Left}_], 0[_{Right}_], ' + @ColumnList + '
          FROM ' + @Expected + '
        UNION ALL 
        SELECT 0[_{Left}_], 1 AS [_{Right}_], ' + @ColumnList + ' 
          FROM ' + @Actual + '
      ) AS X 
      GROUP BY ' + @ColumnList + ' 
    ) AS CollapsedRows
    CROSS APPLY (
       SELECT TOP(CASE WHEN [_{Left}_]>[_{Right}_] THEN [_{Left}_] 
                       ELSE [_{Right}_] END) 
              ROW_NUMBER() OVER(ORDER BY(SELECT 1)) 
         FROM (SELECT 1 
                 FROM ' + @Actual + ' UNION ALL SELECT 1 FROM ' + @Expected + ') X(X)
              ) AS RestoredRowIndex(' + @RestoredRowIndexCounterColName + ');';
    
    EXEC (@cmd); --MainGroupQuery
    
    SET @cmd = 'SET @r = 
         CASE WHEN EXISTS(
                  SELECT 1 
                    FROM ' + @ResultTable + 
                 ' WHERE ' + @MatchIndicatorColumnName + ' IN (''<'', ''>'')) 
              THEN 1 ELSE 0 
         END';
    DECLARE @UnequalRowsExist INT;
    EXEC sp_executesql @cmd, N'@r INT OUTPUT',@UnequalRowsExist OUTPUT;
    
    RETURN @UnequalRowsExist;
END;


GO

GO
CREATE TABLE tSQLt.Private_NullCellTable(
  I INT 
);
GO

INSERT INTO tSQLt.Private_NullCellTable (I) VALUES (NULL);
GO

CREATE TRIGGER tSQLt.Private_NullCellTable_StopDeletes ON tSQLt.Private_NullCellTable INSTEAD OF DELETE, INSERT, UPDATE
AS
BEGIN
  RETURN;
END;
GO


GO

CREATE PROCEDURE tSQLt.AssertObjectExists
    @ObjectName NVARCHAR(MAX),
    @Message NVARCHAR(MAX) = ''
AS
BEGIN
    DECLARE @Msg NVARCHAR(MAX);
    IF(@ObjectName LIKE '#%')
    BEGIN
     IF OBJECT_ID('tempdb..'+@ObjectName) IS NULL
     BEGIN
         SELECT @Msg = '''' + COALESCE(@ObjectName, 'NULL') + ''' does not exist';
         EXEC tSQLt.Fail @Message, @Msg;
         RETURN 1;
     END;
    END
    ELSE
    BEGIN
     IF OBJECT_ID(@ObjectName) IS NULL
     BEGIN
         SELECT @Msg = '''' + COALESCE(@ObjectName, 'NULL') + ''' does not exist';
         EXEC tSQLt.Fail @Message, @Msg;
         RETURN 1;
     END;
    END;
    RETURN 0;
END;


GO

CREATE PROCEDURE tSQLt.AssertObjectDoesNotExist
    @ObjectName NVARCHAR(MAX),
    @Message NVARCHAR(MAX) = ''
AS
BEGIN
     DECLARE @Msg NVARCHAR(MAX);
     IF OBJECT_ID(@ObjectName) IS NOT NULL
     OR(@ObjectName LIKE '#%' AND OBJECT_ID('tempdb..'+@ObjectName) IS NOT NULL)
     BEGIN
         SELECT @Msg = '''' + @ObjectName + ''' does exist!';
         EXEC tSQLt.Fail @Message,@Msg;
     END;
END;


GO

GO
CREATE PROCEDURE tSQLt.AssertEqualsString
    @Expected NVARCHAR(MAX),
    @Actual NVARCHAR(MAX),
    @Message NVARCHAR(MAX) = ''
AS
BEGIN
    IF ((@Expected = @Actual) OR (@Actual IS NULL AND @Expected IS NULL))
      RETURN 0;

    DECLARE @Msg NVARCHAR(MAX);
    SELECT @Msg = CHAR(13)+CHAR(10)+
                  'Expected: ' + ISNULL('<'+@Expected+'>', 'NULL') +
                  CHAR(13)+CHAR(10)+
                  'but was : ' + ISNULL('<'+@Actual+'>', 'NULL');
    EXEC tSQLt.Fail @Message, @Msg;
END;
GO


GO

CREATE PROCEDURE tSQLt.AssertEqualsTable
    @Expected NVARCHAR(MAX),
    @Actual NVARCHAR(MAX),
    @Message NVARCHAR(MAX) = NULL,
    @FailMsg NVARCHAR(MAX) = 'Unexpected/missing resultset rows!'
AS
BEGIN

    EXEC tSQLt.AssertObjectExists @Expected;
    EXEC tSQLt.AssertObjectExists @Actual;

    DECLARE @ResultTable NVARCHAR(MAX);    
    DECLARE @ResultColumn NVARCHAR(MAX);    
    DECLARE @ColumnList NVARCHAR(MAX);    
    DECLARE @UnequalRowsExist INT;
    DECLARE @CombinedMessage NVARCHAR(MAX);

    SELECT @ResultTable = tSQLt.Private::CreateUniqueObjectName();
    SELECT @ResultColumn = 'RC_' + @ResultTable;

    EXEC tSQLt.Private_CreateResultTableForCompareTables 
      @ResultTable = @ResultTable,
      @ResultColumn = @ResultColumn,
      @BaseTable = @Expected;
        
    SELECT @ColumnList = tSQLt.Private_GetCommaSeparatedColumnList(@ResultTable, @ResultColumn);

    EXEC tSQLt.Private_ValidateThatAllDataTypesInTableAreSupported @ResultTable, @ColumnList;    
    
    EXEC @UnequalRowsExist = tSQLt.Private_CompareTables 
      @Expected = @Expected,
      @Actual = @Actual,
      @ResultTable = @ResultTable,
      @ColumnList = @ColumnList,
      @MatchIndicatorColumnName = @ResultColumn;
        
    SET @CombinedMessage = ISNULL(@Message + CHAR(13) + CHAR(10),'') + @FailMsg;
    EXEC tSQLt.Private_CompareTablesFailIfUnequalRowsExists 
      @UnequalRowsExist = @UnequalRowsExist,
      @ResultTable = @ResultTable,
      @ResultColumn = @ResultColumn,
      @ColumnList = @ColumnList,
      @FailMsg = @CombinedMessage;   
END;


GO

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


GO

GO
CREATE PROCEDURE [tSQLt].[AssertLike] 
  @ExpectedPattern NVARCHAR(MAX),
  @Actual NVARCHAR(MAX),
  @Message NVARCHAR(MAX) = ''
AS
BEGIN
  IF (LEN(@ExpectedPattern) > 4000)
  BEGIN
    RAISERROR ('@ExpectedPattern may not exceed 4000 characters.', 16, 10);
  END;

  IF ((@Actual LIKE @ExpectedPattern) OR (@Actual IS NULL AND @ExpectedPattern IS NULL))
  BEGIN
    RETURN 0;
  END

  DECLARE @Msg NVARCHAR(MAX);
  SELECT @Msg = CHAR(13) + CHAR(10) + 'Expected: <' + ISNULL(@ExpectedPattern, 'NULL') + '>' +
                CHAR(13) + CHAR(10) + ' but was: <' + ISNULL(@Actual, 'NULL') + '>';
  EXEC tSQLt.Fail @Message, @Msg;
END;
GO


GO

CREATE PROCEDURE tSQLt.AssertNotEquals
    @Expected SQL_VARIANT,
    @Actual SQL_VARIANT,
    @Message NVARCHAR(MAX) = ''
AS
BEGIN
  IF (@Expected = @Actual)
  OR (@Expected IS NULL AND @Actual IS NULL)
  BEGIN
    DECLARE @Msg NVARCHAR(MAX);
    SET @Msg = 'Expected actual value to not ' + 
               COALESCE('equal <' + tSQLt.Private_SqlVariantFormatter(@Expected)+'>', 'be NULL') + 
               '.';
    EXEC tSQLt.Fail @Message,@Msg;
  END;
  RETURN 0;
END;


GO

CREATE FUNCTION tSQLt.Private_SqlVariantFormatter(@Value SQL_VARIANT)
RETURNS NVARCHAR(MAX)
AS
BEGIN
  RETURN CASE UPPER(CAST(SQL_VARIANT_PROPERTY(@Value,'BaseType')AS sysname))
           WHEN 'FLOAT' THEN CONVERT(NVARCHAR(MAX),@Value,2)
           WHEN 'REAL' THEN CONVERT(NVARCHAR(MAX),@Value,1)
           WHEN 'MONEY' THEN CONVERT(NVARCHAR(MAX),@Value,2)
           WHEN 'SMALLMONEY' THEN CONVERT(NVARCHAR(MAX),@Value,2)
           WHEN 'DATE' THEN CONVERT(NVARCHAR(MAX),@Value,126)
           WHEN 'DATETIME' THEN CONVERT(NVARCHAR(MAX),@Value,126)
           WHEN 'DATETIME2' THEN CONVERT(NVARCHAR(MAX),@Value,126)
           WHEN 'DATETIMEOFFSET' THEN CONVERT(NVARCHAR(MAX),@Value,126)
           WHEN 'SMALLDATETIME' THEN CONVERT(NVARCHAR(MAX),@Value,126)
           WHEN 'TIME' THEN CONVERT(NVARCHAR(MAX),@Value,126)
           WHEN 'BINARY' THEN CONVERT(NVARCHAR(MAX),@Value,1)
           WHEN 'VARBINARY' THEN CONVERT(NVARCHAR(MAX),@Value,1)
           ELSE CAST(@Value AS NVARCHAR(MAX))
         END;
END


GO

CREATE PROCEDURE tSQLt.AssertEmptyTable
  @TableName NVARCHAR(MAX),
  @Message NVARCHAR(MAX) = ''
AS
BEGIN
  EXEC tSQLt.AssertObjectExists @TableName;

  DECLARE @FullName NVARCHAR(MAX);
  IF(OBJECT_ID(@TableName) IS NULL AND OBJECT_ID('tempdb..'+@TableName) IS NOT NULL)
  BEGIN
    SET @FullName = CASE WHEN LEFT(@TableName,1) = '[' THEN @TableName ELSE QUOTENAME(@TableName)END;
  END;
  ELSE
  BEGIN
    SET @FullName = tSQLt.Private_GetQuotedFullName(OBJECT_ID(@TableName));
  END;

  DECLARE @cmd NVARCHAR(MAX);
  DECLARE @exists INT;
  SET @cmd = 'SELECT @exists = CASE WHEN EXISTS(SELECT 1 FROM '+@FullName+') THEN 1 ELSE 0 END;'
  EXEC sp_executesql @cmd,N'@exists INT OUTPUT', @exists OUTPUT;
  
  IF(@exists = 1)
  BEGIN
    DECLARE @TableToText NVARCHAR(MAX);
    EXEC tSQLt.TableToText @TableName = @FullName,@txt = @TableToText OUTPUT;
    DECLARE @Msg NVARCHAR(MAX);
    SET @Msg = @FullName + ' was not empty:' + CHAR(13) + CHAR(10)+ @TableToText;
    EXEC tSQLt.Fail @Message,@Msg;
  END
END


GO

CREATE PROCEDURE tSQLt.ApplyTrigger
  @TableName NVARCHAR(MAX),
  @TriggerName NVARCHAR(MAX)
AS
BEGIN
  DECLARE @OrgTableObjectId INT;
  SELECT @OrgTableObjectId = OrgTableObjectId FROM tSQLt.Private_GetOriginalTableInfo(OBJECT_ID(@TableName)) orgTbl
  IF(@OrgTableObjectId IS NULL)
  BEGIN
    RAISERROR('%s does not exist or was not faked by tSQLt.FakeTable.', 16, 10, @TableName);
  END;
  
  DECLARE @FullTriggerName NVARCHAR(MAX);
  DECLARE @TriggerObjectId INT;
  SELECT @FullTriggerName = QUOTENAME(SCHEMA_NAME(schema_id))+'.'+QUOTENAME(name), @TriggerObjectId = object_id
  FROM sys.objects WHERE PARSENAME(@TriggerName,1) = name AND parent_object_id = @OrgTableObjectId;
  
  DECLARE @TriggerCode NVARCHAR(MAX);
  SELECT @TriggerCode = m.definition
    FROM sys.sql_modules m
   WHERE m.object_id = @TriggerObjectId;
  
  IF (@TriggerCode IS NULL)
  BEGIN
    RAISERROR('%s is not a trigger on %s', 16, 10, @TriggerName, @TableName);
  END;
 
  EXEC tSQLt.RemoveObject @FullTriggerName;
  
  EXEC(@TriggerCode);
END;


GO

GO
CREATE PROCEDURE tSQLt.Private_ValidateObjectsCompatibleWithFakeFunction
  @FunctionName NVARCHAR(MAX),
  @FakeFunctionName NVARCHAR(MAX),
  @FunctionObjectId INT OUTPUT,
  @FakeFunctionObjectId INT OUTPUT,
  @IsScalarFunction BIT OUTPUT
AS
BEGIN
  SET @FunctionObjectId = OBJECT_ID(@FunctionName);
  SET @FakeFunctionObjectId = OBJECT_ID(@FakeFunctionName);

  IF(@FunctionObjectId IS NULL)
  BEGIN
    RAISERROR('%s does not exist!',16,10,@FunctionName);
  END;
  IF(@FakeFunctionObjectId IS NULL)
  BEGIN
    RAISERROR('%s does not exist!',16,10,@FakeFunctionName);
  END;
  
  DECLARE @FunctionType CHAR(2);
  DECLARE @FakeFunctionType CHAR(2);
  SELECT @FunctionType = type FROM sys.objects WHERE object_id = @FunctionObjectId;
  SELECT @FakeFunctionType = type FROM sys.objects WHERE object_id = @FakeFunctionObjectId;

  IF((@FunctionType IN('FN','FS') AND @FakeFunctionType NOT IN('FN','FS'))
     OR
     (@FunctionType IN('TF','IF','FT') AND @FakeFunctionType NOT IN('TF','IF','FT'))
     OR
     (@FunctionType NOT IN('FN','FS','TF','IF','FT'))
     )    
  BEGIN
    RAISERROR('Both parameters must contain the name of either scalar or table valued functions!',16,10);
  END;
  
  SET @IsScalarFunction = CASE WHEN @FunctionType IN('FN','FS') THEN 1 ELSE 0 END;
  
  IF(EXISTS(SELECT 1 
              FROM sys.parameters AS P
             WHERE P.object_id IN(@FunctionObjectId,@FakeFunctionObjectId)
             GROUP BY P.name, P.max_length, P.precision, P.scale, P.parameter_id
            HAVING COUNT(1) <> 2
           ))
  BEGIN
    RAISERROR('Parameters of both functions must match! (This includes the return type for scalar functions.)',16,10);
  END; 
END;
GO
  


GO

GO
CREATE PROCEDURE tSQLt.Private_CreateFakeFunction
  @FunctionName NVARCHAR(MAX),
  @FakeFunctionName NVARCHAR(MAX),
  @FunctionObjectId INT,
  @FakeFunctionObjectId INT,
  @IsScalarFunction BIT
AS
BEGIN
  DECLARE @ReturnType NVARCHAR(MAX);
  SELECT @ReturnType = T.TypeName
    FROM sys.parameters AS P
   CROSS APPLY tSQLt.Private_GetFullTypeName(P.user_type_id,P.max_length,P.precision,P.scale,NULL) AS T
   WHERE P.object_id = @FunctionObjectId
     AND P.parameter_id = 0;
     
  DECLARE @ParameterList NVARCHAR(MAX);
  SELECT @ParameterList = COALESCE(
     STUFF((SELECT ','+P.name+' '+T.TypeName+CASE WHEN T.IsTableType = 1 THEN ' READONLY' ELSE '' END
              FROM sys.parameters AS P
             CROSS APPLY tSQLt.Private_GetFullTypeName(P.user_type_id,P.max_length,P.precision,P.scale,NULL) AS T
             WHERE P.object_id = @FunctionObjectId
               AND P.parameter_id > 0
             ORDER BY P.parameter_id
               FOR XML PATH(''),TYPE
           ).value('.','NVARCHAR(MAX)'),1,1,''),'');
           
  DECLARE @ParameterCallList NVARCHAR(MAX);
  SELECT @ParameterCallList = COALESCE(
     STUFF((SELECT ','+P.name
              FROM sys.parameters AS P
             CROSS APPLY tSQLt.Private_GetFullTypeName(P.user_type_id,P.max_length,P.precision,P.scale,NULL) AS T
             WHERE P.object_id = @FunctionObjectId
               AND P.parameter_id > 0
             ORDER BY P.parameter_id
               FOR XML PATH(''),TYPE
           ).value('.','NVARCHAR(MAX)'),1,1,''),'');


  IF(@IsScalarFunction = 1)
  BEGIN
    EXEC('CREATE FUNCTION '+@FunctionName+'('+@ParameterList+') RETURNS '+@ReturnType+' AS BEGIN RETURN '+@FakeFunctionName+'('+@ParameterCallList+');END;'); 
  END
  ELSE
  BEGIN
    EXEC('CREATE FUNCTION '+@FunctionName+'('+@ParameterList+') RETURNS TABLE AS RETURN SELECT * FROM '+@FakeFunctionName+'('+@ParameterCallList+');'); 
  END;
END;
GO


GO

GO
CREATE PROCEDURE tSQLt.FakeFunction
  @FunctionName NVARCHAR(MAX),
  @FakeFunctionName NVARCHAR(MAX)
AS
BEGIN
  DECLARE @FunctionObjectId INT;
  DECLARE @FakeFunctionObjectId INT;
  DECLARE @IsScalarFunction BIT;

  EXEC tSQLt.Private_ValidateObjectsCompatibleWithFakeFunction 
               @FunctionName = @FunctionName,
               @FakeFunctionName = @FakeFunctionName,
               @FunctionObjectId = @FunctionObjectId OUT,
               @FakeFunctionObjectId = @FakeFunctionObjectId OUT,
               @IsScalarFunction = @IsScalarFunction OUT;

  EXEC tSQLt.RemoveObject @ObjectName = @FunctionName;

  EXEC tSQLt.Private_CreateFakeFunction 
               @FunctionName = @FunctionName,
               @FakeFunctionName = @FakeFunctionName,
               @FunctionObjectId = @FunctionObjectId,
               @FakeFunctionObjectId = @FakeFunctionObjectId,
               @IsScalarFunction = @IsScalarFunction;

END;
GO


GO

CREATE PROCEDURE tSQLt.RenameClass
   @SchemaName NVARCHAR(MAX),
   @NewSchemaName NVARCHAR(MAX)
AS
BEGIN
  DECLARE @MigrateObjectsCommand NVARCHAR(MAX);

  SELECT @NewSchemaName = PARSENAME(@NewSchemaName, 1),
         @SchemaName = PARSENAME(@SchemaName, 1);

  EXEC tSQLt.NewTestClass @NewSchemaName;

  SELECT @MigrateObjectsCommand = (
    SELECT Cmd AS [text()] FROM (
    SELECT 'ALTER SCHEMA ' + QUOTENAME(@NewSchemaName) + ' TRANSFER ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(name) + ';' AS Cmd
      FROM sys.objects
     WHERE schema_id = SCHEMA_ID(@SchemaName)
       AND type NOT IN ('PK', 'F')
    UNION ALL 
    SELECT 'ALTER SCHEMA ' + QUOTENAME(@NewSchemaName) + ' TRANSFER XML SCHEMA COLLECTION::' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(name) + ';' AS Cmd
      FROM sys.xml_schema_collections
     WHERE schema_id = SCHEMA_ID(@SchemaName)
    UNION ALL 
    SELECT 'ALTER SCHEMA ' + QUOTENAME(@NewSchemaName) + ' TRANSFER TYPE::' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(name) + ';' AS Cmd
      FROM sys.types
     WHERE schema_id = SCHEMA_ID(@SchemaName)
    ) AS Cmds
       FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)');

  EXEC (@MigrateObjectsCommand);

  EXEC tSQLt.DropClass @SchemaName;
END;


GO

GO
CREATE TABLE [tSQLt].[Private_AssertEqualsTableSchema_Actual]
(
  name NVARCHAR(256) NULL,
  [RANK(column_id)] INT NULL,
  system_type_id NVARCHAR(MAX) NULL,
  user_type_id NVARCHAR(MAX) NULL,
  max_length SMALLINT NULL,
  precision TINYINT NULL,
  scale TINYINT NULL,
  collation_name NVARCHAR(256) NULL,
  is_nullable BIT NULL,
  is_identity BIT NULL
);
GO
EXEC('
  SET NOCOUNT ON;
  SELECT TOP(0) * 
    INTO tSQLt.Private_AssertEqualsTableSchema_Expected
    FROM tSQLt.Private_AssertEqualsTableSchema_Actual AS AETSA;
');
GO


GO

GO
CREATE PROCEDURE tSQLt.AssertEqualsTableSchema
    @Expected NVARCHAR(MAX),
    @Actual NVARCHAR(MAX),
    @Message NVARCHAR(MAX) = NULL
AS
BEGIN
  INSERT INTO tSQLt.Private_AssertEqualsTableSchema_Expected([RANK(column_id)],name,system_type_id,user_type_id,max_length,precision,scale,collation_name,is_nullable)
  SELECT 
      RANK()OVER(ORDER BY C.column_id),
      C.name,
      CAST(C.system_type_id AS NVARCHAR(MAX))+QUOTENAME(TS.name) system_type_id,
      CAST(C.user_type_id AS NVARCHAR(MAX))+CASE WHEN TU.system_type_id<> TU.user_type_id THEN QUOTENAME(SCHEMA_NAME(TU.schema_id))+'.' ELSE '' END + QUOTENAME(TU.name) user_type_id,
      C.max_length,
      C.precision,
      C.scale,
      C.collation_name,
      C.is_nullable
    FROM sys.columns AS C
    JOIN sys.types AS TS
      ON C.system_type_id = TS.user_type_id
    JOIN sys.types AS TU
      ON C.user_type_id = TU.user_type_id
   WHERE C.object_id = OBJECT_ID(@Expected);
  INSERT INTO tSQLt.Private_AssertEqualsTableSchema_Actual([RANK(column_id)],name,system_type_id,user_type_id,max_length,precision,scale,collation_name,is_nullable)
  SELECT 
      RANK()OVER(ORDER BY C.column_id),
      C.name,
      CAST(C.system_type_id AS NVARCHAR(MAX))+QUOTENAME(TS.name) system_type_id,
      CAST(C.user_type_id AS NVARCHAR(MAX))+CASE WHEN TU.system_type_id<> TU.user_type_id THEN QUOTENAME(SCHEMA_NAME(TU.schema_id))+'.' ELSE '' END + QUOTENAME(TU.name) user_type_id,
      C.max_length,
      C.precision,
      C.scale,
      C.collation_name,
      C.is_nullable
    FROM sys.columns AS C
    JOIN sys.types AS TS
      ON C.system_type_id = TS.user_type_id
    JOIN sys.types AS TU
      ON C.user_type_id = TU.user_type_id
   WHERE C.object_id = OBJECT_ID(@Actual);
  
  EXEC tSQLt.AssertEqualsTable 'tSQLt.Private_AssertEqualsTableSchema_Expected','tSQLt.Private_AssertEqualsTableSchema_Actual',@Message=@Message,@FailMsg='Unexpected/missing column(s)';  
END;
GO


GO

GO
IF NOT(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(MAX)) LIKE '9.%')
BEGIN
  EXEC('CREATE TYPE tSQLt.AssertStringTable AS TABLE(value NVARCHAR(MAX));');
END;
GO


GO

GO
IF NOT(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(MAX)) LIKE '9.%')
BEGIN
EXEC('
CREATE PROCEDURE tSQLt.AssertStringIn
  @Expected tSQLt.AssertStringTable READONLY,
  @Actual NVARCHAR(MAX),
  @Message NVARCHAR(MAX) = ''''
AS
BEGIN
  IF(NOT EXISTS(SELECT 1 FROM @Expected WHERE value = @Actual))
  BEGIN
    DECLARE @ExpectedMessage NVARCHAR(MAX);
    SELECT value INTO #ExpectedSet FROM @Expected;
    EXEC tSQLt.TableToText @TableName = ''#ExpectedSet'', @OrderBy = ''value'',@txt = @ExpectedMessage OUTPUT;
    SET @ExpectedMessage = ISNULL(''<''+@Actual+''>'',''NULL'')+CHAR(13)+CHAR(10)+''is not in''+CHAR(13)+CHAR(10)+@ExpectedMessage;
    EXEC tSQLt.Fail @Message, @ExpectedMessage;
  END;
END;
');
END;
GO


GO

GO
CREATE PROCEDURE tSQLt.Reset
AS
BEGIN
  EXEC tSQLt.Private_ResetNewTestClassList;
END;
GO


GO

GO
SET NOCOUNT ON;
DECLARE @ver NVARCHAR(MAX); 
DECLARE @match INT; 
SELECT @ver = '| tSQLt Version: ' + I.Version,
       @match = CASE WHEN I.Version = I.ClrVersion THEN 1 ELSE 0 END
  FROM tSQLt.Info() AS I;
SET @ver = @ver+SPACE(42-LEN(@ver))+'|';
 
RAISERROR('',0,1)WITH NOWAIT;
RAISERROR('+-----------------------------------------+',0,1)WITH NOWAIT;
RAISERROR('|                                         |',0,1)WITH NOWAIT;
RAISERROR('| Thank you for using tSQLt.              |',0,1)WITH NOWAIT;
RAISERROR('|                                         |',0,1)WITH NOWAIT;
RAISERROR(@ver,0,1)WITH NOWAIT;
IF(@match = 0)
BEGIN
  RAISERROR('|                                         |',0,1)WITH NOWAIT;
  RAISERROR('| ERROR: mismatching CLR Version.         |',0,1)WITH NOWAIT;
  RAISERROR('| Please download a new version of tSQLt. |',0,1)WITH NOWAIT;
END
RAISERROR('|                                         |',0,1)WITH NOWAIT;
RAISERROR('+-----------------------------------------+',0,1)WITH NOWAIT;


GO



GO

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
IF OBJECT_ID('Accelerator.IsExperimentReady') IS NOT NULL DROP FUNCTION Accelerator.IsExperimentReady;
GO

CREATE FUNCTION Accelerator.IsExperimentReady()
RETURNS BIT
AS
BEGIN 
  DECLARE @NumParticles INT;
  
  SELECT @NumParticles = COUNT(1) FROM Accelerator.Particle;
  
  IF @NumParticles > 2
    RETURN 1;

  RETURN 0;
END;
GO


IF OBJECT_ID('Accelerator.GetParticlesInRectangle') IS NOT NULL DROP FUNCTION Accelerator.GetParticlesInRectangle;
GO

CREATE FUNCTION Accelerator.GetParticlesInRectangle(
  @X1 DECIMAL(10,2),
  @Y1 DECIMAL(10,2),
  @X2 DECIMAL(10,2),
  @Y2 DECIMAL(10,2)
)
RETURNS TABLE
AS RETURN (
  SELECT Id, X, Y, Value 
    FROM Accelerator.Particle
   WHERE X > @X1 AND X < @X2
         AND
         Y > @Y1 AND Y < @Y2
);
GO

IF OBJECT_ID('Accelerator.SendHiggsBosonDiscoveryEmail') IS NOT NULL DROP PROCEDURE Accelerator.SendHiggsBosonDiscoveryEmail;
GO

CREATE PROCEDURE Accelerator.SendHiggsBosonDiscoveryEmail
  @EmailAddress NVARCHAR(MAX)
AS
BEGIN
  RAISERROR('Not Implemented - yet',16,10);
END;
GO

IF OBJECT_ID('Accelerator.AlertParticleDiscovered') IS NOT NULL DROP PROCEDURE Accelerator.AlertParticleDiscovered;
GO

CREATE PROCEDURE Accelerator.AlertParticleDiscovered
  @ParticleDiscovered NVARCHAR(MAX)
AS
BEGIN
  IF @ParticleDiscovered = 'Higgs Boson'
  BEGIN
    EXEC Accelerator.SendHiggsBosonDiscoveryEmail 'particle-discovery@new-era-particles.tsqlt.org';
  END;
END;
GO

IF OBJECT_ID('Accelerator.GetStatusMessage') IS NOT NULL DROP FUNCTION Accelerator.GetStatusMessage;
GO

CREATE FUNCTION Accelerator.GetStatusMessage()
  RETURNS NVARCHAR(MAX)
AS
BEGIN
  DECLARE @NumParticles INT;
  SELECT @NumParticles = COUNT(1) FROM Accelerator.Particle;
  RETURN 'The Accelerator is prepared with ' + CAST(@NumParticles AS NVARCHAR(MAX)) + ' particles.';
END;
GO

IF OBJECT_ID('Accelerator.FK_ParticleColor') IS NOT NULL ALTER TABLE Accelerator.Particle DROP CONSTRAINT FK_ParticleColor;
GO

ALTER TABLE Accelerator.Particle ADD CONSTRAINT FK_ParticleColor FOREIGN KEY (ColorId) REFERENCES Accelerator.Color(Id);
GO


GO

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
EXEC tSQLt.NewTestClass 'AcceleratorTests';
GO

CREATE PROCEDURE 
  AcceleratorTests.[test ready for experimentation if 2 particles]
AS
BEGIN
  --Assemble: Fake the Particle table to make sure 
  --          it is empty and has no constraints
  EXEC tSQLt.FakeTable 'Accelerator.Particle';
  INSERT INTO Accelerator.Particle (Id) VALUES (1);
  INSERT INTO Accelerator.Particle (Id) VALUES (2);
  
  DECLARE @Ready BIT;
  
  --Act: Call the IsExperimentReady function
  SELECT @Ready = Accelerator.IsExperimentReady();
  
  --Assert: Check that 1 is returned from IsExperimentReady
  EXEC tSQLt.AssertEquals 1, @Ready;
  
END;
GO

CREATE PROCEDURE AcceleratorTests.[test we are not ready for experimentation if there is only 1 particle]
AS
BEGIN
  --Assemble: Fake the Particle table to make sure it is empty and has no constraints
  EXEC tSQLt.FakeTable 'Accelerator.Particle';
  INSERT INTO Accelerator.Particle (Id) VALUES (1);
  
  DECLARE @Ready BIT;
  
  --Act: Call the IsExperimentReady function
  SELECT @Ready = Accelerator.IsExperimentReady();
  
  --Assert: Check that 0 is returned from IsExperimentReady
  EXEC tSQLt.AssertEquals 0, @Ready;
  
END;
GO

CREATE PROCEDURE AcceleratorTests.[test no particles are in a rectangle when there are no particles in the table]
AS
BEGIN
  --Assemble: Fake the Particle table to make sure it is empty
  EXEC tSQLt.FakeTable 'Accelerator.Particle';

  DECLARE @ParticlesInRectangle INT;
  
  --Act: Call the  GetParticlesInRectangle Table-Valued Function and capture the number of rows it returns.
  SELECT @ParticlesInRectangle = COUNT(1)
    FROM Accelerator.GetParticlesInRectangle(0.0, 0.0, 1.0, 1.0);
  
  --Assert: Check that 0 rows were returned
  EXEC tSQLt.AssertEquals 0, @ParticlesInRectangle;
END;
GO

CREATE PROCEDURE AcceleratorTests.[test a particle within the rectangle is returned]
AS
BEGIN
  --Assemble: Fake the Particle table to make sure it is empty and that constraints will not be a problem
  EXEC tSQLt.FakeTable 'Accelerator.Particle';
  --          Put a test particle into the table
  INSERT INTO Accelerator.Particle (Id, X, Y) VALUES (1, 0.5, 0.5);
  
  --Act: Call the  GetParticlesInRectangle Table-Valued Function and capture the Id column into the #Actual temp table
  SELECT Id
    INTO #Actual
    FROM Accelerator.GetParticlesInRectangle(0.0, 0.0, 1.0, 1.0);
  
  --Assert: Create an empty #Expected temp table that has the same structure as the #Actual table
  SELECT TOP(0) *
    INTO #Expected
    FROM #Actual;
  
  --        A single row with an Id value of 1 is expected
  INSERT INTO #Expected (Id) VALUES (1);

  --        Compare the data in the #Expected and #Actual tables
  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE AcceleratorTests.[test a particle within the rectangle is returned with an Id, Point Location and Value]
AS
BEGIN
  --Assemble: Fake the Particle table to make sure it is empty and that constraints will not be a problem
  EXEC tSQLt.FakeTable 'Accelerator.Particle';
  --          Put a test particle into the table
  INSERT INTO Accelerator.Particle (Id, X, Y, Value) VALUES (1, 0.5, 0.5, 'MyValue');
  
  --Act: Call the  GetParticlesInRectangle Table-Valued Function and capture the relevant columns into the #Actual temp table
  SELECT Id, X, Y, Value
    INTO #Actual
    FROM Accelerator.GetParticlesInRectangle(0.0, 0.0, 1.0, 1.0);
    
  --Assert: Create an empty #Expected temp table that has the same structure as the #Actual table
  SELECT TOP(0) *
    INTO #Expected
    FROM #Actual;
    
  --        A single row with the expected data is inserted into the #Expected table
  INSERT INTO #Expected (Id, X, Y, Value) VALUES (1, 0.5, 0.5, 'MyValue');

  --        Compare the data in the #Expected and #Actual tables
  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE AcceleratorTests.[test a particle is included only if it fits inside the boundaries of the rectangle]
AS
BEGIN
  --Assemble: Fake the Particle table to make sure it is empty and that constraints will not be a problem
  EXEC tSQLt.FakeTable 'Accelerator.Particle';
  --          Populate the Particle table with rows that hug the rectangle boundaries
  INSERT INTO Accelerator.Particle (Id, X, Y) VALUES ( 1, -0.01,  0.50);
  INSERT INTO Accelerator.Particle (Id, X, Y) VALUES ( 2,  0.00,  0.50);
  INSERT INTO Accelerator.Particle (Id, X, Y) VALUES ( 3,  0.01,  0.50);
  INSERT INTO Accelerator.Particle (Id, X, Y) VALUES ( 4,  0.99,  0.50);
  INSERT INTO Accelerator.Particle (Id, X, Y) VALUES ( 5,  1.00,  0.50);
  INSERT INTO Accelerator.Particle (Id, X, Y) VALUES ( 6,  1.01,  0.50);
  INSERT INTO Accelerator.Particle (Id, X, Y) VALUES ( 7,  0.50, -0.01);
  INSERT INTO Accelerator.Particle (Id, X, Y) VALUES ( 8,  0.50,  0.00);
  INSERT INTO Accelerator.Particle (Id, X, Y) VALUES ( 9,  0.50,  0.01);
  INSERT INTO Accelerator.Particle (Id, X, Y) VALUES (10,  0.50,  0.99);
  INSERT INTO Accelerator.Particle (Id, X, Y) VALUES (11,  0.50,  1.00);
  INSERT INTO Accelerator.Particle (Id, X, Y) VALUES (12,  0.50,  1.01);
  
  --Act: Call the  GetParticlesInRectangle Table-Valued Function and capture the relevant columns into the #Actual temp table
  SELECT Id, X, Y
    INTO #Actual
    FROM Accelerator.GetParticlesInRectangle(0.0, 0.0, 1.0, 1.0);
    
  --Assert: Create an empty #Expected temp table that has the same structure as the #Actual table
  SELECT TOP(0) *
    INTO #Expected
    FROM #Actual;
    
  --        The expected data is inserted into the #Expected table
  INSERT INTO #Expected (Id, X, Y) VALUES (3,  0.01, 0.50);
  INSERT INTO #Expected (Id, X, Y) VALUES (4,  0.99, 0.50);
  INSERT INTO #Expected (Id, X, Y) VALUES (9,  0.50, 0.01);
  INSERT INTO #Expected (Id, X, Y) VALUES (10, 0.50, 0.99);
    
  --        Compare the data in the #Expected and #Actual tables
  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE AcceleratorTests.[test email is sent if we detected a higgs-boson]
AS
BEGIN
  --Assemble: Replace the SendHiggsBosonDiscoveryEmail with a spy. 
  EXEC tSQLt.SpyProcedure 'Accelerator.SendHiggsBosonDiscoveryEmail';
  
  --Act: Call the AlertParticleDiscovered procedure - this is the procedure being tested.
  EXEC Accelerator.AlertParticleDiscovered 'Higgs Boson';
  
  --Assert: A spy records the parameters passed to the procedure in a *_SpyProcedureLog table. 
  --        Copy the EmailAddress parameter values that the spy recorded into the #Actual temp table.
  SELECT EmailAddress
    INTO #Actual
    FROM Accelerator.SendHiggsBosonDiscoveryEmail_SpyProcedureLog;
    
  --        Create an empty #Expected temp table that has the same structure as the #Actual table
  SELECT TOP(0) * INTO #Expected FROM #Actual;
  
  --        Add a row to the #Expected table with the expected email address.
  INSERT INTO #Expected 
    (EmailAddress)
  VALUES 
    ('particle-discovery@new-era-particles.tsqlt.org');

  --        Compare the data in the #Expected and #Actual tables
  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO


CREATE PROCEDURE AcceleratorTests.[test email is not sent if we detected something other than higgs-boson]
AS
BEGIN
  --Assemble: Replace the SendHiggsBosonDiscoveryEmail with a spy. 
  EXEC tSQLt.SpyProcedure 'Accelerator.SendHiggsBosonDiscoveryEmail';
  
  --Act: Call the AlertParticleDiscovered procedure - this is the procedure being tested.
  EXEC Accelerator.AlertParticleDiscovered 'Proton';
  
  --Assert: A spy records the parameters passed to the procedure in a *_SpyProcedureLog table. 
  --        Copy the EmailAddress parameter values that the spy recorded into the #Actual temp table.
  SELECT EmailAddress
    INTO #Actual
    FROM Accelerator.SendHiggsBosonDiscoveryEmail_SpyProcedureLog;
    
  --        Create an empty #Expected temp table that has the same structure as the #Actual table
  SELECT TOP(0) * INTO #Expected FROM #Actual;
  
  --        The SendHiggsBosonDiscoveryEmail should not have been called. So the #Expected table is empty.
  
  --        Compare the data in the #Expected and #Actual tables
  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';

END;
GO

CREATE PROCEDURE AcceleratorTests.[test status message includes the number of particles]
AS
BEGIN
  --Assemble: Fake the Particle table to make sure it is empty and that constraints will not be a problem
  EXEC tSQLt.FakeTable 'Accelerator.Particle';
  --          Put 3 test particles into the table
  INSERT INTO Accelerator.Particle (Id) VALUES (1);
  INSERT INTO Accelerator.Particle (Id) VALUES (2);
  INSERT INTO Accelerator.Particle (Id) VALUES (3);

  --Act: Call the GetStatusMessageFunction
  DECLARE @StatusMessage NVARCHAR(MAX);
  SELECT @StatusMessage = Accelerator.GetStatusMessage();

  --Assert: Make sure the status message is correct
  EXEC tSQLt.AssertEqualsString 'The Accelerator is prepared with 3 particles.', @StatusMessage;
END;
GO

CREATE PROCEDURE AcceleratorTests.[test foreign key violated if Particle color is not in Color table]
AS
BEGIN
  --Assemble: Fake the Particle and the Color tables to make sure they are empty and other 
  --          constraints will not be a problem
  EXEC tSQLt.FakeTable 'Accelerator.Particle';
  EXEC tSQLt.FakeTable 'Accelerator.Color';
  --          Put the FK_ParticleColor foreign key constraint back onto the Particle table
  --          so we can test it.
  EXEC tSQLt.ApplyConstraint 'Accelerator.Particle', 'FK_ParticleColor';
  
  --Act: Attempt to insert a record into the Particle table without any records in Color table.
  --     We expect an exception to happen, so we capture the ERROR_MESSAGE()
  DECLARE @err NVARCHAR(MAX); SET @err = '<No Exception Thrown!>';
  BEGIN TRY
    INSERT INTO Accelerator.Particle (ColorId) VALUES (7);
  END TRY
  BEGIN CATCH
    SET @err = ERROR_MESSAGE();
  END CATCH
  
  --Assert: Check that trying to insert the record resulted in the FK_ParticleColor foreign key being violated.
  --        If no exception happened the value of @err is still '<No Exception Thrown>'.
  IF (@err NOT LIKE '%FK_ParticleColor%')
  BEGIN
    EXEC tSQLt.Fail 'Expected exception (FK_ParticleColor exception) not thrown. Instead:',@err;
  END;
END;
GO

CREATE PROC AcceleratorTests.[test foreign key is not violated if Particle color is in Color table]
AS
BEGIN
  --Assemble: Fake the Particle and the Color tables to make sure they are empty and other 
  --          constraints will not be a problem
  EXEC tSQLt.FakeTable 'Accelerator.Particle';
  EXEC tSQLt.FakeTable 'Accelerator.Color';
  --          Put the FK_ParticleColor foreign key constraint back onto the Particle table
  --          so we can test it.
  EXEC tSQLt.ApplyConstraint 'Accelerator.Particle', 'FK_ParticleColor';
  
  --          Insert a record into the Color table. We'll reference this Id again in the Act
  --          step.
  INSERT INTO Accelerator.Color (Id) VALUES (7);
  
  --Act: Attempt to insert a record into the Particle table.
  INSERT INTO Accelerator.Particle (ColorId) VALUES (7);
  
  --Assert: If any exception was thrown, the test will automatically fail. Therefore, the test
  --        passes as long as there was no exception. This is one of the VERY rare cases when
  --        at test case does not have an Assert step.
END
GO


GO

