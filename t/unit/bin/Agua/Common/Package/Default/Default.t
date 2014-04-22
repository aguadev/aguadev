#!/usr/bin/perl -w

use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../../../../../lib";
use lib "$Bin/../../../../../../common/lib";
BEGIN
{
    my $installdir = $ENV{'installdir'} || "/agua";
    unshift(@INC, "$installdir/lib");
    unshift(@INC, "$installdir/lib/external/lib/perl5");
}

#### CREATE OUTPUTS DIR
my $outputsdir = "$Bin/outputs";
`mkdir -p $outputsdir` if not -d $outputsdir;


#### SET DUMPFILE
my $dumpfile    =   "$Bin/../../../../../dump/agua.dump";

#### SET CONF FILE
my $installdir  =   $ENV{'installdir'} || "/agua";
my $configfile    =   "$installdir/conf/config.yaml";

use Test::Agua::Common::Package::Default;
use Getopt::Long;
use FindBin qw($Bin);
use Conf::Yaml;

#### SET LOG
my $showlog     =   2;
my $printlog    =   5;
my $logfile = "$Bin/outputs/defaults.log";

#### GET OPTIONS
my $login;
my $token;
my $keyfile;
my $help;
GetOptions (
    'showlog=i'     => \$showlog,
    'printlog=i'    => \$printlog,
    'login=s'       => \$login,
    'token=s'       => \$token,
    'keyfile=s'     => \$keyfile,
    'help'          => \$help
) or die "No options specified. Try '--help'\n";
usage() if defined $help;

#### LOAD LOGIN, ETC. FROM ENVIRONMENT VARIABLES
$login      = $ENV{'login'} if not defined $login or not $login;
$token      = $ENV{'token'} if not defined $token;
$keyfile    = $ENV{'keyfile'} if not defined $keyfile;

if ( not defined $login or not defined $token
    or not defined $keyfile ) {
    plan 'skip_all' => "Missing login, token or keyfile. Run this script manually and provide GitHub login and token credentials and SSH private keyfile";
}
else {
    plan tests => 6;
}

my $whoami = `whoami`;
$whoami =~ s/\s+//g;
print "Must run as root\n" and exit if $whoami ne "root";

my $conf = Conf::Yaml->new(
    memory      =>  1,
    inputfile	=>	$configfile,
    showlog     =>  2,
    printlog    =>  2,
    logfile     =>  $logfile
);

#### GET TEST USER
my $username    =   $conf->getKey("database", "TESTUSER");

my $object = new Test::Agua::Common::Package::Default (
    showlog     =>  $showlog,
    printlog    =>  $printlog,
    logfile     =>  $logfile,
    dumpfile    =>  $dumpfile,
    conf        =>  $conf,

    login       =>  $login,
    token       =>  $token,
    keyfile     =>  $keyfile,
    username    =>  $username
);

#### TEST DEFAULT PACKAGES
$object->testDefaultPackages();

#### CLEAN UP
`rm -fr $Bin/outputs/*`
