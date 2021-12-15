EXEC tSQLt.NewTestClass 'Private_GetFormattedErrorInfoTests';
GO
CREATE PROCEDURE Private_GetFormattedErrorInfoTests.[test does not return null]
AS
BEGIN
  DECLARE @FormattedError NVARCHAR(MAX) = (SELECT FormattedError FROM tSQLt.Private_GetFormattedErrorInfo());

  EXEC tSQLt.AssertEqualsString @Expected = 'Message: <NULL> | Procedure: <NULL> | Severity, State: <NULL>, <NULL> | Number: <NULL>', @Actual = @FormattedError;
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE Private_GetFormattedErrorInfoTests.[test returns the ERROR information formatted correctly]
AS
BEGIN
  DECLARE @FormattedError NVARCHAR(MAX);

  BEGIN TRY
    EXEC ('RAISERROR(''my test message'', 15, 11);');
  END TRY
  BEGIN CATCH
    SET @FormattedError = (SELECT FormattedError FROM tSQLt.Private_GetFormattedErrorInfo());
  END CATCH;

  EXEC tSQLt.AssertEqualsString @Expected = 'Message: my test message | Procedure: <NULL> (1) | Severity, State: 15, 11 | Number: 50000', @Actual = @FormattedError;
END
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE Private_GetFormattedErrorInfoTests.[test returns the correct ERROR number]
AS
BEGIN
  DECLARE @FormattedError NVARCHAR(MAX);

  BEGIN TRY
    EXEC ('RAISERROR (13042,14,13);');
  END TRY
  BEGIN CATCH
    SET @FormattedError = (SELECT FormattedError FROM tSQLt.Private_GetFormattedErrorInfo());
  END CATCH;

  EXEC tSQLt.AssertLike @ExpectedPattern = '%| Number: 13042', @Actual = @FormattedError;
END
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE Private_GetFormattedErrorInfoTests.[test returns the correct ERROR procedure name and line number]
AS
BEGIN
  DECLARE @FormattedError NVARCHAR(MAX);

  BEGIN TRY
    EXEC ('/*Line 1*/CREATE PROCEDURE #myInnerError
           /*Line 2*/AS
           /*Line 3*/BEGIN 
           /*Line 4*/  RAISERROR (13042,14,13);
           /*Line 5*/END;');
    EXEC #myInnerError;
  END TRY
  BEGIN CATCH
    SET @FormattedError = (SELECT FormattedError FROM tSQLt.Private_GetFormattedErrorInfo());
  END CATCH;

  EXEC tSQLt.AssertLike @ExpectedPattern = '%| Procedure: #myInnerError (4) |%', @Actual = @FormattedError;
END
GO
/*-----------------------------------------------------------------------------------------------*/
GO
