#!/usr/bin/perl -w

use Test::More tests => 18;     #  qw(no_plan);
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

use Test::Agua::Ops::GitHub;
use Getopt::Long;
use Conf::Yaml;

#### SET DUMPFILE
my $dumpfile    =   "$Bin/../../../../dump/create.dump";

#### SET CONF FILE
my $installdir  =   $ENV{'installdir'} || "/agua";
my $configfile    =   "$installdir/conf/config.yaml";

#### SET $Bin
$Bin =~ s/^.+t\/bin/$installdir\/t\/bin/;

#### SET LOG
my $SHOWLOG     =   2;
my $PRINTLOG    =   5;
my $logfile     =   "$Bin/outputs/install.log";

#### GET OPTIONS
my $pwd = $Bin;
my $login;
my $showreport = 1;
my $token;
my $password;
my $keyfile;
my $help;
GetOptions (
    'SHOWLOG=i'     => \$SHOWLOG,
    'PRINTLOG=i'    => \$PRINTLOG,
    'login=s'       => \$login,
    'showreport=s'  => \$showreport,
    'token=s'       => \$token,
    'password=s'    => \$password,
    'keyfile=s'     => \$keyfile,
    'help'          => \$help
) or die "No options specified. Try '--help'\n";
usage() if defined $help;

#### LOAD LOGIN, ETC. FROM ENVIRONMENT VARIABLES
$login = $ENV{'login'} if not defined $login or not $login;
$token = $ENV{'token'} if not defined $token;
$password = $ENV{'password'} if not defined $password;
$keyfile = $ENV{'keyfile'} if not defined $keyfile;

my $whoami = `whoami`;
$whoami =~ s/\s+//g;
if ( not defined $login or not defined $token
    or not defined $keyfile ) {
    print "Missing login, token or keyfile. Run this script manually and provide GitHub login and token credentials and SSH private keyfile\n";
    #ok(1, "Quitting");
    for ( 0 .. 17 ) { pass; }
    done_testing(18);
    #skip(18);
    exit;
}
elsif ( $whoami ne "root" ) {
    print "Install.t    Must run as root\n";
    #done_testing(1);
    #is_passing(18);
    
    exit ;    
}

my $conf = Conf::Yaml->new(
    memory      =>  1,
    inputfile	=>	$configfile,
    SHOWLOG     =>  2,
    PRINTLOG    =>  2,
    logfile     =>  $logfile
);

my $username = $conf->getKey("database", "TESTUSER");

my $object = new Test::Agua::Ops::GitHub (
    SHOWLOG     =>  $SHOWLOG,
    PRINTLOG    =>  $PRINTLOG,
    logfile     =>  $logfile,
    dumpfile    =>  $dumpfile,
    conf        =>  $conf,
    showreport  =>  $showreport,
    pwd         =>  $pwd,
    username    =>  $username,
    
    login       =>  $login,
    token       =>  $token,
    password    =>  $password,
    keyfile     =>  $keyfile
);


#### TEST GET USER INFO
$object->testGetUserInfo();

#### TEST SET CREDENTIALS
$object->testSetCredentials();

#### TEST GET REPO
$object->testGetRepo();

#### TEST GET REPO
$object->testGetRemoteTags();

#### TEST CREATE REPO
$object->testCreateRepo();

#### TEST FORK REPO
$object->testForkRepo();

#### TEST FORK REPO
$object->testRemoveOAuthToken();

#### TEST FORK REPO
$object->testAddOAuthToken();

#### CLEAN UP
`rm -fr $Bin/outputs/*`
