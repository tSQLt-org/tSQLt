@ECHO OFF
%1\bin\nant -buildfile:tSQLt.build -D:msbuild.path=%2 || goto :error
%1\bin\nant -buildfile:tSQLt.validatebuild -D:db.version=%3 -D:db.server=%4 -D:db.name=%5 || goto :error

ECHO +-----------------+
ECHO : BUILD SUCCEEDED :
ECHO +-----------------+
goto :EOF

:error
ECHO +--------------+
ECHO : BUILD FAILED :
ECHO +--------------+
exit /b %errorlevel%