EXEC tSQLt.NewTestClass 'Private_CreateFunctionFacadeStatementTests';
GO
CREATE PROCEDURE Private_CreateFunctionFacadeStatementTests.[test works for simple SVF]
AS
BEGIN
  EXEC('CREATE FUNCTION Private_CreateFunctionFacadeStatementTests.ASimpleSVF() RETURNS INT AS BEGIN RETURN NULL; END;');
  DECLARE @FunctionObjectId INT = OBJECT_ID('Private_CreateFunctionFacadeStatementTests.ASimpleSVF');

  DECLARE @Actual NVARCHAR(MAX) = (SELECT CreateStatement FROM tSQLt.Private_CreateFunctionFacadeStatement(@FunctionObjectId,NULL));

  DECLARE @Expected NVARCHAR(MAX) = 'CREATE FUNCTION [Private_CreateFunctionFacadeStatementTests].[ASimpleSVF]() RETURNS [sys].[int] AS BEGIN RETURN CAST(NULL AS [sys].[int]); END;';

  --SELECT * FROM sys.parameters AS P WHERE P.object_id = @FunctionObjectId;

  EXEC tSQLt.AssertEqualsString @Expected = @Expected, @Actual = @Actual;
END;
GO
CREATE PROCEDURE Private_CreateFunctionFacadeStatementTests.[test works for another simple SVF]
AS
BEGIN
  EXEC('CREATE FUNCTION Private_CreateFunctionFacadeStatementTests.AnotherSimpleSVF() RETURNS VARCHAR(MAX) AS BEGIN RETURN NULL; END;');
  DECLARE @FunctionObjectId INT = OBJECT_ID('Private_CreateFunctionFacadeStatementTests.AnotherSimpleSVF');

  DECLARE @Actual NVARCHAR(MAX) = (SELECT CreateStatement FROM tSQLt.Private_CreateFunctionFacadeStatement(@FunctionObjectId,NULL));

  DECLARE @Expected NVARCHAR(MAX) = 'CREATE FUNCTION [Private_CreateFunctionFacadeStatementTests].[AnotherSimpleSVF]() RETURNS [sys].[varchar](MAX) AS BEGIN RETURN CAST(NULL AS [sys].[varchar](MAX)); END;';

  EXEC tSQLt.AssertEqualsString @Expected = @Expected, @Actual = @Actual;
END;
GO
CREATE PROCEDURE Private_CreateFunctionFacadeStatementTests.[test works for SVF with one parameter]
AS
BEGIN
  EXEC('CREATE FUNCTION Private_CreateFunctionFacadeStatementTests.ASimpleSVF(@P1 INT) RETURNS INT AS BEGIN RETURN NULL; END;');
  DECLARE @FunctionObjectId INT = OBJECT_ID('Private_CreateFunctionFacadeStatementTests.ASimpleSVF');

  DECLARE @Actual NVARCHAR(MAX) = (SELECT CreateStatement FROM tSQLt.Private_CreateFunctionFacadeStatement(@FunctionObjectId,NULL));

  DECLARE @Expected NVARCHAR(MAX) = 'CREATE FUNCTION [Private_CreateFunctionFacadeStatementTests].[ASimpleSVF](@P1 [sys].[int]) RETURNS [sys].[int] AS BEGIN RETURN CAST(NULL AS [sys].[int]); END;';

  EXEC tSQLt.AssertEqualsString @Expected = @Expected, @Actual = @Actual;
END;
GO
CREATE PROCEDURE Private_CreateFunctionFacadeStatementTests.[test works for SVF with several parameters]
AS
BEGIN
  EXEC('CREATE FUNCTION Private_CreateFunctionFacadeStatementTests.ASimpleSVF(@P1 INT,@P2 NVARCHAR(MAX),@P3 DATETIME2) RETURNS INT AS BEGIN RETURN NULL; END;');
  DECLARE @FunctionObjectId INT = OBJECT_ID('Private_CreateFunctionFacadeStatementTests.ASimpleSVF');

  DECLARE @Actual NVARCHAR(MAX) = (SELECT CreateStatement FROM tSQLt.Private_CreateFunctionFacadeStatement(@FunctionObjectId,NULL));

  DECLARE @Expected NVARCHAR(MAX) = 'CREATE FUNCTION [Private_CreateFunctionFacadeStatementTests].[ASimpleSVF](@P1 [sys].[int],@P2 [sys].[nvarchar](MAX),@P3 [sys].[datetime2](7)) RETURNS [sys].[int] AS BEGIN RETURN CAST(NULL AS [sys].[int]); END;';

  EXEC tSQLt.AssertEqualsString @Expected = @Expected, @Actual = @Actual;
END;
GO
CREATE PROCEDURE Private_CreateFunctionFacadeStatementTests.[test produces executable statement for SVF]
AS
BEGIN
  EXEC('CREATE FUNCTION Private_CreateFunctionFacadeStatementTests.ASimpleSVF(@P1 INT,@P2 NVARCHAR(MAX),@P3 DATETIME2) RETURNS INT AS BEGIN RETURN NULL; END;');
  DECLARE @FunctionObjectId INT = OBJECT_ID('Private_CreateFunctionFacadeStatementTests.ASimpleSVF');
  SELECT 
      P.name,
      P.parameter_id,
      P.system_type_id,
      P.user_type_id,
      P.max_length,
      P.precision,
      P.scale,
      P.is_output
    INTO #Expected
    FROM sys.parameters AS P WHERE P.object_id = @FunctionObjectId;

  DECLARE @Statement NVARCHAR(MAX) = (SELECT CreateStatement FROM tSQLt.Private_CreateFunctionFacadeStatement(@FunctionObjectId,NULL));

  DROP FUNCTION Private_CreateFunctionFacadeStatementTests.ASimpleSVF;
  EXEC(@Statement);

  SELECT 
      P.name,
      P.parameter_id,
      P.system_type_id,
      P.user_type_id,
      P.max_length,
      P.precision,
      P.scale,
      P.is_output
    INTO #Actual
    FROM sys.parameters AS P WHERE P.object_id =  OBJECT_ID('Private_CreateFunctionFacadeStatementTests.ASimpleSVF');

    EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROCEDURE Private_CreateFunctionFacadeStatementTests.[test works for simple TVF]
AS
BEGIN
  EXEC('CREATE FUNCTION Private_CreateFunctionFacadeStatementTests.ASimpleTVF() RETURNS TABLE AS RETURN SELECT CAST(1 AS INT) C1;');
  DECLARE @FunctionObjectId INT = OBJECT_ID('Private_CreateFunctionFacadeStatementTests.ASimpleTVF');

  DECLARE @Actual NVARCHAR(MAX) = (SELECT CreateStatement FROM tSQLt.Private_CreateFunctionFacadeStatement(@FunctionObjectId,NULL));

  DECLARE @Expected NVARCHAR(MAX) = 'CREATE FUNCTION [Private_CreateFunctionFacadeStatementTests].[ASimpleTVF]() RETURNS TABLE AS RETURN SELECT TOP(0) CAST(NULL AS [sys].[int]) AS [C1];';

  EXEC tSQLt.AssertEqualsString @Expected = @Expected, @Actual = @Actual;
END;
GO
CREATE PROCEDURE Private_CreateFunctionFacadeStatementTests.[test works for TVF with parameters and multiple return columns]
AS
BEGIN
  EXEC('CREATE FUNCTION Private_CreateFunctionFacadeStatementTests.ASimpleTVF(@P1 BIGINT,@P2 DATE,@P3 CHAR(17),@P4 BIT) RETURNS TABLE AS RETURN SELECT CAST(1 AS SMALLINT) C1, CAST(NULL AS DATETIME) C2, CAST(NULL AS XML)  C3;');
  DECLARE @FunctionObjectId INT = OBJECT_ID('Private_CreateFunctionFacadeStatementTests.ASimpleTVF');

  DECLARE @Actual NVARCHAR(MAX) = (SELECT CreateStatement FROM tSQLt.Private_CreateFunctionFacadeStatement(@FunctionObjectId,NULL));

  DECLARE @Expected NVARCHAR(MAX) = 'CREATE FUNCTION [Private_CreateFunctionFacadeStatementTests].[ASimpleTVF](@P1 [sys].[bigint],@P2 [sys].[date],@P3 [sys].[char](17),@P4 [sys].[bit]) RETURNS TABLE AS RETURN SELECT TOP(0) CAST(NULL AS [sys].[smallint]) AS [C1],CAST(NULL AS [sys].[datetime]) AS [C2],CAST(NULL AS [sys].[xml]) AS [C3];';

  EXEC tSQLt.AssertEqualsString @Expected = @Expected, @Actual = @Actual;
END;
GO
CREATE PROCEDURE Private_CreateFunctionFacadeStatementTests.[test returns executable statement for TVF]
AS
BEGIN
  EXEC('CREATE FUNCTION Private_CreateFunctionFacadeStatementTests.ASimpleTVF(@P1 BIGINT,@P2 DATE,@P3 CHAR(17),@P4 BIT) RETURNS TABLE AS RETURN SELECT CAST(1 AS SMALLINT) C1, CAST(NULL AS DATETIME) C2, CAST(NULL AS XML)  C3;');
  DECLARE @FunctionObjectId INT = OBJECT_ID('Private_CreateFunctionFacadeStatementTests.ASimpleTVF');

  SELECT 
      source = 'P',
      P.name,
      P.parameter_id,
      P.system_type_id,
      P.user_type_id,
      P.max_length,
      P.precision,
      P.scale,
      P.is_output
    INTO #Expected
    FROM sys.parameters AS P WHERE P.object_id = @FunctionObjectId
   UNION ALL
  SELECT 
      source = 'C',
      C.name,
      C.column_id,
      C.system_type_id,
      C.user_type_id,
      C.max_length,
      C.precision,
      C.scale,
      NULL
    FROM sys.columns AS C WHERE C.object_id = @FunctionObjectId;

  DECLARE @Statement NVARCHAR(MAX) = (SELECT CreateStatement FROM tSQLt.Private_CreateFunctionFacadeStatement(@FunctionObjectId,NULL));

  DROP FUNCTION Private_CreateFunctionFacadeStatementTests.ASimpleTVF;
  EXEC(@Statement);

  SELECT 
      source = 'P',
      P.name,
      P.parameter_id,
      P.system_type_id,
      P.user_type_id,
      P.max_length,
      P.precision,
      P.scale,
      P.is_output
    INTO #Actual
    FROM sys.parameters AS P WHERE P.object_id = OBJECT_ID('Private_CreateFunctionFacadeStatementTests.ASimpleTVF')
   UNION ALL
  SELECT 
      source = 'C',
      C.name,
      C.column_id,
      C.system_type_id,
      C.user_type_id,
      C.max_length,
      C.precision,
      C.scale,
      NULL
    FROM sys.columns AS C WHERE C.object_id = OBJECT_ID('Private_CreateFunctionFacadeStatementTests.ASimpleTVF');

    EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROCEDURE Private_CreateFunctionFacadeStatementTests.[test allows for return value for SVF to be specified]
AS
BEGIN
  EXEC('CREATE FUNCTION Private_CreateFunctionFacadeStatementTests.AnotherSimpleSVF() RETURNS NUMERIC(10,2) AS BEGIN RETURN NULL; END;');
  DECLARE @FunctionObjectId INT = OBJECT_ID('Private_CreateFunctionFacadeStatementTests.AnotherSimpleSVF');

  DECLARE @Actual NVARCHAR(MAX) = (SELECT CreateStatement FROM tSQLt.Private_CreateFunctionFacadeStatement(@FunctionObjectId,'42.84'));

  DECLARE @Expected NVARCHAR(MAX) = 'CREATE FUNCTION [Private_CreateFunctionFacadeStatementTests].[AnotherSimpleSVF]() RETURNS [sys].[numeric](10,2) AS BEGIN RETURN CAST(''42.84'' AS [sys].[numeric](10,2)); END;';

  EXEC tSQLt.AssertEqualsString @Expected = @Expected, @Actual = @Actual;
END;
GO
