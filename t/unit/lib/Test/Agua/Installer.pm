package Test::Agua::Installer;

use FindBin qw($Bin);
use lib "../../../t/lib";
use lib "../../../lib";

#### EXTERNAL MODULES
use Data::Dumper;
use Test::More;

#### INTERNAL MODULES
use base 'Agua::Installer';
#use Conf::Yaml;

####////}}}}

sub testInstallRabbitMq {
	my $self		=	shift;

	$self->installRabbitMq();
	
	#### CONFIRM
	my $installed 	=	$self->isInstalled("rabbitmq-server");
	print "Test::Agua::Installer::testInstallRabbitMq    installed: $installed\n";

	ok($installed, "rabbitmq-server is installed");
}
sub testSetRabbitMqKey {
	my $self		=	shift;

	$self->setRabbitMqKey();
	
	#### CONFIRM
	my $pattern = "RabbitMQ Release Signing Key"; 	
	my $output =`sudo apt-key list`;
	print "Agua::Test::Installer::testSetRabbitMqKey    output: $output\n";

	ok($output =~ /$pattern/, "signing key found");
}
sub testStartRabbitMq {
	my $self		=	shift;

	$self->startRabbitMq();
	
	#### CONFIRM
	ok($self->rabbitMqIsRunning(), "rabbitmq started");
}
sub testStopRabbitMq {
	my $self		=	shift;

	$self->stopRabbitMq();
	
	#### CONFIRM
	ok(! $self->rabbitMqIsRunning(), "rabbitmq stopped");
}

sub testInstallExchange {
	my $self		=	shift;

	my $inputfile	=	$self->get_inputfile();
	my $conf		=	$self->get_conf();
	#print "Test::Agua::Installer::testInstallExchange    conf:\n";
	#print Dumper $conf;

	$self->installExchange();
}


1;