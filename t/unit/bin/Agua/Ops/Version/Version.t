#!/usr/bin/perl -w

#### TEST MODULES
use Test::More  tests => 35; #qw(no_plan);

#### EXTERNAL MODULES
use FindBin qw($Bin);
#use lib "$Bin/../../../../../lib";
BEGIN
{
    my $installdir = $ENV{'installdir'} || "/agua";
    unshift(@INC, "$installdir/lib");
    unshift(@INC, "$installdir/lib/external/lib/perl5");
    unshift(@INC, "$installdir/t/unit/lib");
    unshift(@INC, "$installdir/t/common/lib");
}

#### CREATE OUTPUTS DIR
my $outputsdir = "$Bin/outputs";
`mkdir -p $outputsdir` if not -d $outputsdir;

use Getopt::Long;

#### INTERNAL MODULES
use Test::Agua::Ops::Version;

#### SET LOG
my $showlog     =   0;
my $printlog    =   4;
my $logfile = "$Bin/outputs/version.log";

#### GET OPTIONS
my $login;
my $token;
my $keyfile;
my $help;
GetOptions (
    'showlog=i'     => \$showlog,
    'printlog=i'    => \$printlog,
    'help'          => \$help
) or die "No options specified. Try '--help'\n";
usage() if defined $help;

my $object = new Test::Agua::Ops::Version(
    showlog     =>  $showlog,
    printlog    =>  $printlog,
    logfile     =>  $logfile
);

$object->testHigherSemVer();
$object->testVersionSort();
$object->testParseSemVer();
$object->testSameHigherVersion();


sub usage {
    print qq{
        
OPTIONS:

--showlog     Integer from 1 (least) to 5 (most) to display log information
--printlog    Integer from 1 (least) to 5 (most) to print log info to file

    };
}