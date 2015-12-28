CREATE FUNCTION tSQLt_testutil.GetUnsignedEmptyBytes()
RETURNS TABLE
AS
RETURN
  SELECT 0x000000 AS UnsignedEmptyBytes;
