$scriptPath = $MyInvocation.MyCommand.Path;
$invocationDir = Split-Path $scriptPath;
$buildPath = $invocationDir +'/';
$tempPath = $invocationDir + '/temp/tSQLtBuild/';
$outputPath = $invocationDir + '/output/tSQLtBuild/';
$sourcePath = $invocationDir + '/../Source/';
$testUtilPath = $invocationDir + '/../TestUtil/';

.($buildPath+"CommonFunctionsAndMethods.ps1");

Log-Output '<#--=======================================================================-->'
Log-Output '<!--========          Start CreateDropClassStatement.ps1          =========-->'
Log-Output '<#--=======================================================================-->'

$DropClassFileContent = Get-Content -path ($sourcePath+"tSQLt.DropClass.ssp.sql");
$GetDropItemCmdFileContent = Get-Content -path ($sourcePath+"tSQLt.Private_GetDropItemCmd.sfn.sql");
$OutputFilePath = $tempPath+"TempDropClass.sql";

$DropClassSnip = ($DropClassFileContent | Get-SnipContent -startSnipPattern "/*SnipStart: CreateDropClassStatement.ps1*/" -endSnipPattern "/*SnipEnd: CreateDropClassStatement.ps1*/");
$DropItemSnip = ($GetDropItemCmdFileContent | Get-SnipContent -startSnipPattern "/*SnipStart: CreateDropClassStatement.ps1*/" -endSnipPattern "/*SnipEnd: CreateDropClassStatement.ps1*/");
$DropItemParamSnip = ($GetDropItemCmdFileContent | Get-SnipContent -startSnipPattern "/*SnipParamStart: CreateDropClassStatement.ps1*/" -endSnipPattern "/*SnipParamEnd: CreateDropClassStatement.ps1*/");

$VariablesString = ($DropItemParamSnip.trim() -join ' ')

$VariableNames = (Select-String '@\S+' -input $VariablesString -AllMatches|ForEach-Object{$_.matches.Value});
#$VariableNames 

$DISP1 =   ($DropItemSnip | ForEach-Object{
    $s=$_;
    for($i = 0;$i -lt $VariableNames.count;$i++){
      $s=$s -replace $VariableNames[$i], ("($"+($i+1)+")") 
    };
    $s; 
});
$DISP2 = $DISP1.trim() -join ' ';

$DropItemSnipPrepared = "("+ $DISP2 + ")";
$RawDropClassStatement = $DropClassSnip -replace 'tSQLt.Private_GetDropItemCmd\s*\(\s*([^,]*)\s*,\s*([^)]*)\s*\)',$DropItemSnipPrepared;

$DropClassStatement = ($RawDropClassStatement.trim()|Where-Object {$_ -ne "" -and $_ -notmatch "^GO(\s.*)?"}) -join ' ';

Set-Content -Path $OutputFilePath -Value $DropClassStatement;

 Log-Output '<#--=======================================================================-->'
 Log-Output '<!--========            End CreateDropClassStatement.ps1          =========-->'
 Log-Output '<#--=======================================================================-->'
 
 
<# TODO
--> Test this: Empty File TempDropClass.sql file should throw an error
--> Test this: If the $tempPath does not exist, BuildHelper.exe seems to currently throw an error, but does that stop the build?
--> Test this: If the $sourcePath does not exist, BuildHelper.exe seems to currently throw an error, but does that stop the build?
#>
