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

class Queue::Foreman with (Logger, Exchange, Agua::Common::Database, Agua::Common::Timer) {

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
has 'jsonparser'=> ( isa => 'JSON', is => 'rw', lazy	=>	1, builder	=>	"setJsonParser" );
has 'db'		=> ( isa => 'Agua::DBase::MySQL|Undef', is => 'rw', required	=>	0 );
has 'channel'	=> ( isa => 'Any', is => 'rw', required	=>	0 );
has 'virtual'	=> ( isa => 'Any', is => 'rw', lazy	=>	1, builder	=>	"setVirtual" );

use FindBin qw($Bin);
use Test::More;
use Agua::Workflow;
use Virtual;

#####////}}}}}

method BUILD ($args) {
	$self->initialise($args);	
}

method initialise ($args) {
	#$self->logDebug("args", $args);	
}

method listen {
	$self->logDebug("");

	$self->receiveTopic();
}

#### TASKS
method sendTask ($task) {	
	$self->logDebug("task", $task);

	#### GET QUEUE
	my $queuename	=	$task->{queue};
	$self->logDebug("queuename", $queuename);

	my $processid	=	$$;
	#$self->logDebug("processid", $processid);
	$task->{processid}	=	$processid;

	#### ADD UNIQUE IDENTIFIERS
	$task	=	$self->addTaskIdentifiers($task);

	my $jsonparser = JSON->new();
	my $json = $jsonparser->encode($task);
	$self->logDebug("json", $json);

	#### GET HOST
	my $host		=	$self->conf()->getKey("queue:host", undef);
	$self->logDebug("host", $host);
	Coro::async_pool {

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
	
		print " [x] Sent TASK in host $host taskqueue '$queuename': $task->{mode}\n";
	}
	
}

method addTaskIdentifiers ($task) {
	#### SET TIME
	$task->{time}		=	$self->getMysqlTime();
	
	##### SET IP ADDRESS
	my $ipaddress			=	`facter ipaddress`;
	$ipaddress				=~	s/\s+$//;
	$task->{ipaddress}		=	$ipaddress;

	#### SET TOKEN
	$task->{token}		=	$self->token();
	
	#### SET SENDTYPE
	$task->{sendtype}	=	"task";
	
	#### SET DATABASE
	$self->setDbh() if not defined $self->db();
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

### TOPICS 
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

	#### GET HOST
	my $host		=	$self->conf()->getKey("queue:host", undef);

	for my $key ( @$keys ) {
		print " [*] Listening for host $host topic: $key\n";

		$channel->bind_queue(
			exchange => $exchange,
			queue => $queuename,
			routing_key => $key,
		);
	}
	
	no warnings;
	my $handler	= *handleTopic;
	use warnings;
	my $this	=	$self;

	$channel->consume(
        on_consume => sub {
			my $var = shift;
			my $body = $var->{body}->{payload};
		
			print " [x] Received host $host message: $body\n";
			&$handler($this, $body);
		},
		no_ack => 1,
	);
	
	# Wait forever
	AnyEvent->condvar->recv;	
}

method handleTopic ($json) {
	#$self->logDebug("json", $json);

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
	my $targethost		=	lc($data->{host});
	$self->logDebug("targethost", $targethost);
	my $hostname		=	$self->getHostname();
	$self->logDebug("hostname", $hostname);
	
	$self->logDebug("No hostname match ($targethost vs $hostname). Skipping shutdown") and return if $targethost ne $hostname;
	
	#### SET HOSTNAME IN CONFIG
	$self->conf()->setKey("agua:HOSTNAME", undef, $data->{host});

	my $status			=	$self->conf()->getKey("agua:STATUS", undef);
	$self->logDebug("status", $status);

	my $teardown		=	$data->{teardown};
	my $teardownfile	=	$data->{teardownfile};
	$self->logDebug("teardown", $teardown);
	$self->logDebug("teardownfile", $teardownfile);
	if ( defined $teardown ) {
		$self->printToFile($teardownfile, $teardown);
		`chmod 755 $teardownfile`;
		$self->conf()->setKey("agua:TEARDOWNFILE", undef, $teardownfile);
	}
	
	$self->logDebug("status", $status);
	
	#### IF NO WORKFLOW IS RUNNING THEN NOTIFY MASTER TO DELETE HOST
	if ( $status ne "running" ) {
		$self->logDebug("Executing teardownfile: $teardownfile");
	
		#### DO TEARDOWN
		my $teardownfile	=	$self->conf()->getKey("agua:TEARDOWNFILE", undef);
		$self->logDebug("teardownfile", $teardownfile);

		if ( defined $teardownfile ) {
			$self->logDebug("Running teardownfile", $teardownfile);
			$self->logDebug("Can't find teardownfile") if not -f $teardownfile;
			print `cat $teardownfile`;
			`$teardownfile`;
		}
		
		#### SEND DELETE INSTANCE
		$self->logDebug("DOING self->sendDeleteInstance()");
		$self->sendDeleteInstance($data->{host});
	}
	else {
		#### SET SHUTDOWN TO true
		$self->conf()->setKey("agua:SHUTDOWN", undef, "true");
	}
	$self->logDebug("completed");
}

method getHostname {

	#### GET LOCAL HOSTNAME
	my $hostname	=	`facter hostname`;
	$hostname		=~	s/\s+$//g;

	return $hostname;	
}

method verifyShutdown {
	my $shutdown	=	$self->conf()->getKey("agua:SHUTDOWN", undef);
	$self->logDebug("shutdown", $shutdown);
	
	#### GET HOSTNAME FROM CONFIG
	my $host		=	$self->conf()->getKey("agua:HOSTNAME", undef);
	$self->logDebug("host", $host);

	if ( $shutdown eq "true" ) {
		$self->logDebug("DOING self->sendDeleteInstance($host)");
		$self->sendDeleteInstance($host);
	}
}

method sendDeleteInstance ($host) {
	$self->logDebug("host", $host);
	
	my $data		=	{
		host		=>	$host,
		mode		=>	"deleteInstance",
		queue		=>	"update.host.status"
	};

	#### REPORT HOST STATUS TO 
	$self->sendTask($data);
}

method getHostName {
	my $hostname	=	`facter hostname`;
	$hostname		=~ 	s/\s+$//;
	
	$hostname		=	uc(substr($hostname, 0, 1)) . substr($hostname, 1);
	$self->logDebug("hostname", $hostname);
	
	return $hostname;
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


method printToFile ($file, $text) {
	$self->logNote("file", $file);
	$self->logNote("substr text", substr($text, 0, 100));

    open(FILE, ">$file") or die "Can't open file: $file\n";
    print FILE $text;    
    close(FILE) or die "Can't close file: $file\n";
}

method runCommand ($data) {
	my $commands	=	$data->{commands};
	foreach my $command ( @$commands ) {
		print `$command`;
	}
}

#### SET VIRTUALISATION PLATFORM
method setVirtual {
	my $virtualtype		=	$self->conf()->getKey("agua", "VIRTUALTYPE");
	$self->logDebug("virtualtype", $virtualtype);

	#### RETURN IF TYPE NOT SUPPORTED	
	$self->logDebug("virtualtype not supported: $virtualtype") and return if $virtualtype !~	/^(openstack|vagrant)$/;

   #### CREATE DB OBJECT USING DBASE FACTORY
    my $virtual = Virtual->new( $virtualtype,
        {
			conf		=>	$self->conf(),
            username	=>  $self->username(),
			
			logfile		=>	$self->logfile(),
			log			=>	$self->log(),
			printlog	=>	$self->printlog()
        }
    ) or die "Can't create virtualtype: $virtualtype. $!\n";
	$self->logDebug("virtual: $virtual");

	$self->virtual($virtual);
}


} #### END

