IF OBJECT_ID('tSQLt.Private_CreateResultTableForCompareTables') IS NOT NULL DROP PROCEDURE tSQLt.Private_CreateResultTableForCompareTables;
GO
---Build+
GO
CREATE PROCEDURE tSQLt.Private_CreateResultTableForCompareTables
 @ResultTable NVARCHAR(MAX),
 @ResultColumn NVARCHAR(MAX),
 @BaseTable NVARCHAR(MAX)
AS
BEGIN
  DECLARE @Cmd NVARCHAR(MAX);
  SET @Cmd = '
     SELECT TOP(0) ''>'' AS ' + @ResultColumn + ', Expected.* INTO ' + @ResultTable + ' 
       FROM ' + @BaseTable + ' AS Expected RIGHT JOIN ' + @BaseTable + ' AS X ON 1=0; '
  EXEC(@Cmd);
END
GO
---Build-
GO
