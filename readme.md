# What the script does #
This PowerShell script is designed to show how you would use Redgate’s Toolbelt and SQL Clone to take an object-level source (It will create one if you haven’t yet done so) and create from it as many clones of the built database as you wish. It is designed for a daily build and provisioning. It assumes that all changes to individual clones have been checked in, but saves the previous changes anyway before over-writing an old clone. 
If you wish, it will stock the database with generated data rather than take data from a SQL File. To do this, you have to specify the location of your SQL Generator application and your SQL data Generator project file. Also, it will generate the contents of a documentation website if you specify the location of your SQL Doc application.

# At a glance #
![](https://github.com/Phil-Factor/DeployViaToolBeltAndClone/blob/master/BuildAndProvisioning.png?raw=true)
# The Build Data File #

There are two files, a Build Data file and a Process script. The Process script executes the data file, which is a PowerShell script. The Data file has all the data for your particular deployment: nothing is held in the process script. The data file includes a list of all the clones to create or update. If you want the process script to set up the source directory from an existing development server, then it will do this for you, and create the necessary subdirectories.
Before you use it, you will need to install the Toolbelt and SQL Clone. You will also need to modify the instructions to suit your build and development environment, and you will need to provide the paths to the command-line versions of the Toolbelt  tools that you use.
It performs the following actions
- Takes the instructions for the build, and parameters from a build Data file. (a sample is in the release)
- Checks to see if the source control directory exists. If not, it creates an object-level source from the development server that you specify.
- Checks to see if you have a script to insert the static data and any other data needed for testing. If not, it creates it from the current development server. (if you want to automatically generate the data, it won't bother)
- Creates a single build script from the object –level script
- If there is an existing build server, representing the previous day’s build, it checks to see if there are any existing clones, and if so compares each clone with the build server. If any changes have been made to any clone it saves these changes
- Drops any existing build database on the build server (it checks that nobody is using it first - active SPid), and creates a new empty one.
- Executes the build script
- Executes the data script
- Then it checks the new build with the source code directory to make sure that it was successful.
- it documents or refreshes the documentation of the database in HTML
- it applies any data specified by a SQL Data Generator project
- It creates an image of the new build database.
- It creates as many clones as you specify from the image. 

# What you need in order to get it to run #

You will need a couple of SQL Server instances, a copy of SQL Compare, and a copy of SQL Clone. You need to install SQL Clone and set up client servers on which you will create the clones.

# What you need to do in order to get it to run #

You will need to change the Build Data file to define your Database, server environment, network paths, and list of clones in a Powershell PSON Data structure. 
This is in several sections and subsections
## Tools ##
A list of the locations of the various tools (all but SQL Compare can be given a value of null or deleted if you don't want to use them)
 - The path to where we have SQ LCompare installed
 - The path to where we have SQL Data Compare installed (leave $null if not wanted) 
 - The path to where we have SQL Data generator installed  (leave $null if not wanted) 
 - The path to where we have SQL Doc installed  (leave $null if not wanted) 

## Source ##
The various directories you want in order to store files and logs
- The location of the executable SQL data insertion script.
- The location of the Data Generator file for any columns you need to obfuscate (leave $null if not wanted) 
- where you want to put the reports for this particular database.
- where changes between clone and build are stored
## Current ##
The details of the current development shared server if you don't yet have a VCS-based source code directory (leave as $null or delete if you don't need or want to use this. It is only used if the system can't find your source code directory 
- the Server Instance of the development SQL Server to get the source from (optional)
- The name of the database 
## Build ##
The location of the database that you want to build in order to clone
- the Server Instance of the SQL Server you want to use for the build
- The name of the database you want to call it
- The SQL Data Generator project you want to use for the data
## Image ##
The details of the image that you want to create in order to 
- The name of the image we want to create
- The clone server URL 
- The id of the Sql Clone Image Location (usually 1)
## Clones ##
  A list of all the cloned databases, referenced by the netname of the clone servers and the name of the database 
# For further information #
[Using SQL Clone and the Toolbelt for DLM build, integration and provisioning](https://github.com/Phil-Factor/DeployViaToolBeltAndClone/blob/master/Documentation.adoc "Using SQL Clone and the Toolbelt for DLM build, integration and provisioning")




 