IF OBJECT_ID('tSQLt.Private_AssertEqualsTableSchema_Expected') IS NOT NULL DROP TABLE tSQLt.Private_AssertEqualsTableSchema_Expected;
IF OBJECT_ID('tSQLt.Private_AssertEqualsTableSchema_Actual') IS NOT NULL DROP TABLE tSQLt.Private_AssertEqualsTableSchema_Actual;
GO
---Build+
GO
CREATE TABLE [tSQLt].[Private_AssertEqualsTableSchema_Actual]
(
  name NVARCHAR(256) NULL,
  column_id INT NULL,
  system_type_id NVARCHAR(MAX) NULL,
  user_type_id NVARCHAR(MAX) NULL,
  max_length SMALLINT NULL,
  precision TINYINT NULL,
  scale TINYINT NULL,
  collation_name NVARCHAR(256) NULL,
  is_nullable BIT NULL,
  is_identity BIT NULL
);
GO
EXEC('
  SET NOCOUNT ON;
  SELECT TOP(0) * 
    INTO tSQLt.Private_AssertEqualsTableSchema_Expected
    FROM tSQLt.Private_AssertEqualsTableSchema_Actual AS AETSA;
');
GO
---Build-
GO