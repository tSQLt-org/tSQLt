IF OBJECT_ID('tSQLt.Private_GetDataTypeOrComputedColumnDefinition') IS NOT NULL DROP FUNCTION tSQLt.Private_GetDataTypeOrComputedColumnDefinition;
---Build+
GO
CREATE FUNCTION tSQLt.Private_GetDataTypeOrComputedColumnDefinition(@UserTypeId INT, @MaxLength INT, @Precision INT, @Scale INT, @ObjectId INT, @ColumnId INT, @ReturnDetails BIT)
RETURNS TABLE
AS
RETURN SELECT 
              COALESCE(IsComputedColumn, 0) AS IsComputedColumn,
              COALESCE(ComputedColumnDefinition, Name + Suffix) AS ColumnDefinition
        FROM tSQLt.Private_GetFullTypeName(@UserTypeId, @MaxLength, @Precision, @Scale)
        LEFT JOIN (SELECT 1 AS IsComputedColumn,' AS '+ definition + CASE WHEN is_persisted = 1 THEN ' PERSISTED' ELSE '' END AS ComputedColumnDefinition,object_id,column_id
                     FROM sys.computed_columns 
                  )cc
               ON cc.object_id = @ObjectId
              AND cc.column_id = @ColumnId
              AND @ReturnDetails = 1;               
---Build-
GO
