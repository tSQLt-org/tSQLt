


IF OBJECT_ID('A') IS NOT NULL DROP TABLE A;
IF OBJECT_ID('B') IS NOT NULL DROP TABLE B;

CREATE TABLE A (i INT, b VARCHAR(50), c VARCHAR(50), d FLOAT);
CREATE TABLE B (i INT, b VARCHAR(50), c VARCHAR(50), d FLOAT);

INSERT INTO A (i, b, c, d) VALUES (1, 'asdf', 'ewfq', 34.5);
INSERT INTO A (i, b, c, d) VALUES (2, 'asdf', 'ewfq', 34.5);
INSERT INTO A (i, b, c, d) VALUES (3, 'asdf', 'ewfq', 34.5);
INSERT INTO A (i, b, c, d) VALUES (4, 'asdf', 'ewfq', 34.5);

INSERT INTO B (i, b, c, d) VALUES (1, 'asdf', 'ewfq', 34.5);
INSERT INTO B (i, b, c, d) VALUES (7, 'asdf', 'ewfq', 34.5);
INSERT INTO B (i, b, c, d) VALUES (3, 'ewqfwef', 'ewfq', 34.5);
INSERT INTO B (i, b, c, d) VALUES (4, 'asdf', 'ewfq', 34.5);


--SET STATISTICS TIME ON;
SET NOCOUNT ON;
DECLARE @cntr INT = 0;
WHILE @cntr < 1000
BEGIN
  SET @cntr = @cntr + 1;
  EXEC tSQLt.AssertEqualsTable 'A', 'B';
  IF(@cntr % 100 = 0)RAISERROR('current cntr:%i',0,1,@cntr)WITH NOWAIT;
END;

--SET STATISTICS TIME OFF;


--SELECT DB_ID()
SELECT 
Duration,CPU,Reads,CAST(TextData AS NVARCHAR(MAX)) TextData
INTO tempdb.dbo.trc4
FROM tempdb..trc3

SELECT TOP(10)* FROM(
SELECT COUNT(1) Cnt,AVG(Duration) ADur,AVG(CPU)ACPU,AVG(Reads)AReads,CAST(TextData AS NVARCHAR(MAX)) TextData
FROM tempdb..trc1
GROUP BY CAST(TextData AS NVARCHAR(MAX))
HAVING COUNT(1)>1
)x
ORDER BY ACPU DESC, AReads DESC
SELECT TOP(10)* FROM(
SELECT COUNT(1) Cnt,AVG(Duration) ADur,AVG(CPU)ACPU,AVG(Reads)AReads,CAST(TextData AS NVARCHAR(MAX)) TextData
FROM tempdb..trc2
GROUP BY CAST(TextData AS NVARCHAR(MAX))
HAVING COUNT(1)>1
)x
ORDER BY ACPU DESC, AReads DESC

SELECT MIN(StartTime),MAX(StartTime) FROM tempdb..trc3

UPDATE tempdb..trc2
SET TextData = 
'SELECT _=_ AS tSQLt_tempobject_________________________________, Expected.* INTO tSQLt_tempobject_________________________________            FROM @N N            LEFT JOIN A AS Expected ON N.I <> N.I          '
WHERE TextData LIKE 'SELECT _=_ AS tSQLt_tempobject_________________________________, Expected.* INTO tSQLt_tempobject_________________________________%'

SELECT * FROM tempdb..trc2
WHERE TextData LIKE 'SELECT _=_ AS tSQLt_tempobject_________________________________, Expected.* INTO tSQLt_tempobject_________________________________%'

DROP TABLE dbo.expected
SELECT 'DROP TABLE '+name+';' FROM sys.tables WHERE name LIKE 'tSQLt_tempobject%'

