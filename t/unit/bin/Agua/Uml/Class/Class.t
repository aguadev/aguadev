#!/usr/bin/perl -w

use Test::More  tests => 5;

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

use Test::Agua::Uml::Class;
use Getopt::Long;
use FindBin qw($Bin);
use Conf::Yaml;

#### GET OPTIONS
my $showlog     =   2;
my $printlog    =   5;
my $help;
GetOptions (
    'showlog=i'     => \$showlog,
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
    showlog     =>  2,
    printlog    =>  2,
    logfile     =>  $logfile
);

my $object = new Test::Agua::Uml::Class (
    showlog     =>  $showlog,
    printlog    =>  $printlog,
    logfile     =>  $logfile,
    conf        =>  $conf
);

#### TESTS
$object->testSetRoles();
$object->testSetCalls();
$object->testSetClassName();
$object->testSetMethods();



##### CLEAN UP
#`rm -fr $Bin/outputs/*`
