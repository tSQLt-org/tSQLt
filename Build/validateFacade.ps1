<#
- execute the ExecuteFacadeTest.sql file
- validate that the dacpac is correct by installing tSQLt on one database; installing the database on another database; get the list of names from sys.objects where the name is not Private%; assert that it is the same list
-- makesure that the database principal exists, [tSQLt.TestClasses] (maybe)
-- 
#>
Param( 
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $ServerName,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $DatabaseName,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $Login,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $SqlCmdPath
);

$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath

.($dir+"\CommonFunctionsAndMethods.ps1")

Log-Output "FileLocation: $dir"

# Delete files which might have been generated from previous builds
$facadeFiles = @("FacadeScript.sql", "ExecuteFacadeScript.sql", "FacadeTests.sql", "ExecuteFacadeTests.sql");
Get-ChildItem -Path "output/*" -Include $facadeFiles | Remove-Item;

Expand-Archive -Path "./output/tSQLtFacade.zip" -DestinationPath "./output";

# "&quot;${sqlcmd.path}&quot;\sqlcmd ${execute.sql.sqlconnect} -I -i &quot;${execute.sql.executeas}&quot; ${execute.sql.filename} -v NewDbName=${db.name} DbName=${execute.sql.database} ExecuteStatement=&quot;${execute.sql.statement}&quot; -V11" />

Push-Location;
Set-Location './output';

$CallSqlCmd = '&"'+$SqlCmdPath+'\sqlcmd.exe" -S "'+$ServerName+'" '+$Login+' -I -i ExecuteFacadeTests.sql -v FacadeSourceDb="'+$DatabaseName+'_src" FacadeTargetDb="'+$DatabaseName+'_tgt"';
Invoke-Expression $CallSqlCmd;

Log-Output "Oh no! We have no test results. They need to be captured."; 
throw 

Pop-Location;
