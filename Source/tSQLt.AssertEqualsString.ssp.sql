IF OBJECT_ID('tSQLt.AssertEqualsString') IS NOT NULL DROP PROCEDURE tSQLt.AssertEqualsString;
GO
---Build+
GO
CREATE PROCEDURE tSQLt.AssertEqualsString
    @Expected NVARCHAR(MAX),
    @Actual NVARCHAR(MAX),
    @Message NVARCHAR(MAX) = ''
AS
BEGIN
    IF ((@Expected = @Actual) OR (@Actual IS NULL AND @Expected IS NULL))
      RETURN 0;

    DECLARE @Msg NVARCHAR(MAX);
    SELECT @Msg = CHAR(13)+CHAR(10)+
                  'Expected: ' + ISNULL('<'+@Expected+'>', 'NULL') +
                  CHAR(13)+CHAR(10)+
                  'but was : ' + ISNULL('<'+@Actual+'>', 'NULL');
    EXEC tSQLt.Fail @Message, @Msg;
END;
GO
---Build-
GO