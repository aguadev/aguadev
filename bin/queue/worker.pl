#!/usr/bin/perl -w

=head2

APPLICATION 	worker

PURPOSE

	1. Receive tasks and run them
	
HISTORY

	v0.01	Basic options to authenticate user and specify queue name

USAGE

$0 [--user String] [--host String] [--password String] [--vhost String] [--queue String]

EXAMPLE

# Receive task to run 'Align' workflow on sample XXXXXXXXXXXXXXXX 
./worker.pl --username syoung --workflow Align --project XXXXXXXXXXXXXXXX 

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
use Queue::Manager;

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

my $notes		=	"";
my $showlog		=	2;
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
    'notes=s'		=> \$notes,
    'vhost=s'		=> \$vhost,
    'showlog=i'     => \$showlog,
    'printlog=i'    => \$printlog,
    'help'          => \$help
) or die "No options specified. Try '--help'\n";
usage() if defined $help;

my $conf = Conf::Yaml->new(
    memory      =>  0,
    inputfile   =>  $configfile,
    backup      =>  1,

    showlog     =>  $showlog,
    printlog    =>  $printlog,
    logfile     =>  $logfile
);

my $object = Queue::Manager->new({
    host		=>	$host,
    port		=>	$port,
    user		=>	$user,
    pass		=>	$pass,
    vhost		=>	$vhost,

	conf		=>	$conf,
    showlog     =>  $showlog,
    printlog    =>  $printlog,
    logfile     =>  $logfile
});

$object->receiveTask({
    username	=>	$username,
    project		=>	$project,
    workflow	=>	$workflow,
    notes		=>	$notes,
});

exit 0;

##############################################################

sub usage {
	print `perldoc $0`;
	exit;
}

