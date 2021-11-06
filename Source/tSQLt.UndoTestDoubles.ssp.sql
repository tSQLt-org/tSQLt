IF OBJECT_ID('tSQLt.UndoTestDoubles') IS NOT NULL DROP PROCEDURE tSQLt.UndoTestDoubles;
GO
---Build+
GO
CREATE PROCEDURE tSQLt.UndoTestDoubles
AS
BEGIN
  DECLARE @cmd NVARCHAR(MAX);

  SELECT @cmd = 'RAISERROR(''Cannot drop '+Collisions.List+' as it is not marked as temporary. Use @Force = 1 to override.'',16,10)'
    FROM
    (
      SELECT
          QUOTENAME(OBJECT_SCHEMA_NAME(TestDouble.object_id))+'.'+QUOTENAME(TestDouble.name)
        FROM tSQLt.Private_RenamedObjectLog AS ROL
        JOIN sys.objects AS TestDouble
          ON TestDouble.object_id = OBJECT_ID(QUOTENAME(OBJECT_SCHEMA_NAME(ROL.ObjectId))+'.'+QUOTENAME(PARSENAME(ROL.OriginalName,1)))
        LEFT JOIN sys.extended_properties AS EP
          ON EP.class_desc = 'OBJECT_OR_COLUMN'
         AND EP.major_id = TestDouble.object_id
         AND EP.name = 'tSQLt.IsTempObject'
         AND EP.value = 1
       WHERE EP.value IS NULL
    ) Collisions(List)
  EXEC(@cmd);

  SELECT TOP(0)A.* INTO #RenamedObjects FROM tSQLt.Private_RenamedObjectLog A RIGHT JOIN tSQLt.Private_RenamedObjectLog X ON 1=0;





  BEGIN TRAN;
  DELETE FROM tSQLt.Private_RenamedObjectLog OUTPUT Deleted.* INTO #RenamedObjects;
  WITH LL AS
  (
    SELECT 
        ROL.Id,
        ParentROL.Id ParentId,
        ISNULL(ParentROL.Id,ROL.Id) SortId,
        ROL.ObjectId,
        OBJECT_SCHEMA_NAME(ROL.ObjectId) SchemaName,
        OBJECT_NAME(ROL.ObjectId) CurrentName,
        PARSENAME(ROL.OriginalName,1) OriginalName
      FROM #RenamedObjects ROL
      JOIN sys.objects O
        ON ROL.ObjectId = O.object_id
      LEFT JOIN #RenamedObjects ParentROL
        ON O.parent_object_id = ParentROL.ObjectId
  ),
  L AS
  (
    SELECT 
        LL.Id,
        LL.ParentId,
        LL.SortId,
        LL.ObjectId,
        LL.SchemaName,
        LL.CurrentName,
        LL.OriginalName,
        FakeO.type ObjectType,
        CASE WHEN EP.value IS NOT NULL THEN 1 ELSE 0 END IsTempObject
      FROM LL
      LEFT JOIN sys.objects FakeO
        ON FakeO.object_id = OBJECT_ID(QUOTENAME(LL.SchemaName)+'.'+QUOTENAME(LL.OriginalName))
      LEFT JOIN sys.extended_properties AS EP
        ON EP.class_desc = 'OBJECT_OR_COLUMN'
       AND EP.major_id = FakeO.object_id
       AND EP.name = 'tSQLt.IsTempObject'
       AND EP.value = 1
  )
  SELECT @cmd = 
  (
    SELECT 
        ISNULL(CASE 
                 WHEN L.ParentId IS NULL THEN 
                   CASE WHEN L.IsTempObject = 1 
                     THEN  DC.cmd+';' 
                     ELSE 'RAISERROR(''SHOULD NOT GET HERE.'',16,10);'
                   END
                 ELSE NULL
               END,'')+
        'EXEC tSQLt.Private_RenameObject '''+L.SchemaName+''','''+L.CurrentName+''','''+L.OriginalName+''';'
      FROM L
     CROSS APPLY tSQLt.Private_GetDropItemCmd(QUOTENAME(L.SchemaName)+'.'+QUOTENAME(L.OriginalName),L.ObjectType) DC
     ORDER BY L.SortId DESC, L.Id ASC
       FOR XML PATH(''),TYPE
  ).value('.','NVARCHAR(MAX)')
  EXEC(@cmd);
  COMMIT;
END;
GO


