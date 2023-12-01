Push-Location -Path $PSScriptRoot

# Create a unique temporary directory for this process
$randomNumber = Get-Random -Minimum 10000 -Maximum 99999
$tempDir = Join-Path -Path "/tmp" -ChildPath $("myapp_${PID}_$randomNumber")
try{
    New-Item -Path $tempDir -ItemType Directory -Force
    $snkFilePath = Join-Path -Path $tempDir -ChildPath "tSQLtOfficialSigningKey.snk"
    # Set directory permissions to be accessible only by the current user
    Invoke-Expression "chmod 700 '$tempDir'"

    # Define paths and names
    $pfxPath = Join-Path -Path $env:TSQLTCERTPATH -ChildPath $("tSQLtOfficialSigningKey.pfx")
    $pfxPassword = $env:TSQLTCERTPASSWORD

    # Extract the private key from the PFX and convert to SNK
    & openssl pkcs12 -in $pfxPath -nocerts -nodes -passin pass:$pfxPassword | openssl rsa -outform DER -out $snkFilePath

    # Check for errors in the last command
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to extract and convert the private key"
        exit $LASTEXITCODE
    }    

    & dotnet build /p:tSQLtOfficialSigningKey=$snkFilePath        
}
finally {
    try{Remove-Item -Path $tempDir -Recurse -Force}catch{Write-Host "deleting tempdir failed!"}
    Pop-Location
}