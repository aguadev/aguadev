#!/usr/bin/perl -w

use Test::More	tests => 18;

use FindBin qw($Bin);
use lib "$Bin/../../../../lib";
BEGIN
{
    my $installdir = $ENV{'installdir'} || "/agua";
    unshift(@INC, "$installdir/lib");
    unshift(@INC, "$installdir/lib/external/lib/perl5");
}

#### CREATE OUTPUTS DIR
my $outputsdir = "$Bin/outputs";
`mkdir -p $outputsdir` if not -d $outputsdir;


#### SET CONF FILE
my $installdir  =   $ENV{'installdir'} || "/agua";
my $configfile  =   "$installdir/conf/config.yaml";

#### SET $Bin
$Bin =~ s/^.+t\/bin/$installdir\/t\/bin/;

#### SET DUMPFILE
my $dumpfile    =   "$Bin/../../../../dump/create.dump";

use Test::Agua::Common::Stage;
use Getopt::Long;
use Conf::Yaml;
use FindBin qw($Bin);

#### GET CONF
my $logfile     =    "$Bin/outputs/stage.log";
my $conf = Conf::Yaml->new(
	inputfile	=>	$configfile,
	backup		=>	1,
	separator	=>	"\t",
	spacer		=>	"\\s\+",
    logfile     =>  $logfile,
	showlog     =>  2,
	printlog    =>  2
);

#### GET OPTIONS
my $showlog = 2;
my $printlog = 5;
my $help;
GetOptions (
    'showlog=i'     => \$showlog,
    'printlog=i'    => \$printlog,
    'dumpfile=s'    => \$dumpfile,
    'help'          => \$help
) or die "No options specified. Try '--help'\n";


usage() if defined $help;

my $database    = $conf->getKey('database', 'TESTDATABASE');
my $user        = $conf->getKey('database', 'TESTUSER');
my $password    = $conf->getKey('database', 'TESTPASSWORD');
my $object = new Test::Agua::Common::Stage(
    logfile     =>  $logfile,
	showlog     =>  $showlog,
	printlog    =>  $printlog,
    conf        =>  $conf,
    dumpfile    =>  $dumpfile,
    database    =>  $database,
    user        =>  $user,
    username    =>  $user,
    password    =>  $password
);

#### STAGE TO BE ADDED/REMOVED    
my $json = {
    "name"	    =>	"indexReads",
    "owner"	    =>	"admin",
    "type"	    =>	"index",
    "executor"	=>	"/usr/bin/perl",
    "localonly"	=>	"0",
    "location"	=>	"apps/index/indexReads.pl",
    "description"=>	"Index SAM files by read name",
    "notes"	    =>	"Notes",
    "appname"	=>	"indexReads",
    "appnumber"	=>	"3",
    "number"	=>	"3",
    "cluster"	=>	"",
    "project"	=>	"Project1XXX",
    "workflow"	=>	"Workflow1XXX",
    "username"	=>	"syoung",
    "workflownumber"	=>	"1",
    "sessionId"	=>	"1234567890.1234.123",
    "mode"	    =>	"insertStage"
};

#### ADD STAGE / REMOVE STAGE
#$object->testAddRemoveStage($json);

#### INSERT STAGE
$object->testInsertStage();
