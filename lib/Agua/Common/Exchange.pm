use Moose::Util::TypeConstraints;
use MooseX::Declare;
use Method::Signatures::Modifiers;


class Agua::Common::Exchange with (Agua::Common::Logger) {

####////}}}}

use Net::RabbitFoot;
use JSON;

# Ints
has 'SHOWLOG'           => ( isa => 'Int', is => 'rw', default  =>      2       );
has 'PRINTLOG'          => ( isa => 'Int', is => 'rw', default  =>      2       );

## Objects
has 'channel'	=> ( isa => 'Net::RabbitFoot::Channel', is => 'rw', lazy	=> 1, builder => "openConnection" );
has 'conf' 	=> (
	#isa 	=> 'Conf::Yaml',
	isa 	=> 'Conf::Yaml',
	is 		=>	'rw',
	default	=>	sub { Conf::Yaml->new( {} );	}
);

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
	
	$self->logDebug("DOING connection->open_channe()");
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

};
