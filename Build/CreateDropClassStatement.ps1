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

<#
TODO --> Test this: Empty File TempDropClass.sql file should throw an error
TODO --> Test this: If the $tempPath does not exist, BuildHelper.exe seems to currently throw an error, but does that stop the build?
TODO --> Test this: If the $sourcePath does not exist, BuildHelper.exe seems to currently throw an error, but does that stop the build?
#>

<#
# Read file and remove all empty lines
$fileContent = (Get-Content -path ($tempPath+"TempDropClass.sql")).trim() | Where-Object {$_ -ne "" -and $_ -notmatch "^GO(\s.*)?"};

# Make sure that the file is not empty
if($fileContent.length -eq 0) {
  throw "Length of fileContent is zero";
}

# trim lines and jam them all together with a space in between
$singleLineContent = $fileContent -join " ";

<replaceregexp match="^.*?BEGIN" replace="---Build+${line.separator}DECLARE @ClassName NVARCHAR(MAX) ='tSQLt';BEGIN" flags="gm" byline="false" file="temp/tSQLtBuild/TempDropClass.sql" />

#>

<#
if ($LoginTrimmed -match '((.*[-]U)|(.*[-]P))+.*'){
  $AuthenticationString = $LoginTrimmed -replace '^((\s*([-]U\s+)(?<user>\w+)\s*)|(\s*([-]P\s+)(?<password>\S+)\s*))+$', 'User Id=${user};Password="${password}"'  
}
#>

<# We need to replace this target with a exec target which calls a ps1 to do this work.
In addition, we will add a replace which will "in line" the relevant text of tSQLt.Private_GetDropItemCmd.

"suggested (◔_◔)" regex: tSQLt.Private_GetDropItemCmd(Ds.FullName, Ds.ItemType)
'tSQLt\s*.\s*Private_GetDropItemCmd\s*\(\s*([^,]*)\s*,\s*([^)]*)\s*\)'

It should look like this:



DECLARE @ClassName NVARCHAR(MAX) ='tSQLt';BEGIN DECLARE @Cmd NVARCHAR(MAX); WITH ObjectInfo(FullName, ItemType) AS ( SELECT QUOTENAME(SCHEMA_NAME(O.schema_id))+'.'+QUOTENAME(O.name), O.type FROM sys.objects AS O WHERE O.schema_id = SCHEMA_ID(@ClassName) ), TypeInfo(FullName, ItemType) AS ( SELECT QUOTENAME(SCHEMA_NAME(T.schema_id))+'.'+QUOTENAME(T.name), 'type' FROM sys.types AS T WHERE T.schema_id = SCHEMA_ID(@ClassName) ), XMLSchemaInfo(FullName, ItemType) AS ( SELECT QUOTENAME(SCHEMA_NAME(XSC.schema_id))+'.'+QUOTENAME(XSC.name), 'xml_schema_collections' FROM sys.xml_schema_collections AS XSC WHERE XSC.schema_id = SCHEMA_ID(@ClassName) ), SchemaInfo(FullName, ItemType) AS ( SELECT QUOTENAME(S.name), 'schema' FROM sys.schemas AS S WHERE S.schema_id = SCHEMA_ID(PARSENAME(@ClassName,1)) ), DropStatements(no,FullName,ItemType) AS ( SELECT 10, FullName, ItemType FROM ObjectInfo UNION ALL SELECT 20, FullName, ItemType FROM TypeInfo UNION ALL SELECT 30, FullName, ItemType FROM XMLSchemaInfo UNION ALL SELECT 10000, FullName, ItemType FROM SchemaInfo ), StatementBlob(xml)AS ( SELECT GDIC.cmd [text()] FROM DropStatements DS CROSS APPLY 
(
SELECT
   'DROP ' +
   CASE @ItemType 
     WHEN 'P' THEN 'PROCEDURE'
     WHEN 'PC' THEN 'PROCEDURE'
     WHEN 'U' THEN 'TABLE'
     WHEN 'IF' THEN 'FUNCTION'
     WHEN 'TF' THEN 'FUNCTION'
     WHEN 'FN' THEN 'FUNCTION'
     WHEN 'FT' THEN 'FUNCTION'
     WHEN 'V' THEN 'VIEW'
     WHEN 'type' THEN 'TYPE'
     WHEN 'xml_schema_collection' THEN 'XML SCHEMA COLLECTION'
     WHEN 'schema' THEN 'SCHEMA'
    END+
    ' ' + 
    @FullName + 
    ';' AS cmd
)
GDIC ORDER BY no FOR XML PATH(''), TYPE ) SELECT @Cmd = xml.value('/', 'NVARCHAR(MAX)') FROM StatementBlob; EXEC(@Cmd); END;

#>

 Log-Output '<#--=======================================================================-->'
 Log-Output '<!--========            End CreateDropClassStatement.ps1          =========-->'
 Log-Output '<#--=======================================================================-->'
 