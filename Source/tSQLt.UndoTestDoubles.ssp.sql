IF OBJECT_ID('tSQLt.UndoTestDoubles') IS NOT NULL DROP PROCEDURE tSQLt.UndoTestDoubles;
GO
---Build+
GO
CREATE PROCEDURE tSQLt.UndoTestDoubles
AS
BEGIN
  SELECT 
      Id,
      ObjectId,
      OBJECT_SCHEMA_NAME(L.ObjectId) SchemaName,
      OBJECT_NAME(L.ObjectId) CurrentName,
      OriginalName 
    FROM tSQLt.Private_RenamedObjectLog L
  RETURN;
END;
GO


