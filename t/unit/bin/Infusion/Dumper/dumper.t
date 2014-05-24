#!/usr/bin/perl -w

=head2

APPLICATION     dumper.t

PURPOSE         TEST Illumina::WGS::Util::Dumper

=cut

#### USE LIBS
use FindBin qw($Bin);
use lib "$Bin/../../../../../lib";

#### EXTERNAL MODULES
use Getopt::Long;
use Test::More  tests => 36;

#### INTERNAL MODULES
use Test::Illumina::WGS::Util::Dumper;

#### SET LOG
my $log     =   2;
my $printlog    =   5;
my $logfile     =   "$Bin/outputs/sync.log";

#### GET OPTIONS
my $help;
GetOptions (
    'log=i'         => \$log,
    'printlog=i'        => \$printlog,
    'help'              => \$help
) or die "No options specified. Try '--help'\n";
usage() if defined $help;

my $object = Test::Illumina::WGS::Util::Dumper->new({
    log			=>	$log,
    printlog        => $printlog,
    logfile         => $logfile
});

$object->testRemoveQuotes();
$object->testCleanQuotes();
$object->testInsertToTsv();
$object->testGetLineElements();
$object->testParseBlock();
$object->testDumpToSql();

sub usage { `perldoc $0`;   }

