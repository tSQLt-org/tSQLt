IF OBJECT_ID('tSQLt.Private_GetConfiguration') IS NOT NULL DROP FUNCTION tSQLt.Private_GetConfiguration;
GO
---Build+
GO
CREATE FUNCTION tSQLt.Private_GetConfiguration(
  @Name NVARCHAR(100)
)
RETURNS TABLE
AS
RETURN
  SELECT PC.Name,
         PC.Value 
    FROM tSQLt.Private_Configurations AS PC
   WHERE PC.Name = @Name;
GO
---Build-
GO
