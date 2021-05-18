EXEC tSQLt.NewTestClass 'Facade_CreateFacadeDb_Tests';
GO
CREATE PROCEDURE Facade_CreateFacadeDb_Tests.[test CreateSSPFacade works for simple ssp]
AS
BEGIN
  EXEC('CREATE PROC dbo.AProc AS RETURN;'); 
  EXEC Facade.CreateSSPFacade @FacadeDbName = 'tSQLtFacade', @Name = 'dbo.AProc';
  DECLARE @Actual NVARCHAR(MAX);
  SELECT @Actual = definition FROM tSQLtFacade.sys.sql_modules WHERE object_id = OBJECT_ID('tSQLtFacade.dbo.AProc');
  
  EXEC tSQLt.AssertEqualsString @Expected = 'dbo.', @Actual = @Actual;
END;
GO
