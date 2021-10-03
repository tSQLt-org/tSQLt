IF OBJECT_ID('tSQLt.TestClasses') IS NOT NULL DROP VIEW tSQLt.TestClasses;
GO
---Build+
GO
CREATE VIEW tSQLt.TestClasses
AS
  SELECT s.name AS Name, s.schema_id AS SchemaId
    FROM sys.schemas s
    LEFT JOIN sys.extended_properties ep
      ON ep.major_id = s.schema_id
   WHERE ep.name = N'tSQLt.TestClass'
      OR s.principal_id = USER_ID('tSQLt.TestClass');
GO
---Build-
