#!/usr/bin/perl -w

=head2
	
APPLICATION 	test.t

PURPOSE

	Test Queue::Task module
	
NOTES

	1. RUN AS ROOT
	
	2. BEFORE RUNNING, SET ENVIRONMENT VARIABLES, E.G.:
	
		export installdir=/agua/location

=cut

use Test::More 	tests => 23;
use Getopt::Long;
use FindBin qw($Bin);
use lib "$Bin/../../../../../lib";	#### PACKAGE MODULES
use lib "$Bin/../../../lib";		#### TEST MODULES

use Conf::Yaml;

BEGIN
{
    my $installdir = $ENV{'installdir'} || "/agua";
    unshift(@INC, "$installdir/lib");
}

#### CREATE OUTPUTS DIR
my $outputsdir = "$Bin/outputs";
`mkdir -p $outputsdir` if not -d $outputsdir;

BEGIN {
    use_ok('Test::Queue::Task');
}
require_ok('Test::Queue::Task');

#### SET CONF FILE
my $installdir  =   $ENV{'installdir'} || "/agua";
my $urlprefix  =   $ENV{'urlprefix'} || "agua";

#### SET $Bin
#$Bin =~ s/^.+\/bin/$installdir\/t\/unit\/bin/;

#### GET OPTIONS
my $logfile 	= "$Bin/outputs/test.log";
my $showlog     =   2;
my $printlog    =   5;
my $help;
GetOptions (
    'showlog=i'     => \$showlog,
    'printlog=i'    => \$printlog,
    'logfile=s'     => \$logfile,
    'help'          => \$help
) or die "No options specified. Try '--help'\n";
usage() if defined $help;

my $configfile	=	"$installdir/conf/config.yaml";
my $conf	=	Conf::Yaml->new({
	inputfile	=>	$configfile,
	showlog		=>	$showlog,
	printlog	=>	$printlog
});

#my $object1 = new Test::Queue::Task::Receive(
#	conf		=>	$conf,
#    logfile     =>  $logfile,
#	showlog     =>  $showlog,
#	printlog    =>  $printlog
#);
#isa_ok($object1, "Test::Queue::Task", "object1");

##### INTERACTIVE
#$object1->testReceiveTask();

my $object2 = new Test::Queue::Task(
	conf		=>	$conf,
    logfile     =>  $logfile,
	showlog     =>  $showlog,
	printlog    =>  $printlog
);
isa_ok($object2, "Test::Queue::Task", "object2");

#### INTERACTIVE
$object2->testHandleTask();
#$object2->testSendTopic();
#$object2->testVerifyShutdown();
#$object2->testShutdown();

#### SATISFY Agua::Logger::logError CALL TO EXITLABEL
no warnings;
EXITLABEL : {};
use warnings;

#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#                                    SUBROUTINES
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

sub usage {
    print `perldoc $0`;
}

