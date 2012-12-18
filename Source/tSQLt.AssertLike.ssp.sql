IF OBJECT_ID('[tSQLt].[AssertLike]') IS NOT NULL DROP PROCEDURE [tSQLt].[AssertLike];
GO
CREATE PROCEDURE [tSQLt].[AssertLike] 
  @ExpectedPattern NVARCHAR(MAX),
  @Actual NVARCHAR(MAX),
  @Message NVARCHAR(MAX) = ''
AS
BEGIN
  IF (LEN(@ExpectedPattern) > 4000)
  BEGIN
    RAISERROR ('@ExpectedPattern may not exceed 4000 characters.', 16, 10);
  END;

  IF ((@Actual LIKE @ExpectedPattern) OR (@Actual IS NULL AND @ExpectedPattern IS NULL))
  BEGIN
    RETURN 0;
  END

  DECLARE @Msg NVARCHAR(MAX);
  SELECT @Msg = CHAR(13) + CHAR(10) + 'Expected: <' + ISNULL(@ExpectedPattern, 'NULL') + '>' +
                CHAR(13) + CHAR(10) + ' but was: <' + ISNULL(@Actual, 'NULL') + '>';
  EXEC tSQLt.Fail @Message, @Msg;
END;
GO
