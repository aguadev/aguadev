#!/usr/bin/perl -w

=head2

APPLICATION 	socket

PURPOSE

	1. Send messages to or receive messages from a RabbitMQ fanout queue
	
HISTORY

	v0.01	Basic options to authenticate user and specify queue name

USAGE

$0 [--mode String] [--user String] [--host String] [--pass String] [--vhost String] [--queue String]

mode: 		Supported modes: 'send' or 'receive'
user:		RabbitMQ username
host:		RabbitMQ host
pass:		RabbitMQ password
vhost:		RabbitMQ virtual host
message:	Message to send (if mode 'send')
log:	Log level to STDOUT (1 for less, up to 5 for more information)
printlog:	Log level to logfile (1 for less, up to 5 for more information)

EXAMPLE

# Send message to default queue (user=guest, password=guest, host=localhost, vhost=/)
./socket.pl --message '{"message":"my message"}'

# Send message to localhost with log level 4 to STDOUT
./socket.pl --mode send --message '{"username":"testuser","log":4}' --log 4

=cut

#### EXTERNAL MODULES
use Term::ANSIColor qw(:constants);
use Getopt::Long;
use FindBin qw($Bin);
use Net::RabbitFoot;
	
#### USE LIBRARY
use lib "$Bin/../../lib";	
BEGIN {
    my $installdir = $ENV{'installdir'} || "/agua";
    unshift(@INC, "$installdir/lib");
}

#### INTERNAL MODULES
use Conf::Yaml;

my $installdir 	=	 $ENV{'installdir'} || "/agua";
my $configfile	=	"$installdir/conf/config.yaml";
my $mode		=	"message";
my $host		=	'localhost';
my $port		=	5672;
my $user		=	'guest';	
my $pass		=	'guest';
my $vhost		=	'/';
my $message		=	"";
my $log		=	2;
my $printlog	=	2;
my $help;

#### SET LOGFILE
my $logfile		=	"/tmp/pancancer-volume.$$.log";

GetOptions (
    'mode=s'		=> \$mode,
    'host=s'		=> \$host,
    'port=s'		=> \$port,
    'user=s'		=> \$user,
    'pass=s'		=> \$pass,
    'message=s'		=> \$message,
    'vhost=s'		=> \$vhost,
    'log=i'     => \$log,
    'printlog=i'    => \$printlog,
    'help'          => \$help
) or die "No options specified. Try '--help'\n";
usage() if defined $help;

print "Mode not defined (must be 'send' or 'receive'\n" if not defined $mode;
print "Mode not supported: $mode (must be 'send' or 'receive'\n" if $mode !~ /^(send|receive)$/;
$mode = "receiveSocket" if $mode eq "receive";
$mode = "sendSocket" if $mode eq "send";
print "mode: $mode\n";

my $conf = Conf::Yaml->new(
    memory      =>  0,
    inputfile   =>  $configfile,
    backup      =>  1,

    log			=>	$log,
    printlog	=>	$printlog,
    logfile     =>  $logfile
);

package Object;
use Moose;
with 'Exchange';
with 'Logger';
has 'conf'	=> ( isa => 'Conf::Yaml|Undef', is => 'rw' );

my $object = Object->new({
	conf		=>	$conf,
    log			=>	$log,
    printlog	=>	$printlog,
    logfile     =>  $logfile
});

$object->$mode({
    host		=>	$host,
    port		=>	$port,
    user		=>	$user,
    pass		=>	$pass,
    message		=>	$message,
    vhost		=>	$vhost,
});

exit 0;

##############################################################

sub usage {
	print `perldoc $0`;
	exit;
}

