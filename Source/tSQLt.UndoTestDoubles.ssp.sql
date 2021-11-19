IF OBJECT_ID('tSQLt.UndoTestDoubles') IS NOT NULL DROP PROCEDURE tSQLt.UndoTestDoubles;
GO
---Build+
GO
CREATE PROCEDURE tSQLt.UndoTestDoubles
  @Force BIT = 0
AS
BEGIN
  DECLARE @cmd NVARCHAR(MAX);

  IF (@Force = 1) 
  BEGIN
    SET @cmd = 'EXEC tSQLt.Private_Print @Message = ''WARNING: @Force has been set to 1. Dropping the following objects that are not marked as temporary. (%s)'';';
  END;
  ELSE
  BEGIN
    SET @cmd = 'RAISERROR(''Cannot drop these objects as they are not marked as temporary. Use @Force = 1 to override. (%s)'',16,10)';
  END;

  SELECT @cmd = REPLACE(@cmd,'%s',Collisions.List)
    FROM
    (
      SELECT
        STUFF (
        (
          SELECT
              ', ' + QUOTENAME(OBJECT_SCHEMA_NAME(TestDouble.object_id))+'.'+QUOTENAME(TestDouble.name)
            FROM tSQLt.Private_RenamedObjectLog AS ROL
            JOIN sys.objects AS TestDouble
              ON TestDouble.object_id = OBJECT_ID(QUOTENAME(OBJECT_SCHEMA_NAME(ROL.ObjectId))+'.'+QUOTENAME(PARSENAME(ROL.OriginalName,1)))
            LEFT JOIN sys.extended_properties AS EP
              ON EP.class_desc = 'OBJECT_OR_COLUMN'
             AND EP.major_id = TestDouble.object_id
             AND EP.name = 'tSQLt.IsTempObject'
             AND EP.value = 1
           WHERE EP.value IS NULL
           ORDER BY 1
             FOR XML PATH (''), TYPE
         ).value('.','NVARCHAR(MAX)'),
         1,2,'')
    ) Collisions(List)
  EXEC(@cmd);

  IF(EXISTS(
    SELECT ROL.OriginalName, COUNT(1) cnt 
      FROM tSQLt.Private_RenamedObjectLog ROL
      JOIN sys.objects O
        ON ROL.ObjectId = O.object_id
      LEFT JOIN sys.extended_properties AS EP
        ON EP.class_desc = 'OBJECT_OR_COLUMN'
       AND EP.major_id = O.object_id
       AND EP.name = 'tSQLt.IsTempObject'
       AND EP.value = 1
     WHERE EP.value IS NULL
     GROUP BY ROL.OriginalName
    HAVING COUNT(1)>1
  ))
  BEGIN
    RAISERROR('Catastrophy Averted!',16,10);
  END;





  SELECT TOP(0)A.* INTO #RenamedObjects FROM tSQLt.Private_RenamedObjectLog A RIGHT JOIN tSQLt.Private_RenamedObjectLog X ON 1=0;





  BEGIN TRAN;
  DELETE FROM tSQLt.Private_RenamedObjectLog OUTPUT Deleted.* INTO #RenamedObjects;

  WITH MarkedTestDoubles AS
  (
    SELECT 
        TempO.Name,
        SCHEMA_NAME(TempO.schema_id) SchemaName,
        TempO.type ObjectType
      FROM sys.objects TempO
      JOIN sys.extended_properties AS EP
        ON EP.class_desc = 'OBJECT_OR_COLUMN'
       AND EP.major_id = TempO.object_id
       AND EP.name = 'tSQLt.IsTempObject'
       AND EP.value = 1
  )
  SELECT @cmd = 
  (
    SELECT 
        DC.cmd+';'  
      FROM MarkedTestDoubles MTD
     CROSS APPLY tSQLt.Private_GetDropItemCmd(QUOTENAME(MTD.SchemaName)+'.'+QUOTENAME(MTD.Name),MTD.ObjectType) DC
       FOR XML PATH(''),TYPE
  ).value('.','NVARCHAR(MAX)')
  RAISERROR('>>>>>>>>>>>>>>>>> CMD 1: %s', 0,1, @cmd) WITH NOWAIT;
  EXEC(@cmd);

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
                 WHEN L.ParentId IS NULL THEN DC.cmd+';'  
                 ELSE NULL
               END,'')+
        'EXEC tSQLt.Private_RenameObject '''+L.SchemaName+''','''+L.CurrentName+''','''+L.OriginalName+''';'
      FROM L
     CROSS APPLY tSQLt.Private_GetDropItemCmd(QUOTENAME(L.SchemaName)+'.'+QUOTENAME(L.OriginalName),L.ObjectType) DC
     ORDER BY L.SortId DESC, L.Id ASC
       FOR XML PATH(''),TYPE
  ).value('.','NVARCHAR(MAX)')
  RAISERROR('>>>>>>>>>>>>>>>>> CMD 2: %s', 0,1, @cmd) WITH NOWAIT;
  EXEC(@cmd);


  COMMIT;
END;
GO

