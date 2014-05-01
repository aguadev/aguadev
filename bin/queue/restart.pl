#!/usr/bin/perl -w

=head2

APPLICATION 	restart

PURPOSE

	1. Detect nodes running old version of software
	
	2. Run 'max' number of commands concurrently
	
	3. Poll running completed to determine which have completed
	
	4. Execute remaining commands up to 'max' number
	
	5. Repeat 2-4 until all commands are run

HISTORY

	v0.01	Basic loop with threads

USAGE

$0 [--max Int] [--sleep Int] <--commands|--nodename String>

nodename 	:    Name of node (or first part of name)

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
use Queue::Manager;

my $installdir = $ENV{'installdir'} || "/agua";
my $configfile	=	"$installdir/conf/config.yaml";

my $nodename;
my $mode;
my $showlog		=	2;
my $printlog	=	2;
my $logfile		=	"/tmp/pancancer-restart.$$.log";
my $help;
GetOptions (
    'nodename=s'	=> \$nodename,
    'mode=s'		=> \$mode,
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
	conf		=>	$conf,
    showlog     =>  $showlog,
    printlog    =>  $printlog,
    logfile     =>  $logfile
});
$object->$mode($nodename);

exit 0;

##############################################################

sub usage {
	print `perldoc $0`;
	exit;
}

