#!/usr/bin/perl -w

#### DEBUG
my $DEBUG = 0;
#$DEBUG = 1;

=head2

APPLICATION		Json.t

PURPOSE

	TEST PACKAGE Conf::Json

        1. READ JSON ARRAY-FORMAT CONFIGURATION FILES (PRETTY FORMAT)

		2. ADD/EDIT/REMOVE ENTRIES
		
		3. WRITE TO OUTFILE PRESERVING ORDER OF KEYS

USAGE		./Configure.t [Int --SHOWLOG] [Int --PRINTLOG] [--help]

		--SHOWLOG		Displayed log level (1-5)	
		--PRINTLOG		Logfile log level (1-5)	
		--help			Show this message

=cut

use Test::More	tests => 18;
use Getopt::Long;
use FindBin qw($Bin);
use lib "$Bin/../../../lib";
BEGIN
{
    my $installdir = $ENV{'installdir'} || "/agua";
    unshift(@INC, "$installdir/lib");
}

#### SET CONF FILE
my $installdir  =   $ENV{'installdir'} || "/agua";
my $configfile  =   "$installdir/conf/config.yaml";

#### SET $Bin
$Bin =~ s/^.+t\/bin/$installdir\/t\/bin/;

BEGIN {
    use_ok('Conf::Json');
}
require_ok('Conf::Json');

#### INTERNAL MODULES
use Test::Conf::Json;

#### MIXIN TO USE LOGGER
use Moose::Util qw( apply_all_roles );

#### GET OPTIONS
my $SHOWLOG     =   2;
my $PRINTLOG    =   5;
my $help;
GetOptions (
    'SHOWLOG=i'     => \$SHOWLOG,
    'PRINTLOG=i'    => \$PRINTLOG,
    'help'          => \$help
) or die "No options specified. Try '--help'\n";
usage() if defined $help;

my $inputfile = "$Bin/inputs/trackData.json";
my $outputfile = "$Bin/outputs/trackData.json";
my $logfile = "$Bin/outputs/aguatest.json.log";

my $object = Test::Conf::Json->new({
    logfile		=> $logfile,
	inputfile	=>	$inputfile,
	backup		=>	0,
	SHOWLOG 	=> 	$SHOWLOG,
	PRINTLOG	=>	$PRINTLOG
});

#### READ, WRITE, SECTION ORDER AND CONTENTS
$object->testRead($object, $inputfile);
$object->testWrite($object, $inputfile, $outputfile);
$object->testGetSectionOrder($object, $inputfile);
$object->testGetKey($object);
$object->testInsertKey($object);

#### COMPARISON AND RESTORE STATE
my $originalfile = "$Bin/inputs/data/tracks/chr1/hinv70PseudoGene/trackData-original.json";
my $insertedfile = "$Bin/inputs/data/tracks/chr1/hinv70PseudoGene/trackData-inserted.json";
my $prettyfile = "$Bin/inputs/data/tracks/chr1/hinv70PseudoGene/trackData-pretty.json";
my $unprettyfile = "$Bin/inputs/data/tracks/chr1/hinv70PseudoGene/trackData-unpretty.json";

#### SET APPLICATION AND ITS INPUT/OUTPUT FILES
my $application = "$installdir/bin/jbrowse/trackData.pl";
$inputfile = "$Bin/outputs/data/tracks/chr1/hinv70PseudoGene/trackData.json";
my $multifile = "$Bin/outputs/data/tracks/*/hinv70PseudoGene/trackData.json";
my $key = "urlTemplate";
my $value = "http://www.h-invitational.jp/evola_main/locus_maps.cgi?hit={name}";
$logfile = "$Bin/outputs/data/tracks/chr1/hinv70PseudoGene/trackdata.log";

ok(-f $application, "found application");

#### COPY DIRS
my $sourcedir = "$Bin/inputs/data/tracks/chr1/hinv70PseudoGene";
my $targetdir = "$Bin/outputs/data/tracks/chr1/hinv70PseudoGene";
`mkdir -p $targetdir` if not -d $targetdir;
`cp $sourcedir/* $targetdir`;

$object->testPretty($originalfile, $inputfile, $application, $prettyfile);
$object->testUnpretty($originalfile, $inputfile, $application, $prettyfile, $unprettyfile);
$object->testInsert($originalfile, $inputfile, $prettyfile, $insertedfile, $logfile, $application, $key, $value);

$object->testMultiInsert($originalfile, $multifile, $inputfile, $prettyfile, $insertedfile, $logfile, $application, $key, $value);

#### CLEAN UP
`rm -fr $Bin/outputs/*`;

#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#                                    SUBROUTINES
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

sub usage {
    print `perldoc $0`;
}
