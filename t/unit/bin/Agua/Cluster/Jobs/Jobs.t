#!/usr/bin/perl -w

use MooseX::Declare;

use strict;

#### EXTERNAL MODULES
use Test::Simple tests => 4;
use Getopt::Long;
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

#### INTERNAL MODULES
use Test::Agua::Cluster::Jobs;
use Conf::Yaml;

#### GET OPTIONS
my $log = 3;
my $printlog = 3;
my $help;
GetOptions (
    'log=i'     => \$log,
    'printlog=i'    => \$printlog,
    'help'          => \$help
) or die "No options specified. Try '--help'\n";
usage() if defined $help;


my $logfile = "$Bin/outputs/testuser.cluster-jobs.log";

my $conf = Conf::Yaml->new(
	inputfile	=>	$configfile,
	backup		=>	1,
	separator	=>	"\t",
	spacer		=>	"\\s\+",
    logfile     =>  $logfile,
    log     	=>  2,
    printlog    =>  2
);

#### SET DUMPFILE
#my $dumpfile = "$Bin/../../../../../bin/sql/dump/agua.dump";
my $dumpfile    =   "$Bin/../../../../dump/create.dump";

my $object = Test::Agua::Cluster::Jobs->new({
    cluster     =>  "SGE",
    dumpfile    =>  $dumpfile,
    conf        =>  $conf,
    username    =>  "testuser",
    logfile     =>  $logfile,
    log			=>	$log,
    printlog    =>  $printlog
});

$object->testCreateTaskDirs();

