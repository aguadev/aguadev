package Agua::Common::Package::Sync;
use Moose::Role;
use Method::Signatures::Simple;
use JSON;

=head2

	PACKAGE		Agua::Common::Package
	
	PURPOSE
	
		INSTALL/UPGRADE/REMOVE PACKAGES AND UPDATE package TABLE

=cut

has 'message'	=> ( isa => 'Str|Undef', is => 'rw' );
has 'details'	=> ( isa => 'Str|Undef', is => 'rw');

#### SYNC WORKFLOWS
method syncWorkflows () {
	#### GET VARIABLES
	my $message 	= 	$self->message();
	$message =~ s/"/'/g;
	my $details 	= 	$self->details();
	my $username 	= 	$self->username();
	my $branch		=	$self->branch() || "master";
	$self->logDebug("message", $message);
	$self->logDebug("details", $details);
	$self->logDebug("username", $username);
	$self->logDebug("branch", $branch);
	if ( defined $details and $details ) {
		$details =~ s/"/'/g;
		$message .= "\n\n$details";
	}
	$self->logDebug("FINAL message", $message);

	#### SYNC PUBLIC WORKFLOWS
	my $success = $self->syncPublicWorkflows($username, $message, $branch);
	$self->logError("Failed to sync public workflows") and exit if not $success;
	
	##### SYNC PRIVATE WORKFLOWS
	#$success = $self->syncPrivateWorkflows($username, $message, $branch);
	#$self->logError("Failed to sync private workflows") and exit if not $success;
	
	$self->logStatus("Finished sync workflows");
}

method syncPublicWorkflows ($username, $message, $branch) {
	$self->logDebug("message", $message);
	my $resource 	= 	"workflows";
	my $privacy		=	"public";
	my $createsub 	=	\&createProjectFiles;
	$self->logDebug("createsub", $createsub);

	my $success 	= 	$self->_syncResource($username, $resource, $privacy, $message, $branch, $createsub);

	return 0 if not $success;
	return 1;
}

method syncPrivateWorkflows ($username, $message, $branch) {
	$self->logDebug("message", $message);
	my $resource 	= 	"workflows";
	my $privacy		=	"private";
	my $createsub 	=	\&createProjectFiles;

	my $success 	= 	$self->_syncResource($username, $resource, $privacy, $message, $branch, $createsub);

	return 0 if not $success;
	return 1;
}

method _syncResource ($username, $resource, $privacy, $message, $branch, $createsub) {
	$self->logDebug("username", $username);
	$self->logDebug("resource", $resource);
	$self->logDebug("privacy", $privacy);
	$self->logDebug("message", $message);
	$self->logDebug("branch", $branch);
	$self->logDebug("createsub", $createsub);

	#### CHECK PRIVACY
	$self->logCritical("type is not (public|private)") and exit if $privacy !~ /^(public|private)$/;
	
	$self->logDebug("username", $username);
	$self->logDebug("branch", $branch);

	#### SET OWNER, INSTALLDIR, OPSREPO AND HUBTYPE
	my $owner 		= 	$username;
	my $opsrepo 	= 	$self->opsrepo() || $self->setOpsRepo($privacy);
	my $packagedir 	= 	$self->setPackageDir($username, $opsrepo, $privacy);
	my $hubtype 	= 	$self->hubtype();
	$self->logDebug("packagedir", $packagedir);
	$self->logDebug("hubtype", $hubtype);
	
	#### GET LOGIN AND TOKEN FOR USER IF STORED IN DATABASE
	my ($login, $token) = $self->setLoginCredentials($username, $hubtype, $privacy);
	$self->logDebug("login", $login);
	$self->logDebug("token", $token);

	### SET RESOURCE DIR
	my $resourcedir = $self->setResourceDir($packagedir, $username, $resource);
	$self->logDebug("resourcedir", $resourcedir);

	#### CREATE opsrepo BASE DIR TWO DIRS UP IF NOT EXISTS
	my $created = $self->createRepoDir($packagedir);
	$self->logError("Can't create packagedir", $packagedir) and exit if not $created;

	#### CHECK IF REMOTE REPOSITORY ALREADY EXISTS
	my $isrepo = $self->head()->ops()->isRepo($login, $opsrepo, $privacy);
	$self->logDebug("isrepo", $isrepo);

	#### CREATE REMOTE REPO IF NOT EXISTS
	$self->initRemoteRepo($login, $opsrepo, $privacy) if not $isrepo;

	$isrepo = $self->head()->ops()->isRepo($login, $opsrepo, $privacy);
	$self->logDebug("isrepo", $isrepo);

	#### REMOVE EXISTING RESOURCE DIR
	my $remove = "rm -fr $resourcedir";
	$self->logDebug("remove", $remove);
	$self->head()->ops()->runCommand($remove);
	
	#### PRINT RESOURCE FILES
	$self->$createsub($username, $resourcedir);
	
	##### CHANGE TO REPO
	$self->head()->ops()->changeToRepo($packagedir);
	
	#### ADD TO REPO
	$self->head()->ops()->addToRepo();

	#### COMMIT CHANGES
	$self->head()->ops()->commitToRepo($message);

	#### ADD REMOTE IF MISSING
	my $remote = $hubtype;
	my $isremote = $self->head()->ops()->isRemote($login, $opsrepo, $remote);
	$self->head()->ops()->logDebug("isremote", $isremote);
	$self->head()->ops()->removeRemote($remote) if $isremote;
	$self->head()->ops()->addRemote($login, $opsrepo, $remote);	

	#### RETRIEVE keyfile FROM self->keyfile OR hub TABLE
	my $keyfile = $self->setKeyfile($username, $hubtype);
	$self->logDebug("keyfile", $keyfile);
	
	#### PUSH packagedir TO REMOTE
	$self->logDebug("Doing self->pushToRemoteRepo()");
	my $force = 1;
	my $result = $self->pushToRemoteRepo($login, $opsrepo, $hubtype, $remote, $branch, $keyfile, $privacy, $force);
	$self->logDebug("self->pushToRemoteRepo    result", $result);
	
	#### EXIT REPO
	$self->head()->ops()->exitRepo();

	return $result;
}

method initialiseResource ($owner, $username, $package, $privacy, $opsdir, $installdir) {
	
	my $data = {
		owner		=> $owner,
		username	=> $username,
		version		=>	"0.0.1",
		package		=> $package,
		privacy		=>	$privacy,
		opsdir		=>	$opsdir,
		installdir	=>	$installdir
	};
	$self->logDebug("data", $data);
	
	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $required_fields = ['package', 'privacy', 'opsdir', 'installdir'];	
	my $not_defined = $self->db()->notDefined($data, $required_fields);
	$self->logError("undefined values: @$not_defined") and exit if @$not_defined;
	
	#### ADD DATA
	my $success = $self->_addPackage($data);
	$self->logStatus("Could not add package $package") and exit if not $success;
 	$self->logStatus("Added package $package") if $success;
}

method setWorkflowDir ($opsdir, $username) {
	$self->logDebug("opsdir", $opsdir);

	my $opsrepo = $self->conf()->getKey("agua", "OPSREPO");
	$self->logDebug("opsrepo", $opsrepo);
	my $workflowdir = "$opsdir/$username/$opsrepo/workflows";
	$self->logDebug("workflowdir", $workflowdir);
	File::Path::mkpath($workflowdir) if not -d $workflowdir;
	$self->logError("Can't create workflowdir: $workflowdir") and exit if not -d $workflowdir;

	return $workflowdir;
}

#### WORKFLOW FILES
method createProjectFiles ($username, $workflowdir) {
	$self->logDebug("workflowdir", $workflowdir);

	require Agua::CLI::Project;
	require Agua::CLI::Workflow;

	my $projects = $self->_getProjects($username);
	$self->logDebug("no. projects", scalar(@$projects));
	#$self->logDebug("projects", $projects);

	foreach my $project ( @$projects ) {

		#### CREATE PROJECT DIR
		my $projectname = $project->{name};
		my $projectdir = "$workflowdir/projects/$projectname";
		File::Path::mkpath($projectdir) if not -d $projectdir;
		$self->logError("Can't create projectdir: $projectdir") and exit if not -d $projectdir;

		#### SET PROJECT FILE, REMOVE EXISTING FILE
		my $projectfile = "$projectdir/$projectname.proj";
		$self->logDebug("projectfile", $projectfile);
		`rm -fr $projectfile`;

		$project->{owner} 		=	$username;
		$project->{username} 	=	$username;
		$project->{outputfile} 	= 	$projectfile;
		$project->{logfile} 	=	$self->logfile();
		$project->{SHOWLOG}		=	$self->SHOWLOG();
		$project->{PRINTLOG}	=	$self->PRINTLOG();

		my $projectobject = Agua::CLI::Project->new($project);

		#### GET WORKFLOWS		
		my $workflows = $self->getWorkflowsByProject($project);
		$self->logDebug("no. workflows", scalar(@$workflows));
		#$self->logDebug("workflows", $workflows);
	
		foreach my $workflow ( @$workflows ) {
			#$self->logDebug("workflow", $workflow);
			$workflow->{workflow} = $workflow->{name};
			my $stages = $self->getStagesByWorkflow($workflow);
			next if not defined $stages;
			$self->logDebug("No. stages", scalar(@$stages));
			
			my $workflowfile = "$projectdir/$workflow->{number}-$workflow->{name}.work";
			$self->logDebug("workflowfile", $workflowfile);	
	
			#### CREATE WORKFLOW AND LOAD STAGES
			$workflow->{owner} 		=	$username;
			$workflow->{username} 	=	$username;
			$workflow->{outputfile} = 	$workflowfile;
			$workflow->{logfile} 	=	$self->logfile();
			$workflow->{SHOWLOG}	=	$self->SHOWLOG();
			$workflow->{PRINTLOG}	=	$self->PRINTLOG();
	
			my $workflowobject = Agua::CLI::Workflow->new($workflow);
			
			foreach my $stage ( @$stages ) {
				$stage->{appname} = $stage->{name};
				$stage->{appnumber} = $stage->{number};
				my $parameters = $self->getParametersByStage($stage);
				
				#### CREATE APPLICATION AND LOAD PARAMETERS
				$stage->{username} 	=	$username;
				$stage->{logfile} 	=	$self->logfile();
				$stage->{SHOWLOG}	=	$self->SHOWLOG();
				$stage->{PRINTLOG}	=	$self->PRINTLOG();
			
				$self->logDebug("stage", $stage);
				my $appobject = Agua::CLI::App->new($stage);
				#$self->logDebug("appobject", $appobject);
				foreach my $parameter ( @$parameters ) {
					$parameter->{param} = $parameter->{name};
					$appobject->loadParam($parameter);
				}
				
				$workflowobject->_addApp($appobject);
			}

			#### ADD WORKFLOW TO PROJECT
			$projectobject->_addWorkflow($workflowobject);

		}	#### workflows

		#### PRINT PROJECT
		$self->logDebug("printing projectfile", $projectfile);
		$projectobject->export($projectfile);

	}	#### projects
	
	$self->logDebug("END");
}

method loadProjectFiles ($username, $package, $installdir, $workflowdir) {
	$self->logDebug("BEFORE require Agua::CLI::Project");
	require Agua::CLI::Project;
	$self->logDebug("AFTER require Agua::CLI::Project");

	$self->logDebug("username", $username);
	$self->logDebug("workflowdir", $workflowdir);

	#### RETRIEVE EXISTING WORKFLOWS
	my $workflows = $self->getWorkflows();
	#$self->logDebug("workflows", $workflows);

	#### GET PROJECT DIRECTORIES
	my $projects = $self->getDirs("$workflowdir/projects");
	$self->logDebug("projects", $projects);
	
	my $index = 0;
	foreach my $project ( @$projects ) {
		$index++;
				
		my $projectfile = "$workflowdir/projects/$project/$project.proj";
		$self->logDebug("projectfile", $projectfile);
		$self->logCritical("projectfile not found", $projectfile) if not -f $projectfile;
	
		$self->logDebug("Doing Agua::CLI::Project->new()");	
		my $projectobject = Agua::CLI::Project->new(
			inputfile	=>	$projectfile,
			logfile		=>	$self->logfile(),
			SHOWLOG		=>	$self->SHOWLOG(),
			PRINTLOG	=>	$self->PRINTLOG()
		);
		#$self->logDebug("projectobject", $projectobject);
		$self->projectToDatabase($username, $projectobject);

		#### WORKFLOWS
		my $workflowobjects = $projectobject->workflows();
		$self->logDebug("workflowobjects: @$workflowobjects");
		foreach my $workflowobject ( @$workflowobjects ) {
			my $projectname 	= $workflowobject->{project};
			my $workflowname 	= $workflowobject->{name};
			my $workflownumber 	= $workflowobject->{number};

			#### SKIP IF WORKFLOW ALREADY EXISTS
			my $workflowhash = $workflowobject->exportData();
			delete $workflowhash->{apps};
			$self->logDebug("workflowhash", $workflowhash);
			my $keys = ['owner', 'username', 'project', 'name', 'number'];
			my $found = $self->objectInArray($workflows, $workflowhash, $keys);
			$self->logDebug("Doing next because found", $found) if $found;
			next if $found;
			
			#### ADD WORKFLOW
			$self->workflowToDatabase($username, $workflowobject);

			#### STAGES
			my $stageobjects = $workflowobject->apps();
			$self->logDebug("No. stageobjects", scalar(@$stageobjects));
			foreach my $stageobject ( @$stageobjects ) {
				#$self->logDebug("stageobject", $stageobject);
				my $stagenumber = $stageobject->{ordinal};

				#### ADD STAGE	
				$self->stageToDatabase($username, $stageobject, $projectname, $workflowname, $workflownumber, $stagenumber);
				
				#### PARAMETERS
				my $parameterobjects = $stageobject->parameters();
				my $paramnumber = 0;
				foreach my $parameterobject ( @$parameterobjects ) {
					$paramnumber++;
					
					#### ADD PARAMETER
					$self->stageParameterToDatabase($username, $package, $installdir, $stageobject, $parameterobject, $projectname, $workflowname, $workflownumber, $stagenumber, $paramnumber);
				}
			}
		}
	}
	
	$self->logDebug("END");
}

method projectToDatabase ($username, $projectobject) {
	$self->logCritical("username not defined") and exit if not defined $username;
	my $projectdata = $projectobject->exportData();
	delete $projectdata->{workflows};
	$projectdata->{username} = $username;
	$self->logDebug("projectdata", $projectdata);
	
	#### REMOVE PROJECT
	$self->_removeProject($projectdata);
	
	#### ADD PROJECT
	return $self->_addProject($projectdata);
}

method workflowToDatabase ($username, $workflowobject) {
	$self->logCritical("username not defined") and exit if not defined $username;
print "\n";
	my $workflowdata = $workflowobject->exportData();
	delete $workflowdata->{apps};
	$workflowdata->{username} = $self->username();
	$self->logDebug("workflowdata", $workflowdata);

	#### REMOVE WORKFLOW
	$self->_removeWorkflow($workflowdata);
	
	#### ADD WORKFLOW
	return $self->_addWorkflow($workflowdata);
}

method stageToDatabase ($username, $stageobject, $project, $workflow, $workflownumber, $number) {
	$self->logCritical("username not defined") and exit if not defined $username;

	#### ADD STAGE
	my $stagedata = $stageobject->exportData();
	$stagedata->{username} 		= $username;
	$stagedata->{project} 		= $project;
	$stagedata->{workflow} 		= $workflow;
	$stagedata->{workflownumber} = $workflownumber;
	$stagedata->{number} 		= $number;
	#$self->logDebug("stagedata", $stagedata);
	
	#### GET STAGE PARAMETERS DATA
	my $parametersdata = $stagedata->{parameters};
	
	#### DELETE PARAMETERS FROM STAGE BEFORE ADD STAGE
	delete $stagedata->{parameters};
	#$self->logDebug("AFTER delete, stagedata", $stagedata);

	#### REMOVE STAGE
	$self->_removeStage($stagedata);
	
	#### ADD STAGE
	$self->_addStage($stagedata);
}

method stageParameterToDatabase ($username, $package, $installdir, $stage, $parameterobject, $project, $workflow, $workflownumber, $stagenumber, $paramnumber) {
	#$self->logNote("parameter", $parameter);
	
	my $paramdata = $parameterobject->exportData();
	#$self->logDebug("BEFORE paramdata", $paramdata);
	$paramdata->{project}		=	$project;
	$paramdata->{workflow}		=	$workflow;
	$paramdata->{name}			=	$paramdata->{param};
	$paramdata->{number}		=	$paramnumber;
	$paramdata->{appnumber}		=	$stagenumber,
	$paramdata->{owner}			=	$username;
	$paramdata->{username}		=	$username;
	$paramdata->{package}		=	$package;
	$paramdata->{installdir}	=	$installdir;
	$paramdata->{appname}		=	$stage->name(),
	$paramdata->{version}		=	$stage->version(),
	$paramdata->{type}			=	$stage->type(),
	$self->logDebug("AFTER paramdata", $paramdata);	

	#### REMOVE STAGE PARAMETER
	$self->_removeStageParameter($paramdata);

	#### ADD STAGE PARAMETER
	return $self->_addStageParameter($paramdata);
}

#### SYNC APPS
method syncApps () {
	#### GET VARIABLES
	my $message 	= 	$self->message();
	$message =~ s/"/'/g;
	my $details 	= 	$self->details();
	my $username 	= 	$self->username();
	my $branch		=	$self->branch() || "master";
	$self->logDebug("message", $message);
	$self->logDebug("details", $details);
	$self->logDebug("username", $username);
	$self->logDebug("branch", $branch);
	if ( defined $details and $details ) {
		$details =~ s/"/'/g;
		$message .= "\n\n$details";
	}
	$self->logDebug("FINAL message", $message);

	#### SYNC PUBLIC APPS
	my $success = $self->syncPublicApps($username, $message, $branch);
	$self->logError("Failed to sync public workflows") and exit if not $success;
	
	##### SYNC PRIVATE APPS
	#$success = $self->syncPrivateApps($username, $message, $branch);
	#$self->logError("Failed to sync private apps") and exit if not $success;
	
	$self->logStatus("Finished sync apps");
}

method syncPublicApps ($username, $message, $branch) {
	$self->logDebug("");
	my $resource 	= 	"apps";
	my $privacy		=	"public";
	my $createsub 	=	\&createAppFiles;
	$self->logDebug("createsub", $createsub);

	my $success 	= 	$self->_syncResource($username, $resource, $privacy, $message, $branch, $createsub);

	return 0 if not $success;
	return 1;

	my $result = $self->_syncResource("apps", "public", $message);
	$self->logError("Failed to sync public apps") if not defined $result or not $result;
	$self->logStatus("Synched public apps") if $result;
}

method syncPrivateApps ($username, $message, $branch) {
	$self->logDebug("message", $message);
	my $resource 	= 	"apps";
	my $privacy		=	"private";
	my $createsub 	=	\&createAppFiles;

	my $success 	= 	$self->_syncResource($username, $resource, $privacy, $message, $branch, $createsub);

	return 0 if not $success;
	return 1;
}


method createRepoDir ($repodir) {
	$self->logDebug("repodir", $repodir);
	`mkdir -p $repodir` if not -d $repodir;
	$self->logError("Can't create repodir", $repodir) and exit if not -d $repodir;
	my $found = $self->head()->ops()->foundGitDir($repodir);
	$self->logDebug("found", $found);
	return 1 if $found;
	my $command = "cd $repodir; git init";
	$self->head()->ops()->runCommand($command);
	
	return $self->head()->ops()->foundGitDir($repodir);
}

method setResourceDir ($opsdir, $username, $package) {
	$self->logCritical("opsdir not defined") and exit if not defined $opsdir;
	$self->logCritical("username not defined") and exit if not defined $username;
	$self->logCritical("package not defined") and exit if not defined $package;

	$self->logDebug("opsdir", $opsdir);
	$self->logDebug("username", $username);
	$self->logDebug("package", $package);

	my $resourcedir = "$opsdir/$username/$package";
	$self->logDebug("resourcedir", $resourcedir);
	File::Path::mkpath($resourcedir) if not -d $resourcedir;
	$self->logError("Can't create resourcedir: $resourcedir") and exit if not -d $resourcedir;

	return $resourcedir;
}

method keyInArray ($array, $key, $string) {
	$self->logDebug("array not defined") and exit if not defined $array;
	$self->logDebug("key not defined") and exit if not defined $key;
	$self->logDebug("string not defined") and exit if not defined $string;
	
	foreach my $entry ( @$array ) {
		return 1 if $entry->{$key} eq $string;
	}
	
	return 0;
}


#### APP FILES
method createAppFiles ($username, $appdir) {
	$self->logDebug("username", $username);
	$self->logDebug("appdir", $appdir);
	
	my $apps = $self->getApps($username);
	$self->logDebug("no. apps", scalar(@$apps));

	foreach my $app ( @$apps ) {
		$app->{appname} = $app->{name};
		$self->logDebug("app", $app);
		
		my $parameters = $self->getParametersByApp($app);
		$parameters = [] if not defined $parameters;
		$self->logDebug("no. parameters", scalar(@$parameters));

		$self->_createAppFile($app, $parameters, $username, $appdir);
	}
}

method createPackageAppFiles ($package, $owner, $installdir, $opsdir) {
	$self->logDebug("package", $package);
	$self->logDebug("owner", $owner);
	$self->logDebug("installdir", $installdir);
	$self->logDebug("opsdir", $opsdir);

	my $appdir = $self->setResourceDir($opsdir, $owner, $package);
	$self->logDebug("appdir", $appdir);
	
	my $apps = $self->getAppsByPackage({
		owner 		=>	$owner,
		package 	=>	$package,
		installdir	=>	$installdir
	});
	$self->logDebug("apps", $apps);
	
	foreach my $app (@$apps) {
		$app->{appname} = $app->{name};
		my $parameters = $self->getParametersByApp($app);
		$parameters = [] if not defined $parameters;
		$self->logDebug("no. parameters", scalar(@$parameters));

		$self->_createAppFile($app, $parameters, $owner, $appdir);
	}
}

method getAppsByPackage ($package) {
	$self->logDebug("package", $package);
	my $fields = ["package", "owner", "installdir"];
	my $where = $self->db()->where($package, $fields);
	my $query = qq{SELECT * FROM app $where};
	my $apps = $self->db()->queryhasharray($query);
	$self->logDebug("no. apps: ", scalar(@$apps)) if defined $apps and @$apps;
	
	return $apps;
}

method _createAppFile ($app, $parameters, $username, $appdir) {
	require Agua::CLI::App;
	
	#### SANITY CHECK
	$self->logCritical("app->{owner} not defined") and exit if not defined $app->{owner};
	$self->logCritical("app->{package} not defined") and exit if not defined $app->{package};
	$self->logCritical("app->{type} not defined") and exit if not defined $app->{type};
	$self->logCritical("app->{name} not defined") and exit if not defined $app->{name};

	#### CREATE PACKAGE DIR
	my $apptypedir = "$appdir/$app->{type}";
	File::Path::mkpath($apptypedir) if not -d $apptypedir;
	$self->logError("Can't create apptypedir: $apptypedir") and exit if not -d $apptypedir;

	#### SET APP FILE
	my $appfile = "$apptypedir/$app->{name}.app";
	$self->logDebug("appfile", $appfile);

	#### CREATE APPLICATION AND LOAD PARAMETERS
	$app->{username} 	=	$username;
	$app->{outputfile} 	= 	$appfile;
	$app->{logfile} 	=	$self->logfile();
	$app->{SHOWLOG}		=	$self->SHOWLOG();
	$app->{PRINTLOG}	=	$self->PRINTLOG();
	
	my $application = Agua::CLI::App->new($app);
	$self->logNote("application", $application);
	
	foreach my $parameter ( @$parameters ) {
		$parameter->{param} = $parameter->{name};
		$parameter->{inputArgs} = $parameter->{args};
		$application->loadParam($parameter);
	}
	
	$application->exportApp($appfile);

}

method loadAppFiles ($username, $package, $installdir, $appdir) {	
	require Agua::CLI::App;
	$self->logDebug("username", $username);
	$self->logDebug("package", $package);
	$self->logDebug("installdir", $installdir);
	$self->logDebug("appdir", $appdir);
	
	my $typedirs = $self->getDirs($appdir);
	$self->logDebug("typedirs", $typedirs);
	foreach my $typedir ( @$typedirs ) {
		my $subdir = "$appdir/$typedir";
		my $appfiles = $self->getFiles($subdir);
		$self->logDebug("typedir '$typedir' appfiles: @$appfiles") if defined $appfiles;
		
		foreach my $appfile ( @$appfiles ) {
			next if not $appfile =~ /\.app$/;
	
			my $inputfile = "$subdir/$appfile";
			my $application = Agua::CLI::App->new({
				logfile 	=>	$self->logfile,
				SHOWLOG		=>	$self->SHOWLOG,
				PRINTLOG	=>	$self->PRINTLOG,
				inputfile	=>	$inputfile
			});
			$application->read();
	
			my $name = $application->name();
			my $result = $self->appToDatabase($username, $package, $installdir, $application);
			$self->logWarning("appToDatabase failed for application: $name") and next if not defined $result or not $result;
			
			my $parameters = $application->parameters();
			$self->logNote("no. parameters", scalar(@$parameters));
	
			next if scalar(@$parameters) == 0;
			
			foreach my $parameter (@$parameters) {
				my $success = $self->parameterToDatabase($username, $package, $installdir, $application, $parameter);
				$self->logWarning("success", $success) if not $success;
			}
		}
	}
}

method appToDatabase ($username, $package, $installdir, $application) {
	$self->logCritical("username not defined") and exit if not defined $username;
	$self->logCritical("package not defined") and exit if not defined $package;
	$self->logCritical("installdir not defined") and exit if not defined $installdir;
	
	my $app = $application->exportData();
	$app->{owner}		=	$username;
	$app->{package}		=	$package;
	$app->{installdir}	=	$installdir;
	#$self->logDebug("app", $app);

	#### REMOVE APP
	$self->_removeApp($app);

	#### ADD APP
	return $self->_addApp($app);
}

method parameterToDatabase ($username, $package, $installdir, $application, $parameter) {
	my $paramdata = $parameter->exportData();
	#$self->logDebug("BEFORE paramdata", $paramdata);	
	$paramdata->{name}			=	$paramdata->{param};
	$paramdata->{owner}			=	$username;
	$paramdata->{package}		=	$package;
	$paramdata->{installdir}	=	$installdir;
	$paramdata->{appname}		=	$application->name(),
	$paramdata->{apptype}		=	$application->type(),
	$paramdata->{version}		=	$application->version(),
	#$self->logDebug("AFTER paramdata", $paramdata);	

	#### REMOVE PARAMETER
	$self->_removeParameter($paramdata);

	#### ADD PARAMETER
	return $self->_addParameter($paramdata);
}

#### SYNC PACKAGES
method syncPackage () {
	#### GET VARIABLES
	my $message 	= 	$self->message();
	my $username 	= 	$self->username();
	my $package 	= 	$self->package();
	my $branch		=	$self->branch() || "master";
	$self->logDebug("message", $message);
	$self->logDebug("username", $username);
	$self->logDebug("branch", $branch);

	#### SYNC PRIVATE WORKFLOWS
	$self->_syncPackage($username, $package, $message, $branch);

	$self->logStatus("Finished sync package: $package");
}

method _syncPackage ($resource, $privacy, $message) {

	#### ONWORKING
	$self->logDebug("DEBUG EXIT") and exit;
	


	$self->logDebug("privacy", $privacy);
	$self->logDebug("message", $message);

	#### CHECK PRIVACY
	$self->logCritical("type is not (public|private)") and exit if $privacy !~ /^(public|private)$/;
	
	#### GET VARIABLES
	my $username 	= 	$self->username();
	my $branch		=	$self->branch() || "master";
	$self->logDebug("username", $username);
	$self->logDebug("branch", $branch);

	#### SET OWNER AND INSTALLDIR
	my $owner 		= 	$username;
	my $installdir 	= 	$self->setInstallDir($username, $username, $resource, $privacy);
	$self->logDebug("installdir", $installdir);

	#### SET OPSREPO AND hubtype
	my $opsrepo = $self->opsrepo() || $self->setOpsRepo($privacy);
	$self->logDebug("opsrepo", $opsrepo);
	
	my $hubtype = $self->hubtype();
	$self->logDebug("hubtype", $hubtype);
	
	#### GET LOGIN AND TOKEN FOR USER IF STORED IN DATABASE
	my ($login, $token) = $self->setLoginCredentials($username, $hubtype, $privacy);
	$self->logDebug("login", $login);
	$self->logDebug("token", $token);

	#### SET OPSREPO DIRECTORY (USE OPSDIR TO SET APPSDIR BELOW)
	my $opsdir = $self->setOpsDir($username, $opsrepo, $privacy, $resource);
	$self->logDebug("opsdir", $opsdir);

	### SET RESOURCE DIR
	my $resourcedir = $self->setResourceDir($opsdir, $username, $resource);
	$self->logDebug("resourcedir", $resourcedir);

	#### CREATE opsrepo BASE DIR TWO DIRS UP IF NOT EXISTS
	my ($repodir) = $resourcedir =~ /^(.+?)\/[^\/]+\/[^\/]+$/;
	$self->logDebug("repodir", $repodir);
	my $created = $self->createRepoDir($repodir);
	$self->logError("Can't create repodir", $repodir) and exit if not $created;
	
	
	$self->logDebug("DEBUG EXIT") and exit;
	
	
	
	#### CHECK IF REMOTE REPOSITORY ALREADY EXISTS
	my $isrepo = $self->head()->ops()->isRepo($login, $opsrepo, $privacy);
	$self->logDebug("isrepo", $isrepo);

	#### CREATE REMOTE REPO IF NOT EXISTS
	$self->initRemoteRepo($login, $opsrepo, $privacy) if not $isrepo;

	$isrepo = $self->head()->ops()->isRepo($login, $opsrepo, $privacy);
	$self->logDebug("isrepo", $isrepo);


	#### REMOVE EXISTING RESOURCE DIR
	`rm -fr $resourcedir`;
	
	#### DOWNLOAD REMOTE WORKFLOWS TO UPDATE LOCAL REPO
	$self->pullLatestChanges($login, $opsrepo, $hubtype, $opsdir, $branch, $privacy);

	#### PRINT RESOURCE FILES
	$self->createAppFiles($username, $resourcedir) if $resource eq "apps";
	$self->createProjectFiles($username, $resourcedir) if $resource eq "workflows";
	
	##### SET PACKAGE IF NOT EXISTS
	#my $ispackage = $self->isPackage($username, $opsrepo);
	#$self->logDebug("ispackage", $ispackage);
	#$self->initialiseResource($owner, $username, $opsrepo, $privacy, $opsdir, $installdir) if not $ispackage;
	#
	#
	#$self->logDebug("DEBUG EXIT") and exit;
	#
	#
	##### GET PACKAGE OBJECT
	#my $resourceobject = $self->getPackage($username, $resource);
	#$self->logDebug("resourceobject", $resourceobject);
	#
	##### CREATE PM FILE IF NOT PRESENT
	#my ($resourcebasedir) = $resourcedir =~ /^(.+?)\/[^\/]+$/;
	#my $pmfile = "$resourcebasedir/$resource.pm"; 
	#$self->logDebug("pmfile", $pmfile);
	#$self->createPmFile($pmfile, "$resource") if not -f $pmfile;
	#
	##### CREATE OPS FILE IF NOT PRESENT
	#my $opsfile = "$resourcebasedir/$resource.ops"; 
	#$self->logDebug("opsfile", $opsfile);
	#$self->createOpsFile($resourceobject, $opsfile, $opsrepo, $resource);
	
	##### ADD TO REPO
	$self->changeToRepo($repodir);
	$self->addToRepo();

	#### COMMIT CHANGES
	$self->commitToRepo($message);

	#### ADD REMOTE IF MISSING
	my $remote = $hubtype;
	my $isremote = $self->isRemote($login, $opsrepo, $remote);
	$self->logDebug("isremote", $isremote);
	$self->removeRemote($remote) if $isremote;
	$self->addRemote($login, $opsrepo, $remote);	

	#### PUSH TO REMOTE
	#### RETRIEVE keyfile FROM self->keyfile OR hub TABLE
	my $keyfile = $self->setKeyfile($username, $hubtype);
	$self->logDebug("self->installdir()", $self->installdir());
	$self->logDebug("Doing self->pushToRemoteRepo()");
	$self->pushToRemoteRepo($login, $hubtype, $remote, $branch, $keyfile, $privacy);
	
	#### EXIT REPO
	$self->exitRepo();

	
	$self->logDebug("DEBUG EXIT") and exit;
	
	
	return 1;
}

#### SYNC UTILS
method pushToRemoteRepo ($login, $repository, $hubtype, $repodir, $branch, $privacy, $force) {
	$self->logDebug("login", $login);
	$self->logDebug("repository", $repository);
	$self->logDebug("hubtype", $hubtype);
	$self->logDebug("repodir", $repodir);
	$self->logDebug("branch", $branch);
	$self->logDebug("privacy", $privacy);

	#### SET keyfile
	my $keyfile = $self->keyfile() || $self->setKeyfile($login, $hubtype);

	#### CHANGE TO REPO DIR	
	$self->head()->ops()->changeToRepo($repodir);

	#### ADD REMOTE IF MISSING
	my $remote = $hubtype;
	my $isremote = $self->head()->ops()->isRemote($login, $repository, $remote);
	$self->logDebug("isremote", $isremote);
	$self->head()->ops()->addRemote($login, $repository, $remote) if not $isremote;	

	#### DO PUSH
	$self->logDebug("Doing pushToRemote");
	my ($result, $error) = $self->head()->ops()->pushToRemote($login, $hubtype, $remote, $branch, $keyfile, $privacy, $force);
	
	$self->logDebug("result", $result);
	$self->logDebug("error", $error);
	
	my ($denied) = $error =~ /Permission denied/ms || 0;
	$self->logDebug("denied", $denied);
	$self->logDebug("Permission denied") if $denied;
	
	$self->logError("Failed to sync. Please make sure that the public certificate has been added as a deploy key to the '$repository' repository") if $denied;
	exit if $denied;
	
	return 0 if $denied;
	return 1;
}

method pullLatestChanges ($username, $repository, $hubtype, $repodir, $branch, $privacy) {
#### DOWNLOAD REMOTE PUBLIC (biorepository) OR PRIVATE REPO TO UPDATE LOCAL REPO
	$self->logDebug("");
	
	#### SET keyfile
	my $keyfile = $self->keyfile();
	$keyfile = $self->setKeyfile($username, $hubtype) if not defined $keyfile;

	#### GET LOGIN AND TOKEN IF NOT ALREADY DEFINED
	$self->logDebug("Doing setLoginCredentials()");
	my ($login, $token) = $self->setLoginCredentials($username, $hubtype, $privacy);

	#### CHANGE TO REPO DIR	
	$self->head()->ops()->changeToRepo($repodir);

	#### INITIALISE REPOSITORY IF NO .git DIR FOUND
	my $foundgit = $self->head()->ops()->foundGitDir($repodir);
	$self->logDebug("foundgit", $foundgit);
	$self->head()->ops()->initRepo($repodir) if not $foundgit;
	
	#### ADD REMOTE IF MISSING
	my $remote = $hubtype;
	my $isremote = $self->head()->ops()->isRemote($login, $repository, $remote);
	$self->logDebug("isremote", $isremote);
	$self->head()->ops()->addRemote($login, $repository, $remote) if not $isremote;	

	#### PULL REMOTE
	$self->logDebug("Doing self->head()->ops()->pullRemoteRepo");
	$self->head()->ops()->pullRemoteRepo($login, $repository, $hubtype, $login, $privacy, $keyfile);
}

method initRemoteRepo ($username, $repository, $privacy) {
#### IF REMOTE REPOSITORY DOES NOT EXIST:
#### 	1. FORK IT IF IT'S THE OPSREPO
#### 	2. OTHERWISE, CREATE THE PRIVATE OPSREPO

	$self->logDebug("username", $username);
	$self->logDebug("repository", $repository);
	$self->logDebug("privacy", $privacy);

	my $opsrepo	= 	$self->conf()->getKey("agua", "OPSREPO");
	$opsrepo	=	$self->conf()->getKey("agua", "PRIVATEOPSREPO") if $privacy eq "private";
	$self->logDebug("opsrepo", $opsrepo);

	return $self->initOpsRepo($username, $repository, $privacy) if $repository eq $opsrepo;
	
	$self->logWarning("Creating repository", $repository);
	my $description = undef;
	if ( $privacy eq "private" ) {
		$self->logWarning("Doing createPrivateRepo()");
		$self->head()->ops()->createPrivateRepo($username, $repository, $description);
	}
	else {
		$self->logWarning("Doing createPublicRepo()");
		$self->createPublicRepo($username, $repository, $description);
	}
	
	return 1;
}

method initOpsRepo ($login, $repository, $privacy) {
	$self->logDebug("login", $login);
	$self->logDebug("repository", $repository);
	$self->logDebug("privacy", $privacy);

	my $owner = $self->conf()->getKey("agua", "AGUAUSER");
	
	return $self->forkPublicRepo($owner, $repository) if $privacy eq "public";

	return $self->head()->ops()->createPrivateRepo($login, $repository, "Private workflows, apps, etc.");
}

method createPmFile ($file, $package) {
	my $content = qq{
use MooseX::Declare;
class $package extends Agua::Ops {
}};
	open(OUT, ">$file") or $self->logCritical("Can't open file: $file") and exit;
	print OUT $content;
	close(OUT) or $self->logCritical("Can't close file: $file") and exit;
}

method createOpsFile ($object, $file, $opsrepo, $type) {
	$self->logDebug("object", $object);
	$self->logDebug("file", $file);
	
	#### LOAD EXISTING OPSFILE OR GENERATE NEW ONE
	if ( not defined $self->opsinfo() ) {
		my $opsinfo = Agua::OpsInfo->new({
			logfile		=>	$self->logfile(),
			SHOWLOG		=>	$self->SHOWLOG(),
			PRINTLOG	=>	$self->PRINTLOG()
		});
		$self->opsinfo($opsinfo);
		$self->logDebug("opsinfo", $opsinfo);
	}
	
	$self->opsinfo()->inputfile($file);
	if ( -f $file ) {
		$self->opsinfo()->parseFile($file);
	}
	$self->opsinfo()->generate();

	$self->logCritical("object->package not defined") and exit if not defined $object->{package};
	$self->logCritical("object->owner not defined") and exit if not defined $object->{owner};

	my $package 	= $object->{package};
	my $owner 		= $object->{owner};
	my $description = $object->{description} || '';
	my $notes 		= $object->{notes} || '';
	
	#### SET REMOTE FILES
	my $remoteroot 			=	$self->remoteroot();
	my $remoteopsdir 		= 	"$remoteroot/$owner/$opsrepo/$owner/$package";
	my $opsfile 			= 	"$remoteopsdir/$package.ops";
	my $installfile 		= 	"$remoteopsdir/$package.pm";
	my $licensefile 		= 	"$remoteopsdir/LICENSE";
	my $readmefile 			= 	"$remoteopsdir/README";

	#### SET ATTRIBUTES
	$self->opsinfo()->set('package', $object->{package});
	$self->opsinfo()->set('type', $type);
	$self->opsinfo()->set('version', $object->{version});
	$self->opsinfo()->set('description', $object->{description}) if $description;
	$self->opsinfo()->set('notes', $object->{notes}) if $notes;
	$self->opsinfo()->set('opsfile', $opsfile);
	$self->opsinfo()->set('installfile', $installfile);
	$self->opsinfo()->set('licensefile', $licensefile);
	$self->opsinfo()->set('readmefile', $readmefile);
}

method createOpsRepo ($login, $opsrepo, $privacy) {
	$self->logDebug("login", $login);
	$self->logDebug("opsrepo", $opsrepo);
	$self->logDebug("privacy", $privacy);

	my $description = undef;
	if ( $privacy eq "public" ) {
		$self->head()->ops()->createPublicRepo($login, $opsrepo, $description);
	}
	else {
		$self->head()->ops()->createPrivateRepo($login, $opsrepo, $description);
	}
}

method setOpsRepo ($privacy) {
	$self->logDebug("privacy", $privacy);

	#### SET OPSREPO AND hubtype
	my $opsrepo;
	if ( $privacy eq "public" ) {
		$opsrepo = $self->opsrepo() || $self->conf()->getKey("agua", "OPSREPO");
		$self->logDebug("PUBLIC opsrepo", $opsrepo);
	}
	elsif ( $privacy eq "private" ) {
		$opsrepo = $self->opsrepo() || $self->conf()->getKey("agua", "PRIVATEOPSREPO");
		$self->logDebug("PRIVATE opsrepo", $opsrepo);
	}
	$self->logDebug("Returning opsrepo", $opsrepo);
	
	return $opsrepo;	
}

1;
