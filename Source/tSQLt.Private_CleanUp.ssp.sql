IF OBJECT_ID('tSQLt.Private_CleanUp') IS NOT NULL DROP PROCEDURE tSQLt.Private_CleanUp;
GO
---Build+
GO
CREATE PROCEDURE tSQLt.Private_CleanUp
  @FullTestName NVARCHAR(MAX),
  @ErrorMsg NVARCHAR(MAX) OUTPUT
AS
BEGIN
  SELECT 'tSQLt.Private_CleanUp:1',T.object_id,T.name,X.*, E.* FROM sys.tables T LEFT JOIN sys.extended_properties AS E ON T.object_id = E.major_id AND E.class_desc='OBJECT_OR_COLUMN'
  OUTER APPLY (SELECT(SELECT QUOTENAME(name)+' ' FROM sys.columns C WHERE T.object_id = C.object_id ORDER BY C.column_id FOR XML PATH(''),TYPE).value('.','NVARCHAR(MAX)'))X(cols)
  WHERE T.schema_id=SCHEMA_ID('tSQLt') ORDER BY T.object_id, E.name;

  EXEC tSQLt.Private_NoTransactionHandleTables @Action='Reset';

  SELECT 'tSQLt.Private_CleanUp:2',T.object_id,T.name,X.*, E.* FROM sys.tables T LEFT JOIN sys.extended_properties AS E ON T.object_id = E.major_id AND E.class_desc='OBJECT_OR_COLUMN'
  OUTER APPLY (SELECT(SELECT QUOTENAME(name)+' ' FROM sys.columns C WHERE T.object_id = C.object_id ORDER BY C.column_id FOR XML PATH(''),TYPE).value('.','NVARCHAR(MAX)'))X(cols)
  WHERE T.schema_id=SCHEMA_ID('tSQLt') ORDER BY T.object_id, E.name;

  EXEC tSQLt.UndoTestDoubles @Force = 0;

  SELECT 'tSQLt.Private_CleanUp:3',T.object_id,T.name,X.*, E.* FROM sys.tables T LEFT JOIN sys.extended_properties AS E ON T.object_id = E.major_id AND E.class_desc='OBJECT_OR_COLUMN'
  OUTER APPLY (SELECT(SELECT QUOTENAME(name)+' ' FROM sys.columns C WHERE T.object_id = C.object_id ORDER BY C.column_id FOR XML PATH(''),TYPE).value('.','NVARCHAR(MAX)'))X(cols)
  WHERE T.schema_id=SCHEMA_ID('tSQLt') ORDER BY T.object_id, E.name;

END;
GO
---Build-
GO
