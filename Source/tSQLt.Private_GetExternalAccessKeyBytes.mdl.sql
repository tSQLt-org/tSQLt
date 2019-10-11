---Build+
GO
CREATE FUNCTION tSQLt.Private_GetExternalAccessKeyBytes()
RETURNS TABLE
AS
RETURN
  SELECT 
0x000000 
  AS ExternalAccessKeyBytes, 
  0x000001 AS ExternalAccessKeyThumbPrint;
GO
