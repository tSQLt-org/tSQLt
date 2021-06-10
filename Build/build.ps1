<#
Step # is to replace the body of the  <target name="package.create.artifacts"> dba "exec.powershell.build" from tSQLt.build.xml
#>











<#
Step # is to replace the body of the  <target name="package.create.artifacts"> dba "exec.powershell.build" from tSQLt.build.xml
#>

# Delete files which might have been generated from previous builds
$toBeDeleted = @("tSQLt.zip", "ReadMe.txt", "Version.txt");
Get-ChildItem -Path "output/*" -Include $toBeDeleted | Remove-Item;

$toBeZipped = @("ReleaseNotes.txt", "License.txt", "tSQLt.class.sql", "Example.sql", "PrepareServer.sql");
$compress = @{
    CompressionLevel = "Optimal"
    DestinationPath = "output/tSQLt.zip"
    }
Get-ChildItem -Path "temp/*" -Include $toBeZipped | Compress-Archive @compress

Copy-Item "temp/ReleaseNotes.txt" -Destination "output/ReadMe.txt";
Copy-Item "temp/Version.txt" -Destination "output/";
Copy-Item "temp/tSQLt.class.sql" -Destination "output/";

throw "Figure out how to build and run facade in the build: current favorite, new target in ant file, separate zip file for all Facade"