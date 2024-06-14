# this will install the module, can be skipped if aliases shouldn't be tested
# change to $true if you want enable this step
if ($false) {
    Install-Module dbatools -Scope CurrentUser;
    if ( 1 -gt (Get-DbaClientAlias | Where-Object  AliasName -eq 'Dev_tSQLt').Count) {
        Write-Error 'There is no alias `Dev_tSQLt` created';
    }
} else {
    Write-Warning "Aliases test is skipped, modify ($PSScriptRoot) to enable the test";
}

function Test-Variable ($variable, $testPath, $errorMessage) {
    if ($null -eq $variable -or $variable -eq "") {
        Write-Error "$variable system variable is not set"
    }
    if (!(Join-Path $variable $testPath | Test-Path )) {
        Write-Error  $errorMessage;
    }
}

Test-Variable $env:NET4Home "msbuild.exe" "msbuild.exe is not found, maybe NET Framework 4.8 Developer is not installed";
Test-Variable $env:AntHome "bin\ant.bat" "ant.bat is not found, maybe ant is not installed";
Test-Variable $env:SQLCMDPath "SQLCMD.EXE" "SQLCMD.EXE is not found, maybe sqlcmd or/and SSMS is not installed";

if ( !(Test-Path Registry::"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.5")) {
    Write-Error  ".NET 3.5 Framework is not installed";
}

# the path is hardcoded in the bat file (tSQLtCLR\OfficialSigningKey\InstallSigningKey.bat), so hardocing here as well.
if ( !(Test-Path "c:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.8 Tools\x64\sn.exe")) {
    Write-Error  "Signing tool (sn.exe) does not exist";
}

try {
    java -version 2>&1 | Out-Null
}
catch [System.Management.Automation.CommandNotFoundException] {
    Write-Error "java is not installed"
}

try {
    git | Out-Null
}
catch [System.Management.Automation.CommandNotFoundException] {
    Write-Error "git is not installed"
}

