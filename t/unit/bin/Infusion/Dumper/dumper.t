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
my $SHOWLOG     =   2;
my $PRINTLOG    =   5;
my $logfile     =   "$Bin/outputs/sync.log";

#### GET OPTIONS
my $help;
GetOptions (
    'SHOWLOG=i'         => \$SHOWLOG,
    'PRINTLOG=i'        => \$PRINTLOG,
    'help'              => \$help
) or die "No options specified. Try '--help'\n";
usage() if defined $help;

my $object = Test::Illumina::WGS::Util::Dumper->new({
    SHOWLOG         => $SHOWLOG,
    PRINTLOG        => $PRINTLOG,
    logfile         => $logfile
});

$object->testRemoveQuotes();
$object->testCleanQuotes();
$object->testInsertToTsv();
$object->testGetLineElements();
$object->testParseBlock();
$object->testDumpToSql();

sub usage { `perldoc $0`;   }

