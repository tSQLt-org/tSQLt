IF OBJECT_ID('tSQLt.Private_GetSQLProductMajorVersion') IS NOT NULL DROP PROCEDURE tSQLt.Private_GetSQLProductMajorVersion;
GO
---Build+
GO
CREATE PROCEDURE tSQLt.Private_GetSQLProductMajorVersion
AS
  RETURN CAST(PARSENAME(CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(MAX)),4) AS INT);
GO
---Build-
GO
DECLARE @Version INT;
EXEC @Version = tSQLt.Private_GetSQLProductMajorVersion;
PRINT 'SQL Major Version: '+CAST(@Version as NVARCHAR(MAX));

