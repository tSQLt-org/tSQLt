GO
CREATE USER [tSQLt.Build] FROM LOGIN [tSQLt.Build];
GO
ALTER ROLE db_owner ADD MEMBER [tSQLt.Build];
GO