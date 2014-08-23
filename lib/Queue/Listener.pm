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
has 'sleep'		=>  ( isa => 'Int', is => 'rw', default => 2 );

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

#### LISTEN
method listen {
	$self->logDebug("");
	
	my $taskqueues	=	["update.job.status", "update.host.status"];
	$self->receiveTask($taskqueues);
}

#### TOPICS
method sendTopic ($data, $key) {
	$self->logDebug("data", $data);
	$self->logDebug("key", $key);

	my $exchange	=	$self->conf()->getKey("queue:topicexchange", undef);
	$self->logDebug("exchange", $exchange);

	my $host		=	$self->host() || $self->conf()->getKey("queue:host", undef);
	my $user		= 	$self->user() || $self->conf()->getKey("queue:user", undef);
	my $pass	=	$self->pass() || $self->conf()->getKey("queue:pass", undef);
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
	$self->logDebug("json", $json);
	$self->channel()->publish(
		exchange => $exchange,
		routing_key => $key,
		body => $json,
	);
	
	print "[x] Sent topic with key '$key'\n";

	$connection->close();
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

#### TASKS
method receiveTask ($taskqueues) {

	#$self->logDebug("taskqueues", $taskqueues);
	
	#### OPEN CONNECTION
	my $connection	=	$self->newConnection();	
	my $channel 	= 	$connection->open_channel();

	foreach my $taskqueue ( @$taskqueues ) {
		#$self->logDebug("taskqueue", $taskqueue);
	
		#$self->channel($channel);
		$channel->declare_queue(
			queue => $taskqueue,
			durable => 1,
		);
		
		#### GET HOST
		my $host		=	$self->conf()->getKey("queue:host", undef);
	
		print "[*] Waiting for tasks in host $host taskqueue '$taskqueue'\n";
		
		$channel->qos(prefetch_count => 1,);
		
		no warnings;
		my $handler	= *handleTask;
		use warnings;
		my $this	=	$self;
		
		$channel->consume(
			on_consume	=>	sub {
				my $var 	= 	shift;
				#print "Listener::receiveTask    DOING CALLBACK";
			
				my $body 	= 	$var->{body}->{payload};
				print " [x] Received task in host $host taskqueue '$taskqueue'\n";
				print "body: $body\n";
			
				my @c = $body =~ /\./g;
			
				#### RUN TASK
				&$handler($this, $body);
				
				my $sleep	=	$self->sleep();
				#print "Sleeping $sleep seconds\n";
				sleep($sleep);
				
				#### SEND ACK AFTER TASK COMPLETED
				#print "Listener::receiveTask    sending ack\n";
				$channel->ack();
			},
			no_ack => 0,
		);
		
	}
	
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
	
	#### GET HOST
	my $host		=	$self->conf()->getKey("queue:host", undef);

	print " [x] Sent TASK in host $host taskqueue '$queuename': '$json'\n";
}

method addTaskIdentifiers ($task) {
	
	#### SET TOKEN
	$task->{token}		=	$self->token();
	
	#### SET SENDTYPE
	$task->{sendtype}	=	"task";
	
	#### SET DATABASE
	$task->{database} 	= 	$self->db()->database() || "";

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


#### UPDATE
method updateJobStatus ($data) {
	$self->logNote("data", $data);
	$self->logDebug("data not defined") and return if not defined $data;
	$self->logDebug("sample not defined") and return if not defined $data->{sample};
	$self->logDebug("$data->{host} $data->{sample} $data->{status} $data->{time}");
	
	#### UPDATE queuesamples TABLE
	$self->updateQueueSample($data);	

	#### UPDATE provenance TABLE
	$self->updateProvenance($data);	
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

method updateProvenance ($data) {
	#$self->logDebug("$data->{sample} $data->{status} $data->{time}");
	my $keys	=	[ "username", "project", "workflow", "workflownumber", "sample" ];
	my $notdefined	=	$self->notDefined($data, $keys);	
	$self->logDebug("notdefined", $notdefined) and return if @$notdefined;

	#### ADD TO provenance TABLE
	my $table		=	"provenance";
	my $fields		=	$self->db()->fields($table);
	my $success		=	$self->_addToTable($table, $data, $keys, $fields);
	#$self->logDebug("addToTable 'provenance'    success", $success);
}
method updateQueueSample ($data) {
	#$self->logDebug("data", $data);	
	#$self->logDebug("$data->{sample} $data->{status} $data->{time}");
	
	#### UPDATE queuesample TABLE
	my $table	=	"queuesample";
	my $keys	=	[ "sample" ];
	$self->_removeFromTable($table, $data, $keys);
	
	$keys	=	["username", "project", "workflow", "workflownumber", "sample", "status" ];
	$self->_addToTable($table, $data, $keys);
}
#### DELETE
method deleteInstance ($data) {
	#$self->logDebug("data", $data);
	my $host			=	$data->{host};
	$self->logDebug("host", $host);

	my $username	=	$self->getUsernameFromInstance($host);
	$self->logDebug("username", $username);

	my $authfile	=	$self->printAuth($username);
	$self->logDebug("authfile", $authfile);

	my $success		=	$self->virtual()->deleteNode($authfile, $host);
	$self->logDebug("success", $success);

	$self->updateInstanceStatus($host, "deleted");

	return $success;
}

method getTenant ($username) {
	my $query	=	qq{SELECT *
FROM tenant
WHERE username='$username'};
	#$self->logDebug("query", $query);

	return $self->db()->queryhash($query);
}

method getAuthFile ($username, $tenant) {
	#$self->logDebug("username", $username);
	
	my $installdir		=	$self->conf()->getKey("agua", "INSTALLDIR");
	my $targetdir		=	"$installdir/conf/.openstack";
	`mkdir -p $targetdir` if not -d $targetdir;
	my $tenantname		=	$tenant->{os_tenant_name};
	#$self->logDebug("tenantname", $tenantname);
	my $authfile		=	"$targetdir/$tenantname-openrc.sh";
	#$self->logDebug("authfile", $authfile);

	return	$authfile;
}

method getUsernameFromInstance ($host) {
	$self->logDebug("host", $host);
	my $query		=	qq{SELECT queue FROM instance
WHERE LOWER(host) LIKE LOWER('$host')
};
	$self->logDebug("query", $query);
	my $queue		=	$self->db()->query($query);
	#$self->logDebug("queue", $queue);
	
	my ($username)	=	$queue	=~	/^([^\.]+)\./;
	#$self->logDebug("username", $username);
	
	return $username;
}

method printAuth ($username) {
	#$self->logDebug("username", $username);
	
	#### SET TEMPLATE FILE	
	my $installdir		=	$self->conf()->getKey("agua", "INSTALLDIR");
	my $templatefile	=	"$installdir/bin/install/resources/openstack/openrc.sh";

	#### GET OPENSTACK AUTH INFO
	my $tenant		=	$self->getTenant($username);
	#$self->logDebug("tenant", $tenant);

	#### GET AUTH FILE
	my $authfile		=	$self->getAuthFile($username, $tenant);

	#### PRINT FILE
	return	$self->virtual()->printAuthFile($tenant, $templatefile, $authfile);
}

method updateInstanceStatus ($host, $status) {
	$self->logNote("host", $host);
	$self->logNote("status", $status);
	
	my $time		=	$self->getMysqlTime();
	my $query		=	qq{UPDATE instance
SET status='$status',
TIME='$time'
WHERE host='$host'
};
	$self->logDebug("query", $query);
	
	return $self->db()->do($query);
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

method runCommand ($command) {
	$self->logDebug("command", $command);
	
	return `$command`;
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

	
	
	
}


