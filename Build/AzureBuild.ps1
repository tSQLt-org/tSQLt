# [CmdletBinding()]
# param (
#     [Parameter()][string]$AzureFQDN,
#     [Parameter()][string]$AzurePort,
#     [Parameter()][string]$AzureUser,
#     [Parameter()][string]$AzurePwd
# )

<#
Create New ASDB
--
create zip file artifacts from dirs
--
Connect to ASDB
Install tSQLt

tSQLt.RunNew Reset
install main tests
tSQLt.RunNew
capture into summarylog

tSQLt.RunNew Reset
install  tests2
tSQLt.RunNew
capture into summarylog

tSQLt.RunNew Reset
install  tests3
tSQLt.RunNew
capture into summarylog

tSQLt.RunNew Reset
install  tests4
tSQLt.RunNew
capture into summarylog

Report on all test results
--
Delete ASDB
#>

class tSQLt {

    [string]$tSQLtClassSQLFilePath;
    [string]$DatabaseFQDN;
    [string]$DatabasePort;
    [string]$DatabaseUser;
    [string]$DatabasePwd ;  

    tSQLt(
        [string]$tSQLtClassSQLFilePath,
        [string]$DatabaseFQDN,
        [string]$DatabasePort,
        [string]$DatabaseUser,
        [string]$DatabasePwd
    ){
        $this.$tSQLtClassSQLFilePath = $tSQLtClassSQLFilePath;
        $this.$DatabaseFQDN = $DatabaseFQDN;
        $this.$DatabasePort = $DatabasePort;
        $this.$DatabaseUser = $DatabaseUser;
        $this.$DatabasePwd = $DatabasePwd;
    }

    [void]install(){

    }

    [void]runTestSuite(
        [tSQLtTestSuite]$tSQLtTestSuite
    ){
        <#
            tSQLt.RunNew Reset
            install  tests4
            tSQLt.RunNew
            capture into summarylog  
        #>
    }
}

#tSQLtTest
#tSQLtTestClass
class tSQLtTestSuite {

    [string]$testSuiteFolderPath;
    [string]$testSuiteName;

    tSQLtTestSuite(
        [string]$testSuiteFolderPath,
        [string]$testSuiteName
    ){
        this.$testSuiteFolderPath = $testSuiteFolderPath;
        this.$testSuiteName = $testSuiteName;
    }

}
