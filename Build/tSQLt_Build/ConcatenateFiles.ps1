param(
    [Parameter(Mandatory=$true)][string]$OutputFile,
    [Parameter(Mandatory=$true)][string]$SeparatorTemplate,
    [Parameter(Mandatory=$true)][string]$InputPath,
    [hashtable]$replacements = @{},
    [string]$IncludePattern,
    [string]$Bracket,
    [switch]$IncludeFromStart
)

function Get-FileContent {
    param(
        [string]$filePath,
        [string]$bracket,
        [bool]$includeFromStart,
        [string[]]$separator
    )

    $include = $includeFromStart
    $includeHeader = $true
    $includeNameInHeader = $true
    $content = @()
    # Write-Host(">$bracket-n<")

    Get-Content $filePath -ErrorAction Stop| ForEach-Object {
        # Write-Host("$Include::>$_<")
        if ($_ -eq "$bracket-h") {
            $includeHeader = $false
        } elseif ($_ -eq "$bracket-n") {
            $includeNameInHeader = $false
        } elseif ($_ -eq "$bracket+") {
            $include = $true
        } elseif ($_ -eq "$bracket-") {
            $include = $false
        } elseif ($include) {
            $content += $_
        }
    }
    if($includeHeader){
        $filename = ""
        if($includeNameInHeader){
            $fileName = (Split-Path $file -Leaf)
        }
        $content = $separator.Replace("/*--FILENAME--*/",$fileName) + $content
    }
    return $content
}

# Function to concatenate files
function Concatenate-Files {
    param(
        [object]$fileIterator,
        [string[]]$separator,
        [string]$bracket,
        [bool]$includeFromStart
    )

    $output = @()

    foreach ($file in $fileIterator) {
        Write-Host("-->$file")
        $fileContent = Get-FileContent -filePath $file -bracket $bracket -includeFromStart $includeFromStart -separator $separator
        $output += $fileContent
    }

    return $output
}

Write-Host("OutputFile: $OutputFile")
Write-Host("SeparatorTemplate: $SeparatorTemplate")
Write-Host("Input: $InputPath")
$separatorContent = Get-Content $SeparatorTemplate  -ErrorAction Stop
$scriptPath = (Split-Path $InputPath)
Write-Host("Separator Template:")
$separatorContent|%{Write-Host(">:$_")}
Write-Host("scriptPath: $scriptPath")

try{
    if (Test-Path $InputPath -PathType Leaf) {
        # Input is a file
        $fileList = Get-Content $InputPath -ErrorAction Stop
        $fileIterator = $fileList | ForEach-Object { Join-Path $scriptPath $_ | Resolve-Path}

    } else {
        # Input is a directory
        $fileIterator = Get-ChildItem $InputPath -Filter $Pattern
    }
    $concatenatedContent = Concatenate-Files -fileIterator $fileIterator -separator $separatorContent -bracket $Bracket -includeFromStart $IncludeFromStart
    $replacements.Keys|%{$rv=$replacements[$_]; Write-Host("Replacing >$_< with >$rv<...");$concatenatedContent = $concatenatedContent.Replace($_,$rv)}
    $concatenatedContent | Out-File $OutputFile
}catch{
    throw
}
# $concatenatedContent