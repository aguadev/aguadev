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

class Exchange::Manager with (Logger, Exchange, Agua::Common::Database) {

#####////}}}}}

# Integers
has 'showlog'	=>  ( isa => 'Int', is => 'rw', default => 2 );
has 'printlog'	=>  ( isa => 'Int', is => 'rw', default => 5 );
has 'maxjobs'	=>  ( isa => 'Int', is => 'rw', default => 10 );

# Strings
has 'user'		=> ( isa => 'Str|Undef', is => 'rw', required	=>	0 );
has 'pass'		=> ( isa => 'Str|Undef', is => 'rw', required	=>	0 );
has 'host'		=> ( isa => 'Str|Undef', is => 'rw', required	=>	0 );
has 'vhost'		=> ( isa => 'Str|Undef', is => 'rw', required	=>	0 );
has 'message'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0 );
has 'modulestring'	=> ( isa => 'Str|Undef', is => 'rw', default	=> "Agua::Workflow" );
has 'rabbitmqctl'	=> ( isa => 'Str|Undef', is => 'rw', default	=> "/usr/sbin/rabbitmqctl" );

# Objects
has 'modules'	=> ( isa => 'ArrayRef|Undef', is => 'rw', lazy	=>	1, builder	=>	"setModules");
has 'conf'		=> ( isa => 'Conf::Yaml', is => 'rw', required	=>	0 );
has 'db'		=> ( isa => 'Agua::DBase::MySQL', is => 'rw', required	=>	0 );
has 'jsonparser'=> ( isa => 'JSON', is => 'rw', lazy	=>	1, builder	=>	"setJsonParser" );

use FindBin qw($Bin);
use Test::More;

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
	my $shutdown	=	$self->conf()->getKey("shutdown", undef);

	#### LISTEN FOR REPORTS FROM WORKERS
	$self->listenTopics();

	while ( scalar(@$queues) > 0 and not $shutdown eq "true" ) {
		foreach my $queue ( @$queues ) {
			$self->maintainQueue($queue);
		}

		my $sleep	=	$self->sleep();	
		sleep($sleep);
		$queues		=	$self->getQueues();
		$shutdown	=	$self->conf()->getKey("shutdown", undef);
	}	
}

method maintainQueue ($queuedata) {
	$self->logDebug("queuedata", $queuedata);
	
	my $queuename	=	$self->setQueueName($queuedata);
	$self->logDebug("queuename", $queuename);
	
	#### GET MAX JOBS
	my $maxjobs		=	$self->maxJobsForQueue($queuedata);
	$self->logDebug("FINAL maxjobs", $maxjobs);

	#### GET NUMBER OF QUEUED JOBS
	my $numberqueued	=	$self->getNumberQueuedJobs($queuename);
	$self->logDebug("numberqueued", $numberqueued);

	#### ADD MORE JOBS TO QUEUE IF LESS THAN maxjobs
	my $limit	=	$maxjobs - $numberqueued;
	$self->logDebug("limit", $limit);

	return 0 if $limit <= 0;

	my $tasks	=	$self->getTasks($queuedata, $limit);
	$self->logDebug("tasks", $tasks);
	foreach my $task ( @$tasks ) {
		$self->sendTask($task);
	}
	
	return 1;
}

method setConfigMaxJobs ($queuename, $value) {
	return $self->conf()->setKey("queue:maxjobs", $queuename, $value);
}

method getConfigMaxJobs ($queuename) {
	return $self->conf()->getKey("queue:maxjobs", $queuename);
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

method receiveTopic ($message) {
	$self->logDebug("message", $message);

	#### OPEN CONNECTION
	my $connection	=	$self->newConnection();	
	my $channel = $connection->open_channel();

	my $exchange	=	$self->exchange();
	$self->logDebug("exchange", $exchange);
	
	$channel->declare_exchange(
		exchange => $exchange,
		type => 'topic',
	);
	
	my $result = $channel->declare_queue(exclusive => 1);
	my $queuename = $result->{method_frame}->{queue};
	
	my $keys	=	$self->keys();
	$self->logDebug("keys", $keys);

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

method updateQueue ($data) {
	$self->logDebug("data", $data);	
	
	#### UPDATE queue TABLE
	my $table	=	"queue";
	my $keys	=	["username", "project", "workflow", "workflownumber", "sample" ];
	$self->_addToTable($table, $data, $keys);
	
	#### UPDATE SYNAPSE
	my $synapsestatus	=	$self->getSynapseStatus($data);
	my $sample	=	$data->{sample};
	$self->synapse()->change($sample, $synapsestatus);
}

method getSynapseStatus ($data) {
	#### UPDATE SYNAPSE
	my $sample	=	$data->{sample};
	my $stage	=	lc($data->{workflow});
	my $status	=	$data->{status};

	$self->logDebug("sample", $sample);
	$self->logDebug("stage", $stage);
	$self->logDebug("status", $status);

	my $statemap	=	$self->synapse()->statemap();
	my $synapsestatus	=	$statemap->{"$stage:$status"};
	$self->logDebug("synapsestatus", $synapsestatus);

	return $synapsestatus;	
}

method getTasks ($queuedata, $limit) {
	#### GET UNQUEUED TASKS FOR QUEUEING
	$self->logDebug("queuedata", $queuedata);
	$self->logDebug("limit", $limit);

	#### GET TASKS FROM queue TABLE
	my $tasks	=	$self->pullTasks($queuedata, $limit);
	$self->logDebug("tasks", $tasks);

	#### REPLENISH queue TABLE IF EMPTY		
	if ( not defined $tasks or scalar(@$tasks) < $limit ) {
		$self->allocateSamples($queuedata, $limit);
		$tasks	=	$self->pullTasks($queuedata);
	}
	return if not defined $tasks;

	#### DIRECT THE TASK TO EXECUTE A WORKFLOW
	foreach my $task ( @$tasks ) {
		$task->{module}	=	"Agua::Workflow";
		$task->{mode}	=	"executeWorkflow";
		$task->{database}=	$queuedata->{database} || $self->database() || $self->conf()->getKey("database:DATABASE", undef);
		
		#### UPDATE TASK STATUS AS queued
		$self->updateTaskStatus($task, "queued");
	}
	
	return $tasks;
}

method updateTaskStatus ($task, $status) {
	$self->logDebug("status", $status);
	
	#### VERIFY VALUES
	my $notdefined	=	$self->notDefined($task, ["username", "project", "workflow", "workflownumber"]);
	$self->logCritical("not defined", $notdefined) and return if @$notdefined;

	my $query		=	qq{UPDATE queue
SET status='$status'
WHERE username='$task->{username}'
AND project='$task->{project}'
AND workflow='$task->{workflow}'
AND workflownumber='$task->{workflownumber}'};

	return $self->db()->do($query);
}

method pullTasks ($queuedata, $limit) {
	$self->logDebug("queuedata", $queuedata);

	#### VERIFY VALUES
	my $notdefined	=	$self->notDefined($queuedata, ["username", "project", "workflow", "workflownumber"]);
	$self->logCritical("not defined", $notdefined) and return if @$notdefined;

	my $query		=	qq{SELECT * FROM queue
WHERE username='$queuedata->{username}'
AND project='$queuedata->{project}'
AND workflow='$queuedata->{workflow}'
AND workflownumber='$queuedata->{workflownumber}'
AND status='none'
LIMIT $limit};
	$self->logDebug("query", $query);
	
	return $self->db()->queryhasharray($query) || [];
}

method pushTask ($task) {
	#### STORE UNQUEUED TASK IN queue TABLE
	$self->logDebug("task", $task);
	
	#### VERIFY VALUES
	my $notdefined	=	$self->notDefined($task, ["username", "project", "workflow", "workflownumber", "sample"]);
	$self->logCritical("not defined", $notdefined) and return if @$notdefined;

	my $status	=	"unassigned";
	my $table	=	"queue";
	my $keys	=	[ "username", "project", "workflow", "workflownumber", "sample" ];

	$self->_removeFromTable($table, $task, $keys);
	
	return $self->_addToTable($table, $task, $keys);

#	my $query	=	qq{INSERT INTO queue VALUES (
#'$task->{username}',
#'$task->{project}',
#'$task->{workflow}',
#'$task->{workflownumber}',
#'$task->{sample}',
#'$task->{status}'
#)};
#	$self->logDebug("query", $query);

#	return 0 if not $self->db()->do($query);
	#return 1;	
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
	$self->synapse()->getBamForWork($maxjobs);
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

method stopWorkflow ($ips, $type) {
	$self->logDebug("ips", $ips);
	$self->logDebug("type", $type);

}

method getWorkflows ($node) {
#### GET CURRENT WORKFLOW STATES (COMPLETED, EXITED)
	
	
}

method runCommand ($command) {
	$self->logDebug("command", $command);
	
	return `$command`;
}

method startWorkflow {
	

}


method getSampleList {
	
	#### LATER: TRIAGE
	my $list	=	$self->synapse()->getList();
	
	return;
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
