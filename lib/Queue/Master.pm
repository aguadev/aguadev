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

class Queue::Master with (Logger, Exchange, Agua::Common::Database, Agua::Common::Timer, Agua::Common::Project, Agua::Common::Stage) {

#####////}}}}}

{

# Integers
has 'log'	=>  ( isa => 'Int', is => 'rw', default => 2 );
has 'printlog'	=>  ( isa => 'Int', is => 'rw', default => 5 );
has 'maxjobs'	=>  ( isa => 'Int', is => 'rw', default => 10 );
has 'sleep'		=>  ( isa => 'Int', is => 'rw', default => 30 );

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
has 'virtual'=> ( isa => 'Any', is => 'rw', lazy	=>	1, builder	=>	"setVirtual" );

}

#### EXTERNAL MODULES
use FindBin qw($Bin);
use Test::More;
use POSIX qw(ceil);

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

	#### MAINTAIN OPTIMAL THROUGHPUT:
	#
	#### 1. DECIDE JOB THRESHOLD FOR EACH QUEUE BASED ON THROUGHPUT
	#    AND AVAILABLE RESOURCES (CPU, MEMORY)
	#
	#### 2. ADJUST maxjobs THRESHOLD IN CONFIG FILE
	#
	#### 3. ADD/REMOVE VMS TO/FROM QUEUES BASED ON JOB THRESHOLDS
	#
	#### 4. REPLENISH NUMBER OF JOBS IN EACH QUEUE IF BELOW THRESHOLD

	####### INITIALISE/UPDATE queuesample TABLE FROM SYNAPSE
	####### USE FIRST QUEUE FOR username, project AND workflow INFO
	###$self->updateSamples($queues);

	#### LISTEN FOR REPORTS FROM WORKERS
	my $shutdown	=	$self->conf()->getKey("agua:SHUTDOWN", undef);
	$self->logDebug("shutdown", $shutdown);
	$self->listenTopics() if not $shutdown eq "true";

	#### 
	while ( not $shutdown eq "true" ) {
		my $tenants		=	$self->getTenants();
		$self->logDebug("tenants", $tenants);
		foreach my $tenant ( @$tenants ) {
			my $username	=	$tenant->{username};
			my $projects	=	$self->getRunningUserProjects($username);
			$self->logDebug("projects", $projects);

			foreach my $project	( @$projects ) {
				$self->logDebug("project", $project);
	
				#### GET CURRENT QUEUE SAMPLES
				my $queues	=	$self->getDistinctQueues($project);
				$self->logDebug("queues", $queues);
		
				#### GET QUEUE TASK COUNTS LIST FROM RABBITMQ
				my $queuetasks	=	$self->getQueueTasks();
				$self->logDebug("queuetasks", $queuetasks);
		
				#### 1. DECIDE JOB THRESHOLD FOR EACH QUEUE BASED ON THROUGHPUT
				#    AND AVAILABLE RESOURCES (CPU, MEMORY)
				#
				#### 2. ADJUST maxjobs THRESHOLD IN CONFIG FILE
				#
				$self->balanceQueues($queues);
		
				#### 3. ADD/REMOVE VMS TO/FROM QUEUES BASED ON JOB THRESHOLDS
				#
				#### 4. REPLENISH NUMBER OF JOBS IN EACH QUEUE IF BELOW THRESHOLD
				#
				$self->maintainQueues($queues, $queuetasks);
			}
			
		}
		
		#### PAUSE
		$self->pause();

		#### GET SYSTEM SHUTDOWN (USE FOR TESTING)
		$shutdown	=	$self->updateShutdown();
	}
	
	return 1;
}

method updateShutdown {
	$self->logDebug("");
	
	return $self->conf()->getKey("agua:SHUTDOWN", undef);
}

method getTenants {
	my $query	=	qq{SELECT *
FROM tenant};
	$self->logDebug("query", $query);

	return $self->db()->queryhasharray($query);
}

method pause {
	my $sleep	=	$self->sleep();
	print "Queue::Master::pause    Sleeping $sleep seconds\n";
	sleep($sleep);
}

#### MAINTAIN QUEUES
method getProjects ($username) {
	return if not defined $username;
	return $self->db()->queryarray("SELECT * FROM project WHERE username='$username'");
}
method maintainQueues($queues, $queuelist) {
	foreach my $queue ( @$queues ) {
		$self->maintainQueue($queues, $queuelist, $queue);
	}
}

method maintainQueue ($queues, $queuelist, $queuedata) {
	$self->logDebug("queuedata", $queuedata);
	
	my $queuename	=	$self->setQueueName($queuedata);
	$self->logDebug("queuename", $queuename);
	
	#### GET MAX JOBS
	my $maxjobs		=	$self->maxJobsForQueue($queuedata);
	$self->logDebug("FINAL maxjobs", $maxjobs);

	#### GET NUMBER OF QUEUED JOBS
	my $numberqueued	=	$self->getNumberQueuedJobs($queuelist, $queuename) || 0;
	$self->logDebug("numberqueued", $numberqueued);

	#### ADD MORE JOBS TO QUEUE IF LESS THAN maxjobs
	my $limit	=	$maxjobs - $numberqueued;
	$self->logDebug("limit", $limit);

	return 0 if $limit <= 0;

	#### QUEUE UP ADDITIONAL SAMPLES
	my $tasks	=	$self->getTasks($queues, $queuedata, $limit);
	$self->logDebug("tasks", $tasks);

	if ( $numberqueued == 0 and not @$tasks ) {
		$self->logDebug("Setting workflow $queuedata->{workflow} status to 'completed'");
		$queuedata->{name}	=	$queuedata->{workflow};
		$self->setWorkflowStatus($queuedata, "completed");
	}
	elsif ( @$tasks ) {
		foreach my $task ( @$tasks ) {
			$self->sendTask($task);
		}
	}
	
	return 1;
}

method getTasks ($queues, $queuedata, $limit) {
	#### GET ADDITIONAL SAMPLES TO ADD TO QUEUE
	$self->logDebug("queuedata", $queuedata);
	$self->logDebug("limit", $limit);

	#### GET TASKS FROM queuesample TABLE
	my $tasks	=	$self->pullTasks($queues, $queuedata, $limit);
	$self->logDebug("tasks", $tasks);

	#### REPLENISH queue TABLE IF EMPTY		
	my $workflownumber	=	$queuedata->{workflownumber};
	$self->logDebug("workflownumber", $workflownumber);
	
	if ( $workflownumber == 1 and (not defined $tasks or scalar(@$tasks) < $limit) ) {
		$self->allocateSamples($queuedata, $limit);
		$tasks	=	$self->pullTasks($queues, $queuedata, $limit);
	}
	return if not defined $tasks;

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
		$task->{queued}		=	$self->getMysqlTime();

		$self->updateJobStatus($task);
	}
	
	return $tasks;
}

method pullTasks ($queues, $queuedata, $limit) {
	$self->logDebug("queues", $queues);
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
	$self->logDebug("query", $query);
	
	return $self->db()->queryhasharray($query) || [];
}

method getPrevious ($queues, $queuedata) {
	$self->logDebug("queues", $queues);
	$self->logDebug("queuedata", $queuedata);

	my $workflownumber	=	$queuedata->{workflownumber};
	$self->logDebug("workflownumber", $workflownumber);
	
	my $previous	=	{};
	if ( $workflownumber == 1 ) {
		$previous->{status}		=	"none";
		$previous->{username}	=	$queuedata->{username};
		$previous->{project}	=	$queuedata->{project};
		$previous->{workflow}	=	$queuedata->{workflow};
		$previous->{workflownumber}	=	$queuedata->{workflownumber};
	}
	else {
		my $previousdata		=	$$queues[$workflownumber - 2];
		$previous->{status}		=	"completed";
		$previous->{username}	=	$previousdata->{username};
		$previous->{project}	=	$previousdata->{project};
		$previous->{workflow}	=	$previousdata->{workflow};
		$previous->{workflownumber}	=	$previousdata->{workflownumber};
	}

	return $previous;	
}

#### BALANCE
method balanceQueues ($queues) {
	$self->logDebug("queues", $queues);

	# 1. CALCULATE AVERAGE DURATION OF completed SAMPLES IN EACH WORKFLOW/QUEUE
	#
	my $durations	=	$self->getDurations($queues);

	#### NARROW DOWN TO ONLY QUEUES WITH CLUSTERS
	$queues	=	$self->clusterQueuesOnly($queues);	

	#### GET REQUIRED RESOURCES FOR QUEUE INSTANCES (CPUs, RAM, ETC.)
	my $instances	=	$self->getInstances($queues);
	$self->logDebug("instances", $instances);
	
	# 3. IF LATEST RUNNING WORKFLOW HAS NO COMPLETED JOBS, SET
	#	INSTANCE COUNT FOR LAST WORKFLOW TO cluster->minnodes
	my $latestcompleted =	$self->getLatestCompleted($queues);
	$self->logDebug("latestcompleted", $latestcompleted);
	
	if ( not defined $latestcompleted) {

	
	
	#### SET FIRST NODES TO MAX NO SAMPLES COMPLETED
	my $firstqueuename		=	$self->getQueueName($$queues[0]);
	$self->logDebug("firstqueuename", $firstqueuename);
	my $instance		=	$instances->{$firstqueuename};
	$self->logDebug("instance", $instance);
	my $metric	=	$self->metric();
	my $firstresource	=	$instance->{$metric};
	


		my $firstcluster	=	$self->getQueueCluster($$queues[0]);
		$self->logDebug("firstcluster", $firstcluster);
		my $maxnodes		=	$firstcluster->{maxnodes};
		$self->logDebug("maxnodes", $maxnodes);
		
		my $resourcecount 	=	$firstresource * $maxnodes;
		$self->logDebug("resourcecount", $resourcecount);

		my $username	=	$$queues[0]->{username};
		my $quota	=	$self->getResourceQuota($username, $metric);
		$self->logDebug("quota", $quota);
		
		if ( $resourcecount > $quota ) {
			#code
		}
		
		
		#my $resourcecount 	=	$firstresource * $maxnodes;
		#$self->logDebug("resourcecount", $resourcecount);
	}
	
$self->logDebug("DEBUG EXIT") and exit;

	#### GET CURRENT COUNT OF VMS PER QUEUE (queuesample STATUS 'started')
	#### ASSUMES ONE VM PER TASK
	my $currentcounts=	$self->getCurrentCounts();
	$self->logDebug("currentcounts", $currentcounts);
	
	# 2. BALANCE COUNTS BASED ON DURATION
	#
	my $resourcecounts	=	$self->getResourceCounts($queues, $durations, $instances);
	my $instancecounts	=	$self->getInstanceCounts($queues, $instances, $resourcecounts);
	$self->logDebug("instancecounts", $instancecounts);
	

	
	if ( $latestcompleted < scalar(@$queues) - 1) {
		$instancecounts	=	$self->adjustCounts($queues, $resourcecounts, $latestcompleted);
	}
	$self->logDebug("instancecounts", $instancecounts);
	
	for ( my $i = 0; $i < @$instancecounts; $i++ ) {
		my $instancecount =	$$instancecounts[$i];
		$self->logDebug("instancecount", $instancecount);

		my $queue	=	$$queues[$i];
		$self->logDebug("queue", $queue);
		my $queuename	=	$self->getQueueName($queue);
		$self->logDebug("queuename", $queuename);
		
		my $currentcount =	$currentcounts->{$queuename};
		$self->logDebug("currentcount", $currentcount);
		
		my $difference	=	$instancecount - $currentcount;
		$self->logDebug("difference	= $instancecount - $currentcount");
		$self->logDebug("difference", $difference);
		
		if ( $difference > 0 ) {
			$self->addNodes($queue, $difference);
		}
		elsif ( $difference < 0 ) {
			$self->removeNodes($queue, $difference);
		}
	}

	#   TAILOUT AT END OF SAMPLE RUN:
	#   NB: maxJobs <= NUMBER OF REMAINING SAMPLES FOR THE WORKFLOW
}

method clusterQueuesOnly ($queues) {
	my $firstcluster	=	$self->getQueueCluster($$queues[0]);
	$self->logDebug("firstcluster", $firstcluster);
	while ( not defined $firstcluster ) {
		splice @$queues, 0, 1;		
		$firstcluster	=	$self->getQueueCluster($$queues[0]);
		$self->logDebug("firstcluster", $firstcluster);
	}
	$self->logDebug("CLUSTER ONLY queues", $queues);

	return $queues;
}

method addNodes ($queue, $nodes) {
	my $username	=	$queue->{username};
	my $project		=	$queue->{project};
	my $workflow	=	$queue->{workflow};
	
	my $cluster		=	$self->getQueueName($queue);

	#	1. GET amiid, instancetype FOR cluster = username.project.workflow
	my $clusterobject	=	$self->getQueueCluster($queue);
	my $amiid			=	$clusterobject->{amiid};
	my $instancetype	=	$clusterobject->{instancetype};
	$self->logDebug("amiid", $amiid);
	$self->logDebug("instancetype", $instancetype);
	
	#	2. PRINT USERDATA FILE
	my $userdatafile	=	$self->printConfig($queue);
	
	# 	3. PRINT OPENSTACK AUTHENTICATION *-openrc.sh FILE
	my $virtualtype		=	$self->conf()->getKey("agua", "VIRTUALTYPE");
	my $authfile;
	if ( $virtualtype eq "openstack" ) {
		$authfile	=	$self->printAuth($username);
	}
	$self->logDebug("authfile", $authfile);
	
	#	4. SPIN UP cluster.maxnodes OF VMs FOR FIRST WORKFLOW
	my $name	=	$workflow;
	my $success	=	$self->virtual()->launchNodes($authfile, $amiid, $nodes, $instancetype, $userdatafile, $name);
	$self->logDebug("success", $success);
	
	#	5. SET WORKFLOW STATUS
	$self->setWorkflowStatus($username, $project, $workflow, "running") if $success == 1;
	$self->setWorkflowStatus($username, $project, $workflow, "error") if $success == 0;
	$self->logDebug("success", $success);
	
	return $success;
}

method printConfig ($workflowobject) {
	#		GET PACKAGE INSTALLDIR
	my $stages			=	$self->getStagesByWorkflow($workflowobject);
	my $object			=	$$stages[0];
	#$self->logDebug("stages[0]", $object);	

	my $basedir			=	$self->conf()->getKey("agua", "INSTALLDIR");
	$object->{basedir}	=	$basedir;
	
	my $version			=	$object->{version};
	my $package			=	$object->{package};
	
	#		GET TEMPLATE
	my $installdir		=	$object->{installdir};
	my $templatefile	=	$self->setTemplateFile($installdir);
	$self->logDebug("templatefile", $templatefile);
	
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
	
	$self->virtual()->createConfigFile($object, $templatefile, $targetfile);
	
	return $targetfile;
}

method setTemplateFile ($installdir) {
	$self->logDebug("installdir", $installdir);
	
	return "$installdir/data/userdata.tmpl";
}

method getTenant ($username) {
	my $query	=	qq{SELECT *
FROM tenant
WHERE username='$username'};
	$self->logDebug("query", $query);

	return $self->db()->queryhash($query);
}

method adjustCounts ($queues, $resourcecounts, $latestcompleted) {
	my $nextqueue	=	$$queues[$latestcompleted + 1];
	$self->logDebug("nextqueue", $nextqueue);
	my $nextqueuename	=	$self->getQueueName($nextqueue);
	$self->logDebug("nextqueuename", $nextqueuename);
	
	my $cluster	=	$self->getQueueCluster($nextqueue);
	$self->logDebug("cluster", $cluster);
	my $min			=	$cluster->{minnodes};
	$self->logDebug("min", $min);

	my $instances	=	$self->getInstances($queues);
	my $instance	=	$instances->{$nextqueuename};
	$self->logDebug("instance", $instance);
	my $metric		=	$self->metric();
	my $resource	=	$instance->{$metric};
	
	my $total	=	0;
	foreach my $resourcecount ( @$resourcecounts ) {
		$total	+=	$resourcecount;
	}
	$self->logDebug("total", $total);
	
	my $latestcount	=	($min * $resource);
	my $newtotal	=	$total - $latestcount;
	$self->logDebug("newtotal", $newtotal);
	
	foreach my $resourcecount ( @$resourcecounts ) {
		$resourcecount	=	$resourcecount * ($newtotal/$total);
	}
	$self->logDebug("resourcecounts", $resourcecounts);
	push @$resourcecounts, $latestcount;
	
	return $self->getInstanceCounts($queues, $instances, $resourcecounts);
}

method getResourceCounts ($queues, $durations, $instances) {
=doc

=head2	ALGORITHM
	At max throughput:
	[1] T = t1 = t2 = t3
	Where T = total throughput, tx = throughput for workflow x

	Given N is a finite resource (e.g., number of VMs)
	[2] N = n1 + n2 + n3 + ... + nX
	Where X = total no. of workflows, nx = the no. of VMs

	Define:
	[3] tx = dx/nx
	Where tx = throughput for workflow x, dx = duration of workflow x, nx = number of resources used in workflow x (e.g., VMs)

	STEPS:

		1. Solve for n1 using [1], [2] and [3]
		n1 = N/(1 + d2/d1 + d3/d1 + ... + dx/d1)

		2. Calculate n2, n3, etc. using [1] and [3] (d1/n1 = d2/n2)
		n2 = (n1 . d2) / d1

=cut

	my $username	=	$$queues[0]->{username};
	my $metric	=	$self->metric();
	my $quota	=	$self->getResourceQuota($username, $metric);
	
	$self->logDebug("username", $username);
	$self->logDebug("queues", $queues);
	$self->logDebug("durations", $durations);
	$self->logDebug("instances", $instances);
	$self->logDebug("metric", $metric);
	
	#### GET INDEX OF LATEST RUNNING WORKFLOW
	my $latestcompleted =	$self->getLatestCompleted($queues);
	$self->logDebug("latestcompleted", $latestcompleted);

	my $totalresource	=	$self->getResourceQuota($username, $metric);
	my $firstqueue		=	$self->getQueueName($$queues[0]);
	$self->logDebug("firstqueue", $firstqueue);
	my $instance		=	$instances->{$firstqueue};
	$self->logDebug("instance", $instance);
	my $firstresource	=	$instance->{$metric};
	my $firstduration	=	$durations->{$firstqueue} * $firstresource;
	$self->logDebug("totalresource", $totalresource );
	$self->logDebug("firstresource", $firstresource);
	
	#$self->logDebug("firstqueue", $firstqueue);
	#$self->logDebug("firstresource", $firstresource);
	#$self->logDebug("firstduration", $firstduration);
	
	my $terms	=	1;
	for ( my $i = 1; $i < $latestcompleted + 1; $i++ ) {
		my $queue	=	$$queues[$i];
		#$self->logDebug("queue $i", $queue);
		my $queuename	=	$self->getQueueName($queue);
		#$self->logDebug("queuename", $queuename);

		my $duration	=	$durations->{$queuename};
		#$self->logDebug("duration", $duration);

		my $instance	=	$instances->{$queuename};
		#$self->logDebug("instance", $instance);
		my $resource	=	$instance->{$metric};
		#$self->logDebug("resource ($metric)", $resource);

		my $adjustedduration	=	$duration * $resource;
		
		my $term	=	$adjustedduration/$firstduration;
		#$self->logDebug("term", $term);
		
		$terms		+=	$term;
	}
	#$self->logDebug("FINAL terms", $terms);
	
	my $firstcount	=	$totalresource / $terms;
	#$self->logDebug("firstcount", $firstcount);

	my $firstthroughput	=	($firstduration/3600) * $firstcount;
	#$self->logDebug("firstthroughput", $firstthroughput);

	my $queuenames	=	$self->getQueueNames($queues);
	#$self->logDebug("queuenames", $queuenames);

	my $resourcecounts	=	[];
	for ( my $i = 0; $i < $latestcompleted + 1; $i++ ) {
		my $queuename	=	$$queuenames[$i];
		#$self->logDebug("queuename", $queuename);

		my $duration	=	$durations->{$queuename};
		#$self->logDebug("duration", $duration);

		my $instance	=	$instances->{$queuename};
		#$self->logDebug("instance", $instance);
		my $resource	=	$instance->{$metric};
		#$self->logDebug("resource ($metric)", $resource);

		my $adjustedduration	=	$duration * $resource;
		#$self->logDebug("adjustedduration", $adjustedduration);
		
		my $resourcecount	=	($firstcount * $adjustedduration) / $firstduration;
		#$self->logDebug("resourcecount", $resourcecount);

		my $throughput	=	(3600/$adjustedduration) * $resourcecount;
		#$self->logDebug("throughput", $throughput);

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

method getInstanceCounts ($queues, $instances, $resourcecounts) {
	my $metric	=	$self->metric();
	$self->logDebug("metric", $metric);

	my $counts	=	[];
	my $resourcetotal	=	0;
	my $integertotal	=	0;
	for ( my $i = 0; $i < @$resourcecounts; $i++ ) {
		my $queuename	=	$self->getQueueName($$queues[$i]);
		my $resource	=	$instances->{$queuename}->{$metric};
		$self->logDebug("resource", $resource);
		my $resourcecount 	=	$$resourcecounts[$i] / $resource;
		
		#### STASH RUNNING COUNT
		$resourcetotal		+=	$$resourcecounts[$i];

		if ( $i == scalar(@$resourcecounts) - 1) {
			push @$counts, int( ($resourcetotal - $integertotal) / $resource );
		}
		else {
			my $count	=	ceil($$resourcecounts[$i]/$resource);
			$count		=	1 if $count < 1;

			#### STASH RUNNING INTEGER COUNT
			$integertotal	+=	$count * $resource;

			push @$counts, $count;
		}
	}
	
	return $counts;
}

method getQueueNames ($queues) {
	$self->logDebug("queues", $queues);
	
	my $queuenames	=	[];
	for ( my $i = 0; $i < @$queues; $i++ ) {
		my $queue	=	$$queues[$i];
		#$self->logDebug("queue $i", $queue);
		my $queuename	=	$self->getQueueName($queue);
		$self->logDebug("queuename", $queuename);

		push @$queuenames, $queuename;
	}

	return $queuenames;
}

method getResourceQuota ($username, $metric) {
	$self->logDebug("username", $username);
	$self->logDebug("metric", $metric);
	
	my $quota	=	$self->getQuota($username);
	$self->logDebug("quota", $quota);
	
	if ( $metric eq "cpus" ) {
		my $quota	=	$self->getQuota($username);
		$self->logDebug("quota", $quota);
	}
	
}

method getQuota ($username) {
	$self->logDebug("username", $username);
	my $tenant	=	$self->getTenant($username);
	$self->logDebug("tenant", $tenant);
	
	
	
}

method getInstances ($queues) {
	my $instances	=	{};
	foreach my $queue ( @$queues ) {
		#$self->logDebug("queue", $queue);
		my $queuename	=	$self->getQueueName($queue);
		#$self->logDebug("queuename", $queuename);
		
		my $instance	=	$self->getQueueInstance($queue);
		$instances->{$queuename}	= $instance;
	}
	#$self->logDebug("instances", $instances);
	
	return $instances;
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

method getCurrentCounts {
	my $query	=	qq{SELECT queue, COUNT(*) AS count
FROM instance
GROUP BY queue};
	$self->logDebug("query", $query);
	my $entries	=	$self->db()->queryhasharray($query);
	$self->logDebug("entries", $entries);
	my $counts	=	{};
	foreach my $entry ( @$entries ) {
		$counts->{$entry->{queue}}	=	$entry->{count}
	}
	$self->logDebug("counts", $counts);

	return $counts;
}

method setMaxQuota ($queues, $instancecounts, $latestindex) {

	#### GET MAX JOBS
	my $maxjobs		=	$self->maxJobsForQueue($$queues[$latestindex]);
	$self->logDebug("maxjobs", $maxjobs);

	
}

method getRunningUserProjects ($username) {
	$self->logDebug("username", $username);
	my $query	=	qq{SELECT name FROM project
WHERE username='$username'
AND status='running'};
	$self->logDebug("query", $query);
	my $projects	=	$self->db()->queryarray($query);
	
	return $projects;
}

method getLatestCompleted ($queues) {
	#$self->logDebug("queues", $queues);

	my $latestindex;
	for ( my $i = 0; $i < @$queues; $i++ ) {
		my $completed 	=	$self->getCompletedSamples($$queues[$i]);
		#$self->logDebug("completed", $completed);
		$latestindex = $i if defined $completed;
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
		my $completed 	=	$self->getStartedSamples($$queues[$i]);
		#$self->logDebug("completed", $completed);
		$latestindex = $i if defined $completed;
	}
	
	return $latestindex;
}

method getStartedSamples ($queue) {
	my $query	=	qq{SELECT * FROM queuesample
WHERE username='$queue->{username}'
AND project='$queue->{project}'
AND workflow='$queue->{workflow}'
AND workflownumber=$queue->{workflownumber}
AND status='started'
ORDER BY sample};
	#$self->logDebug("query", $query);
	my $samples	=	$self->db()->queryhasharray($query);
	#$self->logDebug("samples", $samples);

	return $samples;	
}
method getQueueInstance ($queue) {
	#$self->logDebug("queue", $queue);
	my $queuename	=	$self->getQueueName($queue);
	$self->logDebug("queuename", $queuename);
	my $query	=	qq{SELECT * FROM instancetype
WHERE username='$queue->{username}'
AND cluster='$queuename'};
	#$self->logDebug("query", $query);
	my $instance	=	$self->db()->queryhash($query);
	#$self->logDebug("instance", $instance);	
	
	return $instance;
}

method getQueueCluster ($queue) {
	$self->logDebug("queue", $queue);
	my $queuename	=	$self->getQueueName($queue);
	my $query	=	qq{SELECT * FROM cluster
WHERE username='$queue->{username}'
AND cluster='$queuename'};
	$self->logDebug("query", $query);
	my $instance	=	$self->db()->queryhash($query);
	$self->logDebug("instance", $instance);
	
	return $instance;
}


method getDurations ($queues) {
	my $durations	=	{};
	foreach my $queue ( @$queues ) {
		#$self->logDebug("queue", $queue);
		my $queuename	=	$queue->{username} . "." . $queue->{project} . "." . $queue->{workflow};
		#$self->logDebug("queuename", $queuename);

		#last if $self->queueNotRunning($queue);
		my $duration	=	$self->getQueueDuration($queue);
		$durations->{$queuename}	= $duration;
	}		

	return $durations;
}

method getQueueDuration ($queue) {
	#$self->logDebug("queue", $queue);

	my $provenance	=	$self->getQueueProvenance($queue);
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
		$duration += $queueduration;
	}
	$duration = $duration / scalar(@$totaldurations) if @$totaldurations;
	#$self->logDebug("FINAL AVERAGE duration", $duration);

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
	if ( $date =~ m{^(\d{1,4})\W*0*(\d{1,2})\W*0*(\d{1,2})\W*0*\s+(\d{0,2})\W*0*(\d{0,2})\W*0*(\d{0,2})}x) {
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

method getQueueInstances ($queue) {
	$self->logDebug("queue", $queue);

#	my $query	=	qq{SELECT * FROM instancetype
#WHERE username='$queue->{username}
#AND cluster='$queue->{}'};
#	my $typeobject	=	$self->db()->query($query);
    #username        VARCHAR(30) NOT NULL,
    #cluster         VARCHAR(30) NOT NULL,
    #instancetype    VARCHAR(20),
    #cpus        	INT(12),
    #memory        	INT(12),
    #disk       		INT(12),
    #ephemeral      	INT(12),
}


#### UPDATE SAMPLES
method updateSamples ($queues) {

	$self->logDebug("queues", $queues);
	
	#### NB: ASSUMES ONLY ONE PROJECT IN queues: PanCancer
	
	my $project		=	$$queues[0]->{project};
	$self->logDebug("project", $project);
	my $username		=	$$queues[0]->{username};
	$self->logDebug("username", $username);
	my $defaultworkflow		=	$$queues[0]->{workflow};
	$self->logDebug("defaultworkflow", $defaultworkflow);

	my $assignments	=	$self->getSampleList();
	$self->logDebug("no. assignments", scalar(@$assignments));
	$self->logDebug("assignements[0]", $$assignments[0]);
	
	my $statemap	=	$self->synapse()->reversestatemap();
	$self->logDebug("statemap", $statemap);

	my $workflowmap;
	%$workflowmap	=	map { $_->{workflow} => $_->{workflownumber} } @$queues;
	$self->logDebug("workflowmap", $workflowmap);

	my $counter = 0;

	foreach my $assignment ( @$assignments ) {
		my ($uuid, $synapsestatus)	=	$assignment	=~ /^(), "\s*(\S+)\s+(\S+)/;
		$self->logDebug("uuid", $uuid);
		$self->logDebug("synapsestatus", $synapsestatus);

		my $statusstring	=	$statemap->{$synapsestatus};
		$self->logDebug("statusstring", $statusstring);

		my ($workflow, $status);
		if ( $statusstring eq "none", ) {
			$workflow	=	$defaultworkflow;
			$status		=	"none";
		}
		else {
			($workflow, $status)	=	$statusstring	=~ /^([^:]+):(.+)$/;
			$workflow	=	uc(substr($workflow, 0, 1)) . substr($workflow, 1);
		}
		
		$self->logDebug("workflow", $workflow);
		$self->logDebug("status", $status);
	
		my $queuedata	=	{};
		$queuedata->{project}	=	$project;
		$queuedata->{username}	=	$username;
		$queuedata->{workflow}	=	$workflow;
		$queuedata->{workflownumber}	=	$workflowmap->{$workflow};
		$queuedata->{status}	=	$status;
		$queuedata->{sample}	=	$uuid;
		
		if ( not $self->inSamples($uuid, $queuedata)) {
			$self->logDebug("DOING makeAssigned: $uuid, $synapsestatus");
			$self->addToSamples($uuid, $synapsestatus, $queuedata);
		}
	}
}

method inSamples ($uuid, $queuedata) {
	my $query	=	qq{SELECT 1 FROM queuesample
WHERE sample='$uuid'
AND username='$queuedata->{username}'
AND project='$queuedata->{project}'
AND workflow='$queuedata->{workflow}'
};
	$self->logDebug("query", $query);

	return $self->db()->query($query);
}

method addToSamples ($uuid, $state, $queuedata) {
	$self->logDebug("uuid", $uuid);
	$self->logDebug("state", $state);
	
	my $table	=	"queuesample";
	my $keys	=	["username", "project", "workflow", "sample" ];
	
	return $self->_addToTable($table, $queuedata, $keys);
}

method getSampleList {
	$self->logDebug("");

	return $self->synapse()->getSampleLines();
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

#### LISTEN FOR TOPICS 
method listenTopics {
	$self->logDebug("");
	my $childpid = fork;
	if ( $childpid ) {
		$self->logDebug("IN PARENT childpid", $childpid);
	}
	elsif ( defined $childpid ) {
		$self->receiveTopic();
	}
}


method receiveTopic {
	$self->logDebug("");
	
	#### OPEN CONNECTION
	my $connection	=	$self->newConnection();	
	my $channel = $connection->open_channel();
	
	my $exchange	=	$self->conf()->getKey("queue:topicexchange", undef);
	$self->logDebug("exchange", $exchange);

	$channel->declare_exchange(
		exchange => $exchange,
		type => 'topic',
	);
	
	my $result = $channel->declare_queue(exclusive => 1);
	my $queuename = $result->{method_frame}->{queue};
	
	my $keystring	=	$self->conf()->getKey("queue:topickeys", undef);
	$self->logDebug("keystring", $keystring);
	my $keys;
	@$keys		=	split ",", $keystring;
	
	$self->logDebug("exchange", $exchange);
	
	for my $key ( @$keys ) {
		$channel->bind_queue(
			exchange => $exchange,
			queue => $queuename,
			routing_key => $key,
		);
	}
	
	print " [*] Listening for topics: @$keys\n";

	no warnings;
	my $handler	= *handleTopic;
	use warnings;
	my $this	=	$self;

	$channel->consume(
        on_consume => sub {
			my $var = shift;
			my $body = $var->{body}->{payload};
		
			print " [x] Received message: $body\n";
			&$handler($this, $body);
		},
		no_ack => 1,
	);
	
	# Wait forever
	AnyEvent->condvar->recv;	
}

method handleTopic ($json) {
	$self->logDebug("json", $json);

	my $data = $self->jsonparser()->decode($json);
	#$self->logDebug("data", $data);

	my $mode =	$data->{mode} || "";
	$self->logDebug("mode", $mode);
	
	if ( $self->can($mode) ) {
		$self->$mode($data);
	}
	else {
		print "mode not supported: $mode\n";
		$self->logDebug("mode not supported: $mode");
	}
}

method updateJobStatus ($data) {
	$self->logDebug("data", $data);
	my $keys	=	[ "username", "project", "workflow", "workflownumber", "sample" ];
	my $notdefined	=	$self->notDefined($data, $keys);	
	$self->logDebug("notdefined", $notdefined) and return if @$notdefined;

	#### ADD TO provenance TABLE
	my $table		=	"provenance";
	my $fields		=	$self->db()->fields($table);
	$self->_addToTable($table, $data, $keys, $fields);

	#### UPDATE queuesamples TABLE
	$self->updateQueueSamples($data);	

	#### UPDATE SYNAPSE
	my $synapsestatus	=	$self->getSynapseStatus($data);
	my $sample	=	$data->{sample};
	$self->synapse()->change($sample, $synapsestatus);
}

method updateQueueSamples ($data) {
	$self->logDebug("data", $data);	
	
	#### UPDATE queuesample TABLE
	my $table	=	"queuesample";
	my $keys	=	[ "sample" ];
	$self->_removeFromTable($table, $data, $keys);
	
	$keys	=	["username", "project", "workflow", "workflownumber", "sample", "status" ];
	$self->_addToTable($table, $data, $keys);
}

method setConfigMaxJobs ($queuename, $value) {
	return $self->conf()->setKey("queue:maxjobs", $queuename, $value);
}

method getSynapseStatus ($data) {
	#### UPDATE SYNAPSE
	my $sample	=	$data->{sample};
	my $stage	=	lc($data->{workflow});
	my $status	=	$data->{status};
	$status		=~	s/^error.+$/error/;

	$self->logDebug("sample", $sample);
	$self->logDebug("stage", $stage);
	$self->logDebug("status", $status);

	my $statemap		=	$self->synapse()->statemap();
	my $synapsestatus	=	$statemap->{"$stage:$status"};
	$self->logDebug("synapsestatus", $synapsestatus);

	return $synapsestatus;	
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
	my $maxjobs		=	$self->getConfigMaxJobs($queuename);
	$self->logDebug("maxjobs", $maxjobs);
	if ( not defined $maxjobs ) {
		$maxjobs	=	$self->maxjobs(); #### EITHER DEFAULT OR USER-DEFINED
		
		$self->setConfigMaxJobs($queuename, $maxjobs);
	}
	
	return $maxjobs;
}

method getSampleFromSynapse ($maxjobs) {
	my $samples	=	$self->synapse()->getBamForWork($maxjobs);
	$self->logDebug("samples", $samples);
	
	return $samples;
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

method getNumberQueuedJobs ($queuelist, $queue) {
	#$self->logDebug("queuelist", $queuelist);
	$self->logDebug("queue", $queue);
	
	my ($jobs)	=	$queuelist	=~ /^$queue(), "\s+(\d+)\s*/ms;
	$self->logDebug("jobs", $jobs);

	return $jobs;
}

#### SEND TASK
method sendTask ($task) {	
	$self->logDebug("task", $task);
	my $processid	=	$$;
	$self->logDebug("processid", $processid);
	$task->{processid}	=	$processid;

	#### SET QUEUE
	my $queuename		=	$self->setQueueName($task);
	$task->{queue}		=	$queuename;	
	
	#### ADD UNIQUE IDENTIFIERS
	$task	=	$self->addIdentifiers($task);

	my $jsonparser = JSON->new();
	my $json = $jsonparser->encode($task);
	$self->logDebug("json", $json);

	#### GET CONNECTION
	my $connection	=	$self->newConnection();
	$self->logDebug("DOING connection->open_channel()");
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
	
	print " [x] Sent TASK: '$json'\n";
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
			log			=>	2,
			printlog	=>	2
        }
    ) or die "Can't create virtual of type: $virtualtype. $!\n";
	$self->logDebug("virtual", $virtual);
$self->logDebug("DEBUG EXIT") and exit;
	$self->virtual($virtual);
}


}


