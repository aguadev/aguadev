#!/usr/bin/perl -w

#### DEBUG
my $DEBUG = 0;
#$DEBUG = 1;

#### TIME
my $time = time();

=head2

	APPLICATION     trackInfo
	    
    PURPOSE

		1. GET/INSERT/REMOVE ENTRIES IN trackInfo.js
  
		E.G., EDIT trackInfo.js BY ADDING 'plugins/view/jbrowse/' TO URL ENTRIES:
		
		trackInfo.pl \
		--path "plugins/view/jbrowse/" \
		--inputfile /data/jbrowse/human/hg19/chr1/data/trackInfo.js
		
		
		TO CHANGE THIS
		
			  "url" : "data/seq/{refseq}/",
		
		TO THIS
		
			  "url" : "plugins/view/jbrowse/data/seq/{refseq}/",
		
		WITH THIS FILE FORMAT
		
		trackInfo = 
		[
		   {
			  "url" : "data/seq/{refseq}/",
			  "args" : {
				 "chunkSize" : 20000
			  },
			  "label" : "DNA",
			  "type" : "SequenceTrack",
			  "key" : "DNA"
		   },
		
		 
		SO THAT LOADED URLS WILL CHANGE FROM
		
		http://localhost/agua/0.4/data/tracks/chr1/exon/trackData.json
		
		TO
		
		http://localhost/agua/0.4/plugins/view/jbrowse/data/tracks/chr1/exon/trackData.json
            
    INPUT
    
		1. ADDITIONAL FILE PATH

        2. INPUT trackInfo.js FILE
		
    OUTPUT
        
        1. EDITED trackInfo.js FILE
        
    USAGE
    
    ./trackInfo.pl  <--inputfile String> <--path String> [--help]
    
        --inputfile	        :   Name or full path to inputfile directory
        --path	       		:   Name or full path to path directory
        --help              :   print help info

    EXAMPLES

cd /nethome/syoung/base/pipeline/jbrowse1/ucsc/chr1

/data/agua/0.6/bin/apps/trackInfo.pl \
--mode insert \
--inputfile /nethome/syoung/base/pipeline/jbrowse1/ucsc/chr1/data/trackInfo.js \
--path "plugins/view/jbrowse"

=cut


use strict;

#### USE LIBRARY
use FindBin qw($Bin);
use lib "$Bin/../../lib";

#### FLUSH BUFFER
$| = 1;

#### INTERNAL MODULES
use Timer;
use Conf::JsonArray;

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
my $assign;
my $key;
my $value;
my $targetkey;
my $targetvalue;
my $index;
my $backup;
my $help;
if ( not GetOptions (
    'inputfile=s' 	=> \$inputfile,
    'logfile=s' 	=> \$logfile,
    'assign=s' 		=> \$assign,
    'mode=s' 		=> \$mode,
    'key=s' 		=> \$key,
    'value=s' 		=> \$value,
    'targetkey=s' 	=> \$targetkey,
    'targetvalue=s' => \$targetvalue,
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
my $object = Conf::JsonArray->new({
	inputfile	=>	$inputfile,
	backup		=>	$backup,
	assign		=>	$assign
});

#### START LOGGING IF SPECIFIED
apply_all_roles( $object, 'Agua::Common::Logger' );
$object->LOG(3) if defined $logfile;
$object->startLog($logfile) if defined $logfile;

#### IF PRESENT, EXPAND '*' WILDCARD TO GET ALL FILES
my $files = [];
if ( $inputfile =~ /^(.+)\/\*\/(.*)$/ )
{
	my $inputdir = $1;
	my $rest = $2;
	$object->logger("inputdir: $inputdir");
	$object->logger("rest: $rest");
	my $path = "$inputdir///$rest";
	$object->logger("path: $path");	
	my $search = File::Wildcard->new( path => $path);
	@$files = $search->all;
}
#### OTHERWISE, DO A SINGLE FILE
else {
	push @$files, $inputfile;
}

foreach my $file ( @$files ) {
	$object->logger("file: $file");
	$object->inputfile($file);
	
	#### RUN COMMAND
	$object->removeKey($key, $value) if $mode eq "remove";
	$object->insertKey($key, $value, $targetkey, $targetvalue) if $mode eq "insert";	
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

