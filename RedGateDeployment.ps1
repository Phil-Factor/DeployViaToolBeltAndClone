 <# 
 This script is about maintaining the various databases required for test and development, being
 copies of what is in source control, with one or more versions of data for test or development
 It uses the SQL Toolbelt and will make use of SQL clone. If you have the SQL Toolbelt but no
 clone, you can still do this but it will be much slower and it will take more space. 
   
In this script, we are assuming a database being developed and source kept in Source control. If
not already in source control, a directory is created, and stocked from the development server with
the latest version of the code on it, and we assume that this will then be turned into
a github repository. Whichever way it happens, you specify the directory. The code and data are
both stored in this repository. In reality, there will be a number of different data sets
for various forms of testing

Then a new build is created and checked against the source. 

In the next stage, a clone is created 

Finally, a list of databases in one or more servers are either refreshed or created with
copies of the database as built by the build process.

This should end up with all databases with identical metadata and data.
#>
$VerbosePreference = "Silentlycontinue"
# the import process is very noisy if you are in verbose mode
Import-Module sqlps -DisableNameChecking #load the SQLPS functionality
$VerbosePreference = "continue"

# set "Option Explicit" to catch subtle errors
set-psdebug -strict
$ErrorActionPreference = "stop"

<# just to make it easier to understand, the various values are structured in a hierarechy. We 
iterate over the clones when making or updating them #>
#read in the configuration
$data = $null

$Data = &'MyInstallationData.ps1'
<# we read in the data as a structure. Then we do some sanity checking to make sure that the 
data is reasonably viable. #>

$DataError = ''
if ($data.source.DatabasePath -eq $null) { $DataError += 'no source.DatabasePath,' };
if ($data.tools.SQLCompare -eq $null) { $DataError += 'no path to SQL Compare ' };
if ($data.source.ReportPath -eq $null) { $DataError += 'no source.ReportPath,' };
if ($data.source.DataSyncFile -eq $null) { $DataError += 'no source.DataSyncFile' };
if ($data.Build.NewBuildServerInstance -eq $null) { $DataError += 'Build.NewBuildServerInstance,' };
if ($data.Build.NewDatabase -eq $null) { $DataError += 'no Build.NewDatabase,' };
if ($data.Image.Name -eq $null) { $DataError += 'no Image.Name,' };
if ($data.Image.ServerURL -eq $null) { $DataError += 'no Image.ServerURL,' };
if ($data.Image.ID -eq $null) { $DataError += 'no Image.ID,' };
if ($DataError -ne '') { Throw "Cannot run the application because there is $DataError" }

# Firstly, we create the aliases to make the execution of command-line programs easier.
Set-Alias SQLCompare $data.tools.SQLCompare  -Scope Script
if ($data.tools.SQLCompare -ne $null) {Set-Alias SQLDataCompare $data.tools.SQLCompare  -Scope Script}
# there are other ways to execute command-line apps, but this seems stress-free
if ($data.tools.SQLDataGenerator -ne $null) {Set-Alias SQLDataGenerator $data.tools.SQLDataGenerator  -Scope Script}
if ($data.tools.SQLDoc -ne $null) {Set-Alias SQLDoc $data.tools.SQLDoc  -Scope Script}

#initialise SQL Clone
Connect-SqlClone -ServerUrl $data.image.ServerURL


# first of all we specify a working version that we can use if we  haven't already a source control
# directory
# first see if the source control directory exists. 
# If there isn't anything there, then create it.
if (-not (Test-Path -PathType Container $data.source.DatabasePath))
{
    # we create the script directory (normally you get these scripts from source control but to make the
    # script more versatile we'll create it if it isn't there
    New-Item -ItemType Directory -Force -Path $data.source.DatabasePath;
}
if (-not (Test-Path -PathType Container $data.source.ReportPath))
{
    # we create the report directory if it doesn't already exist
    New-Item -ItemType Directory -Force -Path $data.source.ReportPath;
}
# if there are no build scripts there, then generate them from build database on the current build server 
if (-not (Test-Path -path "$($data.source.DatabasePath)\Source\*.*"))
{
    if (-not (Test-Path -PathType Container "$($data.source.DatabasePath)/Source"))
    {
        # we create the script source directory (normally you get these from source control
        New-Item -ItemType Directory -Force -Path "$($data.source.DatabasePath)/Source";
    }
    <# at this point we've established that you have not created a source directory so we will
    retro-fit it from your development database, as a series of object-level scripts in orderly
    subdirectories #>
    $DataError = ''
    if ($data.Current.DevServerInstance -eq $null) { $DataError += 'no Current.DevServerInstance,' };
    if ($data.Current.Database -eq $null) { $DataError += 'no Current.Database,' };
    if ($DataError -ne '') { Throw "$DataError I need a devServer/Database from which to produce a source directory" }
    # by splatting, we can document each parameter
    write-verbose "creating source control directory of database $($data.current.Database)  on server $($data.current.DevServerInstance)"
    $AllArgs = @("/server1:$($data.current.DevServerInstance)", # The source server
        "/database1:$($data.current.Database)", #The name of the source database on the source server
        "/scripts2:$($data.source.DatabasePath)\Source", #the destination scripts directory
        '/q', '/synch', #quiet, do a synch
        "/report:$($data.source.ReportPath)\ObjectSourceReport.html", #where the report goes
        "/reportType:Simple", "/rad", "/force") # do a simple report
    SQLCompare $AllArgs > "$($data.source.reportPath)\InitialScriptReport.txt" #save the output
    if ($?) { 'updated successfully' }
    else
    {
        if ($LASTEXITCODE -eq 63) { 'Database and scripts were identical' }
        else { "we had an error! (code $LASTEXITCODE)" }
    }
}


#now have we got the data insert statements? If not get them from the current build
# (in this case, we're assuming that you've obfuscated any real data using SDG).
#only do this once if there is no data sync file
if (-not (Test-Path -PathType leaf $data.Source.DataSyncFile))
{
    if (-not (Test-Path -PathType Container "$($data.source.DatabasePath)/Data"))
    {
        # we create the script directory (normally you get static data from source control
        New-Item -ItemType Directory -Force -Path "$($data.source.DatabasePath)/Data";
    } #now we  dump all the test data to disk as insert statements
    
    If (Test-Path $data.Source.DataSyncFile)
    {
        Remove-Item $data.Source.DataSyncFile
    }
    <# if you have no data directory, then we will take the data from the current development
    database. We make sure that you've sprecified this. #>
    $DataError = ''
    if ($data.Current.DevServerInstance -eq $null) { $DataError += 'no Current.DevServerInstance,' };
    if ($data.Current.Database -eq $null) { $DataError += 'no Current.Database,' };
    if ($DataError -ne '') { Throw "$DataError I need a devServer/Database from which to get sample data" }
    Write-verbose "creating the data insert statements  from $($data.current.DevServerInstance):$($data.current.Database) "
    $AllArgs = @("/server1:$($data.current.DevServerInstance)",
        "/database1:$($data.current.Database)", #The name of the source database on the source server
        "/scripts2:$($data.source.DatabasePath)\Source", #the destination scripts directory
        '/o:Default', "/ScriptFile:$($data.Source.DataSyncFile)", "/Include:Identical", "/sync", "/v")
    SQLDataCompare $AllArgs > "$($data.source.reportPath)\DataInsertReport.txt" #save the output
    if ($?) { Write-Verbose "Data Script '$($data.Source.DataSyncFile)' generated successfully" }
    else { Write-Error "we had an error with SQL Data Compare! (code $LASTEXITCODE)" }
}
# Now we create a single build script containing all the object-level scripts in the 
#right order with rollback on error 
# for a database of any size we will want to create a single script that we can inspect
# if you are feeling lucky, you can just build a database from it!
write-verbose "creating build script for $($data.build.NewBuildServerInstance)"
$AllArgs = @("/scripts1:$($data.source.DatabasePath)/Source", "/server2:$($data.build.NewBuildServerInstance)",
    '/quiet', '/options:ThrowOnFileParseFailed,IgnoreCollations,IgnoreSchemaObjectAuthorization', '/exclude:user',
    '/database2:model', "/scriptfile:$($data.source.DatabasePath)\$($data.current.Database).sql")
if (Test-Path "$($data.source.DatabasePath)\$($data.current.Database).sql")
{ Remove-item "$($data.source.DatabasePath)\$($data.current.Database).sql" }
SQLCompare $AllArgs > "$($data.source.reportPath)\BuildScriptReport.txt" #save the output
if ($?) { write-verbose "Script '$($($data.source.DatabasePath))\$($data.current.Database).sql' generated successfully" }
else { "we had an error! (code $LASTEXITCODE)" }

# Next, we will execute the build script, and stock the new database with data.
# first, we check that the report directory is already created.
if (-not (Test-Path -PathType Container $data.source.ReportPath))
{
    # we create the script directory (normally you get these from source control
    New-Item -ItemType Directory -Force -Path $data.source.ReportPath;
}

#now we create the database on the target server
$server = New-Object -TypeName Microsoft.SqlServer.Management.Smo.server $data.build.NewBuildServerInstance
$ExistingDatabase = $server.Databases[$data.build.NewDatabase]
<# Ah, you have an existing build database. Before we destroy it, we need to save all the alterations
in all your existing clones. We need to check against the existing build server. #>
if ($ExistingDatabase -ne $null)
{
    # this means that we have a previous version. We can check to see if we have existing clones.
    #If so, we can save any changes, just in case...
    $data.clones | foreach {
        $clone = $null; $Thedatabase = $_.Database; $sqlServerInstance = (Get-SqlCloneSqlServerInstance | Where server -eq $_.NetName);
        $comparison = "$TheDatabase($($_.NetName))$(get-date -format 'yymmddhm')"
        if ($sqlServerInstance -eq $null) { Throw "Unable to find the location of $_.NetName" }
        $clone = Get-SqlClone | where { $_.name -eq $TheDatabase -and ($_.Locationid -eq $sqlServerInstance.Id) }
        if ($clone -ne $null)
        {
            if (-not (Test-Path -PathType Container $data.source.ChangesPath))
            {
                # we create the changes script directory 
                New-Item -ItemType Directory -Force -Path $data.source.ChangesPath;
            }
            write-verbose "checking whether anything has changed on clone $($sqlServerInstance.ServerAddress):$TheDatabase against $($data.current.DevServerInstance):$($data.current.Database)"
            
            $AllArgs = @("/server1:$($data.current.DevServerInstance)", # The source server
                "/database1:$($data.current.Database)", #The name of the source database on the source server
                "/server2:$($sqlServerInstance.ServerAddress)", #the clone
                "/database2:$TheDatabase", #The name of the database on the clone server
                "/scriptfile:$($data.source.ChangesPath)\$comparison.sql"
                
                #, #quiet, do a synch
                #"/report:$($data.source.ChangesPath)\$($TheDatabase)Report$(get-date -format 'yymmddhm').html", #where the report goes
                #"/reportType:Simple", "/rad", "/force"# do a simple report
            )
            SQLCompare $AllArgs  > "$($data.source.ChangesPath)\$comparisonChanges.txt" #save the output
            if ($?) { 'updated successfully' }
            else
            {
                if ($LASTEXITCODE -eq 63) { 'Database and scripts were identical' }
                else { "we had an error! (code $LASTEXITCODE)" }
            }
        }
    }
    if (($server.EnumProcesses() | where database -eq $data.build.NewDatabase) -eq $null)
    { $ExistingDatabase.Drop() }
    else
    { Throw "Could not drop $($data.build.NewDatabase) on $($server.Name) because it still has users." }
}
$db = New-Object Microsoft.SqlServer.Management.Smo.Database
$db.Name = $data.build.NewDatabase
$db.Parent = $server
$db.Create()
# Now the white-knuckle bit: we build the database first .... 
write-verbose "creating the build database $($data.build.NewDatabase) on $($data.build.NewBuildServerInstance)"
<# we can add pre-build and post-build scripts at this point where they are really necessary #>
try
{
    Invoke-Sqlcmd -serverinstance $data.build.NewBuildServerInstance -Database $data.build.NewDatabase `
                  -InputFile "$($data.source.DatabasePath)\$($data.current.Database).sql" | #execute the build script
    Out-File -filePath "$($data.source.ReportPath)\$($data.build.NewDatabase)CodeBuild.rpt"
    if (($data.tools.sqlDataGenerator -ne $null) -and($data.Source.SQLDataGeneratorFile -ne $null))
    { #they have specified using SQL Data Generator 
    write-verbose "Using SQL Data Generator project file $($data.Source.SQLDataGeneratorFile) on database $($data.build.NewDatabase) on server $($data.build.NewBuildServerInstance)"

    sqldatagenerator /project:$data.Source.SQLDataGeneratorFile /server:$data.build.NewBuildServerInstance `
                     /database:$data.build.NewDatabase | Out-File -filePath "$($data.source.ReportPath)\$($data.build.NewDatabase)SDG.rpt"
    if ($?) { Write-verbose 'inserted fake data successfully' }
    else
    {
        
        Write-error "we had an error with SQL Data Generator! (code $LASTEXITCODE)" 
    }


    }
    elseif ($data.Source.DataSyncFile -ne $null) #they want to fill with insertion scripts.
    {
        # ...and now we stock the database with data.
       write-verbose "Executing insert statements from $($data.Source.DataSyncFile) on database $($data.build.NewDatabase) on server $($data.build.NewBuildServerInstance)"
       Invoke-Sqlcmd -serverinstance $data.build.NewBuildServerInstance -Database $data.build.NewDatabase `
                      -InputFile $data.Source.DataSyncFile | #and insert the data
        Out-File -filePath "$($data.source.ReportPath)\$($data.build.NewDatabase)DataBuild.rpt"
    }
    else { throw 'No way of stocking the data was specified' }
}
catch
{
    Throw @"
    Could not build $($data.build.NewDatabase) on $($data.build.NewBuildServerInstance). 
     $($error[0].ToString() + $error[0].InvocationInfo.PositionMessage)
"@
}

#now we document the source of the database.
if ($data.tools.sqlDoc -ne $null)
    { #they have specified using SQL doc
    write-verbose "Using SQL Doc on database $($data.build.NewDatabase) on server $($data.build.NewBuildServerInstance)"
    sqldoc /server:$data.build.NewBuildServerInstance  /database:$data.build.NewDatabase | 
        Out-File -filePath "$($data.source.ReportPath)\$($data.build.NewDatabase)SDG.rpt"
    if ($?) { Write-verbose 'Documented the source successfully' }
    else
    {
        
        Write-error "we had an error with SQLDoc! (code $LASTEXITCODE)" 
    }
}

#check the build
write-verbose "checking the build database $($data.build.NewDatabase) on $($data.build.NewBuildServerInstance)"

$AllArgs = @("/scripts1:$($data.source.DatabasePath)\Source", #The source server
    "/server2:$($data.build.NewBuildServerInstance)",
    "/database2:$($data.build.NewDatabase)", #the destination scripts directory
    '/q', '/synch', "/exclude:user", #quiet, do a synch
    "/report:$($data.source.reportPath)\BuildCheckReport.html", #where the report goes
    "/options:IgnoreWhiteSpace,ignoreuserproperties,ignorefillfactor" #ignore semicolons and whitespace
    "/reportType:Simple", "/rad", "/force") # do a simple report
SQLCompare $AllArgs > "$($data.source.reportPath)\BuildCheck.txt" #save the output
if ($?) { 'checked new build successfully' }
else { write-warning  "see file:///$($data.source.DatabasePath)\CheckReport.html for differences to build and source" }


#create an image of what we built

$AllArgs = @{
    'Name' = "$($data.Image.Name.ToString())"; #
    'SqlServerInstance' = (Get-SqlCloneSqlServerInstance | Where server -eq $db.parent.NetName);
    'DatabaseName' = "$($db.name)";
    'Destination' = (Get-SqlCloneImageLocation | Where Id -eq $data.Image.ID)
}
$ImageOperation = New-SqlCloneImage @AllArgs

Wait-SqlCloneOperation -Operation $ImageOperation

write-verbose "Cloning $($data.build.NewDatabase) on $($data.build.NewBuildServerInstance)"

#check the image

if (-not (Get-SqlCloneImage | where name -eq $data.image.Name))
{
    throw "couldn't find the clone $($data.image.Name)"
}
#clone it as whatever database is specified to whatever sql clone servers are specified

$data.clones | foreach {
    $clone = $null; $Thedatabase = $_.Database;
    #get the correct instance that has an agent installed on it.
    $sqlServerInstance = (Get-SqlCloneSqlServerInstance | Where server -eq $_.NetName);
    if ($sqlServerInstance -eq $null) { Throw "Unable to find the location of $_.NetName" }
    write-verbose "Cloning $($_.Database) on $($_.NetName)"
    $clone = Get-SqlClone -ErrorAction silentlyContinue -Name "$($TheDatabase)" -Location $sqlServerInstance
    #$clone = Get-SqlClone | where { $_.name -eq $TheDatabase -and ($_.locationID -eq $sqlServerInstance.Id) }
    #$clone = Get-SqlClone -name $_.Database -Location (Get-SqlCloneSqlServerInstance | Where server -eq $_.NetName)
    if (($clone) -ne $null)
    {
        write-warning  "Removing Clone $Thedatabase that already existed on $($_.NetName)"
        Remove-SqlClone $clone | Wait-SqlCloneOperation
    }
    Get-SqlCloneImage -Name $data.Image.Name |
    New-SqlClone -Name "$($_.Database)" -Location $SqlServerInstance | Wait-SqlCloneOperation
}
