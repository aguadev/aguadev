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

class Queue::Worker with (Logger, Exchange, Agua::Common::Database, Agua::Common::Timer) {

#####////}}}}}

# Integers
has 'log'	=>  ( isa => 'Int', is => 'rw', default => 4 );
has 'printlog'	=>  ( isa => 'Int', is => 'rw', default => 5 );
has 'sleep'		=>  ( isa => 'Int', is => 'rw', default => 300 );

# Strings
has 'database'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0 );
has 'user'		=> ( isa => 'Str|Undef', is => 'rw', required	=>	0 );
has 'pass'		=> ( isa => 'Str|Undef', is => 'rw', required	=>	0 );
has 'host'		=> ( isa => 'Str|Undef', is => 'rw', required	=>	0 );
has 'vhost'		=> ( isa => 'Str|Undef', is => 'rw', required	=>	0 );
has 'modulestring'	=> ( isa => 'Str|Undef', is => 'rw', default	=> "Agua::Workflow" );

# Objects
has 'conf'		=> ( isa => 'Conf::Yaml', is => 'rw', required	=>	0 );
has 'nova'		=> ( isa => 'Virtual::Openstack', is => 'rw', lazy	=>	1, builder	=>	"setNova" );
has 'synapse'	=> ( isa => 'Synapse', is => 'rw', lazy	=>	1, builder	=>	"setSynapse" );
has 'jsonparser'=> ( isa => 'JSON', is => 'rw', lazy	=>	1, builder	=>	"setJsonParser" );
has 'db'	=> ( isa => 'Agua::DBase::MySQL|Undef', is => 'rw', required	=>	0 );

use FindBin qw($Bin);
use Test::More;

use Virtual::Openstack;
use Agua::Workflow;

#####////}}}}}

method BUILD ($args) {
	$self->initialise($args);	
}

method initialise ($args) {
	#$self->logDebug("args", $args);	
}

method listen {
	#### LISTEN FOR TASKS SENT FROM MASTER
	$self->listenTasks();

	#### PERIODICALLY SEND 'HEARTBEAT' NODE STATUS INFO
	my $shutdown	=	$self->conf()->getKey("agua:SHUTDOWN", undef);
	while ( not $shutdown eq "true" ) {
		my $sleep	=	$self->sleep();
		print "Queue::Master::manage    Sleeping $sleep seconds\n";
		sleep($sleep);
		$self->heartbeat();
		
		$shutdown	=	$self->conf()->getKey("agua:SHUTDOWN", undef);

	}	

}

method heartbeat {
	my $key	=	"update.host.status";
	my $data	=	{};
	$data->{cpu}	=	$self->getCpu();
	$data->{disk}	=	$self->getDisk();
	$data->{memory}	=	$self->getMemory();
	
	$self->sendTopic($data, $key);
}

method getCpu {
	
}

method getDisk {
	return `df -ah`;
}

method listenTasks ($taskqueue) {
	my $taskqueue =	$self->conf()->getKey("queue:taskqueue", undef);
	$self->logDebug("$$ taskqueue", $taskqueue);

	my $childpid = fork;
	if ( $childpid ) #### ****** Parent ****** 
	{
		$self->logDebug("$$ PARENT childpid", $childpid);
	}
	elsif ( defined $childpid ) {
		$self->receiveTask($taskqueue);	
	}		
}

method receiveTask ($taskqueue) {
	$self->logDebug("$$ queue", $taskqueue);
	
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
			print "$$ Exchange::receiveTask    DOING CALLBACK";
		
			my $body 	= 	$var->{body}->{payload};
			print " [x] Received $body\n";
		
			my @c = $body =~ /\./g;
		
			Coro::async_pool {

				#### RUN TASK
				&$handler($this, $body);
				
				#### SEND ACK AFTER TASK COMPLETED
				$channel->ack();
			}
		},
		no_ack => 0,
	);
	
	# Wait forever
	AnyEvent->condvar->recv;	
}

method handleTask ($json) {
	$self->logDebug("$$ json", $json);
	my $data = $self->jsonparser()->decode($json);    

	$data->{start}		=  	1;
	$data->{conf}		=   $self->conf();
	$data->{log}	=   $self->log();
	$data->{logfile}	=   $self->logfile();
	$data->{printlog}	=   $self->printlog();	
	$data->{worker}		=	$self;

	$self->setDbh() if not defined $self->db();

	my $workflow = Agua::Workflow->new($data);
	print "$$ workflow: $workflow\n";
	$self->logDebug("new Agua::Workflow object: $workflow");

	$workflow->executeWorkflow();	

	#### SHUTDOWN IF SPECIFIED IN config.yaml
	$self->verifyShutdown();
}

method verifyShutdown {
	my $shutdown	=	$self->conf()->getKey("agua:SHUTDOWN", undef);
	$self->logDebug("shutdown", $shutdown);
	
	if ( $shutdown eq "true" ) {
		$self->logDebug("DOING self->shutdown()");
		$self->shutdown();
	}
}

method shutdown {
	$self->logDebug("");
	
	#### REPORT
	my $datetime	=	$self->getMysqlTime();
	my $host		=	$self->getHostName();
	my $data		=	{
		datetime	=>	$datetime,
		host		=>	$host,
		status		=>	"shutdown",
		mode		=>	"updateHostStatus"
	};

	#### REPORT HOST STATUS TO 
	$self->sendTopic($data, "update.host.status");
	
	#### SHUTDOWN TASK DAEMON
	$self->logDebug("SHUTTING DOWN: service task stop");
	`service task stop`;
}

method getHostName {
	my $hostname	=	`facter ipaddress`;
	$hostname		=~ 	s/\s+$//;
	
	return $hostname;
}

method sendTopic ($data, $key) {
	$self->logDebug("$$ data", $data);
	$self->logDebug("$$ key", $key);

	#### SET mode
	$data->{mode}	=	"updateJobStatus";

	my $exchange	=	$self->conf()->getKey("queue:topicexchange", undef);
	$self->logDebug("$$ exchange", $exchange);

	my $host		=	$self->host() || $self->conf()->getKey("queue:host", undef);
	my $user		= 	$self->user() || $self->conf()->getKey("queue:user", undef);
	my $pass	=	$self->pass() || $self->conf()->getKey("queue:pass", undef);
	my $vhost		=	$self->vhost() || $self->conf()->getKey("queue:vhost", undef);
	$self->logDebug("$$ host", $host);
	$self->logDebug("$$ user", $user);
	$self->logDebug("$$ pass", $pass);
	$self->logDebug("$$ vhost", $vhost);
	
    my $connection = Net::RabbitFoot->new()->load_xml_spec()->connect(
        host 	=>	$host,
        port 	=>	5672,
        user 	=>	$user,
        pass 	=>	$pass,
        vhost	=>	$vhost,
    );

	$self->logDebug("$$ connection: $connection");
	$self->logDebug("$$ DOING connection->open_channel");
	my $channel 	= 	$connection->open_channel();
	$self->channel($channel);

	$self->logDebug("$$ DOING channel->declare_exchange");

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

method setJsonParser {
	return JSON->new->allow_nonref;
}





} #### END
