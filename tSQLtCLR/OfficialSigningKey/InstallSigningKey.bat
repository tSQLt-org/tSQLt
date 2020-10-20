@ECHO OFF
REM This installs the signing key for tSQLt on the local machine. 
REM If you do not have access to the original key, create your own and use SN.exe to install it into the tSQLt_OfficialSigningKey container.
REM This is only needed if you want to build tSQLt yourself.
REM

cd /d "%~dp0"
DEL KeyInfo.txt
DEL KeyInfoC.txt
ECHO --------------------------------------------------------------------------------------------------------------------
ECHO Deleting existing container (might fail)
ECHO --------------------------------------------------------------------------------------------------------------------
"c:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.8 Tools\x64\sn.exe" -d tSQLt_OfficialSigningKey
ECHO --------------------------------------------------------------------------------------------------------------------
ECHO Installing Key
ECHO --------------------------------------------------------------------------------------------------------------------
"c:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.8 Tools\x64\sn.exe" -i tSQLtOfficialSigningKey.pfx tSQLt_OfficialSigningKey
ECHO --------------------------------------------------------------------------------------------------------------------
ECHO Extracting Key Info
ECHO --------------------------------------------------------------------------------------------------------------------
"c:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.8 Tools\x64\sn.exe" -p tSQLtOfficialSigningKey.pfx KeyInfo.txt sha1
"c:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.8 Tools\x64\sn.exe" -pc tSQLt_OfficialSigningKey KeyInfoC.txt sha1
ECHO --------------------------------------------------------------------------------------------------------------------
ECHO KeyInfo from file
ECHO --------------------------------------------------------------------------------------------------------------------
"c:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.8 Tools\x64\sn.exe" -tp KeyInfo.txt 
ECHO --------------------------------------------------------------------------------------------------------------------
ECHO KeyInfo from container
ECHO --------------------------------------------------------------------------------------------------------------------
"c:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.8 Tools\x64\sn.exe" -tp KeyInfoC.txt 

