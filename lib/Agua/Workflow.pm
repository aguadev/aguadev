use MooseX::Declare;

=head2

	PACKAGE		Workflow
	
	PURPOSE
	
		THE Workflow OBJECT PERFORMS THE FOLLOWING TASKS:
		
			1. SAVE WORKFLOWS
			
			2. RUN WORKFLOWS
			
			3. PROVIDE WORKFLOW STATUS

	NOTES

		Workflow::executeWorkflow
			|
			|
			|
			|
		Workflow::runStages
				|
				|
				|
				-> 	my $stage = Agua::Stage->new()
					...
					|
					|
					-> $stage->run() 
						|
						|
						? DEFINED 'CLUSTER' AND 'SUBMIT'
						|				|
						|				|
						|				YES ->  Agua::Stage::runOnCluster() 
						|
						|
						NO ->  Agua::Stage::runLocally()

=cut

use strict;
use warnings;
use Carp;

class Agua::Workflow with (Agua::Common, Agua::Common::Exchange) {

#### EXTERNAL MODULES
use Data::Dumper;
use FindBin::Real;
use lib FindBin::Real::Bin() . "/lib";

#### INTERNAL MODULES	
use Agua::DBaseFactory;
use Conf::Yaml;
use Agua::Stage;
use Agua::StarCluster;
use Agua::Instance;
use Agua::Monitor::SGE;



# Integers
has 'SHOWLOG'		=>  ( isa => 'Int', is => 'rw', default => 1 );  
has 'PRINTLOG'		=>  ( isa => 'Int', is => 'rw', default => 4 );
has 'workflowpid'	=> ( isa => 'Int|Undef', is => 'rw', required => 0 );
has 'workflownumber'=>  ( isa => 'Str|Undef', is => 'rw' );
has 'start'     	=>  ( isa => 'Int|Undef', is => 'rw' );
has 'stop'     		=>  ( isa => 'Int|Undef', is => 'rw' );
has 'submit'  		=>  ( isa => 'Int|Undef', is => 'rw' );
has 'validated'		=> ( isa => 'Int|Undef', is => 'rw', default => 0 );
has 'qmasterport'	=> ( isa => 'Int', is  => 'rw' );
has 'execdport'		=> ( isa => 'Int', is  => 'rw' );

# Strings
has 'random'		=> ( isa => 'Str|Undef', is => 'rw', required	=> 	0	);
has 'configfile'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'installdir'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'fileroot'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'qstat'			=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'queue'			=>  ( isa => 'Str|Undef', is => 'rw', default => 'default' );
has 'cluster'		=>  ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'whoami'  		=>  ( isa => 'Str', is => 'rw' );
has 'username'  	=>  ( isa => 'Str', is => 'rw' );
has 'password'  	=>  ( isa => 'Str', is => 'rw' );
has 'workflow'  	=>  ( isa => 'Str', is => 'rw' );
has 'project'   	=>  ( isa => 'Str', is => 'rw' );
has 'outputdir'		=>  ( isa => 'Str', is => 'rw' );
has 'keypairfile'	=> ( is  => 'rw', 'isa' => 'Str|Undef', required	=>	0	);
has 'keyfile'		=> ( isa => 'Str|Undef', is => 'rw'	);
has 'instancetype'	=> ( isa => 'Str|Undef', is  => 'rw', required	=>	0	);
has 'sgeroot'		=> ( isa => 'Str', is  => 'rw', default => "/opt/sge6"	);
has 'sgecell'		=> ( isa => 'Str', is  => 'rw', required	=>	0	);
has 'upgradesleep'	=> ( is  => 'rw', 'isa' => 'Int', default	=>	10	);

# Objects
has 'ssh'			=> ( isa => 'Agua::Ssh', is => 'rw', required	=>	0	);
has 'opsinfo'		=> ( isa => 'Agua::OpsInfo', is => 'rw', required	=>	0	);
has 'jsonparser'	=> ( isa => 'JSON', is => 'rw', lazy => 1, builder => "setJsonParser" );
has 'json'			=> ( isa => 'HashRef', is => 'rw', required => 0 );
has 'db'			=> ( isa => 'Agua::DBase::MySQL', is => 'rw', required => 0 );
has 'stages'		=> 	( isa => 'ArrayRef', is => 'rw', required => 0 );
has 'stageobjects'	=> 	( isa => 'ArrayRef', is => 'rw', required => 0 );
has 'conf'	=> ( isa => 'Conf::Yaml', is => 'rw', lazy => 1, builder => "setConf" );
has 'starcluster'	=> ( isa => 'Agua::StarCluster', is => 'rw', lazy => 1, builder => "setStarCluster" );
has 'head'	=> ( isa => 'Agua::Instance', is => 'rw', lazy => 1, builder => "setHead" );
has 'master'	=> ( isa => 'Agua::Instance', is => 'rw', lazy => 1, builder => "setMaster" );
has 'monitor'	=> ( isa => 'Agua::Monitor::SGE', is => 'rw', lazy => 1, builder => "setMonitor" );

####////}}}

method BUILD ($hash) {
}

method initialise ($json) {
	#### SET LOG
	my $username 	=	$json->{username};
	my $logfile 	= 	$json->{logfile};
	my $mode		=	$json->{mode};
	$self->logDebug("logfile", $logfile);
	$self->logDebug("mode", $mode);
	if ( not defined $logfile or not $logfile ) {
		my $identifier 	= 	"workflow";
		$self->setUserLogfile($username, $identifier, $mode);
		$self->appendLog($logfile);
	}

	#### IF JSON IS DEFINED, ADD VALUES TO SLOTS
	$self->json($json);
	if ( $json ) {
		foreach my $key ( keys %{$json} ) {
			$json->{$key} = $self->unTaint($json->{$key});
			$self->$key($json->{$key}) if $self->can($key);
		}
	}
	$self->logDebug("json", $json);	
		
	#### SET CLUSTER INSTANCES LOG
	$self->head()->logfile($logfile);
	$self->head()->SHOWLOG($self->SHOWLOG());
	$self->head()->PRINTLOG($self->PRINTLOG());
	$self->master()->logfile($logfile);
	$self->master()->SHOWLOG($self->SHOWLOG());
	$self->master()->PRINTLOG($self->PRINTLOG());
	
	#### SET HEADNODE OPS LOG
	$self->head()->ops()->logfile($logfile);	
	$self->head()->ops()->SHOWLOG($self->SHOWLOG());
	$self->head()->ops()->PRINTLOG($self->PRINTLOG());

	#### SET HEADNODE OPS CONF
	my $conf 	= 	$self->conf();
	$self->head()->ops()->conf($conf);	

	#### SET MASTER OPS LOG
	$self->master()->ops()->logfile($logfile);	
	$self->master()->ops()->SHOWLOG($self->SHOWLOG());
	$self->master()->ops()->PRINTLOG($self->PRINTLOG());

	#### SET MASTER OPS CONF
	$self->master()->ops()->conf($conf);	
	
	#### SET DATABASE HANDLE
	$self->logDebug("Doing self->setDbh");
	$self->setDbh();
    
	#### VALIDATE
	$self->logDebug("mode", $mode);
    $self->logError("User session not validated for username: $username") and exit unless $mode eq "submitLogin" or $self->validate();

	#### SET WORKFLOW PROCESS ID
	$self->workflowpid($$);	

	#### SET CLUSTER IF DEFINED
	$self->logError("Agua::Workflow::BUILD    conf->getKey(agua, CLUSTERTYPE) not defined") if not defined $self->conf()->getKey('agua', 'CLUSTERTYPE');    
	$self->logError("Agua::Workflow::BUILD    conf->getKey(cluster, QSUB) not defined") if not defined $self->conf()->getKey('cluster', 'QSUB');
	$self->logError("Agua::Workflow::BUILD    conf->getKey(cluster, QSTAT) not defined") if not defined $self->conf()->getKey('cluster', 'QSTAT');
}

method setUserLogfile ($username, $identifier, $mode) {
	my $installdir = $self->conf()->getKey("agua", "INSTALLDIR");
	$identifier	=~ s/::/-/g;
	
	return "$installdir/log/$username.$identifier.$mode.log";
}

#### EXECUTE WORKFLOW}
method executeWorkflow {
=head2

	SUBROUTINE		executeWorkflow
	
	PURPOSE
	
		WORKFLOW EXECUTION SIMPLIFIED SEQUENCE DIAGRAM
        
		Agua::Workflow.pm -> executeWorkflow()
		|
		|
		-> Agua::Workflow.pm -> runStages()
			|
			| has many Agua::Stages
			|
			-> Agua::Stage -> run()
				| 
				|
				-> Agua::Stage -> execute() LOCAL JOB
				|
				OR
				|
				-> Agua::Stage -> clusterSubmit()  CLUSTER JOB
			
=cut

	my $username 	=	$self->username();
	my $cluster 	=	$self->cluster();
	my $project 	=	$self->project();
	my $workflow 	=	$self->workflow();
	my $workflownumber=	$self->workflownumber();
	my $start 		=	$self->start();
	my $submit 		= 	$self->submit();
	$self->logDebug("submit", $submit);
	$self->logDebug("username", $username);
	$self->logDebug("project", $project);
	$self->logDebug("workflow", $workflow);
	$self->logDebug("workflownumber", $workflownumber);
	$self->logDebug("cluster", $cluster);
	
	#### QUIT IF INSUFFICIENT INPUTS
	if ( not $username or not $project or not $workflow or not $workflownumber or not $start ) {
		my $error = '';
		$error .= "username, " if not defined $username;
		$error .= "project, " if not defined $project;
		$error .= "workflow, " if not defined $workflow;
		$error .= "workflownumber, " if not defined $workflownumber;
		$error .= "start, " if not defined $start;
		$error =~ s/,\s+$//;
		$self->logError("Cannot run workflow $project.$workflow becuase of undefined values: $error") and return;
	}
	#### QUIT IF RUNNING ALREADY
	$self->logError("workflow $project.$workflow is already running") and return if $self->workflowIsRunning($username, $project, $workflow);
	
	#### QUIT IF submit BUT cluster IS EMPTY
	$self->logError("Cannot run workflow $project.$workflow: cluster not defined") and return if $submit and not $cluster;
	
	$self->logError("No AWS credentials for username $username") and return if $submit and not defined $self->_getAws($username);
	
	# SKIP REPORT
	#$self->logStatus("Running workflow $project.$workflow");
	
	#### SET STAGES
	$self->logDebug("DOING self->setStages");
	my $data = {
		username	=>	$username,
		project		=>	$project,
		workflow	=>	$workflow
	};
	my $stages = $self->setStages($username, $cluster, $data, $project, $workflow);

	#### RUN LOCALLY OR ON CLUSTER
	if ( not $submit or not defined $cluster or not $cluster ) {
		$self->logDebug("DOING self->runLocally");
		$self->runLocally($stages);
	}
	else {
		$self->logDebug("DOING self->runOnCluster");
		$self->runOnCluster($stages, $username, $project, $workflow, $workflownumber, $cluster);
	}

	$self->logGroupEnd("Agua::Workflow::executeWorkflow");

	$self->logDebug("COMPLETED");
}

method runLocally ($stages) {
	$self->logDebug("no. stages", scalar(@$stages));

	#### RUN STAGES
	$self->logDebug("BEFORE runStages()\n");
	$self->runStages($stages);
	$self->logDebug("AFTER runStages()\n");
}

method runOnCluster ($stages, $username, $project, $workflow, $workflownumber, $cluster) {
#### 1. LOAD STARCLUSTER
#### 2. CREATE CONFIG FILE
#### 3. START CLUSTER IF NOT RUNNING
#### 4. START BALANCER IF NOT RUNNING
#### 5. START SGE IF NOT RUNNING
#### 6. RUN STAGES

	$self->logDebug("XOXOXOXOXOXOXOXOXOXOXOXOXOXOXOXOXOXOXOXOXOXOXOXOXOXOXO");
	
	#### LOAD STARCLUSTER
	$self->loadStarCluster($username, $cluster);
	
	#### CREATE CONFIG FILE IF MISSING
	my $configfile = $self->setConfigFile($username, $cluster);
	$self->createConfigFile($username, $cluster) if not -f $configfile;
	
	#### SET CLUSTER WORKFLOW STATUS TO 'pending'
	$self->updateClusterWorkflow($username, $cluster, $project, $workflow, 'pending');
	
	#### SET WORKFLOW STATUS TO 'pending'
	$self->updateWorkflowStatus($username, $cluster, $project, $workflow, 'pending');
	
	#### START STARCLUSTER IF NOT RUNNING
	return if not $self->ensureStarClusterRunning($username, $cluster);
	
	### DELETE DEFAULT master -- ALREADY TAKEN CARE OF BY sge.py
	$self->deleteDefaultMaster();
	
	#### GET SGE PORTS
	my ($qmasterport, $execdport) 	= 	$self->getSgePorts();
	
	#### SET MASTER INFO FILE ON HEADNODE
	$self->setMasterInfo($username, $cluster, $qmasterport, $execdport);
	
	#### START BALANCER IF NOT RUNNING
	return if not $self->ensureBalancerRunning($username, $cluster);
	
	#### START SGE IF NOT RUNNING
	return if not $self->ensureSgeRunning($username, $cluster, $project, $workflow);
	
	#### CREATE UNIQUE QUEUE FOR WORKFLOW
	my $envars = $self->getEnvars($username, $cluster);
	$self->logDebug("envars", $envars);
	$self->createQueue($username, $cluster, $project, $workflow, $envars);
	
	#### SET CLUSTER WORKFLOW STATUS TO 'running'
	$self->updateClusterWorkflow($username, $cluster, $project, $workflow, 'running');
	
	#### SET WORKFLOW STATUS TO 'running'
	$self->updateWorkflowStatus($username, $cluster, $project, $workflow, 'running');
	
	### RELOAD DBH
	$self->setDbh();
	
	#### RUN STAGES
	$self->logDebug("BEFORE runStages()\n");
	$self->runStages($stages);
	$self->logDebug("AFTER runStages()\n");
	
	#### RESET DBH JUST IN CASE
	$self->setDbh();
	
	#### SET CLUSTER WORKFLOW STATUS TO 'completed'
	$self->updateClusterWorkflow($username, $cluster, $project, $workflow, 'completed');
	
	#### SET WORKFLOW STATUS TO 'completed'
	$self->updateWorkflowStatus($username, $cluster, $project, $workflow, 'completed');
	
	#### RETURN IF OTHER WORKFLOWS ARE RUNNING
	my $clusterbusy = $self->clusterIsBusy($username, $cluster);
	$self->logDebug("clusterbusy", $clusterbusy);
	return if $clusterbusy;
	
	#### OTHERWISE, SET CLUSTER FOR TERMINATION
	$self->markForTermination($username, $cluster);
	
	$self->logDebug("COMPLETED");
}

method ensureStarClusterRunning ($username, $cluster) {
#### START STARCLUSTER IF NOT RUNNING
	$self->logDebug("");
	
	#### CHECK IF STARCLUSTER IS RUNNING
    $self->logDebug("DOING self->starcluster()->isRunning()");
	my $clusterrunning = $self->starcluster()->isRunning();
	$self->logDebug("clusterrunning", $clusterrunning);
	return 1 if $clusterrunning;
	
	#### START STARCLUSTER IF NOT RUNNING
	my $success = $self->startStarCluster($username, $cluster);
	$self->logDebug("Failed to start cluster") if not $success;

	return $success;
}

method ensureBalancerRunning ($username, $cluster) {
#### START BALANCER IF NOT CLUSTER OR BALANCER RUNNING
	$self->logDebug("");
	
	#### CHECK IF BALANCER IS RUNNING
	my $balancerrunning = $self->starcluster()->balancerRunning();
	$self->logDebug("balancerrunning", $balancerrunning);

	return 1 if $balancerrunning;

	#### START BALANCER IF NOT RUNNING
	my $success = $self->startStarBalancer($username, $cluster);
	$self->logDebug("Failed to start cluster") if not $success;
	
	return $success;
}

method ensureSgeRunning ($username, $cluster, $project, $workflow) {
	$self->logDebug("");
	
	#### RESET DBH JUST IN CASE
	$self->setDbh();
	
	#### CHECK SGE IS RUNNING ON MASTER THEN HEADNODE
	$self->logDebug("DOING self->checkSge($username, $cluster)");
	my $isrunning = $self->checkSge($username, $cluster);
	$self->logDebug("isrunning", $isrunning);
	
	#### RESET DBH IF NOT DEFINED
	$self->logDebug("DOING self->setDbh()");
	$self->setDbh();

	if ( $isrunning ) {
		#### UPDATE CLUSTER STATUS TO 'running'
		$self->updateClusterStatus($username, $cluster, 'SGE running');
		
		return 1;
	}
	else {
		#### SET CLUSTER STATUS TO 'error'
		$self->updateClusterStatus($username, $cluster, 'SGE error');

		$self->logDebug("Failed to start SGE");
		
		return 0;
	}
}

#### STARCLUSTER
method setStarCluster {
	$self->logCaller("");

	my $starcluster = Agua::StarCluster->new({
		username	=>	$self->username(),
		conf		=>	$self->conf(),
        SHOWLOG     => 	$self->SHOWLOG(),
        PRINTLOG    =>  $self->PRINTLOG()
    });

	$self->starcluster($starcluster);
}
method loadStarCluster ($username, $cluster) {
#### RETURN INSTANCE OF StarCluster
	$self->logDebug("username", $username);
	$self->logDebug("cluster", $cluster);
	$self->logError("username not defined") and exit if not defined $username;
	$self->logError("cluster not defined") and exit if not defined $cluster;

	#### GET CLUSTER INFO
	my $clusterobject = $self->getCluster($username, $cluster);
	$self->logDebug("clusterobject", $clusterobject);
	$self->logError("Agua::Workflow::loadStarCluster    clusterobject not defined") if not defined $clusterobject;

	#### SET SGE PORTS
	my $clustervars = $self->getClusterVars($username, $cluster);
	$self->logDebug("clustervars", $clustervars);
	$clusterobject = $self->addHashes($clusterobject, $clustervars) if defined $clustervars;
	
	### SET whoami
	$clusterobject->{whoami} = $self->whoami();
	
	#### ADD CLUSTER STATUS IF EXISTS
	my $clusterstatus = $self->getClusterStatus($username, $cluster);
	$self->logNote("clusterstatus", $clusterstatus);
	$clusterobject = $self->addHashes($clusterobject, $clusterstatus) if defined $clusterstatus;
	
	#### ADD EC2 KEY FILES
	my $keyfiles = $self->getEc2KeyFiles();
	$self->logNote("keyfiles", $keyfiles);
	$clusterobject = $self->addHashes($clusterobject, $keyfiles) if defined $keyfiles;

	#### ADD CONF
	$clusterobject->{conf} = $self->conf();
	
	#### ADD AWS
	my $aws 		= 	$self->_getAws($username);	
	$self->logDebug("aws", $aws);
	$clusterobject = $self->addHashes($clusterobject, $aws) if defined $aws;
	
	#### SET STARCLUSTER BINARY
	my $executable = $self->conf()->getKey("agua", "STARCLUSTER");
	$self->logDebug("executable", $executable);
	$clusterobject->{executable} = $executable;
	
	#### SET LOG
	$clusterobject->{SHOWLOG} = $self->SHOWLOG();
	$clusterobject->{PRINTLOG} = $self->PRINTLOG();
	
	#### GET ENVARS
	my $envars = $self->getEnvars($username, $cluster);
	$clusterobject->{envars} = $envars;
	
	#### SET JSON (LEGACY FOR ROLE METHODS)
	$clusterobject->{json} = $self->json();
	
	#### SET CLUSTER STARTUP WAIT TIME (SECONDS)
	$clusterobject->{tailwait} = 1200;
	
	#### INSTANTIATE STARCLUSTER OBJECT
	$self->logNote("DOING self->starcluster->load(clusterobject)", $clusterobject);
	my $starcluster = $self->starcluster()->load($clusterobject);
	$self->logDebug("AFTER self->starcluster(starcluster)");
	
	return $starcluster;	
}

method startStarCluster ($username, $cluster) {	
	$self->logDebug("username", $username);
	$self->logDebug("cluster", $cluster);
	
	#### UPDATE CLUSTER STATUS TO 'starting'
	$self->logDebug("Starting StarCluster: $cluster\n");
	$self->updateClusterStatus($username, $cluster, "starting cluster");

	#### TERMINATE BALANCER
	$self->starcluster()->terminateBalancer();
	
	#### START STARCLUSTER
	my $success = $self->starcluster()->startCluster();
	$self->logDebug("starcluster->starCluster    success", $success);
	
	#### VERIFY CLUSTER IS RUNNING
	my $isrunning = $self->starcluster()->isRunning();
	$self->logDebug("isrunning", $isrunning);
	
	#### RESET DBH IF NOT DEFINED
	$self->logDebug("DOING self->setDbh()");
	$self->setDbh();

	if ( $isrunning ) {
		#### UPDATE CLUSTER STATUS TO 'running'
		$self->updateClusterStatus($username, $cluster, 'cluster running');
	
		return 1;
	}
	else {
		#### SET CLUSTER STATUS TO 'error'
		$self->updateClusterStatus($username, $cluster, 'cluster error');
		
		return 0;
	}
}

method startStarBalancer ($username, $cluster) {	
#### 1. START STARCLUSTER BALANCER
#### 2. UPDATE BALANCER PID IN clusterstatus TABLE
####. 
	$self->logDebug("username", $username);
	$self->logDebug("cluster", $cluster);

	#### START BALANCER
	my $pid = $self->starcluster()->startBalancer();
	$self->logDebug("pid", $pid);
	
	#### RESET DBH
	$self->logDebug("DOING self->setDbh()");
	$self->setDbh();

	#### SET PROCESS PID IN clusterstatus TABLE
	$self->updateClusterPid($username, $cluster, $pid) if $pid;
	
	if ( $pid ) {
		#### UPDATE CLUSTER STATUS TO 'running'
		$self->updateClusterStatus($username, $cluster, 'balancer running');
	
		return 1;
	}
	else {
		#### SET CLUSTER STATUS TO 'error'
		$self->updateClusterStatus($username, $cluster, 'balancer error');
		
		return 0;
	}
}

method markForTermination ($username, $cluster) {
	$self->logDebug("");
	
	#### SET MINNODES TO ZERO	
	$self->starcluster()->minnodes(0);
	$self->logDebug("self->starcluster->minnodes", $self->starcluster()->minnodes());
	
	#### STOP BALANCER
	$self->logDebug("DOING self->starcluster->terminateBalancer");
	$self->starcluster()->terminateBalancer();

	#### RESTART BALANCER (DUE TO TERMINATE)
	$self->logDebug("DOING self->starcluster->launchBalancer");
	my $pid = $self->starcluster()->launchBalancer();
	$self->logDebug("pid", $pid);
	
	return if not defined $pid;

	$self->updateClusterPid($username, $cluster, $pid);	
}

method getEc2KeyFiles {
#### SET PRIVATE KEY AND PUBLIC CERT FILE LOCATIONS	
	my $object = {};

	#### USE ADMIN KEY FILES IF USER IS IN ADMINUSER LIST
	my $username	=	$self->username();
	my $adminkey 	=	$self->getAdminKey($username);
	$self->logDebug("adminkey", $adminkey);

	my $adminuser = $self->conf()->getKey("agua", "ADMINUSER");
	if ( $adminkey ) {
		$object->{privatekey} =  $self->getEc2PrivateFile($adminuser);
		$object->{publiccert} =  $self->getEc2PublicFile($adminuser);
	}
	else {
		$object->{privatekey} =  $self->getEc2PrivateFile($username);
		$object->{publiccert} =  $self->getEc2PublicFile($username);
	}	
	$self->logDebug("privatekey", $object->{privatekey});
	$self->logDebug("publiccert", $object->{publiccert});

	return $object;
}

method stopStarCluster {
	my $username	=	$self->username();
	my $cluster		=	$self->cluster();
	
	#### UPDATE CLUSTER STATUS TO 'stopping'
	$self->updateClusterStatus($username, $cluster, 'stopping');
	
	#### LOAD STARCLUSTER IF NOT LOADED
	$self->logDebug("Doing self->loadStarCluster($username, $cluster) if not loaded");
	$self->loadStarCluster($username, $cluster) if not $self->starcluster()->loaded();
	
	#### STOP STARCLUSTER AND BALANCER
	$self->logDebug("Doing starcluster->stopCluster()");
	my $stopped = $self->starcluster()->stopCluster();	
	
	if ( $stopped ) {
		#### UPDATE CLUSTER STATUS TO 'running'
		$self->updateClusterStatus($username, $cluster, 'stopped');
	
		return 1;
	}
	else {
		#### SET CLUSTER STATUS TO 'error'
		$self->updateClusterStatus($username, $cluster, 'stopping error');
		
		return 0;
	}
}

#### STAGES
method setStages ($username, $cluster, $json, $project, $workflow) {
	$self->logGroup("Agua::Workflow::setStages");
	$self->logDebug("username", $username);
	$self->logDebug("cluster", $cluster);
	$self->logDebug("project", $project);
	$self->logDebug("workflow", $workflow);
	
	#### SET STAGES
	my $stages = $self->getStages($json);
	
	#### VERIFY THAT PREVIOUS STAGE HAS STATUS completed
	return 0 if not $self->checkPrevious($stages, $json);

	#### GET STAGE PARAMETERS FOR THESE STAGES
	$stages = $self->setStageParameters($stages, $json);

	#### SET START AND STOP
	my ($start, $stop) = $self->setStartStop($stages, $json);
	
	#### GET SETUID
	my $setuid = $self->json()->{setuid};
	$self->logDebug("setuid", $setuid) if defined $setuid;

	#### GET FILEROOT
	my $fileroot = $self->getFileroot($username);	
	
	#### SET FILE DIRS
	my ($scriptsdir, $stdoutdir, $stderrdir) = $self->setFileDirs($fileroot, $project, $workflow);
	$self->logDebug("scriptsdir", $scriptsdir);
	
	#### WORKFLOW PROCESS ID
	my $workflowpid = $self->workflowpid();

	#### CLUSTER, QUEUE AND QUEUE OPTIONS
	my $queue = $self->queueName($username, $project, $workflow);
	my $queue_options = $self->json()->{queue_options};
	
	#### SET OUTPUT DIR
	my $outputdir =  "$fileroot/$project/$workflow/";

	#### GET ENVIRONMENT VARIABLES
	my $envars = $self->getEnvars($username, $cluster);

	#### GET MONITOR
	$self->logDebug("BEFORE monitor = self->updateMonitor()");
	my $monitor = $self->updateMonitor();
	$self->logDebug("AFTER monitor = self->updateMonitor()");

	#### LOAD STAGE OBJECT FOR EACH STAGE TO BE RUN
	my $stageobjects = [];    
	for ( my $counter = $start; $counter < $stop + 1; $counter++ ) {
		my $stage = $$stages[$counter];
		
		#### QUIT IF NO STAGE PARAMETERS
		$self->logError("stageparameters not defined for stage $stage->{name}") and exit if not defined $stage->{stageparameters};
		
		my $stage_number = $counter + 1;

		#### SET MONITOR
		$stage->{monitor} = $monitor;

		#### SET SGE ENVIRONMENT VARIABLES
		$stage->{envars} = $envars;
		
        #### SET SCRIPT, STDOUT AND STDERR FILES
		$stage->{scriptfile} 	=	"$scriptsdir/$stage->{number}-$stage->{name}.sh";
        $stage->{stdoutfile} 	=	"$stdoutdir/$stage->{number}-$stage->{name}.stdout";
        $stage->{stderrfile} 	= 	"$stderrdir/$stage->{number}-$stage->{name}.stderr";
		$stage->{cluster}		=  	$cluster;
		$stage->{workflowpid}	=	$workflowpid;
		$stage->{db}			=	$self->db();
		$stage->{conf}			=  	$self->conf();
		$stage->{fileroot}		=  	$fileroot;
		$stage->{queue}			=  	$queue;
		$stage->{queue_options}	=  	$queue_options;
		$stage->{outputdir}		=  	$outputdir;
		$stage->{setuid}		=  	$setuid;
		$stage->{qsub}			=  	$self->conf()->getKey("cluster", "QSUB");
		$stage->{qstat}			=  	$self->conf()->getKey("cluster", "QSTAT");
		$stage->{envars}		=  	$self->envars();

		#### ADD LOG INFO
		$stage->{SHOWLOG} 		=	$self->SHOWLOG();
		$stage->{PRINTLOG} 		=	$self->PRINTLOG();
		$stage->{logfile} 		=	$self->logfile();

		my $stageobject = Agua::Stage->new($stage);

		#### NEAT PRINT STAGE
		#$stageobject->toString();

		push @$stageobjects, $stageobject;
	}

	#### SET self->stages()
	$self->stages($stageobjects);
	$self->logDebug("final no. stageobjects", scalar(@$stageobjects));
	
	$self->logGroupEnd("Agua::Workflow::setStages");

	return $stageobjects;
}

method setFileDirs ($fileroot, $project, $workflow) {
	$self->logDebug("fileroot", $fileroot);
	$self->logDebug("project", $project);
	$self->logDebug("workflow", $workflow);
	my $scriptsdir = $self->createDir("$fileroot/$project/$workflow/scripts");
	my $stdoutdir = $self->createDir("$fileroot/$project/$workflow/stdout");
	my $stderrdir = $self->createDir("$fileroot/$project/$workflow/stdout");

	#### CREATE DIRS	
	`mkdir -p $scriptsdir` if not -d $scriptsdir;
	`mkdir -p $stdoutdir` if not -d $stdoutdir;
	`mkdir -p $stderrdir` if not -d $stderrdir;
	$self->logError("Cannot create directory scriptsdir: $scriptsdir") and exit if not -d $scriptsdir;
	$self->logError("Cannot create directory stdoutdir: $stdoutdir") and exit if not -d $stdoutdir;
	$self->logError("Cannot create directory stderrdir: $stderrdir") and exit if not -d $stderrdir;		

	return $scriptsdir, $stdoutdir, $stderrdir;
}

method runStages ($stages) {
	$self->logDebug("no. stages", scalar(@$stages));

	for ( my $stage_counter = 0; $stage_counter < @$stages; $stage_counter++ )
	{
		my $stage = $$stages[$stage_counter];
		my $stage_number = $stage->number();
		my $stage_name = $stage->name();
		
		####  RUN STAGE
		$self->logDebug("Running stage $stage_number", $stage_name);
		my ($completed, $error) = $stage->run();
		$self->logDebug("completed", $completed);
		$self->logDebug("error", $error);
		$error = "" if not defined $error;
		$completed = "" if not defined $completed;
		$self->logDebug("Ended running stage $stage_counter", $completed);

		#### STOP IF THIS STAGE DIDN'T COMPLETE SUCCESSFULLY
		#### ALL APPLICATIONS MUST RETURN '0' FOR SUCCESS)
		$completed = 0 if $completed eq "0";
		if ( $completed == 0 ) {
			$self->logDebug("Stage $stage_number: '$stage_name' completed successfully");
		}
		else {
            $self->logDebug("Setting status to 'error'");
            $stage->setStatus('error');
            $self->logDebug("After setting status");
			$self->logError("Stage $stage_number. $stage_name failed. code: $completed. error: $error");
			return 0;
		}
	}    
	
	return 1;
}

method getWorkflowStages ($json) {
	$self->logDebug("Agua::Workflow::getWorkflowStages(json)");
    
	my $username = $json->{username};
    my $project = $json->{project};
    my $workflow = $json->{workflow};

	#### CHECK INPUTS
    $self->logError("Agua::Workflow::getWorkflowStages    username not defined") if not defined $username;
    $self->logError("Agua::Workflow::getWorkflowStages    project not defined") if not defined $project;
    $self->logError("Agua::Workflow::getWorkflowStages    workflow not defined") if not defined $workflow;

	#### GET ALL STAGES FOR THIS WORKFLOW
    my $query = qq{SELECT * FROM stage
WHERE username ='$username'
AND project = '$project'
AND workflow = '$workflow'
ORDER BY number};
    $self->logDebug("$query");
    my $stages = $self->db()->queryhasharray($query);
	$self->logError("stages not defined for username: $username") and return if not defined $stages;	

	$self->logDebug("stages:");
	foreach my $stage ( @$stages )
	{
		my $stage_number = $stage->number();
		my $stage_name = $stage->name();
		my $stage_submit = $stage->submit();
		print "Agua::Workflow::runStages    stage $stage_number: $stage_name [submit: $stage_submit]";
	}

	return $stages;
}

method checkPrevious ($stages, $json) {
	#### IF NOT STARTING AT BEGINNING, CHECK IF PREVIOUS STAGE COMPLETED SUCCESSFULLY
	
	my $start = $json->{start};
    $start--;	
	$self->logDebug("start", $start);
	return 1 if $start <= 0;

	my $stage_number = $start - 1;
	$$stages[$stage_number]->{appname} = $$stages[$stage_number]->{name};
	$$stages[$stage_number]->{appnumber} = $$stages[$stage_number]->{number};
	my $keys = ["username", "project", "workflow", "name", "number"];
	my $where = $self->db()->where($$stages[$stage_number], $keys);
	my $query = qq{SELECT status FROM stage $where};
	my $status = $self->db()->query($query);
	
	return 1 if not defined $status or not $status;
	$self->logError("previous stage not completed: $stage_number") and return 0 if $status ne "completed";
	return 1;
}

method setStageParameters ($stages, $json) {
	#### GET THE PARAMETERS FOR THE STAGES WE WANT TO RUN
	$self->logDebug("Agua::Workflow::setStageParameters(stages, json)");
	#### GET THE PARAMETERS FOR THE STAGES WE WANT TO RUN
	my $start = $json->{start};
    $start--;
	for ( my $i = $start; $i < @$stages; $i++ )
	{
		$$stages[$i]->{appname} = $$stages[$i]->{name};
		$$stages[$i]->{appnumber} = $$stages[$i]->{number};
		my $keys = ["username", "project", "workflow", "appname", "appnumber"];
		my $where = $self->db()->where($$stages[$i], $keys);
		my $query = qq{SELECT * FROM stageparameter
$where AND paramtype='input'};
		my $stageparameters = $self->db()->queryhasharray($query);
		$$stages[$i]->{stageparameters} = $stageparameters;
	}
	
	return $stages;
}

method setStartStop ($stages, $json) {
	$self->logDebug("Agua::Workflow::setStartStop(stages, json)");
	$self->logDebug("No. stages: " . scalar(@$stages));
	$self->logError("stages is empty") and return if not scalar(@$stages);

	my $start = $self->start();
	$self->logError("json->{start} not defined") and return if not defined $start;
	$self->logError("start is non-numeric: $start") and return if $start !~ /^\d+$/;
	$start--;

	$self->logError("Runner starting stage $start is greater than the number of stages") and return if $start > @$stages;

	my $stop = $self->stop();
	if ( defined $stop and $stop ne '' ) {
		$self->logError("stop is non-numeric: $stop") and return if $stop !~ /^\d+$/;
		$self->logError("Runner stoping stage $stop is greater than the number of stages") and return if $stop > @$stages;
		$stop--;
	}
	else {
		$stop = scalar(@$stages) - 1;
	}
	
	if ( $start > $stop ) {
		$self->logError("start ($start) is greater than stop ($stop)");
	}

	$self->logDebug("Setting start: $start");	
	$self->logDebug("Setting stop: $stop");	
	
	$self->start($start);
	$self->stop($stop);
	
	return ($start, $stop);
}

#### QUEUE
method deleteDefaultMaster {
	#### DELETE 'master' FROM ADMIN, SUBMIT AND EXECUTION HOST LISTS
	$self->logDebug("");
	my $output = $self->removeFromAllHosts("master");
	$self->logDebug("output", $output);
	
	$self->deleteAdminHost("master");
	$self->deleteSubmitHost("master");
	$self->deleteExecutionHost("master");
}

method setMasterInfo ($username, $cluster, $qmasterport, $execdport) {
#### 1. SET qmaster_info
#### 2. SET HEADNODE common/act_qmaster
#### 3. SET MASTER common/act_qmaster
#### 4. UPDATE MASTER dnsname IN @allhosts GROUP hostlist

	$self->logDebug("username", $username);

	#### LOAD STARCLUSTER IF NOT ALREADY LOADED
	$self->loadStarCluster($username, $cluster) if not $self->starcluster()->loaded();

	#### QUIT IF CLUSTER DOES NOT EXIST
	my $exists = $self->starcluster()->instance()->exists();
	$self->logDebug("exists", $exists);
	return if not $exists;

	#### GET STORED AND CURRENT MASTER EXTERNAL FQDN
	my $newexternalfqdn = $self->starcluster()->instance()->master()->externalfqdn();
	$self->logDebug("newexternalfqdn", $newexternalfqdn);
	my $masterinfo = $self->getHeadnodeMasterInfo($cluster);
	$self->logDebug("masterinfo", $masterinfo);
	my $oldexternalfqdn = $masterinfo->{externalfqdn};
	$self->logDebug("oldexternalfqdn", $oldexternalfqdn);
	
	#### QUIT IF MASTER INSTANCE HAS NOT CHANGED
	return $masterinfo if $newexternalfqdn eq $oldexternalfqdn;
	
	#### GET NEW MASTER INSTANCE INFO
	my $instanceinfo	= $self->getMasterInstanceInfo($username, $cluster);
	$self->logDebug("instanceinfo", $instanceinfo);
	my $newname 		= $instanceinfo->{internalfqdn};
	my $internalip 		= $instanceinfo->{internalip};
	my $instanceid 		= $instanceinfo->{instanceid};
	my $externalfqdn 	= $instanceinfo->{externalfqdn};
	my $externalip 		= $instanceinfo->{externalip};
	$self->logDebug("newname", $newname);
	
	#### 1. SET HEADNODE qmaster_info
	$self->_setHeadnodeMasterInfo($cluster, $newname, $internalip, $instanceid, $externalfqdn, $externalip);
	
	#### 2. UPDATE HEADNODE act_qmaster 
	$self->setHeadnodeActQmaster($cluster, $newname);
	
	#### 3. UPDATE MASTER act_qmaster 
	$self->setMasterActQmaster($cluster, $newname);
	
	#### 4. UPDATE MASTER dnsname IN @allhosts GROUP hostlist
	$self->addToAllHosts($newname);
	
	##### 5. UPDATE MASTER dnsname IN SUBMIT HOSTS LIST
	#$self->setSgeSubmitHosts($cluster, $qmasterport, $execdport, $oldname, $newname) if $oldname ne $newname;
	
	##### RESTART HEADNODE SGE EXECD
	#$self->restartHeadnodeSge($execdport);
	
	return $instanceinfo;
}

method createQueue ($username, $cluster, $project, $workflow, $envars) {
	$self->logCaller("");
	$self->logDebug("project", $project);
	$self->logDebug("workflow", $workflow);
	$self->logDebug("username", $username);
	$self->logDebug("cluster", $cluster);
	
	$self->logError("Agua::Workflow::createQueue    project not defined") if not defined $project;
	$self->logError("Agua::Workflow::createQueue    workflow not defined") if not defined $workflow;

	my $headip = $self->getHeadnodeInternalIp();
	$self->logDebug("headip", $headip);
	
	#### SET VARIABLES
	$self->username($username);
	$self->cluster($cluster);
	$self->project($project);
	$self->workflow($workflow);
	$self->qmasterport($envars->{qmasterport});
	$self->execdport($envars->{execdport});
	$self->sgecell($envars->{sgecell});
	$self->sgeroot($envars->{sgeroot});
	
	#### SET CONFIGFILE
	my $adminkey = $self->getAdminKey($username);
	$self->logDebug("adminkey", $adminkey);
	my $adminuser = $self->conf()->getKey("agua", "ADMINUSER");
	my $configfile;
	$configfile =  $self->setConfigFile($username, $cluster) if not $adminkey;
	$configfile =  $self->setConfigFile($username, $cluster, $adminuser) if $adminkey;
	$self->configfile($configfile);
	
	#### SET INSTANCETYPE
	my $clusterobject = $self->getCluster($username, $cluster);
	my $instancetype = $clusterobject->{instancetype};
	$self->logDebug("instancetype", $instancetype);
	$self->instancetype($instancetype);
	
	#### CREATE QUEUE
	my $queue = $self->queueName($username, $project, $workflow);
	my $qmasterport = $envars->{qmasterport};
	my $execdport = $envars->{execdport};
	$self->logDebug("queue", $queue);
	$self->logDebug("qmasterport", $qmasterport);
	$self->logDebug("execdport", $execdport);

	#### SET QUEUE
	$self->logDebug("Doing self->setQueue($queue)\n");
	$self->setQueue($queue, $qmasterport, $execdport);

	$self->logGroupEnd("Agua::Workflow::createQueue    COMPLETED");
}

method deleteQueue ($project, $workflow, $username, $cluster, $envars) {
	$self->logError("Agua::Workflow::deleteQueue    project not defined") if not defined $project;
	$self->logError("Agua::Workflow::deleteQueue    workflow not defined") if not defined $workflow;

	#### GET ENVIRONMENT VARIABLES FOR THIS CLUSTER/CELL
	my $args = $self->json();
	$args->{qmasterport} = $envars->{qmasterport};
	$args->{execdport} = $envars->{execdport};
	$args->{sgecell} = $envars->{sgecell};
	$args->{sgeroot} = $envars->{sgeroot};

	#### DETERMINE WHETHER TO USE ADMIN KEY FILES
	my $adminkey = $self->getAdminKey($username);
	$self->logDebug("adminkey", $adminkey);
	return if not defined $adminkey;
	my $adminuser = $self->conf()->getKey("agua", "ADMINUSER");
	$args->{configfile} =  $self->setConfigFile($username, $cluster) if not $adminkey;
	$args->{configfile} =  $self->setConfigFile($username, $cluster, $adminuser) if $adminkey;
	$self->logDebug("configfile", $args->{configfile});

	#### ADD CONF OBJECT	
	$args->{conf} = $self->conf();

	$self->logDebug("args", $args);
	
	#### RUN starcluster.pl TO GENERATE KEYPAIR FILE IN .starcluster DIR
	my $queue = $self->queueName($username, $project, $workflow);
	$self->logDebug("queue", $queue);

#    #### SET STARCLUSTER
#	my $starcluster = $self->starcluster();
#	$starcluster = $self->starcluster()->load($args) if not $self->starcluster()->loaded();
    
    #### UNSET QUEUE
#    $self->logDebug("Doing StarCluster->unsetQueue($queue)");
#	$starcluster->unsetQueue($queue);
    $self->logDebug("Doing self->unsetQueue($queue)");
	$self->unsetQueue($queue);
}

#### QUEUE
method setQueue ($queue, $qmasterport, $execdport) {
	$self->logDebug("DOING slots = self->setSlotNumber(self->instancetype())");
	my $slots = $self->setSlotNumber($self->instancetype());
	$slots = 1 if not defined $slots;
	$self->logDebug("slots", $slots);
	$self->logDebug("self->qmasterport", $self->qmasterport());
	
	my $parameters = {
		qname			=>	$queue,
		slots			=>	$slots,
		shell			=>	"/bin/bash",
		hostlist		=>	"\@allhosts",
		load_thresholds	=>	"np_load_avg=20"
	};

	my $queuefile = $self->getQueuefile("queue-$queue");
	$self->logDebug("queuefile", $queuefile);
	
	my $exists = $self->queueExists($queue, $qmasterport, $execdport);
	$self->logDebug("exists", $exists);
	
	$self->_addQueue($queue, $queuefile, $parameters) if not $exists;
}

method unsetQueue ($queue) {
	my $queuefile = $self->getQueuefile("queue-$queue");
	$self->logDebug("queuefile", $queuefile); 
	
	$self->_removeQueue($queue, $queuefile);
}

method setPE ($pe, $queue) {
 	$self->logDebug("pe", $pe);
 	$self->logDebug("queue", $queue);

	my $slots = $self->setSlotNumber($self->instancetype());
	$self->logDebug("slots", $slots); 

	my $pefile = $self->getQueuefile("pe-$pe");
	$self->logDebug("pefile", $pefile); 
	my $queuefile = $self->getQueuefile("queue-$queue");
	$self->logDebug("queuefile", $queuefile); 

	$self->addPE($pe, $pefile, $slots);

	#$self->addPEToQueue($pe, $queue, $queuefile);

	$self->logDebug("Completed"); 
}

### QUEUE MONITOR
method setMonitor {
	$self->logCaller("");
	
	my $monitor = Agua::Monitor::SGE->new({
		conf		=>	$self->conf(),
		whoami		=>	$self->whoami(),
		pid			=>	$self->workflowpid(),
		db			=>	$self->db(),
		username	=>	$self->username(),
		project		=>	$self->project(),
		workflow	=>	$self->workflow(),
		cluster		=>	$self->cluster(),
		envars		=>	$self->envars(),

		logfile		=>	$self->logfile(),
		SHOWLOG		=>	$self->SHOWLOG(),
		PRINTLOG	=>	$self->PRINTLOG()
	});
	
	$self->monitor($monitor);
}
method updateMonitor {
	$self->logDebug("");
	$self->monitor()->load ({
		pid			=>	$self->workflowpid(),
		conf 		=>	$self->conf(),
		whoami		=>	$self->whoami(),
		db			=>	$self->db(),
		username	=>	$self->username(),
		project		=>	$self->project(),
		workflow	=>	$self->workflow(),
		cluster		=>	$self->cluster(),
		envars		=>	$self->envars(),
		logfile		=>	$self->logfile(),
		SHOWLOG		=>	$self->SHOWLOG(),
		PRINTLOG	=>	$self->PRINTLOG()
	});

	return $self->monitor();
}


#### STOP WORKFLOW
method stopWorkflow {
    $self->logDebug("");
    
	my $json         =	$self->json();

	#### SET EXECUTE WORKFLOW COMMAND
    my $bindir = $self->conf()->getKey("agua", 'INSTALLDIR') . "/cgi-bin";

    my $username = $json->{username};
    my $project = $json->{project};
    my $workflow = $json->{workflow};
	my $cluster = $json->{cluster};
	my $start = $json->{start};
    $start--;
    $self->logDebug("project", $project);
    $self->logDebug("start", $start);
    $self->logDebug("workflow", $workflow);
    
	#### GET ALL STAGES FOR THIS WORKFLOW
    my $query = qq{SELECT * FROM stage
WHERE username ='$username'
AND project = '$project'
AND workflow = '$workflow'
AND status='running'
ORDER BY number};
	$self->logDebug("$query");
	my $stages = $self->db()->queryhasharray($query);
	$self->logDebug("stages", $stages);

	#### EXIT IF NO PIDS
	$self->logError("No running stages in $project.$workflow") and return if not defined $stages;

	#### WARNING IF MORE THAN ONE STAGE RETURNED (SHOULD NOT HAPPEN 
	#### AS STAGES ARE EXECUTED CONSECUTIVELY)
	$self->logError("More than one running stage in $project.$workflow. Continuing with stopWorkflow") if scalar(@$stages) > 1;

	my $submit = $$stages[0]->{submit};
	$self->logDebug("submit", $submit);

	my $messages;
	if ( defined $submit and $submit )
	{
		$self->logDebug("Doing killClusterJob(stages)");
		$messages = $self->killClusterJob($project, $workflow, $username, $cluster, $stages);
	}
	else
	{
		$self->logDebug("Doing killLocalJob(stages)");
		$messages = $self->killLocalJob($stages);
	}
	
	#### UPDATE STAGE STATUS TO 'stopped'
	my $update_query = qq{UPDATE stage
SET status = 'stopped'
WHERE username = '$username'
AND project = '$project'
AND workflow = '$workflow'
AND status = 'running'
};
	$self->logDebug("$update_query\n");
	my $success = $self->db()->do($update_query);
	$self->logError("Could not update stages for $project.$workflow") and exit if not $success;
	$self->logStatus("Updated stages for $project.$workflow");
}

method killClusterJob ($project, $workflow, $username, $cluster, $stages) {
=head2

	SUBROUTINE		killClusterJob
	
	PURPOSE
	
		1. CANCEL THE JOB IDS OF ANY RUNNING STAGE OF THE WORKFLOW:
		
			1. IN THE CASE OF A SINGLE JOB, CANCEL THAT JOB ID
			
			2. IF AN APPLICATION IS RUNNING LOCALLY AND SUBMITTING JOBS TO THE
			
			CLUSTER, KILL ITS PROCESS ID AND CANCEL ANY JOBS IT HAS SUBMITTED
			
			(SHOULD BE REGISTERED IN THE stagejobs TABLE)

=cut
    $self->logDebug("Agua::Workflow::killClusterJob(stages)");
    
    $self->logDebug("stages", $stages);

        my $json         =	$self->json();
	
	foreach my $stage ( @$stages )
	{
		#### KILL PROCESS THAT SUBMITTED JOBS TO CLUSTER
		$self->killPid($stage->{workflowpid});
		#$self->killPid($stage->{stagepid});
	}

	#### DELETE THE QUEUE CONTAINING ALL JOBS FOR THIS WORKFLOW
	my $envars = $self->getEnvars($username, $cluster);
	$self->deleteQueue($project, $workflow, $username, $cluster, $envars);
}



method cancelJob ($jobid) {
=head2

	SUBROUTINE		cancelJob
	
	PURPOSE
	
		CANCEL A CLUSTER JOB BY JOB ID
		
=cut
	$self->logDebug("Agua::Workflow::cancelJob(jobid)");
	my $canceljob = $self->conf()->getKey("cluster", 'CANCELJOB');
	$self->logDebug("jobid", $jobid);
	
	my $command = "$canceljob $jobid";

	return `$command`;
}

method killLocalJob ($stages) {
#### 1. 'kill -9' THE PROCESS IDS OF ANY RUNNING STAGE OF THE WORKFLOW
#### 2. INCLUDES STAGE PID, App PARENT PID AND App CHILD PID)

    $self->logDebug("stages", $stages);
	my $messages = [];
	foreach my $stage ( @$stages )
	{
		#### OTHERWISE, KILL ALL PIDS
		push @$messages, $self->killPid($stage->{childpid}) if defined $stage->{childpid};
		push @$messages, $self->killPid($stage->{parentpid}) if defined $stage->{parentpid};
		push @$messages, $self->killPid($stage->{stagepid}) if defined $stage->{stagepid};
		push @$messages, $self->killPid($stage->{workflowpid}) if defined $stage->{workflowpid};
	}

	return $messages;
}

#### GET STATUS
method getStatus {
#### 1. GET STAGES STATUS FROM stage TABLE
#### 2. GET CLUSTER STATUS IF CLUSTER IS RUNNING
#### 3. USER'S PROJECT WORKFLOW QUEUE STATUS IF CLUSTER IS RUNNING
#### 4. UPDATE stage TABLE WITH JOB STATUS FROM QSTAT IF CLUSTER IS RUNNING
#### 5. RETURN VALUES FROM 1, 2 AND 3 IN A HASH

    $self->logDebug("");
	
    my $username	= 	$self->username();
    my $cluster 	= 	$self->cluster();
    my $project 	= 	$self->project();
    my $workflow 	= 	$self->workflow();
    my $json  		=	$self->json();
    my $start 		= 	$json->{start};

	$self->logError("username not defined") and exit if not defined $self->username();
	$self->logError("cluster not defined") and exit if not defined $self->cluster();
	$self->logError("project not defined") and exit if not defined $self->project();
	$self->logError("workflow not defined") and exit if not defined $self->workflow();
	$self->logError("json not defined") and exit if not defined $self->json();

    $self->logDebug("project", $project);
    $self->logDebug("workflow", $workflow);

	my $status = $self->_getStatus($username, $start, $project, $workflow, $json);
	#$self->logDebug("status", $status);
	
	#### PRINT STATUS
    require JSON;
    my $jsonObject = JSON->new();
    my $statusJson = $jsonObject->encode($status);
    print $statusJson;
}

method _getStatus ($username, $start, $project, $workflow, $json) {
=head2

OUTPUT

	{
		stagestatus 	=> 	{
			project		=>	String,
			workflow	=>	String,
			stages		=>	HashArray,
			status		=>	String
		},
		clusterstatus	=>	{
			cluster		=>	String,
			status		=>	String,
			list		=>	String,
			log			=> 	String,
			balancer	=>	String
		},
		queuestatus		=>	{
			queue		=>	String,
			status		=>	String			
		}
	}

=cut

    $self->logDebug("username", $username);
    $self->logDebug("start", $start);
    $self->logDebug("project", $project);
    $self->logDebug("workflow", $workflow);
    $self->logDebug("json", $json);

	#### GET STAGES FROM stage TABLE
    my $query = qq{SELECT *, NOW() AS now
FROM stage
WHERE username ='$username'
AND project = '$project'
AND workflow = '$workflow'
ORDER BY number
};
	$self->logDebug("query", $query);
    my $stages = $self->db()->queryhasharray($query);
	$self->logDebug("stages", $stages);
	
	#### QUIT IF stages NOT DEFINED
	$self->logError("No stages with run status for username: $username, project: $project, workflow: $workflow from start: $start") and exit if not defined $stages;

	#### RETRIEVE CLUSTER INFO FROM clusterworkflow TABLE
	my $cluster = $self->getClusterByWorkflow($username, $project, $workflow);
	$self->logDebug("cluster", $cluster);
	$cluster = "" if not defined $cluster;
	$self->cluster($cluster);

    #### PRINT stages AND RETURN IF CLUSTER IS NOT DEFINED
	return $self->_getStatusLocal($username, $project, $workflow, $stages) if not $cluster;

	#### OTHERWISE, GET CLUSTER STATUS
	return $self->_getStatusCluster($username, $cluster, $project, $workflow, $stages);
}

method _getStatusCluster($username, $cluster, $project, $workflow, $stages) {
	$self->logDebug("");	

	#### GET WORKFLOW STATUS
	my $clusterworkflow = $self->getClusterWorkflow($username, $cluster, $project, $workflow);
	$self->logDebug("clusterworkflow", $clusterworkflow);
	my $workflowstatus = $self->getWorkflowStatus($username, $project, $workflow);	
	$self->logDebug("workflowstatus", $workflowstatus);

	#### SET DEFAULT VALUES
	my $stagestatus = {
		project		=>	$project,
		workflow	=>	$workflow,
		status		=>	$workflowstatus,
		stages		=>	$stages
	};
	
	#### SET EMPTY STATUS
	my $clusterstatus = $self->_emptyClusterStatus($cluster, "none");	
	my $queuestatus = $self->_emptyQueueStatus();
	
	my $status = {};
	$status->{stagestatus} 		= $stagestatus;
	$status->{clusterstatus} 	= $clusterstatus;
	$status->{queuestatus} 		= $queuestatus;
	
	#### RETURN EMPTY CLUSTER/QUEUE STATUS IF WORKFLOW IS EMPTY OR CLUSTER IS PENDING
	return $status if $workflowstatus eq "";

	#### GET CLUSTER STATUS
	my $currentstatus  =	$self->getClusterStatus($username, $cluster);
	$self->logDebug("currentstatus", $currentstatus);

	#### RETURN EMPTY CLUSTER/QUEUE STATUS IF NO CURRENT CLUSTER STATUS
	return $status if not defined $currentstatus;

	#### RETURN CURRENT CLUSTER STATUS AND EMPTY QUEUE STATUS
	#### IF CLUSTER IS PENDING
	$status->{clusterstatus} = $currentstatus;
	return $status if $currentstatus->{status} eq "cluster pending";

	#### CHECK IF CLUSTER IS RUNNING	
	my $starcluster 		= 	$self->loadStarCluster($username, $cluster);
	my $clusterrunning 		= 	$self->starcluster()->isRunning();
	$self->logDebug("clusterrunning", $clusterrunning);

	#### RETURN CURRENT CLUSTER STATUS AND EMPTY QUEUE STATUS
	#### IF CLUSTER IS NOT RUNNING
	return $status if not $clusterrunning;
	
	#### GET MASTER INFO
	my $masterinfo = $self->getHeadnodeMasterInfo($cluster);
	$self->logDebug("masterinfo", $masterinfo);
	return $status if not defined $masterinfo;
	
	### SET MASTER OPS SSH
	my $mastername	=	$masterinfo->{internalfqdn};
	$self->logDebug("mastername", $mastername);	
	$self->logDebug("DOING setMasterOpsSsh($mastername)");
	$self->setMasterOpsSsh($mastername);
	
	#### DETECT IF MASTER IS READY BY CONNECTING VIA SSH
	$self->logDebug("DOING masterConnect()");
	my $timeout = 10;
	my $masterconnect = $self->masterConnect($timeout);
	$self->logDebug("masterconnect", $masterconnect);
	
	#### REFRESH CLUSTER STATUS
	$clusterstatus = $self->clusterStatus();
	$self->logDebug("clusterstatus", $clusterstatus);
	
	#### IF CLUSTER IS RUNNING AND MASTER IS ACCESSIBLE,
	#### GET QUEUE STATUS
	if ( $clusterrunning and $masterconnect ) {
	
		#### GET qstat QUEUE STATUS FOR THIS USER'S PROJECT WORKFLOW
		my $monitor = $self->updateMonitor();
		$queuestatus = $monitor->queueStatus();
		$self->logDebug("queuestatus", $queuestatus);
	
		#### UPDATE stage TABLE WITH JOB STATUS FROM QSTAT
		$self->updateStageStatus($monitor, $stages);
	}	
	
	$status->{stagestatus} 		= $stagestatus;
	$status->{clusterstatus} 	= $clusterstatus;
	$status->{queuestatus} 		= $queuestatus;
	
	return $status;
}

method getWorkflowStatus ($username, $project, $workflow) {
	$self->logDebug("workflow", $workflow);

	my $object = $self->getWorkflow($username, $project, $workflow);
	$self->logDebug("object", $object);
	return if not defined $object;
	
	return $object->{status};
}

#### MASTER NODE METHODS
method masterConnect ($timeout) {
	$self->logDebug("timeout", $timeout);	
	my $command = "hostname";
	$self->logDebug("command", $command);
	my $connect = $self->master()->ops()->timeoutCommand($command, $timeout);
	$self->logDebug("connect", $connect);
	
	return 0 if not $connect;
	return 1;
}

method _getStatusLocal ($username, $project, $workflow, $stages) {
#### PRINT stages AND RETURN IF CLUSTER IS NOT DEFINED
#### I.E., JOB WAS SUBMITTED LOCALLY. 
#### NB: THE stage TABLE SHOULD BE UPDATED BY THE PROCESS ON EXIT.

	$self->logDebug("username", $username);
	
	my $workflowobject = $self->getWorkflow($username, $project, $workflow);
	$self->logDebug("workflowobject", $workflowobject);
	my $status = $workflowobject->{status} || '';
	my $stagestatus 	= 	{
		project		=>	$project,
		workflow	=>	$workflow,
		stages		=>	$stages,
		status		=>	$status
	};
	$self->logDebug("stagestatus", $stagestatus);
	
	my $clusterstatus 	=	$self->_emptyClusterStatus(undef, undef);
	$self->logDebug("clusterstatus", $clusterstatus);
	my $queuestatus		=	$self->_emptyQueueStatus();
	$self->logDebug("queuestatus", $queuestatus);
	
	return {
		stagestatus 	=> 	$stagestatus,
		clusterstatus	=>	$clusterstatus,
		queuestatus		=>	$queuestatus
	};	
}

method _emptyClusterStatus ($cluster, $status) {
	$cluster = "" if not defined $cluster;
	$status = "" if not defined $status;
	
	return {
		cluster		=> 	$cluster,
		status		=>	$status,
		list		=>	"NO CLUSTER OUTPUT",
		log			=> 	"NO CLUSTER OUTPUT",
		balancer	=>	""
	};
}

method _emptyQueueStatus {
	return {
		queue		=>	"NO QUEUE INFORMATION AVAILABLE",
		status		=>	""
	};
}

method updateStageStatus($monitor, $stages) {
#### UPDATE stage TABLE WITH JOB STATUS FROM QSTAT
	my $statusHash = $monitor->statusHash();
	$self->logDebug("statusHash", $statusHash);	
	foreach my $stage ( @$stages ) {
		my $stagejobid = $stage->{stagejobid};
		next if not defined $stagejobid or not $stagejobid;
		$self->logDebug("pid", $stagejobid);

		#### GET STATUS
		my $status;
		if ( defined $statusHash )
		{
			$status = $statusHash->{$stagejobid};
			next if not defined $status;
			$self->logDebug("status", $status);

			#### SET TIME ENTRY TO BE UPDATED
			my $datetime = "queued";
			$datetime = "started" if defined $status and $status eq "running";

			$datetime = "completed" if not defined $status;
			$status = "completed" if not defined $status;
		
			#### UPDATE THE STAGE ENTRY IF THE STATUS HAS CHANGED
			if ( $status ne $stage->{status} )
			{
				my $query = qq{UPDATE stage
SET status='$status',
$datetime=NOW()
WHERE username ='$stage->{username}'
AND project = '$stage->{project}'
AND workflow = '$stage->{workflow}'
AND number='$stage->{number}'};
				$self->logDebug("$query");
				my $result = $self->db()->do($query);
				$self->logDebug("status update result", $result);
			}
		}
	}	
}

method clusterStatus {
	$self->logDebug("");
	my $username = $self->username();
	my $cluster = $self->cluster();
	$self->logError("cluster not defined") and return if not $cluster;
	
	#### LOAD STARCLUSTER
	$self->loadStarCluster($username, $cluster) if not $self->starcluster()->loaded();
	my $clusterlines = 20;
	my $balancerlog = $self->starcluster()->balancerLog($clusterlines);
	my $clusterlog = $self->starcluster()->clusterLog($clusterlines);
	
	#### GET CLUSTER LIST
	my $configfile	=	$self->setConfigFile($username, $cluster);
	my $command = "starcluster -c $configfile listclusters $cluster";
	$self->logDebug("command", $command);
	my ($clusterlist) = $self->head()->ops()->runCommand($command);
	my $status = "unknown";
	if ( $clusterlist =~ /Cluster nodes:\s+master\s+(\S+)/ ) {
		$status = $1;
	}

	my $clusterstatus = {
		cluster		=>	$cluster,
		status		=>	$status,
		list		=>	$clusterlist,
		log			=>	$clusterlog,
		balancer	=>	$balancerlog,
	};
	
	return $clusterstatus;
}

#### UPDATE
method updateWorkflowStatus ($username, $cluster, $project, $workflow, $status) {
	my $table ="workflow";
	my $hash = {
		username	=>	$username,
		cluster		=>	$cluster,
		project		=>	$project,
		name		=>	$workflow,
		status		=>	$status,
	};
	$self->logDebug("hash", $hash);
	my $required_fields = ["username", "project", "name"];
	my $set_hash = {
		status		=>	$status
	};
	my $set_fields = ["status"];
	
	my $success = $self->db()->_updateTable($table, $hash, $required_fields, $set_hash, $set_fields);
	$self->logDebug("success", $success);
	
	return $success;
}

method updateClusterWorkflow ($username, $cluster, $project, $workflow, $status) {
 	$self->logDebug("");

	my $query = qq{SELECT * FROM clusterworkflow
WHERE username='$username'
AND project='$project'
AND workflow='$workflow'};
	$self->logDebug("$query");
	my $exists = $self->db()->query($query);
	$self->logDebug("clusterworkflow entry exists", $exists);

	#### SET STATUS
	my $success;
	if ( defined $exists ) {
		$query = qq{UPDATE clusterworkflow
SET status='$status'
WHERE username='$username'
AND project='$project'
AND workflow='$workflow'};
		$self->logDebug("$query");
		$success = $self->db()->do($query);
	}
	else {
		my $object = {
			status		=>	$status,
			username	=>	$username,
			cluster		=>	$cluster,
			project		=>	$project,
			workflow	=>	$workflow
		};

		#### DO THE ADD
		my $required_fields = [ "username", "project", "workflow" ];
		my $inserted_fields = $self->db()->fields("clusterworkflow");
		$success = $self->_addToTable("clusterworkflow", $object, $required_fields, $inserted_fields);
		$self->logDebug("insert success", $success)  if defined $success;

		my $success = $self->db()->do($query);
	}

	return 1 if defined $success and $success;
	return 0;
}

method updateClusterPid ($username, $cluster, $pid) {
	$self->logDebug("pid", $pid);
	#### CHANGE STATUS TO COMPLETED IN clusterstatus TABLE
	
	my $query = qq{UPDATE clusterstatus
SET pid='$pid'
WHERE username='$username'
AND cluster='$cluster'};
	my $success = $self->db()->do($query);
	return 1 if defined $success and $success;
	return 0;
}

method updateClusterStatus ($username, $cluster, $status) {
 	$self->logDebug("username", $username);
	$self->logDebug("cluster", $cluster);
	$self->logDebug("status", $status);
	
	my $query = qq{SELECT 1 FROM clusterstatus
WHERE username='$username'
AND cluster='$cluster'};
	$self->logDebug("$query");
	my $exists = $self->db()->query($query);
	$self->logDebug("clusterstatus entry exists", $exists);

	#### SET STATUS
	my $now = $self->db()->now();
	my $success;
	if ( defined $exists ) {
		$query = qq{UPDATE clusterstatus
SET polled=$now,
status='$status'
WHERE username='$username'
AND cluster='$cluster'};
		$self->logDebug("$query");
		$success = $self->db()->do($query);
	}
	else {
		$query = qq{SELECT *
FROM cluster
WHERE username='$username'
AND cluster='$cluster'};
		$self->logDebug("$query");
		my $object = $self->db()->queryhash($query);
		$object->{started} = $now;
		$object->{polled} = $now;
		$object->{status} = $status;
		
		my $required = ["username", "cluster"];
		my $required_fields = ["username", "cluster"];
	
		#### CHECK REQUIRED FIELDS ARE DEFINED
		my $not_defined = $self->db()->notDefined($object, $required_fields);
		$self->logError("undefined values: @$not_defined") and return if @$not_defined;
	
		#### DO THE ADD
		my $inserted_fields = $self->db()->fields("clusterstatus");
		$success = $self->_addToTable("clusterstatus", $object, $required_fields, $inserted_fields);
		$self->logDebug("insert success", $success)  if defined $success;
	}

	return 1 if defined $success and $success;
	return 0;
}

#### START BALANCER
method startBalancer ($clusterobject) {
    $self->logDebug("Workflow::startBalancer(clusterobject)");
    $self->logDebug("clusterobject", $clusterobject);
	
    my $username    = $self->username();
    my $cluster    = $self->cluster();
    
	my $starcluster = $self->loadStarCluster($username, $cluster);
	$starcluster->launchBalancer();
}

#### STOP CLUSTER
method stopCluster {
	$self->logDebug("Agua::Workflow::stopCluster()");

    my $json         =	$self->json();
	my $username 	=	$json->{username};
	my $cluster 	=	$json->{cluster};

	$self->logDebug("cluster", $json->{cluster});
	$self->logDebug("username", $json->{username});

	$self->logDebug("Doing starcluster = StarCluster->new(json)");
	my $starcluster = $self->loadStarCluster($username, $cluster);

	$self->logError("Cluster $cluster is not running: $cluster") and return if not $starcluster->isRunning();
	
	$self->logDebug("Doing StarCluster->stop()");
	$starcluster->stopCluster();
}

#### STOP CLUSTER
method startCluster {
	my $username 	=	$self->username();
	my $cluster 	=	$self->cluster();
	$self->logDebug("username", $username);
	$self->logDebug("cluster", $cluster);
	
	$self->logDebug("Doing self->loadStarCluster()");
	my $starcluster = $self->loadStarCluster($username, $cluster);

	$self->logError("Cluster $cluster is already running: $cluster") and return if $starcluster->isRunning();
	
	$self->logDebug("Doing StarCluster->start()");
	my $started = $starcluster->startCluster();
	
	$self->logError("Failed to start cluster", $cluster) and exit if not $started;
	$self->logStatus("Started cluster", $cluster);
}

#### ADD AWS INFORMATION
method addAws {
#### SAVE USER'S AWS AUTHENTICATION INFORMATION TO aws TABLE
	my $username 	= 	$self->username();
    my $json 		=	$self->json();
	$self->logDebug("username", $username);
	$self->logDebug("json", $json);
    
	my $clusterrunning = $self->clusterWorkflowIsRunning($username);
	$self->logDebug("clusterrunning", $clusterrunning);
	$self->logError("Can't add AWS credentials (and regenerate keypair file) while any cluster is running. Please stop all workflows running on clusters and retry", $clusterrunning) and exit if $clusterrunning;

	#### REMOVE 
	$self->_removeAws({username => $username});

	#### ADD TO TABLE
	my $success = $self->_addAws($json);
 	$self->logError("Failed to add AWS table entry") and return if not defined $success or not $success;

	##### REMOVE WHITESPACE
	$json->{ec2publiccert} =~ s/\s+//g;
	$json->{ec2privatekey} =~ s/\s+//g;
	
	#### PRINT KEY FILES
	$self->logDebug("DOING self->printKeyFiles()");
	my $privatekey	=	$json->{ec2privatekey};
	my $publiccert	=	$json->{ec2publiccert};
	$self->printEc2KeyFiles($username, $privatekey, $publiccert);
	
	#### GENERATE KEYPAIR FILE FROM KEYS
	$self->logDebug("Doing self->generateClusterKeypair()");
	$self->generateClusterKeypair();
	
 	$self->logStatus("Added AWS credentials");
	return;
}

method clusterWorkflowIsRunning ($username) {
	my $query = qq{SELECT 1 from clusterworkflow
WHERE username='$username'
AND status='running'};
	$self->logDebug("query", $query);
    my $result =  $self->db()->query($query);
	$self->logDebug("result", $result);
	
	return 0 if not defined $result or not $result;
	return 1;
}
#### STARCLUSTER KEYS
method generateClusterKeypair {
	$self->logDebug("");
	
	my $username 		=	$self->username();
	my $login 			=	$self->login();
	my $hubtype 		=	$self->hubtype();
	$self->logDebug("username", $username);
	$self->logDebug("login", $login);
	$self->logDebug("hubtype", $hubtype);

	#### SET KEYNAME
	my $keyname 		= 	"$username-key";
	$self->logDebug("keyname", $keyname);

	#### SET PRIVATE KEY AND PUBLIC CERT FILE LOCATIONS	
	my $privatekey	=	$self->getEc2PrivateFile($username);
	my $publiccert 	= 	$self->getEc2PublicFile($username);

	$self->logDebug("privatekey", $privatekey);
	$self->logDebug("publiccert", $publiccert);

    #### SET STARCLUSTER	
	my $starcluster = $self->starcluster();
	$starcluster = $self->starcluster()->load(
		{
			privatekey	=>	$privatekey,
			publiccert	=>	$publiccert,
			username	=>	$username,
			keyname		=>	$keyname,
			conf		=>	$self->conf(),
			SHOWLOG		=>	$self->SHOWLOG(),
			PRINTLOG	=>	$self->PRINTLOG(),
			logfile		=>	$self->logfile()
		}
	) if not $self->starcluster()->loaded();
	
	#### GENERATE KEYPAIR FILE IN .starcluster DIR
	$self->logDebug("Doing starcluster->generateKeypair()");
	$starcluster->generateKeypair();
}

### NEW/ADD CLUSTER
method newCluster {
#### CREATE NEW CELL DIR
	$self->logDebug("");
    my $json 		=	$self->json();
	my $username 	=	$json->{username};
	my $cluster 	=	$json->{cluster};
	$self->logError("Cluster $cluster already exists") and return if $self->_isCluster($username, $cluster);
	my $success = $self->_addCluster();
	$self->logError("Could not add cluster $json->{cluster} into cluster table. Returning") and return if not defined $success or not $success;

	$self->setSgePorts();
	
	#### ENSURE DB HANDLE STAYS ALIVE
	$self->setDbh();

	#### CREATE STARCLUSTER config FILE
	$self->logDebug("Creating configfile and copying celldir");
	$self->createConfigFile($username, $cluster);	
	$self->_createCellDir();	
}

method addCluster {
#### MODIFY EXISTING CLUSTER. DO NOT CREATE NEW CELL DIR
 	$self->logDebug("");
    my $data 		=	$self->json();
	my $username 	=	$self->json()->{username};
	my $cluster 	=	$data->{cluster};

	$self->_removeCluster();	
	my $success = $self->_addCluster();
	return if not defined $success;
	$self->logStatus("Could not add cluster $data->{cluster}") and return if not $success;

	#### FORK: PARENT MESSAGES AND QUITS, CHILD DOES THE WORK
	if ( my $child_pid = fork() ) 
	{
		#### PARENT EXITS
	
		#### SET InactiveDestroy ON DATABASE HANDLE
		$self->db()->dbh()->{InactiveDestroy} = 1;
		my $dbh = $self->db()->dbh();
		undef $dbh;
	
		$self->logStatus("Updated cluster $data->{cluster}");
		exit(0);
	}
	else
	{
		#### CHILD CONTINUES THE JOB
	
		#### CLOSE OUTPUT SO CGI SCRIPT WILL QUIT
		close(STDOUT);  
		close(STDERR);
		close(STDIN);
		
		#### ENSURE DB HANDLE STAYS ALIVE
		$self->setDbh();
	
		#### CREATE STARCLUSTER config FILE
		$self->logDebug("Doing     self->createConfigFile($username, $cluster)");
		$self->createConfigFile($username, $cluster);
	}
}

method createConfigFile ($username, $cluster) {
	$self->logDebug("");
	
	#### LOAD STARCLUSTER IF NOT LOADED
	$self->loadStarCluster($username, $cluster) if not $self->starcluster()->loaded();
	
	#### SET UNIQUE WORKFLOW
	$self->starcluster()->project($self->project());
	$self->starcluster()->workflow($self->workflow());

	#### CREATE CONFIG FILE
	$self->starcluster()->createConfig();
}


#### SET OPS
method setHead {
	my $instance = Agua::Instance->new({
		conf		=>	$self->conf(),
		SHOWLOG		=>	$self->SHOWLOG(),
		PRINTLOG	=>	$self->PRINTLOG()
	});

	$self->head($instance);	
}

method setMaster {
	my $instance = Agua::Instance->new({
		conf		=>	$self->conf(),
		SHOWLOG		=>	$self->SHOWLOG(),
		PRINTLOG	=>	$self->PRINTLOG()
	});

	$self->master($instance);	
}

}	#### Agua::Workflow


