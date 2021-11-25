SELECT 
    R.EventSequence,
    TE.name,
    TSV.subclass_name,
    R.ObjectName,
    R.LineNumber,
    R.TransactionID,
    R.XactSequence,
    ISNULL(REPLICATE('    ',(R.NestLevel-1)),'')+CAST(R.TextData AS NVARCHAR(MAX)) AS TextData,
    R.Error,
    R.Severity,
    R.NestLevel,
    R.RowNumber,
    R.EventClass,
    R.EventSubClass,
    R.ApplicationName,
    R.ClientProcessID,
    R.DatabaseID,
    R.DatabaseName,
    R.GroupID,
    R.HostName,
    R.IsSystem,
    R.LoginName,
    R.LoginSid,
    R.NTDomainName,
    R.NTUserName,
    R.RequestID,
    R.SPID,
    R.ServerName,
    R.SessionLoginName,
    R.StartTime,
    R.Success,
    R.GUID,
    R.BinaryData,
    R.Duration,
    R.EndTime,
    R.IntegerData,
    R.CPU,
    R.IntegerData2,
    R.Offset,
    R.Reads,
    R.RowCounts,
    R.Writes,
    R.State,
    R.ObjectID,
    R.ObjectType,
    R.SourceDatabaseID,
    R.IndexID,
    R.Type,
    R.Mode,
    R.OwnerID,
    R.ObjectID2,
    R.BigintData1
  FROM dbo.run4 R
  LEFT JOIN sys.trace_events AS TE
    ON R.EventClass = TE.trace_event_id
  LEFT JOIN sys.trace_subclass_values AS TSV
    ON TSV.trace_event_id = TE.trace_event_id
   AND R.EventSubClass = TSV.subclass_value
  WHERE ISNULL(R.ObjectName,'???') NOT IN ('Private_Print','sp_rename', 'sp_validname','GetTestResultFormatter','sp_addextendedproperty','sp_updateextendedproperty')
  ORDER BY R.EventSequence