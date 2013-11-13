use Moose::Util::TypeConstraints;
use MooseX::Declare;
use Method::Signatures::Modifiers;

class Test::Agua::Common::Exchange extends Agua::Common::Exchange with (Agua::Common::Logger) {

use Data::Dumper;
use Test::More;
use FindBin qw($Bin);
use Net::RabbitFoot;
use Conf::Yaml;

# Objects
has 'connection'=> ( isa => 'Net::RabbitFoot', is => 'rw', lazy	=> 1, builder => "openConnection" );
has 'channel'	=> ( isa => 'Net::RabbitFoot::Channel', is => 'rw', lazy	=> 1, builder => "openConnection" );

# Ints
has 'LOG'		=> ( isa => 'Int', 		is => 'rw', default	=> 	2);

# STRINGS
has 'dumpfile'		=>  ( isa => 'Str|Undef', is => 'rw' );
has 'username'		=>  ( isa => 'Str|Undef', is => 'rw' );
has 'password'		=>  ( isa => 'Str|Undef', is => 'rw' );
has 'database'		=>  ( isa => 'Str|Undef', is => 'rw' );
has 'logfile'		=>  ( isa => 'Str|Undef', is => 'rw' );
has 'requestor'		=> 	( isa => 'Str|Undef', is => 'rw' );

# OBJECTS
has 'db'		=> ( isa => 'Agua::DBase::MySQL', is => 'rw', required => 0 );
has 'conf' 	=> (
	is 		=>	'rw',
	isa 	=> 	'Conf::Yaml|Conf::Yaml'
);

#####/////}}}}}

method BUILD ($args) {
	if ( defined $args ) {
		foreach my $arg ( $args ) {
			$self->$arg($args->{$arg}) if $self->can($arg);
		}
	}
	$self->logDebug("args", $args);
}

method testOpenConnection {
	diag("# openConnection");
	
	my $connection = $self->openConnection();
	$self->logDebug("connection", $connection);
	
	isa_ok($connection, "Net::RabbitFoot", "connection");
	#isa_ok($connection->{arc}, "AnyEvent::RabbitMQ::Channel", "channel");
	###isa_ok($connection->{_content_queue}, "AnyEvent::RabbitMQ::LocalQueue", "queue");	
	###is_deeply($connection->{_ar}->{_channels}->{1}, "AnyEvent::Handle", "handle");
	#is_deeply($connection->{_ar}->{_is_open}, 1, "_is_open is one");
	is_deeply($connection->{_ar}->{_channels}->{1}->{_is_active}, 1, "_is_active == 1");
}

method testCloseConnection {
	diag("# closeConnection");

	my $connection = $self->openConnection();
	$self->logDebug("BEFORE connection", $connection);
	
	$self->closeConnection();
	$connection	=	$self->connection();
	$self->logDebug("AFTER connection", $connection);

	my $testname = "close success";
	is_deeply($connection->{_ar}->{_channels}->{1}->{_is_active}, 0, "_is_active == 1");
	#is_deeply($connection->{_ar}->{_is_open}, 0, "_is_open is zero");
	isa_ok($connection->{_ar}, "AnyEvent::RabbitMQ", "_ar");
}

method testSendMessage {
	diag("# sendMessage");
	
	my $connection = $self->openConnection();
	$self->logDebug("BEFORE connection", $connection);

	my $message = "TEST MESSAGE";
	my $result = $self->sendMessage($message);
	$self->logDebug("result", $result);
	
	isa_ok($result, "Net::RabbitFoot::Channel", "channel");
}

method testSendData {
	diag("# sendData");
	
	my $connection = $self->openConnection();
	$self->logDebug("BEFORE connection", $connection);

	my $data = {
		token		=> "1234123421341234123421",
		callback	=>	"openProjectDialog",
		params	=>	{
			project		=>	"III_Test4"
		}
	};
	
	my $result = $self->sendData($data);
	$self->logDebug("result", $result);
	
	isa_ok($result, "Net::RabbitFoot::Channel", "channel");
}



}	####	Agua::Login::Common
