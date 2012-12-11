IF OBJECT_ID('tSQLt.Private_GetCommaSeparatedColumnList') IS NOT NULL DROP FUNCTION tSQLt.Private_GetCommaSeparatedColumnList;
GO
---BUILD+
CREATE FUNCTION tSQLt.Private_GetCommaSeparatedColumnList (@Table NVARCHAR(MAX), @ExcludeColumn NVARCHAR(MAX))
RETURNS NVARCHAR(MAX)
AS 
BEGIN
  RETURN STUFF((
     SELECT ',' + CASE WHEN system_type_id = TYPE_ID('timestamp') THEN ';TIMESTAMP columns are unsupported!;' ELSE QUOTENAME(name) END 
       FROM sys.columns 
      WHERE object_id = OBJECT_ID(@Table) 
        AND name <> @ExcludeColumn 
      ORDER BY column_id
     FOR XML PATH(''), TYPE).value('.','NVARCHAR(MAX)')
    ,1, 1, '');
        
END;
---BUILD-
GO