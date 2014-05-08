package Exchange;
use Moose::Role;
use Method::Signatures::Simple;

####////}}}}

use AnyEvent;
use Net::RabbitFoot;
use JSON;
use Coro;
use Data::Dumper;

#### Strings
has 'sourceid'	=>	( isa => 'Undef|Str', is => 'rw', default => "" );
has 'callback'	=>	( isa => 'Undef|Str', is => 'rw', default => "" );
has 'token'		=> ( isa => 'Str|Undef', is => 'rw' );
has 'user'		=> ( isa => 'Str|Undef', is => 'rw', required	=>	0 );
has 'pass'		=> ( isa => 'Str|Undef', is => 'rw', required	=>	0 );
has 'host'		=> ( isa => 'Str|Undef', is => 'rw', required	=>	0 );
has 'vhost'		=> ( isa => 'Str|Undef', is => 'rw', required	=>	0 );

#### Objects
has 'connection'=> ( isa => 'Net::RabbitFoot', is => 'rw', lazy	=> 1, builder => "openConnection" );
has 'channel'	=> ( isa => 'Net::RabbitFoot::Channel', is => 'rw', lazy	=> 1, builder => "openConnection" );

method notifyStatus ($data) {
	$self->logDebug("data", $data);
	#$self->logDebug("DOING self->openConnection() with data", $data);
	async {	
		$self->logDebug("DOING self->openConnection()");
		my $connection = $self->openConnection();
		#$self->logDebug("connection", $connection);
		sleep(1);
		
		$self->logDebug("DOING self->sendData(data)");
		print "Exchange::notifyStatus    DOING self->sendData(data)\n";
		$self->sendData($data);
	}
}

method notifyError ($data, $error) {
	$self->logDebug("error", $error);
	$data->{error}	=	$error;
	
	$self->notifyStatus($data);
}

method notify ($status, $error, $data) {
	#### NOTIFY CLIENT OF STATUS
	my $object = {
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
	my $connection	=	$self->newConnection();
	
	#$self->logDebug("DOING connection->open_channel()");
	my $channel = $connection->open_channel();
	$self->channel($channel);
	#$self->logDebug("BEFORE channel", $channel);

	#### SET DEFAULT CHANNEL
	$self->setChannel("chat", "fanout");	
	$channel->declare_exchange(
		exchange => 'chat',
		type => 'fanout',
	);
	#$self->logDebug("channel", $channel);
	
	return $connection;
}
method send ($args) {
	
	$self->logDebug("args", $args);

	my $host = $args->{host};
	my $port = $args->{port};
	my $user = $args->{user};
	my $pass = $args->{pass};
	my $vhost = $args->{vhost};
	my $message = $args->{message};

	my $exchange	=	$self->conf()->getKey("queue:test", undef);
	my $type		=	'fanout';

	my $conn = Net::RabbitFoot->new()->load_xml_spec()->connect(
		host => $host,
		port => 5672,
		user => $user,	
		pass => $pass,
		vhost => $vhost,
	);
	
	my $channel = $conn->open_channel();
	
	$channel->declare_exchange(
		exchange => $exchange,
		type => $type,
	);
	
	$channel->publish(
		exchange => $exchange,
		routing_key => '',
		body => $message,
	);
	
	print " [x] Sent message [exchange: $exchange, host: $host, user: $user): $message\n";
	
	$conn->close();

	#my $conn = Net::RabbitFoot->new()->load_xml_spec()->connect(
	#	host => 'localhost',
	#	port => 5672,
	#	user => 'guest',
	#	pass => 'guest',
	#	vhost => '/',
	#);
	#
	#my $channel = $conn->open_channel();
	#
	#$channel->declare_exchange(
	#	exchange => 'chat',
	#	type => 'fanout',
	#);
	#
	#my $msg = join(' ', @ARGV) || "info: Hello World!";
	#
	#$channel->publish(
	#	exchange => 'chat',
	#	routing_key => '',
	#	body => $msg,
	#);
	#
	#print " [x] Sent $msg\n";
	#
	#$conn->close();

}

method receive ($args) {
	$self->logDebug("args", $args);

	my $host = $args->{host};
	my $port = $args->{port};
	my $user = $args->{user};
	my $pass = $args->{pass};
	my $vhost = $args->{vhost};

	my $exchange	=	$self->conf()->getKey("queue:test", undef);
	my $exchangetype	=	"fanout";

	my $conn = Net::RabbitFoot->new()->load_xml_spec()->connect(
		host => $host,
		port => 5672,
		user => $user,	
		pass => $pass,
		vhost => $vhost,
	);
	
	my $channel = $conn->open_channel();
	
	$channel->declare_exchange(
		exchange => $exchange,
		type => $exchangetype,
	);
	
	my $result = $channel->declare_queue( exclusive => 1, );
	
	my $queuename = $result->{method_frame}->{queue};
	
	$channel->bind_queue(
		exchange => $exchange,
		queue => $queuename,
	);
	
	print " [*] [$host|$exchange|$exchangetype|$queuename] Waiting for logs. To exit press CTRL-C\n";
	
	sub callback {
		my $var = shift;
		my $body = $var->{body}->{payload};
	
		print " [x] Received message: $body \n";
	}
	
	$channel->consume(
		on_consume 	=> 	\&callback,
		queue 		=> 	$queuename,
		no_ack 		=> 	1
	);
	
	AnyEvent->condvar->recv;
}

method startRabbitJs {
	my $command		=	"service rabbitjs restart";
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
	my $command		=	"service rabbitjs stop";
	$self->logDebug("command", $command);
	
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
	my $processid	=	$$;
	$self->logDebug("processid", $processid);
	$data->{processid}	=	$processid;
	#$self->logDebug("data", $data);

	#### ADD UNIQUE IDENTIFIERS
	$data	=	$self->addIdentifiers($data);

	my $jsonparser = JSON->new();
	my $json = $jsonparser->encode($data);
	$self->logDebug("json", $json);

	#$self->logDebug("BEFORE channel->publish, self->channel", $self->channel());
	my $result = $self->channel()->publish(
		exchange => 'chat',
		routing_key => '',
		body => $json,
	);
	$self->logDebug(" [x] Sent message", $json);
	$self->logDebug(" [x] Sent message length", length($json));

	return $result;
}

method addIdentifiers ($data) {
	$data->{sourceid}	= 	$self->sourceid();
	$data->{callback}	= 	$self->callback();
	$data->{token}		=	$self->token();
	my $internalip		=	$self->conf()->getKey("queue:selfinternalip", undef);
	my $externalip		=	$self->conf()->getKey("queue:selfexternalip", undef);
	$data->{selfinternalip}	=	$internalip if defined $internalip and $internalip ne "";
	$data->{selfexternalip}	=	$externalip if defined $externalip and $externalip ne "";

	return $data;	
}

method newConnection {
	my $host		=	$self->host() || $self->conf()->getKey("queue:host", undef);
	my $user		= 	$self->user() || $self->conf()->getKey("queue:user", undef);
	my $pass	=	$self->pass() || $self->conf()->getKey("queue:pass", undef);
	my $vhost		=	$self->vhost() || $self->conf()->getKey("queue:vhost", undef);
	$self->logDebug("$$ host", $host);
	$self->logDebug("$$ user", $user);
	$self->logDebug("$$ pass", $pass);
	$self->logDebug("$$ vhost", $vhost);
	

	$self->logDebug("BEFORE my connnection = Net::RabbitFoot()");
    
	my $connection = Net::RabbitFoot->new()->load_xml_spec()->connect(
        host 	=>	$host,
        port 	=>	5672,
        user 	=>	$user,
        pass 	=>	$pass,
        vhost	=>	$vhost,
    );
	$self->logDebug("AFTER my connnection = Net::RabbitFoot(). SLEEPING FOR 5 SECONDS");
	
	
	sleep(5);

	$self->logDebug("AFTER my connnection = Net::RabbitFoot()");


	#$self->logDebug("$$ conn", $conn);
	$self->connection($connection);
	$self->logDebug("AFTER connection->connnection()");
	
	#my $channel 	= 	$connection->open_channel();
	#$self->channel($channel);

	return $connection;	
}


1;
