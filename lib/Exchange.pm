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
has 'queue'		=>	( isa => 'Undef|Str', is => 'rw', default => undef );
has 'token'		=> ( isa => 'Str|Undef', is => 'rw' );
has 'user'		=> ( isa => 'Str|Undef', is => 'rw', required	=>	0 );
has 'pass'		=> ( isa => 'Str|Undef', is => 'rw', required	=>	0 );
has 'host'		=> ( isa => 'Str|Undef', is => 'rw', required	=>	0 );
has 'vhost'		=> ( isa => 'Str|Undef', is => 'rw', required	=>	0 );
has 'port'		=> ( isa => 'Str|Undef', is => 'rw', default	=>	5672 );
has 'sleep'		=>  ( isa => 'Int', is => 'rw', default => 2 );

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
	
	$self->logCaller("XXXXXXXXXXXXXXXX");
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

method receiveSocket ($data) {

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

method addIdentifiers ($data) {
	$self->logDebug("data", $data);
	
	#### SET TOKEN
	$data->{token}		=	$self->token();
	
	#### SET SENDTYPE
	$data->{sendtype}	=	"data";
	
	#### SET DATABASE
	$self->setDbh() if not defined $self->db();
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


#### TASK
method receiveTask ($taskqueue) {
	$self->logDebug("taskqueue", $taskqueue);
	
	#### OPEN CONNECTION
	my $connection	=	$self->newConnection();	
	my $channel 	= 	$connection->open_channel();
	#$self->channel($channel);
	$channel->declare_queue(
		queue => $taskqueue,
		durable => 1,
	);
	
	print "[*] Waiting for tasks in queue: $taskqueue\n";
	
	$channel->qos(prefetch_count => 1,);
	
	no warnings;
	my $handler	= *handleTask;
	use warnings;
	my $this	=	$self;

	#### GET HOST
	my $host		=	$self->conf()->getKey("queue:host", undef);
	
	print " [x] Receiving tasks in host $host taskqueue '$taskqueue'\n";
	
	$channel->consume(
		on_consume	=>	sub {
			my $var 	= 	shift;
			#print "Listener::receiveTask    DOING CALLBACK";
		
			my $body 	= 	$var->{body}->{payload};
			print " [x] Received task in host $host taskqueue '$taskqueue': $body\n";
		
			my @c = $body =~ /\./g;
		
			#### RUN TASK
			&$handler($this, $body);
			
			my $sleep	=	$self->sleep();
			#print "Sleeping $sleep seconds\n";
			sleep($sleep);
			
			#### SEND ACK AFTER TASK COMPLETED
			print "Listener::receiveTask    sending ack\n";
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
	$self->logDebug("json", substr($json, 0, 1000));

	#my $data = $self->jsonparser()->decode($json);
	##$self->logDebug("data", $data);
	#
	######my $duplicate	=	$self->duplicate();
	######if ( defined $duplicate and not $self->deeplyIdentical($data, $duplicate) ) {
	######	$self->logDebug("Skipping duplicate message");
	######	return;
	######}
	######else {
	######	$self->duplicate($data);
	######}
	#
	#my $mode =	$data->{mode} || "";
	##$self->logDebug("mode", $mode);
	#
	#if ( $self->can($mode) ) {
	#	$self->$mode($data);
	#}
	#else {
	#	print "mode not supported: $mode\n";
	#	$self->logDebug("mode not supported: $mode");
	#}
}

method sendTask ($task) {
	$self->logDebug("task", $task);
	my $processid	=	$$;
	$self->logDebug("processid", $processid);
	$task->{processid}	=	$processid;

	#### SET QUEUE
	$task->{queue} = $self->setQueueName($task) if not defined $task->{queue};
	my $queuename		=	$task->{queue};
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
		exchange 		=> '',
		routing_key 	=> $queuename,
		body 			=> $json
	);

	my $host		=	$self->conf()->getKey("queue:host", undef);
	
	print " [x] Sent task in host $host taskqueue '$queuename': '$json'\n";
}

method addTaskIdentifiers ($task) {
	
	#### SET TOKEN
	$task->{token}		=	$self->token();
	
	#### SET SENDTYPE
	$task->{sendtype}	=	"task";
	
	#### SET DATABASE
	$self->setDbh() if not defined $self->db();
	$task->{database} 	= 	$self->db()->database() || "";

	#### SET SOURCE ID
	$task->{sourceid} 	= 	$self->sourceid();
	
	#### SET CALLBACK
	$task->{callback} 	= 	$self->callback();
	
	$self->logDebug("Returning task", $task);
	
	return $task;
}
method setQueueName ($task) {
	$self->logDebug("task", $task);
	
	#### VERIFY VALUES
	my $notdefined	=	$self->notDefined($task, ["username", "project", "workflow"]);
	$self->logDebug("notdefined", $notdefined);
	
	$self->logCritical("notdefined", @$notdefined) and return if @$notdefined;
	
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



#### TOPIC
#method sendTopic 

#### FANOUT
method sendFanout ($exchange, $message) {
	
	my $key	=	"chat";
	
	my $host	=	$self->host();
	my $port	=	$self->port();
	my $user	=	$self->user();
	my $pass	=	$self->pass();
	my $vhost	=	$self->vhost();

	my $connection = Net::RabbitFoot->new()->load_xml_spec()->connect(
		host 	=> $host,
		port 	=> $port,
		user 	=> $user,
		pass 	=> $pass,
		vhost 	=> $vhost
	);
	
	my $chan = $connection->open_channel();
	
	$chan->publish(
		exchange => '',
		routing_key => '$key',
		body => '$message',
	);
	
	print " [x] Sent fanout on host $host routing key '$key': $message\n";
	
	$connection->close();	
}

method receiveFanout ($message) {
	
	my $key	=	"chat";
	
	my $conn = Net::RabbitFoot->new()->load_xml_spec()->connect(
		host => 'localhost',
		port => 5672,
		user => 'myuser',
		pass => 'mypassword',
		vhost => 'myvhost',
	);
	
	my $channel = $conn->open_channel();
	
	$channel->declare_exchange(
		#exchange => 'logs',
		exchange => 'chat',
		type => 'fanout',
	);
	
	my $result = $channel->declare_queue( exclusive => 1, );
	
	my $queue_name = $result->{method_frame}->{queue};
	
	$channel->bind_queue(
		exchange => 'chat',
		queue => $queue_name,
	);
	
	#### GET HOST
	my $host		=	$self->conf()->getKey("queue:host", undef);
	
	print " [*] Waiting for fanout on host $host routing key '$key'\n";
	
	no warnings;
	sub callback {
		my $var = shift;
		my $body = $var->{body}->{payload};
	
		print " [x] Received fanout on host $host routing key '$key'$body\n";
	}
	use warnings;
		
	$channel->consume(
		on_consume => \&callback,
		queue => $queue_name,
		no_ack => 1,
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

#method sendTask ($task) {	
#	$self->logDebug("task", $task);
#	my $processid	=	$$;
#	$self->logDebug("processid", $processid);
#	$task->{processid}	=	$processid;
#
#	#### SET QUEUE
#	my $queuename		=	$task->{queue} || $self->setQueueName($task);
#	$task->{queue}	=	$queuename;	
#	$self->logDebug("queuename", $queuename);
#
#	#### ADD UNIQUE IDENTIFIERS
#	$task	=	$self->addIdentifiers($task);
#
#	my $jsonparser = JSON->new();
#	my $json = $jsonparser->encode($task);
#	$self->logDebug("json", $json);
#
#	#### GET CONNECTION
#	my $connection	=	$self->newConnection();
#	$self->logDebug("DOING connection->open_channel()");
#	my $channel = $connection->open_channel();
#	$self->channel($channel);
#	#$self->logDebug("channel", $channel);
#	
#	$channel->declare_queue(
#		queue => $queuename,
#		durable => 1,
#	);
#	
#	#### BIND QUEUE TO EXCHANGE
#	$self->channel()->publish(
#		exchange => '',
#		routing_key => $queuename,
#		body => $json,
#	);
#	
#	print " [x] Sent TASK: '$json'\n";
#}
#
#method sendFanout ($message) {
#	$self->logDebug("message", $message);
#	my $data	=	$self->jsonparser()->decode($message);
#	$self->logDebug("data", $data);
#	my $processid	=	$$;
#	$self->logDebug("processid", $processid);
#	$data->{processid}	=	$processid;
#	#$self->logDebug("data", $data);
#
#	#### SET TYPE response
#	$data->{sendtype}	=	$self->sendtype();
#	
#	my $jsonparser = JSON->new();
#	my $json = $jsonparser->encode($data);
#	$self->logDebug("json", $json);
#
#	#$self->logDebug("BEFORE channel->publish, self->channel", $self->channel());
#	my $result = $self->channel()->publish(
#		exchange => 'chat',
#		routing_key => '',
#		body => $json,
#	);
#	$self->logDebug(" [x] Sent message", $json);
#	$self->logDebug(" [x] Sent message length", length($json));
#
#	return $result;
#}
#
