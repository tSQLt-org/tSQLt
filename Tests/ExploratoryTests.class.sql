EXEC tSQLt.NewTestClass 'ExploratoryTests';
GO
CREATE PROCEDURE ExploratoryTests.[test NULL can be CAST into any datatype]
AS
BEGIN
  DECLARE @cmd NVARCHAR(MAX) = 
    (
      SELECT ',CAST(NULL AS '+QUOTENAME(SCHEMA_NAME(schema_id))+'.'+QUOTENAME(name)+')['+CAST(user_type_id AS NVARCHAR(MAX))+']'
        FROM sys.types
       WHERE is_user_defined = 0
         FOR XML PATH(''),TYPE
    ).value('.','NVARCHAR(MAX)');
  SET @cmd = STUFF(@cmd,1,1,'');
  SET @cmd = 'SELECT TOP(0) '+@cmd+' INTO ExploratoryTests.DataTypeTestTable;'
  EXEC(@cmd);
  SELECT * 
    INTO #Actual
    FROM sys.columns 
   WHERE object_id = OBJECT_ID('ExploratoryTests.DataTypeTestTable')
     AND name <> user_type_id
  EXEC tSQLt.AssertEmptyTable @TableName = '#Actual';
END;
GO
