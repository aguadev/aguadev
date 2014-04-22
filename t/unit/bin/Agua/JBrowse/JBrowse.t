#!/usr/bin/perl -w

=head2

APPLICATION		JBrowse.t

PURPOSE

	TEST bin/jbrowse APPLICATIONS
	
	E.G., bin/jbrowse/trackData.pl

        1. REMOVE outputs DIRECTORY
		
		2. COPY inputs DIRECTORY TO outputs DIRECTORY

		3. RUN trackData.pl
		
		4. CONFIRM DIFFERENCES BETWEEN FILES IN inputs AND outputs
		
USAGE		./Configure.t [Int --showlog] [Int --printlog] [--help]

		--showlog		Displayed log level (1-5)	
		--printlog		Logfile log level (1-5)	
		--help			Show this message

=cut

use strict;

use Test::More	tests => 5;
use Test::Files;
use Getopt::Long;

use FindBin qw($Bin);
use lib "$Bin/../../../lib";
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
use Test::Agua::JBrowse;

#### GET OPTIONS
my $showlog     =   2;
my $printlog    =   5;
my $help;
GetOptions (
    'showlog=i'     => \$showlog,
    'printlog=i'    => \$printlog,
    'help'          => \$help
) or die "No options specified. Try '--help'\n";
usage() if defined $help;

my $object = Test::Agua::JBrowse->new({
	showlog		=> 	$showlog,
	printlog	=>	$printlog
});

#### COMPARISON AND RESTORE STATE
my $originalfile = "$Bin/inputs/data/tracks/chr1/hinv70PseudoGene/trackData-original.json";
my $insertedfile = "$Bin/inputs/data/tracks/chr1/hinv70PseudoGene/trackData-inserted.json";
my $prettyfile = "$Bin/inputs/data/tracks/chr1/hinv70PseudoGene/trackData-pretty.json";
my $unprettyfile = "$Bin/inputs/data/tracks/chr1/hinv70PseudoGene/trackData-unpretty.json";

#### APPLICATION
my $application = "$installdir/bin/jbrowse/trackData.pl";
my $inputfile = "$Bin/outputs/data/tracks/chr1/hinv70PseudoGene/trackData.json";
my $multifile = "$Bin/outputs/data/tracks/*/hinv70PseudoGene/trackData.json";
my $key = "urlTemplate";
my $value = "http://www.h-invitational.jp/evola_main/locus_maps.cgi?hit={name}";
my $logfile = "$Bin/outputs/data/tracks/chr1/hinv70PseudoGene/trackdata.log";

ok(-f $application, "found application: $application");

#### CREATE OUTPUT DIR
`mkdir -p $Bin/outputs/data/tracks/chr1/hinv70PseudoGene`;

#### TEST PRETTY
$object->testPretty($originalfile, $inputfile, $application, $prettyfile);

#### TEST UNPRETTY
$object->testUnpretty($originalfile, $inputfile, $application, $prettyfile, $unprettyfile);

#### TEST INSERT
$object->testInsert($originalfile, $inputfile, $application, $prettyfile, $insertedfile, $logfile,  $key, $value);

#### TEST MULTI-INSERT
$object->testMultiInsert($originalfile, $inputfile, $application, $prettyfile, $multifile, $insertedfile, $logfile, $key, $value);

#### CLEAN UP
`rm -fr $Bin/outputs/*`;

exit(0);

#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#                                    SUBROUTINES
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

sub usage {
    print `perldoc $0`;
}


#sub testPretty {
#	my $originalfile=	shift;
#	my $inputfile	=	shift;
#	my $application	=	shift;
#	my $prettyfile	=	shift;
#
#	#### SET UP
#	setupFile($originalfile, $inputfile);
#
#	my $command = qq{$application \\
#--inputfile "$inputfile" \\
#--mode pretty};
#	#print "command: $command\n";
#	`$command`;
#
#	#compare_ok($inputfile, $prettyfile, "input and pretty file comparison");
#	my $diff = `diff -wB $inputfile $prettyfile`;
#	is($diff, '', "testPretty: input and pretty files are identical");
#
#	#### CLEAN UP
#	setupFile($originalfile, $inputfile);
#}
#
#sub testUnpretty {
#	my $originalfile=	shift;
#	my $inputfile	=	shift;
#	my $application	=	shift;
#	my $prettyfile	=	shift;
#	my $unprettyfile=	shift;
#
#	#### SET UP: COPY PRETTY TO INPUT
#	setupFile($prettyfile, $inputfile);
#
#	my $command = qq{$application \\
#--inputfile "$inputfile" \\
#--mode unpretty};
#	#print "command: $command\n";
#	`$command`;
#	
#	my $diff = `diff -wB $inputfile $unprettyfile`;
#	is($diff, '', "testUnpretty: input and unpretty files are identical");
#
#	#### CLEAN UP
#	setupFile($originalfile, $inputfile);
#}
#
#sub testInsert {
#	my $originalfile	=	shift;
#	my $inputfile		=	shift;
#	my $prettyfile		=	shift;
#	my $insertedfile	=	shift;
#	my $logfile			=	shift;
#	my $application		=	shift;
#	my $key				=	shift;
#	my $value			=	shift;
#	
#	#### SET UP: COPY PRETTY TO INPUT
#	setupFile($prettyfile, $inputfile);
#	
#	my $command = qq{$application \\
#--inputfile "$inputfile" \\
#--mode insert \\
#--key $key \\
#--value "$value"
#};	
#	#print "command: $command\n";
#	`$command`;
#
#	my $diff = `diff -wB $inputfile $insertedfile`;
#	is($diff, '', "testInsert: input and inserted files are identical");
#
#	#### CLEAN UP
#	setupFile($originalfile, $inputfile);
#}
#
#sub testMultiInsert {
#	my $originalfile	=	shift;
#	my $multifile		=	shift;
#	my $inputfile		=	shift;
#	my $prettyfile		=	shift;
#	my $insertedfile	=	shift;
#	my $logfile			=	shift;
#	my $application		=	shift;
#	my $key				=	shift;
#	my $value			=	shift;
#
#	#### SET UP
#	setupDirs();
#	my $command = qq{$application \\
#--inputfile "$multifile" \\
#--mode pretty
#};	
#	`$command`;
#
#	$command = qq{$application \\
#--inputfile "$multifile" \\
#--mode insert \\
#--key $key \\
#--value "$value"
#};	
#	#print "command: $command\n";
#	`$command`;
#
#	my $diff = `diff -wB $inputfile $insertedfile`;
#	is($diff, '', "testMultiInsert: input and inserted files are identical");
#
#return;
#
#
#
#	#### CLEAN UP
#	setupDirs();
#}
#
#
#sub setupDirs {
#	#### CLEAN UP
#	`rm -fr $Bin/outputs`;
#	`cp -r $Bin/inputs $Bin/outputs`;
#	`cd $Bin/outputs; find ./ -type d -exec chmod 0755 {} \\;; find ./ -type f -exec chmod 0644 {} \\;;`;
#}
#
#sub setupFile {
#	my $sourcefile	=	shift;
#	my $targetfile	=	shift;	
#	`cp $sourcefile $targetfile`;
#	`chmod 644 $targetfile`;	
#}
#
