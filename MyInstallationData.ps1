$Database = 'Customers'
@{
    'Tools' = @{
        #where we have SQ LCompare installed
        'SQLCompare' = 'C:\Program Files (x86)\Red Gate\SQL Compare 10\SQLCompare.exe'
        #Whare we have SQL Data Compare installed (leave $null if not wanted) 
        'SQLDataCompare' = 'C:\Program Files (x86)\Red Gate\SQL Data Compare 10\SQLDataCompare.exe'
        #Whare we have SQL Data generator installed  (leave $null if not wanted) 
        'SQLDataGenerator' = 'C:\Program Files (x86)\Red Gate\SQL Data Generator 3\SQLDataGenerator.exe'
        #Whare we have SQL Doc installed  (leave $null if not wanted) 
        'SQLDoc' = 'C:\Program Files (x86)\Red Gate\SQL Doc 3\SQLdoc.exe'
    }
    "Source" = @{
        #specify the various directories you want in order to store files and logs
        #The location of the executable SQL data insertion script.
        'DataSyncFile' = "$($env:HOMEDRIVE)$($env:HOMEPATH)\Documents\GitHub\$Database\Data\DataSyncFile.SQL";
        #The location of the Data Generator file for any columns you need to obfuscate (leave $null if not wanted) 
        'SQLDataGeneratorFile' = "$($env:HOMEDRIVE)$($env:HOMEPATH)\Documents\GitHub\$Database\DataGenerator.sqlgen";
        #where you want to put the reports for this particular database.
        'ReportPath' = "$($env:HOMEDRIVE)$($env:HOMEPATH)\Documents\GitHub\$Database\Reports";
        #where changes between clone and build are stored
        'ChangesPath' = "$($env:HOMEDRIVE)$($env:HOMEPATH)\Documents\GitHub\$Database\Changes";
        #where you have (or want to put) the source of the current database.
        'DatabasePath' = "$($env:HOMEDRIVE)$($env:HOMEPATH)\Documents\GitHub\$Database";
    }
    "Current" = @{
        # we define the location of our development database
        'DevServerInstance' = 'MySevServer';
        'Database' = $database;
    }
    "Build" = @{
        #now we'll specify where we want the new build. We will clone from this.
        'NewBuildServerInstance' = 'MyBuildServer'; #The SQL Server instance
        'NewDatabase' = "New$Database"; #The name of the database
        'DataGeneratorProject' = $null
    }
    "Image" = @{
        #create an image of what we built
        'Name' = "$($Database)-$(get-date -format 'yyyyMMddHHmm')";
        'ServerURL' = 'http://MyCloneServer';
        'ID' = 1
    }
    "Clones" = @(
        @{ "NetName" = "MyServerName"; "Database" = "$($database)1" },
        @{ "NetName" = "MyServerName"; "Database" = "$($database)2" },
        @{ "NetName" = "MyServerName"; "Database" = "$($database)3" },
        @{ "NetName" = "MyServerName"; "Database" = "$($database)1" },
        @{ "NetName" = "MyServerName"; "Database" = "$($database)2" },
        @{ "NetName" = "MyServerName"; "Database" = "$($database)3" }
    )
}