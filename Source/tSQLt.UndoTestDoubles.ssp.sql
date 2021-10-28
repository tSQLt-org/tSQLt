IF OBJECT_ID('tSQLt.UndoTestDoubles') IS NOT NULL DROP PROCEDURE tSQLt.UndoTestDoubles;
GO
---Build+
GO
CREATE PROCEDURE tSQLt.UndoTestDoubles
AS
BEGIN
  DECLARE @cmd NVARCHAR(MAX);
  WITH L AS
  (
    SELECT 
        ROL.Id,
        ParentROL.Id ParentId,
        ISNULL(ParentROL.Id,ROL.Id) SortId,
        ROL.ObjectId,
        OBJECT_SCHEMA_NAME(ROL.ObjectId) SchemaName,
        OBJECT_NAME(ROL.ObjectId) CurrentName,
        PARSENAME(ROL.OriginalName,1) OriginalName,
        O.type ObjectType
      FROM tSQLt.Private_RenamedObjectLog ROL
      JOIN sys.objects O
        ON ROL.ObjectId = O.object_id
      LEFT JOIN tSQLt.Private_RenamedObjectLog ParentROL
        ON O.parent_object_id = ParentROL.ObjectId
  )
  SELECT @cmd = 
  (
    SELECT 
        CASE WHEN L.ParentId IS NULL THEN DC.cmd ELSE '' END+
        ';EXEC tSQLt.Private_RenameObject '''+L.SchemaName+''','''+L.CurrentName+''','''+L.OriginalName+''';'
      FROM L
     CROSS APPLY tSQLt.Private_GetDropItemCmd(QUOTENAME(L.SchemaName)+'.'+QUOTENAME(L.OriginalName),L.ObjectType) DC
     ORDER BY L.SortId DESC, L.Id ASC
       FOR XML PATH(''),TYPE
  ).value('.','NVARCHAR(MAX)')
  EXEC(@cmd);
END;
GO


