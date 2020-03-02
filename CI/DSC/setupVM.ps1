Function Setup-VM() {

    Write-Host "Starting..."
        Write-Host "Executed as: $(whoami)"
        Write-Host 'Setting up VM for tSQLt CI execution...'
        Write-Host '--1---------------------------------------------------------------'
        New-Item -Path c:\ -Name "setupvm.sql" -Force -ItemType "file" -Value "PRINT @@VERSION; PRINT SYSDATETIME();"
        Write-Host '--2---------------------------------------------------------------'
        New-Item -Path c:\ -Name "setupvm.pass" -Force -ItemType "file" -Value "qTv3f9gduUFuc8BQTZUq4MEcFbY3(2H)"
        Write-Host '--3---------------------------------------------------------------'
        if(test-path c:\logsqloutput.txt){remove-item C:\logsqloutput.txt -Force}
        if(test-path c:\logsqloutput2.txt){remove-item C:\logsqloutput2.txt -Force}
        Write-Host '--4---------------------------------------------------------------'
        New-Item -Path c:\ -Name "setupvm.bat" -Force -ItemType "file" -Value 'RUNAS /netonly /user:localhost\tSQLt "cmd /C c:\setupvm2.bat"<c:\setupvm.pass'
        New-Item -Path c:\ -Name "setupvm2.bat" -Force -ItemType "file" -Value 'SQLCMD -i c:\setupvm.sql -o c:\logsqloutput.txt'
        Add-Content -Path c:\setupvm2.bat -Force -Value "`r`n"
        Add-Content -Path c:\setupvm2.bat -Force -Value 'ECHO.>c:\logsqloutput2.txt'
        Write-Host '--5---------------------------------------------------------------'
        Invoke-Item c:\setupvm.bat
        Write-Host '--6---------------------------------------------------------------'
        Write-Host "Waiting for SQL to finish..."
        $cc=0;while (!(Test-Path "C:\logsqloutput2.txt")) {if($cc++ -ge 60){Write-Error "Timeout while waiting for SQL to finish";break;} Write-Host $cc;Start-Sleep 1 }
        Get-Content c:\logsqloutput.txt
        Write-Host '--7---------------------------------------------------------------'

        <# -
        New-NetFirewallRule -DisplayName "Allow WinRM" -Direction Inbound -LocalPort 5986 -Protocol TCP -Action Allow
        New-NetFirewallRule -DisplayName "Allow SQLServer" -Direction Inbound -LocalPort 1433 -Protocol TCP -Action Allow

        #(Invoke-SqlCmd -Verbose -Credential $Credential -Query "EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'LoginMode', REG_DWORD, 2")[0]

        #Restart-Service -Name "SQL Server (MSSQLSERVER)"

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

    #>

    Write-Host 'Done setting up VM for tSQLt CI execution.'
}
Setup-VM
