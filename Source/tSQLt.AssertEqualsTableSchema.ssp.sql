IF OBJECT_ID('tSQLt.AssertEqualsTableSchema') IS NOT NULL DROP PROCEDURE tSQLt.AssertEqualsTableSchema;
GO
---Build+
GO
CREATE PROCEDURE tSQLt.AssertEqualsTableSchema
    @Expected NVARCHAR(MAX),
    @Actual NVARCHAR(MAX),
    @Message NVARCHAR(MAX) = NULL
AS
BEGIN
  SELECT 
      RANK()OVER(ORDER BY C.column_id) [RANK(column_id)],
      C.name,
      CAST(C.system_type_id AS NVARCHAR(MAX))+QUOTENAME(TS.name) system_type_id,
      CAST(C.user_type_id AS NVARCHAR(MAX))+CASE WHEN TU.system_type_id<> TU.user_type_id THEN QUOTENAME(SCHEMA_NAME(TU.schema_id))+'.' ELSE '' END + QUOTENAME(TU.name) user_type_id,
      C.max_length,
      C.precision,
      C.scale,
      C.collation_name,
      C.is_nullable
    INTO #Expected
    FROM sys.columns AS C
    JOIN sys.types AS TS
      ON C.system_type_id = TS.user_type_id
    JOIN sys.types AS TU
      ON C.user_type_id = TU.user_type_id
   WHERE C.object_id = OBJECT_ID(@Expected);
  SELECT 
      RANK()OVER(ORDER BY C.column_id) [RANK(column_id)],
      C.name,
      CAST(C.system_type_id AS NVARCHAR(MAX))+QUOTENAME(TS.name) system_type_id,
      CAST(C.user_type_id AS NVARCHAR(MAX))+CASE WHEN TU.system_type_id<> TU.user_type_id THEN QUOTENAME(SCHEMA_NAME(TU.schema_id))+'.' ELSE '' END + QUOTENAME(TU.name) user_type_id,
      C.max_length,
      C.precision,
      C.scale,
      C.collation_name,
      C.is_nullable
    INTO #Actual
    FROM sys.columns AS C
    JOIN sys.types AS TS
      ON C.system_type_id = TS.user_type_id
    JOIN sys.types AS TU
      ON C.user_type_id = TU.user_type_id
   WHERE C.object_id = OBJECT_ID(@Actual);
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual',@Message=@Message,@FailMsg='Unexpected/missing column(s)';  
END;
GO