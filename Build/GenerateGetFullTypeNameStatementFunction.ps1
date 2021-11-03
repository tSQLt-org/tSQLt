$scriptPath = $MyInvocation.MyCommand.Path;
$invocationDir = Split-Path $scriptPath;
$buildPath = $invocationDir +'/';
$tempPath = $invocationDir + '/temp/tSQLtBuild/';
$sourcePath = $invocationDir + '/../Source/';

.($buildPath+"CommonFunctionsAndMethods.ps1");

Log-Output '<#--=======================================================================================-->'
Log-Output '<!--========          Start GenerateGetFullTypeNameStatementFunction.ps1          =========-->'
Log-Output '<#--=======================================================================================-->'

$sourceFileContent = Get-Content -path ($sourcePath+"tSQLt.Private_GetFullTypeName.sfn.sql");

$statementSnip = ($SourceFileContent | Get-SnipContent -startSnipPattern "/*SnipStart: GenerateGetFullTypeNameStatementFunction.ps1*/" -endSnipPattern "/*SnipEnd: GenerateGetFullTypeNameStatementFunction.ps1*/");

$replacementToken = '/*ReplacementToken1 GenerateGetFullTypeNameStatementFunction.ps1*/';

$finalStatement = $statementSnip.Replace("'", "''") -Replace "(@\w+)", '''+$1+''';

$templateFileContent = Get-Content -path ($sourcePath+"tSQLt.Private_GetFullTypeNameStatement.template.sql");

$replacedFileContent = $templateFileContent.replace($replacementToken, $finalStatement);

Set-Content -Path (Join-Path $tempPath 'tSQLt.Private_GetFullTypeNameStatement.sfn.sql') -Value $replacedFileContent;
# C:\demo\2\tSQLt\Build\temp\tSQLtBuild\tSQLt.Private_GetFullTypeNameStatement.sfn.sql