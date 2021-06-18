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
