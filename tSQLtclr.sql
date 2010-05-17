sp_configure 'clr enabled', 1
GO
RECONFIGURE
GO
IF EXISTS (SELECT 1 FROM sys.assemblies WHERE name = 'tSQLtCLR')
    DROP ASSEMBLY tSQLtCLR;
GO
CREATE ASSEMBLY tSQLtCLR FROM 'C:\Projects\tSQLt.sourceforge\tSQLtCLR\tSQLtCLR\bin\Release\tSQLtCLR.dll' WITH PERMISSION_SET = SAFE
GO
CREATE PROCEDURE tSQLt.ResultsetFilter @ResultsetNo INT, @Command NVARCHAR(MAX)
AS
EXTERNAL NAME tSQLtCLR.[tSQLtCLR.StoredProcedures].ResultSetFilter;
GO
CREATE PROCEDURE tSQLt.AssertResultSetsHaveSameMetaData @expectedCommand NVARCHAR(MAX), @actualCommand NVARCHAR(MAX)
AS
EXTERNAL NAME tSQLtCLR.[tSQLtCLR.StoredProcedures].AssertResultSetsHaveSameMetaData;
GO