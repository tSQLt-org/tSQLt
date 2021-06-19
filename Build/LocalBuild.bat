@ECHO OFF

ECHO +-------------------------+
ECHO : Executing Local Build   :
ECHO +-------------------------+
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
ECHO DBLogin: "%DBLogin%"
ECHO SQLPackagePath: "%SQLPackagePath%"
ECHO VerboseOutput: "%VerboseOutput%"

REM CALL "%AntHome%\bin\ant" -buildfile Build\tSQLt.experiments.build.xml -Dmsbuild.path="%NET4Home%" -verbose || goto :error
REM goto :EOF

ECHO +-------------------------+
ECHO : Starting CLR BUILD      :
ECHO +-------------------------+
IF "%VerboseOutput%"=="ON" @ECHO ON
CALL "%AntHome%\bin\ant" -buildfile Build\tSQLt.buildCLR.xml -Dmsbuild.path="%NET4Home%" || goto :error
@ECHO OFF

ECHO +-------------------------+
ECHO : Starting tSQLt BUILD    :
ECHO +-------------------------+
IF "%VerboseOutput%"=="ON" @ECHO ON
CALL "%AntHome%\bin\ant" -buildfile Build\tSQLt.build.xml || goto :error
@ECHO OFF

ECHO +-------------------------+
ECHO : Creating tSQLt Facade   :
ECHO +-------------------------+
IF "%VerboseOutput%"=="ON" @ECHO ON
CALL "powershell.exe" -Command "Set-ExecutionPolicy Bypass -Scope CurrentUser"
CALL "powershell.exe" -File Build\FacadeBuildDacpac.ps1 -ErrorAction Stop -ServerName "%SQLInstanceName%" -DatabaseName "%DBName%" -Login "%DBLogin%" -SqlCmdPath "%SQLCMDPath%" -SqlPackagePath "%SQLPackagePath%" || goto :error
@ECHO OFF

ECHO +-------------------------+
ECHO : Repackage zip file      :
ECHO +-------------------------+
CALL "throw" || goto :error


ECHO +-------------------------+
ECHO : Copying BUILD           :
ECHO +-------------------------+
IF "%VerboseOutput%"=="ON" @ECHO ON
CALL "%AntHome%\bin\ant" -buildfile Build\tSQLt.copybuild.xml || goto :error
@ECHO OFF

ECHO +-------------------------+
ECHO : Validating BUILD        :
ECHO +-------------------------+
IF "%VerboseOutput%"=="ON" @ECHO ON
CALL "%AntHome%\bin\ant" -buildfile Build\tSQLt.validatebuild.xml -Ddb.server="%SQLInstanceName%" -Ddb.name=%DBName% -Ddb.login="%DBLogin%" -Dsqlcmd.path="%SQLCMDPath%" -Dsqlpackage.path="%SQLPackagePath%" || goto :error
@ECHO OFF

ECHO +-------------------------+
ECHO :     BUILD SUCCEEDED     :
ECHO +-------------------------+
goto :EOF

:error
ECHO +-------------------------+
ECHO :  !!! BUILD FAILED !!!   :
ECHO +-------------------------+
exit /b %errorlevel%

