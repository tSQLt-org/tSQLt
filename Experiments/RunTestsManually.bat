SQLCMD -S .\R2A -E -I -d tempdb -i ..\Build\temp\ResetValidationServer.sql
SQLCMD -S .\R2A -E -I -d tempdb -i ..\Build\temp\PrepareServer.sql
SQLCMD -S .\R2A -E -I -d tempdb -i ..\Build\temp\temp_prepare_server.sql -v NewDbName=tSQLt_dev
SQLCMD -S .\R2A -E -I -d tSQLt_dev -i ..\Build\temp\tSQLt.class.sql
REM SQLCMD -S .\R2A -E -I -d tSQLt_dev -i "..\Build\temp\Drop(master.tSQLt_testutil).sql"
REM SQLCMD -S .\R2A -E -I -d tSQLt_dev -i "..\Build\temp\Install(master.tSQLt_testutil).sql"
REM SQLCMD -S .\R2A -E -I -d tSQLt_dev -i "..\Build\temp\Drop(tSQLtAssemblyKey)(Pre2017).sql"
REM SQLCMD -S .\R2A -E -I -d tSQLt_dev -i "..\Build\temp\BootStrapTest.sql"
SQLCMD -S .\R2A -E -I -d tSQLt_dev -i "..\Build\temp\TestUtil.sql"
SQLCMD -S .\R2A -E -I -d tSQLt_dev -Q "EXEC tSQLt_testutil.PrepMultiRunLogTable;EXEC tSQLt.SetSummaryError @SummaryError=0;"

SQLCMD -S .\R2A -E -I -d tSQLt_dev -Q "EXEC tSQLt.Reset;"
SQLCMD -S .\R2A -E -I -d tSQLt_dev -i "..\Build\temp\temp_executeas_sa.sql" ..\Build\temp\AllTests.SA.sql -v DbName="tSQLt_dev" ExecuteStatement=""
REM SQLCMD -S .\R2A -E -I -d tSQLt_dev -i "..\Build\temp\temp_executeas_sa.sql" -v DbName="tSQLt_dev" ExecuteStatement="EXEC tSQLt.SetVerbose @Verbose = 1;EXEC tSQLt.RunNew;"
SQLCMD -S .\R2A -E -I -d tSQLt_dev -i "..\Build\temp\temp_executeas_sa.sql" -v DbName="tSQLt_dev" ExecuteStatement="EXEC tSQLt.SetVerbose @Verbose = 1;EXEC tSQLt.Run '[RemoveAssemblyKeyTests].[test login with control server permission can execute procedure]';"

SQLCMD -S .\R2A -E -I -d tSQLt_dev -i "..\Build\temp\Install(tSQLtAssemblyKey).sql"
SQLCMD -S .\R2A -E -I -d tSQLt_dev -Q "EXEC tSQLt.Reset;"
SQLCMD -S .\R2A -E -I -d tSQLt_dev -i "..\Build\temp\temp_executeas_sa.sql" ..\Build\temp\AllTests.EXTERNAL_ACCESS_KEY_EXISTS.sql -v DbName="tSQLt_dev" ExecuteStatement=""
REM SQLCMD -S .\R2A -E -I -d tSQLt_dev -i "..\Build\temp\temp_executeas_sa.sql" -v DbName="tSQLt_dev" ExecuteStatement="EXEC tSQLt.SetVerbose @Verbose = 1;EXEC tSQLt.RunNew;"
SQLCMD -S .\R2A -E -I -d tSQLt_dev -i "..\Build\temp\temp_executeas_sa.sql" -v DbName="tSQLt_dev" ExecuteStatement="EXEC tSQLt.SetVerbose @Verbose = 1;EXEC tSQLt.Run '[EnableExternalAccessTests].[test tSQLt.EnableExternalAccess produces no output, if @try = 1 and setting fails]';"
