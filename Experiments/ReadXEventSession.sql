DECLARE @xml_output xml;

-- Get the XML data from the ring buffer
SELECT @xml_output = CAST(xet.target_data AS xml)
FROM sys.dm_xe_session_targets AS xet
JOIN sys.dm_xe_sessions AS xe
ON (xe.address = xet.event_session_address)
WHERE xe.name = N'MyXEventSession' -- Replace with your session name
AND xet.target_name = N'ring_buffer';
-- SELECT @xml_output
-- Parse and display the relevant information
SELECT 
    event_data.value('(@timestamp)[1]', 'datetime2') AS EventTime,
    event_data.value('(data[@name="duration"]/value)[1]', 'int') AS Duration,
    event_data.value('(action[@name="sql_text"]/value)[1]', 'nvarchar(max)') AS SqlText,
    event_data.query('.') xx
FROM @xml_output.nodes('RingBufferTarget/event') AS XEventData(event_data)
ORDER BY EventTime;
