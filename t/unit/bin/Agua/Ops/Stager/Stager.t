#!/usr/bin/perl -w

#### TEST MODULES
use Test::More  tests => 1; #qw(no_plan);

#### EXTERNAL MODULES
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

use Getopt::Long;

#### INTERNAL MODULES
use Test::Agua::Ops::Stager;

#### SET LOG
my $SHOWLOG     =   0;
my $PRINTLOG    =   4;
my $logfile = "$Bin/outputs/version.log";

#### GET OPTIONS
my $login;
my $token;
my $keyfile;
my $help;
GetOptions (
    'SHOWLOG=i'     => \$SHOWLOG,
    'PRINTLOG=i'    => \$PRINTLOG,
    'help'          => \$help
) or die "No options specified. Try '--help'\n";
usage() if defined $help;

my $object = new Test::Agua::Ops::Stager(
    SHOWLOG     =>  $SHOWLOG,
    PRINTLOG    =>  $PRINTLOG,
    logfile     =>  $logfile
);
isa_ok($object, "Test::Agua::Ops::Stager");

exit;

##### SET UP REPO
#$object->setUp();

##### TEST RUN STAGER
#$object->testRunStager();


$object->cleanUp();

sub usage {
    print qq{
        
OPTIONS:

--SHOWLOG     Integer from 1 (least) to 5 (most) to display log information
--PRINTLOG    Integer from 1 (least) to 5 (most) to print log info to file

    };
}