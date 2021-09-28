
Param( 
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $ServerName,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $Login,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $SqlCmdPath
);


$sqlFileForTesting = @"
    RAISERROR('an error',15,2);
    GO
    RAISERROR('no error 1',0,1)WITH NOWAIT;
    GO
    RAISERROR('no error 2',0,1)WITH NOWAIT;
    GO
"@;

Set-Content "sqlFileForTesting.sql" $sqlFileForTesting;

#$CallSqlCmd = '&"'+$SqlCmdPath+'\sqlcmd.exe" -S "'+$ServerName+'" '+$Login+' -I -b -Q "RAISERROR (''an error!'',15,3)"';
$CallSqlCmd = '&"'+$SqlCmdPath+'\sqlcmd.exe" -S "'+$ServerName+'" '+$Login+' -I -b -i "sqlFileForTesting.sql"';
$CallSqlCmd;
$CallSqlCmd = $CallSqlCmd + ';if($LASTEXITCODE -ne 0){throw "error during execution";}'
Invoke-Expression $CallSqlCmd;

