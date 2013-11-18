IF OBJECT_ID('tSQLt.Private_ValidateObjectsCompatibleWithFakeFunction') IS NOT NULL DROP PROCEDURE tSQLt.Private_ValidateObjectsCompatibleWithFakeFunction;
GO
CREATE PROCEDURE tSQLt.Private_ValidateObjectsCompatibleWithFakeFunction
  @FunctionName NVARCHAR(MAX),
  @FakeFunctionName NVARCHAR(MAX),
  @FunctionObjectId INT OUTPUT,
  @FakeFunctionObjectId INT OUTPUT,
  @IsScalarFunction BIT OUTPUT
AS
BEGIN
  SET @FunctionObjectId = OBJECT_ID(@FunctionName);
  SET @FakeFunctionObjectId = OBJECT_ID(@FakeFunctionName);

  IF(@FunctionObjectId IS NULL)
  BEGIN
    RAISERROR('%s does not exist!',16,10,@FunctionName);
  END;
  IF(@FakeFunctionObjectId IS NULL)
  BEGIN
    RAISERROR('%s does not exist!',16,10,@FakeFunctionName);
  END;
  
  DECLARE @FunctionType CHAR(2);
  DECLARE @FakeFunctionType CHAR(2);
  SELECT @FunctionType = type FROM sys.objects WHERE object_id = @FunctionObjectId;
  SELECT @FakeFunctionType = type FROM sys.objects WHERE object_id = @FakeFunctionObjectId;

  IF((@FunctionType IN('FN','FS') AND @FakeFunctionType NOT IN('FN','FS'))
     OR
     (@FunctionType IN('TF','IF','FT') AND @FakeFunctionType NOT IN('TF','IF','FT'))
     OR
     (@FunctionType NOT IN('FN','FS','TF','IF','FT'))
     )    
  BEGIN
    RAISERROR('Both parameters must contain the name of either scalar or table valued functions!',16,10);
  END;
  
  SET @IsScalarFunction = CASE WHEN @FunctionType IN('FN','FS') THEN 1 ELSE 0 END;
  
  IF(EXISTS(SELECT 1 
              FROM sys.parameters AS P
             WHERE P.object_id IN(@FunctionObjectId,@FakeFunctionObjectId)
             GROUP BY P.name, P.max_length, P.precision, P.scale, P.parameter_id
            HAVING COUNT(1) <> 2
           ))
  BEGIN
  	 RAISERROR('Parameters of both functions must match! (This includes the return type for scalar functions.)',16,10);
  END;	
END;
GO
  