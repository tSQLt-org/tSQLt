Function Setup-VM() {

    Write-Host 'Setting up VM for tSQLt CI execution...'
	#<#
	New-NetFirewallRule -DisplayName "Allow WinRM" -Direction Inbound -LocalPort 5986 -Protocol TCP -Action Allow
	New-NetFirewallRule -DisplayName "Allow SQLServer" -Direction Inbound -LocalPort 1433 -Protocol TCP -Action Allow

	SqlCmd -S localhost -E -Q "PRINT @@VERSION;"
	SqlCmd -S localhost -E -Q "CREATE LOGIN tSQLtExternal WITH PASSWORD = 'qTv3f9gduUFuc8BQTZUq4MEcFbY3(2H)',CHECK_EXPIRATION = OFF, CHECK_POLICY = OFF,DEFAULT_DATABASE = tempdb;ALTER SERVER ROLE sysadmin ADD MEMBER tSQLtExternal;"

	SqlCmd -S localhost -E -Q "EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'LoginMode', REG_DWORD, 2"

	Restart-Service -Name "SQL Server (MSSQLSERVER)"
    ##>
    Write-Host 'Done setting up VM for tSQLt CI execution.'
}
Setup-VM