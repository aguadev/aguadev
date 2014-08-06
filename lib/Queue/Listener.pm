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

class Queue::Listener with (Logger, Exchange, Agua::Common::Database, Agua::Common::Timer, Agua::Common::Project, Agua::Common::Stage, Agua::Common::Workflow, Agua::Common::Util) {

#####////}}}}}

{

# Integers
has 'log'	=>  ( isa => 'Int', is => 'rw', default => 2 );
has 'printlog'	=>  ( isa => 'Int', is => 'rw', default => 5 );
has 'maxjobs'	=>  ( isa => 'Int', is => 'rw', default => 1 );
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
has 'virtual'	=> ( isa => 'Any', is => 'rw', lazy	=>	1, builder	=>	"setVirtual" );
has 'duplicate'	=> ( isa => 'HashRef|Undef', is => 'rw');

}

#### EXTERNAL MODULES
use FindBin qw($Bin);
use Test::More;

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

#### SEND TOPIC
method sendTopic ($data, $key) {
	$self->logDebug("$$ data", $data);
	$self->logDebug("$$ key", $key);

	my $exchange	=	$self->conf()->getKey("queue:topicexchange", undef);
	$self->logDebug("$$ exchange", $exchange);

	my $host		=	$self->host() || $self->conf()->getKey("queue:host", undef);
	my $user		= 	$self->user() || $self->conf()->getKey("queue:user", undef);
	my $pass	=	$self->pass() || $self->conf()->getKey("queue:pass", undef);
	my $vhost		=	$self->vhost() || $self->conf()->getKey("queue:vhost", undef);
	$self->logNote("$$ host", $host);
	$self->logNote("$$ user", $user);
	$self->logNote("$$ pass", $pass);
	$self->logNote("$$ vhost", $vhost);
	
    my $connection = Net::RabbitFoot->new()->load_xml_spec()->connect(
        host 	=>	$host,
        port 	=>	5672,
        user 	=>	$user,
        pass 	=>	$pass,
        vhost	=>	$vhost,
    );

	$self->logNote("$$ connection: $connection");
	$self->logNote("$$ DOING connection->open_channel");
	my $channel 	= 	$connection->open_channel();
	$self->channel($channel);

	$self->logNote("$$ DOING channel->declare_exchange");

	$channel->declare_exchange(
		exchange => $exchange,
		type => 'topic',
	);
	
	my $json	=	$self->jsonparser()->encode($data);
	$self->logDebug("$$ json", $json);
	$self->channel()->publish(
		exchange => $exchange,
		routing_key => $key,
		body => $json,
	);
	
	print "$$ [x] Sent topic with key '$key'\n";

	$connection->close();
}

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
	#$self->logDebug("CLUSTER ONLY clusterworkflows", $clusterworkflows);

	return $clusterworkflows;
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
	my $templatefile	=	$self->setTemplateFile($installdir, $version);
	$self->logDebug("templatefile", $templatefile);
	
	#		SET EXTRA
	my $queuename		=	$self->getQueueName($workflowobject);
	$self->logDebug("queuename", $queuename);
	my $extra			=	$self->getExtra($installdir, $version);
	$self->logDebug("extra", $extra);

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
	
	$self->virtual()->createConfig($object, $templatefile, $targetfile, $extra);
	
	return $targetfile;
}

method getExtra ($installdir, $version) {
	my $extrafile		=	"$installdir/$version/data/sh/extra";
	$self->logDebug("extrafile", $extrafile);
	
	return "" if not -f $extrafile;
	
	my $extra			=	$self->getFileContents($extrafile);

	return $extra;
}

method setTemplateFile ($installdir, $version) {
	$self->logDebug("installdir", $installdir);
	
	return "$installdir/data/tmpl/userdata.tmpl";
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
	
	my $latestcount	=	($min * $resource);
	my $newtotal	=	$total - $latestcount;
	$self->logDebug("newtotal", $newtotal);
	
	foreach my $resourcecount ( @$resourcecounts ) {
		$resourcecount	=	$resourcecount * ($newtotal/$total);
	}
	$self->logDebug("resourcecounts", $resourcecounts);
	push @$resourcecounts, $latestcount;
	
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

	my $username	=	$$queues[0]->{username};
	my $metric	=	$self->metric();
	
	$self->logDebug("username", $username);
	$self->logDebug("queues", $queues);
	$self->logDebug("durations", $durations);
	$self->logDebug("instancetypes", $instancetypes);
	$self->logDebug("metric", $metric);
	
	#### GET INDEX OF LATEST RUNNING WORKFLOW
	my $latestcompleted =	$self->getLatestCompleted($queues);
	$self->logDebug("latestcompleted", $latestcompleted);

	my $firstqueue		=	$self->getQueueName($$queues[0]);
	$self->logDebug("firstqueue", $firstqueue);
	my $instancetype		=	$instancetypes->{$firstqueue};
	$self->logDebug("instancetype", $instancetype);
	my $firstresource	=	$instancetype->{$metric};
	my $firstduration	=	$durations->{$firstqueue} * $firstresource;
	$self->logDebug("firstresource", $firstresource);
	
	$self->logDebug("firstqueue", $firstqueue);
	$self->logDebug("firstresource", $firstresource);
	$self->logDebug("firstduration", $firstduration);
	
	my $terms	=	1;
	for ( my $i = 1; $i < $latestcompleted + 1; $i++ ) {
		my $queue	=	$$queues[$i];
		$self->logDebug("queue $i", $queue);
		my $queuename	=	$self->getQueueName($queue);
		$self->logDebug("queuename", $queuename);

		my $duration	=	$durations->{$queuename};
		$self->logDebug("duration", $duration);
		next if not defined $duration or $duration == 0;
		
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
	
	my $firstcount	=	$quota / $terms;
	$self->logDebug("firstcount", $firstcount);

	my $firstthroughput	=	($firstduration/3600) * $firstcount;
	$self->logDebug("firstthroughput", $firstthroughput);

	my $queuenames	=	$self->getQueueNames($queues);
	$self->logDebug("queuenames", $queuenames);

	my $resourcecounts	=	[];
	for ( my $i = 0; $i < $latestcompleted + 1; $i++ ) {
		my $queuename	=	$$queuenames[$i];
		$self->logDebug("queuename", $queuename);

		my $duration	=	$durations->{$queuename};
		$self->logDebug("duration", $duration);
		push @$resourcecounts, undef if not defined $duration;
		
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

method getInstanceCounts ($queues, $instancetypes, $resourcecounts) {

=head2	SUBROUTINE	getInstanceCounts

=head2	PURPOSE
	
	Allocate instances to each workflow

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
		$self->logDebug("resource", $resource);
		my $resourcecount 	=	$$resourcecounts[$i] / $resource;
		
		#### STASH RUNNING COUNT
		$resourcetotal		+=	$$resourcecounts[$i];

		if ( $i == scalar(@$resourcecounts) - 1) {
			push @$instancecounts, int( ($resourcetotal - $integertotal) / $resource );
		}
		else {
			my $instancecount	=	ceil($$resourcecounts[$i]/$resource);
			$instancecount		=	1 if $instancecount < 1;

			#### STASH RUNNING INTEGER COUNT
			$integertotal	+=	$instancecount * $resource;

			push @$instancecounts, $instancecount;
		}
	}
	
	return $instancecounts;
}

#### LISTEN FOR TOPICS
method listen {
	$self->logDebug("");
	
	$self->receiveTask("update.job.status");
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
			
			my $excerpt	=	substr($body, 0, 200);
			
			#print " [x] Received message: $excerpt\n";
			&$handler($this, $body);
		},
		no_ack => 1,
	);
	
	# Wait forever
	AnyEvent->condvar->recv;	
}

method receiveTask ($taskqueue) {
	$self->logDebug("$$ taskqueue", $taskqueue);
	
	#### OPEN CONNECTION
	my $connection	=	$self->newConnection();	
	my $channel 	= 	$connection->open_channel();
	#$self->channel($channel);
	$channel->declare_queue(
		queue => $taskqueue,
		durable => 1,
	);
	
	print "$$ [*] Waiting for tasks in queue: $taskqueue\n";
	
	$channel->qos(prefetch_count => 1,);
	
	no warnings;
	my $handler	= *handleTask;
	use warnings;
	my $this	=	$self;
	
	$channel->consume(
		on_consume	=>	sub {
			my $var 	= 	shift;
			print "$$ Listener::receiveTask    DOING CALLBACK";
		
			my $body 	= 	$var->{body}->{payload};
			print " [x] Received $body\n";
		
			my @c = $body =~ /\./g;
		
			#### RUN TASK
			&$handler($this, $body);
			
			print "Sleeping 10 seconds\n";
			sleep(10);
			
			#### SEND ACK AFTER TASK COMPLETED
			print "$$ Listener::receiveTask    sending ack\n";
			$channel->ack();
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

	#my $duplicate	=	$self->duplicate();
	#if ( defined $duplicate and not $self->deeplyIdentical($data, $duplicate) ) {
	#	$self->logDebug("Skipping duplicate message");
	#	return;
	#}
	#else {
	#	$self->duplicate($data);
	#}

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

method handleTopic ($json) {
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

method updateJobStatus ($data) {
	#$self->logDebug("data", $data);
	
	$self->logDebug("$data->{sample} $data->{status} $data->{time}");
	
	#### UPDATE queuesamples TABLE
	$self->updateQueueSample($data);	

	#### UPDATE provenance TABLE
	$self->updateProvenance($data);	

	##### UPDATE SYNAPSE
	#my $synapsestatus	=	$self->getSynapseStatus($data);
	#my $sample	=	$data->{sample};
	#$self->synapse()->change($sample, $synapsestatus);
}

method updateProvenance ($data) {
	$self->logDebug("");
	my $keys	=	[ "username", "project", "workflow", "workflownumber", "sample" ];
	my $notdefined	=	$self->notDefined($data, $keys);	
	$self->logDebug("notdefined", $notdefined) and return if @$notdefined;

	#### ADD TO provenance TABLE
	my $table		=	"provenance";
	my $fields		=	$self->db()->fields($table);
	my $success		=	$self->_addToTable($table, $data, $keys, $fields);
	$self->logDebug("addToTable 'provenance'    success", $success);
}
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

method updateQueueSample ($data) {
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


#### SEND TASK
method sendTask ($task) {	
	$self->logDebug("task", $task);
	my $processid	=	$$;
	$self->logDebug("processid", $processid);
	$task->{processid}	=	$processid;

	#### SET QUEUE
	my $queuename		=	$self->setQueueName($task);
	$task->{queue}		=	$queuename;
	$self->logDebug("queuename", $queuename);
	
	#### ADD UNIQUE IDENTIFIERS
	$task	=	$self->addTaskIdentifiers($task);

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
	
	$self->logDebug("Returning task", $task);
	
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


