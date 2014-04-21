package Agua::Common::Exchange;
use Moose::Role;
use Method::Signatures::Simple;

####////}}}}

use Net::RabbitFoot;
use JSON;
use Coro;
use Data::Dumper;

#### Strings
has 'sourceid'	=>	( isa => 'Undef|Str', is => 'rw', default => "" );
has 'callback'	=>	( isa => 'Undef|Str', is => 'rw', default => "" );

#### Objects
has 'connection'=> ( isa => 'Net::RabbitFoot', is => 'rw', lazy	=> 1, builder => "openConnection" );
has 'channel'	=> ( isa => 'Net::RabbitFoot::Channel', is => 'rw', lazy	=> 1, builder => "openConnection" );

method notifyStatus ($data) {	
	$self->logDebug("DOING self->openConnection() with data", $data);
	async {
	
		$self->logDebug("DOING self->openConnection()");
		my $connection = $self->openConnection();
		$self->logDebug("connection", $connection);
		sleep(1);
		
		$self->logDebug("DOING self->sendData(data)");
		$self->sendData($data);
	}
}

method notify ($status, $error, $data) {
	#### NOTIFY CLIENT OF STATUS
	my $object = {
		sourceid	=> 	$self->sourceid(),
		callback	=> 	$self->callback(),
		token		=>	$self->token(),
		queue		=> 	"routing",
		status		=> 	$status,
		error		=>	$error,
		data		=>	$data
	};
	$self->logDebug("object", $object);
	
	$self->notifyStatus($object);
}

method openConnection {
	$self->logDebug("");
	
	my $hostname	=	`hostname -s`;
	$hostname		=~	s/\s+$//;
	$self->logDebug("hostname", $hostname);

	my $connection = Net::RabbitFoot->new()->load_xml_spec()->connect(
		host => 'localhost',
		#host => '10.14.152.42',
		#host => $hostname,
		port => 5672,
		user => 'guest',
		pass => 'guest',
		vhost => '/',
	);
	
	$self->logDebug("DOING connection->open_channel()");
	my $channel = $connection->open_channel();
	$self->channel($channel);
	$self->logDebug("BEFORE channel", $channel);

	#### SET DEFAULT CHANNEL
	$self->setChannel("chat", "fanout");	
	$channel->declare_exchange(
		exchange => 'chat',
		type => 'fanout',
	);
	#$self->logDebug("channel", $channel);

	#### START RABBIT.JS
	$self->startRabbitJs();
	
	return $connection;
}

method startRabbitJs {
	my $installdir	=	$self->conf()->getKey("agua", "INSTALLDIR");
	my $appsdir		=	$self->conf()->getKey("agua", "APPSDIR");
	my $rabbitjs	=	$self->conf()->getKey("install", "RABBITJS");
	my $command		=	"node $installdir/$appsdir/$rabbitjs &";
	$self->logDebug("command", $command);
	
	my $childpid = fork;
	if ( $childpid ) #### ****** Parent ****** 
	{
		$self->logDebug("PARENT childpid", $childpid);
	}
	elsif ( defined $childpid ) {
		`$command`;
	}
}

method stopRabbitJs {

	my $installdir	=	$self->installdir();
	my $appsdir		=	$self->conf()->getKey("agua", "APPSDIR");
	my $rabbitjs	=	$self->conf()->getKey("install", "RABBITJS");
	my $command		=	"node $installdir/$appsdir/$rabbitjs";
	$self->logDebug("command", $command);
	
	$self->logDebug("DEBUG EXIT") and exit;
	
	return `$command`;
}

method setChannel($name, $type) {
	$self->channel()->declare_exchange(
		exchange => $name,
		type => $type,
	);
}

method closeConnection {
	$self->logDebug("self->connection()", $self->connection());
	$self->connection()->close();
}

method sendMessage ($message) {
	$self->logDebug("message", $message);

	$self->openConnection() if not defined $self->connection();
	
	my $result = $self->channel()->publish(
		exchange => 'chat',
		routing_key => '',
		body => $message,
	);
	$self->logDebug(" [x] Sent message", $message);

	return $result;
}

method sendData ($data) {
	$self->logDebug("data", $data);

	my $jsonparser = JSON->new();
	my $json = $jsonparser->encode($data);
	$self->logDebug("json", $json);

	$self->logDebug("BEFORE channel->publish, self->channel", $self->channel());

	my $result = $self->channel()->publish(
		exchange => 'chat',
		routing_key => '',
		body => $json,
	);
	$self->logDebug(" [x] Sent message", $json);

	return $result;
}

method sendTask ($message) {
	my $host	=	`facter ipaddress_vmnet8`;
	#my $host	=	`facter ipaddress`;
	$host		=~	s/\s+$//;
	$self->logDebug("host", $host);

	#my $host    =   "127.0.0.1";
	#my $host    =   "localhost";
	my $connection = Net::RabbitFoot->new()->load_xml_spec()->connect(
		#host => 'localhost',
		#host => '10.14.152.42',
		host => $host,
		port => 5672,
		user => 'guest',
		pass => 'guest',
		vhost => '/',
	);
	
	$self->logDebug("DOING connection->open_channel()");
	my $channel = $connection->open_channel();
	$self->channel($channel);
	#$self->logDebug("channel", $channel);
	
	$channel->declare_queue(
		queue => 'task_queue',
		durable => 1,
	);
	
	$message = "Hello World!" if not defined $message;
	
	$self->channel()->publish(
		exchange => '',
		routing_key => 'task_queue',
		body => $message,
	);
	
	print " [x] Sent '$message'\n";
}

method handleTasks {
	my $conn = Net::RabbitFoot->new()->load_xml_spec()->connect(
		host => 'localhost',
		port => 5672,
		user => 'guest',
		pass => 'guest',
		vhost => '/',
	);
	
	my $channel = $conn->open_channel();
	$self->channel($channel);
	$self->channel()->declare_queue(
		queue => 'task_queue',
		durable => 1,
	);
	
	print " [*] Waiting for messages. To exit press CTRL-C\n";
	
	$self->channel()->qos(prefetch_count => 1,);
	
	my $reference 	= $self->can('taskCallback');
	$self->channel()->consume(
		on_consume	=>	sub {
			my $var 	= 	shift;
			#print "DOING CALLBACK   var:";
			#print Dumper $var;
		
			my $body 	= 	$var->{body}->{payload};
			print " [x] Received $body\n";
		
			my @c = $body =~ /\./g;
			sleep(1);
			#sleep(scalar(@c));
		
			print " [x] Done\n";
			$channel->ack();
			#print " AFTER channel->ack()\n";
		},
		no_ack => 0,
	);

	# Wait forever
	AnyEvent->condvar->recv;	
}


1;
