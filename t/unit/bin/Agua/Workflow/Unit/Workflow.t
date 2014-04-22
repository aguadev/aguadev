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
my $showlog     =   2;
my $printlog    =   5;

my $help;
GetOptions (
    'logfile=s'     =>  \$logfile,
    'showlog=s'     =>  \$showlog,
    'printlog=s'    =>  \$printlog,
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
    showlog     =>  2,
    printlog    =>  2
);

my $object = Test::Agua::Workflow::Unit->new(
    conf            =>  $conf,
    logfile         =>  $logfile,
    dumpfile        =>  $dumpfile,
    showlog         =>  $showlog,
    printlog        =>  $printlog
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

