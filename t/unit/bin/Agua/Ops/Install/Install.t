#!/usr/bin/perl -w

use Test::More tests => 9;     #  qw(no_plan);
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

use Test::Agua::Ops::Install;
use Getopt::Long;
use Conf::Yaml;

#### SET DUMPFILE
my $dumpfile    =   "$Bin/../../../../dump/create.dump";

#### SET CONF FILE
my $installdir  =   $ENV{'installdir'} || "/agua";
my $configfile    =   "$installdir/conf/config.yaml";

#### SET $Bin
$Bin =~ s/^.+\/bin/$installdir\/t\/bin/;

#### SET LOG
my $SHOWLOG     =   2;
my $PRINTLOG    =   5;
my $logfile     =   "$Bin/outputs/install.log";

#### GET OPTIONS
my $pwd = $Bin;
my $login;
my $showreport = 1;
my $token;
my $keyfile;
my $help;
GetOptions (
    'SHOWLOG=i'     => \$SHOWLOG,
    'PRINTLOG=i'    => \$PRINTLOG,
    'login=s'       => \$login,
    'showreport=s'  => \$showreport,
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
    print "Missing login, token or keyfile. Run this script manually and provide GitHub login and token credentials and SSH private keyfile\n";
    done_testing(9);
    exit;
}

my $whoami = `whoami`;
$whoami =~ s/\s+//g;
print "Install.t    Must run as root\n" and exit if $whoami ne "root";

my $conf = Conf::Yaml->new(
    memory      =>  1,
    inputfile	=>	$configfile,
    SHOWLOG     =>  2,
    PRINTLOG    =>  2,
    logfile     =>  $logfile
);

my $username = $conf->getKey("database", "TESTUSER");

my $object = new Test::Agua::Ops::Install (
    SHOWLOG     =>  $SHOWLOG,
    PRINTLOG    =>  $PRINTLOG,
    logfile     =>  $logfile,
    dumpfile    =>  $dumpfile,
    conf        =>  $conf,
    showreport  =>  $showreport,
    pwd         =>  $pwd,
    username    =>  $username,
    
    installdir  =>  $installdir,
    login       =>  $login,
    token       =>  $token,
    keyfile     =>  $keyfile
);

##### TEST UPDATE CONFIG
#$object->testUpdateConfig();
#
##### TEST LOAD CONFIG
#$object->testLoadConfig();
#
##### TEST PARSE REPORT
#$object->testParseReport();
#
##### TEST INSTALL AGUA
#$object->testInstallAgua();
#
##### ONWORKING:
########### TEST TERMINAL INSTALL
#######$object->testTerminalInstall();

#### TEST INSTALL BIOAPPS
$object->testInstallBioApps();

##### TEST INSTALL BIOAPPS
#$object->testInstallTests();

#### CLEAN UP
`rm -fr $Bin/outputs/*`;


#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#                                    SUBROUTINES
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

sub usage {
    print `perldoc $0`;
}

