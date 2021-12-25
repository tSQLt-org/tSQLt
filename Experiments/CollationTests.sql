/*--
RELEVANT LINKS
https://www.red-gate.com/simple-talk/databases/sql-server/t-sql-programming-sql-server/questions-sql-server-collations-shy-ask/
https://docs.microsoft.com/en-us/sql/t-sql/statements/windows-collation-name-transact-sql?view=sql-server-ver15
--*/

SELECT DATABASEPROPERTYEX('tempdb','Collation') [tempdb collation],
       DATABASEPROPERTYEX(DB_NAME(),'Collation') [database collation]
GO

DROP TABLE IF EXISTS dbo.atable;
DROP TABLE IF EXISTS tempdb..#Actual;
SELECT 
    'Hello World!' COLLATE SQL_Polish_CP1250_CI_AS c1, 
    'Hello World!' COLLATE SQL_Latin1_General_CP437_BIN c2, 
    'Hello World!' COLLATE Albanian_BIN2 c3 
  INTO dbo.atable
SELECT * INTO #Actual FROM dbo.atable

SELECT 'dbo.atable' [table],* FROM sys.columns WHERE object_id = OBJECT_ID('dbo.atable')

SELECT '#Actual',* FROM tempdb.sys.columns WHERE object_id = OBJECT_ID('tempdb..#Actual');

GO

DROP TABLE IF EXISTS tempdb..#E;
CREATE TABLE #E(
  C1 NVARCHAR(MAX) COLLATE DATABASE_DEFAULT,
  C2 NVARCHAR(MAX)
);

SELECT '#E',* FROM tempdb.sys.columns WHERE object_id = OBJECT_ID('tempdb..#E');
GO
SELECT *
FROM #E E1
JOIN #E E2
ON E2.C2 = E1.C1