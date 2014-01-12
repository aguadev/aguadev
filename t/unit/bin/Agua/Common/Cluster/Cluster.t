#!/usr/bin/perl -w

#### EXTERNAL MODULES
use Test::More  tests => 13;

use FindBin qw($Bin);
use lib "$Bin/../../../../lib";
BEGIN
{
    my $installdir = $ENV{'installdir'} || "/agua";
    unshift(@INC, "$installdir/lib");
}

#### CREATE OUTPUTS DIR
my $outputsdir = "$Bin/outputs";
`mkdir -p $outputsdir` if not -d $outputsdir;


#### INTERNAL MODULES
use Test::Agua::Common::Cluster;
use Conf::Yaml;

my $SHOWLOG     = 3;
my $PRINTLOG    = 3;
my $logfile = "$Bin/outputs/testuser.cluster.log";

#### SET CONF FILE
my $installdir  =   $ENV{'installdir'} || "/agua";
my $configfile  =   "$installdir/conf/config.yaml";

#### SET $Bin
$Bin =~ s/^.+t\/bin/$installdir\/t\/bin/;

my $conf = Conf::Yaml->new(
	inputfile	=>	$configfile,
	backup		=>	1,
	separator	=>	"\t",
	spacer		=>	"\\s\+",
    logfile     =>  $logfile,
    SHOWLOG     =>  2,
    PRINTLOG    =>  2
);

#### SET DUMPFILE
#my $dumpfile = "$Bin/../../../../bin/sql/dump/agua.dump";
my $dumpfile    =   "$Bin/../../../../dump/create.dump";

my $tester = new Test::Agua::Common::Cluster(
    database    =>  "testuser",
    dumpfile    =>  $dumpfile,
    logfile     =>  $logfile,
    conf        =>  $conf,
    json        =>  {
        username    =>  'syoung'
    },
    username    =>  "testuser",
    project     =>  "Project1",
    workflow    =>  "Workflow1",
    SHOWLOG     =>  $SHOWLOG,
    PRINTLOG    =>  $PRINTLOG
);

#### STAGE TO BE ADDED/REMOVED    
my $json = {
    username	=>	"syoung",
    description	=>	"Small test cluster",
    availzone	=>	"us-east-1a",
    cluster	    =>	"syoung-testcluster",
    minnodes	=>	"0",
    maxnodes	=>	"5",
    amiid	    =>	"ami-b07985d9",
    instancetype=>	"t1.micro"
};
$tester->testAddRemoveCluster($json);

