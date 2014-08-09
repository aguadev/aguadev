package Exchange;
use Moose::Role;
use Method::Signatures::Simple;
#use Method::Manual::MethodModifiers;

####////}}}}

use AnyEvent;
use Net::RabbitFoot;
use JSON;
use Coro;
use Data::Dumper;

#### Strings
has 'sendtype'	=> 	( isa => 'Str|Undef', is => 'rw', default => "response" );
has 'sourceid'	=>	( isa => 'Undef|Str', is => 'rw', default => "" );
has 'callback'	=>	( isa => 'Undef|Str', is => 'rw', default => "" );
has 'token'		=> ( isa => 'Str|Undef', is => 'rw' );
has 'user'		=> ( isa => 'Str|Undef', is => 'rw', required	=>	0 );
has 'pass'		=> ( isa => 'Str|Undef', is => 'rw', required	=>	0 );
has 'host'		=> ( isa => 'Str|Undef', is => 'rw', required	=>	0 );
has 'vhost'		=> ( isa => 'Str|Undef', is => 'rw', required	=>	0 );
has 'port'		=> ( isa => 'Str|Undef', is => 'rw', required	=>	0 );

#### Objects
has 'connection'=> ( isa => 'Net::RabbitFoot', is => 'rw', lazy	=> 1, builder => "openConnection" );
has 'channel'	=> ( isa => 'Net::RabbitFoot::Channel', is => 'rw', lazy	=> 1, builder => "openConnection" );

method notifyStatus ($data) {
	$self->logDebug("");
	#$self->logDebug("data", $data);

	async {	
		#$self->logDebug("DOING self->openConnection()");
		#my $connection = $self->openConnection();
		##$self->logDebug("connection", $connection);
		#sleep(1);
		
		$self->logDebug("DOING self->sendSocket(data)");
		print "Exchange::notifyStatus    DOING self->sendSocket(data)\n";
		$self->sendSocket($data);
	}
}

around logError => sub {
	my $orig	=	shift;
    my $self 	= 	shift;
	my $error	=	shift;
	
	$self->logCaller("");
	$self->logDebug("self->logtype", $self->logtype());

	#### DO logError
	$self->$orig($error);
	
	warn "Error: $error" and return if $self->logtype() eq "cli";

	#### SEND EXCHANGE MESSAGE
	my $data	=	{
		error	=>	$error,
		status	=>	"error"
	};
	$self->sendSocket($data);
};

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

#### SEND SOCKET
method sendSocket ($data) {	
	$self->logDebug("");
	#$self->logDebug("$$    data", $data);

	#### BUILD RESPONSE
	my $response	=	{};
	$response->{username}	=	$self->username();
	$response->{sourceid}	=	$self->sourceid();
	$response->{callback}	=	$self->callback();
	$response->{token}		=	$self->token();
	$response->{sendtype}	=	"response";
	$self->logDebug("$$    response (PRE-ADD DATA)", $response);

	#### ADD DATA
	$response->{data}		=	$data;

	$self->sendData($response);
}

method sendData ($data) {
	#### CONNECTION
	my $connection		=	$self->newSocketConnection($data);
	my $channel 		=	$connection->open_channel();
	my $exchange		=	$self->conf()->getKey("socket:exchange", undef);
	my $exchangetype	=	$self->conf()->getKey("socket:exchangetype", undef);
	#$self->logDebug("$$    exchange", $exchange);
	#$self->logDebug("$$    exchangetype", $exchangetype);

	$channel->declare_exchange(
		exchange 	=> 	$exchange,
		type 		=> 	$exchangetype,
	);

	my $jsonparser 	= 	JSON->new();
	my $json 		=	$jsonparser->encode($data);
	$self->logDebug("$$    json", substr($json, 0, 1500));
	
	$channel->publish(
		exchange => $exchange,
		routing_key => '',
		body => $json,
	);

	my $host = $data->{host} || $self->conf()->getKey("socket:host", undef);
	print "[*]   $$   [$host|$exchange|$exchangetype] Sent message: ", substr($json, 0, 1500), "\n";
	
	$connection->close();
}

method addIdentifiers ($data) {
	$self->logDebug("data", $data);
	
	#### SET TOKEN
	$data->{token}		=	$self->token();
	
	#### SET SENDTYPE
	$data->{sendtype}	=	"data";
	
	#### SET DATABASE
	$data->{database} 	= 	$self->db()->database() || "";

	#### SET USERNAME		
	$data->{username} 	= 	$data->{username};

	#### SET SOURCE ID
	$data->{sourceid} 	= 	$self->sourceid();
	
	#### SET CALLBACK
	$data->{callback} 	= 	$self->callback();
	
	$self->logDebug("Returning data", $data);

	return $data;
}

method newSocketConnection ($args) {
	$self->logCaller("");
	$self->logDebug("args", $args);

	my $host = $args->{host} || $self->conf()->getKey("socket:host", undef);
	my $port = $args->{port} || $self->conf()->getKey("socket:port", undef);
	my $user = $args->{user} || $self->conf()->getKey("socket:user", undef);
	my $pass = $args->{pass} || $self->conf()->getKey("socket:pass", undef);
	my $vhost = $args->{vhost} || $self->conf()->getKey("socket:vhost", undef);
	$self->logDebug("host", $host);
	$self->logDebug("port", $port);
	$self->logDebug("user", $user);
	$self->logDebug("pass", $pass);
	$self->logDebug("host", $host);

	my $connection = Net::RabbitFoot->new()->load_xml_spec()->connect(
		host => $host,
		port => $port,
		user => $user,	
		pass => $pass,
		vhost => $vhost,
	);
	
	return $connection;	
}

method receiveSocket ($data, $handler) {

	$data 	=	{}	if not defined $data;
	$self->logDebug("data", $data);

	my $connection	=	$self->newSocketConnection($data);
	my $channel = $connection->open_channel();
	
	#### GET EXCHANGE INFO
	my $exchange		=	$self->conf()->getKey("socket:exchange", undef);
	my $exchangetype	=	$self->conf()->getKey("socket:exchangetype", undef);

	$channel->declare_exchange(
		exchange 	=> 	$exchange,
		type 		=> 	$exchangetype,
	);
	
	my $result = $channel->declare_queue( exclusive => 1, );	
	my $queuename = $result->{method_frame}->{queue};
	
	$channel->bind_queue(
		exchange 	=> 	$exchange,
		queue 		=> 	$queuename,
	);

	#### REPORT	
	my $host = $data->{host} || $self->conf()->getKey("socket:host", undef);
	$self->logDebug(" [*] [$host|$exchange|$exchangetype|$queuename] Waiting for RabbitJs socket traffic");
	print " [*] [$host|$exchange|$exchangetype|$queuename] Waiting for RabbitJs socket traffic\n";
	
	sub callback {
		my $var = shift;
		my $body = $var->{body}->{payload};
	
		print " [x] Received message: ", substr($body, 0, 500), "\n";
	}
	
	$channel->consume(
		on_consume 	=> 	\&callback,
		queue 		=> 	$queuename,
		no_ack 		=> 	1
	);
	
	AnyEvent->condvar->recv;
}

#### CONNECTION
method getConnection {
	return $self->connection() if defined $self->connection();
	
	my $host		=	$self->host() || $self->conf()->getKey("queue:host", undef);
	my $user		= 	$self->user() || $self->conf()->getKey("queue:user", undef);
	my $pass		=	$self->pass() || $self->conf()->getKey("queue:pass", undef);
	my $vhost		=	$self->vhost() || $self->conf()->getKey("queue:vhost", undef);
	$self->logDebug("$$ host", $host);
	$self->logDebug("$$ user", $user);
	$self->logDebug("$$ pass", $pass);
	$self->logDebug("$$ vhost", $vhost);
	
	$self->logDebug("BEFORE my connection = Net::RabbitFoot()");
    
	my $connection = Net::RabbitFoot->new()->load_xml_spec()->connect(
        host 	=>	$host,
        port 	=>	5672,
        user 	=>	$user,
        pass 	=>	$pass,
        vhost	=>	$vhost,
    );
	#my $sleep	=	1;
	#$self->logDebug("AFTER my connnection = Net::RabbitFoot(). SLEEPING FOR $sleep SECONDS");
	#sleep($sleep);

	$self->connection($connection);

	return $connection;	
}

method newConnection {
	my $host		=	$self->conf()->getKey("queue:host", undef);
	my $user		= 	$self->conf()->getKey("queue:user", undef);
	my $pass		=	$self->conf()->getKey("queue:pass", undef);
	my $vhost		=	$self->conf()->getKey("queue:vhost", undef);
	$self->logNote("$$ host", $host);
	$self->logNote("$$ user", $user);
	$self->logNote("$$ pass", $pass);
	$self->logNote("$$ vhost", $vhost);
	
	$self->logNote("BEFORE my connnection = Net::RabbitFoot()");
    
	my $connection = Net::RabbitFoot->new()->load_xml_spec()->connect(
        host 	=>	$host,
        port 	=>	5672,
        user 	=>	$user,
        pass 	=>	$pass,
        vhost	=>	$vhost,
    );
	#my $sleep	=	1;
	#$self->logDebug("AFTER my connnection = Net::RabbitFoot(). SLEEPING FOR $sleep SECONDS");
	#sleep($sleep);

	#$self->logDebug("AFTER my connnection = Net::RabbitFoot()");


	#$self->logDebug("$$ conn", $conn);
	$self->connection($connection);
	#$self->logDebug("AFTER connection->connnection()");
	
	#my $channel 	= 	$connection->open_channel();
	#$self->channel($channel);

	return $connection;	
}

method openConnection {
	$self->logDebug("");
	my $connection	=	$self->newConnection();
	
	#$self->logDebug("DOING connection->open_channel()");
	my $channel = $connection->open_channel();
	$self->channel($channel);
	#$self->logDebug("BEFORE channel", $channel);

	#### GET EXCHANGE INFO
	my $exchange		=	$self->conf()->getKey("socket:exchange", undef);
	my $exchangetype	=	$self->conf()->getKey("socket:exchangetype", undef);

	#### SET DEFAULT CHANNEL
	$self->setChannel($exchange, $exchangetype);	
	$channel->declare_exchange(
		exchange => 'chat',
		type => 'fanout',
	);
	#$self->logDebug("channel", $channel);
	
	return $connection;
}

#### UTILS
method startRabbitJs {
	my $command		=	"service rabbitjs restart";
	$self->logDebug("command", $command);
	
	return `$command`;
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



1;
