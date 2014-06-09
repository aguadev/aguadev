#!/usr/bin/perl -w

#### DEBUG
my $DEBUG = 0;
#$DEBUG = 1;

#### TIME
my $time = time();

=head2

	APPLICATION     run-flatfile-to-json
	    
    PURPOSE
  
        	WRAPPER TO RUN flatfile-to-json.pl ON ONE GFF FILE
			
			AT A TIME TO SAVE ON MEMORY USAGE.
			
			(I.E., USEFUL WHEN USING THE db_adaptor='memory'
			
			OPTION IN THE .json CONFIG FILE.)
            
    INPUT
    
		1. INPUT DIRECTORY CONTAINING GFF FILES

        2. PARENT DIRECTORY OF 'data' DIRECTORY (DESTINATION FOR OUTPUT FILES)
		
		3. JBROWSE .json CONFIGURATION FILE 

		4. 'flatfile-to-json.pl' EXECUTABLE
		
		
    OUTPUT
        
        1. PROCESSED FILES FOUND IN DIRECTORY agua/data/seq AND agua/data/tracks
        
    USAGE
    
    ./run-flatfile-to-json.pl
		<--executable String>
		<--inputdir String>
		<--outputdir String>
		<--jsonfile String>
		[--help]
    
        --executable	       	:   Location of 'flatfile-to-json.pl' executable 
        --inputdir	           	:   Full path to input directory
        --outputdir	           	:   The 'data' directory will be created in this directory
        --jsonfile	       		:   Full path to .json configuration file 
        --help                 	:   Print this help info

    EXAMPLES

/data/agua/0.4/bin/apps/run-flatfile-to-json.pl \
--executable /var/www/html/jbrowse/bin/flatfile-to-json.pl \
--inputdir /nethome/syoung/base/pipeline/jbrowse1/ucsc/gff \
--outputdir /nethome/syoung/base/pipeline/jbrowse1/ucsc/chr1 \
--jsonfile /nethome/syoung/base/pipeline/jbrowse1/ucsc/ucsc-gff.json


=cut

use strict;

#### USE LIBRARY
use FindBin qw($Bin);
use lib "$Bin/../../lib";

#### FLUSH BUFFER
$| = 1;

#### INTERNAL MODULES
use Timer;
use Util;
use Conf::Yaml;


#### SAVE ARGUMENTS
my @args = @ARGV;

#### EXTERNAL MODULES
use File::Copy;
use File::Remove;
use File::Path;
use JSON;
use Term::ANSIColor qw(:constants);
use Getopt::Long;
use Data::Dumper;

#### GET OPTIONS
my $inputdir;
my $jsonfile;
my $executable;
my $outputdir;
my $help;
if ( not GetOptions (
    'inputdir=s' => \$inputdir,
    'jsonfile=s' => \$jsonfile,
    'executable=s' => \$executable,
    'outputdir=s' => \$outputdir,
	'help' => \$help
) )
{	usage(); exit;	};

#### PRINT HELP
if ( defined $help )	{	usage();	}

#### CHECK INPUTS
die "jsonfile not defined (use --help option for usage)\n" if not defined $jsonfile;
die "inputdir not defined (use --help option for usage)\n" if not defined $inputdir;
die "executable not defined (use --help option for usage)\n" if not defined $executable;
die "outputdir not defined (use --help option for usage)\n" if not defined $outputdir;

#### CHDIR TO EXECUTABLE DIRECTORY
my ($libdir) = $executable =~ /^(.+)\/[^\/]+$/;
#print "Using lib $libdir/../lib\n";

#### GET RID OF ANNOYING ERROR:
#### Use of uninitialized value in concatenation (.) or string
no warnings;
use lib "$libdir/../lib";
use warnings;

#### PRINT HOST NAME (FOR RUNNING ON CLUSTER)
print "hostname:\n";
print `hostname`;
print "\n";

#### INITIALISE JSON PARSER
my $jsonParser = JSON->new();

#### GET .json FILE HASH
open(ARGS, $jsonfile) or die "Can't open args file: $jsonfile\n";
$/ = undef;
my $contents = <ARGS>;
close(ARGS);
die "Json file is empty\n" if $contents =~ /^\s*$/;
my $json = $jsonParser->decode($contents);

#### GET FILES
opendir(DIR, $inputdir) or die "Can't open directory: $inputdir\n";
my @inputfiles = readdir(DIR);
closedir(DIR);
print "inputfiles: @inputfiles\n" if $DEBUG;

#### SET TEMP DIR
my $tempdir = "$outputdir/runbiodb";
if ( not -d $tempdir )
{
	my $mkpath_result = File::Path::mkpath($tempdir);
	print "mkpath_result: $mkpath_result\n";
	die "Can't create temp dir: $tempdir\n" if not $mkpath_result;
}

#### DO ALL FILES SPECIFIED IN FEATURES HASH
my $file_counter = 0;
foreach my $inputfile ( @inputfiles )
{
	next if not $inputfile =~ /\.gff/;
	$file_counter++;
	print "Doing file $file_counter: $inputfile\n";

	#### SET FEATURE HASH
	my $featurehash = featurehash($json, $inputfile);
	next unless defined $featurehash;

	my $tracklabel = $featurehash->{track};
	my $key = $featurehash->{key};

	

	#### CHANGE TO OUTPUT DIRECTORY:
	####
	#### 1. IT MUST CONTAIN A 'data' FOLDER INSIDE IT
	#### 	(UNLESS YOU SPECIFY A DIFFERENT DIRECTORY WITH
	#### 	THE '--out' option)
	####
	#### 2. THE 'data' FOLDER MUST CONTAIN A refSeqs.js FILE
	####
	chdir($outputdir) or die "Can't change to output dir: $outputdir\n";
	
	#### CONVERT TO GFF
	my $command = "$executable --gff $inputdir/$inputfile --tracklabel $tracklabel --key $key";
	print "command: $command\n";
	print `$command`;	
}

#### PRINT RUN TIME
my $runtime = Timer::runtime( $time, time() );
print "\nRun time: $runtime\n";
print "Completed $0\n";
print Util::datetime(), "\n";
print "****************************************\n\n\n";
exit;

#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#									SUBROUTINES
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::



sub featurehash
{
	my $json	=	shift;
	my $inputfile	=	shift;
	
	my $featurehash;
	my @inputtypes = keys %{$json->{features}};
	@inputtypes = sort @inputtypes;
	foreach my $inputtype ( @inputtypes )
	{
		#print "inputtype: $inputtype\n";
		
		#use re 'eval';# EVALUATE $pattern AS REGULAR EXPRESSION
		if ( $inputfile =~ /$inputtype/ )
		{
			$featurehash = $json->{features}->{$inputtype};
			last;
		}
		#no re 'eval';# EVALUATE $pattern AS REGULAR EXPRESSION
	}

	return $featurehash;
}



sub usage
{
	print `perldoc $0`;
    exit;
}

