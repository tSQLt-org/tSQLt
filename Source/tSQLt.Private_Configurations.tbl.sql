IF OBJECT_ID('tSQLt.Private_Configurations') IS NOT NULL DROP TABLE tSQLt.Private_Configurations;
---Build+
CREATE TABLE tSQLt.Private_Configurations (
  Name NVARCHAR(100) PRIMARY KEY CLUSTERED,
  Value SQL_VARIANT
);
---Build-
