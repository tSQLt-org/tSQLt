DECLARE @txt NVARCHAR(MAX);
IF(OBJECT_ID('tempdb..#VersionInfoTable')IS NOT NULL)DROP TABLE #VersionInfoTable;
SELECT Version, ClrVersion, ClrSigningKey INTO #VersionInfoTable FROM tSQLt.Info();
EXEC tSQLt.TableToText @txt = @txt OUTPUT, @TableName = N'#VersionInfoTable';

RAISERROR('+-----------------------------------------------------------------------------------------------------+',0,1)WITH NOWAIT;
RAISERROR('|                                             tSQLt Info:                                             |',0,1)WITH NOWAIT;
RAISERROR('+-----------------------------------------------------------------------------------------------------+',0,1)WITH NOWAIT;
RAISERROR('',0,1)WITH NOWAIT;
RAISERROR(@txt,0,1)WITH NOWAIT;
RAISERROR('',0,1)WITH NOWAIT;
RAISERROR('+-----------------------------------------------------------------------------------------------------+',0,1)WITH NOWAIT;
RAISERROR('|                                          SQL Server Info:                                           |',0,1)WITH NOWAIT;
RAISERROR('+-----------------------------------------------------------------------------------------------------+',0,1)WITH NOWAIT;
RAISERROR('',0,1)WITH NOWAIT;
RAISERROR('%s',0,1,@@VERSION)WITH NOWAIT;
RAISERROR('-------------------------------------------------------------------------------------------------------',0,1)WITH NOWAIT;
