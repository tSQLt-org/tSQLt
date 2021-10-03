# The script starts the SQL Server Service

param(
[Parameter(Mandatory=$false)]
[string]$ACCEPT_EULA,

[Parameter(Mandatory=$false)]
[string]$sqlsrvrlogin
)

Write-Host "Beginning of start.ps1"

if($ACCEPT_EULA -ne "Y" -And $ACCEPT_EULA -ne "y")
{
	Write-Verbose "ERROR: You must accept the End User License Agreement before this container can start."
	Write-Verbose "Set the environment variable ACCEPT_EULA to 'Y' if you accept the agreement."

    exit 1
}

# start the service
Write-Verbose "Starting SQL Server"
start-service MSSQLSERVER
Write-Verbose "Started SQL Server."

# create the sql server login
Write-Verbose "Create login for sqlsrvrlogin account."

$createLogin="CREATE LOGIN  [" + $env:USERDOMAIN + "\"+ $sqlsrvrlogin +"] FROM WINDOWS"
Write-Verbose "Create login command: $createLogin" 
& sqlcmd -j -m-1 -Q $createLogin

Write-Verbose "Providing sysadmin permissions to sqlsrvrlogin account."

$enableSysAdminPermissions="sp_addsrvRolemember [" + $env:USERDOMAIN + "\"+ $sqlsrvrlogin +"], 'sysadmin'"
Write-Verbose "Enable sys admin permissions command: $enableSysAdminPermissions" 
& sqlcmd -j -m-1 -Q $enableSysAdminPermissions

$lastCheck = (Get-Date).AddSeconds(-2) 
while ($true) 
{ 
    Get-EventLog -LogName Application -Source "MSSQL*" -After $lastCheck | Select-Object TimeGenerated, EntryType, Message	 
    $lastCheck = Get-Date 
    Start-Sleep -Seconds 2 
}
Write-Error "Should not get here, ever."