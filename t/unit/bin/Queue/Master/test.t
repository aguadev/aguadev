#!/usr/bin/perl -w

=head2
	
APPLICATION 	test.t

PURPOSE

	Test Queue::Master module
	
NOTES

	1. RUN AS ROOT
	
	2. BEFORE RUNNING, SET ENVIRONMENT VARIABLES, E.G.:
	
		export installdir=/agua/location

=cut

use Test::More 	tests =>	17;
use Getopt::Long;
use FindBin qw($Bin);
use lib "$Bin/../../../../../lib";		#### PACKAGE MODULES
use lib "$Bin/../../../lib";			#### TEST MODULES
use lib "$Bin/../../../../common/lib";	#### TEST MODULES
BEGIN
{
    my $installdir = $ENV{'installdir'} || "/agua";
    unshift(@INC, "$installdir/lib");
}

#### CREATE OUTPUTS DIR
my $outputsdir = "$Bin/outputs";
`mkdir -p $outputsdir` if not -d $outputsdir;

BEGIN {
    use_ok('Test::Queue::Master');
    use_ok('Test::Queue::Master::Manage');
}
require_ok('Test::Queue::Master');
require_ok('Test::Queue::Master::Manage');

#### SET CONF FILE
my $installdir  =   $ENV{'installdir'} || "/agua";
my $urlprefix  	=   $ENV{'urlprefix'} || "agua";
my $ospassword	=	$ENV{'ospassword'};
my $osauthurl	=	$ENV{'osauthurl'};
my $ostenantid	=	$ENV{'ostenantid'};
my $ostenantname=	$ENV{'ostenantname'};
my $osusername	=	$ENV{'osusername'};

#### SET $Bin
$Bin =~ s/^.+\/unit\/bin/$installdir\/t\/unit\/bin/;

#### GET OPTIONS
my $logfile 	= "$Bin/outputs/test.log";
my $log     	=   2;
my $printlog    =   5;
my $help;
GetOptions (
    'log=i'     => \$log,
    'printlog=i'    => \$printlog,
    'logfile=s'     => \$logfile,
    'help'          => \$help
) or die "No options specified. Try '--help'\n";
usage() if defined $help;

my $configfile	=	"$installdir/conf/config.yaml";
my $conf	=	Conf::Yaml->new({
	inputfile	=>	$configfile,
	log			=>	$log,
	printlog	=>	$printlog
});

my $dumpfile	=	"$installdir/bin/sql/dump/agua/create-agua.dump";
my $object1 = new Test::Queue::Master(
	conf		=>	$conf,
    logfile     =>  $logfile,
    dumpfile    =>  $dumpfile,
	log			=>	$log,
	printlog    =>  $printlog
);
isa_ok($object1, "Test::Queue::Master", "object1");

#### AUTOMATED
#$object1->testDownloadPercent();
#$object1->testParseUuid();
#$object1->testGetNumberQueuedJobs();
#$object1->testHandleTopic();
#$object1->testGetSynapseStatus();
#$object1->testUpdateSamples();
#$object1->testUpdateQueueSamples();
#$object1->testGetQueues();
#$object1->testManage();
#$object1->testParseDate();
#$object1->testGetSampleDurations();
######$object1->testGetDuration();
#$object1->testGetQueueDuration();
#$object1->testGetQueueInstance();
#$object1->testGetLatestCompleted();
#$object1->testGetLatestStarted();
#$object1->testGetTenants();
#$object1->testGetRunningUserProjects();
#$object1->testGetQueueTasks();
#$object1->testGetDurations();
#$object1->testGetInstances();
#$object1->testGetResourceCounts();
$object1->testBalanceQueues();

##### INTERACTIVE
#$object1->testReceiveTopic();
##$object1->testListenTopics();
##$object1->testMaintainQueue();


my $object2 = new Test::Queue::Master::Manage(

	ospassword	=>	$ospassword,
	osauthurl	=>	$osauthurl,
	ostenantid	=>	$ostenantid,
	ostenantname=>	$ostenantname,
	osusername	=>	$osusername,

	conf		=>	$conf,
    logfile     =>  $logfile,
    dumpfile    =>  $dumpfile,
	log			=>	$log,
	printlog    =>  $printlog
);
isa_ok($object2, "Test::Queue::Master::Manage", "object2");

#$object2->testManage();



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

