IF OBJECT_ID('tSQLt.Private_ValidateObjectsCompatibleWithFakeFunction') IS NOT NULL DROP PROCEDURE tSQLt.Private_ValidateObjectsCompatibleWithFakeFunction;
GO
---Build+
GO
CREATE PROCEDURE tSQLt.Private_ValidateObjectsCompatibleWithFakeFunction
  @FunctionName         NVARCHAR(MAX),
  @FakeFunctionName     NVARCHAR(MAX) = NULL,
  @FakeDataSource       NVARCHAR(MAX) = NULL,
  @FunctionObjectId     INT = NULL OUTPUT,
  @FakeFunctionObjectId INT = NULL OUTPUT,
  @IsScalarFunction     BIT = NULL OUTPUT
AS
BEGIN
  SET @FunctionObjectId = OBJECT_ID(@FunctionName);

  IF(@FunctionObjectId IS NULL)
  BEGIN
    RAISERROR('%s does not exist!',16,10,@FunctionName);
  END;

   IF COALESCE(@FakeFunctionName, @FakeDataSource) IS NULL
   BEGIN
      RAISERROR ('Either @FakeFunctionName or @FakeDataSource must be provided', 16, 10);
   END;

   IF (@FakeFunctionName  IS NOT NULL  AND @FakeDataSource IS NOT NULL )
   BEGIN
      RAISERROR ('Both @FakeFunctionName and @FakeDataSource are valued. Please use only one.', 16, 10);
   END;

   IF (@FakeDataSource IS NOT NULL ) 
   BEGIN
      IF NOT EXISTS (
         SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(@FunctionName) and type in ('TF', 'IF')
      ) 
      BEGIN
         RAISERROR('You can use @FakeDataSource only with Inline or Multi-Statement Table-Valued functions.', 16, 10);
      END
      
	  RETURN 0;
   END

  SET @FakeFunctionObjectId = OBJECT_ID(@FakeFunctionName);
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
