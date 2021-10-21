IF OBJECT_ID('tSQLt.UndoTestDoubles') IS NOT NULL DROP PROCEDURE tSQLt.UndoTestDoubles;
GO
---Build+
GO
CREATE PROCEDURE tSQLt.UndoTestDoubles
AS
BEGIN
  SELECT * FROM tSQLt.Private_RenamedObjectLog
  SELECT 
      QUOTENAME(SCHEMA_NAME(T.schema_id))+'.'+QUOTENAME(T.name) OriginalName, 
      OBJECT_SCHEMA_NAME(OTI.OrgTableObjectId),
      OBJECT_NAME(OTI.OrgTableObjectId)
    FROM sys.tables T CROSS APPLY tSQLt.Private_GetOriginalTableInfo(T.object_id) OTI
  RETURN;
END;
GO


