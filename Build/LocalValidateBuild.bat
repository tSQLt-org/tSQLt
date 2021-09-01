@ECHO OFF

ECHO +----------------------------------+
ECHO :      Executing Validate Build    :
ECHO +----------------------------------+
ECHO Parameters:
SET AntHome=%~1
ECHO AntHome: "%AntHome%"
SET NET4Home=%~2
ECHO NET4Home: "%NET4Home%"
SET SQLCMDPath=%~3
ECHO SQLCMDPath: "%SQLCMDPath%"
ECHO SQLVersion: "deprecated"
SET SQLInstanceName=%~4
ECHO SQLInstanceName: "%SQLInstanceName%"
SET DBName=%~5
ECHO DBName: "%DBName%"
SET DBLogin=-E
IF NOT "%~6"=="-v" IF NOT "%~6"=="" SET DBLogin=%~6
IF NOT "%~7"=="-v" IF NOT "%~7"=="" SET SQLPackagePath=%~7
SET VerboseOutput=ON
IF NOT "%~6"=="-v" IF NOT "%~7"=="-v" IF NOT "%~8"=="-v" SET VerboseOutput=OFF
REM ECHO DBLogin: "%DBLogin%"
ECHO SQLPackagePath: "%SQLPackagePath%"
ECHO VerboseOutput: "%VerboseOutput%"

CALL "powershell.exe" -Command "Set-ExecutionPolicy Bypass -Scope CurrentUser"

ECHO +----------------------------------+
ECHO :         VALIDATING BUILD         :
ECHO +----------------------------------+
IF "%VerboseOutput%"=="ON" @ECHO ON
@REM -----------------------------------------------------------------------------This space character is utterly important! ----v
CALL "ant" -buildfile Build\tSQLt.validatebuild.xml -Ddb.server="%SQLInstanceName%" -Ddb.name=%DBName% -Ddb.login=" %DBLogin%" -Dsqlcmd.path="%SQLCMDPath%" -Dsqlpackage.path="%SQLPackagePath%" || goto :error
@ECHO OFF

ECHO +----------------------------------+
ECHO :     VALIDATE BUILD SUCCEEDED     :
ECHO +----------------------------------+
goto :EOF

:error
@ECHO OFF
ECHO +----------------------------------+
ECHO :       !!! BUILD FAILED !!!       :
ECHO +----------------------------------+
exit /b %errorlevel%
