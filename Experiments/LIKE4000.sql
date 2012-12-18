SELECT *
INTO #td
FROM (
VALUES(
N'before+before+before+before+before+before+'+REPLICATE(CAST('12345' AS NVARCHAR(MAX)),4000)+N'+after+after+after+after+after+after',
'%'+REPLICATE(CAST('12345' AS NVARCHAR(MAX)),800)+'%'
))X(s,p);
GO
RAISERROR('direct select',0,1)WITH NOWAIT;

SELECT *
FROM (VALUES('direct'))AS L(loc)
LEFT OUTER JOIN #td td
ON td.s LIKE td.p;
GO
CREATE PROCEDURE #tttt
@s NVARCHAR(MAX),
@p NVARCHAR(4000)
AS
SELECT *
FROM (VALUES('proc'))AS L(loc)
LEFT OUTER JOIN
(VALUES(@s)) AS X(s)
ON s LIKE @p;
GO
RAISERROR('procedure call',0,1)WITH NOWAIT;

DECLARE @s NVARCHAR(MAX);
DECLARE @p NVARCHAR(MAX);
SELECT @s = s, @p = p FROM #td;

EXEC #tttt @s, @p;

GO

DROP PROC #tttt
DROP TABLE #td