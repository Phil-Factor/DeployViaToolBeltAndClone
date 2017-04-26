This PowerShell script is designed to show how you would use Redgate’s Toolbelt and SQL Clone to take an object-level source (It will create one if you haven’t yet done so) and create from it as many clones of the built database as you wish. It is designed for a daily build and provisioning. It assumes that all changes to individual clones have been checked in, but saves the previous changes anyway before over-writing an old clone. 
If you wish, it will stock the database with generated data rather than take data from a SQL File. To do this, you have to specify the location of your SQL Generator application and your SQL data Generator project file. Also, it will generate the contents of a documentation website if you specify the location of your SQL Doc application.
There are two files, a Data file and a Process script. The Process script executes the data file, which is a powershell script. The Data file has all the data for your particular deployment: nothing is held in the process script. The data file includes a list of all the clones to create or update. If you want the process script to set up the source directory from an existing development server, then it will do this for you, and create the nessesary subdirectories.
Before you use it, you will need to install the Toolbelt and SQL Clone. You will also need to modify the instructions to suit your build and development environment, and you will need to provide the paths to the command-line versions of the Toolbelt  tools that you use.
It performs the following actions
- Takes the instructions for the build, and parameters from a build file. (a sample is in the release)
- Checks to see if the source control directory exists. If not, it creates an object-level source from the development server that you specify.
- Checks to see if you have a script to insert the static data. If not, it creates it from the current development server
- Creates a single build script from the object –level script
- If there is an existing build server, representing the previous day’s build, it checks to see if there are any existing clones, and if so compares each clone with the build server. If any changes have been made to any clone it saves these changes
- Drops any existing build database on the build server, and creates a new empty one.
- Executes the build script
- Executes the data script
- Then it checks the new build with the source code directory to make sure that it was successful.
- (it documents or refreshes the documentation of the database in Markdown for a git repository)
- (it applies any data specified by a SQL Data Generator project)
- It creates an image of the new build database.
- It creates as many clones as you specify from the image. 
 
(Bracketed features are published separately on the Redgate blog and will be inserted in due course)
