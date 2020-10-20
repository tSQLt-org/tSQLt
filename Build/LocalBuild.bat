@ECHO OFF

ECHO +-------------------------+
ECHO : Executing Local Build   :
ECHO +-------------------------+
ECHO Parameters:
ECHO AntHome: "%~1"
ECHO NET4Home: "%~2"
ECHO SQLCMDPath: "%~3"
ECHO SQLVersion: "deprecated"
ECHO SQLInstanceName: "%~4"
ECHO DBName: "%~5"
IF "%~6"=="-v" ECHO Verbose ON ELSE ECHO Verbose OFF

REM CALL "%~1\bin\ant" -buildfile Build\tSQLt.experiments.build.xml -Dmsbuild.path="%~2" -verbose || goto :error
REM goto :EOF

ECHO +-------------------------+
ECHO : Starting CLR BUILD      :
ECHO +-------------------------+
IF "%~6"=="-v" @ECHO ON
CALL "%~1\bin\ant" -buildfile Build\tSQLt.buildCLR.xml -Dmsbuild.path="%~2" || goto :error
@ECHO OFF

ECHO +-------------------------+
ECHO : Starting tSQLt BUILD    :
ECHO +-------------------------+
IF "%~6"=="-v" @ECHO ON
CALL "%~1\bin\ant" -buildfile Build\tSQLt.build.xml || goto :error
@ECHO OFF

ECHO +-------------------------+
ECHO : Copying BUILD           :
ECHO +-------------------------+
ECHO :- THIS STEP IS OPTIONAL -:
ECHO +-------------------------+
IF "%~6"=="-v" @ECHO ON
CALL "%~1\bin\ant" -buildfile Build\tSQLt.copybuild.xml || goto :error
@ECHO OFF

ECHO +-------------------------+
ECHO : Validating BUILD        :
ECHO +-------------------------+
IF "%~6"=="-v" @ECHO ON
CALL "%~1\bin\ant" -buildfile Build\tSQLt.validatebuild.xml -Ddb.server=%~4 -Ddb.name=%~5 -Ddb.login="-E" -Dsqlcmd.path="\"%~3\"" || goto :error
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

