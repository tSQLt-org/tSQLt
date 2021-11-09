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
  DECLARE @NewNameOfOriginalFunction NVARCHAR(MAX);

  EXEC tSQLt.Private_ValidateObjectsCompatibleWithFakeFunction 
               @FunctionName = @FunctionName,
               @FakeFunctionName = @FakeFunctionName,
               @FakeDataSource   = @FakeDataSource,
               @FunctionObjectId = @FunctionObjectId OUT,
               @FakeFunctionObjectId = @FakeFunctionObjectId OUT,
               @IsScalarFunction = @IsScalarFunction OUT;

  EXEC tSQLt.RemoveObject
               @ObjectName = @FunctionName,
               @NewName = @NewNameOfOriginalFunction OUTPUT;

  EXEC tSQLt.Private_CreateFakeFunction 
               @FunctionName = @FunctionName,
               @FakeFunctionName = @FakeFunctionName,
               @FakeDataSource   = @FakeDataSource,
               @FunctionObjectId = @FunctionObjectId,
               @FakeFunctionObjectId = @FakeFunctionObjectId,
               @IsScalarFunction = @IsScalarFunction;

  EXEC tSQLt.Private_MarktSQLtTempObject
               @ObjectName = @FunctionName,
               @ObjectType = N'FUNCTION',
               @NewNameOfOriginalObject = @NewNameOfOriginalFunction;

END;
GO
