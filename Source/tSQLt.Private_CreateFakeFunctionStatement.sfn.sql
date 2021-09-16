IF OBJECT_ID('tSQLt.Private_CreateFakeFunctionStatement') IS NOT NULL DROP FUNCTION tSQLt.Private_CreateFakeFunctionStatement;
GO
---Build+
GO
CREATE FUNCTION tSQLt.Private_CreateFakeFunctionStatement(
  @FunctionObjectId INT,
  @ReturnValue NVARCHAR(MAX)
)
RETURNS TABLE
AS
RETURN
  SELECT 
      'CREATE FUNCTION ' + QUOTENAME(OBJECT_SCHEMA_NAME(@FunctionObjectId)) + '.' + QUOTENAME(OBJECT_NAME(@FunctionObjectId)) + 
      '(' +
      ISNULL(PAS.ParametersAndReturnScalar, '') + 
      ISNULL(') RETURNS TABLE AS RETURN ' + T.TypeOnlySelectStatement,'') + ';' CreateStatement,
      T.TypeOnlySelectStatement
    FROM
    (
      SELECT 
          (
            SELECT 
              CASE P.is_output 
              WHEN 0 THEN CASE WHEN P._RN_ = 1 THEN '' ELSE ',' END +P.name+' '+T.TypeName
              WHEN 1 THEN ') RETURNS '+T.TypeName+' AS BEGIN RETURN CAST('+ISNULL(''''+@ReturnValue+'''','NULL')+' AS '+T.TypeName+'); END'
              END
              FROM 
              (
                SELECT
                    ROW_NUMBER()OVER(ORDER BY PP.is_output ASC,PP.parameter_id ASC) _RN_,
                    PP.*
                  FROM
                  (
                    SELECT  
                        object_id,
                        name,
                        parameter_id,
                        system_type_id,
                        user_type_id,
                        max_length,
                        precision,
                        scale,
                        is_output
                      FROM sys.parameters
                  ) AS PP
                 WHERE PP.object_id = @FunctionObjectId
              )AS P
             CROSS APPLY tSQLt.Private_GetFullTypeName(P.user_type_id,P.max_length,P.precision,P.scale,NULL) AS T
             ORDER BY P._RN_
               FOR XML PATH(''),TYPE
          ).value('.','NVARCHAR(MAX)') ParametersAndReturnScalar
    )PAS
    CROSS JOIN
    (
      SELECT 
          (
            SELECT 
              CASE WHEN P.column_id = 1 
                THEN 'SELECT TOP(0) ' 
                ELSE ',' 
              END + 
              'CAST(NULL AS '+T.TypeName+') AS '+QUOTENAME(P.name)
              FROM 
              (
                SELECT
                    ROW_NUMBER()OVER(ORDER BY PP.column_id ASC) _RN_,
                    PP.*
                  FROM
                  (
                    SELECT  
                        object_id,
                        name,
                        column_id,
                        system_type_id,
                        user_type_id,
                        max_length,
                        precision,
                        scale
                      FROM sys.columns
                  ) AS PP
                 WHERE PP.object_id = @FunctionObjectId
              )AS P
             CROSS APPLY tSQLt.Private_GetFullTypeName(P.user_type_id,P.max_length,P.precision,P.scale,NULL) AS T
             ORDER BY P._RN_
               FOR XML PATH(''),TYPE
          ).value('.','NVARCHAR(MAX)') TypeOnlySelectStatement
    )T
GO
---Build-
GO
