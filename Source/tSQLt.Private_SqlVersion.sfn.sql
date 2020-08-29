IF OBJECT_ID('tSQLt.Private_SqlVersion') IS NOT NULL DROP FUNCTION tSQLt.Private_SqlVersion;
GO
---Build+
GO
CREATE FUNCTION tSQLt.Private_SqlVersion()
RETURNS TABLE
AS
RETURN
  SELECT PARSENAME(SP.ProductVersion,4) Major,
         PARSENAME(SP.ProductVersion,3) Minor, 
         PARSENAME(SP.ProductVersion,2) Build,
         PARSENAME(SP.ProductVersion,1) Revision,
         SP.ProductVersion,
         SP.Edition
    FROM 
    (
      SELECT CAST(SERVERPROPERTY('ProductVersion')AS NVARCHAR(128)) ProductVersion,
             CAST(SERVERPROPERTY('Edition')AS NVARCHAR(128)) Edition
    )SP
GO
---Build-
GO
