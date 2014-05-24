#!/usr/bin/perl -w

use Test::More  tests => 7;

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

use Test::Agua::StarCluster::Instance;
use Getopt::Long;
use Conf::Yaml;
use FindBin qw($Bin);

#### SET CONF FILE
my $installdir  =   $ENV{'installdir'} || "/agua";
my $configfile  =   "$installdir/conf/config.yaml";

#### SET $Bin
$Bin =~ s/^.+t\/bin/$installdir\/t\/bin/;

#### GET OPTIONS
my $log = 3;
my $printlog = 5;
my $help;
GetOptions (
    'log=i'     => \$log,
    'printlog=i'    => \$printlog,
    'help'          => \$help
) or die "No options specified. Try '--help'\n";
usage() if defined $help;

my $logfile = "$Bin/outputs/instance.log";

my $conf = Conf::Yaml->new(
    memory      =>  1,
    inputfile	=>	$configfile,
    log     =>  2,
    printlog    =>  2,
    logfile     =>  $logfile
);

my $object = new Test::Agua::StarCluster::Instance(
    conf        =>  $conf,
    logfile     =>  $logfile,
    log			=>	$log,
    printlog    =>  $printlog
);

#### TEST PARSE INFO
$object->testParseClusterInfo();