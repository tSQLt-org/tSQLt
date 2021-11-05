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
SET AntTarget=All
IF NOT "%~6"=="-v" IF NOT "%~6"=="" SET DBLogin=%~6
IF NOT "%~7"=="-v" IF NOT "%~7"=="" SET SQLPackagePath=%~7
IF NOT "%~8"=="-v" IF NOT "%~8"=="" SET AntTarget=%~9
SET VerboseOutput=ON
IF NOT "%~6"=="-v" IF NOT "%~7"=="-v" IF NOT "%~8"=="-v" IF NOT "%~9"=="-v" SET VerboseOutput=OFF
ECHO DBLogin: "%DBLogin%"
ECHO SQLPackagePath: "%SQLPackagePath%"
ECHO VerboseOutput: "%VerboseOutput%"

REM CALL "%AntHome%\bin\ant" -buildfile Build\tSQLt.experiments.build.xml -Dmsbuild.path="%NET4Home%" -verbose || goto :error
REM goto :EOF

CALL "powershell.exe" -Command "Set-ExecutionPolicy Bypass -Scope CurrentUser"

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
CALL "%AntHome%\bin\ant" -buildfile Build\tSQLt.build.xml -Dcommit.id="--> LOCALBUILD <--" || goto :error
@ECHO OFF

ECHO +-----------------------------------+
ECHO : Creating tSQLt and Facade dacpacs   :
ECHO +-----------------------------------+
IF "%VerboseOutput%"=="ON" @ECHO ON
CALL "powershell.exe" -File Build\SetupDacpacBuild.ps1 -ErrorAction Stop || goto :error
@REM -----------------------------------------------------------------------------This space character is utterly important! --------------v
CALL "powershell.exe" -File Build\FacadeBuildDacpac.ps1 -ErrorAction Stop -ServerName "%SQLInstanceName%" -DatabaseName "%DBName%" -Login " %DBLogin%" -SqlCmdPath "%SQLCMDPath%" -SqlPackagePath "%SQLPackagePath%" || goto :error
CALL "powershell.exe" -File Build\BuildtSQLtDacpac.ps1 -ErrorAction Stop -ServerName "%SQLInstanceName%" -DatabaseName "%DBName%_dacpac_src" -Login " %DBLogin%" -SqlCmdPath "%SQLCMDPath%" -SqlPackagePath "%SQLPackagePath%" || goto :error
@ECHO OFF

ECHO +-------------------------+
ECHO : Repackage zip file      :
ECHO +-------------------------+
IF "%VerboseOutput%"=="ON" @ECHO ON
CALL "powershell.exe" -File Build\BuildtSQLtZip.ps1 -ErrorAction Stop || goto :error
@ECHO OFF

ECHO +----------------------------+
ECHO : Create Build Debug Project :
ECHO +----------------------------+
IF "%VerboseOutput%"=="ON" @ECHO ON
CALL "powershell.exe" -File Build\CreateDebugSSMSProject.ps1 -ErrorAction Stop || goto :error
@ECHO OFF

ECHO +-------------------------+
ECHO : Validating BUILD        :
ECHO +-------------------------+
FOR /F "usebackq tokens=1,2 delims==" %%i in (`wmic os get LocalDateTime /VALUE 2^>NUL`) do if '.%%i.'=='.LocalDateTime.' set LogTableName=tempdb.dbo.[%%j]
ECHO LogTableName: %LogTableName%

IF "%VerboseOutput%"=="ON" @ECHO ON
@REM -----------------------------------------------------------------------------This space character is utterly important! ----v
CALL "%AntHome%\bin\ant" "%AntTarget%" -buildfile Build\tSQLt.validatebuild.xml -Ddb.server="%SQLInstanceName%" -Ddb.name=%DBName% -Ddb.login=" %DBLogin%" -Dsqlcmd.path="%SQLCMDPath%" -Dsqlpackage.path="%SQLPackagePath%" -Dlogtable.name="%LogTableName%" || goto :error
@ECHO OFF

ECHO +-------------------------+
ECHO :     BUILD SUCCEEDED     :
ECHO +-------------------------+
goto :EOF

:error
@ECHO OFF
ECHO +-------------------------+
ECHO :  !!! BUILD FAILED !!!   :
ECHO +-------------------------+
exit /b %errorlevel%

