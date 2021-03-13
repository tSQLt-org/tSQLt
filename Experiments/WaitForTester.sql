USE master;
GO
IF OBJECT_ID('tempdb..#ForceDropDatabaseAndLogin') IS NOT NULL DROP PROCEDURE #ForceDropDatabaseAndLogin;
GO
CREATE PROCEDURE #ForceDropDatabaseAndLogin
@db_name NVARCHAR(MAX)
AS
BEGIN
  IF(DB_ID(@db_name)IS NOT NULL)
  BEGIN
    BEGIN TRY
    EXEC('
    USE master;
    ALTER DATABASE '+@db_name+' SET ONLINE WITH ROLLBACK IMMEDIATE;
    ALTER DATABASE '+@db_name+' SET RESTRICTED_USER WITH ROLLBACK IMMEDIATE;
    USE '+@db_name+';
    ALTER DATABASE '+@db_name+' SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    ');
    END TRY BEGIN CATCH END CATCH;
    EXEC('
    USE master;
    DROP DATABASE '+@db_name+';
    ');
    IF SUSER_SID(@db_name) IS NOT NULL EXEC('DROP LOGIN '+@db_name+';');
  END;
END
GO
IF OBJECT_ID('tempdb..#CreateDatabaseWithOwningLogin') IS NOT NULL DROP PROCEDURE #CreateDatabaseWithOwningLogin;
GO
CREATE PROCEDURE #CreateDatabaseWithOwningLogin
@db_name NVARCHAR(MAX)
AS
BEGIN
  DECLARE @cmd NVARCHAR(MAX) = 'CREATE LOGIN '+@db_name+' WITH PASSWORD = ''';
  SET @cmd = @cmd + CAST(NEWID() AS NVARCHAR(MAX))+''';';
  EXEC(@cmd);
  EXEC('USE master;DENY CONNECT SQL TO '+@db_name+';');
  EXEC('CREATE DATABASE '+@db_name+';');
  EXEC('ALTER AUTHORIZATION ON DATABASE::'+@db_name+' TO '+@db_name+';');
  EXEC('ALTER DATABASE '+@db_name+' SET RECOVERY SIMPLE;');
END
GO
IF OBJECT_ID('tempdb..#RecreateDB') IS NOT NULL DROP PROCEDURE #RecreateDB;
GO
CREATE PROCEDURE #RecreateDB
@db_name NVARCHAR(MAX)
AS
BEGIN
  EXEC #ForceDropDatabaseAndLogin @db_name;
  EXEC #CreateDatabaseWithOwningLogin @db_name;
END;
GO
EXEC #RecreateDB 'WaitForTester';
GO
USE WaitForTester;
GO
IF OBJECT_ID('dbo.GetNums') IS NOT NULL DROP FUNCTION dbo.GetNums;
GO
CREATE FUNCTION dbo.GetNums(@n AS BIGINT) RETURNS TABLE
-- by Itzik Ben-Gan
-- http://www.sqlmag.com/article/sql-server/virtual-auxiliary-table-of-numbers
AS
RETURN
  WITH
  L0   AS(SELECT 1 AS c UNION ALL SELECT 1),
  L1   AS(SELECT 1 AS c FROM L0 AS A CROSS JOIN L0 AS B),
  L2   AS(SELECT 1 AS c FROM L1 AS A CROSS JOIN L1 AS B),
  L3   AS(SELECT 1 AS c FROM L2 AS A CROSS JOIN L2 AS B),
  L4   AS(SELECT 1 AS c FROM L3 AS A CROSS JOIN L3 AS B),
  L5   AS(SELECT 1 AS c FROM L4 AS A CROSS JOIN L4 AS B),
  Nums AS(SELECT ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS n FROM L5)
  SELECT TOP (@n) n FROM Nums ORDER BY n;
GO  
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
GO
SET QUOTED_IDENTIFIER ON;
GO
DROP TABLE IF EXISTS dbo.timelog;
GO
CREATE TABLE dbo.timelog(
  id INT IDENTITY(1,1),
  [@a] DATETIME2,
  [@c] DATETIME2,
  [@b] DATETIME2,
  spid INT DEFAULT @@SPID
);
GO
SET NOCOUNT ON;
GO
DROP PROCEDURE IF EXISTS dbo.loopy;
GO
CREATE PROCEDURE dbo.loopy
  @loopcount INT = 100000
AS
BEGIN
  DECLARE @a DATETIME2, @b DATETIME2,@c DATETIME2;
  WHILE(@loopcount > 0)
  BEGIN
    SET @a = SYSDATETIME();
    EXEC sp_executesql N'WAITFOR DELAY ''00:00:00.111'';SET @c = SYSDATETIME();',N'@c DATETIME2 OUTPUT', @c OUT;
    SET @b = SYSDATETIME();
    INSERT INTO dbo.timelog([@a],[@c],[@b])
    SELECT @a,@c,@b;
    SET @loopcount -=1;
  END;
END;
GO
--EXEC dbo.Loopy 10;
--SELECT X.[@b-@a],COUNT(1) cnt FROM(SELECT [@a],[@c],[@b],DATEDIFF(MILLISECOND,[@a],[@b])[@b-@a] FROM dbo.timelog AS T WITH(NOLOCK))X GROUP BY GROUPING SETS ((X.[@b-@a]),())ORDER BY X.[@b-@a];
GO
--EXEC AsyncExec.QueueCommand @cmd = 'EXEC dbo.Loopy 10;';
GO
USE master;
GO
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
ALTER DATABASE WaitForTester SET ENABLE_BROKER WITH ROLLBACK IMMEDIATE;
GO
USE WaitForTester;
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
GO
IF(EXISTS(SELECT 1 FROM sys.services WHERE name = '//AsyncExec/AsyncExecSourceQueue/Service'))DROP SERVICE [//AsyncExec/AsyncExecSourceQueue/Service];
IF(OBJECT_ID('AsyncExec.AsyncExecSourceQueue') IS NOT NULL)DROP QUEUE AsyncExec.AsyncExecSourceQueue;
IF(EXISTS(SELECT 1 FROM sys.service_contracts WHERE name = '//AsyncExec/ExecuteCommand/Contract'))DROP CONTRACT [//AsyncExec/ExecuteCommand/Contract];
IF(EXISTS(SELECT 1 FROM sys.service_message_types WHERE name = '//AsyncExec/ExecuteCommand'))DROP MESSAGE TYPE [//AsyncExec/ExecuteCommand];
DROP PROCEDURE IF EXISTS AsyncExec.AsyncExecTargetQueueProcessor;
DROP PROCEDURE IF EXISTS AsyncExec.QueueCommand;
DROP SCHEMA IF EXISTS AsyncExec;
GO
CREATE SCHEMA AsyncExec;
GO
CREATE MESSAGE TYPE [//AsyncExec/ExecuteCommand] VALIDATION = WELL_FORMED_XML;
GO
CREATE CONTRACT [//AsyncExec/ExecuteCommand/Contract]([//AsyncExec/ExecuteCommand] SENT BY INITIATOR);
GO
CREATE QUEUE AsyncExec.AsyncExecSourceQueue WITH STATUS=ON, RETENTION=OFF;
GO
CREATE SERVICE [//AsyncExec/AsyncExecSourceQueue/Service] ON QUEUE AsyncExec.AsyncExecSourceQueue([//AsyncExec/ExecuteCommand/Contract]);
GO
CREATE PROCEDURE AsyncExec.QueueCommand
  @cmd NVARCHAR(MAX)
AS
BEGIN
  DECLARE @DialogHandle UNIQUEIDENTIFIER;
  DECLARE @Message XML;
  BEGIN TRANSACTION;
	   BEGIN DIALOG @DialogHandle
		    FROM SERVICE [//AsyncExec/AsyncExecSourceQueue/Service]
		    TO SERVICE N'//AsyncExec/AsyncExecSourceQueue/Service'
		    ON CONTRACT [//AsyncExec/ExecuteCommand/Contract]
		    WITH ENCRYPTION = OFF;
	   SELECT @Message = (SELECT @cmd [cmd] FOR XML PATH(''),TYPE);
	   SEND ON CONVERSATION @DialogHandle
		    MESSAGE TYPE [//AsyncExec/ExecuteCommand]
		    (@Message);
	   SELECT @Message AS QueuedCommand;
  COMMIT TRANSACTION;
END;
GO
CREATE PROCEDURE AsyncExec.AsyncExecTargetQueueProcessor
AS
BEGIN
  DECLARE @DialogHandle UNIQUEIDENTIFIER;
  DECLARE @MessageTypeName sysname;
  DECLARE @Message XML;
  DECLARE @ErrMessage VARCHAR(MAX) = NULL;
  DECLARE @cmd NVARCHAR(MAX);
  WHILE (1=1)
  BEGIN
    BEGIN TRY
      BEGIN TRANSACTION;
      WAITFOR
      (
        RECEIVE TOP(1)
             @DialogHandle = conversation_handle,
             @MessageTypeName = message_type_name,
             @Message = CONVERT(XML, message_body)
           FROM AsyncExec.AsyncExecSourceQueue
      ), TIMEOUT 100000;
 
      IF (@@ROWCOUNT = 0)
      BEGIN
        IF (@@TRANCOUNT > 0 ) ROLLBACK TRANSACTION;
        BREAK;
      END;
 
      SET @cmd = NULL;
      IF @MessageTypeName = N'//AsyncExec/ExecuteCommand'
      BEGIN
        SELECT @cmd = @Message.value('/cmd[1]','NVARCHAR(MAX)');
        END CONVERSATION @DialogHandle;
      END;
      COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
      IF (@@TRANCOUNT > 0 ) ROLLBACK TRANSACTION;
      SET @ErrMessage = 'Error during reading of cmd. (ErrorNumber=' + CONVERT(VARCHAR(100), ERROR_NUMBER()) + ' : ErrorMessage=' + ERROR_MESSAGE()+')';
      BREAK;
    END CATCH;

    IF(@cmd IS NOT NULL)
    BEGIN
      BEGIN TRY
        EXEC(@cmd);
      END TRY
      BEGIN CATCH
        SET @ErrMessage = 'Error during execution of cmd (ErrorNumber=' + CONVERT(VARCHAR(100), ERROR_NUMBER()) + ' : ErrorMessage=' + ERROR_MESSAGE()+'): '+@cmd;
        BREAK;
      END CATCH;
    END;
  END;
  IF(@ErrMessage IS NOT NULL)
  BEGIN
    RAISERROR(@ErrMessage, 16, 1);
  END;
END;
GO
ALTER QUEUE AsyncExec.AsyncExecSourceQueue WITH ACTIVATION(STATUS=ON,MAX_QUEUE_READERS=20,PROCEDURE_NAME=AsyncExec.AsyncExecTargetQueueProcessor,EXECUTE AS OWNER);
GO
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
GO
EXEC AsyncExec.QueueCommand @cmd = 'EXEC dbo.Loopy 1000000;';
GO 20
GO
SELECT * FROM AsyncExec.AsyncExecSourceQueue;
--SELECT * FROM sys.service_queues AS SQ
GO
--EXEC AsyncExec.AsyncExecTargetQueueProcessor;
SELECT X.[@b-@a],MIN([@a]) [MIN(@a)], MAX([@a])[MAX(@a)],COUNT(1) cnt FROM(SELECT [@a],[@c],[@b],DATEDIFF(MILLISECOND,[@a],[@b])[@b-@a] FROM dbo.timelog AS T WITH(NOLOCK))X GROUP BY GROUPING SETS ((X.[@b-@a]),())ORDER BY X.[@b-@a];
GO
SELECT * FROM sys.dm_exec_requests
SELECT * FROM sys.dm_exec_sessions AS DES
