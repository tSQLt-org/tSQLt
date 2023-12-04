param (
    [string]$OutputPath,
    [string]$DllPath,
    [string]$TemplatePath,
    [string]$HexPlaceholder,
    [string]$ThumbprintPlaceholder,
    [int]$MaxLineLength,
    [string]$LineSeparator
)
.(Join-Path $PSScriptRoot '../CommonFunctionsAndMethods.ps1'| Resolve-Path)

function Convert-DllToHex {
    param (
        [byte[]]$Bytes,
        [int]$MaxLineLength,
        [string]$LineSeparator
    )

    # Convert to hex string
    $hexString = ($Bytes | ForEach-Object { $_.ToString("X2") }) -join ''

    # Split hex string into lines of specified length
    $hexLines = $hexString -split "(.{$MaxLineLength})" | Where-Object { $_ }

    # Join lines with separator
    return ($hexLines -join $LineSeparator)
}

function Get-AssemblyThumbprint {
    param (
        [string]$DllPath
    )
    
    $getAssemblyInfoPath = (Join-Path $PSScriptRoot "GetAssemblyInfo.ps1" | Resolve-Path)
    $token = & $getAssemblyInfoPath $DllPath -t
    return $token
}

function Replace-TemplatePlaceholders {
    param (
        [string]$TemplatePath,
        [string]$HexPlaceholder,
        [string]$ThumbprintPlaceholder,
        [string]$HexContent,
        [string]$Thumbprint
    )

    $templateContent = Get-Content $TemplatePath -Raw

    # Replace placeholders
    $templateContent = $templateContent -replace $ThumbprintPlaceholder, ('--TTTT--' + $ThumbprintPlaceholder + '--TTTT--')
    $templateContent = $templateContent -replace $HexPlaceholder, ('0x' + $HexContent)
    $templateContent = $templateContent -replace ('--TTTT--' + $ThumbprintPlaceholder + '--TTTT--'), ('0x' + $Thumbprint)

    return $templateContent
}

if (-not (Test-Path $DllPath)) {
    Write-Error "DLL not found at path: $DllPath"
    return
}

if (-not (Test-Path $TemplatePath)) {
    Write-Error "Template file not found at path: $TemplatePath"
    return
}

if ($MaxLineLength -le 10) {
    Write-Error "Max line length must be greater than 10"
    return
}

try {
    # Read DLL file bytes
    $bytes = [System.IO.File]::ReadAllBytes($DllPath)

    # Convert DLL to hex
    $hexContent = Convert-DllToHex -Bytes $bytes -MaxLineLength $MaxLineLength -LineSeparator $LineSeparator

    # Get assembly thumbprint
    $thumbprint = Get-AssemblyThumbprint -DllPath $DllPath

    # Replace placeholders in template
    $outputContent = Replace-TemplatePlaceholders -TemplatePath $TemplatePath -HexPlaceholder $HexPlaceholder -ThumbprintPlaceholder $ThumbprintPlaceholder -HexContent $hexContent -Thumbprint $thumbprint

    # # Output to file
    $outputContent | Out-File -FilePath $outputPath

    Log-Output("Output generated: $outputPath");
    # $outputContent
}
catch {
    Write-Error "Error: $_"
}
