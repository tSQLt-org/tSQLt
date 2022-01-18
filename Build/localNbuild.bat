@ECHO OFF

ECHO +-------------------+
ECHO : Starting BUILD    :
ECHO +-------------------+
REM %1\bin\nant -buildfile:tSQLt.build -D:msbuild.path=%~2 || goto :error

ECHO +-------------------+
ECHO : Copying BUILD     :
ECHO +-------------------+
REM %1\bin\nant -buildfile:tSQLt.local_build_output.build || goto :error

XCOPY ..\Deployable\tSQLt.zip .\output\
XCOPY ..\Deployable\tSQLt.test.zip .\output\

ECHO +-------------------+
ECHO : Validating BUILD  :
ECHO +-------------------+
%1\bin\nant -buildfile:tSQLt.validatebuild -D:db.version=%3 -D:db.server=%4 -D:db.name=%5 || goto :error

ECHO +-------------------+
ECHO : BUILD SUCCEEDED   :
ECHO +-------------------+
goto :EOF

:error
ECHO +-------------------+
ECHO : BUILD FAILED      :
ECHO +-------------------+
exit /b %errorlevel%