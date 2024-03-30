param(
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $pfxFilePath ,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][securestring] $pfxPassword
)
Push-Location -Path $PSScriptRoot

# Create a unique temporary directory for this process
$randomNumber = Get-Random -Minimum 10000 -Maximum 99999
$tempDir = Join-Path -Path "/tmp" -ChildPath $("myapp_${PID}_$randomNumber")
try{
    New-Item -Path $tempDir -ItemType Directory -Force
    Invoke-Expression "chmod 700 '$tempDir'"

    $snkFilePath = Join-Path -Path $tempDir -ChildPath "tSQLtOfficialSigningKey.snk"
    $pemFilePath = Join-Path -Path $tempDir -ChildPath "tSQLtOfficialSigningKey.pem"

    & openssl pkcs12 -in "$pfxFilePath" -out "$pemFilePath" -nodes -passin pass:"$((ConvertFrom-SecureString $pfxPassword -AsPlainText))"

    $rsa = New-Object System.Security.Cryptography.RSACryptoServiceProvider
    $pemContent = Get-Content -Path "$pemFilePath" -Raw
    $rsa.ImportFromPem($pemContent.ToCharArray())
    $keyPair = $rsa.ExportCspBlob($true)
    [System.IO.File]::WriteAllBytes($snkFilePath, $keyPair)

    & dotnet build /p:tSQLtOfficialSigningKey="$snkFilePath"
}
finally {
    try{Remove-Item -Path $tempDir -Recurse -Force}catch{Write-Host "deleting tempdir failed!"}
    Pop-Location
}