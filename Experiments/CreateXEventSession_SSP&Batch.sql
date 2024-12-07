IF(EXISTS(SELECT * FROM sys.server_event_sessions WHERE name = 'MyXEventSession'))
BEGIN
  DROP EVENT SESSION [MyXEventSession] ON SERVER;
END;
CREATE EVENT SESSION [MyXEventSession] ON SERVER 
ADD EVENT sqlserver.rpc_completed (
    ACTION(sqlserver.sql_text, sqlserver.database_id, sqlserver.username)
    WHERE (sqlserver.database_name=N'tSQLt_ValidateBuild')
),
ADD EVENT sqlserver.rpc_starting (
    ACTION(sqlserver.sql_text, sqlserver.database_id, sqlserver.username)
    WHERE (sqlserver.database_name=N'tSQLt_ValidateBuild')
),
ADD EVENT sqlserver.sql_batch_completed (
    ACTION(sqlserver.sql_text, sqlserver.database_id, sqlserver.username)
    WHERE (sqlserver.database_name=N'tSQLt_ValidateBuild')
),
ADD EVENT sqlserver.sql_batch_starting (
    ACTION(sqlserver.sql_text, sqlserver.database_id, sqlserver.username)
    WHERE (sqlserver.database_name=N'tSQLt_ValidateBuild')
)
ADD TARGET package0.ring_buffer(SET max_memory=4096) -- Storing data in a ring buffer
WITH (MAX_MEMORY=4096 KB, EVENT_RETENTION_MODE=NO_EVENT_LOSS, MAX_DISPATCH_LATENCY=30 SECONDS, MAX_EVENT_SIZE=0 KB, MEMORY_PARTITION_MODE=NONE, TRACK_CAUSALITY=ON, STARTUP_STATE=OFF)
GO
ALTER EVENT SESSION [MyXEventSession] ON SERVER STATE = START;