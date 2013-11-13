#!/usr/bin/perl -w

use Test::More tests => 6;
use FindBin qw($Bin);
use Getopt::Long;

use lib "$Bin/../../../../lib";
BEGIN
{
    my $installdir = $ENV{'installdir'} || "/agua";
    unshift(@INC, "$installdir/lib");
}

BEGIN {
    use_ok('Test::Agua::Workflow::GetStatus'); 
}
require_ok('Test::Agua::Workflow::GetStatus');

use Test::Agua::Workflow::GetStatus;

#### SET $Bin
my $installdir  =   $ENV{'installdir'} || "/agua";
$Bin =~ s/^.+bin/$installdir\/t\/bin/;

#### SET DUMPFILE
my $dumpfile    =   "$Bin/../../../../dump/create.dump";

#### SET LOGFILE
my $logfile = "$Bin/outputs/opsinfo.log";
my $SHOWLOG     =   2;
my $PRINTLOG    =   5;

my $help;
GetOptions (
    'logfile=s'     =>  \$logfile,
    'SHOWLOG=s'     =>  \$SHOWLOG,
    'PRINTLOG=s'    =>  \$PRINTLOG,
    'help'          =>  \$help
) or die "No options specified. Try '--help'\n";
usage() if defined $help;

#### SET CONF
my $configfile  =   "$installdir/conf/config.yaml";
my $conf = Conf::Yaml->new(
	inputfile	=>	$configfile,
	memory		=>	1,
	backup		=>	1,
	separator	=>	"\t",
	spacer		=>	"\\s\+",
    logfile     =>  $logfile,
    SHOWLOG     =>  2,
    PRINTLOG    =>  2
);

my $object = Test::Agua::Workflow::GetStatus->new(
    conf            =>  $conf,
    logfile         =>  $logfile,
    dumpfile        =>  $dumpfile,
    SHOWLOG         =>  $SHOWLOG,
    PRINTLOG        =>  $PRINTLOG
);
isa_ok($object, "Test::Agua::Workflow::GetStatus");

##### LOAD STARCLUSTER
#$object->testLoadStarCluster();
#
##### EXECUTE WORKFLOW
#$object->testStartStarCluster();

#### GET STATUS
$object->testGetStatus();

##### GET CLUSTER WORKFLOW
#$object->testGetClusterWorkflow();
#
##### UPDATE CLUSTER WORKFLOW
#$object->testUpdateClusterWorkflow();
#
##### UPDATE CLUSTER WORKFLOW
#$object->testUpdateWorkflowStatus();

