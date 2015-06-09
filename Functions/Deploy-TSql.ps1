function Deploy-TSql {
<#  .SYNOPSIS
        Apply t-Sql changes to database objects in a named database.
    .Description
        During LMS deployments there are changes to the database objects accomplished
        using t-Sql scripts. These must be deployed in a logical manner usually based
        on case number.
    .Parameter SqlTag
        CaseNumber - [String].  The numeric value of the SysAid case that dev was performed under. (required)
        Ex:  -CaseNumber 13552
    .Parameter SqlTag
        SqlTag - [String].  Enter the SQL Server or SQLServer\Instance name
        with the port number if non-standard where the scripts are to be run. (required)
        EX:  -SqlTag 'DataUS\DevUS,4433'
    .Parameter DatabaseName
        DatabaseName - [String].  Enter the full database name to use for the deployed
        script context.
        EX:  'LMS'
    .Parameter DatabaseName
        RootPath - [String].  Enter path to the point just above your scriptPath folders.
        Ex:  "D:\GenDev-Project\Release13.2.1.0\FinalReleaseCode\Release13.2.1.2"
    .Example 
        Deploy-TSql -CaseNumber 13010 `
                -SqlTag $servername `
                -DatabaseName $dbName `           # This variable refers to a looping control in a forwach loop.
                -RootPath "D:\GenDev-Project\Release13.2.1.0\FinalReleaseCode\Release13.2.1.2"
        Using the full function name with all paramaters.
    .Notes 
        NAME: Deploy-TSql
        Alias: *NONE*
        AUTHOR: Richard Dawson
        Created:  05/21/2013 - Version 0.1 - This is a basic function.
        Compatibility - Version 1 and Version 2 and Version 3
    .Link 
	    about_functions 
	    about_functions_advanced 
	    about_functions_advanced_methods 
	    about_functions_advanced_parameters 
    .Inputs
    	SqlTag - [String] - Required	
    	DatabaseName - [String] - Required
    .Outputs
    	Return [] - N/A.
#>
	param(  [Parameter(Mandatory=$true, Position=0)][ValidateScript({$_ -ne $Null})] [string] $CaseNumber,
			[Parameter(Mandatory=$true, Position=1)][ValidateScript({$_ -ne $Null})] [string] $SqlTag,
			[Parameter(Mandatory=$true, Position=2)][ValidateScript({$_ -ne $Null})] [string] $DatabaseName,
            [Parameter(Mandatory=$true, Position=3)][ValidateScript({$_ -ne $Null})] [string] $Release,
			[Parameter(Mandatory=$true, Position=4)][ValidateScript({$_ -ne $Null})] [string] $RootPath
	        )


    $serverObj = New-Object PSObject -Property @{
        Corp_Sql2012 = "Corp-Sql2012,21021";
        Corp_VS2012 = "Corp-VS2012\SqlExpress,54568";
        QA_AGL01 = "QA-AGL01,27097";
        QA_AGL02 = "QA-AGL02,27097";
        SqlAG01 = "SqlAG01,27096";
        SqlAG02 = "SqlAG02,27069";
        SqlAG03 = "SqlAG03,29076";
        SqlAG04 = "SqlAG04,29067";
        pc_rdawson = "pc-rdawson\Sql2012,50249";
        US_Dev = "DataUS\DevUS,4433";
        US_QA = "DataUS\QAUS,4183";
        DBA_Backup = "DBA-Backup,14655";
        Dev_VSTF = "Dev-VSTF\SqlExpress,49254";
        DevReport = "Denali-Test\DevReport,20061";
        Sandbox = "Sandbox,16755";
        Backup = "Sql-Backup,18766";
        DR = "Sql-DR,16952";
        Monitor = "Sql-Monitor,16723";
        ReportDB = "Sql-ReportDB,2186";
        Distribution = "Sql-ReportDB\Distributor,2188";
        Prod_Staging = "Stg-Sql,14563"
        TDCVSql02 = "TDCVSql02,1433";
        }

    $srvrString = $serverObj.[string]$SqlTag

    $OFS = ","
    $scriptPath = $RootPath+"\";

    $logPath = $scriptPath+"ReleaseLog\";
    $schemaPath = $scriptPath+"Production\Procedures\";
    $provPath = $scriptPath+"Production\Provisioning\";
    $rptProcPath = $scriptPath+"ReportDB Only\Procedures\";
    $rptProvPath = $scriptPath+"ReportDB Only\Provisioning\";



#   I need to change this to use the Get-Credentail function and assign the username and
#   password to the variables at runtime.

#    $userName = 'rlDawson'        #  If you are using Sql Authentication put your username here
#    $pswd     = 'xxxxxxxx'        #  If you are using Sql Authentication put your password here


#   Everything after this are things that I want to break out and put into a module for easier
#   reuse.

    $pathIsValid = Test-Path -Path $logPath
    if ( $pathIsValid -eq $false ) {
        mkdir $logPath > $null;
        }

    $pathIsValid = Test-Path -Path $logPath
    if ( $pathIsValid -eq $true ) {
        Write-Host "The ReleaseLog path exists"
        }

#   I switch which one of the sqlcmd lines are called depending on whether we are running
#   against the corp network servers or the prod network servers.
#   once we have moved to sql 2012 it won't matter as they will use windows authentication
#   and the sql server data engine has powershell integration built in.

    Write-Host
    Write-Host –NoNewLine "Deploying Case#: "$CaseNumber' to db: '$DatabaseName' on '$SqlTag;
    Write-Host

	$filter = [string]$CaseNumber+"_SCHEMA*";

    $pathIsValid = Test-Path -Path $schemaPath
    if ( $pathIsValid -eq $true) {
        $s = Get-ChildItem -Path $schemaPath -file -Name -Filter $filter

#       In the sections below this if you are using sql authentication leave it as is.
#       If you are using windows authentication swap the commented lines.
        foreach ($tsql in $s) {
            Write-Host $tsql
#           sqlcmd -S $srvrString -d $DatabaseName -U $userName -P $pswd -i $schemaPath$tsql -e -o $logPath$DatabaseName"_"$tsql"_Report.txt"
            sqlcmd -S $srvrString -d $DatabaseName -E -i $schemaPath$tsql -e -o $logPath$DatabaseName"_"$tsql"_Report.txt"
#            Invoke-SqlCmd -Database $DatabaseName -InputFile $schemaPath$tsql -OutputSqlErrors $true -ServerInstance $srvrString  | Out-File -filePath $logPath$DatabaseName"_"$tsql"_Report.txt"
            }

	    $filter = [string]$CaseNumber+"_TRIG*";

        $t = Get-ChildItem -Path $schemaPath -file -Name -Filter $filter

        foreach ($tsql in $t) {
            Write-Host $tsql
#           sqlcmd -S $srvrString -d $DatabaseName -U $userName -P $pswd -i $schemaPath$tsql -e -o $logPath$DatabaseName"_"$tsql"_Report.txt"
            sqlcmd -S $srvrString -d $DatabaseName -E -i $schemaPath$tsql -e -o $logPath$DatabaseName"_"$tsql"_Report.txt"
#           Invoke-SqlCmd -Database $DatabaseName -InputFile $schemaPath$tsql -OutputSqlErrors $true -ServerInstance $srvrString  | Out-File -filePath $logPath$DatabaseName"_"$tsql"_Report.txt"
            }

	    $filter = [string]$CaseNumber+"_VIEW*";

        $v = Get-ChildItem -Path $schemaPath -file -Name -Filter $filter

        foreach ($tsql in $v) {
            Write-Host $tsql
#           sqlcmd -S $srvrString -d $DatabaseName -U $userName -P $pswd -i $schemaPath$tsql -e -o $logPath$DatabaseName"_"$tsql"_Report.txt"
            sqlcmd -S $srvrString -d $DatabaseName -E -i $schemaPath$tsql -e -o $logPath$DatabaseName"_"$tsql"_Report.txt"
#           Invoke-SqlCmd -Database $DatabaseName -InputFile $schemaPath$tsql -OutputSqlErrors $true -ServerInstance $srvrString  | Out-File -filePath $logPath$DatabaseName"_"$tsql"_Report.txt"
            }

	    $filter = [string]$CaseNumber+"_FUNC*";

        $r = Get-ChildItem -Path $schemaPath -file -Name -Filter $filter

        foreach ($tsql in $r) {
            Write-Host $tsql
#           sqlcmd -S $srvrString -d $DatabaseName -U $userName -P $pswd -i $schemaPath$tsql -e -o $logPath$DatabaseName"_"$tsql"_Report.txt"
            sqlcmd -S $srvrString -d $DatabaseName -E -i $schemaPath$tsql -e -o $logPath$DatabaseName"_"$tsql"_Report.txt"
#           Invoke-SqlCmd -Database $DatabaseName -InputFile $schemaPath$tsql -OutputSqlErrors $true -ServerInstance $srvrString  | Out-File -filePath $logPath$DatabaseName"_"$tsql"_Report.txt"
            }

	    $filter = [string]$CaseNumber+"_PROC*";

        $p = Get-ChildItem -Path $schemaPath -file -Name -Filter $filter

        foreach ($tsql in $p) {
            Write-Host $tsql
#           sqlcmd -S $srvrString -d $DatabaseName -U $userName -P $pswd -i $schemaPath$tsql -e -o $logPath$DatabaseName"_"$tsql"_Report.txt"
            sqlcmd -S $srvrString -d $DatabaseName -E -i $schemaPath$tsql -e -o $logPath$DatabaseName"_"$tsql"_Report.txt"
#           Invoke-SqlCmd -Database $DatabaseName -InputFile $schemaPath$tsql -OutputSqlErrors $true -ServerInstance $srvrString  | Out-File -filePath $logPath$DatabaseName"_"$tsql"_Report.txt"
            }
        }

    $pathIsValid = Test-Path -Path $provPath

    if ( $pathIsValid -eq $true ) {
    	$filter = [string]$CaseNumber+"_PROV*";

        $p = Get-ChildItem -Path $provPath -file -Name -Filter $filter

        foreach ($tsql in $p) {
            Write-Host $tsql
#           sqlcmd -S $srvrString -d $DatabaseName -U $userName -P $pswd -i $provPath$tsql -e -o $logPath$DatabaseName"_"$tsql"_ProvReport.txt"
            sqlcmd -S $srvrString -d $DatabaseName -E -i $provPath$tsql -e -o $logPath$DatabaseName"_"$tsql"_Report.txt"
#           Invoke-SqlCmd -Database $DatabaseName -InputFile $provPathPath$tsql -OutputSqlErrors $true -ServerInstance $srvrString  | Out-File -filePath $logPath$DatabaseName"_"$tsql"_Report.txt"
            }
        }

	$filter = [string]$CaseNumber+"_PROC*";

    $pathIsValid = Test-Path -Path $rptProcPath
    if ( $pathIsValid -eq $true) {
        $s = Get-ChildItem -Path $rptProcPath -file -Name -Filter $filter

#       In the sections below this if you are using sql authentication leave it as is.
#       If you are using windows authentication swap the commented lines.
        foreach ($tsql in $s) {
            Write-Host $tsql
#           sqlcmd -S $srvrString -d $DatabaseName -U $userName -P $pswd -i $schemaPath$tsql -e -o $logPath$DatabaseName"_"$tsql"_Report.txt"
            sqlcmd -S $srvrString -d $DatabaseName -E -i $schemaPath$tsql -e -o $logPath$DatabaseName"_"$tsql"_Report.txt"
#           Invoke-SqlCmd -Database $DatabaseName -InputFile $schemaPath$tsql -OutputSqlErrors $true -ServerInstance $srvrString  | Out-File -filePath $logPath$DatabaseName"_"$tsql"_Report.txt"
            }
        }

	$filter = [string]$CaseNumber+"_PROV*";

    $pathIsValid = Test-Path -Path $rptProvPath
    if ( $pathIsValid -eq $true) {
        $s = Get-ChildItem -Path $rptProvPath -file -Name -Filter $filter

#       In the sections below this if you are using sql authentication leave it as is.
#       If you are using windows authentication swap the commented lines.
        foreach ($tsql in $s) {
            Write-Host $tsql
#           sqlcmd -S $srvrString -d $DatabaseName -U $userName -P $pswd -i $schemaPath$tsql -e -o $logPath$DatabaseName"_"$tsql"_Report.txt"
            sqlcmd -S $srvrString -d $DatabaseName -E -i $schemaPath$tsql -e -o $logPath$DatabaseName"_"$tsql"_Report.txt"
#           Invoke-SqlCmd -Database $DatabaseName -InputFile $schemaPath$tsql -OutputSqlErrors $true -ServerInstance $srvrString  | Out-File -filePath $logPath$DatabaseName"_"$tsql"_Report.txt"
            }
        }



#    The test file referenced here is one that I write for each case. It is a check for existance or
#    modification of any objects referenced in the scripts for a specified case. One of the things I
#    have in mind to do is to write some code that could parse our script files and find the name and
#    type of db object and dynamically create this part.

<#  $pathIsValid = Test-Path -Path $scriptPath"Test For Successful $caseNumber Deploy.sql"

    if ( $pathIsValid -eq $true ) {
#       sqlcmd -S $srvrString -d $DatabaseName -U $userName -P $pswd -i $scriptPath"Test For Successful $caseNumber Deploy.sql" -e -o $logPath"000"$DatabaseName"_"$caseNumber"_FinalReport.txt"
#       sqlcmd -S $srvrString -d $DatabaseName -E -i $scriptPath"Test For Successful $caseNumber Deploy.sql" -e -o $logPath"000"$DatabaseName"_"$caseNumber"_FinalReport.txt"
        Invoke-SqlCmd -Database $DatabaseName -InputFile $scriptPath"Test For Successful $caseNumber Deploy.sql" -OutputSqlErrors $true -ServerInstance $srvrString  | Out-File -filePath $logPath"000"$DatabaseName"_"$caseNumber"_FinalReport.txt"
        Write-Host;
        }   #>
    }


#sqlcmd -S $srvrString -d 'master' -E -i $provPath$tsql -e -o $logPath$DatabaseName"_"$tsql"_ProvReport.txt"


#   Deploy Prod_Staging
cls
$servername = "Prod_Staging";
$scriptPath = "D:\GenDev-Project\Deployment\SQLScripts\"
$release    = "Release14.2.2.0"

$db = @( 'LMS', 'LMS_001', 'LMS_002', 'LMS_004', 'LMS_005', 'LMS_007', 'LMS_008', 'LMS_009', 'LMS_010',
         'LMS_011', 'LMS_012', 'LMS_013', 'LMS_014', 'LMS_017', 'LMS_018', 'LMS_019', 'LMS_021', 'LMS_022',
         'LMS_023', 'LMS_024', 'LMS_025', 'LOC_001' )


    $start = Get-Date

    foreach ($dbName in $db) {
        Write-Host
        Write-Host $dbName
        $now = Get-Date
        Write-Host
        Write-Host $now     #   What time is it

#   One line for each case number in the deployment
        Deploy-TSql -CaseNumber 28993 -SqlTag $servername -DatabaseName $dbName -Release $release -RootPath $scriptPath

        Deploy-TSql -CaseNumber 29006 -SqlTag $servername -DatabaseName $dbName -Release $release -RootPath $scriptPath

        Deploy-TSql -CaseNumber 29172 -SqlTag $servername -DatabaseName $dbName -Release $release -RootPath $scriptPath

        Deploy-TSql -CaseNumber 29276 -SqlTag $servername -DatabaseName $dbName -Release $release -RootPath $scriptPath
        }

#   Write a final datetime to get the duration.
    $now = Get-Date
    Write-Host
    Write-Host $now              #   What time is it
    Write-Host $now - $start     #   What is the difference


