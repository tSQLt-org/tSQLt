
EXEC('PRINT ''$(parameter1)'';')




GO
CREATE PROCEDURE #somethingrather
AS
BEGIN
  RETURN;
END;
GO
SELECT * FROM sys.procedures
SELECT * FROM tempdb.sys.procedures AS P
GO
IF OBJECT_ID('tempdb..#PrepareServer') IS NOT NULL DROP PROCEDURE tempdb..#PrepareServer;
EXEC('
CREATE PROCEDURE tempdb..#PrepareServer
AS
BEGIN
  SELECT DB_NAME();
END;
');
SELECT * FROM tempdb.sys.procedures AS P
EXEC tempdb..#PrepareServer;
GO
EXEC('
CREATE TABLE #SuchATable(id INT)
');
SELECT * FROM tempdb.sys.tables AS P
GO
CREATE PROCEDURE #ScopeTest
AS
BEGIN
  EXEC('CREATE PROC #Inner1 AS BEGIN RETURN END;');
  EXEC #Inner1;
END;
GO
EXEC #ScopeTest

GO
------------------------------------------------------------
IF OBJECT_ID('') IS NOT NULL DROP PROCEDURE ;
IF OBJECT_ID('') IS NOT NULL DROP PROCEDURE ;
IF OBJECT_ID('') IS NOT NULL DROP PROCEDURE ;
IF OBJECT_ID('') IS NOT NULL DROP PROCEDURE ;
IF OBJECT_ID('') IS NOT NULL DROP PROCEDURE ;
IF OBJECT_ID('') IS NOT NULL DROP PROCEDURE ;
GO
CREATE PROCEDURE #...
GO
CREATE FUNCTION #xxx
RETURNS TABLE
AS
RETURN
SELECT 'abcd' xxx
GO
