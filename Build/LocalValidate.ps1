param(
    [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()][string] $ServerName = 'localhost,1433',
    [Parameter(Mandatory=$true, ParameterSetName = 'UserPass')][ValidateNotNullOrEmpty()][string] $UserName = "sa" ,
    [Parameter(Mandatory=$true, ParameterSetName = 'UserPass')][ValidateNotNullOrEmpty()][securestring] $Password = (ConvertTo-SecureString "P@ssw0rd" -AsPlainText),
    [Parameter(Mandatory=$true, ParameterSetName = 'TrustedCon')][ValidateNotNullOrEmpty()][switch] $TrustedConnection,
    [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()][string] $DatabaseName = 'tSQLtValidateBuild',
    [Parameter(Mandatory=$false, ParameterSetName="IgnoreMe")][string]$IgnoreMe
)
$PSDefaultParameterValues = $PSDefaultParameterValues.clone()
$PSDefaultParameterValues += @{'*:ErrorAction' = 'Stop'}

Write-Host "Starting execution of LocalBuild.ps1"
$__=$__ #quiesce warnings
$invocationDir = $PSScriptRoot
Push-Location -Path $invocationDir
$cfam = (Join-Path $invocationDir "CommonFunctionsAndMethods.psm1" | Resolve-Path)
Write-Host "Attempting to load module from: $cfam"
Import-Module "$cfam" -Force -Verbose
. (Join-Path $invocationDir 'SQLServerConnection.ps1');


try{

    if($TrustedConnection){
        Write-Warning('GH:TC')
        $SqlServerConnection = [SqlServerConnection]::new($ServerName,"LocalBuild");
    }else{
        Write-Warning('GH:UP')
        $SqlServerConnection = [SqlServerConnection]::new($ServerName,$UserName,$Password,"LocalBuild");
    }

    Log-Output('');
    Log-Output("+--------------------------------------------------------------------+");
    Log-Output("|         ***** Executing Local tSQLt Build Validation *****         |");
    Log-Output("+--------------------------------------------------------------------+");
    Log-Output('');

    
    Log-Output('+ - - - - - - - - - - - - - - - - - +')
    Log-Output(': Starting Build Validation         :')
    Log-Output('+ - - - - - - - - - - - - - - - - - +')

    $parameters = @{
        SqlServerConnection = $SqlServerConnection
        MainTestDb = 'tSQLt.TmpBuild.ValidateBuild'
        DacpacTestDb = 'tSQLt.TmpBuild.ValidateDacPac'
        ExampleTestDb = 'tSQLt.TmpBuild.ValidateExample'
    }

    & ./tSQLt_Validate.ps1 @parameters

    Log-Output('+ - - - - - - - - - - - - - - - - - +')
    Log-Output(': Build Validation Finished         :')
    Log-Output('+ - - - - - - - - - - - - - - - - - +')

    
}
catch{
    throw;
}
finally{
    Pop-Location
}