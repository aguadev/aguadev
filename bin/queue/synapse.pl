#!/usr/bin/perl -w

=head2

APPLICATION 	synapse

PURPOSE

	1. Attach or detach volumes on an instance
	
HISTORY

	v0.01	Basic wrapper around synapseICGCMonitor

USAGE

$0 <--mode String> <--uuid Int> <--state (SSD|HD)>

=cut

#### EXTERNAL MODULES
use Term::ANSIColor qw(:constants);
use Getopt::Long;
use FindBin qw($Bin);

#### USE LIBRARY
use lib "$Bin/../../lib";	
BEGIN {
    my $installdir = $ENV{'installdir'} || "/agua";
    unshift(@INC, "$installdir/lib");
}

use lib "/agua/lib";

#### INTERNAL MODULES
use Conf::Yaml;
use Synapse;

my $installdir = $ENV{'installdir'} || "/agua";
my $configfile	=	"$installdir/conf/config.yaml";

my $mode;
my $uuid;
my $state;
my $target;
my $showlog		=	2;
my $printlog	=	2;
my $logfile		=	"/tmp/pancancer-volume.$$.log";
my $help;
GetOptions (
    'mode=s'		=> \$mode,
    'instanceid=s'	=> \$instanceid,
    'state=s'		=> \$state,
    'target=s'		=> \$target,
    'uuid=s'		=> \$uuid,
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


my $object = Synapse->new({
	conf		=>	$conf,
    showlog     =>  $showlog,
    printlog    =>  $printlog,
    logfile     =>  $logfile
});

$object->$mode({
	instanceid	=>	$instanceid,
	uuid		=>	$uuid,
	state		=>	$state,
	target		=> 	$target
});

exit 0;

##############################################################

sub usage {
	print `perldoc $0`;
	exit;
}

