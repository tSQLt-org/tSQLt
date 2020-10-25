IF OBJECT_ID('tSQLt.Private_CreateFakeFunction') IS NOT NULL DROP PROCEDURE tSQLt.Private_CreateFakeFunction;
GO
---Build+
GO
CREATE PROCEDURE tSQLt.Private_CreateFakeFunction
  @FunctionName         NVARCHAR(MAX),
  @FakeFunctionName     NVARCHAR(MAX) = NULL,
  @FunctionObjectId     INT = NULL,
  @FakeFunctionObjectId INT = NULL,
  @IsScalarFunction     BIT = NULL,
  @FakeDataSource       NVARCHAR(MAX) = NULL 
AS
BEGIN
  DECLARE @ReturnType NVARCHAR(MAX);
  SELECT @ReturnType = T.TypeName
    FROM sys.parameters AS P
   CROSS APPLY tSQLt.Private_GetFullTypeName(P.user_type_id,P.max_length,P.precision,P.scale,NULL) AS T
   WHERE P.object_id = @FunctionObjectId
     AND P.parameter_id = 0;
     
  DECLARE @ParameterList NVARCHAR(MAX);
  SELECT @ParameterList = COALESCE(
     STUFF((SELECT ','+P.name+' '+T.TypeName+CASE WHEN T.IsTableType = 1 THEN ' READONLY' ELSE '' END
              FROM sys.parameters AS P
             CROSS APPLY tSQLt.Private_GetFullTypeName(P.user_type_id,P.max_length,P.precision,P.scale,NULL) AS T
             WHERE P.object_id = @FunctionObjectId
               AND P.parameter_id > 0
             ORDER BY P.parameter_id
               FOR XML PATH(''),TYPE
           ).value('.','NVARCHAR(MAX)'),1,1,''),'');
           
  DECLARE @ParameterCallList NVARCHAR(MAX);
  SELECT @ParameterCallList = COALESCE(
     STUFF((SELECT ','+P.name
              FROM sys.parameters AS P
             CROSS APPLY tSQLt.Private_GetFullTypeName(P.user_type_id,P.max_length,P.precision,P.scale,NULL) AS T
             WHERE P.object_id = @FunctionObjectId
               AND P.parameter_id > 0
             ORDER BY P.parameter_id
               FOR XML PATH(''),TYPE
           ).value('.','NVARCHAR(MAX)'),1,1,''),'');


  IF(@IsScalarFunction = 1)
  BEGIN
    EXEC('CREATE FUNCTION '+@FunctionName+'('+@ParameterList+') RETURNS '+@ReturnType+' AS BEGIN RETURN '+@FakeFunctionName+'('+@ParameterCallList+');END;');	
  END
  ELSE IF (@FakeDataSource IS NOT NULL)
  BEGIN
    DECLARE @newTbleName NVARCHAR(MAX);
    EXEC tSQLt.Private_PrepareFakeFunctionOutputTable @FakeDataSource, @newTbleName OUTPUT;
    EXEC ('CREATE FUNCTION '+@FunctionName+'('+@ParameterList+') RETURNS TABLE AS RETURN ( SELECT * FROM '+@newTbleName+');');
  END
  ELSE
  BEGIN
    EXEC('CREATE FUNCTION '+@FunctionName+'('+@ParameterList+') RETURNS TABLE AS RETURN SELECT * FROM '+@FakeFunctionName+'('+@ParameterCallList+');');	
  END;
END;
GO
