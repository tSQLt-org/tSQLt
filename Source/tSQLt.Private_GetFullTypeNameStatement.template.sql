IF OBJECT_ID('tSQLt.Private_GetFullTypeNameStatement') IS NOT NULL DROP FUNCTION tSQLt.Private_GetFullTypeNameStatement;
GO
---Build+
GO
CREATE FUNCTION tSQLt.Private_GetFullTypeNameStatement(@DatabaseName NVARCHAR(MAX),@TypeId NVARCHAR(MAX), @Length NVARCHAR(MAX), @Precision NVARCHAR(MAX), @Scale NVARCHAR(MAX), @CollationName NVARCHAR(MAX))
RETURNS TABLE
AS
RETURN 
SELECT '/*ReplacementToken1 GenerateGetFullTypeNameStatementFunction.ps1*/' cmd;
GO
