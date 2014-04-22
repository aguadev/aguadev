#!/usr/bin/perl -w

use Test::More tests => 12;

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

use Test::Agua::CLI::App;
use Getopt::Long;
use FindBin qw($Bin);
use Conf::Yaml;

#### SET LOG
my $showlog     =   2;
my $printlog    =   5;
my $logfile = "$Bin/outputs/sync.log";

#### GET OPTIONS
my $login;
my $owner       =   "anonymous";
my $username    =   "syoung";
my $token;
my $keyfile;
my $help;
GetOptions (
    'showlog=i'     => \$showlog,
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
    showlog     =>  2,
    printlog    =>  2,
    logfile     =>  $logfile
);

my $object = new Test::Agua::CLI::App(
    showlog     =>  $showlog,
    printlog    =>  $printlog,
    logfile     =>  $logfile,
    dumpfile    =>  $dumpfile,
    conf        =>  $conf,
    username    =>  $username,
    owner       =>  $owner
);

#### START LOG AFRESH
$object->startLog($object->logfile());

#### TEST loadUsage
$object->testLoadUsage();

#### CLEAN UP
`rm -fr $Bin/outputs/*`
