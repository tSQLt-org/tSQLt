ECHO GOTHERE
CALL :RUN %* > "%~f1\buildlog.txt" 2>"%~f1\builderr.txt"
GOTO :EOF
:RUN
SET tSQLtPath=%~f1\..\
SET tSQLtCLRTargetFile=%~f2

ECHO tSQLtPath = %tSQLtPath%
ECHO tSQLtCLRTargetFile = %tSQLtCLRTargetFile%

ECHO Starting tSQLt.class.sql
sqlcmd -E -S localhost -d tSQLt -b -i "%~f1\..\tSQLt.class.sql"
ECHO Starting tSQLtCLR.sql
sqlcmd -E -S localhost -d tSQLt -b -i "%~f1\..\tSQLtCLR.sql"
ECHO Starting tSQLtCLR_CreateProcs.sql
sqlcmd -E -S localhost -d tSQLt -b -i "%~f1\..\tSQLtCLR_CreateProcs.sql"
ECHO %ERRORLEVEL%

ECHO Finished!
:EOF