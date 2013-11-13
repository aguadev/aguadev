#!/usr/bin/perl -w

use Test::More  tests => 7;

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
my $SHOWLOG = 3;
my $PRINTLOG = 5;
my $help;
GetOptions (
    'SHOWLOG=i'     => \$SHOWLOG,
    'PRINTLOG=i'    => \$PRINTLOG,
    'help'          => \$help
) or die "No options specified. Try '--help'\n";
usage() if defined $help;

my $logfile = "$Bin/outputs/instance.log";

my $conf = Conf::Yaml->new(
    memory      =>  1,
    inputfile	=>	$configfile,
    SHOWLOG     =>  2,
    PRINTLOG    =>  2,
    logfile     =>  $logfile
);

my $object = new Test::Agua::StarCluster::Instance(
    conf        =>  $conf,
    logfile     =>  $logfile,
    SHOWLOG     =>  $SHOWLOG,
    PRINTLOG    =>  $PRINTLOG
);

#### TEST PARSE INFO
$object->testParseClusterInfo();