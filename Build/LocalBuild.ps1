param(
    [switch]$verbose
)

Push-Location -Path $PSScriptRoot
try{
    .("./CommonFunctionsAndMethods.ps1");

    Log-Output('');
    Log-Output("+--------------------------------------------------------------------+");
    Log-Output("|              ***** Executing Local tSQLt Build *****               |");
    Log-Output("+--------------------------------------------------------------------+");
    Log-Output('');

    
    Log-Output('+ - - - - - - - - - - - - - - - - - +')
    Log-Output(': Starting CLR Build                :')
    Log-Output('+ - - - - - - - - - - - - - - - - - +')

    & ./tSQLt_BuildCLR.ps1

    Log-Output('+ - - - - - - - - - - - - - - - - - +')
    Log-Output(': Starting tSQLt Build              :')
    Log-Output('+ - - - - - - - - - - - - - - - - - +')

    & ./tSQLt_Build.ps1

    # Log-Output('+ - - - - - - - - - - - - - - - - - +')
    # Log-Output(': Packaging tSQLt                   :')
    # Log-Output('+ - - - - - - - - - - - - - - - - - +')

    
}
finally{
    Pop-Location
}