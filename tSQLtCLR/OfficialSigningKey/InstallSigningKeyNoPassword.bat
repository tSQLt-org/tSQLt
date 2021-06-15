@ECHO OFF
REM This will backup existing pfx file (if there is backup already - it will be replaced),
REM create self-signed key without password and run InstallSigningKey.bat to add this key
REM to needed container and some other  stuff.
cd /d "%~dp0"

ECHO --------------------------------------------------------------------------------------------------------------------
ECHO Backing up existing key
ECHO --------------------------------------------------------------------------------------------------------------------
copy tSQLtOfficialSigningKey.pfx tSQLtOfficialSigningKey.pfx_backup
ECHO --------------------------------------------------------------------------------------------------------------------
ECHO Creating new key
ECHO --------------------------------------------------------------------------------------------------------------------
"C:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.8 Tools"\sn.exe -k tSQLtOfficialSigningKey.pfx

InstallSigningKey.bat
