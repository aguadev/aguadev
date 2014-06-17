#!/usr/bin/perl -w

use Test::More tests => 9;
use FindBin qw($Bin);
use Getopt::Long;

use lib "$Bin/../../../../lib";
BEGIN {
    my $installdir = $ENV{'installdir'} || "/agua";
    unshift(@INC, "$installdir/lib");
    unshift(@INC, "$installdir/t/unit/lib");
    unshift(@INC, "$installdir/t/common/lib");
}

BEGIN {
    use_ok('Test::Agua::Workflow::ExecuteProject'); 
}
require_ok('Test::Agua::Workflow::ExecuteProject');

use Test::Agua::Workflow::ExecuteProject;

#### SET $Bin
my $installdir  =   $ENV{'installdir'} || "/agua";
$Bin =~ s/^.+\/unit\/bin/$installdir\/t\/unit\/bin/;

#### SET DUMPFILE
my $dumpfile    =   "$installdir/bin/sql/dump/agua/create-agua.dump";

#### SET LOGFILE
my $logfile 	= 	"$Bin/outputs/opsinfo.log";
my $log     	=   2;
my $printlog    =   5;

my $help;
GetOptions (
    'logfile=s'     =>  \$logfile,
    'log=s'     	=>  \$log,
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
    log     	=>  2,
    printlog    =>  2
);

my $object = Test::Agua::Workflow::ExecuteProject->new(
    conf            =>  $conf,
    logfile         =>  $logfile,
    dumpfile        =>  $dumpfile,
    log				=>	$log,
    printlog        =>  $printlog
);
isa_ok($object, "Test::Agua::Workflow::ExecuteProject");

#### EXECUTE WORKFLOW
$object->testPrintConfig();
$object->testPrintAuth();
$object->testRunSiphon();
$object->testExecuteProject();

