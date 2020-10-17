REM This installs the signing key for tSQLt on the local machine. 
REM If you do not have access to the original key, create your own and use SN.exe to install it into the tSQLt_OfficialSigningKey container.
REM This is only needed if you want to build tSQLt yourself.
REM
cd /d "%~dp0"
"c:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.8 Tools\x64\sn.exe" -d tSQLt_OfficialSigningKey
"c:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.8 Tools\x64\sn.exe" -i tSQLtOfficialSigningKey.pfx tSQLt_OfficialSigningKey
