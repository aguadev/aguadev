#!/usr/bin/perl -w

=head2

APPLICATION 	emit

PURPOSE

	1. Send messages to a RabbitMQ fanout queue
	
HISTORY

	v0.01	Basic options to authenticate user and specify queue name

USAGE

$0 [--user String] [--host String] [--password String] [--vhost String] [--queue String]

EXAMPLE

# Send message to default queue (user=guest, password=guest, host=localhost, vhost=/)
./emit.pl "my message"

# Send message to custom queue on localhost
./emit.pl --user myUserName --password mySecret "

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
use Exchange::Manager;

my $installdir 	=	 $ENV{'installdir'} || "/agua";
my $configfile	=	"$installdir/conf/config.yaml";
my $username;
my $project;
my $workflow;

my $host;
my $port;
my $user;
my $pass;
my $vhost;

#my $host		=	'localhost';
#my $port		=	5672;
#my $user		=	'myuser';	
#my $pass		=	'mypassword';
#my $vhost		=	'myvhost';
my $message		=	"";
my $log		=	2;
my $printlog	=	2;
my $help;

#### SET LOGFILE
my $logfile		=	"/tmp/pancancer-volume.$$.log";

GetOptions (
    'username=s'	=> \$username,
    'project=s'		=> \$project,
    'workflow=s'	=> \$workflow,
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

my $conf = Conf::Yaml->new(
    memory      =>  0,
    inputfile   =>  $configfile,
    backup      =>  1,

    log			=>	$log,
    printlog	=>	$printlog,
    logfile     =>  $logfile
);

my $object = Exchange::Manager->new({
    host		=>	$host,
    port		=>	$port,
    user		=>	$user,
    pass		=>	$pass,
    vhost		=>	$vhost,

	conf		=>	$conf,
    log			=>	$log,
    printlog	=>	$printlog,
    logfile     =>  $logfile
});

	$object->sendTask({
	username	=>	$username,
	project		=>	$project,
	workflow	=>	$workflow,
    message		=>	$message,
});

exit 0;

##############################################################

sub usage {
	print `perldoc $0`;
	exit;
}
