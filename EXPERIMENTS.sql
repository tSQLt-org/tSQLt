
CREATE PROC RegExTests.[test an expression used ...]
AS
BEGIN
    DECLARE @re RegEx, @bin VARBINARY(MAX),@s NVARCHAR(MAX);
    SET @re = RegEx::Expr(N'??MyRegex').CaseSen;
-- insertAspect>@re = CAST(CAST(...
    EXEC tSQLt.assert
END


------------
GO


-- @n,@n2,@n3=(0,33,8),(1,13,9)
CREATE PROC RegExTests.[test an expression used ...]
  @n INT,@n2 INT,@n3 INT
AS
OR
-- @n=[0..1]
CREATE PROC RegExTests.[test an expression used ...]
  @n INT
AS

BEGIN
    DECLARE @re RegEx, @bin VARBINARY(MAX),@s NVARCHAR(MAX);

    EXEC dbo.CreateExp (@n, 'RegEx::Expr(N''??MyRegex'').CaseSen',@re OUT);
    
    EXEC tSQLt.assert
END

--
SELECT * FROM (VALUES(1,2))x(a,b)

@n INT,@n2 INT,@n3 INT VALUES(0,33,8),(1,13,9)

DECLARE @n INT,@n2 INT,@n3 INT
DECLARE cur CURSOR FAST_FORWARD FOR
SELECT * FROM (VALUES(0,33,8),(1,13,9))x([@n],[@n2],[@n3])
OPEN cur;
FETCH NEXT FROM cur INTO @n,@n2,@n3
WHILE(@@FETCH_STATUS = 0)
BEGIN
SELECT @n,@n2,@n3; --exec test case
FETCH NEXT FROM cur INTO @n,@n2,@n3
END
CLOSE cur;
DEALLOCATE cur;
