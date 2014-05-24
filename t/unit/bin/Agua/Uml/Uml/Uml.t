#!/usr/bin/perl -w

use Test::More  tests => 2;

use FindBin qw($Bin);
use lib "$Bin/../../../../lib";
BEGIN
{
    my $installdir = $ENV{'installdir'} || "/agua";
    unshift(@INC, "$installdir/lib");
    unshift(@INC, "$installdir/lib/external/lib/perl5");
}

#### SET CONF FILE
my $installdir  =   $ENV{'installdir'} || "/agua";
my $configfile    =   "$installdir/conf/config.yaml";

use Test::Agua::Uml;
use Getopt::Long;
use FindBin qw($Bin);
use Conf::Yaml;

#### GET OPTIONS
my $log     =   2;
my $printlog    =   5;
my $help;
GetOptions (
    'log=i'     => \$log,
    'printlog=i'    => \$printlog,
    'help'          => \$help
) or die "No options specified. Try '--help'\n";
usage() if defined $help;

#### SET LOG
my $logfile = "$Bin/outputs/defaults.log";

#### SET CONF
my $conf = Conf::Yaml->new(
    memory      =>  1,
    inputfile	=>	$configfile,
    log     =>  2,
    printlog    =>  2,
    logfile     =>  $logfile
);

my $object = new Test::Agua::Uml (
    log			=>	$log,
    printlog    =>  $printlog,
    logfile     =>  $logfile,
    conf        =>  $conf
);
isa_ok($object, "Test::Agua::Uml");

#### TEST ROLE USER
$object->testRoleUser();

###### TO DO:
###### TEST USER ROLES
##$object->testUserRoles();

###### TO DO:
###### TEST GET USERS
##$object->testRoleUsers();


##### CLEAN UP
#`rm -fr $Bin/outputs/*`
