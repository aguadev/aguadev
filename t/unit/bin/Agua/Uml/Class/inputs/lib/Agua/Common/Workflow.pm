package Agua::Common::Workflow;
use Moose::Role;
use Moose::Util::TypeConstraints;

#has 'json'			=> ( isa => 'HashRef', is => 'rw', required => 0 );

=head2

	PACKAGE		Agua::Common::Workflow
	
	PURPOSE
	
            WORKFLOW METHODS FOR Agua::Common
	
=cut

use Data::Dumper;

sub getWorkflows {
	my $self		=	shift;
	
    #### VALIDATE
    my $username = $self->username();
	return $self->_getWorkflows($username);
}

sub _getWorkflows {
	my $self		=	shift;
	my $username	=	shift;
	
	#### GET ALL SOURCES
	my $query = qq{SELECT * FROM workflow
WHERE username='$username'
ORDER BY project, name};
	$self->logDebug("$query");
	$self->logDebug("self->db()", $self->db());

	my $workflows = $self->db()->queryhasharray($query);

	######## IF NO RESULTS:
	####	2. INSERT DEFAULT WORFKLOW INTO workflow TABLE
	####	2. CREATE DEFAULT WORKFLOW FOLDERS
	return $self->_defaultWorkflows() if not defined $workflows;

	return $workflows;
}

sub getWorkflowsByProject {
	my $self			=	shift;
	my $projectdata		=	shift;
	#$self->logDebug("projectdata", $projectdata);
	
	my $username = $projectdata->{username};
	my $project = $projectdata->{name};
	$self->logCritical("username not defined") and exit if not defined $username;
	$self->logCritical("project not defined") and exit if not defined $project;
	
	#### GET ALL SOURCES
	my $query = qq{SELECT * FROM workflow
WHERE username='$username'
AND project='$project'
ORDER BY name};
	$self->logDebug("self->db()", $self->db());
	$self->logDebug("$query");
	my $workflows = $self->db()->queryhasharray($query);
	$workflows = [] if not defined $workflows;
	
	return $workflows;
}

sub addWorkflow {
=head2

	SUBROUTINE		addWorkflow
	
	PURPOSE

		ADD A WORKFLOW TO THE workflow TABLE
        
=cut

	my $self		=	shift;
    my $data 		=	$self->json();
 	$self->logDebug("data", $data);

	my $success = $self->_addWorkflow($data);
 	return if not defined $success;
	$self->logError("Could not add workflow $data->{workflow} into project $data->{project} in workflow table") and exit if not defined $success;
	$self->logStatus("Added $data->{name} to project $data->{project}");
}

sub _addWorkflow {
#### ADD A WORKFLOW TO workflow, stage AND stageparameter
	my $self		=	shift;
    my $data 		=	shift;
	
	$self->logDebug("data", $data);
	
	#### SET TABLE AND REQUIRED FIELDS	
	my $table = "workflow";
	my $required_fields = ["username", "project", "name"];

	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $not_defined = $self->db()->notDefined($data, $required_fields);
    $self->logError("not defined: @$not_defined") and exit if @$not_defined;

	#### REMOVE IF EXISTS ALREADY
	$self->_removeFromTable($table, $data, $required_fields);

	#### GET MAX WORKFLOW NUMBER IF NOT DEFINED
    my $username = $data->{username};
	$self->logDebug("username", $username);
    my $number = $data->{number};
	$self->logDebug("number", $number);
	if ( not defined $number ) {
		my $query = qq{SELECT MAX(number)
		FROM workflow
		WHERE username = '$username'
		AND project = '$data->{project}'};
		$self->logDebug("query", $query);
		my $number = $self->db()->query($query);
		$number = 1 if not defined $number;
		$number++ if defined $number;
		$data->{number} = $number;
	}

	#### DO ADD
	my $success = $self->_addToTable($table, $data, $required_fields);
	$self->logDebug("success", $success);

	#### ADD THE PROJECT DIRECTORY TO THE USER'S agua DIRECTORY
	my $fileroot = $self->getFileroot($username);
	$self->logDebug("fileroot", $fileroot);
	my $filepath = "$fileroot/$data->{project}/$data->{name}";
	$self->logDebug("Creating directory", $filepath);
	File::Path::mkpath($filepath);
	$self->logError("Could not create the fileroot directory: $fileroot") and exit if not -d $filepath;
	
	#### SET PERMISSIONS
	$self->setPermissions($username, $filepath);

	return 1;
}

sub removeWorkflow {
 	my $self		=	shift;
    my $data	=	$self->json();
 	$self->logDebug("data", $data);

	#### REMOVE WORKFLOW AND SUBSIDIARY DATA
	#### (STAGE, STAGE PARAMETERS, VIEW, ETC.)
	$self->_removeWorkflow($data);

	#### REMOVE WORKFLOW DIRECTORY
    my $username = $data->{'username'};
	$self->logDebug("username", $username);
	my $fileroot = $self->getFileroot($username);
	$self->logDebug("fileroot", $fileroot);

	my $filepath = "$fileroot/$data->{project}/$data->{workflow}";
	$self->logDebug("Removing directory", $filepath);
	$self->logError("Could not find directory for workflow $data->{name} in project $data->{project}") and exit if not -d $filepath;
	
	$self->logError("Could not remove directory: $filepath") and exit if not File::Remove::rm(\1, $filepath);

	$self->logStatus("Removed workflow $data->{name} from project $data->{project}");
}

sub _removeWorkflow {
	my $self		=	shift;
	my $data		=	shift;
	$self->logCaller("");
	$self->logDebug("data", $data);
	
	#### SET TABLE AND REQUIRED FIELDS	
	my $table = "workflow";
	my $required_fields = ["username", "project", "name", "number"];

	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $not_defined = $self->db()->notDefined($data, $required_fields);
    $self->logError("undefined values: @$not_defined") and exit if @$not_defined;

	#### REMOVE FROM workflow
	my $success = $self->_removeFromTable($table, $data, $required_fields);
 	$self->logError("Could not remove $data->{workflow} from project $data->{project}") and exit if not defined $success;

	#### SET 'workflow' FIELD
	$data->{workflow} = $data->{name};
	
	#### REMOVE FROM stage
	$table = "stage";
	my $stage_fields = ["username", "project", "workflow"];
	$self->_removeFromTable($table, $data, $stage_fields);

	#### REMOVE FROM clusterworkflow
	$table = "clusterworkflow";
	my $clusters_fields = ["username", "project", "workflow"];
	$self->_removeFromTable($table, $data, $clusters_fields);
	
	#### REMOVE FROM stageparameter
	$table = "stageparameter";
	my $stageparameter_fields = ["username", "project", "workflow"];
	$self->_removeFromTable($table, $data, $stageparameter_fields);

	#### REMOVE FROM view
	$table = "view";
	my $view_fields = ["username", "project"];
	$self->_removeFromTable($table, $data, $view_fields);

	return 1;
}

sub renameWorkflow {
#### RENAME A WORKFLOW IN workflow, stage AND stageparameter
	my $self		=	shift;
    $self->logDebug("Common::renameWorkflow()");
    
        my $json 			=	$self->json();

    $self->logDebug("json", $json);

	#### GET NEW NAME
	my $newname = $json->{newname};
    $self->logError("No newname parameter. Exiting") and exit if not defined $newname;
    $self->logDebug("newname", $newname);

    #### VALIDATE
    $self->logError("User session not validated") and exit unless $self->validate();

	#### QUIT IF NEW NAME EXISTS ALREADY
	my $query = qq{SELECT name FROM workflow
WHERE project='$json->{project}'
AND name='$newname'};
	my $already_exists = $self->db()->query($query);
	if ( $already_exists )
	{
	    $self->logError("New name $newname already exists in workflow table");
		return;
	}

	#### SET TABLE AND REQUIRED FIELDS	
	my $table = "workflow";
	my $required_fields = ["username", "project", "name"];

	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $not_defined = $self->db()->notDefined($json, $required_fields);
    $self->logError("undefined values: @$not_defined") and exit if @$not_defined;
	
	#### UPDATE workflow
	my $set_hash = { name => $newname };
	my $set_fields = ["name"];
	my $success = $self->_updateTable($table, $json, $required_fields, $set_hash, $set_fields);
 	$self->logError("Could not rename workflow '$json->{workflow}' to '$newname' in $table table") and exit if not defined $success;

	#### SET 'workflow' FIELD FOR STAGE AND STAGEPARAMETER TABLES
	$json->{workflow} = $json->{name};
	
	#### UPDATE stage
	$table = "stage";
	$set_hash = { workflow => $newname };
	$set_fields = ["workflow"];
	$required_fields = ["username", "project", "name"];
	$self->_updateTable($table, $json, $required_fields, $set_hash, $set_fields);
	
	#### UPDATE stage
	$table = "stageparameter";
	$self->_updateTable($table, $json, $required_fields, $set_hash, $set_fields);
	
	#### UPDATE clusters
	$table = "cluster";
	$set_hash = { workflow => $newname };
	$set_fields = ["workflow"];
	$required_fields = ["username", "project", "workflow"];
	$self->_updateTable($table, $json, $required_fields, $set_hash, $set_fields);

	#### RENAME WORKFLOW DIRECTORY
	my $fileroot = $self->getFileroot();
	$self->logDebug("fileroot", $fileroot);
	my $old_filepath = "$fileroot/$json->{project}/$json->{name}";
	my $new_filepath = "$fileroot/$json->{project}/$json->{newname}";
	if ( $^O =~ /^MSWin32$/ )   {   $old_filepath =~ s/\//\\/g;  }
	$self->logDebug("old_filepath", $old_filepath);
	$self->logDebug("new_filepath", $new_filepath);

	#### CHECK IF WORKFLOW DIRECTORY EXISTS
	$self->logError("Cannot find old workflow directory: $old_filepath") and exit if not -d $old_filepath;
	
	#### RENAME WORKFLOW DIRECTORY
	File::Copy::move($old_filepath, $new_filepath);

	$self->logError("Could not rename directory: $old_filepath to $new_filepath") and exit if not -d $new_filepath;

	$self->logStatus("Successfully renamed workflow $json->{workflow} to $newname in workflow table");
	
}	#### renameWorkflow

sub moveWorkflow {
#### MOVE A WORKFLOW WITHIN A PROJECT
	my $self		=	shift;
	
	my $workflowobject = $self->{json};
	$self->logDebug("workflowobject", $workflowobject);
	my $newnumber = $workflowobject->{newnumber};
	
	my $oldnumber = $workflowobject->{number};
	$self->logError("oldnumber not defined") and exit if not defined $oldnumber;
	$self->logError("oldnumber == newnumber") and exit if $oldnumber == $newnumber;
	
	my $projectname = $workflowobject->{project};
	my $workflowname = $workflowobject->{name};
	my $username = $workflowobject->{username};

	#### CHECK ENTRY IS CORRECT
	my $query = qq{SELECT 1 FROM workflow
WHERE username = '$username'
AND project = '$projectname'
AND name = '$workflowname'
AND number = '$oldnumber'};
	$self->logError("Workflow '$workflowname' (number $oldnumber) not found in project $projectname'") and exit if not $self->db()->query($query);	

	#### GET WORKFLOWS ORDERED BY WORKFLOW NUMBER
	$query = qq{SELECT * FROM workflow
WHERE username = '$username'
AND project = '$projectname'
ORDER BY number};
	my $workflows = $self->db()->queryhasharray($query);
	#foreach my $workflow ( @$workflows ) {
	#	$self->logDebug("$workflow->{name} - $workflow->{number}");
	#}
	#### DO RENUMBER
	for ( my $i = 0; $i < @$workflows; $i++ )
	{
		$self->logDebug("$$workflows[$i]->{name} - $$workflows[$i]->{number}");
		my $counter = $i + 1;
		my $number;
		#### SKIP IF BEFORE REORDERED WORKFLOWS
		if ( $counter < $oldnumber and $counter < $newnumber )
		{
			$self->logDebug("Setting counter", $counter);
			$number = $counter;
		}
		#### IF WORKFLOW HAS BEEN MOVED DOWNWARDS, GIVE IT THE NEW INDEX
		#### AND DECREMENT COUNTER FOR SUBSEQUENT WORKFLOWS
		elsif ( $oldnumber < $newnumber ) {
			if ( $counter == $oldnumber ) {
				$self->logDebug("Setting newnumber", $newnumber);
				$number = $newnumber;
			}
			elsif ( $counter <= $newnumber ) {
				$self->logDebug("Setting counter - 1: ", $counter - 1, "");
				$number = $counter - 1;
			}
			else {
				$self->logDebug("Setting counter", $counter);
				$number = $counter;
			}
		}
		#### OTHERWISE, THE WORKFLOW HAS BEEN MOVED UPWARDS SO GIVE IT
		#### THE NEW INDEX AND INCREMENT COUNTER FOR SUBSEQUENT WORKFLOWS
		else {
			if ( $counter < $oldnumber ) {
				$self->logDebug("Setting counter + 1: ", $counter + 1, "");
				$number = $counter + 1;
			}
			elsif ( $oldnumber == $counter ) {
				$self->logDebug("Setting newnumber", $newnumber);
				$number = $newnumber;
			}
			else {
				$self->logDebug("Setting counter", $counter);
				$number = $counter;
			}
		}
		#my $existingnumber= ;
		$query = qq{UPDATE workflow SET number = $number
WHERE username = '$username' AND project = '$projectname' AND number = $$workflows[$i]->{number} AND name = '$$workflows[$i]->{name}'};
		$self->logDebug("$query");
		$self->db()->do($query);
	}

	$self->logStatus("Moved workflow $workflowname in project $projectname");
}
=head2

	SUBROUTINE		_defaultWorkflows
	
	PURPOSE

		1. INSERT DEFAULT WORKFLOW INTO workflow TABLE
		
		2. CREATE DEFAULT PROJECT AND WORKFLOW FOLDERS

	INPUT
	
		1. USERNAME
		
		2. SESSION ID
		
	OUTPUT
		
		1. JSON HASH { project1 : { workflow}

=cut

sub _defaultWorkflows {
	my $self		=	shift;
	
    #### VALIDATE    
    $self->logError("User session not validated") and exit unless $self->validate();

	#### SET DEFAULT WORKFLOW
	my $json = {};
	$json->{username} = $self->username();
	$json->{project} = "Project1";
	$json->{name} = "Workflow1";
	$json->{number} = 1;
	$self->logDebug("json", $json);
	
	#### ADD WORKFLOW
	my $success = $self->_addWorkflow($json);
 	$self->logError("Could not add workflow $json->{workflow} into  workflow table") and exit if not defined $success;

	#### DO QUERY
    my $username = $json->{username};
	$self->logDebug("username", $username);
	my $query = qq{SELECT * FROM workflow
WHERE username='$username'
ORDER BY project, name};
	$self->logDebug("$query");	;
	my $workflows = $self->db()->queryhasharray($query);

	return $workflows;
}

=head2

	SUBROUTINE		copyWorkflow
	
	PURPOSE
	
        COPY A WORKFLOW TO ANOTHER (NON-EXISTING) WORKFLOW:
		
			1. UPDATE THE workflow TABLE TO ADD THE NEW WORKFLOW

			3. COPY THE WORKFLOW DIRECTORY TO THE NEW WORKFLOW IF
            
                copyFile IS DEFINED
                
                 echo '{"sourceuser":"admin","targetuser":"syoung","sourceworkflow":"Workflow0","sourceproject":"Project1","targetworkflow":"Workflow9","targetproject":"Project1","username":"syoung","sessionId":"9999999999.9999.999","mode":"copyWorkflow"}' |  ./workflow.cgi
                
=cut
sub copyWorkflow {
	my $self			=	shift;
        my $json 			=	$self->json();
 	$self->logDebug("Common::copyWorkflow()");
    $self->logError("No data provided")
        if not defined $json;
	
	my $sourceuser     	= $json->{sourceuser};
	my $targetuser     	= $json->{targetuser};
	my $sourceproject  	= $json->{sourceproject};
	my $sourceworkflow 	= $json->{sourceworkflow};
	my $targetproject  	= $json->{targetproject};
	my $targetworkflow 	= $json->{targetworkflow};
	my $copyfiles      	= $json->{copyfiles};
	my $date			= $json->{date};

    $self->logDebug("sourceuser", $sourceuser);
	$self->logDebug("targetuser", $targetuser);
    $self->logDebug("sourceworkflow", $sourceworkflow);
	$self->logDebug("targetworkflow", $targetworkflow);

    $self->logError("User not validated: $targetuser") and exit if not $self->validate();
    $self->logError("targetworkflow not defined: $targetworkflow") and exit if not defined $targetworkflow or not $targetworkflow;

    my $can_copy;
	$can_copy = 1 if $sourceuser eq $targetuser;
	$can_copy = $self->canCopy($sourceuser, $sourceproject, $targetuser) if $sourceuser ne $targetuser;
	$self->logDebug("can_copy", $can_copy);

    $self->logError("Insufficient privileges for user: $targetuser") and exit if not $can_copy;

	#### CHECK IF WORKFLOW ALREADY EXISTS
	my $query = qq{SELECT 1
FROM workflow
WHERE username = '$targetuser'
AND project = '$targetproject'
AND name = '$targetworkflow'};
	$self->logDebug("$query");
	my $workflow_exists = $self->db()->query($query);
	$self->logError("Workflow already exists: $targetworkflow") and exit if $workflow_exists;
	
	#### GET SOURCE PROJECT
	$query = qq{SELECT *
FROM workflow
WHERE username = '$sourceuser'
AND project = '$sourceproject'
AND name = '$sourceworkflow'};
	$self->logDebug("$query");
	my $workflowobject = $self->db()->queryhash($query);
    $self->logError("Source workflow does not exist: $targetworkflow") and exit if not defined $workflowobject;
	
	#### SET PROVENANCE
	$workflowobject = $self->setProvenance($workflowobject, $date);
	
	#### SET WORKFLOW NUMBER
	$query = qq{SELECT MAX(number)
FROM workflow
WHERE username = '$targetuser'
AND project = '$targetproject'};
	$self->logDebug("$query");
	my $workflownumber = $self->db()->query($query);
	$workflownumber = 0 if not defined $workflownumber;
	$workflownumber++;
    $workflowobject->{number} = $workflownumber;
    
    #### COPY WORKFLOW (AND STAGES, STAGE PARAMETERS, VIEW, ETC.)
    $self->_copyWorkflow($workflowobject, $targetuser, $targetproject, $targetworkflow, $date);
    
    #### COPY FILES IF FLAGGED BY copyfiles 
    if ( defined $copyfiles and $copyfiles )
    {
        #### SET DIRECTORIES
        my $aguadir = $self->conf()->getKey("agua", 'AGUADIR');
        my $userdir = $self->conf()->getKey("agua", 'USERDIR');
        my $sourcedir = "$userdir/$sourceuser/$aguadir/$sourceproject/$sourceworkflow";
        my $targetdir = "$userdir/$targetuser/$aguadir/$targetproject/$targetworkflow";
        $self->logDebug("sourcedir", $sourcedir);
        $self->logDebug("targetdir", $targetdir);
    
        #### COPY DIRECTORY
        my $copy_result = $self->copyFilesystem($targetuser, $sourcedir, $targetdir);
        $self->logStatus("Copied to $targetworkflow") and exit if $copy_result;
        $self->logStatus("Could not copy to '$targetworkflow");
    }
    
    $self->logStatus("Completed copy to $targetworkflow");
}

sub _copyWorkflow {
    my $self            =   shift;
	my $workflowobject  =   shift;
    my $targetuser      =   shift;
    my $targetproject   =   shift;
    my $targetworkflow  =   shift;
	my $date			=	shift;
    
	my $sourceuser      =   $workflowobject->{username};
	my $sourceworkflow  =   $workflowobject->{name};
	my $sourceproject   =   $workflowobject->{project};

    $self->logDebug("targetuser", $targetuser);
    $self->logDebug("targetworkflow", $targetworkflow);
    $self->logDebug("targetproject", $targetproject);

	$self->logDebug("sourceuser", $sourceuser);
    $self->logDebug("sourceproject", $sourceproject);
    $self->logDebug("workflowobject", $workflowobject);

	#### CREATE PROJECT DIRECTORY
	my $aguadir = $self->conf()->getKey("agua", 'AGUADIR');
	my $userdir = $self->conf()->getKey("agua", 'USERDIR');
	my $targetdir = "$userdir/$targetuser/$aguadir/$targetproject/$targetworkflow";
	$self->logDebug("targetdir", $targetdir);
	File::Path::mkpath($targetdir);

	#### SET PROVENANCE
	$workflowobject = $self->setProvenance($workflowobject, $date);

    #### INSERT COPY OF WORKFLOW INTO TARGET 
    $workflowobject->{username} = $targetuser;
    $workflowobject->{project} = $targetproject;
    $workflowobject->{name} = $targetworkflow;
    $self->insertWorkflow($workflowobject);

	my $query;
    #### COPY STAGES
    $query = qq{SELECT * FROM stage
WHERE username='$sourceuser'
AND project='$sourceproject'
AND workflow='$sourceworkflow'};
    $self->logDebug("$query"); ;
    my $stages = $self->db()->queryhasharray($query);
    $stages = [] if not defined $stages;
    $self->logDebug("No. stages: " . scalar(@$stages));
    foreach my $stage ( @$stages )
    {
        $stage->{username} = $targetuser;
        $stage->{project} = $targetproject;
        $stage->{workflow} = $targetworkflow;
    }
    $self->insertStages($stages);

    #### COPY STAGE PARAMETERS
    foreach my $stage ( @$stages )
    {
        my $query = qq{SELECT * FROM stageparameter
WHERE username='$sourceuser'
AND project='$sourceproject'
AND workflow='$sourceworkflow'
AND appnumber='$stage->{number}'};
        $self->logDebug("$query");
        my $stageparams = $self->db()->queryhasharray($query);
        $stageparams = [] if not defined $stageparams;
        $self->logDebug("No. stageparams: " . scalar(@$stageparams));
        foreach my $stageparam ( @$stageparams )
        {
			my $sourcedir = "$stageparam->{project}/$stageparam->{workflow}";
			my $targetdir = "$targetproject/$targetworkflow";
			$stageparam->{value} =~ s/$sourcedir/$targetdir/g;
            $stageparam->{username} = $targetuser;
            $stageparam->{project} = $targetproject;
	        $stageparam->{workflow} = $targetworkflow;
        }
        $self->insertStageParameters($stageparams);
    }
    
    #### COPY INFORMATION IN view TABLE
    $query = qq{SELECT * FROM view
WHERE username='$sourceuser'
AND project='$sourceproject'};
    $self->logDebug("$query");
    my $views = $self->db()->queryhasharray($query);
    $views = [] if not defined $views;
    $self->logDebug("No. views: " . scalar(@$views));
    foreach my $view ( @$views )
    {
        $view->{username} = $targetuser;
        $view->{project} = $targetproject;
    }
    $self->insertViews($views); 
}

sub copyFilesystem {
#### COPY DIRECTORY
    my $self    	=   shift;
	my $username	=	shift;
    my $source  	=   shift;
    my $target  	=   shift;
    
	require File::Copy::Recursive;
    $self->logDebug("Copying...");
    $self->logDebug("FROM", $source);
    $self->logDebug("TO", $target);
    my $result = File::Copy::Recursive::rcopy($source, $target);
    $self->logDebug("copy result", $result);
    
	#### SET PERMISSIONS
	$self->setPermissions($username, $target);
	
    return $result;
}

=head2

	SUBROUTINE		copyProject
	
	PURPOSE
	
       THIS SUBROUTINE HAS TWO ROLES:
       
       1. COPY A PROJECT TO A (NON-EXISTING) DESTINATION PROJECT:
       
			1. ADD PROJECT TO project TABLE
            
            2. ADD ANY WORKFLOWS TO THE workflow TABLE
			
			2. OPTIONALLY, COPY THE PROJECT DIRECTORY

echo '{"sourceuser":"admin","targetuser":"syoung","sourceproject":"Project1","targetproject":"Project1","username":"syoung","sessionId":"9999999999.9999.999","mode":"copyProject"}' |  ./workflow.cgi
                
=cut

sub copyProject {
	my $self		=	shift;

    my $json 		=	$self->json();
 	$self->logDebug("Common::copyProject()");
    $self->logError("No data provided")
        if not defined $json;
	
	my $sourceuser 		= $json->{sourceuser};
	my $targetuser 		= $json->{targetuser};
	my $sourceproject 	= $json->{sourceproject};
	my $targetproject 	= $json->{targetproject};
	my $copyfiles 		= $json->{copyfiles};
	
    $self->logError("User not validated: $targetuser") and exit if not $self->validate();
	
    my $can_copy = $self->projectPrivilege($sourceuser, $sourceproject, $targetuser, "groupcopy");
    $self->logError("Insufficient privileges for user: $targetuser") and exit if not $can_copy;

	#### EXIT IF TARGET PROJECT ALREADY EXISTS IN project TABLE
	my $query = qq{SELECT 1
FROM project
WHERE username = '$targetuser'
AND name = '$targetproject'};
	$self->logDebug("$query");
	my $exists = $self->db()->query($query);
    $self->logError("Project already exists: $targetproject ") and exit if $exists;

	my $success = $self->_copyProject($json);
	$self->logError("Failed to copy project $sourceproject to $targetproject") and exit if not $success;
	
	$self->logStatus("Copied to project $sourceproject to $targetproject") ;    
}

sub _copyProject {
	my $self			=	shift;
	my $data			=	shift;

	$self->logDebug("data", $data);
	
	my $sourceuser 		= $data->{sourceuser};
	my $targetuser 		= $data->{targetuser};
	my $sourceproject 	= $data->{sourceproject};
	my $targetproject 	= $data->{targetproject};
	my $copyfiles 		= $data->{copyfiles};
	
	#### CONFIRM THAT SOURCE PROJECT EXISTS IN project TABLE
	my $query = qq{SELECT *
FROM project
WHERE username = '$sourceuser'
AND name = '$sourceproject'};
	$self->logDebug("$query");
	my $projectobject = $self->db()->queryhash($query);
	$self->logDebug("projectObject", $projectobject);
    $self->logError("Source project does not exist: $sourceproject") and exit if not defined $projectobject;
	
	#### SET PROVENANCE
	my $date = $data->{date};
	$projectobject = $self->setProvenance($projectobject, $date);
	
	#### SET TARGET VARIABLES
	$projectobject->{username} 	= 	$targetuser;
	$projectobject->{name}		=	$targetproject;

	#### DO ADD
	$self->logDebug("Doing _addToTable(table, json, required_fields)");
	my $required_fields = [ "username", "name" ];
	my $table = "project";	
	my $success = $self->_addToTable($table, $projectobject, $required_fields);	
	$self->logDebug("_addToTable(stage info) success", $success);
    $self->logError("Could not insert project: $targetproject") and exit if not $success;

    #### GET SOURCE WORKFLOW INFORMATION
    $query = qq{SELECT * FROM workflow
WHERE username='$sourceuser'
AND project='$sourceproject'};
	$self->logDebug("$query");
	my $workflowObjects = $self->db()->queryhasharray($query);
    $self->logDebug("No. workflows: " . scalar(@$workflowObjects));

	#### COPY SOURCE WORKFLOW TO TARGET WORKFLOW
    #### COPY ALSO STAGE, STAGEPARAMETER, VIEW AND REPORT INFO
    foreach my $workflowObject ( @$workflowObjects )
    {
        $self->_copyWorkflow($workflowObject, $targetuser, $targetproject, $workflowObject->{name}, $date);
    }
	
	#### CREATE PROJECT DIRECTORY
	my $aguadir = $self->conf()->getKey("agua", 'AGUADIR');
	my $userdir = $self->conf()->getKey("agua", 'USERDIR');
	my $targetdir = "$userdir/$targetuser/$aguadir/$targetproject";
	File::Path::mkpath($targetdir);

    #### COPY FILES AND SUBDIRS IF FLAGGED BY copyfiles
    if ( defined $copyfiles and $copyfiles )
    {
        #### SET DIRECTORIES
        $self->logDebug("aguadir", $aguadir);
        my $sourcedir = "$userdir/$sourceuser/$aguadir/$sourceproject";
        
        #### COPY DIRECTORY
        my $copy_success = $self->copyFilesystem($sourcedir, $targetdir);
		$copy_success = 0 if not defined $copy_success;
		$self->logError("Could not copy to '$targetproject") and exit if not $copy_success;
    }
	
	return 1;    
}



sub setProvenance {
	my $self		=	shift;
	my $object		=	shift;
	my $date		=	shift;

	#### GET PROVENANCE
	require JSON; 
	my $jsonparser = new JSON;
	my $provenance;
	$self->logDebug("object->{provenance}", $object->{provenance});
	$provenance = $jsonparser->allow_nonref->decode($object->{provenance}) if $object->{provenance};
	$provenance = [] if not $object->{provenance};
	
	#### SET PROVENANCE
	my $username = $self->username();
	delete $object->{provenance};
	push @$provenance, {
		copiedby	=>	$username,
		date		=>	$date,
		original	=>	$object
	};
	my $provenancestring = $jsonparser->encode($provenance);
	$self->logDebug("provenancestring", $provenancestring);
	$object->{provenance} = $provenancestring;
	
	return $object;
}

sub insertViews {
    my $self        =   shift;
    my $hasharray   =   shift;
	$self->logDebug("Agua::Common::Workflow::insertViews(hasharray)");
	$self->logDebug("hasharray", $hasharray);
    
	#### SET TABLE AND REQUIRED FIELDS	
    	my $table       =   "view";
	my $required_fields = ["username", "project"];
	my $inserted_fields = $self->db()->fields($table);

    foreach my $hash ( @$hasharray )
    {    
        #### CHECK REQUIRED FIELDS ARE DEFINED
        my $not_defined = $self->db()->notDefined($hash, $required_fields);
        $self->logError("undefined values: @$not_defined") and exit if @$not_defined;
    
        #### DO ADD
        $self->logDebug("Doing _addToTable(table, json, required_fields)");
        my $success = $self->_addToTable($table, $hash, $required_fields, $inserted_fields);	
        $self->logDebug("_addToTable(stage info) success", $success);
    }
}

sub insertReports {
    my $self        =   shift;
    my $hasharray   =   shift;
	#### SET TABLE AND REQUIRED FIELDS	
    	my $table       =   "report";
	my $required_fields = ["username", "project", "name", "number"];
	my $inserted_fields = $self->db()->fields($table);

    foreach my $hash ( @$hasharray )
    {    
        #### CHECK REQUIRED FIELDS ARE DEFINED
        my $not_defined = $self->db()->notDefined($hash, $required_fields);
        $self->logError("undefined values: @$not_defined") and exit if @$not_defined;
    
        #### DO ADD
        $self->logDebug("Doing _addToTable(table, json, required_fields)");
        my $success = $self->_addToTable($table, $hash, $required_fields, $inserted_fields);	
        $self->logDebug("_addToTable(stage info) success", $success);
    }
}

sub insertStageParameters {
    my $self        =   shift;
    my $stageparameters   =   shift;
	#### SET TABLE AND REQUIRED FIELDS	
    	my $table       =   "stageparameter";
	my $required_fields = ["username", "project", "workflow", "appname", "appnumber", "name"];
    my $inserted_fields = $self->db()->fields($table); 
    foreach my $stageparameter ( @$stageparameters )
    {    
        #### CHECK REQUIRED FIELDS ARE DEFINED
        my $not_defined = $self->db()->notDefined($stageparameter, $required_fields);
        $self->logError("undefined values: @$not_defined") and exit if @$not_defined;
    
        #### DO ADD
        $self->logDebug("Doing _addToTable(table, json, required_fields)");
        my $success = $self->_addToTable($table, $stageparameter, $required_fields, $inserted_fields);	
        $self->logDebug("_addToTable(stage info) success", $success);
    }
}

sub insertStages {
    my $self        =   shift;
    my $stages   =   shift;
	#### SET TABLE AND REQUIRED FIELDS	
    	my $table       =   "stage";
	my $required_fields = ["username", "project", "workflow", "number"];
    my $inserted_fields = $self->db()->fields($table);    
    
    foreach my $stage ( @$stages )
    {    
        #### CHECK REQUIRED FIELDS ARE DEFINED
        my $not_defined = $self->db()->notDefined($stage, $required_fields);
        $self->logError("undefined values: @$not_defined") and exit if @$not_defined;
    
        #### DO ADD
        $self->logDebug("Doing _addToTable(table, json, required_fields)");
        my $success = $self->_addToTable($table, $stage, $required_fields, $inserted_fields);	
        $self->logDebug("_addToTable(stage info) success", $success);
    }
}

sub insertWorkflow {
    my $self            =   shift;
    my $workflowObject  =   shift;
	#### SET TABLE AND REQUIRED FIELDS	
    	my $table       =   "workflow";
	my $required_fields = ["username", "project", "name", "number"];
	my $inserted_fields = $self->db()->fields($table);

    #### CHECK REQUIRED FIELDS ARE DEFINED
    my $not_defined = $self->db()->notDefined($workflowObject, $required_fields);
    $self->logError("undefined values: @$not_defined") and exit if @$not_defined;

    #### DO ADD
    $self->logDebug("Doing _addToTable(table, json, required_fields)");
    my $success = $self->_addToTable($table, $workflowObject, $required_fields, $inserted_fields);	
    $self->logDebug("_addToTable(stage info) success", $success);
}








sub workflowIsRunning {
	my $self		=	shift;
	my $username	=	shift;
	my $project		=	shift;
	my $workflow	=	shift;
	
	$self->logDebug("username", $username);
	$self->logDebug("project", $project);
	$self->logDebug("workflow", $workflow);

	my $query = qq{SELECT 1 from stage
WHERE username='$username'
AND project='$project'
AND workflow='$workflow'
AND status='running'
};
	$self->logDebug("query", $query);
    my $result =  $self->db()->query($query);
	$self->logDebug("Returning result", $result);
	
	return $result
}

1;