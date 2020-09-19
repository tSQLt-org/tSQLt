---Build+
GO
CREATE FUNCTION tSQLt.Private_GetAssemblyKeyBytes()
RETURNS TABLE
AS
RETURN
  SELECT 
0x000000 
  AS AssemblyKeyBytes, 
  0x000001 AS AssemblyKeyThumbPrint;
GO
