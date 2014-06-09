#!/usr/bin/perl -w

#### DEBUG
my $DEBUG = 0;
#$DEBUG = 1;

#### TIME
my $time = time();

=head2

APPLICATION     trackData
	
PURPOSE

	1. 'PRETTIFY' A trackData.json FILE
	
	2. GET/INSERT/REMOVE ENTRIES IN PRETTIFIED trackData.json
	
	3. OPTIONALLY SPECIFY POSITION OF NEW ENTRIES IN FILE

INPUT

	1. KEY NAME
	
	2. KEY VALUE

	3. POSITION OF INSERTED VALUE

	4. INPUTFILE LOCATION WITH OR WITHOUT WILDCARD '*'
	
	
OUTPUT
	
	1. EDITED FILE
	

NOTES

	FOR EXAMPLE, GIVEN THIS FILE FORMAT:
	
		trackData = 
		[
		   {
			  "url" : "plugins/view/jbrowse/data/seq/{refseq}/",
			  "args" : {
				 "chunkSize" : 20000
			  },
			  "label" : "DNA",
			  "type" : "SequenceTrack",
			  "key" : "DNA"
		   },

	THIS APPLICATION CAN BE USED TO CHANGE THIS:

		  "url" : "data/seq/{refseq}/",
	
	TO THIS:
	
		  "url" : "plugins/view/jbrowse/data/seq/{refseq}/",
	

	I.E., THIS WILL CHANGE THE LOADING URLS FOR THE FEATURE FILES
	
	FROM
	
	http://localhost/agua/0.4/data/tracks/chr1/exon/...
	
	TO
	
	http://localhost/agua/0.4/plugins/view/jbrowse/data/tracks/chr1/exon/...
	

USAGE

./trackData.pl  <--mode String> <--inputfile String> <--key String> [--value String] [--help]

	--mode	       		:   Either 'insert' or 'remove'
	--inputfile	        :   Inputfile location, substitute '*' for directory as a wildcard
	--key	       		:   Name of key to insert/remove
	--value	       		:   Value of key to insert
	--position			:	Position in file to insert key (0, 1, 2, ...)
	--help              :   print help info


EXAMPLES

PRETTIFY ALL trackData.json FILES FOR ALL EXPERIMENTS AND ALL CHROMOSOMES:

sudo /agua/0.6/bin/jbrowse/trackData.pl \
--inputfile "/data/jbrowse/species/human/hg19/demo/*/data/tracks/chr22/*/trackData.json" \
--mode pretty

SET lazyfeatureUrlTemplate KEY FOR ALL chr22 trackData.json FILE:

sudo /agua/0.6/bin/jbrowse/trackData.pl \
--inputfile /data/jbrowse/species/human/hg19/demo/test1/data/tracks/chr22/test1/trackData.json \
--mode insert \
--key "lazyfeatureUrlTemplate" \
--value "data/tracks/chr22/test1/lazyfeatures-{chunk}.json"    



=cut


use strict;

#### USE LIBRARY
use FindBin qw($Bin);
use lib "$Bin/../../lib";

#### FLUSH BUFFER
$| = 1;

#### INTERNAL MODULES
use Timer;
use Conf::Json;

#### SAVE ARGUMENTS
my @args = @ARGV;

#### EXTERNAL MODULES
use File::Wildcard;
use Term::ANSIColor qw(:constants);
use Getopt::Long;
use Data::Dumper;

#### GET OPTIONS
my $inputfile;
my $logfile;
my $mode;
my $key;
my $value;
my $index;
my $backup;
my $help;
if ( not GetOptions (
    'inputfile=s' 	=> \$inputfile,
    'logfile=s' 	=> \$logfile,
    'mode=s' 		=> \$mode,
    'key=s' 		=> \$key,
    'value=s' 		=> \$value,
    'index=i' 		=> \$index,
    'backup' 		=> \$backup,
    'help' 			=> \$help
) )
{	usage(); exit;	};

#### PRINT HELP
if ( defined $help )	{	usage();	}

#### CHECK INPUTS
die "mode not defined (use --help option for usage)\n" if not defined $mode;
die "mode not supported (use --help option for usage)\n" if not $mode =~ /(insert|remove|pretty|unpretty)/;
die "inputfile not defined (use --help option for usage)\n" if not defined $inputfile;
die "value not defined (use --help option for usage)\n" if $mode eq "insert" and not defined $value;

#### DEFAULTS
$backup = 0 if not defined $backup;

#### MIXIN TO USE LOGGER
use Moose::Util qw( apply_all_roles );
my $object = Conf::Json->new({
	inputfile	=>	$inputfile,
	backup		=>	$backup,
	logfile		=>	$logfile
});

#### IF PRESENT, EXPAND '*' WILDCARD TO GET ALL FILES
my $files = [];
if ( $inputfile =~ /^(.+)\/\*\/(.*)$/ )
{
	my $inputdir = $1;
	my $rest = $2;
	print "inputdir: $inputdir\n";
	print "rest: $rest\n";
	my $path = "$inputdir/*/$rest";
	print "path: $path\n";	
	my $search = File::Wildcard->new( path => $path, follow => 1 );
	@$files = $search->all;
	print "files: @$files\n";
}
#### OTHERWISE, DO A SINGLE FILE
else {
	push @$files, $inputfile;
}

foreach my $file ( @$files ) {
	print "file: $file\n";
	$object->inputfile($file);
	
	#### RUN COMMAND
	$object->removeKey($key) if $mode eq "remove";
	$object->insertKey($key, $value, $index) if $mode eq "insert";	
	$object->pretty($file) if $mode eq "pretty";
	$object->unpretty($file) if $mode eq "unpretty";
}

#### PRINT RUN TIME
my $runtime = Timer::runtime( $time, time() );
print "\nRun time: $runtime\n";
print "Completed $0\n";
print Timer::datetime(), "\n";
print "****************************************\n\n\n";
exit;

#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#									SUBROUTINES
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

sub usage
{
	print `perldoc $0`;
    exit;
}

