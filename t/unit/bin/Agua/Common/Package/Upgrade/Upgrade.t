#!/usr/bin/perl -w

use Test::More  tests => 15;  # qw(no_plan);

use FindBin qw($Bin);
use lib "$Bin/../../../../../lib";
BEGIN
{
    my $installdir = $ENV{'installdir'} || "/agua";
    unshift(@INC, "$installdir/lib");
}

#### CREATE OUTPUTS DIR
my $outputsdir = "$Bin/outputs";
`mkdir -p $outputsdir` if not -d $outputsdir;

#### SET DUMPFILE
my $dumpfile    =   "$Bin/../../../../../dump/create.dump";

#### SET CONF FILE
my $installdir  =   $ENV{'installdir'} || "/agua";
my $configfile    =   "$installdir/conf/config.yaml";

use Test::Agua::Common::Package::Upgrade;
use Getopt::Long;
use FindBin qw($Bin);
use Conf::Yaml;

#### SET LOG
my $logfile = "$Bin/outputs/upgrade.log";

#### GET OPTIONS
my $SHOWLOG     =   2;
my $PRINTLOG    =   5;
my $login;
my $token;
my $keyfile;
my $help;
GetOptions (
    'SHOWLOG=i'     => \$SHOWLOG,
    'PRINTLOG=i'    => \$PRINTLOG,
    'login=s'       => \$login,
    'token=s'       => \$token,
    'keyfile=s'     => \$keyfile,
    'help'          => \$help
) or die "No options specified. Try '--help'\n";
usage() if defined $help;

#### LOAD LOGIN, ETC. FROM ENVIRONMENT VARIABLES
$login = $ENV{'login'} if not defined $login or not $login;
$token = $ENV{'token'} if not defined $token;
$keyfile = $ENV{'keyfile'} if not defined $keyfile;

if ( not defined $login or not defined $token
    or not defined $keyfile ) {
    plan 'skip_all' => "Missing login, token or keyfile. Run this script manually and provide GitHub login and token credentials and SSH private keyfile";
}

my $whoami = `whoami`;
$whoami =~ s/\s+//g;
print "Must run as root\n" and exit if $whoami ne "root";

#### SET CONF
my $conf = Conf::Yaml->new(
    memory      =>  1,
    inputfile	=>	$configfile,
    SHOWLOG     =>  2,
    PRINTLOG    =>  2,
    logfile     =>  $logfile
);

my $object = new Test::Agua::Common::Package::Upgrade(
    SHOWLOG     =>  $SHOWLOG,
    PRINTLOG    =>  $PRINTLOG,
    logfile     =>  $logfile,
    dumpfile    =>  $dumpfile,
    conf        =>  $conf
);

#### START LOG AFRESH
$object->startLog($object->logfile());

#### TEST SET LOGIN CREDENTIALS
$object->testSetLoginCredentials();

#### TEST UPGRADE
$object->testUpgrade();

#### CLEAN UP
`rm -fr $Bin/outputs/*`;

#### SATISFY Agua::Common::Logger::logError CALL TO EXITLABEL
no warnings;
EXITLABEL : {};
use warnings;


