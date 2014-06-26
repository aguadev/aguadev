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
has 'arch'		=> ( isa => 'Str|Undef', is => 'rw', required	=>	0 );
has 'modulestring'	=> ( isa => 'Str|Undef', is => 'rw', default	=> "Agua::Workflow" );

# Objects
has 'conf'		=> ( isa => 'Conf::Yaml', is => 'rw', required	=>	0 );
has 'nova'		=> ( isa => 'Virtual::Openstack', is => 'rw', lazy	=>	1, builder	=>	"setNova" );
has 'synapse'	=> ( isa => 'Synapse', is => 'rw', lazy	=>	1, builder	=>	"setSynapse" );
has 'jsonparser'=> ( isa => 'JSON', is => 'rw', lazy	=>	1, builder	=>	"setJsonParser" );
has 'db'		=> ( isa => 'Agua::DBase::MySQL|Undef', is => 'rw', required	=>	0 );
has 'channel'	=> ( isa => 'Any', is => 'rw', required	=>	0 );


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
	
	my $time		=	$self->getMysqlTime();
	my $host		=	$self->getHostName();

	my $arch	=	$self->getArch();
	if ( $arch eq "ubuntu" ) {
		`if [ ! -f /usr/bin/mpstat ]; then  apt-get install -y sysstat; fi`;
	}
	elsif ( $arch eq "centos" ) {
		`if [ ! -f /usr/bin/mpstat ]; then  yum install -y sysstat; fi`;
	}
	
	my $cpu		=	$self->getCpu();
	$self->logDebug("cpu", $cpu);
	
	my $io		=	$self->getIo();
	$self->logDebug("io", $io);
	
	my $disk		=	$self->getDisk();
	$self->logDebug("disk", $disk);

	my $memory		=	$self->getMemory();
	$self->logDebug("memory", $memory);
		
	my $key	=	"update.host.status";
	my $data	=	{
		host	=>	$host,
		cpu		=>	$cpu,
		io		=>	$io,
		disk	=>	$disk,
		memory	=>	$memory,
		time	=>	$time,
		mode	=>	"updateHeartbeat"
	};
	$self->logDebug("data", $data);
	
	$self->sendTopic($data, $key);
}

method getHost {
	return `hostname`;
}
method getIo {
	return `iostat`;
}

method getCpu {
	return `mpstat`;
}

method getDisk {
	return `df -ah`;
}

method getMemory {
	return `sar -r 1 1`;
}

#### LISTEN FOR TASKS
method listenTasks {
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
	
	#### SET self->connection
	$self->connection($connection);
	
	# Wait forever
	AnyEvent->condvar->recv;	
}

method handleTask ($json) {
	$self->logDebug("$$ json", $json);
	my $data = $self->jsonparser()->decode($json);    

	$data->{start}		=  	1;
	$data->{conf}		=   $self->conf();
	$data->{log}		=   $self->log();
	$data->{logfile}	=   $self->logfile();
	$data->{printlog}	=   $self->printlog();	
	$data->{worker}		=	$self;

	$self->setDbh() if not defined $self->db();

	my $workflow = Agua::Workflow->new($data);
	print "$$ workflow: $workflow\n";
	$self->logDebug("new Agua::Workflow object: $workflow");

	#### SET STATUS TO running
	$self->conf()->setKey("agua", "STATUS", "running");

	$workflow->executeWorkflow();	

	#### SET STATUS TO completed
	$self->conf()->setKey("agua", "STATUS", "completed");

	#### SHUT DOWN TASK LISTENER IF SPECIFIED IN config.yaml
	$self->verifyShutdown();
}

### LISTEN FOR TOPICS 
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

method doShutdown ($data) {
	$self->logDebug("data", $data);
	my $hostname	=	$self->getHostname();
	$self->logDebug("hostname", $hostname);	
	
	$self->logDebug("No hostname match. Skipping shutdown") and return if $data->{host} ne $hostname;
	
	my $status	=	$self->conf()->getKey("agua:STATUS", undef);
	$self->logDebug("status", $status);
	
	#### IF THE INSTANCE IS NOT RUNNING THEN DO SHUTDOWN
	if ( $status ne "running" ) {
		$self->shutdown();
	}
	else {
		#### SET SHUTDOWN TO true
		#### WHEN THE CURRENT WORKFLOW ENDS, IF IT SEES THE SHUTDOWN
		#### FLAG IS true, IT WILL:
		#### 1. RUN shutdown()
		#### 2. ACCEPT NO MORE TASKS
		#### 3. AWAIT TERMINATION
		$self->conf()->setKey("agua:SHUTDOWN", "true");
	}
	

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
	
	my $key	=	"update.host.status";

	my $time		=	$self->getMysqlTime();
	my $host		=	$self->getHostName();
	my $data		=	{
		time		=>	$time,
		host		=>	$host,
		status		=>	"shutdown",
		mode		=>	"updateShutdown"
	};

	#### REPORT HOST STATUS TO 
	$self->sendTopic($data, $key);
	
	##### SHUTDOWN TASK CONNECTION
	#$self->connection()->close();
}

method getHostName {
	my $hostname	=	`facter hostname`;
	$hostname		=~ 	s/\s+$//;
	
	return $hostname;
}

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

method setJsonParser {
	return JSON->new->allow_nonref;
}

method getArch {
	my $arch = $self->arch();
	return $arch if defined $arch;
	
	$arch 	= 	"linux";
	my $command = "uname -a";
    my $output = `$command`;
	#$self->logDebug("output", $output);
	
    #### Linux ip-10-126-30-178 2.6.32-305-ec2 #9-Ubuntu SMP Thu Apr 15 08:05:38 UTC 2010 x86_64 GNU/Linux
    $arch	=	 "ubuntu" if $output =~ /ubuntu/i;
    #### Linux ip-10-127-158-202 2.6.21.7-2.fc8xen #1 SMP Fri Feb 15 12:34:28 EST 2008 x86_64 x86_64 x86_64 GNU/Linux
    $arch	=	 "centos" if $output =~ /fc\d+/;
    $arch	=	 "centos" if $output =~ /\.el\d+\./;
	$arch	=	 "debian" if $output =~ /debian/i;
	$arch	=	 "freebsd" if $output =~ /freebsd/i;
	$arch	=	 "osx" if $output =~ /darwin/i;

	$self->arch($arch);
    $self->logDebug("FINAL arch", $arch);
	
	return $arch;
}


} #### END

