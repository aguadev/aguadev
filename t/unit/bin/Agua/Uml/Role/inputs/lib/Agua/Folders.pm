use MooseX::Declare;

=head2

		PACKAGE		Folders
		
		PURPOSE
		
			THE Folders OBJECT PERFORMS THE FOLLOWING TASKS:
			
				1. RETURNS THE FILE AND DIRECTORY LISTINGS OF A GIVEN PATH AS A
                
                    dojox.data.FileStore JSON OBJECT (TO BE RENDERED USING
                    
                    FilePicker INSIDE dojox.dijit.Dialog)

                2. MAINTAINS THE PERMISSIONS ON THE FILES AND FOLDERS TO
				
					PERMIT ACCESS BY THE USER AND THE APACHE USER
                    
                3. PROVIDES THE FOLLOWING FUNCTIONALITY:

                    - PROJECT FOLDERS
                    
                        - ADD
                        - RENAME
                        - DELETE 

                    - WORKFLOWS
                        
                        - ADD
                        - RENAME
                        - DELETE
                        - MOVE TO PROJECT
                        - COPY TO PROJECT

                    - FILES
                    
                        - ADD
                        - RENAME
                        - DELETE
                        - MOVE TO WORKFLOW OR LOWER DIRECTORY
                        - COPY TO WORKFLOW OR LOWER DIRECTORY


				NB: Agua::Folders DOES NOT DO THE FOLLOWING:

					- KEEP TRACK OF FILESYSTEM SIZES IN EACH PROJECT

					- LIMIT FILE ADDITIONS BEYOND A PRESET USER QUOTA
					 

	NOTES
	
		EXAMPLE OF dojox.data.FileStore JSON OBJECT
    
{
    "total":4,
    "items":
    [
        {
            "name":"dijit",
            "parentDir":".",
            "path":".\/dijit",
            "directory":true,
            "size":0,
            "modified" :1227075503,
            "children":
            [
                "ColorPalette.js",
                "Declaration.js",
                "Dialog.js",
                "dijit-all.js",
                "dijit.js","Editor.js","form","InlineEditBox.js","layout","LICENSE","Menu.081119-added-currentTarget.js","Menu.js","nls","ProgressBar.js","resources","robot.js","robotx.js","templates","tests","themes","TitlePane.js","Toolbar.js","Tooltip.js","Tree.js","_base","_base.js","_Calendar.js","_Container.js","_editor","_Templated.js","_TimePicker.js","_tree","_Widget.js"
            ]
        },
        {
            "name":"dojo",
            "parentDir":".",
            "path":".\/dojo",
            "directory":true,
            "size":0,
            "modified":1226987387,
            "children":
            [
                "AdapterRegistry.js","back.js","behavior.js","cldr","colors.js","cookie.js","currency.js","data","date","date.js","DeferredList.js","dnd","dojo.js","dojo.js.uncompressed.js","fx","fx.js","gears.js","html.js","i18n.js","io","jaxer.js","LICENSE","nls","NodeList-fx.js","NodeList-html.js","number.js","OpenAjax.js","parser.js","regexp.js","resources","robot.js","robotx.js","rpc","string.js","tests","tests.js","_base","_base.js","_firebug"
            ]
        },
        {
            "name":"dojox",
            "parentDir":".",
            "path":".\/dojox",
            "directory":true,
            "size":0,
            "modified":1228105583,
            "children":
            [
                "analytics","analytics.js","av","charting","collections","collections.js","color","color.js","cometd","cometd.js","data","date","dtl","dtl.js","editor","embed","encoding","flash","flash.js","form","fx","fx.js","gfx","gfx.js","gfx3d","gfx3d.js","grid","help","highlight","highlight.js","html","html.js","image","io","json","jsonPath","jsonPath.js","lang","layout","LICENSE","math","math.js","off","off.js","presentation","presentation.js","resources","robot","rpc","secure","sketch","sketch.js","sql","sql.js","storage","storage.js","string","testing","timing","timing.js","uuid","uuid.js","validate","validate.js","widget","wire","wire.js","xml","xmpp"
            ]
        }
        ,
        {
            "name":"util",
            "parentDir":".",
            "path":".\/util",
            "directory":true,
            "size":0,
            "modified":1226987022,
            "children":
            [
                "buildscripts", "docscripts","doh","jsdoc","LICENSE","maven","resources","shrinksafe"
            ]
        }
    ]
}

=cut


#### USE LIB FOR INHERITANCE
use FindBin qw($Bin);
use FindBin::Real;
use lib FindBin::Real::Bin() . "/lib";

use File::Remove;

use strict;
use warnings;

class Agua::Folders with (Agua::Cluster::Checker,
	Agua::Common::Base,
	Agua::Common::Database,
	Agua::Common::File,
	Agua::Common::Logger,
	Agua::Common::Project,
	Agua::Common::Privileges,
	Agua::Common::Transport,
	Agua::Common::Util,
	Agua::Common::Workflow) {

#### EXTERNAL MODULES
use File::Basename;
use File::Copy;    
use File::Path;		
use File::stat;     
use Data::Dumper;   
use Carp;           
use JSON -support_by_pp;

#### INTERNAL MODULES
use Agua::DBaseFactory;

# Booleans
has 'SHOWLOG'	=>  ( isa => 'Int', is => 'rw', default => 0 );  
has 'PRINTLOG'	=>  ( isa => 'Int', is => 'rw', default => 0 );
has 'validated'	=> ( isa => 'Int', is => 'rw', default => 0 );

# Ints
has 'bytes'		=> ( isa => 'Int', is => 'rw', default => 200 );

# Strings
has 'fileroot'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'username'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'project'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'workflow'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );

# Objects
has 'json'		=> ( isa => 'HashRef|Undef', is => 'rw', default => undef );
has 'jsonparser'=> ( isa => 'JSON', is => 'rw');
has 'db'	=> ( isa => 'Agua::DBase::MySQL', is => 'rw', required => 0 );
has 'conf' 		=> (
	is =>	'rw',
	'isa' => 'Conf::Agua',
	default	=>	sub { Conf::Agua->new(	backup	=>	1, separator => "\t"	);	}
);

####////}}

method BUILD ($hash) {
	#$self->initialise();
}

method initialise ($json) {
	#### IF JSON IS DEFINED, ADD VALUES TO SLOTS
	$self->json($json);
	if ( $self->json() )
	{
		foreach my $key ( keys %{$self->{json}} ) {
			$self->logDebug("setting self->$key", $self->{json}->{$key}) if $self->can($key);
			$json->{$key} = $self->unTaint($json->{$key});
			$self->$key($self->{json}->{$key}) if $self->can($key);
		}
	}

	#### SET DATABASE HANDLE
	$self->setDbh();		

    #### VALIDATE
    $self->logError("User session not validated") and exit unless $self->validate();
}

method newFolder {
	$self->logDebug("");

    my $folderpath = $self->json()->{folderpath};
    $self->logDebug("folderpath", $folderpath);

    my $location = $self->json()->{location};
    $self->logDebug("location", $location);

    #### GET FULL PATH TO USER'S HOME DIRECTORY
    my $fileroot = $self->getFileroot() || '';

	#### SET FULL PATH TO FILE TO BE COPIED
	if ( $location ) {
		$folderpath = "$location/$folderpath";
	}
	else {
		$folderpath = "$fileroot/$folderpath";
	}
		
    #### CONVERT folderpath AND destinationPath ON WINDOWS
    $self->logDebug("folderpath", $folderpath);    

    #### CHECK FILE IS PRESENT
    #### IF NOT, PRINT ERROR AND EXIT
	$self->logError("A folder already exists in path: $folderpath") and exit if -d $folderpath;
	$self->logError("A file already exists in path: $folderpath") and exit if -f $folderpath;
    
	#### CREATE NEW FOLDER
	File::Path::mkpath($folderpath);
	$self->logError("Could not create folder in path: $folderpath") and exit if not -d $folderpath;

    #### EXIT ON COMPLETION
	$self->logStatus("Created folder in path: $folderpath");    
}

method copyFolder {
	return $self->copyFile();
}

method deleteFolder {
	return $self->removeFile();
}

method moveFolder {
	return $self->renameFile();
}

method renameFolder {
	return $self->renameFile();	
}

method renameWorkflow {
    $self->logDebug("");
    
    #### VALIDATE
    my $validated = $self->validate();
    $self->logDebug("validated", $validated);
	$self->logError("User session not validated") and exit if not $validated;

    #### GET USER NAME, SESSION ID AND PATH FROM CGI OBJECT
    my $username = $self->json()->{username};
    my $oldpath = $self->json()->{oldPath};
    my $newpath = $self->json()->{newPath};
	my ($newworkflow) = $newpath =~ /([^\/]+)$/;
	my ($oldworkflow) = $oldpath =~ /([^\/]+)$/;
    my ($project) = $oldpath =~ /^([^\/]+)/;

	my $success = $self->_renameWorkflow($username, $project, $oldworkflow, $newworkflow);
	$self->logError("Could not update project workflow name from $oldworkflow to $newworkflow") and exit if not $success;
	$self->logStatus(". Successfully updated project workflow name from $oldworkflow to $newworkflow");
}

method _renameWorkflow ($username, $project, $oldworkflow, $newworkflow) {
	$self->logDebug("username", $username);
	$self->logDebug("project", $project);
	$self->logDebug("oldworkflow", $oldworkflow);
	$self->logDebug("newworkflow", $newworkflow);
	
	#### GET WORKFLOW OBJECT
	my $query = qq{SELECT * FROM workflow
WHERE username ='$username'
AND name='$oldworkflow'
AND project='$project'};
	my $workflowobject = $self->db()->queryhash($query);
	$self->logDebug("workflowobject", $workflowobject);

	#### COPY TO NEW NAME
	$self->_copyWorkflow($workflowobject, $username, $project, $newworkflow, undef);

	#### DELETE ORIGINAL
	$workflowobject->{name} = $oldworkflow;
	$self->logDebug("BEFORE _removeWorkflow, workflowobject", $workflowobject);
	$self->_removeWorkflow($workflowobject);

	#### MOVE DIRECTORY TO NEW NAME
	my $aguadir = $self->conf()->getKey("agua", 'AGUADIR');
	my $userdir = $self->conf()->getKey("agua", 'USERDIR');
	my $sourcedir = "$userdir/$username/$aguadir/$project/$oldworkflow";
	my $targetdir = "$userdir/$username/$aguadir/$project/$newworkflow";
	$self->logDebug("sourcedir", $sourcedir);
	$self->logDebug("targetdir", $targetdir);
	my $move = "mv $sourcedir $targetdir";
	$self->logDebug("move", $move);
	`$move`;
}

method renameFile {
    $self->logDebug("");
    
    #### VALIDATE
    my $validated = $self->validate();
    $self->logDebug("Validated", $validated);
    if ( not $validated )
    {
        $self->logError("User session not validated");
        return;
    }

    #### GET USER NAME, SESSION ID AND PATH FROM CGI OBJECT
    my $username = $self->json()->{username};
    my $oldpath = $self->json()->{oldpath};
    my $newpath = $self->json()->{newpath};

	#### GET FILEROOT 
	my $fileroot = $self->getFileroot($username);

	$oldpath = "$fileroot/$oldpath";
	$newpath = "$fileroot/$newpath";
	$self->logDebug("oldpath", $oldpath);
	$self->logDebug("newpath", $newpath);
	$self->logError("Cannot find file: <br>$oldpath") and exit if not -f $oldpath;


    #### BEGIN RENAME OLD TO NEW
	use File::Copy;
	my $success = File::Copy::move($oldpath,$newpath);

	$self->logError("Cannot rename file <br>$oldpath <br> as <br>$newpath") and exit if not $success;
	$self->logStatus("Renamed file <br>$oldpath <br> as <br>$newpath");
}


method getFolders {
    $self->logDebug("");

    #### GET USER NAME, SESSION ID AND PATH FROM CGI OBJECT
    my $username = $self->json()->{username};

	#### POPULATE THIS FOLDERS HASH	
	my $folders = {};
	
	#### USER'S PROJECTS
	my $query = qq{SELECT DISTINCT project, description FROM workflow WHERE username='$username'};
	my $my_projects = $self->db()->queryhasharray($query);

	#### IF PROJECTS NOT DEFINED, CREATE DEFAULT PROJECT 1, WORKFLOW 1
	if ( not defined $my_projects or not @$my_projects )
	{
		my $project = "Project1";
		my $workflow = "Workflow1";

		$my_projects = [
			{
				'project' => $project,
				'description' => ''
			}
		];

		my $fileroot = $self->getFileroot($username);
		$self->logDebug("fileroot", $fileroot);
		
		my $projectdir = "$fileroot/$project";
		my $workflowdir = "$fileroot/$project/$workflow";
		
		$self->logDebug("Creating project dir: $projectdir... ");
		File::Path::mkpath($projectdir) or die "Can't create project dir: $projectdir\n" if not -d $projectdir;

		$self->logDebug("Creating workflow dir: $workflowdir... ");
		File::Path::mkpath($workflowdir) or die "Can't create workflow dir: $workflowdir\n" if not -d $workflowdir;

		#### ADD TO groupmember TABLE
		my $query = qq{INSERT INTO groupmember
(owner, groupname, groupdesc, name, type, description, location)
VALUES ('$username', 'First Group', '$project', 'project', '', '$projectdir')};
		$self->logDebug("$query");
	}
	
    ####
    #
    #   GENERATE LIST OF USER-ACCESSIBLE SHARED PROJECTS
	#
    #    1. GET OWNER AND GROUP NAME OF ANY GROUPS THE USER BELONGS TO
    #
    #    2. GET NAMES OF PROJECTS IN THE GROUPS THE USER BELONGS TO
    #    
    #    3. GET THE PERMISSIONS AND LOCATIONS OF SHARED PROJECTS
    #
    #    .schema access
    #    CREATE TABLE access
    #    (
    #            project                 VARCHAR(20),
    #            owner                   VARCHAR(20),
    #            ownerrights             INT(1),
    #            grouprights             INT(1),
    #            worldrights             INT(1),
    #            location                TEXT,
    #    
    #            PRIMARY KEY (project, owner, ownerrights, grouprights, worldrights, loca
    #    tion)
    #    );
    #
	
	my $shared_projects = $self->sharedProjects($username);

    ####
    #
    #   GENERATE LIST OF WORLD READABLE PROJECTS
	#
	#### 

	my $world_projects = $self->worldProjects($username, $shared_projects);

	$self->logDebug("world_projects", $world_projects);

	my $sources = $self->sources($username);

	#### DEFINE IF NOT DEFINED
	$my_projects = [] if not defined $my_projects;
	$shared_projects = [] if not defined $shared_projects;
	$world_projects = [] if not defined $world_projects;
	$sources = [] if not defined $sources;	

	$folders->{projects} = $my_projects;
	$folders->{sharedprojects} = $shared_projects;
	$folders->{worldprojects} = $world_projects;
	$folders->{sources} = $sources;

	#### PRINT JSON
    my $jsonObject = JSON->new();
    #my $json = $jsonObject->objToJson($folders, {pretty => 1, indent => 4});
    my $json = $jsonObject->pretty->indent->encode($folders);
    print $json;
}

method removeFile {
=head2

    SUBROUTINE     removeFile
    
    PURPOSE
        
        Remove a file system with the following functions/constraints:
        
        1. Return "removing" if remove is already underway
        
        2. Return "completed" if remove is done
        
        3. Return "file system busy" if File is being copied from
        
    NOTES

        Remove constraints and progress are implemented using the first of these
        
        two methodologies: 
    
            A) Presence/absence of a flag file ".removeFile.txt"
            
                in the top directory of the file system to be removed. File
                
                is removed on completion of remove action.
        
            B) Remove progress stored in SQL table and updated by calls to
			
				the same perl executable that carried out the remove command
    
    
            http://search.cpan.org/~adamk/File-Remove-1.42/lib/File/Remove.pm   
            use File::Remove 'remove';
        
            # removes (without recursion) several files
            remove( '*.c', '*.pl' );
        
            # removes (with recursion) several directories
            remove( \1, qw{directory1 directory2} ); 
        
            # removes (with recursion) several files and directories
            remove( \1, qw{file1 file2 directory1 *~} );
        
            # trashes (with support for undeleting later) several files
            trash( '*~' );

=cut

    
    my $file = $self->json()->{file};
    my $modifier = $self->json()->{modifier};
    if ( not defined $modifier )    {   $modifier = ''; }

    #### VALIDATE
    my $validated = $self->validate();
    $self->logDebug("Validated", $validated);
    if ( not $validated )
    {
        $self->logError("User session not validated");
        return;
    }
    $self->logDebug("File", $file);
    
	#### GET USER NAME
    my $username = $self->json()->{username};

    #### GET FULL PATH TO USER'S HOME DIRECTORY
    my $fileroot = $self->getFileroot($username);

    #### SET FULL PATH TO FILE TO BE COPIED
    my $filePath = "$fileroot/$file";
    $self->logDebug("filePath", $filePath);    

    #### CHECK FILE IS PRESENT
    #### IF NOT, PRINT ERROR AND EXIT
    if ( not $modifier =~ /^status$/ )
    {
        if ( not -f $filePath and not -d $filePath )
        {
            $self->logError("File not found");
            return;
        }
    }

    #### CHECK FOR COPY FLAG FILE 
    my $copyFlagFile = "$filePath~copyFile";
    $self->logDebug("copyFlagFile", $copyFlagFile);
    if ( -f $copyFlagFile )
    {
        $self->logError("File being copied");
        return;
    }
    
    #### SET REMOVE FLAG FILE 
    my $flagFile = "$filePath~removeFile";
    $self->logDebug("flagFile", $flagFile);
    
    #### RETURN 'removing' IF FLAG FILE FOUND
    if ( -f $flagFile )
    {
        #open(FILE, $flagFile) or die "Can't open flagFile: $flagFile\n";
        
        if ( $modifier =~ /^status$/ )
        {        
            $self->logStatus("ongoing");
            return;
        }
        else
        {
            $self->logStatus("removing");
        }
        return;
    }
    else
    {
        if ( $modifier =~ /^status$/ )
        {
            $self->logStatus("completed");
            return;
        }
    }
    
    #### CREATE FLAG FILE
    open(FLAG, ">$flagFile") or die "Can't open copyFile flag file\n";
    print FLAG time();
    close(FLAG);
    
    #### PRINT COPY STATUS: INITIATED
    $self->logStatus("Initiated remove file: $filePath");
    
    #### FLUSH BUFFER TO MAKE SURE STATUS MESSAGE IS SENT
    $| = 1;
 
	use File::Remove;

    #### BEGIN REMOVING FILE
    $self->logDebug("Removing $filePath");
    if ( -f $filePath )
    {
        my $result = File::Remove::rm($filePath);
        $self->logDebug("Result", $result);
    }
    elsif ( -d $filePath )
    {
        my $result = File::Remove::rm(\1, $filePath);
        $self->logDebug("Result", $result);
    }
    
    #### REMOVE FLAG FILE
    File::Remove::rm($flagFile);    
}

method copyFile {
=head2

    SUBROUTINE     copyFile
    
    PURPOSE
    
        Copy a file system to different file system with
    
        the following functions/constraints:
        
        1. Return "copying" if copy is already underway and
        
            modifier = 'status' (i.e., its just a status check)
        
        2. Return "copying" if attempting to copy a
        
            file that has not been completely copied
        
    NOTES

        Copy constraints and progress are implemented using the first of these
        
        two methodologies: 
    
            A) Presence/absence of a flag file, e.g., "file.txt~copying"
                    
            B) Copy progress stored in SQL table and updated by the copying 
            
                process once the copy is completed
    
=cut
    $self->logDebug();

    #### GET USERNAME, FILE, DESTINATION AND MODIFIER
    my $username = $self->json()->{username};
    my $owner = $self->json()->{owner};
    my $file = $self->json()->{file};
    my $destination = $self->json()->{destination};
    my $modifier = $self->json()->{modifier};
    if ( not defined $modifier )    {   $modifier = ''; }
    my $location = $self->json()->{location};
	$self->logDebug("owner", $owner);
	$self->logDebug("location", $location);
    $self->logDebug("file", $file);

	$self->logError("destination not defined") and exit if not defined $destination;
	$self->logError("file not defined") and exit if not defined $file;
	
    #### SET FULL PATH TO FILE TO BE COPIED
    my $filePath = '';

    #### SET FULL PATH TO DESTINATION DIRECTORY
    my $destinationPath = '';

    #### CHECK THAT USER HAS RIGHTS TO READ OTHER FILE SYSTEM
    if ( defined $owner and $owner ne '' and $owner ne $username )
    {
        $self->logDebug("File starts with 'owner'", $owner);

        $file =~ /^([^\/]+)\/(.*)$/;
        my $project = $1;
        my $rest = $2;
        $self->logDebug("owner", $owner);
        $self->logDebug("project", $project);

	    my $groupname = $self->json()->{groupname};
		my $type = "project";
		$type = "source" if defined $location and $location;
		$self->logError("User $username cannot access group $groupname owned by $owner") and exit if not $self->_canCopyGroup($owner, $groupname, $username, $type);
        $self->logDebug("User $username can access group $groupname owned by $owner");

		my $privileges = $self->_getPrivileges($owner, $groupname);
		$self->logDebug("privileges", $privileges);
		$self->logError("No privileges for group $groupname owned by $owner") and exit if not defined $privileges;
		my $can_copy = $privileges->{groupcopy};
		$self->logDebug("can_copy", $can_copy);
        $self->logError("User $username does not have sufficient privileges to copy this file") and exit if not $can_copy;

		#### GET FILE ROOT
		my $fileroot;
		$fileroot = $location if defined $location and $location;
		$fileroot = $self->getFileroot($owner) if not defined $fileroot;
		
        #### SET FULL PATH TO FILE TO BE COPIED
		if ( $file =~ /^\// )
		{
			$filePath = $file;
		}
		else {
			$filePath = "$fileroot/$project";
			if ( defined $rest )
			{
				$filePath .= "/$rest";
			}
		}
    }
    else
    {
		#### GET FILE ROOT
		my $fileroot;
		$fileroot = $location if defined $location and $location;
		$fileroot = $self->getFileroot($username) if not defined $fileroot;
		
		$filePath = $file;
		$filePath = "$fileroot/$file" if $file !~ /^\//;
    }
	$self->logDebug("filePath", $filePath);
	$self->logDebug("destinationPath", $destinationPath);
	$self->logDebug("destination", $destination);
	
	my $fileroot = $self->getFileroot($username);
	if ( $destination !~ /^\// ) {
		$self->logDebug("Setting destinationPath = fileroot/destination");
		$destinationPath = "$fileroot/$destination";
	}
	else {
		$destinationPath = $destination;
		$self->logDebug("destinationPath", $destinationPath);
	}
	
    #### CHECK THAT USER HAS RIGHTS TO WRITE TO OTHER FILE SYSTEM
    if ( $destination =~ /^owner:/ ) {
        $self->logDebug("Destination starts with 'owner:'. Copying to another user's directory");
    
        $destination =~ /^owner:([^\/]+)\/([^\/]+)(.*)$/;
        my $owner = $1;
        my $project = $2;
        my $rest = $3;
        $self->logDebug("Owner", $owner);
        $self->logDebug("Project", $project);
        
        my $privilege = $self->projectPrivilege($owner, $project, $username, "groupwrite");
        if ( not defined $privilege or not $privilege)
        {
            $self->logError("User $username does not have sufficient privileges to write to this file system");
            exit;
        }
        $self->logDebug("Privilege", $privilege);
    
        #### SET FULL PATH TO FILE TO BE COPIED
        $destinationPath = "$fileroot/$project";
        if ( defined $rest )
        {
            $destinationPath .= "$rest";
        }
    }
  
    $self->logDebug("filePath", $filePath);    
    $self->logDebug("destinationPath", $destinationPath);
    #### CHECK FILE IS PRESENT
    #### IF NOT, PRINT ERROR AND EXIT
    if ( not -f $filePath and not -d $filePath )
    {
        $self->logError("File path not found: $filePath");
        return;
    }
    
    #### CHECK IF DESTINATION DIRECTORY IS PRESENT
    #### IF NOT, PRINT ERROR AND EXIT
    if ( not -d $destinationPath )
    {
        $self->logError("Destination directory not found: $destination");
        return;
    }

    #### SET FLAG FILE 
    my $flagFile = "$filePath~copyFile";
    $self->logDebug("flagFile", $flagFile);
    
    #### RETURN 'copying' IF FLAG FILE FOUND
    if ( -f $flagFile )
    {
        #open(FILE, $flagFile) or die "Can't open flagFile: $flagFile\n";
        
        if ( $modifier =~ /^status$/ )
        {        
            $self->logStatus("copying");
            return;
        }
        
        $self->logError("Already copying file in directory");
        return;
    }

    
    #### SET DESTINATION FILE
    my ($filename) = $file =~ /([^\/]+)$/; 
    my $destinationFile = "$destinationPath/$filename";
    $self->logDebug("destinationPath", $destinationPath);


    #### CHECK IF DESTINATION FILE EXISTS
    if ( -f $destinationFile or -d $destinationFile )
    {
		if ( $modifier =~ /^status$/ )
		{
			$self->logStatus("completed");
			return;
		}

        elsif ( not $modifier =~ /^overwrite$/ )
        {
            $self->logError("File exists");
            return;
        }
    }

    #### CREATE FLAG FILE
	$self->logDebug("flagFile present BEFORE rm", $flagFile), if -f $flagFile;
    `rm -fr $flagFile` if -f $flagFile;
	$self->logDebug("flagFile present AFTER rm", $flagFile), if -f $flagFile;
    open(FLAG, ">$flagFile") or die "{ error: 'Cannot open copyFile flagfile: $flagFile' }";
    print FLAG time();
    close(FLAG);
    
    #### PRINT COPY STATUS: INITIATED
    $self->logStatus("initiated");

	#### FAKE CGI TERMINATION
	$self->fakeTermination();    
	
    #### FLUSH BUFFER TO MAKE SURE STATUS MESSAGE IS SENT
    $| = 1;

    #### BEGIN COPY FILE TO DESTINATION
	use File::Copy::Recursive;

    $self->logDebug("Copying...");
    $self->logDebug("FROM", $filePath);
    $self->logDebug("TO", $destinationFile);
    #my $result = File::Copy::cp($filePath, $destinationFile);
    my $result = File::Copy::Recursive::rcopy($filePath, $destinationFile);
    $self->logDebug("Result", $result);
    
    #### REMOVE FLAG FILE
    File::Remove::rm($flagFile);

    #### SET PERMISSIONS
	$self->setPermissions($username, $destinationFile);
}

}

