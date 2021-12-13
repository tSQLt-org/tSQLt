IF OBJECT_ID('tSQLt.Private_HandleMessageAndResult') IS NOT NULL DROP FUNCTION tSQLt.Private_HandleMessageAndResult;
GO
---Build+
GO
CREATE FUNCTION tSQLt.Private_HandleMessageAndResult (
  @PrevMessage NVARCHAR(MAX),
  @PrevResult NVARCHAR(MAX),
  @NewMessage NVARCHAR(MAX),
  @NewResult NVARCHAR(MAX)
)
RETURNS TABLE
AS
RETURN
  SELECT '<NULL> [Result: <NULL>] || '+ISNULL(@NewMessage,'<NULL>') Message;
GO
---Build-
GO
