IF OBJECT_ID('tSQLt.Private_GetAssemblyKeyBytes') IS NOT NULL DROP PROCEDURE tSQLt.Private_GetAssemblyKeyBytes;
GO

---Build+
GO
CREATE PROCEDURE tSQLt.Private_GetAssemblyKeyBytes
   @AssemblyKeyBytes VARBINARY(MAX) = NULL OUTPUT,
   @AssemblyKeyThumbPrint VARBINARY(MAX) = NULL OUTPUT
AS
  SELECT @AssemblyKeyBytes =
0x000000 
  ,@AssemblyKeyThumbPrint = 0x000001 ;
GO
---Build-
GO
