EXEC tSQLt.NewTestClass 'Run_Methods_Tests_2008';
GO
CREATE PROCEDURE Run_Methods_Tests_2008.[test tSQLt.Private_InputBuffer does not produce output]
AS
BEGIN
  DECLARE @Actual NVARCHAR(MAX);SET @Actual = '<Something went wrong!>';

  EXEC tSQLt.CaptureOutput 'DECLARE @r NVARCHAR(MAX);EXEC tSQLt.Private_InputBuffer @r OUT;';

  SELECT @Actual  = COL.OutputText FROM tSQLt.CaptureOutputLog AS COL;
  
  EXEC tSQLt.AssertEqualsString @Expected = NULL, @Actual = @Actual;
END
GO
