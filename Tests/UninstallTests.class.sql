EXEC tSQLt.NewTestClass @ClassName = 'UninstallTests';
GO
CREATE PROCEDURE UninstallTests.[test Uninstall removes schema tSQLt]
AS
BEGIN
  DECLARE @id INT;
  BEGIN TRAN;
  DECLARE @TranName CHAR(32); EXEC tSQLt.GetNewTranName @TranName OUT;
  SAVE TRAN @TranName;

  EXEC tSQLt.Uninstall;
  SET @id = SCHEMA_ID('tSQLt');

  ROLLBACK TRAN @TranName;
  COMMIT TRAN;
  
  IF @id IS NOT NULL
  BEGIN
    EXEC tSQLt.Fail 'tSQLt schema not removed';
  END;
END;
GO

CREATE PROCEDURE UninstallTests.[test Uninstall removes data type tSQLt.Private]
AS
BEGIN
  DECLARE @id INT;
  BEGIN TRAN;
  DECLARE @TranName CHAR(32); EXEC tSQLt.GetNewTranName @TranName OUT;
  SAVE TRAN @TranName;

  EXEC tSQLt.Uninstall;
  SET @id = TYPE_ID('tSQLt.Private');

  ROLLBACK TRAN @TranName;
  COMMIT TRAN;
  
  IF @id IS NOT NULL
  BEGIN
    EXEC tSQLt.Fail 'tSQLt.Private data type not removed';
  END;
END;
GO

CREATE PROCEDURE UninstallTests.[test Uninstall removes the tSQLt Assembly]
AS
BEGIN
  DECLARE @id INT;
  BEGIN TRAN;
  DECLARE @TranName CHAR(32); EXEC tSQLt.GetNewTranName @TranName OUT;
  SAVE TRAN @TranName;

  EXEC tSQLt.Uninstall;
  
  SET @id = (SELECT assembly_id FROM sys.assemblies WHERE name = 'tSQLtCLR');

  ROLLBACK TRAN @TranName;
  COMMIT TRAN;
  
  IF @id IS NOT NULL
  BEGIN
    EXEC tSQLt.Fail 'tSQLtCLR assembly not removed';
  END;
END;
GO

CREATE PROCEDURE UninstallTests.[test Uninstall removes 'tSQLt.TestClass' user]
AS
BEGIN
  DECLARE @id INT;
  BEGIN TRAN;
  DECLARE @TranName CHAR(32); EXEC tSQLt.GetNewTranName @TranName OUT;
  SAVE TRAN @TranName;

  EXEC tSQLt.Uninstall;
  SET @id = USER_ID('tSQLt.TestClass');

  ROLLBACK TRAN @TranName;
  COMMIT TRAN;
  
  IF @id IS NOT NULL
  BEGIN
    EXEC tSQLt.Fail 'tSQLt.TestClass user not removed';
  END;
END;
GO
CREATE PROCEDURE UninstallTests.[test Uninstall does not fail if the 'tSQLt.TestClass' user is missing]
AS
BEGIN
  DECLARE @id INT;
  DECLARE @ErrorMsg NVARCHAR(MAX) = NULL;
  BEGIN TRAN;
  DECLARE @TranName CHAR(32); EXEC tSQLt.GetNewTranName @TranName OUT;
  SAVE TRAN @TranName;

  DROP USER [tSQLt.TestClass];

  BEGIN TRY
    EXEC tSQLt.Uninstall;
  END TRY
  BEGIN CATCH
    SET @ErrorMsg = ERROR_MESSAGE();
  END CATCH;
  SET @id = USER_ID('tSQLt.TestClass');

  ROLLBACK TRAN @TranName;
  COMMIT TRAN;
  
  EXEC tSQLt.AssertEqualsString @Expected = NULL,
                          @Actual = @ErrorMsg,
                          @Message = N'Expected no error to be raised, but got: '
END;
GO
CREATE PROCEDURE UninstallTests.[test Uninstall fails if the 'tSQLt.TestClass' user is referenced]
AS
BEGIN
  DECLARE @id INT;
  DECLARE @ErrorNumber INT = -1;
  DECLARE @ErrorMessage NVARCHAR(MAX) = NULL;
  BEGIN TRAN;
  DECLARE @TranName CHAR(32); EXEC tSQLt.GetNewTranName @TranName OUT;
  SAVE TRAN @TranName;

  EXEC ('CREATE SCHEMA aTestSchema1 AUTHORIZATION [tSQLt.TestClass];');

  BEGIN TRY
    EXEC tSQLt.Uninstall;
  END TRY
  BEGIN CATCH
    SET @ErrorNumber = ERROR_NUMBER();
    SET @ErrorMessage = ERROR_MESSAGE();
  END CATCH;
  SET @id = USER_ID('tSQLt.TestClass');

  ROLLBACK TRAN @TranName;
  COMMIT TRAN;
  
  DECLARE @FailureMessage NVARCHAR(MAX) = N'Expected a database-principal-cannot-be-dropped message, but was: ' + ISNULL(@ErrorMessage,'No error.') + ' | For ERROR_NUMBER:';
  EXEC tSQLt.AssertEquals @Expected = 15138,
                          @Actual = @ErrorNumber,
                          @Message = @FailureMessage;
END;
GO
CREATE PROCEDURE UninstallTests.[test Uninstall does not fail if the tSQLtCLR assembly is missing]
AS
BEGIN
  DECLARE @id INT;
  DECLARE @ErrorMsg NVARCHAR(MAX) = NULL;
  BEGIN TRAN;
  DECLARE @TranName CHAR(32); EXEC tSQLt.GetNewTranName @TranName OUT;
  SAVE TRAN @TranName;

  DROP PROCEDURE tSQLt.ResultSetFilter;
  DROP PROCEDURE tSQLt.AssertResultSetsHaveSameMetaData;
  DROP PROCEDURE tSQLt.NewConnection;
  DROP PROCEDURE tSQLt.CaptureOutput;
  DROP PROCEDURE tSQLt.SuppressOutput;
  DROP FUNCTION tSQLt.Private_GetAnnotationList;
  DROP TYPE tSQLt.[Private];

  DROP ASSEMBLY tSQLtCLR;

  BEGIN TRY
    EXEC tSQLt.Uninstall;
  END TRY
  BEGIN CATCH
    SET @ErrorMsg = ERROR_MESSAGE();
  END CATCH;
  SET @id = USER_ID('tSQLt.TestClass');

  ROLLBACK TRAN @TranName;
  COMMIT TRAN;
  
  EXEC tSQLt.AssertEqualsString @Expected = NULL,
                          @Actual = @ErrorMsg,
                          @Message = N'Expected no error to be raised, but got: '
END;
GO

