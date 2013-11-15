IF OBJECT_ID('tSQLt.FakeFunction') IS NOT NULL DROP PROCEDURE tSQLt.FakeFunction;
GO
CREATE PROCEDURE tSQLt.FakeFunction
  @FunctionName NVARCHAR(MAX),
  @FakeFunctionName NVARCHAR(MAX)
AS
BEGIN
  IF(OBJECT_ID(@FunctionName) IS NULL)
  BEGIN
    RAISERROR('%s does not exist!',16,10,@FunctionName);
  END;
  IF(OBJECT_ID(@FakeFunctionName) IS NULL)
  BEGIN
    RAISERROR('%s does not exist!',16,10,@FakeFunctionName);
  END;
  
  DECLARE @FunctionType CHAR(2);
  DECLARE @FakeFunctionType CHAR(2);
  SELECT @FunctionType = type FROM sys.objects WHERE object_id = OBJECT_ID(@FunctionName);
  SELECT @FakeFunctionType = type FROM sys.objects WHERE object_id = OBJECT_ID(@FakeFunctionName);

  IF((@FunctionType IN('FN','FS') AND @FakeFunctionType NOT IN('FN','FS'))
     OR
     (@FunctionType IN('TF','IF','FT') AND @FakeFunctionType NOT IN('TF','IF','FT'))
     OR
     (@FunctionType NOT IN('FN','FS','TF','IF','FT'))
     )    
  BEGIN
    RAISERROR('Both parameters must contain the name of either scalar or table valued functions!',16,10);
  END;
  
  IF(EXISTS(SELECT 1 
              FROM sys.parameters AS P
             WHERE P.object_id IN(OBJECT_ID(@FunctionName),OBJECT_ID(@FakeFunctionName))
             GROUP BY P.name, P.max_length, P.precision, P.scale, P.parameter_id
            HAVING MIN(P.object_id) = MAX(P.object_id)
           ))
  BEGIN
  	 RAISERROR('Parameters of both functions must match! (This includes the return type for scalar functions.)',16,10);
  END;

  DECLARE @ReturnType NVARCHAR(MAX);
  SELECT @ReturnType = T.TypeName
    FROM sys.parameters AS P
   CROSS APPLY tSQLt.Private_GetFullTypeName(P.user_type_id,P.max_length,P.precision,P.scale,NULL) AS T
   WHERE P.object_id = OBJECT_ID(@FunctionName)
     AND P.parameter_id = 0;
     
  DECLARE @ParameterList NVARCHAR(MAX);
  SELECT @ParameterList = COALESCE(
     STUFF((SELECT ','+P.name+' '+TypeName
              FROM sys.parameters AS P
             CROSS APPLY tSQLt.Private_GetFullTypeName(P.user_type_id,P.max_length,P.precision,P.scale,NULL) AS T
             WHERE P.object_id = OBJECT_ID(@FunctionName)
               AND P.parameter_id > 0
             ORDER BY P.parameter_id
               FOR XML PATH(''),TYPE
           ).value('.','NVARCHAR(MAX)'),1,1,''),'');
           
  DECLARE @ParameterCallList NVARCHAR(MAX);
  SELECT @ParameterCallList = COALESCE(
     STUFF((SELECT ','+P.name
              FROM sys.parameters AS P
             CROSS APPLY tSQLt.Private_GetFullTypeName(P.user_type_id,P.max_length,P.precision,P.scale,NULL) AS T
             WHERE P.object_id = OBJECT_ID(@FunctionName)
               AND P.parameter_id > 0
             ORDER BY P.parameter_id
               FOR XML PATH(''),TYPE
           ).value('.','NVARCHAR(MAX)'),1,1,''),'');

  EXEC tSQLt.RemoveObject @ObjectName = @FunctionName;

  IF(@FunctionType IN('FN','FS'))
  BEGIN
    EXEC('CREATE FUNCTION '+@FunctionName+'('+@ParameterList+') RETURNS '+@ReturnType+' AS BEGIN RETURN '+@FakeFunctionName+'('+@ParameterCallList+');END;');	
  END
  ELSE
  BEGIN
    EXEC('CREATE FUNCTION '+@FunctionName+'('+@ParameterList+') RETURNS TABLE AS RETURN SELECT * FROM '+@FakeFunctionName+'('+@ParameterCallList+');');	
  END
END;
GO