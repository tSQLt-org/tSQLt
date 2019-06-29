@ECHO OFF

REM CALL %1\bin\ant -buildfile Build\tSQLt.experiments.build.xml -Dmsbuild.path=%2 || goto :error
REM goto :EOF

ECHO +-------------------------+
ECHO : Starting CLR BUILD      :
ECHO +-------------------------+
CALL %1\bin\ant -buildfile Build\tSQLt.buildCLR.xml -Dmsbuild.path=%2 || goto :error

ECHO +-------------------------+
ECHO : Starting tSQLt BUILD    :
ECHO +-------------------------+
CALL %1\bin\ant -buildfile Build\tSQLt.build.xml || goto :error

ECHO +-------------------------+
ECHO : Copying BUILD           :
ECHO +-------------------------+
ECHO :- THIS STEP IS OPTIONAL -:
ECHO +-------------------------+
CALL %1\bin\ant -buildfile Build\tSQLt.copybuild.xml || goto :error

ECHO +-------------------------+
ECHO : Validating BUILD        :
ECHO +-------------------------+
CALL %1\bin\ant -buildfile Build\tSQLt.validatebuild.xml -Ddb.version=%3 -Ddb.server=%4 -Ddb.name=%5 || goto :error

ECHO +-------------------------+
ECHO :     BUILD SUCCEEDED     :
ECHO +-------------------------+
goto :EOF

:error
ECHO +-------------------------+
ECHO :  !!! BUILD FAILED !!!   :
ECHO +-------------------------+
exit /b %errorlevel%

