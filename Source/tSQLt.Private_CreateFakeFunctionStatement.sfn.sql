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
  SELECT 'CREATE FUNCTION '+QUOTENAME(OBJECT_SCHEMA_NAME(@FunctionObjectId))+'.'+QUOTENAME(OBJECT_NAME(@FunctionObjectId))+'('+X.FunctionTail+';' CreateStatement
    FROM
    (
      SELECT
        STUFF(
          (
            SELECT 
              CASE P.block_id 
              WHEN 0 THEN ','+P.name+' '+T.TypeName
              WHEN 1 THEN CASE WHEN P._RN_ = 1 THEN ' ' ELSE '' END +') RETURNS '+T.TypeName+' AS BEGIN RETURN CAST('+ISNULL(''''+@ReturnValue+'''','NULL')+' AS '+T.TypeName+'); END'
              WHEN 2 THEN CASE WHEN P.parameter_id = 1 THEN CASE WHEN P._RN_ = 1 THEN ' ' ELSE '' END +') RETURNS TABLE AS RETURN SELECT TOP(0) ' ELSE ',' END + 'CAST(NULL AS '+T.TypeName+') AS '+QUOTENAME(P.name)
              END
              FROM 
              (
                SELECT
                    ROW_NUMBER()OVER(ORDER BY PP.block_id ASC,PP.parameter_id ASC) _RN_,
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
                        CAST(is_output AS INT) block_id
                      FROM sys.parameters
                     UNION ALL
                    SELECT  
                        object_id,
                        name,
                        column_id,
                        system_type_id,
                        user_type_id,
                        max_length,
                        precision,
                        scale,
                        2 block_id
                      FROM sys.columns
                  ) AS PP
                 WHERE PP.object_id = @FunctionObjectId
              )AS P
             CROSS APPLY tSQLt.Private_GetFullTypeName(P.user_type_id,P.max_length,P.precision,P.scale,NULL) AS T
             ORDER BY P.block_id ASC,P.parameter_id ASC
               FOR XML PATH(''),TYPE
          ).value('.','NVARCHAR(MAX)'),
          1,1,''
        ) FunctionTail
    )X
GO
---Build-
GO
