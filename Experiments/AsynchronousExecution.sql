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
EXEC AsyncExec.QueueCommand @cmd = 'EXEC dbo.Loopy 1000;';
EXEC AsyncExec.QueueCommand @cmd = 'EXEC dbo.Loopy 1000;';
EXEC AsyncExec.QueueCommand @cmd = 'EXEC dbo.Loopy 1000;';
EXEC AsyncExec.QueueCommand @cmd = 'EXEC dbo.Loopy 1000;';
EXEC AsyncExec.QueueCommand @cmd = 'EXEC dbo.Loopy 1000;';
EXEC AsyncExec.QueueCommand @cmd = 'EXEC dbo.Loopy 1000;';
EXEC AsyncExec.QueueCommand @cmd = 'EXEC dbo.Loopy 1000;';
EXEC AsyncExec.QueueCommand @cmd = 'EXEC dbo.Loopy 1000;';
EXEC AsyncExec.QueueCommand @cmd = 'EXEC dbo.Loopy 1000;';
EXEC AsyncExec.QueueCommand @cmd = 'EXEC dbo.Loopy 1000;';
GO
SELECT * FROM AsyncExec.AsyncExecSourceQueue;
--SELECT * FROM sys.service_queues AS SQ
GO
--EXEC AsyncExec.AsyncExecTargetQueueProcessor;
SELECT X.[@b-@a],COUNT(1) cnt FROM(SELECT [@a],[@c],[@b],DATEDIFF(MILLISECOND,[@a],[@b])[@b-@a] FROM dbo.timelog AS T WITH(NOLOCK))X GROUP BY GROUPING SETS ((X.[@b-@a]),())ORDER BY X.[@b-@a];
GO
SELECT * FROM sys.dm_exec_requests
SELECT * FROM sys.dm_exec_sessions AS DES