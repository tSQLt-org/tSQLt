param([Parameter(Mandatory = $true)][string]$dllPath,
    [Parameter(Mandatory = $true)][string]$templatePath,
    [Parameter(Mandatory = $true)][string]$assemblyPattern,
    [string]$thumbPrintPattern,
    [int]$maxLength = 0,
    [string]$separator = "'+$( [Environment]::NewLine )'")

$ErrorActionPreference = 'Stop'

class Generator
{
    static
    [string]
    GetHexStringFromBytes([byte[]]$dllBytes)
    {
        $stringBuilder = [System.Text.StringBuilder]::new('0x', $dllBytes.Length * 2 + 2)

        foreach ($dllByte in $dllBytes)
        {
            $stringBuilder.Append($dllByte.ToString('X2'))
        }

        return $stringBuilder.ToString()
    }

    static
    [byte[]]
    GetBytesFromDll([string]$dllPath)
    {
        return (Get-Content -Path $dllPath -AsByteStream -Raw)
    }

    static
    [string]
    GetTemplateFile([string]$templatePath)
    {
        return (Get-Content -Path $templatePath -Raw)
    }

    static
    [string]
    GetTemplate([string]$templatePath,
                [string]$assemblyPattern,
                [string]$thumbPrintPattern)
    {
        $template = [Generator]::GetTemplateFile($templatePath)
        if ($template -notmatch $assemblyPattern)
        {
            throw "The specified template file [" + $templatePath + "] did not contain the specified assembly pattern [" + $assemblyPattern + "]!"
        }

        if (![string]::IsNullOrEmpty($thumbPrintPattern) -and $template -notmatch $thumbPrintPattern)
        {
            throw "The specified template file [" + $templatePath + "] did not contain the specified thumbprint pattern [" + $thumbPrintPattern + "]!"
        }
        return $template
    }

    static
    [byte[]]
    GetAssemblyBytes([string]$dllPath)
    {
        $bytesFromDll = [Generator]::GetBytesFromDll($dllPath)
        if ($bytesFromDll.Length -eq 0)
        {
            throw "The DLL specified [" + $dllPath + "] for generating the CREATE ASSEMBLY statement was empty"
        }
        return $bytesFromDll
    }

    static
    [string]
    Wrap([string]$hexString,
         [int] $maxLength,
         [string] $separator)
    {
        if ($maxLength -le 0 -or $hexString.Length -le $maxLength)
        {
            return $hexString
        }

        $separator = $separator -replace '\\n', [Environment]::NewLine
        $stringBuilder = [System.Text.StringBuilder]::new($hexString.Length + [int][Math]::Floor($hexString.Length / $maxLength) * $separator.Length)

        $stringBuilder.Append($hexString, 0, $maxLength);
        for ($i = $maxLength; $i -lt $hexString.Length; $i += $maxLength) {
            $stringBuilder.Append($separator)
            $stringBuilder.Append($hexString, $i,[Math]::Min($maxLength, $hexString.Length - $i))
        }

        return $stringBuilder.ToString()
    }
}

$template = [Generator]::GetTemplate($templatePath, $assemblyPattern, $thumbPrintPattern)
$assemblyBytes = [Generator]::GetAssemblyBytes($dllPath)

if (![string]::IsNullOrEmpty($thumbPrintPattern))
{
    $thumbPrint = [Generator]::GetHexStringFromBytes([System.Reflection.Assembly]::Load($assemblyBytes).GetName().GetPublicKeyToken())
    $template = $template -replace $thumbPrintPattern, $thumbPrint
}

if (![string]::IsNullOrEmpty($assemblyPattern))
{
    $hexString = [Generator]::GetHexStringFromBytes($assemblyBytes)
    $assembly = [Generator]::Wrap($hexString, $maxLength, $separator)
    $template = $template -replace $assemblyPattern, $assembly
}

Write-Host $template
