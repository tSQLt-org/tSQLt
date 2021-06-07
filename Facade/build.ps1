<#
BuildHelper
- :SETVAR NewDbName db1
- Facade.CreateDatabase.sql so that we strip it of :SETVAR line, and create db1 to install tSQLt
- :SETVAR NewDbName db2
- Facade.CreateDatabase.sql --> create db2 to run the Facade.CreateAllFacadeObjects on db2
- USE db1
- output/tSQLt.class.sql
- Facade.CreateAllObjects.sql
#>
$scriptpath = $MyInvocation.MyCommand.Path;
$dir = Split-Path $scriptpath;
#Log-Output "FileLocation: $dir";
Set-Location $dir;

$facadeHeader1 = ':SETVAR NewDbName $(FacadeSourceDb)';
$facadeHeader2 = ':SETVAR NewDbName $(FacadeTargetDb)';
$facadeHeader3 = 'USE $(FacadeSourceDb);'

Set-Content "../Build/temp/FacadeHeader1.ps1" $facadeHeader1;
Set-Content "../Build/temp/FacadeHeader2.ps1" $facadeHeader2;
Set-Content "../Build/temp/FacadeHeader3.ps1" $facadeHeader3;

../Build/BuildHelper.exe "BuildOrder.txt" "../Build/output/CreateFacade.sql" "---Build" "+"
