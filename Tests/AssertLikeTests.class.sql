EXEC tSQLt.NewTestClass 'AssertLikeTests';
GO
CREATE PROC [AssertLikeTests].[test AssertLike fails when expectedPattern value IS NULL and actual value IS NOT NULL]
AS
BEGIN
    DECLARE @Command NVARCHAR(MAX); SET @Command = 'EXEC tSQLt.AssertLike NULL, ''1'';';
    EXEC tSQLt_testutil.assertFailCalled @Command, 'AssertLike did not call Fail';
END;
GO

CREATE PROC [AssertLikeTests].[test AssertLike fails when expectedPattern value IS NOT NULL and actual value IS NULL]
AS
BEGIN
    DECLARE @Command NVARCHAR(MAX); SET @Command = 'EXEC tSQLt.AssertLike ''Test'', NULL;';
    EXEC tSQLt_testutil.assertFailCalled @Command, 'AssertLike did not call Fail';
END;
GO

CREATE PROC [AssertLikeTests].[test AssertLike succeeds when expectedPattern value IS NULL and actual value IS NULL]
AS
BEGIN
    EXEC tSQLt.AssertLike NULL, NULL;
END;
GO

CREATE PROC [AssertLikeTests].[test AssertLike supports exact match]
AS
BEGIN
    EXEC tSQLt.AssertLike 'Exact match test.', 'Exact match test.';
END;
GO

CREATE PROC [AssertLikeTests].[test AssertLike supports wildcard match]
AS
BEGIN
    EXEC tSQLt.AssertLike '%cat%', 'concatenate';
END;
GO

CREATE PROC [AssertLikeTests].[test AssertLike supports wildcard range match]
AS
BEGIN
    EXEC tSQLt.AssertLike 'cr[a-d]ft', 'craft';
END;
GO

CREATE PROC [AssertLikeTests].[test AssertLike supports wildcard characters as literals when escaped with brackets]
AS
BEGIN
    EXEC tSQLt.AssertLike '[[]object_schema].[[]object[_]name]', '[object_schema].[object_name]';
END;
GO

CREATE PROC [AssertLikeTests].[test AssertLike fails literal match when wildcards in expectedPattern are not escaped]
AS
BEGIN
    DECLARE @Command NVARCHAR(MAX); SET @Command = 'EXEC tSQLt.AssertLike ''[quotedname]'', [quotedname];';
    EXEC tSQLt_testutil.assertFailCalled @Command, 'AssertLike did not call Fail';
END;
GO

CREATE PROC [AssertLikeTests].[test AssertLike errors when length of @ExpectedPattern is over 4000 characters]
AS
BEGIN
  DECLARE @Error NVARCHAR(MAX); SET @Error = '<No Error>';
  BEGIN TRY
    DECLARE @TooLongPattern NVARCHAR(MAX); SET @TooLongPattern = REPLICATE(CAST(N'x' AS NVARCHAR(MAX)),4001);
    EXEC tSQLt.AssertLike @TooLongPattern, '';
  END TRY
  BEGIN CATCH
    SET @Error =ERROR_MESSAGE();
  END CATCH;  
  
  EXEC tSQLt.AssertLike '%[@]ExpectedPattern may not exceed 4000 characters%', @Error;
END;
GO

CREATE PROC [AssertLikeTests].[test AssertLike can handle length of @ExpectedPattern equal to 4000 characters]
AS
BEGIN
  DECLARE @NotTooLongPattern NVARCHAR(MAX); SET @NotTooLongPattern = REPLICATE(CAST(N'x' AS NVARCHAR(MAX)),4000);
  EXEC tSQLt.AssertLike @NotTooLongPattern, @NotTooLongPattern;
END;
GO

CREATE PROC [AssertLikeTests].[test AssertLike returns helpful message on failure]
AS
BEGIN
	DECLARE @Command NVARCHAR(MAX); SET @Command = ' EXEC tSQLt.AssertLike ''craft'', ''cruft'';';
	EXEC tSQLt_testutil.AssertFailMessageEquals @Command, '
Expected: <craft>
 but was: <cruft>';
END;
GO

CREATE PROC [AssertLikeTests].[test AssertLike allows custom failure message]
AS
BEGIN
	DECLARE @Command NVARCHAR(MAX); SET @Command = ' EXEC tSQLt.AssertLike ''craft'', ''cruft'', ''Custom Fail Message'';';
	EXEC tSQLt_testutil.AssertFailMessageEquals @Command, 'Custom Fail Message
Expected: <craft>
 but was: <cruft>';
END;
GO