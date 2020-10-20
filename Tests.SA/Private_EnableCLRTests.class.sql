EXEC tSQLt.NewTestClass 'Private_EnableCLRTests';
GO
CREATE PROCEDURE Private_EnableCLRTests.[test alters value for 'clr enabled' in serverconfigurations]
AS
BEGIN
  EXEC tSQLt.CaptureOutput 'EXEC sys.sp_configure @configname=''clr enabled'', @configvalue=0;';
  
  BEGIN TRY
    EXEC tSQLt.Private_EnableCLR;
  END TRY
  BEGIN CATCH
    PRINT ERROR_MESSAGE();
  END CATCH

  SELECT name,value
    INTO #Actual
    FROM sys.configurations AS C
   WHERE C.name = 'clr enabled';

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected VALUES('clr enabled',1);
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
   
END;
GO
CREATE PROCEDURE Private_EnableCLRTests.[test does not alter other values in serverconfigurations]
AS
BEGIN
  SELECT C.name,
         C.value
    INTO #Expected
    FROM master.sys.configurations AS C
   WHERE name <> 'clr enabled';

  BEGIN TRY
    EXEC tSQLt.Private_EnableCLR;
  END TRY
  BEGIN CATCH
    PRINT ERROR_MESSAGE();
  END CATCH

  SELECT name,value
    INTO #Actual
    FROM sys.configurations AS C
   WHERE C.name <> 'clr enabled';

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
   
END;
GO
CREATE PROCEDURE Private_EnableCLRTests.[test calls RECONFIGURE]
AS
BEGIN
   EXEC tSQLt.ExpectException @ExpectedMessage = 'CONFIG statement cannot be used inside a user transaction.';

   EXEC tSQLt.Private_EnableCLR;
END;
GO
