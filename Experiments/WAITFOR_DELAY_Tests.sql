DROP TABLE IF EXISTS dbo.timelog;
GO
CREATE TABLE dbo.timelog(
  id INT IDENTITY(1,1),
  [@a] DATETIME2,
  [@c] DATETIME2,
  [@b] DATETIME2
);
GO
SET NOCOUNT ON;
GO
CREATE PROCEDURE dbo.loopy
  @loopcount INT = 100000
AS
BEGIN
  DECLARE @a DATETIME2, @b DATETIME2,@c DATETIME2;
  WHILE(@loopcount > 0)
  BEGIN
    SET @a = SYSDATETIME();
    EXEC sp_executesql N'WAITFOR DELAY ''00:00:00.111'';SET @c = SYSDATETIME();',N'@c DATETIME2 OUTPUT', @c OUT;
    SET @b = SYSDATETIME();
    INSERT INTO dbo.timelog
    SELECT @a,@c,@b;
    SET @loopcount -=1;
  END;
END;
GO
EXEC dbo.loopy 1000000;
GO
SELECT [@a],[@c],[@b],DATEDIFF(MICROSECOND,[@a],[@b])[@b-@a],DATEDIFF(MICROSECOND,[@a],[@c])[@c-@a],DATEDIFF(MICROSECOND,[@c],[@b])[@b-@c]
  FROM dbo.timelog AS T;
GO