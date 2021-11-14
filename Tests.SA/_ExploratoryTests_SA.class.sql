EXEC tSQLt.NewTestClass '_ExploratoryTests_SA';
GO
CREATE PROCEDURE [_ExploratoryTests_SA].[test MSSQL preserves COLLATION when using SELECT INTO across databases]
AS
BEGIN
  SELECT 
    'Hello World!' COLLATE SQL_Polish_CP1250_CI_AS c1, 
    'Hello World!' COLLATE SQL_Latin1_General_CP437_BIN c2, 
    'Hello World!' COLLATE Albanian_BIN2 c3 
  INTO [_ExploratoryTests_SA].Table1

  SELECT * INTO tempdb.dbo.Table2 FROM [_ExploratoryTests_SA].Table1

  SELECT
      C.name COLLATE DATABASE_DEFAULT name, 
      C.collation_name COLLATE DATABASE_DEFAULT collation_name
    INTO #Expected
    FROM sys.columns C 
   WHERE C.object_id = OBJECT_ID('[_ExploratoryTests_SA].Table1');

  SELECT
      C.name COLLATE DATABASE_DEFAULT name, 
      C.collation_name COLLATE DATABASE_DEFAULT collation_name
    INTO #Actual
    FROM tempdb.sys.columns C 
   WHERE C.object_id = OBJECT_ID('tempdb.dbo.Table2');

   EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
   
END;
GO
