$Database = 'MyDatabase'
$Data = @{
    "Source" = @{
        #specify the various directories you want in order to store files and logs
        #The location of the executable SQL data insertion script.
        'DataSyncFile' = "$($env:HOMEDRIVE)$($env:HOMEPATH)\Documents\GitHub\$Database\Data\DataSyncFile.SQL";
        #The location of the Data Generator file for any columns you need to obfuscate
        'SQLDataGeneratorFile' = "$($env:HOMEDRIVE)$($env:HOMEPATH)\Documents\GitHub\$Database\DataGenerator.sqlgen";
        #where you want to put the reports for this particular database.
        'ReportPath' = "$($env:HOMEDRIVE)$($env:HOMEPATH)\Documents\GitHub\$Database\Reports";
        #where you have (or want to put) the source of the current database.
        'DatabasePath' = "$($env:HOMEDRIVE)$($env:HOMEPATH)\Documents\GitHub\$Database";
    }
    "Current" = @{
        # we define the location of our development database
        'DevServerInstance' = 'MyServer';
        'Database' = $database;
    }
    "Build" = @{
        #now we'll specify where we want the new build. We will clone from this.
        'NewBuildServerInstance' = 'MyBuildServer'; #The SQL Server instance
        'NewDatabase' = "New$Database"; #The name of the database
    }
    "Image" = @{
        #create an image of what we built
        'Name' = "$($db.name)-$(get-date -format 'yyyyMMddHHmm')";
        'ServerURL' = 'MyCloneServer';
        'ID' = 1
    }
    "Clones" = @(
        @{ "NetName" = "DevServer1"; "Database" = "$($database)1" },
        @{ "NetName" = "DevServer1"; "Database" = "$($database)2" },
        @{ "NetName" = "DevServer1"; "Database" = "$($database)3" },
        @{ "NetName" = "DevServer2"; "Database" = "$($database)1" },
        @{ "NetName" = "DevServer2"; "Database" = "$($database)2" },
        @{ "NetName" = "DevServer2"; "Database" = "$($database)3" }
    )
}