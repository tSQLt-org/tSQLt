EXEC tSQLt.NewTestClass 'Run_Methods_Tests_EA';
GO
CREATE TABLE Run_Methods_Tests_EA.[table 4 tSQLt.Private_InputBuffer tests](
  InputBuffer NVARCHAR(MAX)
);
GO
--[@tSQLt:RunOnlyOnHostPlatform]('Windows')
CREATE PROCEDURE Run_Methods_Tests_EA.[test tSQLt.Private_InputBuffer returns actual INPUTBUFFER]
AS
BEGIN
  EXEC tSQLt.NewConnection @command = 'TRUNCATE TABLE Run_Methods_Tests_EA.[table 4 tSQLt.Private_InputBuffer tests]';
  DECLARE @ExecutedCmd NVARCHAR(MAX);
  SET @ExecutedCmd = 'DECLARE @r NVARCHAR(MAX);EXEC tSQLt.Private_InputBuffer @r OUT;INSERT INTO Run_Methods_Tests_EA.[table 4 tSQLt.Private_InputBuffer tests] SELECT @r;'
  EXEC tSQLt.NewConnection @command = @ExecutedCmd;
  DECLARE @Actual NVARCHAR(MAX);
  SELECT @Actual = InputBuffer FROM Run_Methods_Tests_EA.[table 4 tSQLt.Private_InputBuffer tests];
  EXEC tSQLt.AssertEqualsString @Expected = @ExecutedCmd, @Actual = @Actual;
END
GO
