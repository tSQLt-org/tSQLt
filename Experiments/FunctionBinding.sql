IF OBJECT_ID('dbo.CheckFnA') IS NOT NULL DROP TABLE dbo.CheckFnA;
IF OBJECT_ID('dbo.FnB') IS NOT NULL DROP FUNCTION dbo.FnB;
IF OBJECT_ID('dbo.FnA') IS NOT NULL DROP FUNCTION dbo.FnA;
IF OBJECT_ID('dbo.FnA2') IS NOT NULL DROP FUNCTION dbo.FnA2;
GO
CREATE FUNCTION dbo.FnA()
RETURNS INT
AS
BEGIN
  RETURN 3;
END;
GO
CREATE FUNCTION dbo.FnA2()
RETURNS INT
AS
BEGIN
  RETURN 3;
END;
GO
CREATE FUNCTION dbo.FnB()
RETURNS INT
AS
BEGIN
  RETURN dbo.FnA();
END;
GO
BEGIN TRAN;
BEGIN TRY
  DROP FUNCTION dbo.FnA;
  RAISERROR('Drop Successful!',0,1)WITH NOWAIT;
END TRY
BEGIN CATCH
  RAISERROR('Drop Unsuccessful!',0,1)WITH NOWAIT;
END CATCH;
ROLLBACK;
GO
CREATE TABLE dbo.CheckFnA(
 Id INT CHECK (dbo.FnA() = 3),
 val AS (dbo.FnA())
)
GO
INSERT INTO dbo.CheckFnA(Id)VALUES(13);
GO
BEGIN TRAN;
BEGIN TRY
  DROP FUNCTION dbo.FnA;
  RAISERROR('Drop Successful!',0,1)WITH NOWAIT;
END TRY
BEGIN CATCH
  DECLARE @msg NVARCHAR(MAX);SET @msg = ERROR_MESSAGE();
  RAISERROR('Drop Unsuccessful:%s',0,1,@msg)WITH NOWAIT;
END CATCH;
ROLLBACK;
GO

BEGIN TRAN;
BEGIN TRY
  EXEC sp_rename 'dbo.FnA','FnA_XX';
  RAISERROR('rename Successful!',0,1)WITH NOWAIT;
END TRY
BEGIN CATCH
  DECLARE @msg NVARCHAR(MAX);SET @msg = ERROR_MESSAGE();
  RAISERROR('rename Unsuccessful:%s',0,1,@msg)WITH NOWAIT;
END CATCH;
ROLLBACK;
GO
ALTER FUNCTION dbo.FnA()
RETURNS INT
AS
BEGIN
  RETURN dbo.FnA2()
END
GO
SELECT OBJECT_NAME(sd.object_id),* 
FROM sys.sql_dependencies sd
LEFT JOIN sys.check_constraints cc
ON sd.object_id = cc.object_id
LEFT JOIN sys.sql_modules sm
ON sd.object_id = sm.object_id
WHERE sd.referenced_major_id = OBJECT_ID('dbo.FnA');

SELECT * FROM sys.sql_expression_dependencies sed
WHERE sed.referenced_id = OBJECT_ID('dbo.FnA');
