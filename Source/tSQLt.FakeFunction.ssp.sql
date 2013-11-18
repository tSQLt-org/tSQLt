IF OBJECT_ID('tSQLt.FakeFunction') IS NOT NULL DROP PROCEDURE tSQLt.FakeFunction;
GO
CREATE PROCEDURE tSQLt.FakeFunction
  @FunctionName NVARCHAR(MAX),
  @FakeFunctionName NVARCHAR(MAX)
AS
BEGIN
  DECLARE @FunctionObjectId INT;
  DECLARE @FakeFunctionObjectId INT;
  DECLARE @IsScalarFunction BIT;

  EXEC tSQLt.Private_ValidateObjectsCompatibleWithFakeFunction 
               @FunctionName = @FunctionName,
               @FakeFunctionName = @FakeFunctionName,
               @FunctionObjectId = @FunctionObjectId OUT,
               @FakeFunctionObjectId = @FakeFunctionObjectId OUT,
               @IsScalarFunction = @IsScalarFunction OUT;

  EXEC tSQLt.RemoveObject @ObjectName = @FunctionName;

  EXEC tSQLt.Private_CreateFakeFunction 
               @FunctionName = @FunctionName,
               @FakeFunctionName = @FakeFunctionName,
               @FunctionObjectId = @FunctionObjectId,
               @FakeFunctionObjectId = @FakeFunctionObjectId,
               @IsScalarFunction = @IsScalarFunction;

END;
GO
