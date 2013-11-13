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
my $SHOWLOG = 3;
my $PRINTLOG = 3;
my $help;
GetOptions (
    'SHOWLOG=i'     => \$SHOWLOG,
    'PRINTLOG=i'    => \$PRINTLOG,
    'help'          => \$help
) or die "No options specified. Try '--help'\n";
usage() if defined $help;


my $logfile = "$Bin/outputs/aguatest.cluster-jobs.log";

my $conf = Conf::Yaml->new(
	inputfile	=>	$configfile,
	backup		=>	1,
	separator	=>	"\t",
	spacer		=>	"\\s\+",
    logfile     =>  $logfile,
    SHOWLOG     =>  2,
    PRINTLOG    =>  2
);

#### SET DUMPFILE
#my $dumpfile = "$Bin/../../../../../bin/sql/dump/agua.dump";
my $dumpfile    =   "$Bin/../../../../dump/create.dump";

my $object = Test::Agua::Cluster::Jobs->new({
    cluster     =>  "SGE",
    dumpfile    =>  $dumpfile,
    conf        =>  $conf,
    username    =>  "aguatest",
    logfile     =>  $logfile,
    SHOWLOG     =>  $SHOWLOG,
    PRINTLOG    =>  $PRINTLOG
});

$object->testCreateTaskDirs();

