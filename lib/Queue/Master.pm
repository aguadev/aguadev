use MooseX::Declare;

=head2

PURPOSE

	Run tasks on worker nodes using task queue

	Use queues to communicate between master and nodes:
	
		WORKERS: REPORT STATUS TO MASTER
	
		MASTER: DIRECT WORKERS TO:
		
			- DEPLOY APPS
			
			- PROVIDE WORKFLOW STATUS
			
			- STOP/START WORKFLOWS

=cut

use strict;
use warnings;

class Queue::Master with (Logger, Exchange, Agua::Common::Database, Agua::Common::Timer, Agua::Common::Project, Agua::Common::Stage, Agua::Common::Workflow, Agua::Common::Util) {

#####////}}}}}

{

# Integers
has 'log'	=>  ( isa => 'Int', is => 'rw', default => 2 );
has 'printlog'	=>  ( isa => 'Int', is => 'rw', default => 5 );
has 'maxjobs'	=>  ( isa => 'Int', is => 'rw', default => 30 );
has 'sleep'		=>  ( isa => 'Int', is => 'rw', default => 10 );

# Strings
has 'metric'	=> ( isa => 'Str|Undef', is => 'rw', default	=>	"cpus" );
has 'user'		=> ( isa => 'Str|Undef', is => 'rw', required	=>	0 );
has 'pass'		=> ( isa => 'Str|Undef', is => 'rw', required	=>	0 );
has 'host'		=> ( isa => 'Str|Undef', is => 'rw', required	=>	0 );
has 'vhost'		=> ( isa => 'Str|Undef', is => 'rw', required	=>	0 );
has 'modulestring'	=> ( isa => 'Str|Undef', is => 'rw', default	=> "Agua::Workflow" );
has 'rabbitmqctl'	=> ( isa => 'Str|Undef', is => 'rw', default	=> "/usr/sbin/rabbitmqctl" );

# Objects
has 'modules'	=> ( isa => 'ArrayRef|Undef', is => 'rw', lazy	=>	1, builder	=>	"setModules");
has 'conf'		=> ( isa => 'Conf::Yaml', is => 'rw', required	=>	0 );
has 'synapse'	=> ( isa => 'Synapse', is => 'rw', lazy	=>	1, builder	=>	"setSynapse" );
has 'db'		=> ( isa => 'Agua::DBase::MySQL', is => 'rw', lazy	=>	1,	builder	=>	"setDbh" );
has 'jsonparser'=> ( isa => 'JSON', is => 'rw', lazy	=>	1, builder	=>	"setJsonParser" );
has 'virtual'	=> ( isa => 'Any', is => 'rw', lazy	=>	1, builder	=>	"setVirtual" );
has 'duplicate'	=> ( isa => 'HashRef|Undef', is => 'rw');

}

#### EXTERNAL MODULES
use FindBin qw($Bin);
use Test::More;
use POSIX qw(ceil floor);

#### INTERNAL MODULES
use Virtual::Openstack;
use Synapse;
use Time::Local;
use Virtual;

#####////}}}}}

method BUILD ($args) {
	$self->initialise($args);	
}

method initialise ($args) {
	#$self->logDebug("args", $args);
	#$self->manage();
}

method manage {
	#my $shutdown	=	$self->conf()->getKey("agua:SHUTDOWN", undef);
	#$self->logDebug("shutdown", $shutdown);
	#while ( not $shutdown eq "true" ) {
	while ( 1 ) {
	
		my $tenants		=	$self->getTenants();
		#$self->logDebug("tenants", $tenants);
		foreach my $tenant ( @$tenants ) {
			my $username	=	$tenant->{username};
			
			#### GET PROJECTS
			my $projects	=	$self->getRunningUserProjects($username);
			#$self->logDebug("projects", $projects);

			foreach my $project	( @$projects ) {
				#$self->logDebug("project", $project);
	
				#### GET WORKFLOWS
				my $workflows	=	$self->getWorkflowsByProject({
					name		=>	$project,
					username	=>	$username
				});
				#$self->logDebug("workflows", $workflows);
				next if not defined $workflows or not @$workflows;
				print "Master::manage    project $project workflows:\n";
				foreach my $workflow ( @$workflows ) {
					print "Master::manage    $project [$workflow->{number}] $workflow->{name}\n";
				}
				
				#### BALANCE INSTANCES
				$self->balanceInstances($workflows);
	
				#### MAINTAIN QUEUES
				$self->maintainQueues($workflows);
			}
			
		}
		
		#### PAUSE
		$self->pause();

		##### GET SYSTEM SHUTDOWN
		#$shutdown	=	$self->updateShutdown();
	}
	
	return 1;
}

method getTenants {
	my $query	=	qq{SELECT *
FROM tenant};
	#$self->logDebug("query", $query);

	return $self->db()->queryhasharray($query);
}

method pause {
	my $sleep	=	$self->sleep();
	print "Queue::Master::pause    Sleeping $sleep seconds\n";
	sleep($sleep);
}

method getProjects ($username) {
	return if not defined $username;
	return $self->db()->queryarray("SELECT * FROM project WHERE username='$username'");
}
#### BALANCE INSTANCES
method balanceInstances ($workflows) {
	print "\n\n#### DOING balanceInstances\n";
	#$self->logDebug("workflows", $workflows);

	my $stopping	=	$self->stoppingInstances();
	$self->logDebug("stopping", $stopping);
	return if $stopping;
	
	my $username	=	$$workflows[0]->{username};
	#$self->logDebug("username", $username);

	# 1. CALCULATE AVERAGE DURATION OF completed SAMPLES IN EACH WORKFLOW/QUEUE
	my $durations	=	$self->getDurations($workflows);
	$self->logDebug("durations", $durations);
	
	#### NARROW DOWN TO ONLY QUEUES WITH CLUSTERS
	$workflows	=	$self->clusterWorkflows($workflows);	
	#$self->logDebug("cluster only workflows", $workflows);

	# 2. GET CURRENT COUNTS OF RUNNING INSTANCES PER QUEUE
	my $currentcounts	=	$self->getCurrentCounts($username);
	$self->logDebug("currentcounts", $currentcounts);

	#### GET REQUIRED RESOURCES FOR QUEUE INSTANCES (CPUs, RAM, ETC.)
	my $instancetypes	=	$self->getInstanceTypes($workflows);
	#$self->logDebug("instancetypes", $instancetypes);

	# 3. IF LATEST RUNNING WORKFLOW HAS NO COMPLETED JOBS, SET
	#	INSTANCE COUNT FOR NEXT WORKFLOW TO cluster->minnodes
	my $latestcompleted =	$self->getLatestCompleted($workflows);
	$self->logDebug("latestcompleted", $latestcompleted);

	# 4. GET TOTAL QUOTA FOR RESOURCE (DEFAULT: NO. CPUS)
	my $metric	=	$self->metric();	
	my $quota	=	$self->getResourceQuota($username, $metric);
	$self->logDebug("quota", $quota);

#### DEBUG

$quota		=	4;
$self->logDebug("DEBUG quota", $quota);

#### DEBUG


	my $resourcecounts	=	[];
	my $instancecounts	=	[];
	#### SET DEFAULT INSTANCE COUNTS FOR FIRST WORKFLOW IF:
	#### 1. PROJECT WORKFLOWS HAVE JUST STARTED RUNNING, OR
	#### 2. SAMPLES HAVE JUST BEEN LOADED
	#### 
	if ( not defined $latestcompleted or not %$durations ) {
		print "#### DOING getDefaultResource\n";
		my $resourcecount	=	$self->getDefaultResource($$workflows[0], $instancetypes, $quota);
		$self->logDebug("resourcecount", $resourcecount);

		my $metric	=	$self->metric();

		my $queuename	=	$self->getQueueName($$workflows[0]);
		my $resource	=	$instancetypes->{$queuename}->{$metric};
		my $instancecount	=	ceil($resourcecount/$resource);
		$instancecount		=	1 if $instancecount < 1;
		$self->logDebug("instancecount", $instancecount);
		
		$resourcecounts	=	[ $resourcecount ];
		$instancecounts	=	[ $instancecount ];
	}
	else {
		print "#### DOING getResourceCounts\n";
		##### GET CURRENT COUNT OF VMS PER QUEUE (queueample STATUS 'started')
		##### ASSUMES ONE VM PER TASK
		#my $currentcounts=	$self->getCurrentCounts();
		#$self->logDebug("currentcounts", $currentcounts);
		
		# 2. BALANCE COUNTS BASED ON DURATION
		#
		$resourcecounts	=	$self->getResourceCounts($workflows, $durations, $instancetypes, $quota);
		$instancecounts	=	$self->getInstanceCounts($workflows, $instancetypes, $resourcecounts);
		#$self->logDebug("instancecounts", $instancecounts);

		#### IF NOT ALL WORKFLOWS HAVE RUNNING INSTANCES,
		#### SET DEFAULT INSTANCE COUNTS FOR 2ND TO LAST RUNNING WORKFLOW 
		#### IF IT HAS NO COMPLETED JOBS TO PROVIDE DURATION INFO
		my $lateststarted	=	$self->getLatestStarted($workflows);
		$self->logDebug("lateststarted", $lateststarted);
		$lateststarted		=	$latestcompleted if not defined $lateststarted;
	
		if ( $lateststarted != $latestcompleted ) {
			$instancecounts	=	$self->adjustCounts($workflows, $resourcecounts, $lateststarted, $quota);
		}
	}
	$self->logDebug("resourcecounts", $resourcecounts);
	$self->logDebug("instancecounts", $instancecounts);

	$self->addRemoveNodes($workflows, $instancecounts, $currentcounts);

	#   TAILOUT AT END OF SAMPLE RUN:
	#   NB: maxJobs <= NUMBER OF REMAINING SAMPLES FOR THE WORKFLOW
}

method stoppingInstances {
	my $query	=	qq{SELECT * FROM instance
WHERE status='stopping'
};
	my $stopping	=	$self->db()->queryhasharray($query);
	$self->logDebug("stopping", $stopping);
	
	if ( defined $stopping ) {
		print "Stopping instances:\n" ;
		foreach my $stopinstance ( @$stopping ) {
			print "$stopinstance->{queue}: $stopinstance->{host}\n";
		}
	}

	return 1 if defined $stopping and @$stopping;
	return 0;
}

#### ADD NODES
method addRemoveNodes ($workflows, $instancecounts, $currentcounts) {
	#$self->logDebug("workflows", $workflows);
	$self->logDebug("instancecounts", $instancecounts);
	
	for ( my $i = 0; $i < @$instancecounts; $i++ ) {
		my $instancecount =	$$instancecounts[$i];
		$self->logDebug("instancecount [$i]", $instancecount);

		my $queuename	=	$self->getQueueName($$workflows[$i]);
		$self->logDebug("queuename [$i]", $queuename);
		
		my $currentcount =	$currentcounts->{$queuename} || 0;
		$self->logDebug("currentcount [$i]", $currentcount);
		
		my $difference	=	$instancecount - $currentcount;
		$self->logDebug("difference	= $instancecount - $currentcount");
		$self->logDebug("difference [$i]", $difference);
		
		if ( $difference > 0 ) {
			$self->addNodes($$workflows[$i], $difference);
		}
		elsif ( $difference < 0 ) {
			$self->deleteNodes($$workflows[$i], abs($difference));
		}
	}	
}
method addNodes ($workflow, $number) {
	my $username	=	$workflow->{username};
	my $project		=	$workflow->{project};
	my $name		=	$workflow->{workflow};
	
	my ($authfile, $amiid, $instancetype, $userdatafile, $keypair)	=	$self->getVirtualInputs($workflow);
	
	for ( my $i = 0; $i < $number; $i++ ) {

		my $hostname	=	$self->randomHostname($name);
		$self->logDebug("hostname", $hostname);
	
		my $id	=	$self->virtual()->launchNode($authfile, $amiid, $number, $instancetype, $userdatafile, $keypair, $hostname);
		#$self->logDebug("id", $id);
		$self->logError("failed to add node") and return 0 if not defined $id;

		my $success	=	0;
		$success	=	1 if $id =~ /^[0-9a-z\-]+$/;
		$self->logDebug("failed to add node") and return 0 if not $success;
		
		$self->addHostInstance($workflow, $hostname, $id);
	}
	
	return 1;
}

method addHostInstance ($workflow, $hostname, $id) {
	#$self->logDebug("workflow", $workflow);
	#$self->logDebug("hostname", $hostname);
	#$self->logDebug("id", $id);
	
	my $time			=	$self->getMysqlTime();

	my $data	=	{};
	$data->{username}	=	$workflow->{username};
	$data->{queue}		=	$self->getQueueName($workflow);
	$data->{host}		=	$hostname;
	$data->{id}			=	$id;
	$data->{status}		=	"running";
	$data->{time}		=	$time;
	#$self->logDebug("data", $data);
	
	my $keys	=	[ "username", "queue", "host" ];
	my $notdefined	=	$self->notDefined($data, $keys);	
	$self->logDebug("notdefined", $notdefined) and return if @$notdefined;

	#### ADD TO TABLE
	my $table		=	"instance";
	my $fields		=	$self->db()->fields($table);
	$self->_addToTable($table, $data, $keys, $fields);
}

method printConfig ($workflowobject) {
	#		GET PACKAGE INSTALLDIR
	my $stages			=	$self->getStagesByWorkflow($workflowobject);
	my $object			=	$$stages[0];
	my $package			=	$object->{package};
	my $version			=	$object->{version};
	$self->logDebug("package", $package);
	#$self->logDebug("stages[0]", $object);	

	my $installdir		=	$self->getInstallDir($package);
	$self->logDebug("installdir", $installdir);
	$object->{installdir}=	$installdir;
	
	my $basedir			=	$self->conf()->getKey("agua", "INSTALLDIR");
	$object->{basedir}	=	$basedir;

	#		GET TEMPLATE
	my $templatefile	=	$self->setTemplateFile($installdir, $version);
	#$self->logDebug("templatefile", $templatefile);
	
	#		SET PREDATA AND POSTDATA
	my $predata			=	$self->getPreData($installdir, $version);
	$self->logDebug("predata", $predata);
	my $postdata			=	$self->getPostData($installdir, $version);
	$self->logDebug("postdata", $postdata);

	#		PRINT TEMPLATE
	my $username		=	$object->{username};
	my $project			=	$object->{project};
	my $workflow		=	$object->{workflow};
	
	my $virtualtype		=	$self->conf()->getKey("agua", "VIRTUALTYPE");
	my $targetfile		= 	undef;
	if ( $virtualtype eq "openstack" ) {
		my $targetdir	=	"$basedir/conf/.openstack";
		`mkdir -p $targetdir` if not -d $targetdir;
		$targetfile		=	"$targetdir/$username.$project.$workflow.sh";
	}
	elsif ( $virtualtype eq "vagrant" ) {
		my $targetdir	=	"$basedir/conf/.vagrant/$username.$project.$workflow";
		`mkdir -p $targetdir` if not -d $targetdir;
		$targetfile		=	"$targetdir/Vagrantfile";
	}
	$self->logDebug("targetfile", $targetfile);
	
	$self->logDebug("object", $object);
	
	$self->virtual()->createConfig($object, $templatefile, $targetfile, $predata, $postdata);
	
	return $targetfile;
}

method getInstallDir ($packagename) {
	$self->logDebug("packagename", $packagename);

	my $packages = $self->conf()->getKey("packages:$packagename", undef);
	$self->logDebug("packages", $packages);
	my $version	=	undef;
	foreach my $key ( %$packages ) {
		$version	=	$key;
		last;
	}

	my $installdir	=	$packages->{$version}->{INSTALLDIR};
	$self->logDebug("installdir", $installdir);
	
	return $installdir;
}

method getPreData ($installdir, $version) {
	my $predatafile		=	"$installdir/data/sh/predata";
	$self->logDebug("predatafile", $predatafile);
	
	return "" if not -f $predatafile;
	
	my $predata			=	$self->getFileContents($predatafile);

	return $predata;
}

method getPostData ($installdir, $version) {
	my $postdatafile		=	"$installdir/data/sh/postdata";
	$self->logDebug("postdatafile", $postdatafile);
	
	return "" if not -f $postdatafile;
	
	my $postdata			=	$self->getFileContents($postdatafile);

	return $postdata;
}

method setTemplateFile ($installdir, $version) {
	$self->logDebug("installdir", $installdir);
	
	return "$installdir/data/tmpl/userdata.tmpl";
}

method randomHostname ($name) {
	
	my $length	=	10;
	my $random	=	$self->randomHexadecimal($length);	
	my $randomname	=	$name . "-" . $random;
	#$self->logDebug("randomname", $randomname);
	while ( $self->hostExists($randomname) ) {
		$random	=	$self->randomHexadecimal($length);	
		$randomname	=	$name . "-" . $random;
	}

	return $randomname;	
}

method hostExists ($host) {
	my $query	=	qq{SELECT 1 FROM heartbeat
WHERE host='$host'};
	#$self->logDebug("query", $query);
	
	my $success	=	$self->db()->query($query);
	#$self->logDebug("success", $success);
	
	return 0 if not defined $success;
	return 1;
}

method randomHexadecimal ($length) {
	#$self->logDebug("length", $length);
	
	my $random	=	"";
	for ( 0 .. $length ) {
		$random .= sprintf "%01X", rand(0xf);
	}
	$random	=	lc($random);
	#$self->logDebug("random", $random);
	
	return $random;
}

method getVirtualInputs ($workflow) {
	my $username	=	$workflow->{username};
	
	my $cluster		=	$self->getQueueName($workflow);

	#	1. GET amiid, instancetype FOR cluster = username.project.workflow
	my $clusterobject	=	$self->getQueueCluster($workflow);
	my $amiid			=	$clusterobject->{amiid};
	my $instancetype	=	$clusterobject->{instancetype};
	$self->logDebug("amiid", $amiid);
	$self->logDebug("instancetype", $instancetype);
	
	#	2. PRINT USERDATA FILE
	my $userdatafile	=	$self->printConfig($workflow);
	$self->logDebug("userdatafile", $userdatafile);
		
	# 	3. PRINT OPENSTACK AUTHENTICATION *-openrc.sh FILE
	my $virtualtype		=	$self->conf()->getKey("agua", "VIRTUALTYPE");
	my $authfile;
	if ( $virtualtype eq "openstack" ) {
		$authfile	=	$self->printAuth($username);
	}
	$self->logDebug("authfile", $authfile);
	
	#### GET OPENSTACK AUTH INFO
	my $tenant		=	$self->getTenant($username);
	$self->logDebug("tenant", $tenant);
	my $keypair		=	$tenant->{keypair};
	
	return ($authfile, $amiid, $instancetype, $userdatafile, $keypair);
}

method printAuth ($username) {
	$self->logDebug("username", $username);
	
	#### SET TEMPLATE FILE
	#### NB: 
	my $installdir		=	$self->conf()->getKey("agua", "INSTALLDIR");
	my $templatefile	=	"$installdir/bin/install/resources/openstack/openrc.sh";

	#### GET OPENSTACK AUTH INFO
	my $tenant		=	$self->getTenant($username);
	$self->logDebug("tenant", $tenant);

	#### GET AUTH FILE
	my $authfile		=	$self->getAuthFile($username, $tenant);

	#### PRINT FILE
	return	$self->virtual()->printAuthFile($tenant, $templatefile, $authfile);
}

method getAuthFile ($username, $tenant) {
	#$self->logDebug("username", $username);
	
	my $installdir		=	$self->conf()->getKey("agua", "INSTALLDIR");
	my $targetdir		=	"$installdir/conf/.openstack";
	`mkdir -p $targetdir` if not -d $targetdir;
	my $tenantname		=	$tenant->{os_tenant_name};
	#$self->logDebug("tenantname", $tenantname);
	my $authfile		=	"$targetdir/$tenantname-openrc.sh";
	$self->logDebug("authfile", $authfile);

	return	$authfile;
}

method updateInstanceStatus ($id, $status) {
	$self->logNote("id", $id);
	$self->logNote("status", $status);
	
	my $time		=	$self->getMysqlTime();
	my $query		=	qq{UPDATE instance
SET status='$status',
TIME='$time'
WHERE id='$id'
};
	return $self->db()->do($query);
}

#### DELETE NODES
method deleteNodes ($workflow, $number) {
	my $queuename	=	$self->getQueueName($workflow);
	my $username	=	$workflow->{username};
	my $query	=	qq{SELECT * FROM instance
WHERE username='$username'
AND queue='$queuename'
AND status='running'
LIMIT $number};
	#$self->logDebug("query", $query);
	
	my $instances	=	$self->db()->queryhasharray($query);
	foreach my $instance ( @$instances ) {
		$self->updateInstanceStatus($instance->{id}, "stopping");
		$self->shutdownInstance($workflow, $instance->{host});
	}
}
method shutdownInstance ($workflow, $id) {
	#$self->logDebug("id", $id);

	my $stages			=	$self->getStagesByWorkflow($workflow);
	my $object			=	$$stages[0];
	my $package			=	$object->{package};
	my $installdir		=	$self->getInstallDir($package);
	my $version			=	$object->{version};
	my $teardownfile	=	$self->setTearDownFile($installdir, $version);
	#$self->logDebug("teardownfile", $teardownfile);
	my $teardown			=	$self->getFileContents($teardownfile);
	#$self->logDebug("teardown", substr($teardown, 0, 100));
	
	my $data	=	{
		host			=>	$id,
		mode			=>	"doShutdown",
		teardown		=>	$teardown,
		teardownfile	=>	$teardownfile
	};
	
	my $key	=	"update.host.status";
	$self->sendTopic($data, $key);
}

method setTearDownFile($installdir, $version) {
	return "$installdir/data/sh/teardown.sh";
}

#### RESOURCES
method getDefaultResource ($queue, $instancetypes, $quota) {
	$self->logDebug("queue", $queue);

	#### SET FIRST NODES TO MAX NO SAMPLES COMPLETED
	my $queuename		=	$self->getQueueName($queue);
	my $instancetype		=	$instancetypes->{$queuename};
	my $metric			=	$self->metric();
	my $resource	=	$instancetype->{$metric};
	$self->logDebug("queuename", $queuename);
	$self->logDebug("resource", $resource);
	$self->logDebug("instancetype", $instancetype);

	#### SET RESOURCE QUOTA
	my $resourcequota	=	$quota;
	$self->logDebug("resourcequota", $resourcequota);

	my $cluster	=	$self->getQueueCluster($queue);
	$self->logDebug("cluster", $cluster);
	my $maxnodes		=	$cluster->{maxnodes};
	$self->logDebug("maxnodes", $maxnodes);
	
	my $resourcecount 	=	$resource * $maxnodes;
	$self->logDebug("resourcecount", $resourcecount);

	my $username		=	$queue->{username};
	
	if ( $resourcecount > $resourcequota ) {
		$self->logDebug("resourcecount $resourcecount > resourcequota $resourcequota. Setting to resourcequota ($resourcequota)");
		$resourcecount = $resourcequota;
	}
	$self->logDebug("resourcecount", $resourcecount);
	
	return $resourcecount;
}

method clusterWorkflows ($workflows) {
	#$self->logDebug("workflows", $workflows);

	my $clusterworkflows	=	[];
	for ( my $i = 0; $i < @$workflows; $i++ ) {
		#$self->logDebug("workflows[$i]", $$workflows[$i]);

		my $cluster	=	$self->getQueueCluster($$workflows[$i]);
		#$self->logDebug("cluster", $cluster);
		if ( defined $cluster ) {
			push @$clusterworkflows, $$workflows[$i];			
		}
	}
	##$self->logDebug("CLUSTER ONLY clusterworkflows", $clusterworkflows);
	#if ( defined $clusterworkflows ) {
	#	print "cluster workflows:\n";
	#	foreach my $clusterworkflow ( @$clusterworkflows ) {
	#		print "$clusterworkflow->{name}\n";
	#	}
	#}

	return $clusterworkflows;
}

method getTenant ($username) {
	my $query	=	qq{SELECT *
FROM tenant
WHERE username='$username'};
	#$self->logDebug("query", $query);

	return $self->db()->queryhash($query);
}

method adjustCounts ($queues, $resourcecounts, $lateststarted, $quota) {

#### SET DEFAULT INSTANCE COUNTS FOR NEXT WORKFLOW IF IT HAS NO
#### COMPLETED JOBS TO PROVIDE DURATION INFO

	$self->logDebug("resourcecounts", $resourcecounts);
	my $nextqueue	=	$$queues[$lateststarted];
	$self->logDebug("nextqueue", $nextqueue);
	my $nextqueuename	=	$self->getQueueName($nextqueue);
	$self->logDebug("nextqueuename", $nextqueuename);
	
	my $cluster	=	$self->getQueueCluster($nextqueue);
	$self->logDebug("cluster", $cluster);
	my $min			=	$cluster->{minnodes};
	$self->logDebug("min", $min);

	my $instancetypes	=	$self->getInstanceTypes($queues);
	my $instancetype	=	$instancetypes->{$nextqueuename};
	$self->logDebug("instancetype", $instancetype);
	my $metric		=	$self->metric();
	my $resource	=	$instancetype->{$metric};
	
	my $total	=	0;
	foreach my $resourcecount ( @$resourcecounts ) {
		$total	+=	$resourcecount;
	}
	$self->logDebug("total", $total);
	
	#### IF 
	if ( $total == 0 ) {
		$$resourcecounts[$lateststarted] = $quota;
	}
	else {
		my $latestcount	=	($min * $resource);
		my $newtotal	=	$total - $latestcount;
		$self->logDebug("newtotal", $newtotal);
		
		if ( $newtotal == $total ) {
			$$resourcecounts[$lateststarted] = $quota;
		}
		else {
			foreach my $resourcecount ( @$resourcecounts ) {
				last if $resourcecount == 0;
				$resourcecount	=	$resourcecount * ($newtotal/$total);
			}
			$$resourcecounts[$lateststarted] = $latestcount;
		}		
	}
	$self->logDebug("FINAL resourcecounts", $resourcecounts);
	
	$self->logDebug("RETURNING RERUN OF self->getInstanceCounts");
	return $self->getInstanceCounts($queues, $instancetypes, $resourcecounts);
}

method getResourceCounts ($queues, $durations, $instancetypes, $quota) {

=head2	SUBROUTINE	getResourceCounts

=head2	PURPOSE
	
	Allocate resources (e.g., CPUs) to each workflow

=head2	ALGORITHM

	At max throughput:
	[1] T = t1 = t2 = t3
	Where T = total throughput, tx = throughput for workflow x

	Given N is a finite resource (e.g., number of VMs)
	[2] N = n1 + n2 + n3 + ... + nX
	Where X = total no. of workflows, nx = no. of VMs for workflow x

	Define:
	[3] tx = dx/nx
	Where tx = throughput for workflow x, dx = duration of workflow x, nx = number of resources used in workflow x (e.g., VMs)

	STEPS:

		1. Solve for n1 using [1], [2] and [3]
		n1 = N/(1 + d2/d1 + d3/d1 + ... + dx/d1)

		2. Calculate n2, n3, etc. using [1] and [3] (d1/n1 = d2/n2)
		n2 = (n1 . d2) / d1

=cut
	
	#$self->logDebug("username", $username);
	#$self->logDebug("queues", $queues);
	#$self->logDebug("durations", $durations);
	#$self->logDebug("instancetypes", $instancetypes);
	
	#### GET INDEX OF LATEST RUNNING WORKFLOW
	my $lateststarted 	=	$self->getLatestStarted($queues);
	$self->logDebug("lateststarted", $lateststarted);
	$lateststarted		=	$self->getLatestCompleted($queues) if not defined $lateststarted;

	#### GET FIRST DURATION
	my $firstqueue		=	$self->getQueueName($$queues[0]);
	my $metric	=	$self->metric();
	my $instancetype	=	$instancetypes->{$firstqueue};
	my $firstresource	=	$instancetype->{$metric};
	my $firstduration	=	$durations->{$firstqueue} * $firstresource;
	$self->logDebug("firstqueue", $firstqueue);
	$self->logDebug("firstresource", $firstresource);
	$self->logDebug("firstduration", $firstduration);
	
	####	1. Solve for n1 using [1], [2] and [3]
	####	n1 = N/(1 + d2/d1 + d3/d1 + ... + dx/d1)
	my $terms	=	$self->solveForTerms($queues, $durations, $instancetypes, $lateststarted);
	$self->logDebug("terms", $terms);
	
	my $firstcount		=	$quota / $terms;
	$self->logDebug("firstcount", $firstcount);

	my $firstthroughput	=	($firstduration/3600) * $firstcount;
	$self->logDebug("firstthroughput", $firstthroughput);

	my $queuenames		=	$self->getQueueNames($queues);
	#$self->logDebug("queuenames", $queuenames);

	my $completedworkflows	=	$self->getCompletedWorkflows($queues);	
	$self->logDebug("completedworkflows", $completedworkflows);

	my $resourcecounts	=	[];
	for ( my $i = 0; $i < $lateststarted + 1; $i++ ) {
		my $queuename	=	$$queuenames[$i];
		$self->logDebug("queuename [$i]", $queuename);
		$self->logDebug("completedworkflows [$i]", $$completedworkflows[$i]);

		push @$resourcecounts, 0 and next if $$completedworkflows[$i];
		
		my $duration	=	$durations->{$queuename};
		$self->logDebug("duration", $duration);
		push @$resourcecounts, 0 and last if not defined $duration;
		
		my $instancetype	=	$instancetypes->{$queuename};
		$self->logDebug("instancetype", $instancetype);
		my $resource	=	$instancetype->{$metric};
		$self->logDebug("resource ($metric)", $resource);

		my $adjustedduration	=	$duration * $resource;
		$self->logDebug("adjustedduration", $adjustedduration);
		
		my $resourcecount	=	($firstcount * $adjustedduration) / $firstduration;
		$self->logDebug("resourcecount", $resourcecount);

		my $throughput	=	(3600/$adjustedduration) * $resourcecount;
		$self->logDebug("throughput", $throughput);

		push @$resourcecounts, $resourcecount;
	}
	$self->logDebug("resourcecounts", $resourcecounts);

	##### VERIFY TOTAL
	#my $total = 0;
	#for ( my $i = 0; $i < @$resourcecounts; $i++ ) {
	#	my $resourcecount 	=	$$resourcecounts[$i];
	#
	#	my $queuename	=	$$queuenames[$i];
	#	$self->logDebug("queuename", $queuename);
	#
	#	my $duration	=	$durations->{$queuename};
	#	$self->logDebug("duration", $duration);
	#
	#	$self->logDebug("count = $resourcecount / $duration");
	#	my $count	=	$resourcecount / $duration;
	#	$self->logDebug("count", $count);
	#	
	#	$total 	+=	$resourcecount;
	#}
	#$self->logDebug("total", $total);
	
	return $resourcecounts;
}

method getCompletedWorkflows ($queues) {
	#$self->logDebug("queues", $queues);
	
	my $completed	=	[];
	my $complete	=	1;
	foreach my $queue ( @$queues ) {
		#$self->logDebug("queue", $queue);
		if ( $self->hasNonCompletedSamples($queue) ) {
			$complete = 0;
		}
		push @$completed, $complete;
	}
	#$self->logDebug("completed", $completed);
	
	return $completed;	
}

method hasNonCompletedSamples ($queue) {
	#$self->logDebug("queue", $queue);
	
	my $query	=	qq{SELECT 1 FROM queuesample
WHERE username='$queue->{username}'
AND project='$queue->{project}'
AND workflow='$queue->{workflow}'
AND workflownumber=$queue->{workflownumber}
AND status!='completed'
ORDER BY sample};
	#$self->logDebug("query", $query);
	my $has	=	$self->db()->query($query);
	#$self->logDebug("has", $has);

	return 1 if defined $has;
	return 0;
}

method solveForTerms ($queues, $durations, $instancetypes, $latestcompleted) {
	#$self->logDebug("queues", $queues);
	#$self->logDebug("durations", $durations);
	#$self->logDebug("instancetypes", $instancetypes);

	#### GET FIRST DURATION
	my $firstqueue		=	$self->getQueueName($$queues[0]);
	my $instancetype	=	$instancetypes->{$firstqueue};
	my $metric			=	$self->metric();
	my $firstresource	=	$instancetype->{$metric};
	my $firstduration	=	$durations->{$firstqueue} * $firstresource;
	$self->logDebug("firstqueue", $firstqueue);
	#$self->logDebug("instancetype", $instancetype);
	$self->logDebug("firstresource", $firstresource);
	$self->logDebug("firstduration", $firstduration);

	my $terms	=	1;
	for ( my $i = 1; $i < $latestcompleted + 1; $i++ ) {
		my $queue	=	$$queues[$i];
		#$self->logDebug("queue $i", $queue);
		my $queuename	=	$self->getQueueName($queue);
		$self->logDebug("queuename", $queuename);

		my $duration	=	$durations->{$queuename};
		$self->logDebug("duration", $duration);
		last if not defined $duration or $duration == 0;
		
		my $instancetype	=	$instancetypes->{$queuename};
		$self->logDebug("instancetype", $instancetype);
		my $resource	=	$instancetype->{$metric};
		$self->logDebug("resource ($metric)", $resource);

		my $adjustedduration	=	$duration * $resource;
		
		my $term	=	$adjustedduration/$firstduration;
		$self->logDebug("term", $term);
		
		$terms		+=	$term;
	}
	$self->logDebug("FINAL terms", $terms);
	
	return $terms;	
}
method getInstanceCounts ($queues, $instancetypes, $resourcecounts) {

=head2	SUBROUTINE	getInstanceCounts

=head2	PURPOSE
	
	Given the CPU allocations (resourceallocations), allocate instances to each workflow

=head2	ALGORITHM


=cut

	my $metric	=	$self->metric();
	$self->logDebug("metric", $metric);

	my $instancecounts	=	[];
	my $resourcetotal	=	0;
	my $integertotal	=	0;
	for ( my $i = 0; $i < @$resourcecounts; $i++ ) {
		my $queuename	=	$self->getQueueName($$queues[$i]);
		my $resource	=	$instancetypes->{$queuename}->{$metric};
		my $resourcecount 	=	$$resourcecounts[$i] / $resource;
		$self->logDebug("$queuename instance $resource CPUs resourcecount", $resourcecount);
		
		push @$instancecounts, 0 and next if not defined $$resourcecounts[$i];
		
		#### STASH RUNNING COUNT
		$resourcetotal		+=	$$resourcecounts[$i];

		$self->logDebug("");
		if ( $i == scalar(@$resourcecounts) - 1) {
			$self->logDebug("pushing to instancecounts int( ($resourcetotal - $integertotal) / $resource )", int( ($resourcetotal - $integertotal) / $resource ));

			my $instancecount	=	int( ($resourcetotal - $integertotal) / $resource );
			$self->logDebug("instancecount", $instancecount);
			if ( $instancecount <= 0 ) {
				$instancecount		=	0;
			}
			elsif ( $instancecount < 1 ) {
				$instancecount		=	1 ;
			}

			push @$instancecounts, $instancecount;
		}
		else {
			my $instancecount	=	floor($$resourcecounts[$i]/$resource);
			$self->logDebug("pushing to instancecounts floor($$resourcecounts[$i]/$resource)", $instancecount);
			$self->logDebug("instancecount", $instancecount);
			if ( $instancecount <= 0 ) {
				$instancecount		=	0;
			}
			elsif ( $instancecount < 1 ) {
				$instancecount		=	1 ;
			}

			#### STASH RUNNING INTEGER COUNT
			$integertotal	+=	$instancecount * $resource;

			push @$instancecounts, $instancecount;
		}
	}
	$self->logDebug("integertotal", $integertotal);
	$self->logDebug("instancecounts", $instancecounts);

	return $instancecounts;
}

method getQueueNames ($queues) {
	#$self->logDebug("queues", $queues);
	
	my $queuenames	=	[];
	for ( my $i = 0; $i < @$queues; $i++ ) {
		my $queue	=	$$queues[$i];
		#$self->logDebug("queue $i", $queue);
		my $queuename	=	$self->getQueueName($queue);
		#$self->logDebug("queuename", $queuename);

		push @$queuenames, $queuename;
	}

	return $queuenames;
}

#### QUOTAS
method getResourceQuota ($username, $metric) {
=pod

nova quota-show
+-----------------------------+---------+
| Quota                       | Limit   |
+-----------------------------+---------+
| instances                   | 100     |
| cores                       | 576     |
| ram                         | 4718592 |
| floating_ips                | 10      |
| fixed_ips                   | -1      |
| metadata_items              | 128     |
| injected_files              | 5       |
| injected_file_content_bytes | 10240   |
| injected_file_path_bytes    | 255     |
| key_pairs                   | 100     |
| security_groups             | 10      |
| security_group_rules        | 20      |
+-----------------------------+---------+

=cut

	$self->logNote("username", $username);
	$self->logNote("metric", $metric);

	my $quotas	=	$self->getQuotas($username);
	#$self->logNote("quotas", $quotas);

	my $quota	=	undef;
	if ( $metric eq "cpus" ) {
		($quota)	=	$quotas	=~	/cores\s+\|\s+(\d+)/ms;
		$self->logNote("quota", $quota);
	}
	else {
		print "Master::getResourceQuota    Metric not supported: $metric\n" and exit;
	}

	return $quota;	
}

method getQuotas ($username) {
	#$self->logCaller("");
	$self->logNote("username", $username);
	my $tenant	=	$self->getTenant($username);
	$self->logNote("tenant", $tenant);
	my $authfile	=	$self->getAuthFile($username, $tenant);
	$self->printAuth($username) if not -f $authfile;
	$self->logNote("authfile", $authfile);
	
	my $quotas	=	$self->virtual()->getQuotas($authfile, $tenant->{os_tenant_id});
	#$self->logNote("quotas", $quotas);
	
	return $quotas;
}


#### INSTANCE TYPE
method getInstanceTypes ($queues) {
	
	#$self->logDebug("queues", $queues);
	
	my $instancetypes	=	{};
	foreach my $queue ( @$queues ) {
		#$self->logDebug("queue", $queue);
		my $queuename	=	$self->getQueueName($queue);
		#$self->logDebug("queuename", $queuename);
		
		my $instancetype	=	$self->getQueueInstance($queue);
		$instancetypes->{$queuename}	= $instancetype;
	}
	#$self->logDebug("instancetypes", $instancetypes);
	
	return $instancetypes;
}

method getQueueInstance ($queue) {
	#$self->logDebug("queue", $queue);
	my $queuename	=	$self->getQueueName($queue);
	#$self->logDebug("queuename", $queuename);
	my $query	=	qq{SELECT * FROM instancetype
WHERE username='$queue->{username}'
AND cluster='$queuename'};
	#$self->logDebug("query", $query);
	my $instancetype	=	$self->db()->queryhash($query);
	#$self->logDebug("instancetype", $instancetype);	
	
	return $instancetype;
}

method getThroughputs ($queues, $durations, $instancecounts) {
	$self->logDebug("queues", $queues);
	$self->logDebug("durations", $durations);
	$self->logDebug("instancecounts", $instancecounts);
	my $SECONDS	=	3600;
	my $throughputs	=	{};
	foreach my $queue ( @$queues ) {
		my $queuename	=	$self->getQueueName($queue);
		#$self->logDebug("queuename", $queuename);
		
		my $throughput	=	($SECONDS/$durations->{$queuename}) * $instancecounts->{$queuename};
		$self->logDebug("throughput = ($SECONDS/$durations->{$queuename}) * $instancecounts->{$queuename}");
		$self->logDebug("throughput", $throughput);
		
		$throughputs->{$queuename}	=	$throughput;
	}
	
	return $throughputs;
}

method getQueueName ($queue) {
	#$self->logDebug("queue", $queue);
	
	my $fields	=	[ "username", "project", "workflow" ];
	foreach my $field ( @$fields ) {
		return if not defined $queue->{$field};
	}

	return $queue->{username} . "." . $queue->{project} . "." . $queue->{workflow};
}

#### COUNTS
method getCurrentCounts ($username) {
	my $query	=	qq{SELECT queue, COUNT(*) AS count
FROM instance
WHERE username='$username'
AND status='running'
GROUP BY queue};
	#$self->logDebug("query", $query);
	my $entries	=	$self->db()->queryhasharray($query);
	#$self->logDebug("entries", $entries);
	my $counts	=	{};
	foreach my $entry ( @$entries ) {
		$counts->{$entry->{queue}}	=	$entry->{count}
	}
	#$self->logDebug("counts", $counts);

	return $counts;
}

method setMaxQuota ($queues, $instancecounts, $latestindex) {

	#### GET MAX JOBS
	my $maxjobs		=	$self->maxJobsForQueue($$queues[$latestindex]);
	$self->logDebug("maxjobs", $maxjobs);

	
}

method getRunningUserProjects ($username) {
	#$self->logDebug("username", $username);
	my $query	=	qq{SELECT name FROM project
WHERE username='$username'
AND status='running'};
	#$self->logDebug("query", $query);
	my $projects	=	$self->db()->queryarray($query);
	
	return $projects;
}

method getLatestCompleted ($queues) {
	#$self->logDebug("queues", $queues);

	my $latestindex;
	for ( my $i = 0; $i < @$queues; $i++ ) {
		my $incomplete 	=	$self->hasNonCompletedSamples($$queues[$i]);
		#$self->logDebug("incomplete", $incomplete);
		$latestindex = $i if not $incomplete;
	}
	
	return $latestindex;
}

method getCompletedSamples ($queue) {
	my $query	=	qq{SELECT * FROM queuesample
WHERE username='$queue->{username}'
AND project='$queue->{project}'
AND workflow='$queue->{workflow}'
AND workflownumber=$queue->{workflownumber}
AND status='completed'
ORDER BY sample};
	#$self->logDebug("query", $query);
	my $samples	=	$self->db()->queryhasharray($query);
	#$self->logDebug("samples", $samples);

	return $samples;	
}

method getLatestStarted ($queues) {
	#$self->logDebug("queues", $queues);

	my $latestindex;
	for ( my $i = 0; $i < @$queues; $i++ ) {
		my $started 	=	$self->hasStartedSamples($$queues[$i]);
		#$self->logDebug("queue [$i] $$queues[$i]->{workflow} started", $started);
		$latestindex = $i if $started;
	}
	
	return $latestindex;
}

method hasStartedSamples ($queue) {
	my $query	=	qq{SELECT 1 FROM queuesample
WHERE username='$queue->{username}'
AND project='$queue->{project}'
AND workflow='$queue->{workflow}'
AND workflownumber=$queue->{workflownumber}
AND status!='completed'
AND status!='none'
ORDER BY sample};
	#$self->logDebug("query", $query);
	my $started	=	$self->db()->query($query);
	#$self->logDebug("started", $started);

	return 1 if defined $started;
	return 0;
}

method getStartedSamples ($queue) {
	my $query	=	qq{SELECT * FROM queuesample
WHERE username='$queue->{username}'
AND project='$queue->{project}'
AND workflow='$queue->{workflow}'
AND workflownumber=$queue->{workflownumber}
AND status!='completed'
ORDER BY sample};
	#$self->logDebug("query", $query);
	my $samples	=	$self->db()->queryhasharray($query);
	#$self->logDebug("samples", $samples);

	return $samples;	
}
method getQueueCluster ($queue) {
	#$self->logDebug("queue", $queue);
	my $queuename	=	$self->getQueueName($queue);
	my $query	=	qq{SELECT * FROM cluster
WHERE username='$queue->{username}'
AND cluster='$queuename'};
	#$self->logDebug("query", $query);
	my $instancetype	=	$self->db()->queryhash($query);
	#$self->logDebug("instance", $instance);
	
	return $instancetype;
}


method getDurations ($queues) {
	my $durations	=	{};
	foreach my $queue ( @$queues ) {
		#$self->logDebug("queue", $queue);
		my $queuename	=	$queue->{username} . "." . $queue->{project} . "." . $queue->{workflow};
		my $duration	=	$self->getQueueDuration($queue);
		#$self->logDebug("duration", $duration);

		$durations->{$queuename}	= $duration if defined $duration;
		last if not defined $duration;
	}		

	return $durations;
}

method getQueueDuration ($queue) {
	
	#$self->logDebug("queue", $queue);

	my $provenance	=	$self->getQueueProvenance($queue);
	return if not defined $provenance or not @$provenance;
	#$self->logDebug("provenance", $provenance);
	
	#### COUNT ALL NON-ERROR start-completed DURATIONS
	my $samples	=	{};
	foreach my $row ( @$provenance ) {
		my $sample	=	$row->{sample};
		#$self->logDebug("sample", $sample);

		if ( defined $samples->{$sample} ) {
			push @{$samples->{$sample}}, $row;
		}
		else {
			$samples->{$sample}	=	[ $row ];
		}
	}
	#$self->logDebug("samples", $samples);
	
	my $totaldurations	=	[];
	foreach my $sample ( keys %$samples ) {
		#$self->logDebug("sample", $sample);
		my $rows	=	$samples->{$sample};
		#$self->logDebug("rows", $rows);

		my $sampledurations	=	$self->getSampleDurations($rows);
		#$self->logDebug("sampledurations", $sampledurations);
		@$totaldurations = (@$totaldurations, @$sampledurations) if defined $sampledurations and @$sampledurations;
	}
	#$self->logDebug("totaldurations", $totaldurations);
	
	my $duration = 0;
	foreach my $queueduration ( @$totaldurations ) {
		#$self->logDebug("queueduration", $queueduration);
		$duration += $queueduration;
	}
	$duration = $duration / scalar(@$totaldurations) if @$totaldurations;
	#$self->logDebug("FINAL AVERAGE duration", $duration);

	return undef if $duration == 0;
	return $duration;
}

method getSampleDurations ($rows) {
	#### WORK BACKWARDS AND COUNT EACH GOOD RUN
	#$self->logDebug("rows", $rows);

	my $durations	=	[];
	my $completed;
	my $start;
	for ( my $i = scalar(@$rows) - 1; $i > -1; $i-- ) {
		my $entry	=	$$rows[$i];
		#$self->logDebug("entry $i status", $entry->{status});
		if ( $entry->{status} eq "completed" ) {
			#$self->logDebug("completed, adding completed to entry", $entry);
			$completed = $entry;
		}
		elsif ( defined $completed and $entry->{status} eq "started" ) {
			my $duration	=	$self->calculateDuration($entry->{time}, $completed->{time});
			#$self->logDebug("duration", $duration);
			push @$durations, $duration if defined $duration;
			$completed = undef;
		}
		else {
			$completed = undef;
		}
	}
	
	return $durations;
}

method calculateDuration ($start, $stop) {
	#$self->logDebug("start", $start);
	#$self->logDebug("stop", $stop);
	return if not defined $start or not defined $stop;

	my $startseconds	=	$self->parseDate($start);
	#$self->logDebug("startseconds", $startseconds);
	return if not defined $startseconds;
	my $stopseconds	=	$self->parseDate($stop);
	#$self->logDebug("stopseconds", $stopseconds);
	return if not defined $stopseconds;

	return $stopseconds - $startseconds;
}

method parseDate ($date) { 
	#$self->logDebug("date", $date);

	# 2014-06-12 10:41:15
	my ($year, $month, $day, $hour, $minute, $second);
	if ( $date =~ m{^(\d{1,4})\W*0*(\d{1,2})\W*0*(\d{1,2})\W*0?\s+(\d{0,2})\W*0?(\d{0,2})\W*0?(\d{0,2})}x) {
		$year = $1;  $month = $2;   $day = $3;
		$hour = $4;  $minute = $5;  $second = $6;
		$hour |= 0;  $minute |= 0;  $second |= 0;  # defaults.
		$year = ($year<100 ? ($year<70 ? 2000+$year : 1900+$year) : $year);
		return timelocal($second, $minute, $hour, $day, $month - 1, $year);  
	}

	return undef;
}

method getQueueProvenance ($queue) {
	#$self->logDebug("queue", $queue);
	
	my $query	=	qq{SELECT * FROM provenance
WHERE username='$queue->{username}'
AND project='$queue->{project}'
AND workflow='$queue->{workflow}'
AND workflownumber=$queue->{workflownumber}
ORDER BY sample, time};
	#$self->logDebug("query", $query);
	my $provenance	=	$self->db()->queryhasharray($query);
	#$self->logDebug("provenance", $provenance);

	return $provenance;
}

method getQueues {
	my $query       =	qq{SELECT queuesample.* FROM queuesample,project
WHERE project.status='running'
AND project.username=queuesample.username
AND project.name=queuesample.project
ORDER BY queuesample.username, queuesample.project, queuesample.workflownumber, queuesample.sample};
	$self->logDebug("query", $query);

	return	$self->db()->queryhasharray($query);
}

method getDistinctQueues ($project) {
	my $query       =	qq{SELECT DISTINCT queuesample.username, queuesample.project, queuesample.workflow, queuesample.workflownumber
FROM queuesample,project,cluster
WHERE project.name='$project'
AND project.status='running'
AND project.username=queuesample.username
AND project.name=queuesample.project
ORDER BY queuesample.username, queuesample.project, queuesample.workflownumber, queuesample.sample};
	#$self->logDebug("query", $query);

	return	$self->db()->queryhasharray($query);
}

#### MAINTAIN QUEUES
method maintainQueues($workflows) {
	#$self->logDebug("workflows", $workflows);
	
	print "\n\n#### DOING maintainQueues\n";
	for ( my $i = 0; $i < @$workflows; $i++ ) {
		my $workflow	=	$$workflows[$i];
		$self->logDebug("workflow $i", $workflow->{name});
		my $label	=	"[" . ($i + 1) . "] ". $$workflows[$i]->{name};
		
		if ( $i != 0 ) {
			$self->logDebug("$label NO COMPLETED JOBS in previous queue") and next if $self->noCompletedJobs($$workflows[$i - 1]);
		}
		
		$self->logDebug("$label DOING self->maintainQueue()");
		$self->maintainQueue($workflows, $workflow);
	}
}

method maintainQueue ($workflows, $workflowdata) {
	
	#$self->logDebug("workflowdata", $workflowdata);
	
	my $queuename	=	$self->setQueueName($workflowdata);
	$self->logDebug("queuename", $queuename);
	
	my $workflowcompleted	=	$self->workflowCompleted($workflowdata);
	$self->logDebug("workflowcompleted", $workflowcompleted);
	$self->logDebug("Skipping completed queue", $queuename) and return if $workflowcompleted;
	
	#### GET MAX JOBS
	my $maxjobs		=	$self->maxJobsForQueue($workflowdata);
	$self->logDebug("FINAL maxjobs", $maxjobs);

	#### GET NUMBER OF QUEUED JOBS
	my $queuedjobs	=	$self->getQueuedJobs($workflowdata);
	my $numberqueued=	scalar(@$queuedjobs);
	$self->logDebug("numberqueued", $numberqueued);

	#### ADD MORE JOBS TO QUEUE IF LESS THAN maxjobs
	my $limit	=	$maxjobs - $numberqueued;
	$self->logDebug("limit", $limit);

	return 0 if $limit <= 0;

	#### QUEUE UP ADDITIONAL SAMPLES
	my $tasks	=	$self->getTasks($workflows, $workflowdata, $limit);
	#$self->logDebug("tasks", $tasks);
	$self->logDebug("no. tasks", scalar(@$tasks)) if defined $tasks;
	$self->logDebug("tasks: undefined") if not defined $tasks;
	return 0 if not defined $tasks;

	if ( $numberqueued == 0 and not @$tasks ) {
		$self->logDebug("Setting workflow $workflowdata->{workflow} status to 'completed'");
		$self->setWorkflowStatus($workflowdata->{username}, $workflowdata->{project}, $workflowdata->{workflow}, "completed");
	}
	elsif ( @$tasks ) {
		foreach my $task ( @$tasks ) {
			$self->sendTask($task);
		
			$self->updateJobStatus($task);
		}
	}
	
	return 1;
}

method noCompletedJobs ($workflow) {
	my $query	=	qq{SELECT COUNT(*) FROM queuesample
WHERE username='$workflow->{username}'
AND project='$workflow->{project}'
AND workflow='$workflow->{workflow}'
AND workflownumber='$workflow->{workflownumber}'
AND status='completed'};
	$self->logDebug("query", $query);
	
	my $completed	=	$self->db()->query($query);
	#$self->logDebug("completed", $completed);
	
	return 1 if $completed == 0;
	return 0;
}

method setWorkflowCompleted ($workflowdata) {
	my $query	=	qq{UPDATE workflow
SET status='completed'
WHERE username='$workflowdata->{username}'
AND project='$workflowdata->{project}'
AND name='$workflowdata->{name}'
};
	$self->logDebug("query", $query);

	return $self->db()->do($query);
}

method workflowCompleted ($workflowdata) {
	my $query	=	qq{SELECT 1 FROM workflow
WHERE username='$workflowdata->{username}'
AND project='$workflowdata->{project}'
AND name='$workflowdata->{name}'
AND status='completed'};
	#$self->logDebug("query", $query);
	
	return 1 if defined $self->db()->query($query);
	return 0;
}

method getTasks ($queues, $queuedata, $limit) {

	#### GET ADDITIONAL SAMPLES TO ADD TO QUEUE
	$self->logDebug("queuedata", $queuedata);
	$self->logDebug("limit", $limit);

	#### GET SAMPLE TABLE
	my $sampletable	=	$self->getSampleTable($queuedata);
	#$self->logDebug("sampletable", $sampletable);
	print "Master::getTasks    sampletable not defined\n" and exit if not defined $sampletable;

	#### POPULATE QUEUE SAMPLE TABLE IF EMPTY	
	my $workflownumber	=	$queuedata->{workflownumber};
	#$self->logDebug("workflownumber", $workflownumber);
	if ( $workflownumber == 1 ) {
		my $hassamples		=	$self->hasQueueSamples($queuedata);
		#$self->logDebug("hassamples", $hassamples);
		$self->populateQueueSamples($queuedata, $sampletable) if not $hassamples;
	}

	#### GET TASKS FROM queuesample TABLE
	my $tasks	=	$self->pullTasks($queues, $queuedata, $limit);
	#$self->logDebug("tasks", $tasks);
	#$self->logDebug("no. tasks", scalar(@$tasks));
	return if not @$tasks;

	#### DIRECT THE TASK TO EXECUTE A WORKFLOW
	foreach my $task ( @$tasks ) {
		$task->{module}		=	"Agua::Workflow";
		$task->{mode}		=	"executeWorkflow";
		$task->{database}	=	$queuedata->{database} || $self->database() || $self->conf()->getKey("database:DATABASE", undef);
		
		$task->{workflow}	=	$queuedata->{workflow};
		$task->{workflownumber}=	$queuedata->{workflownumber};
		
		#### UPDATE TASK STATUS AS queued
		$task->{status}		=	"queued";
		
		#### SET TIME QUEUED
		$task->{time}		=	$self->getMysqlTime();

		#### SET SAMPLE HASH
		$task->{samplehash}	=	$self->getTaskSampleHash($task, $sampletable);
		#$self->logDebug("task", $task);
	}
	
	return $tasks;
}

method hasQueueSamples ($queuedata) {
	#$self->logDebug("queuedata", $queuedata);
	my $query	=	qq{SELECT 1 FROM queuesample
WHERE username='$queuedata->{username}'
AND project='$queuedata->{project}'
AND workflow='$queuedata->{workflow}'};
	#$self->logDebug("query", $query);
	
	return 1 if defined $self->db()->query($query);
	return 0;
}

method populateQueueSamples($queuedata, $sampletable) {

	$self->logDebug("queuedata", $queuedata);
	$self->logDebug("sampletable", $sampletable);

	my $query		=	qq{SELECT * FROM $sampletable};
	$self->logDebug("query", $query);
	my $samples		=	$self->db()->queryhasharray($query);
	$self->logDebug("no. samples", scalar(@$samples));
	my $fields		=	$self->db()->fields("queuesample");
	$self->logDebug("fields", $fields);

	my $tsvfile		=	"/tmp/queuesample.$sampletable.$$.tsv";
	$self->logDebug("tsvfile", $tsvfile);
	open(OUT, ">", $tsvfile) or die "Can't open tsv file: $tsvfile\n";
	foreach my $sample ( @$samples ) {
		$sample->{username}	=	$queuedata->{username};
		$sample->{project}	=	$queuedata->{project};
		$sample->{workflow}	=	$queuedata->{workflow};
		$sample->{status}	=	"none";
		my $line	=	$self->db()->fieldsToTsv($fields, $sample);
		#$self->logDebug("line", $line);

		print OUT $line;
	}
	close(OUT) or die "Can't close tsv file: $tsvfile\n";

	$self->logDebug("loading 'queuesample' table");
	$self->db()->load("queuesample", $tsvfile, undef);
	
}

method getSampleTable ($queuedata) {
	my $username	=	$queuedata->{username};
	my $project		=	$queuedata->{project};
	my $query		=	qq{SELECT sampletable FROM sampletable
WHERE username='$username'
AND project='$project'};
	#$self->logDebug("query", $query);
	
	return $self->db()->query($query);
}

method getTaskSampleHash ($task, $sampletable) {
	my $username	=	$task->{username};
	my $project		=	$task->{project};
	my $sample		=	$task->{sample};
	my $query		=	qq{SELECT * FROM $sampletable
WHERE username='$username'
AND project='$project'
AND sample='$sample'};
	#$self->logDebug("query", $query);
	
	return $self->db()->queryhash($query);
}

method pullTasks ($queues, $queuedata, $limit) {
	
	#$self->logDebug("queues", $queues);
	$self->logDebug("queuedata", $queuedata);

	my $workflownumber	=	$queuedata->{workflownumber};
	my $previous	=	$self->getPrevious($queues, $queuedata);
	$self->logDebug("previous", $previous);

	#### VERIFY VALUES
	my $notdefined	=	$self->notDefined($queuedata, ["username", "project", "workflow"]);
	$self->logCritical("not defined", @$notdefined) and return if scalar(@$notdefined) != 0;

	my $query		=	qq{SELECT * FROM queuesample
WHERE username='$previous->{username}'
AND project='$previous->{project}'
AND workflow='$previous->{workflow}'
AND workflownumber='$previous->{workflownumber}'
AND status='$previous->{status}'
LIMIT $limit};
	#$self->logDebug("query", $query);
	
	return $self->db()->queryhasharray($query) || [];
}

method getPrevious ($queues, $queuedata) {

	#$self->logDebug("queues", $queues);
	#$self->logDebug("queuedata", $queuedata);

	my $workflownumber	=	$queuedata->{workflownumber};
	#$self->logDebug("workflownumber", $workflownumber);
	
	my $previous	=	{};
	if ( $workflownumber == 1 ) {
		$previous->{status}		=	"none";
		$previous->{username}	=	$queuedata->{username};
		$previous->{project}	=	$queuedata->{project};
		$previous->{workflow}	=	$queuedata->{workflow};
		$previous->{workflownumber}	=	$queuedata->{workflownumber};
	}
	else {
		my $previousindex		=	$workflownumber - 2;
		$self->logDebug("previousindex", $previousindex);
		my $previousdata		=	$$queues[$previousindex];
		$previous->{status}		=	"completed";
		$previous->{username}	=	$previousdata->{username};
		$previous->{project}	=	$previousdata->{project};
		$previous->{workflow}	=	$previousdata->{workflow};
		$previous->{workflownumber}	=	$previousdata->{workflownumber};
	}

	return $previous;	
}

#### TOPICS
method sendTopic ($data, $key) {

	$self->logDebug("data", $data);
	#$self->logDebug("key", $key);

	my $exchange	=	$self->conf()->getKey("queue:topicexchange", undef);
	#$self->logDebug("exchange", $exchange);

	my $host		=	$self->host() || $self->conf()->getKey("queue:host", undef);
	my $user		= 	$self->user() || $self->conf()->getKey("queue:user", undef);
	my $pass		=	$self->pass() || $self->conf()->getKey("queue:pass", undef);
	my $vhost		=	$self->vhost() || $self->conf()->getKey("queue:vhost", undef);
	$self->logNote("host", $host);
	$self->logNote("user", $user);
	$self->logNote("pass", $pass);
	$self->logNote("vhost", $vhost);
	
    my $connection = Net::RabbitFoot->new()->load_xml_spec()->connect(
        host 	=>	$host,
        port 	=>	5672,
        user 	=>	$user,
        pass 	=>	$pass,
        vhost	=>	$vhost,
    );

	$self->logNote("connection: $connection");
	$self->logNote("DOING connection->open_channel");
	my $channel 	= 	$connection->open_channel();
	$self->channel($channel);

	$self->logNote("DOING channel->declare_exchange");

	$channel->declare_exchange(
		exchange => $exchange,
		type => 'topic',
	);
	
	my $json	=	$self->jsonparser()->encode($data);
	#$self->logDebug("json", $json);
	$self->channel()->publish(
		exchange => $exchange,
		routing_key => $key,
		body => $json,
	);
	
	print "[x] Sent topic with key '$key' mode '$data->{mode}'\n";

	$self->logDebug("closing connection");
	$connection->close();
}

#### TASKS
method receiveTask ($taskqueue) {
	$self->logDebug("taskqueue", $taskqueue);
	
	#### OPEN CONNECTION
	my $connection	=	$self->newConnection();	
	my $channel 	= 	$connection->open_channel();
	#$self->channel($channel);
	$channel->declare_queue(
		queue => $taskqueue,
		durable => 1,
	);
	
	print "[*] Waiting for tasks in queue: $taskqueue\n";
	
	$channel->qos(prefetch_count => 1,);
	
	no warnings;
	my $handler	= *handleTask;
	use warnings;
	my $this	=	$self;
	
	$channel->consume(
		on_consume	=>	sub {
			my $var 	= 	shift;
			print "Master::receiveTask    DOING CALLBACK";
		
			my $body 	= 	$var->{body}->{payload};
			print " [x] Received $body\n";
		
			my @c = $body =~ /\./g;
		
			#Coro::async_pool {

				#### RUN TASK
				&$handler($this, $body);
				
				#### SEND ACK AFTER TASK COMPLETED
				$channel->ack();
			#}
		},
		no_ack => 0,
	);
	
	#### SET self->connection
	$self->connection($connection);
	
	# Wait forever
	AnyEvent->condvar->recv;	
}

method handleTask ($json) {
	#$self->logDebug("json", substr($json, 0, 200));

	my $data = $self->jsonparser()->decode($json);
	#$self->logDebug("data", $data);

	my $duplicate	=	$self->duplicate();
	if ( defined $duplicate and not $self->deeplyIdentical($data, $duplicate) ) {
		#$self->logDebug("Skipping duplicate message");
		return;
	}
	else {
		$self->duplicate($data);
	}

	my $mode =	$data->{mode} || "";
	#$self->logDebug("mode", $mode);
	
	if ( $self->can($mode) ) {
		$self->$mode($data);
	}
	else {
		print "mode not supported: $mode\n";
		$self->logDebug("mode not supported: $mode");
	}
}

method sendTask ($task) {	
	$self->logDebug("task", $task);
	#$self->logDebug("$task->{workflow} $task->{sample} $task->{status}");

	my $processid	=	$$;
	#$self->logDebug("processid", $processid);
	$task->{processid}	=	$processid;

	#### SET QUEUE
	my $queuename		=	$self->setQueueName($task);
	$task->{queue}		=	$queuename;
	#$self->logDebug("queuename", $queuename);
	
	#### ADD UNIQUE IDENTIFIERS
	$task	=	$self->addTaskIdentifiers($task);

	my $jsonparser = JSON->new();
	my $json = $jsonparser->encode($task);
	#$self->logDebug("json", $json);

	#### GET CONNECTION
	my $connection	=	$self->newConnection();
	#$self->logDebug("DOING connection->open_channel()");
	my $channel = $connection->open_channel();
	$self->channel($channel);
	#$self->logDebug("channel", $channel);
	
	$channel->declare_queue(
		queue => $queuename,
		durable => 1,
	);
	
	#### BIND QUEUE TO EXCHANGE
	$channel->publish(
		exchange => '',
		routing_key => $queuename,
		body => $json,
	);
	
	print " [x] Sent TASK:  $task->{mode} $task->{workflow} $task->{sample}\n";
}

method addTaskIdentifiers ($task) {
	
	#### SET TOKEN
	$task->{token}		=	$self->token();
	
	#### SET SENDTYPE
	$task->{sendtype}	=	"task";
	
	#### SET DATABASE
	$task->{database} 	= 	$self->db()->database() || "";

	#### SET USERNAME		
	$task->{username} 	= 	$task->{username};

	#### SET SOURCE ID
	$task->{sourceid} 	= 	$self->sourceid();
	
	#### SET CALLBACK
	$task->{callback} 	= 	$self->callback();
	
	#$self->logDebug("Returning task", $task);
	
	return $task;
}
method setQueueName ($task) {
	#### VERIFY VALUES
	my $notdefined	=	$self->notDefined($task, ["username", "project", "workflow"]);
	$self->logCritical("not defined", $notdefined) and return if @$notdefined;
	
	my $username	=	$task->{username};
	my $project		=	$task->{project};
	my $workflow	=	$task->{workflow};
	my $queue		=	"$username.$project.$workflow";
	#$self->logDebug("queue", $queue);
	
	return $queue;	
}

method notDefined ($hash, $fields) {
	return [] if not defined $hash or not defined $fields or not @$fields;
	
	my $notDefined = [];
    for ( my $i = 0; $i < @$fields; $i++ ) {
        push( @$notDefined, $$fields[$i]) if not defined $$hash{$$fields[$i]};
    }

    return $notDefined;
}

#### JOB STATUS
method updateJobStatus ($data) {
	#$self->logDebug("data", $data);
	$self->logDebug("$data->{sample} $data->{status}");

	my $keys	=	[ "username", "project", "workflow", "workflownumber", "sample" ];
	my $notdefined	=	$self->notDefined($data, $keys);	
	$self->logDebug("notdefined", $notdefined) and return if @$notdefined;

	#### ADD TO provenance TABLE
	my $table		=	"provenance";
	my $fields		=	$self->db()->fields($table);
	my $success		=	$self->_addToTable($table, $data, $keys, $fields);
	#$self->logDebug("addToTable 'provenance'    success", $success);
	$self->logDebug("failed to add to provenance table") if not $success;

	#### UPDATE queuesamples TABLE
	$success		=	$self->updateQueueSample($data);	
	$self->logDebug("failed to add to queuesample table") if not $success;
}

method updateQueueSample ($data) {
	#$self->logDebug("data", $data);	
	
	#### UPDATE queuesample TABLE
	my $table	=	"queuesample";
	my $keys	=	[ "sample" ];
	$self->_removeFromTable($table, $data, $keys);
	
	$keys	=	["username", "project", "workflow", "workflownumber", "sample", "status" ];

	return $self->_addToTable($table, $data, $keys);
}

#### HEARTBEAT
method updateHeartbeat ($data) {
	$self->logDebug("host $data->{host} [$data->{time}]");
	#$self->logDebug("data", $data);
	my $keys	=	[ "host", "time" ];
	my $notdefined	=	$self->notDefined($data, $keys);	
	$self->logDebug("notdefined", $notdefined) and return if @$notdefined;

	#### ADD TO TABLE
	my $table		=	"heartbeat";
	my $fields		=	$self->db()->fields($table);
	$self->_addToTable($table, $data, $keys, $fields);
}

method setConfigMaxJobs ($queuename, $value) {
	return $self->conf()->setKey("queue:maxjobs", $queuename, $value);
}

method getConfigMaxJobs ($queuename) {
	return $self->conf()->getKey("queue:maxjobs", $queuename);
}

method pushTask ($task) {
	#### STORE UNQUEUED TASK IN queue TABLE
	$self->logDebug("task", $task);
	
	#### VERIFY VALUES
	my $keys	=	["username", "project", "workflow", "workflownumber", "sample"];
	my $notdefined	=	$self->notDefined($task, $keys);
	$self->logCritical("not defined", @$notdefined) and return if @$notdefined;

	my $status	=	"unassigned";
	my $table	=	"queuesample";
	$self->_removeFromTable($table, $task, $keys);
	
	return $self->_addToTable($table, $task, $keys);
}

method allocateSamples ($queuedata, $limit) {
	$self->logDebug("queuedata", $queuedata);
	
	my $samples	=	$self->getSampleFromSynapse($limit);
	foreach my $sample ( @$samples ) {
		my $hash		=	$self->copyHash($queuedata);
		$hash->{sample}	=	$sample;
		return 0 if $self->pushTask($hash) == 0;
	}
	
	return 1;
}

method copyHash ($hash1) {
	my $hash2 = {};
	foreach my $key ( keys %$hash1 ) {
		$hash2->{$key}	=	$hash1->{$key};
	}
	
	return $hash2;
}

method maxJobsForQueue ($queuedata) {
	my $queuename	=	$self->setQueueName($queuedata);
	#$self->logDebug("queuename", $queuename);
	my $maxjobs		=	$self->getConfigMaxJobs($queuename);
	
	if ( not defined $maxjobs ) {
		$maxjobs	=	$self->maxjobs(); #### EITHER DEFAULT OR USER-DEFINED
		
		$self->setConfigMaxJobs($queuename, $maxjobs);
	}
	$self->logDebug("maxjobs", $maxjobs);
	
	return $maxjobs;
}

method getQueueTasks {	
	my $list		=	$self->getQueueTaskList();
	$list		=~	s/Listing queues ...(), "\s*\n//;
	$list		=~	s/(), "\n...done.\s*//;
	my $tasks	=	{};
	foreach my $entry ( split "\n", $list ) {
		#$self->logDebug("entry", $entry);
		my ($queue, $taskcount)	=	$entry	=~	/^(\S+)\s+(\d+)/;
		$tasks->{$queue}	=	$taskcount if defined $queue and defined $taskcount;
	}	
	#$self->logDebug("tasks", $tasks);

	return $tasks;
}

method getQueueTaskList {
	
	my $vhost		=	$self->conf()->getKey("queue:vhost", undef);
	#$self->logDebug("vhost", $vho st);
	
	my $rabbitmqctl	=	$self->rabbitmqctl();
	#$self->logDebug("rabbitmqctl", $rabbitmqctl);
	
	my $command		=	qq{$rabbitmqctl list_queues -p $vhost name messages};
	#$self->logDebug("command", $command);

	my $queuelist	=	`$command`;
	#$self->logDebug("queuelist", $queuelist);

	return $queuelist;
}


method getQueuedJobs ($workflowdata) {
	my $query	=	qq{SELECT * FROM queuesample
WHERE username='$workflowdata->{username}'
AND project='$workflowdata->{project}'
AND workflow='$workflowdata->{workflow}'
AND status='queued'};
	#$self->logDebug("query", $query);
	
	return $self->db()->queryhasharray($query) || [];
}

#### SEND TASK
method setModules {
    my $installdir = $self->conf()->getKey("agua", "INSTALLDIR");
    my $modulestring = $self->modulestring();
	$self->logDebug("modulestring", $modulestring);

	my $modules = {};
    my @modulenames = split ",", $modulestring;
    foreach my $modulename ( @modulenames) {
        my $modulepath = $modulename;
        $modulepath =~ s/::/(), "\//g;
        my $location    = "$installdir/lib/$modulepath.pm";
        #print "location: $location\n";
        my $class       = "$modulename";
        eval("use $class");
    
        my $object = $class->new({
            conf        =>  $self->conf(),
            log     =>  $self->log(),
            printlog    =>  $self->printlog()
        });
        print "object: $object\n";
        
        $modules->{$modulename} = $object;
    }

    return $modules; 
}

#### UTILS
method exited ($nodename) {	
	my $entries	=	$self->virtual()->getEntries($nodename);
	foreach my $entry ( @$entries ) {
		my $internalip	=	$entry->{internalip};
		$self->logDebug("internalip", $internalip);
		my $status	=	$self->workflowStatus($internalip);	

		if ( $status =~ /Done, exiting/ ) {
			my $id	=	$entry->{id};
			$self->logDebug("DOING novaDelete($id)");
			$self->virtual()->novaDelete($id);
		}
	}
}

method sleeping ($nodename) {	
	my $entries	=	$self->virtual()->getEntries($nodename);
	foreach my $entry ( @$entries ) {
		my $internalip	=	$entry->{internalip};
		$self->logDebug("internalip", $internalip);
		my $status	=	$self->workflowStatus($internalip);	

		if ( $status =~ /Done, sleep/ ) {
			my $id	=	$entry->{id};
			$self->logDebug("DOING novaDelete($id)");
			$self->virtual()->novaDelete($id);
		}
	}
}

method status ($nodename) {	
	my $entries	=	$self->virtual()->getEntries($nodename);
	foreach my $entry ( @$entries ) {
		my $internalip	=	$entry->{internalip};
		$self->logDebug("internalip", $internalip);
		my $status	=	$self->workflowStatus($internalip);	
		my $percent	=	$self->downloadPercent($status);
		$self->logDebug("percent", $percent);
		next if not defined $percent;
		
		if ( $percent < 90 ) {
			my $uuid	=	$self->getDownloadUuid($internalip);
			$self->logDebug("uuid", $uuid);
			
			$self->resetStatus($uuid, "todownload");

			my $id	=	$entry->{id};
			$self->logDebug("id", $id);
			
			$self->logDebug("DOING novaDelete($id)");
			$self->virtual()->novaDelete($id);
		}
	}
}

method getDownloadUuid ($ip) {
	$self->logDebug("ip", $ip);
	my $command =	qq{ssh -o "StrictHostKeyChecking no" -t ubuntu(), "\@", $self->ip "ps aux | grep /usr/bin/gtdownload"};
	$self->logDebug("command", $command);
	
	my $output	=	`$command`;
	#$self->logDebug("output", $output);

	my @lines	=	split $output;
	#$self->logDebug("lines", (), "\@lines);
	
	my $uuid	=	$self->parseUuid(\@lines);
	
	return $uuid;
}
method workflowStatus ($ip) {
	$self->logDebug("ip", $ip);
	my $command =	qq{ssh -o "StrictHostKeyChecking no" -t ubuntu(), "\@", $self->ip "tail -n1 ~/worker.log"};
	$self->logDebug("command", $command);
	
	my $status	=	`$command`;
	#$self->logDebug("status", $status);
	
	return $status;
}

method downloadPercent ($status) {
	#$self->logDebug("status", $status);
	my ($percent)	=	$status	=~ /(), "\(([\d\.]+)\% complete\)/;
	$self->logDebug("percent", $percent);
	
	return $percent;
}

method parseUuid ($lines) {
	$self->logDebug("lines length", scalar(@$lines));
	for ( my $i = 0; $i < @$lines; $i++ ) {
		#$self->logDebug("lines[$i]", $$lines[$i]);
		
		if ( $$lines[$i] =~ /(), "\-d ([a-z0-9\-]+)/ ) {
			return $1;
		}
	}

	return;
}

method stopWorkflow ($ips, $workflow) {
	$self->logDebug("ips", $ips);
	$self->logDebug("workflow", $workflow);
	
	foreach my $ip ( @$ips ) {
		my $data	=	{};
		$data->{module}	=	"Agua::Workflow";
		$data->{mode}	=	"stopWorkflow";
		
	}
}

method getWorkflows ($node) {
#### GET CURRENT WORKFLOW STATES (COMPLETED, EXITED)
	
}

method runCommand ($command) {
	$self->logDebug("command", $command);
	
	return `$command`;
}

method startWorkflow {
	#### OVERRIDE	
}

method setSynapse {
	$self->logDebug("");

	my $synapse	= Synapse->new({
		conf		=>	$self->conf(),
		log     =>  $self->log(),
		printlog    =>  $self->printlog(),
		logfile     =>  $self->logfile()
	});

	$self->synapse($synapse);
}

method pushWorkflow {
	#### ADD A WORKFLOW RECORD TO A REMOTE HOST	
	
}

method pullWorkflow {
	#### GET A WORKFLOW RECORD FROM A REMOTE HOST
	#### INCLUDES ALL FIELDS 
	
	
}

method pullProvenance {
	#### INCLUDES
	#	-	PACKAGES (SOFTWARE AND DATA - URLs, DOIs, ETC.)
	#	-	APPLICATION
	#	-	PARAMETERS
	#	-	RUNTIME
	#	-	STDOUT AND STDERR (FIRST 1000 LINES EACH, STORED IN A GLOB)
	
}



method setJsonParser {
	return JSON->new->allow_nonref;
}

method setVirtual {
	my $virtualtype		=	$self->conf()->getKey("agua", "VIRTUALTYPE");
	$self->logDebug("virtualtype", $virtualtype);

	#### RETURN IF TYPE NOT SUPPORTED	
	$self->logDebug("virtual virtualtype not supported: $virtualtype") and return if $virtualtype !~	/^(openstack|vagrant)$/;

   #### CREATE DB OBJECT USING DBASE FACTORY
    my $virtual = Virtual->new( $virtualtype,
        {
			conf		=>	$self->conf(),
            username	=>  $self->username(),
			
			logfile		=>	$self->logfile(),
			log			=>	$self->log(),
			printlog	=>	$self->printlog()
        }
    ) or die "Can't create virtual of type: $virtualtype. $!\n";
	$self->logDebug("virtual: $virtual");

	$self->virtual($virtual);
}


method deeplyIdentical ($a, $b) {
    if (not defined $a)        { return not defined $b }
    elsif (not defined $b)     { return 0 }
    elsif (not ref $a)         { $a eq $b }
    elsif ($a eq $b)           { return 1 }
    elsif (ref $a ne ref $b)   { return 0 }
    elsif (ref $a eq 'SCALAR') { $$a eq $$b }
    elsif (ref $a eq 'ARRAY')  {
        if (@$a == @$b) {
            for (0..$#$a) {
                my $rval;
                return $rval unless ($rval = $self->deeplyIdentical($a->[$_], $b->[$_]));
            }
            return 1;
        }
        else { return 0 }
    }
    elsif (ref $a eq 'HASH')   {
        if (keys %$a == keys %$b) {
            for (keys %$a) {
                my $rval;
                return $rval unless ($rval = $self->deeplyIdentical($a->{$_}, $b->{$_}));
            }
            return 1;
        }
        else { return 0 }
    }
    elsif (ref $a eq ref $b)   { warn 'Cannot test '.(ref $a)."\n"; undef }
    else                       { return 0 }
}
	
	
	

}


#method getSynapseStatus ($data) {
#	#### UPDATE SYNAPSE
#	my $sample	=	$data->{sample};
#	my $stage	=	lc($data->{workflow});
#	my $status	=	$data->{status};
#	$status		=~	s/^error.+$/error/;
#
#	$self->logDebug("sample", $sample);
#	$self->logDebug("stage", $stage);
#	$self->logDebug("status", $status);
#
#	my $statemap		=	$self->synapse()->statemap();
#	my $synapsestatus	=	$statemap->{"$stage:$status"};
#	$self->logDebug("synapsestatus", $synapsestatus);
#
#	return $synapsestatus;	
#}
#
#method getSampleFromSynapse ($maxjobs) {
#	my $samples	=	$self->synapse()->getBamForWork($maxjobs);
#	$self->logDebug("samples", $samples);
#	
#	return $samples;
#}
#
