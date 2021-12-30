# from https://github.com/teach-for-america/ssiscicd/blob/master/docker/mssqlssis/setupSSIS.ps1
Write-Verbose "Enable CLR Integration."
$enableCLRsqlcmd = "C:\SSIS_SCRIPTS\enableCLR.sql"
& sqlcmd -i $enableCLRsqlcmd

Write-Verbose "Create SSIS Catalog."
$create_SSIS_Catalog_Script= "C:\SSIS_SCRIPTS\createSSISCatalog.ps1"
&$create_SSIS_Catalog_Script