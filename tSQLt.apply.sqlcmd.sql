EXEC sp_configure 'show_advanced_options',1
GO
RECONFIGURE
Print 'Calling tSQLt.class.sql'
:r "tSQLt.class.sql"
GO
Print 'Calling tSQLtCLR.sql'
:setvar tSQLtCLRTargetFile C:\Users\meinse00\Documents\SVN\tSQLt\tSQLtCLR\tSQLtCLR\bin\Release\tSQLtCLR.dll
GO
:r "tSQLtCLR.sql"