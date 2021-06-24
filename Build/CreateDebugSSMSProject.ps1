
$scriptpath = $MyInvocation.MyCommand.Path;
$dir = Split-Path $scriptpath;
$ParentDir = Split-Path $dir;
$DebugProjectPath = $ParentDir + "/Build_Debug/";
$OutputPath = $dir + "/output/";

.($dir+"\CommonFunctionsAndMethods.ps1");

<# Delete all files in Build_Debug except for the ssmssqlproj and .gitignore #>
$FileNamesToExclude = ".gitignore", "Build_Debug.ssmssqlproj";
Remove-Item  -Path $DebugProjectPath -Include "*" -Exclude $FileNamesToExclude -Recurse -Force;

<# "hello announcement" #>
$VersionFile = "output/tSQLtBuild/Version.txt";
$Version = Get-Content $VersionFile;
Log-Output ("Copying tSQLt build files to local Build_Debug. (Version:" + $Version.Trim() + ")");

<# "copy output files and unzip tSQLt.zip and tSQLt.tests.zip" #>
$OutputFilesToCopy = @(
    ($OutputPath + "tSQLt/tSQLt.zip")
    ($OutputPath + "tSQLtBuild/tSQLt.tests.zip")
    ($OutputPath + "tSQLtBuild/tSQLtSnippets(SQLPrompt).zip")
    ($OutputPath + "tSQLtBuild/Version.txt")
    ($OutputPath + "tSQLtBuild/ReadMe.txt")
);
Copy-Item -Path $OutputFilesToCopy -Destination "$DebugProjectPath";

$tSQLtZipFile = $DebugProjectPath + "tSQLt.zip";
Expand-Archive -Path $tSQLtZipFile -DestinationPath $DebugProjectPath;

$tSQLtTestsZipFile = $DebugProjectPath + "tSQLt.tests.zip";
Expand-Archive -Path $tSQLtTestsZipFile -DestinationPath $DebugProjectPath;
