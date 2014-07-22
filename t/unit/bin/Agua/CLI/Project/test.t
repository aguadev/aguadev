#!/usr/bin/perl -w

use Test::More qw(no_plan);

use FindBin qw($Bin);
use lib "$Bin/../../../../lib";
BEGIN
{
    my $installdir = $ENV{'installdir'} || "/agua";
    unshift(@INC, "$installdir/lib");
    unshift(@INC, "$installdir/t/common/lib");
    unshift(@INC, "$installdir/t/unit/lib");
}

#### CREATE OUTPUTS DIR
my $outputsdir = "$Bin/outputs";
`mkdir -p $outputsdir` if not -d $outputsdir;


#### SET CONF FILE
my $installdir  =   $ENV{'installdir'} || "/agua";
my $configfile  =   "$installdir/conf/config.yaml";

#### SET $Bin
$Bin =~ s/^.+t\/bin/$installdir\/t\/unit\/bin/;

#### SET DUMPFILE
my $dumpfile    =   "$Bin/../../../../dump/create.dump";

use Test::Agua::CLI::Project;
use Getopt::Long;
use FindBin qw($Bin);
use Conf::Yaml;

#### SET LOG
my $log     =   2;
my $printlog    =   5;
my $logfile = "$Bin/outputs/test.log";

#### GET OPTIONS
my $login;
my $owner;
my $username = "syoung";
my $token;
my $keyfile;
my $help;
GetOptions (
    'log=i'     => \$log,
    'printlog=i'    => \$printlog,
    'login=s'       => \$login,
    'owner=s'       => \$owner,
    'username=s'    => \$username,
    'token=s'       => \$token,
    'keyfile=s'     => \$keyfile,
    'help'          => \$help
) or die "No options specified. Try '--help'\n";
usage() if defined $help;

#### LOAD LOGIN, ETC. FROM ENVIRONMENT VARIABLES
$login = $ENV{'login'} if not defined $login or not $login;
$token = $ENV{'token'} if not defined $token;
$keyfile = $ENV{'keyfile'} if not defined $keyfile;

my $conf = Conf::Yaml->new(
    memory      =>  1,
    inputfile	=>	$configfile,
    log     =>  2,
    printlog    =>  2,
    logfile     =>  $logfile
);

my $object = new Test::Agua::CLI::Project(
    log			=>	$log,
    printlog    =>  $printlog,
    logfile     =>  $logfile,
    dumpfile    =>  $dumpfile,
    conf        =>  $conf,
    username    =>  $username
);

#### START LOG AFRESH
$object->startLog($object->logfile());

##### TEST SORT WORKFLOW FILES
#$object->testSortWorkflowFiles();

#### TEST GET WORKFLOW FILES
#$object->testGetWorkflowFiles();

#### SAVE
#$object->testSave();

#### SAVE WORKFLOW
#$object->testSaveWorkflow();

##### DELETE
#$object->testDelete();

#### LOAD SCRIPT
$object->testLoadScript();

##### CLEAN UP
#`rm -fr $Bin/outputs/*`
