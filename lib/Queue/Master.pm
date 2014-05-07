use MooseX::Declare;

=head2

NOTES

	Use SSH to parse logs and execute commands on remote nodes
	
TO DO

	Use queues to communicate between master and nodes:
	
		WORKERS REPORT STATUS TO MANAGER
	
		MANAGER DIRECTS WORKERS TO:
		
			- DEPLOY APPS
			
			- PROVIDE WORKFLOW STATUS
			
			- STOP/START WORKFLOWS

=cut

use strict;
use warnings;

class Queue::Master with (Logger, Exchange, Agua::Common::Database) {

#####////}}}}}

# Integers
has 'showlog'	=>  ( isa => 'Int', is => 'rw', default => 2 );
has 'printlog'	=>  ( isa => 'Int', is => 'rw', default => 5 );
has 'maxjobs'	=>  ( isa => 'Int', is => 'rw', default => 10 );
has 'sleep'		=>  ( isa => 'Int', is => 'rw', default => 30 );

# Strings
has 'user'		=> ( isa => 'Str|Undef', is => 'rw', required	=>	0 );
has 'pass'		=> ( isa => 'Str|Undef', is => 'rw', required	=>	0 );
has 'host'		=> ( isa => 'Str|Undef', is => 'rw', required	=>	0 );
has 'vhost'		=> ( isa => 'Str|Undef', is => 'rw', required	=>	0 );
has 'modulestring'	=> ( isa => 'Str|Undef', is => 'rw', default	=> "Agua::Workflow" );
has 'rabbitmqctl'	=> ( isa => 'Str|Undef', is => 'rw', default	=> "/usr/sbin/rabbitmqctl" );

# Objects
has 'modules'	=> ( isa => 'ArrayRef|Undef', is => 'rw', lazy	=>	1, builder	=>	"setModules");
has 'conf'		=> ( isa => 'Conf::Yaml', is => 'rw', required	=>	0 );
has 'nova'		=> ( isa => 'Openstack::Nova', is => 'rw', lazy	=>	1, builder	=>	"setNova" );
has 'synapse'	=> ( isa => 'Synapse', is => 'rw', lazy	=>	1, builder	=>	"setSynapse" );
has 'db'		=> ( isa => 'Agua::DBase::MySQL', is => 'rw', lazy	=>	1,	builder	=>	"setDbh" );
has 'jsonparser'=> ( isa => 'JSON', is => 'rw', lazy	=>	1, builder	=>	"setJsonParser" );

use FindBin qw($Bin);
use Test::More;
use Openstack::Nova;
use Synapse;

#####////}}}}}

method BUILD ($args) {
	$self->initialise($args);	
}

method initialise ($args) {
	#$self->logDebug("args", $args);
	#$self->manage();
}

method manage {
	
	#### MAINTAIN QUEUES AT LEVELS REQUIRED FOR OPTIMAL THROUGHPUT.
	#### ADD EXTRA JOBS IF NUMBER OF JOBS IN QUEUE IS BELOW THRESHOLD

	#### GET CURRENT QUEUES
	my $queues	=	$self->getQueues();
	$self->logDebug("queues", $queues);

	my $shutdown	=	$self->conf()->getKey("agua:SHUTDOWN", undef);
	$self->logDebug("shutdown", $shutdown);
	
	####### INITIALISE/UPDATE queuesample TABLE FROM SYNAPSE
	####### USE FIRST QUEUE FOR username, project AND workflow INFO
	###$self->updateSamples($queues);

	#### LISTEN FOR REPORTS FROM WORKERS
	$self->listenTopics();

	while ( not $shutdown eq "true" ) {
		foreach my $queue ( @$queues ) {
			$self->maintainQueue($queues, $queue);
		}

		my $sleep	=	$self->sleep();
		print "Queue::Master::manage    Sleeping $sleep seconds\n";
		sleep($sleep);
		$queues		=	$self->getQueues();
		$shutdown	=	$self->conf()->getKey("agua:SHUTDOWN", undef);
	}	
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
		my ($uuid, $synapsestatus)	=	$assignment	=~ /^\s*(\S+)\s+(\S+)/;
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
	my $query       =	qq{SELECT * FROM queue
ORDER BY username, project, workflownumber};
	$self->logDebug("query", $query);

	return	$self->db()->queryhasharray($query);
}

#### MAINTAIN QUEUES
method maintainQueue ($queues, $queuedata) {
	$self->logDebug("queuedata", $queuedata);
	
	my $queuename	=	$self->setQueueName($queuedata);
	$self->logDebug("queuename", $queuename);
	
	#### GET MAX JOBS
	my $maxjobs		=	$self->maxJobsForQueue($queuedata);
	$self->logDebug("FINAL maxjobs", $maxjobs);

	#### GET NUMBER OF QUEUED JOBS
	my $numberqueued	=	$self->getNumberQueuedJobs($queuename) || 0;
	$self->logDebug("numberqueued", $numberqueued);

	#### ADD MORE JOBS TO QUEUE IF LESS THAN maxjobs
	my $limit	=	$maxjobs - $numberqueued;
	$self->logDebug("limit", $limit);

	return 0 if $limit <= 0;

	#### QUEUE UP ADDITIONAL SAMPLES
	my $tasks	=	$self->getTasks($queues, $queuedata, $limit);
	
	
$self->logDebug("DEBUG RETURN") and return;

	$self->logDebug("tasks", $tasks);
	foreach my $task ( @$tasks ) {
		$self->sendTask($task);
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


$self->logDebug("DEBUG RETURN") and return [];

	#### REPLENISH queue TABLE IF EMPTY		
	if ( not defined $tasks or scalar(@$tasks) < $limit ) {
		$self->allocateSamples($queuedata, $limit);
		$tasks	=	$self->pullTasks($queues, $queuedata, $limit);
	}
	return if not defined $tasks;

	#### DIRECT THE TASK TO EXECUTE A WORKFLOW
	foreach my $task ( @$tasks ) {
		$task->{module}	=	"Agua::Workflow";
		$task->{mode}	=	"executeWorkflow";
		$task->{database}=	$queuedata->{database} || $self->database() || $self->conf()->getKey("database:DATABASE", undef);
		
		#### UPDATE TASK STATUS AS queued
		$task->{status}	=	"queued";
		$self->updateTaskStatus($task);
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

method listenTopics {
	$self->logDebug("");
	my $childpid = fork;
	if ( $childpid ) #### ****** Parent ****** 
	{
		$self->logDebug("PARENT childpid", $childpid);
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
	$channel->declare_exchange(
		exchange => $exchange,
		type => 'topic',
	);
	
	my $result = $channel->declare_queue(exclusive => 1);
	my $queuename = $result->{method_frame}->{queue};
	
	my $keys	=	$self->conf()->getKey("queue:topickeys", undef);
	$self->logDebug("keys", $keys);

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

	my $mode =	$data->{mode};
	$self->logDebug("mode", $mode);
	
	if ( $mode eq "hostStatus" ) {
		$self->updateHostStatus($data);
	}
	else {
		$self->updateTaskStatus($data);
	}
}

method updateTaskStatus ($data) {
	$self->logDebug("data", $data);
	my $keys	=	[ "username", "project", "workflow", "workflownumber", "sample", "stage", "stagenumber" ];
	my $notdefined	=	$self->notDefined($data, $keys);	
	$self->logDebug("notdefined", $notdefined) and return if @$notdefined;

	#### ADD TO provenance TABLE
	my $table	=	"provenance";
	$self->_addToTable($table, $data, $keys);

	#### UPDATE queue TABLE
	$self->updateQueue($data);	
}

method updateQueueSamples ($data) {
	$self->logDebug("data", $data);	
	
	#### UPDATE queuesample TABLE
	my $table	=	"queuesample";
	my $keys	=	["username", "project", "workflow", "workflownumber", "sample", "status" ];
	$self->_addToTable($table, $data, $keys);
	
	#### UPDATE SYNAPSE
	my $synapsestatus	=	$self->getSynapseStatus($data);
	my $sample	=	$data->{sample};
	$self->synapse()->change($sample, $synapsestatus);
}

method setConfigMaxJobs ($queuename, $value) {
	return $self->conf()->setKey("queue:maxjobs", $queuename, $value);
}

method getConfigMaxJobs ($queuename) {
	return $self->conf()->getKey("queue:maxjobs", $queuename);
}

method getSynapseStatus ($data) {
	#### UPDATE SYNAPSE
	my $sample	=	$data->{sample};
	my $stage	=	lc($data->{workflow});
	my $status	=	$data->{status};

	$self->logDebug("sample", $sample);
	$self->logDebug("stage", $stage);
	$self->logDebug("status", $status);

	my $statemap		=	$self->synapse()->statemap();
	my $synapsestatus	=	$statemap->{"$stage:$status"};
	$self->logDebug("synapsestatus", $synapsestatus);

	return $synapsestatus;	
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

method getNumberQueuedJobs ($queue) {
	$self->logDebug("queue", $queue);
	my $vhost	=	$self->conf()->getKey("queue:vhost", undef);
	$self->logDebug("vhost", $vhost);
	
	my $rabbitmqctl	=	$self->rabbitmqctl();
	$self->logDebug("rabbitmqctl", $rabbitmqctl);
	
	my $command	=	qq{$rabbitmqctl list_queues -p $vhost name messages};
	$self->logDebug("command", $command);
	my $output	=	`$command`;
	$self->logDebug("output", $output);
	
	my ($jobs)	=	$output	=~ /^$queue\s+(\d+)\s*/ms;
	$self->logDebug("jobs", $jobs);

	return $jobs;
}

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
        $modulepath =~ s/::/\//g;
        my $location    = "$installdir/lib/$modulepath.pm";
        #print "location: $location\n";
        my $class       = "$modulename";
        eval("use $class");
    
        my $object = $class->new({
            conf        =>  $self->conf(),
            showlog     =>  $self->showlog(),
            printlog    =>  $self->printlog()
        });
        print "object: $object\n";
        
        $modules->{$modulename} = $object;
    }

    return $modules; 
}

#### UTILS
method exited ($nodename) {	
	my $entries	=	$self->nova()->getEntries($nodename);
	foreach my $entry ( @$entries ) {
		my $internalip	=	$entry->{internalip};
		$self->logDebug("internalip", $internalip);
		my $status	=	$self->workflowStatus($internalip);	

		if ( $status =~ /Done, exiting/ ) {
			my $id	=	$entry->{id};
			$self->logDebug("DOING novaDelete($id)");
			$self->nova()->novaDelete($id);
		}
	}
}

method sleeping ($nodename) {	
	my $entries	=	$self->nova()->getEntries($nodename);
	foreach my $entry ( @$entries ) {
		my $internalip	=	$entry->{internalip};
		$self->logDebug("internalip", $internalip);
		my $status	=	$self->workflowStatus($internalip);	

		if ( $status =~ /Done, sleep/ ) {
			my $id	=	$entry->{id};
			$self->logDebug("DOING novaDelete($id)");
			$self->nova()->novaDelete($id);
		}
	}
}

method status ($nodename) {	
	my $entries	=	$self->nova()->getEntries($nodename);
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
			$self->nova()->novaDelete($id);
		}
	}
}

method getDownloadUuid ($ip) {
	$self->logDebug("ip", $ip);
	my $command =	qq{ssh -o "StrictHostKeyChecking no" -t ubuntu\@$ip "ps aux | grep /usr/bin/gtdownload"};
	$self->logDebug("command", $command);
	
	my $output	=	`$command`;
	#$self->logDebug("output", $output);

	my @lines	=	split "\n", $output;
	#$self->logDebug("lines", \@lines);
	
	my $uuid	=	$self->parseUuid(\@lines);
	
	return $uuid;
}

method workflowStatus ($ip) {
	$self->logDebug("ip", $ip);
	my $command =	qq{ssh -o "StrictHostKeyChecking no" -t ubuntu\@$ip "tail -n1 ~/worker.log"};
	$self->logDebug("command", $command);
	
	my $status	=	`$command`;
	$self->logDebug("status", $status);
	
	return $status;
}

method downloadPercent ($status) {
	#$self->logDebug("status", $status);
	my ($percent)	=	$status	=~ /\(([\d\.]+)\% complete\)/;
	$self->logDebug("percent", $percent);
	
	return $percent;
}

method parseUuid ($lines) {
	$self->logDebug("lines length", scalar(@$lines));
	for ( my $i = 0; $i < @$lines; $i++ ) {
		#$self->logDebug("lines[$i]", $$lines[$i]);
		
		if ( $$lines[$i] =~ /\-d ([a-z0-9\-]+)/ ) {
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


method setNova {

	my $nova	= Openstack::Nova->new({
	conf		=>	$self->conf(),
    showlog     =>  $self->showlog(),
    printlog    =>  $self->printlog(),
    logfile     =>  $self->logfile()
});

	$self->nova($nova);
}

method setSynapse {

	my $synapse	= Synapse->new({
		conf		=>	$self->conf(),
		showlog     =>  $self->showlog(),
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

}
