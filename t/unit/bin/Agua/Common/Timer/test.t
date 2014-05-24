#!/usr/bin/perl -w

use Test::More  tests => 29;
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

#### SET LOG
my $log     =   4;
my $printlog    =   4;
my $logfile = "$Bin/outputs/version.log";

#### GET OPTIONS
my $login;
my $token;
my $keyfile;
my $help;
GetOptions (
    'log=i'     => \$log,
    'printlog=i'    => \$printlog,
    'help'          => \$help
) or die "No options specified. Try '--help'\n";
usage() if defined $help;


BEGIN {
    use_ok('Test::Agua::Common::Timer');
}
require_ok('Test::Agua::Common::Timer');

my $object = Test::Agua::Common::Timer->new(
    log			=>	$log,
    printlog    =>  $printlog
);
isa_ok($object, "Test::Agua::Common::Timer");

$object->testDatetimeToMysql();

#### CLEAN UP
`rm -fr $Bin/outputs/*`;

