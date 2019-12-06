IF OBJECT_ID('tSQLt.FakeFunction') IS NOT NULL DROP PROCEDURE tSQLt.FakeFunction;
GO
---Build+
GO
CREATE PROCEDURE tSQLt.FakeFunction
  @FunctionName     NVARCHAR(MAX),
  @FakeFunctionName NVARCHAR(MAX) = NULL,
  @FakeDataSource   NVARCHAR(MAX) = NULL

AS
BEGIN
  DECLARE @FunctionObjectId INT;
  DECLARE @FakeFunctionObjectId INT;
  DECLARE @IsScalarFunction BIT;

  EXEC tSQLt.Private_ValidateObjectsCompatibleWithFakeFunction 
               @FunctionName = @FunctionName,
               @FakeFunctionName = @FakeFunctionName,
               @FakeDataSource   = @FakeDataSource,
               @FunctionObjectId = @FunctionObjectId OUT,
               @FakeFunctionObjectId = @FakeFunctionObjectId OUT,
               @IsScalarFunction = @IsScalarFunction OUT;

  EXEC tSQLt.RemoveObject @ObjectName = @FunctionName;

  EXEC tSQLt.Private_CreateFakeFunction 
               @FunctionName = @FunctionName,
               @FakeFunctionName = @FakeFunctionName,
               @FakeDataSource   = @FakeDataSource,
               @FunctionObjectId = @FunctionObjectId,
               @FakeFunctionObjectId = @FakeFunctionObjectId,
               @IsScalarFunction = @IsScalarFunction;

END;
GO