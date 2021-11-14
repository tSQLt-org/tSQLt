EXEC tSQLt.NewTestClass 'Private_ResettSQLtTablesTests';
GO
CREATE PROCEDURE Private_ResettSQLtTablesTests.[test TODO]
AS
BEGIN
  EXEC tSQLt.Fail;
END;
GO

/*--
TODO

- Tables --> SELECT * FROM sys.tables WHERE schema_id = SCHEMA_ID('tSQLt');

--*/