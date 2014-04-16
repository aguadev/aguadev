#!/usr/bin/perl -w

use Test::More tests => 24;
use FindBin qw($Bin);
use Getopt::Long;

use lib "$Bin/../../../../lib";
BEGIN
{
    my $installdir = $ENV{'installdir'} || "/agua";
    unshift(@INC, "$installdir/lib");
    unshift(@INC, "$installdir/lib/external/lib/perl5");
}

BEGIN {
    use_ok('Test::Agua::Workflow::Unit'); 
}
require_ok('Test::Agua::Workflow::Unit');

use Test::Agua::Workflow::Unit;

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

my $object = Test::Agua::Workflow::Unit->new(
    conf            =>  $conf,
    logfile         =>  $logfile,
    dumpfile        =>  $dumpfile,
    SHOWLOG         =>  $SHOWLOG,
    PRINTLOG        =>  $PRINTLOG
);
isa_ok($object, "Test::Agua::Workflow::Unit");

#### LOAD STARCLUSTER
$object->testLoadStarCluster();

#### EXECUTE WORKFLOW
$object->testStartStarCluster();

#### GET CLUSTER WORKFLOW
$object->testGetClusterWorkflow();

#### UPDATE CLUSTER WORKFLOW
$object->testUpdateClusterWorkflow();

#### UPDATE CLUSTER WORKFLOW
$object->testUpdateWorkflowStatus();

