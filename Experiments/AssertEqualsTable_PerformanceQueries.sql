


IF OBJECT_ID('A') IS NOT NULL DROP TABLE A;
IF OBJECT_ID('B') IS NOT NULL DROP TABLE B;

CREATE TABLE A (i INT, b VARCHAR(50), c VARCHAR(50), d FLOAT);
CREATE TABLE B (i INT, b VARCHAR(50), c VARCHAR(50), d FLOAT);

INSERT INTO A (i, b, c, d) VALUES (1, 'asdf', 'ewfq', 34.5);
INSERT INTO A (i, b, c, d) VALUES (2, 'asdf', 'ewfq', 34.5);
INSERT INTO A (i, b, c, d) VALUES (3, 'asdf', 'ewfq', 34.5);
INSERT INTO A (i, b, c, d) VALUES (4, 'asdf', 'ewfq', 34.5);

--INSERT INTO B (i, b, c, d) VALUES (1, 'asdf', 'ewfq', 34.5);
--INSERT INTO B (i, b, c, d) VALUES (2, 'asdf', 'ewfq', 34.5);
--INSERT INTO B (i, b, c, d) VALUES (3, 'asdf', 'ewfq', 34.5);
--INSERT INTO B (i, b, c, d) VALUES (4, 'asdf', 'ewfq', 34.5);

INSERT INTO B (i, b, c, d) VALUES (1, 'asdf', 'ewfq', 34.5);
INSERT INTO B (i, b, c, d) VALUES (7, 'asdf', 'ewfq', 34.5);
INSERT INTO B (i, b, c, d) VALUES (3, 'ewqfwef', 'ewfq', 34.5);
INSERT INTO B (i, b, c, d) VALUES (4, 'asdf', 'ewfq', 34.5);


--SET STATISTICS TIME ON;
SET NOCOUNT ON;
DECLARE @cntr INT = 0;
WHILE @cntr < 1--000
BEGIN
  SET @cntr = @cntr + 1;
  BEGIN TRAN
  EXEC tSQLt.AssertEqualsTable 'A', 'B';
  ROLLBACK
  IF(@cntr % 100 = 0)RAISERROR('current cntr:%i',0,1,@cntr)WITH NOWAIT;
END;

--SET STATISTICS TIME OFF;

--SET STATISTICS TIME ON;
SET NOCOUNT ON;
DECLARE @cntr INT = 0;
WHILE @cntr < 500
BEGIN
  SET @cntr = @cntr + 1;
  BEGIN TRAN
    EXEC tSQLt.AssertEqualsTable_1 'A', 'B';
    EXEC tSQLt.AssertEqualsTable 'A', 'B';
--  SELECT * FROM tSQLt.TestMessage;
  ROLLBACK
  IF(@cntr % 100 = 0)RAISERROR('current cntr:%i',0,1,@cntr)WITH NOWAIT;
END;

--SET STATISTICS TIME OFF;


SELECT * FROM(
SELECT ROW_NUMBER()OVER(PARTITION BY ObjectId ORDER BY ACPU DESC, AReads DESC) AS Rn,* FROM(
SELECT COUNT(1) Cnt,ObjectId,ObjectName,AVG(Duration*1.) ADur,AVG(CPU*1.)ACPU,AVG(Reads*1.)AReads,TextData,MAX(EndTime) met
FROM(
SELECT ObjectId,ObjectName,Duration, CPU, Reads, CAST(TextData AS NVARCHAR(MAX)) AS TextData,EndTime
FROM tempdb..trc11
)x
GROUP BY ObjectId,ObjectName,TextData
HAVING COUNT(1)>1
)xx
)xxx
WHERE Rn<5 --AND ObjectId IS NOT NULL
ORDER BY ObjectId,Rn


SELECT TOP(10)* FROM(
SELECT COUNT(1) Cnt,AVG(Duration*1.) ADur,AVG(CPU*1.)ACPU,AVG(Reads*1.)AReads,CAST(TextData AS NVARCHAR(MAX)) TextData
FROM tempdb..trc5
GROUP BY CAST(TextData AS NVARCHAR(MAX))
HAVING COUNT(1)>1
)x
ORDER BY ACPU DESC, AReads DESC



UPDATE tempdb..trc11
SET TextData = 
'SELECT _=_ AS tSQLt_tempobject_________________________________, Expected.* INTO tSQLt_tempobject_________________________________            FROM @N N            LEFT JOIN A AS Expected ON N.I <> N.I          '
WHERE TextData LIKE 'SELECT _=_ AS tSQLt_tempobject_________________________________, Expected.* INTO tSQLt_tempobject_________________________________%'



DROP TABLE dbo.expected
SELECT 'DROP TABLE '+name+';' FROM sys.tables WHERE name LIKE 'tSQLt_tempobject%'


EXEC tSQLt.P