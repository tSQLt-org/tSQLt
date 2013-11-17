@ECHO OFF
IF "%~1"=="" GOTO :Usage

CD /d %~p0
sqlcmd -S %1 -E -I -d master -i "ExecuteAsSA.sql" "tSQLtKey.sql" "Create(tSQLtKey).sql" "CreateLogin(tSQLt.Build).sql"  -V11
GOTO :EOF

:Usage
  ECHO Usage %~nx0 ServerAndInstanceName
