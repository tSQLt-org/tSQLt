IF OBJECT_ID('tSQLt.UndoTestDoubles') IS NOT NULL DROP PROCEDURE tSQLt.UndoTestDoubles;
GO
---Build+
GO
CREATE PROCEDURE tSQLt.UndoTestDoubles
  @Force BIT = 0
AS
BEGIN
  DECLARE @cmd NVARCHAR(MAX);
  DECLARE @ErrorMessageTableList NVARCHAR(MAX);
  DECLARE @ErrorMessage NVARCHAR(MAX) = '';


  /*-- Two non-temp objects, the first of which should be renamed to the second --*/
  SELECT @ErrorMessage = @ErrorMessage + ISNULL(REPLACE('Attempting to remove object(s) that is/are not marked as temporary. Use @Force = 1 to override. (%s)','%s',Collisions.List),'')
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

  /*-- Attempting to rename two or more non-temp objects to the same name --*/

  IF(EXISTS(
    SELECT O.schema_id, ROL.OriginalName, COUNT(1) cnt 
      FROM tSQLt.Private_RenamedObjectLog ROL
      JOIN sys.objects O
        ON ROL.ObjectId = O.object_id
      LEFT JOIN sys.extended_properties AS EP
        ON EP.class_desc = 'OBJECT_OR_COLUMN'
       AND EP.major_id = O.object_id
       AND EP.name = 'tSQLt.IsTempObject'
       AND EP.value = 1
     WHERE EP.value IS NULL
     GROUP BY O.schema_id, ROL.OriginalName
    HAVING COUNT(1)>1
  ))
  BEGIN
    WITH S AS(
      SELECT 
          C.Id,
          C.OriginalName,
          C.CurrentName,
          C.SchemaName
        FROM(
          SELECT ROL.OriginalName, ROL.Id, O.name CurrentName, SCHEMA_NAME(O.schema_id) SchemaName, COUNT(1)OVER(PARTITION BY O.schema_id, ROL.OriginalName) Cnt
            FROM tSQLt.Private_RenamedObjectLog ROL
            JOIN sys.objects O
              ON ROL.ObjectId = O.object_id
            LEFT JOIN sys.extended_properties AS EP
              ON EP.class_desc = 'OBJECT_OR_COLUMN'
             AND EP.major_id = O.object_id
             AND EP.name = 'tSQLt.IsTempObject'
             AND EP.value = 1
           WHERE EP.value IS NULL
        )C
       WHERE C.Cnt>1
    ),
    ErrorTableLists AS(
      SELECT 
          '{'+C.CList+'}-->' + QUOTENAME(SO.SchemaName)+'.'+QUOTENAME(PARSENAME(SO.OriginalName,1)) ErrorTableList,
          QUOTENAME(SO.SchemaName)+'.'+QUOTENAME(PARSENAME(SO.OriginalName,1)) FullOriginalName
        FROM (SELECT DISTINCT SchemaName, OriginalName FROM S) SO
       CROSS APPLY (
         SELECT (
           STUFF(
             (
               SELECT ', '+QUOTENAME(SC.CurrentName)
                 FROM S AS SC
                WHERE SC.OriginalName = SO.OriginalName
                  AND SC.SchemaName = SO.SchemaName
                ORDER BY SC.Id
                  FOR XML PATH(''),TYPE
             ).value('.','NVARCHAR(MAX)'),
             1,2,'')
         ) CList
       )C
    )
    SELECT @ErrorMessageTableList = (
      STUFF(
        (
          SELECT '; '+ETL.ErrorTableList
            FROM ErrorTableLists ETL
           ORDER BY ETL.FullOriginalName
             FOR XML PATH(''),TYPE
        ).value('.','NVARCHAR(MAX)'),
        1,2,''
      )
    );
    SELECT @ErrorMessage = @ErrorMessage + REPLACE('Attempting to rename two or more objects to the same name. Use @Force = 1 to override, only first object of each rename survives. (%s)','%s',@ErrorMessageTableList);
  END;
  IF(@ErrorMessage <> '')
  BEGIN
    IF (@Force = 1) 
    BEGIN
      SET @ErrorMessage = 'WARNING: @Force has been set to 1. Overriding the following error(s):'+@ErrorMessage;
      EXEC tSQLt.Private_Print @Message = @ErrorMessage;
    END;
    ELSE
    BEGIN
      RAISERROR(@ErrorMessage,16,10);
    END;
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
  ).value('.','NVARCHAR(MAX)');
  EXEC(@cmd);

  SELECT @cmd = 
  (
    SELECT
        DC.cmd+';'
      FROM(
        SELECT
            *
          FROM(
            SELECT
                ROL.OriginalName,
                O.object_id,
                O.type ObjectType,
                SCHEMA_NAME(O.schema_id) SchemaName, 
                O.name CurrentName,
                ROW_NUMBER()OVER(PARTITION BY O.schema_id, ROL.OriginalName ORDER BY ROL.Id) RN
              FROM #RenamedObjects AS ROL
              JOIN sys.objects O
                ON O.object_id = ROL.ObjectId
          )ROLI
         WHERE ROLI.RN>1
      )Deletables
     CROSS APPLY tSQLt.Private_GetDropItemCmd(QUOTENAME(Deletables.SchemaName)+'.'+QUOTENAME(Deletables.CurrentName),Deletables.ObjectType) DC
       FOR XML PATH(''),TYPE
  ).value('.','NVARCHAR(MAX)');
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
  ).value('.','NVARCHAR(MAX)');
  EXEC(@cmd);


  COMMIT;
END;
GO

