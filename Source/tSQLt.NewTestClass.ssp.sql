IF OBJECT_ID('tSQLt.NewTestClass') IS NOT NULL DROP PROCEDURE tSQLt.NewTestClass;
GO
---Build+
CREATE PROCEDURE [tSQLt].[NewTestClass]
     @ClassName NVARCHAR(MAX)
	,@IsMSBuild	BIT	= 0
AS
BEGIN
  BEGIN TRY
	IF (@IsMSBuild = 0)
	BEGIN
		EXEC tSQLt.Private_DisallowOverwritingNonTestSchema @ClassName;
		EXEC tSQLt.DropClass @ClassName = @ClassName;
	END;

    DECLARE @QuotedClassName NVARCHAR(MAX);
    SELECT @QuotedClassName = tSQLt.Private_QuoteClassNameForNewTestClass(@ClassName);

	IF (NOT EXISTS (SELECT 1 FROM SYS.SCHEMAS WHERE NAME = @ClassName))
		EXEC ('CREATE SCHEMA ' + @QuotedClassName);  

    EXEC tSQLt.Private_MarkSchemaAsTestClass @QuotedClassName;
  END TRY
  BEGIN CATCH
    DECLARE @ErrMsg NVARCHAR(MAX);SET @ErrMsg = ERROR_MESSAGE() + ' (Error originated in ' + ERROR_PROCEDURE() + ')';
    DECLARE @ErrSvr INT;SET @ErrSvr = ERROR_SEVERITY();
    
    RAISERROR(@ErrMsg, @ErrSvr, 10);
  END CATCH;
END;
---Build-
GO
