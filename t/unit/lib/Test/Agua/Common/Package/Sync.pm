use MooseX::Declare;
use Method::Signatures::Simple;

class Test::Agua::Common::Package::Sync with (Test::Agua::Common::Package,
	Agua::Common::Package,
	Test::Agua::Common::Database,
	Test::Agua::Common::Util,
	Agua::Common::Database,
	Agua::Common::Logger,
	Agua::Common::Project,
	Agua::Common::Workflow,
	Agua::Common::Privileges,
	Agua::Common::Stage,
	Agua::Common::App,
	Agua::Common::Parameter,
	Agua::Common::Base,
	Agua::Common::Util) extends Agua::Workflow {

use Data::Dumper;
use Test::More;
use Test::DatabaseRow;
use Agua::DBaseFactory;
use Agua::Ops;
use Agua::Instance;
use Conf::Yaml;
use FindBin qw($Bin);

####////}}

method BUILD ($hash) {
	$self->logDebug("");
	
	if ( defined $self->logfile() ) {
		$self->head()->ops()->logfile($self->logfile());
		$self->head()->ops()->keyfile($self->keyfile());
		$self->head()->ops()->log($self->log());
		$self->head()->ops()->printlog($self->printlog());
	}

	if ( defined $self->conf() ) {
		$self->head()->ops()->conf($self->conf());
	}

}

#### SYNC WORKFLOWS
method testSyncPrivateWorkflows {
	diag("Test _syncWorkflows: private");

	$self->testSyncWorkflows("private");
}

method testSyncPublicWorkflows {
	diag("Test _syncWorkflows: public");

	$self->testSyncWorkflows("public");
}

method testSyncWorkflows ($privacy) {
    $self->logDebug("privacy", $privacy);
	
	##### LOAD DATABASE
	$self->setUpTestDatabase();
	$self->setDatabaseHandle();

	#### COPY DIRS AFRESH
	$self->cleanUpDirs();
	#$self->copyDirs();

	#### LOAD DATA
	my $packagefile			=	"$Bin/inputs/tsv/workflows/package.tsv";
	my $projectfile			=	"$Bin/inputs/tsv/workflows/project.tsv";
	my $workflowfile		=	"$Bin/inputs/tsv/workflows/workflow.tsv";
	my $stagefile			=	"$Bin/inputs/tsv/workflows/stage.tsv";
	my $stageparameterfile	=	"$Bin/inputs/tsv/workflows/stageparameter.tsv";
	$self->loadTsvFile("package", $packagefile);
	$self->loadTsvFile("project", $projectfile);
	$self->loadTsvFile("workflow", $workflowfile);
	$self->loadTsvFile("stage", $stagefile);
	$self->loadTsvFile("stageparameter", $stageparameterfile);
	
	#### SET USERNAME
	my $username = $self->conf()->getKey("database", "TESTUSER");
	$self->username($username);
	$self->logDebug("username", $username);
	
	#### SET SESSION ID
	my $sessionid 	= 	$self->conf()->getKey("database", "TESTSESSIONID");
	$self->setSession($username, $sessionid);

	#### SET OPSREPO
	my $opsrepo 	= 	$self->setOpsRepo($privacy);

	#### SET OPSDIR FOR APPDIR AND TO RETRIEVE DB ENTRY
	####	<Agua_installdir>/repos/<private|public>/<owner>/<opsrepo>/<owner>/<package>

	my $opsdir		= 	"$Bin/outputs/repos/$privacy/$username/$opsrepo/$username/$opsrepo";
	$opsdir =~ s/^\/mnt//;
	$self->opsdir($opsdir);
	$self->logDebug("opsdir", $opsdir);
	
	#### SET INSTALLDIR TO RETRIEVE ENTRY IN package TABLE
	####	<userdir>/<username>/repos/<private|public>/<package>/<owner>
	my $installdir 	= "$Bin/outputs/repos/$privacy/$username/$opsrepo";
	$installdir =~ s/^\/mnt//;
	$self->installdir($installdir);
	$self->logDebug("installdir", $installdir);

	#### SET BRANCH AND MESSAGE	
	my $branch = "master";
	my $message = "Syncing $privacy workflows";

	#### SET CREATE RESOURCE SUBROUTINE REFERENCE
	my $createsub 	=	\&createProjectFiles;

	#### SYNC WORKFLOWS
	$self->logDebug("Doing _syncResource('workflows', '$privacy')");
	my $success = $self->_syncResource($username, "workflows", $privacy, $message, $branch, $createsub);
	ok($success, "completed _syncWorkflows: $privacy");
}

method testSyncPrivateApps {
	diag("Test _syncApps: private");
    $self->logDebug("");
	$self->testSyncApps("private");
}

method testSyncPublicApps {
	diag("Test _syncApps: public");
    $self->logDebug("");
	$self->testSyncApps("public");
}

method testSyncApps ($privacy) {
	##### LOAD DATABASE
	$self->logDebug("");
	
	$self->setUpTestDatabase();
	$self->setDatabaseHandle();
	
	#### COPY inputs/private/biorepository AFRESH
	$self->copyDirs();
	
	#### LOAD TESTUSER APPS INTO DATABASE
	my $appfile			=	"$Bin/inputs/tsv/apps/app.tsv";
	my $parameterfile	=	"$Bin/inputs/tsv/apps/parameter.tsv";
	my $packagefile		=	"$Bin/inputs/tsv/apps/package.tsv";
	$self->loadTsvFile("app", $appfile);
	$self->loadTsvFile("parameter", $parameterfile);
	$self->loadTsvFile("package", $packagefile);
	
	#### SET USERNAME
	my $username = $self->conf()->getKey("database", "TESTUSER");
	$self->username($username);
	
	#### SET SESSION ID
	my $sessionid 		= 	"1234567890.1234.123";
	$self->setSession($username, $sessionid);
	
	#### SET Bin
	my $aguadir			=	$self->conf()->getKey("agua", "INSTALLDIR");
	$Bin =~ s/^.+\/bin/$aguadir\/t\/bin/;
	$self->logDebug("Bin", $Bin);
	
	#### SET OPSDIR TO RETRIEVE DB ENTRY
	my $opsrepo = $self->conf()->getKey("agua", "OPSREPO");
	my $opsdir	= "$Bin/inputs/repos/$privacy/$username/$opsrepo/$username";
	$opsdir =~ s/^\/mnt//;
	$self->opsdir($opsdir);
	$self->logDebug("opsdir", $opsdir);
	
	#### SET OPS FILE
	my $repository 		= 	"apps";
	my $opsfile 		= 	"$opsdir/$repository/$repository.ops";
	$self->logDebug("opsfile: $opsfile");
	
	#### SET opsinfo OBJECT FROM *.ops FILE
	$self->ops()->setOpsInfo($opsfile);
	
	#### SET INSTALLDIR TO RETRIEVE ENTRY IN package TABLE
	#### outputs/repos/public/apps/testuser/apps
	my $installdir = "$Bin/outputs/repos/$privacy/apps/$username/apps";
	$installdir =~ s/^\/mnt//;
	$self->installdir($installdir);
	$self->logDebug("installdir", $installdir);	
	
	#### SET PRIVACY
	$self->privacy("$privacy");
	
	#### SET BRANCH AND MESSAGE	
	my $branch = "master";
	my $message = "Syncing $privacy apps";

	#### SET CREATE RESOURCE SUBROUTINE REFERENCE
	my $createsub 	=	\&createAppFiles;

	#### SYNC APPS
	$self->logDebug("Doing _syncResource('apps', '$privacy')");
	my $success = $self->_syncResource($username, "apps", $privacy, $message, $branch, $createsub);
	ok($success, "completed _syncApps: $privacy");
}

#### WORKFLOW FILES
method testCreateProjectFiles {
	diag("Test createProjectFiles");

	my $privacy = "public";

	#### CLEAR DATABASE
    $self->prepareTestDatabase();

	#### CREATE DATABASE TABLES ONLY (NO LOAD DATA)
	$self->setUpTestDatabase();
	
	#### SET DATABASE HANDLE
	$self->setDatabaseHandle();
	
	#### REMOVE EXISTING DIRS
	$self->cleanUpDirs();
	
	#### LOAD WORKFLOWS
	my $packagefile			=	"$Bin/inputs/tsv/apps/package.tsv";
	my $projectfile			=	"$Bin/inputs/tsv/workflows/project.tsv";
	my $workflowfile		=	"$Bin/inputs/tsv/workflows/workflow.tsv";
	my $stagefile			=	"$Bin/inputs/tsv/workflows/stage.tsv";
	my $stageparameterfile	=	"$Bin/inputs/tsv/workflows/stageparameter.tsv";
	$self->loadTsvFile("project", $projectfile);
	$self->loadTsvFile("workflow", $workflowfile);
	$self->loadTsvFile("stage", $stagefile);
	$self->loadTsvFile("stageparameter", $stageparameterfile);
	$self->loadTsvFile("package", $packagefile);

	#### SET USERNAME
	my $username = $self->conf()->getKey("database", "TESTUSER");
	$self->username($username);
	$self->logDebug("username", $username);
	
	#### SET SESSION ID
	my $sessionid = $self->conf()->getKey("database", "TESTSESSIONID");
	$self->setSession($username, $sessionid);
	
	#### GET OPSREPO
	my $opsrepo = $self->setOpsRepo($privacy);

	#### SET SOURCE DIR
	#### $opsdir = "$installdir/repos/$privacy/$owner/$opsrepo/$owner/$package";
	#### $installdir = "$userdir/$username/$reposubdir/$privacy/$package/$owner";

	my $opsdir		= 	"$Bin/outputs/repos/$privacy/$username/biorepository";
	my $workflowdir = 	$self->setResourceDir($opsdir, $username, "workflows");
	$self->logDebug("workflowdir", $workflowdir);

	#### SET EXPECTED DIR
	my $expecteddir = "$Bin/inputs/repos/$privacy/$username/$opsrepo/$username/workflows";
	$self->logDebug("expecteddir", $expecteddir);
	
	#### CREATE FILES
	$self->createProjectFiles($username, $workflowdir);

	#### CHECK FILES
	$self->checkWorkflowFiles($expecteddir, $workflowdir);
}

method testSortWorkflowFiles () {

	require Agua::CLI::Project;
	my $projectobject = Agua::CLI::Project->new();

	my $workflows = [
		'1-Workflow1',
		'11-Workflow11',
		'2-Workflow2',
		'22-Workflow22',
		'3-Workflow3'
	];

	my $expected = [
		'1-Workflow1',
		'2-Workflow2',
		'3-Workflow3',
		'11-Workflow11',
		'22-Workflow22'
	];

	$workflows = $projectobject->sortWorkflowFiles($workflows);
	ok ($self->identicalArray($workflows, $expected), "workflows array order");	
}

method validate {
	return 1;
}

method checkWorkflowFiles ($expecteddir, $workflowdir) {
	$self->logDebug("expecteddir", $expecteddir);
	$self->logDebug("workflowdir", $workflowdir);
	
	my $workflows = $self->getWorkflows();
	#$self->logDebug("workflows", $workflows);

	my $projectobject = Agua::CLI::Project->new();

	foreach my $workflow ( @$workflows ) {
		my $project = $workflow->{project};
		
		my $subdir = "$workflowdir/projects/$project";
		#$self->logDebug("subdir", $subdir);

		#### VERIFY PROJECT FILE
		my $projectfile = "$workflowdir/projects/$project/$project.proj";
		my $expectedfile = "$expecteddir/projects/$project/$project.proj";
		$self->logDebug("projectfile", $projectfile);
		$self->logDebug("expectedfile", $expectedfile);
		
		ok(-f $projectfile, "project file created");
		ok($self->diff($expectedfile, $projectfile), "projectfile as expected");
		
		#### VERIFY WORKFLOW FILES
		my $workflowfiles = $projectobject->getWorkflowFiles($subdir);
		#$self->logDebug("project '$project' workflowfiles: @$workflowfiles") if defined $workflowfiles;
		
		foreach my $workflowfile ( @$workflowfiles ) {
			my $expectedfile= "$expecteddir/projects/$project/$workflowfile";
			my $actualfile 	= "$workflowdir/projects/$project/$workflowfile";
			
			ok(-f $actualfile, "createProjectFiles    workflow file created");
			#$self->logDebug("expectedfile", $expectedfile);
			#$self->logDebug("actualfile", $actualfile);
			ok($self->diff($expectedfile, $actualfile), "createProjectFiles    workflowfile as expected");
		}
	}
}

method testLoadProjectFiles () {
	diag("Test loadProjectFiles");

	my $privacy =	"public";
    $self->logDebug("privacy", $privacy);
	
	#### CLEAR DATABASE
    $self->prepareTestDatabase();

	#### CREATE DATABASE TABLES ONLY (NO LOAD DATA)
	$self->setUpTestDatabase();

	#### DEBUG
	$self->setDatabaseHandle();

	### COPY DIRS AFRESH
	$self->cleanUpDirs();
	#$self->copyDirs();

	#### EXPECTED VALUES
	my $projecttsvfile			=	"$Bin/inputs/tsv/workflows/project.tsv";
	my $workflowtsvfile			=	"$Bin/inputs/tsv/workflows/workflow.tsv";
	my $stagetsvfile			=	"$Bin/inputs/tsv/workflows/stage.tsv";
	my $stageparametertsvfile	=	"$Bin/inputs/tsv/workflows/stageparameter.tsv";

	#### SET USERNAME
	my $username = $self->conf()->getKey("database", "TESTUSER");
	$self->username($username);
	
	#### SET SESSION ID
	my $sessionid = "1234567890.1234.123";
	$self->setSession($username, $sessionid);

	#### SET OPSDIR FOR APPDIR AND TO RETRIEVE DB ENTRY
	my $opsdir		= "$Bin/inputs/repos/$privacy/$username/biorepository";
	$self->opsdir($opsdir);
	$self->logDebug("opsdir", $opsdir);
	
	### SET WORKFLOW DIR
	my $opsrepo = $self->setOpsRepo($privacy);
	my $workflowdir = 	$self->setResourceDir($opsdir, $username, "workflows");
	$self->logDebug("workflowdir", $workflowdir);

	#### SET PACKAGE AND INSTALLDIR
	my $package		=	"bioapps";
	my $installdir 	= 	"$Bin/outputs/$privacy/apps/$username/$package";
	$self->logDebug("installdir", $installdir);

	#### LOAD PROJECTS
	$self->loadProjectFiles($username, "$installdir/$package", $package, $workflowdir);
	
	#### VERIFY
	print "Checking loaded projects\n";
	$self->checkTsvLines("project", $projecttsvfile);
	print "Checking loaded workflows\n";
	$self->checkTsvLines("workflow", $workflowtsvfile);
	print "Checking loaded stages\n";
	$self->checkTsvLines("stage", $stagetsvfile);	
	print "Checking loaded parameters\n";
	$self->checkTsvLines("stageparameter", $stageparametertsvfile);
}

method _defaultWorkflows {
	return [];
}

method getFileroot {
	my $username = $self->username();
	$self->logDebug("username", $username);
	
	my $userdir = $self->conf()->getKey('agua', 'USERDIR');
	my $aguadir = $self->conf()->getKey('agua', 'AGUADIR');
	my $fileroot = "$Bin/outputs$userdir/$username/$aguadir";
	$self->logDebug("fileroot", $fileroot);

	return $fileroot;
}

#### APP FILES
method testCreateAppFiles {
	diag("Test createAppFiles");

	#### CLEAR DATABASE
    $self->prepareTestDatabase();

	#### CREATE DATABASE TABLES ONLY (NO LOAD DATA)
	$self->setUpTestDatabase();
	
	#### SET DATABASE HANDLE
	$self->setDatabaseHandle();
	
	#### REMOVE EXISTING DIRS
	$self->cleanUpDirs();
	
	#### REMOVE ALL EXISTING ENTRIES
	my $query = qq{DELETE FROM app};
	$self->db()->do($query);
	$query = qq{DELETE FROM parameter};
	$self->db()->do($query);	

	#### LOAD TSVFILE APPS INTO DATABASE
	my $appfile			=	"$Bin/inputs/tsv/apps/app.tsv";
	my $parameterfile	=	"$Bin/inputs/tsv/apps/parameter.tsv";
	$self->loadTsvFile("app", $appfile);
	$self->loadTsvFile("parameter", $parameterfile);
	
	#### SET USERNAME
	my $username	=	$self->conf()->getKey("database", "TESTUSER");
	$self->username($username);
	$self->logDebug("username", $username);

	#### SET OPSREPO
	my $opsrepo 	= 	$self->conf()->getKey("agua", "OPSREPO");
	
	#### SET OPSDIR
	my $opsdir		= "$Bin/outputs/repos/private/$username/$opsrepo";
	$self->opsdir($opsdir);
	$self->logDebug("opsdir", $opsdir);
	
	#### SET EXPECTEDDIR
	my $package		=	"bioapps";
	my $sourcedir 	=	"$Bin/inputs/repos/private/$username/$opsrepo";
	my $expecteddir = 	$self->setResourceDir($sourcedir, $username, $package);
	$self->logDebug("expectedir", $expecteddir);
	
	### SET APPDIR	
	my $appdir 		= 	$self->setResourceDir($opsdir, $username, $package);
	$self->logDebug("appdir", $appdir);
	
	#### CREATE APP FILES
	$self->createAppFiles($username, $appdir);
	
	#### CHECK APP FILES
	$self->checkAppFiles($expecteddir, $appdir);
}

method checkAppFiles ($expecteddir, $appdir) {
	$self->logDebug("");
	my $privacydirs = $self->getDirs($appdir);
	$self->logDebug("typedirs", $privacydirs);
	foreach my $privacydir ( @$privacydirs ) {
		my $subdir = "$appdir/$privacydir";
		my $appfiles = $self->getFiles($subdir);
		$self->logDebug("typedir '$privacydir' appfiles: @$appfiles") if defined $appfiles;
		
		foreach my $appfile ( @$appfiles ) {
			my $expectedfile = "$expecteddir/$privacydir/$appfile";
			my $actualfile 	=	"$appdir/$privacydir/$appfile";
			$self->logDebug("expectedfile", $expectedfile);
			$self->logDebug("actualfile", $actualfile);
			ok(-f $actualfile, "createAppFiles    appfile created");
			ok( $self->diff($expectedfile, $actualfile), "createAppFiles    appfile as expected");
		}
	}
}

method testLoadAppFiles {
	diag("Test loadAppFiles");
	
	#### SET TYPE
	my $privacy = "private";
	
	#### SET LOG
	$self->logfile("$Bin/outputs/loadappfiles.log");

	#### SET USERNAME
	my $username	=	$self->conf()->getKey("database", "TESTUSER");

	#### CLEAR DATABASE
    $self->prepareTestDatabase();

	#### CREATE DATABASE TABLES ONLY (NO LOAD DATA)
	$self->setUpTestDatabase();
	
	#### SET DATABASE HANDLE
	$self->setDatabaseHandle();
	
	#### SET Bin
	my $aguadir		=	$self->conf()->getKey("agua", "INSTALLDIR");
	$Bin =~ s/^.+\/bin/$aguadir\/t\/bin/;
	$self->logDebug("Bin", $Bin);
	
	##### LOAD TESTUSER APPS INTO DATABASE
	my $apptsvfile		=	"$Bin/inputs/tsv/apps/app.tsv";
	my $parametertsvfile=	"$Bin/inputs/tsv/apps/parameter.tsv";

	#### SET PACKAGE AND INSTALLDIR
	my $package		=	"bioapps";
	my $installdir 	= 	"$Bin/outputs/$privacy/apps/$username/$package";
	$self->logDebug("installdir", $installdir);
	
	#### SET TEST DATABASEROW
	$self->setTestDatabaseRow();
	
	#### SET USERNAME	
	$self->username($username);
	
	#### SET OPSREPO
	my $opsrepo 		=	$self->conf()->getKey("agua", "OPSREPO");
	
	#### SET OPSDIR
	my $opsdir	= "$Bin/inputs/repos/$privacy/$username/$opsrepo";
	$opsdir =~ s/^\/mnt//;
	$self->opsdir($opsdir);
	$self->logDebug("opsdir", $opsdir);
	
	#### SET APP DIR
	my $appdir = $self->setResourceDir($opsdir, $username, $package);
	$appdir =~ s/^\/mnt//;
	$self->logDebug("appdir", $appdir);
	
	
	#### LOAD APP FILES
	$self->loadAppFiles($username, $package, $installdir, $appdir);

	##### VERIFY
	diag("Test check loaded apps");
	$self->checkTsvLines("app", $apptsvfile);

	diag("Test check loaded parameters");
	$self->checkTsvLines("parameter", $parametertsvfile);
}
method checkTsvLines ($table, $tsvfile) {
	my $fields =	$self->db()->fields($table);
	#$self->logDebug("fields: @$fields");
	my $lines = $self->getLines($tsvfile);
	$self->logDebug("no. lines", scalar(@$lines));
	$self->logWarning("file is empty: $tsvfile") and return if not defined $lines;
	
	foreach my $line ( @$lines ) {
		$line =~ s/\s+$//;
		my @elements = split "\t", $line;
		my $hash = {};
		for ( my $i = 0; $i < @$fields; $i++ ) {
			#$self->logDebug("elements[$i]", $elements[$i]);
			$hash->{$$fields[$i]} = $elements[$i];
			$hash->{$$fields[$i]} = '' if not defined $hash->{$$fields[$i]};
		}

		my $where = $self->db()->where($hash, $fields);
		
		#### FILTER BACKSLASHES
		$where =~ s/\\\\/\\/g;
		my $query = qq{SELECT 1 FROM $table $where};
		$self->logDebug("query", $query);
		ok($self->db()->query($query), "field values in table $table");
	}
}

method setInstallDir ($username, $owner, $package, $privacy) {
#### RETURN LOCATION OF APPLICATION FILES - OVERRIDEN FOR TESTING
	#### E.G., /agua/t/bin/Agua/Common/Package/Sync/outputs/private/apps/testuser/apps
	
	return $self->installdir();
}

method setOpsDir ($username, $repository, $privacy, $package) {
#### example: /agua/repos/public/biorepository/syoung/bioapps
	$self->logNote("username", $username);
	$self->logNote("repository", $repository);
	$self->logNote("type", $privacy);
	$self->logNote("package", $package);

	#### ADDED FOR TESTING
	return $self->opsdir() if defined $self->opsdir();
	
	$self->logError("type is not public or private") and exit if $privacy !~ /^(public|private)$/;
	my $installdir = $self->conf()->getKey("agua", "INSTALLDIR");
	my $opsdir = "$installdir/repos/$privacy/$repository/$username/$package";
	File::Path::mkpath($opsdir);
	$self->logError("can't create opsdir: $opsdir") if not -d $opsdir;
	
	return $opsdir;
}

method setInstallDir ($username, $owner, $package, $privacy) {
#### RETURN LOCATION OF APPLICATION FILES - OVERRIDEN FOR TESTING
	$self->logNote("username", $username);
	$self->logNote("owner", $owner);
	$self->logNote("package", $package);
	$self->logNote("type", $privacy);

	return $self->installdir() if defined $self->installdir();
	
	my $userdir = $self->conf()->getKey("agua", "USERDIR");

	return "$userdir/$username/repos/$privacy/$package/$owner";
}


}   #### Test::Agua::Common::Package::Sync


=cut
