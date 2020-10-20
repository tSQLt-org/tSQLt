IF OBJECT_ID('tSQLt.SetSummaryError') IS NOT NULL DROP PROCEDURE tSQLt.SetSummaryError;
GO
---Build+
GO
CREATE PROCEDURE tSQLt.SetSummaryError
  @SummaryError INT
AS
BEGIN
  IF(@SummaryError NOT IN (0,1))
  BEGIN
    RAISERROR('@SummaryError has to be 0 or 1, but it was: %i',16,10,@SummaryError);
  END;
  EXEC tSQLt.Private_SetConfiguration @Name = 'SummaryError', @Value = @SummaryError;
END;
GO
---Build-
GO