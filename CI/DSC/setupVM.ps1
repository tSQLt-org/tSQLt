Function Setup-VM() {

    Write-Host "Starting..."
	Write-Host "Executed as: $(whoami)"
	Write-Host 'Setting up VM for tSQLt CI execution...'
	
	#<#
	New-NetFirewallRule -DisplayName "Allow WinRM" -Direction Inbound -LocalPort 5986 -Protocol TCP -Action Allow
	New-NetFirewallRule -DisplayName "Allow SQLServer" -Direction Inbound -LocalPort 1433 -Protocol TCP -Action Allow

    $User = "tSQLt"
	$Pword = "qTv3f9gduUFuc8BQTZUq4MEcFbY3(2H)"
	$PWordS = ConvertTo-SecureString -String $Pword -AsPlainText -Force
    $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWordS

	Invoke-Command -ComputerName localhost  -ScriptBlock {Write-Host $(whoami)} -Credential $Credential
	#Invoke-Command -ComputerName localhost  -ScriptBlock {Write-Host h:$using:hello} -Credential $Credential
	#(Invoke-SqlCmd -Verbose -Credential $Credential -Query "PRINT @@VERSION;" )[0]
	#(Invoke-SqlCmd -Verbose -Credential $Credential -Query "CREATE LOGIN tSQLtExternal WITH PASSWORD = 'qTv3f9gduUFuc8BQTZUq4MEcFbY3(2H)',CHECK_EXPIRATION = OFF, CHECK_POLICY = OFF,DEFAULT_DATABASE = tempdb;ALTER SERVER ROLE sysadmin ADD MEMBER tSQLtExternal;")[0]

	#(Invoke-SqlCmd -Verbose -Credential $Credential -Query "EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'LoginMode', REG_DWORD, 2")[0]

	Restart-Service -Name "SQL Server (MSSQLSERVER)"
    ##>

    Write-Host 'Done setting up VM for tSQLt CI execution.'
}
Setup-VM

