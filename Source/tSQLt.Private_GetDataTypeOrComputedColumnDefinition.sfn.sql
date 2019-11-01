IF OBJECT_ID('tSQLt.Private_GetDataTypeOrComputedColumnDefinition') IS NOT NULL DROP FUNCTION tSQLt.Private_GetDataTypeOrComputedColumnDefinition;
---Build+
GO
CREATE FUNCTION tSQLt.Private_GetDataTypeOrComputedColumnDefinition(@UserTypeId INT, @MaxLength INT, @Precision INT, @Scale INT, @CollationName NVARCHAR(MAX), @ObjectId INT, @ColumnId INT, @ReturnDetails BIT)
RETURNS TABLE
AS
RETURN SELECT 
              COALESCE(cc.IsComputedColumn, 0) AS IsComputedColumn,
              COALESCE(cc.ComputedColumnDefinition, GFTN.TypeName) AS ColumnDefinition
        FROM (SELECT @UserTypeId, @MaxLength, @Precision, @Scale, @CollationName, @ObjectId, @ColumnId, @ReturnDetails) 
             AS V(UserTypeId, MaxLength, Precision, Scale, CollationName, ObjectId, ColumnId, ReturnDetails)
       CROSS APPLY tSQLt.Private_GetFullTypeName(V.UserTypeId, V.MaxLength, V.Precision, V.Scale, V.CollationName) AS GFTN
        LEFT JOIN (SELECT 1 AS IsComputedColumn,
                          ' AS '+ cci.definition + CASE WHEN cci.is_persisted = 1 THEN ' PERSISTED' ELSE '' END COLLATE database_default AS ComputedColumnDefinition,
                          cci.object_id,
                          cci.column_id
                     FROM sys.computed_columns cci
                  )cc
               ON cc.object_id = V.ObjectId
              AND cc.column_id = V.ColumnId
              AND V.ReturnDetails = 1;               
---Build-
GO
