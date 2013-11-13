#!/usr/bin/perl -w

use Test::More  tests => 100;

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

#### SET DUMPFILE
my $dumpfile    =   "$Bin/../../../../../../dump/create.dump";

#### SET CONF FILE
my $installdir  =   $ENV{'installdir'} || "/agua";
my $configfile    =   "$installdir/conf/config.yaml";

use Conf::Yaml;
use Test::Agua::StarCluster;
use Getopt::Long;
use FindBin qw($Bin);
use Conf::Yaml;

#### SET LOG
my $logfile = "$Bin/outputs/upgrade.log";

#### GET OPTIONS
my $SHOWLOG     =   2;
my $PRINTLOG    =   5;
my $keyfile;
my $amazonuserid;
my $awsaccesskeyid;
my $awssecretaccesskey;
my $help;
GetOptions (
    'SHOWLOG=i'             => \$SHOWLOG,
    'PRINTLOG=i'            => \$PRINTLOG,
    'keyfile=s'             => \$keyfile,
    'amazonuserid=s'        => \$amazonuserid,
    'awsaccesskeyid=s'      => \$awsaccesskeyid,
    'awssecretaccesskey=s'  => \$awssecretaccesskey,
    'help'                  => \$help
) or die "No options specified. Try '--help'\n";
usage() if defined $help;


#### LOAD LOGIN, ETC. FROM ENVIRONMENT VARIABLES
$keyfile            = $ENV{'keyfile'} if not defined $keyfile or not $keyfile;
$amazonuserid       = $ENV{'amazonuserid'} if not defined $amazonuserid or not $amazonuserid;
$awsaccesskeyid     = $ENV{'awsaccesskeyid'} if not defined $awsaccesskeyid;
$awssecretaccesskey = $ENV{'awssecretaccesskey'} if not defined $awssecretaccesskey;

#print "StarCluster.t    keyfile not defined\n" and exit if not defined $keyfile;
#print "StarCluster.t    amazonuserid not defined\n" and exit if not defined $amazonuserid;
#print "StarCluster.t    awsaccesskeyid not defined\n" and exit if not defined $awsaccesskeyid;
#print "StarCluster.t    awssecretaccesskey not defined\n" and exit if not defined $awssecretaccesskey;

my $conf = Conf::Yaml->new(
    memory      =>  1,
    inputfile	=>	$configfile,
    SHOWLOG     =>  2,
    PRINTLOG    =>  2,
    logfile     =>  $logfile
);

my $object = new Test::Agua::StarCluster(
    SHOWLOG     =>  $SHOWLOG,
    PRINTLOG    =>  $PRINTLOG,
    logfile     =>  $logfile,
    dumpfile    =>  $dumpfile,
    conf        =>  $conf,

    amazonuserid        =>  $amazonuserid,
    awsaccesskeyid      =>  $awsaccesskeyid,
    awssecretaccesskey  =>  $awssecretaccesskey,
    keyfile             =>  $keyfile
);


$object->testGetProcessPids();
$object->testGetProcessTree();

#### TEST start
$object->testStartCluster();

#### TEST clear
$object->testClear();

#### RESTORE INPUT VALUES AFTER CALL TO 'clear'
$object->keyfile($keyfile);
$object->amazonuserid($amazonuserid);
$object->awsaccesskeyid($awsaccesskeyid);
$object->awssecretaccesskey($awssecretaccesskey);
$object->conf($conf);

#### TEST load
$object->testLoad();

exit;

##### CLEAN UP
#`rm -fr $Bin/outputs/*`;

#### SATISFY Agua::Common::Logger::logError CALL TO EXITLABEL
no warnings;
EXITLABEL : {};
use warnings;


