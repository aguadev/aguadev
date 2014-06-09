#!/usr/bin/perl -w

#### DEBUG
my $DEBUG = 0;
#$DEBUG = 1;

#### TIME
my $time = time();

=head2

	APPLICATION     run-biodb-to-json
	    
    PURPOSE
  
        	WRAPPER TO RUN biodb-to-json.pl ON ONE GFF FILE
			
			AT A TIME TO SAVE ON MEMORY USAGE.
			
			(I.E., USEFUL WHEN USING THE db_adaptor='memory'
			
			OPTION IN THE .json CONFIG FILE.)
            
    INPUT
    
		1. INPUT DIRECTORY CONTAINING GFF FILES

        2. PARENT DIRECTORY OF 'data' DIRECTORY (DESTINATION FOR OUTPUT FILES)
		
		3. JBROWSE .json CONFIGURATION FILE 

		4. 'biodb-to-json.pl' EXECUTABLE
		
		
    OUTPUT
        
        1. PROCESSED FILES FOUND IN DIRECTORY agua/data/seq AND agua/data/tracks
        
    USAGE
    
    ./run-biodb-to-json.pl
		<--executable String>
		<--inputdir String>
		<--outputdir String>
		<--jsonfile String>
		[--help]
    
        --executable	       	:   Location of 'biodb-to-json.pl' executable 
        --inputdir	           	:   Full path to input directory
        --outputdir	           	:   The 'data' directory will be created in this directory
        --jsonfile	       		:   Full path to .json configuration file 
        --help                 	:   Print this help info

    EXAMPLES

/data/agua/0.4/bin/apps/run-biodb-to-json.pl \
--executable /var/www/html/jbrowse/bin/biodb-to-json.pl \
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
print "Using lib $libdir/../lib\n";

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
	my $featurehash = $json->{features}->{$inputdir};

	#### SET TEMP DIRECTORY
	my $random_number = sprintf "%06d", rand(100000);	
	my $rundir = "$tempdir/$random_number";
	while ( -d $rundir )
	{
		$rundir = "$tempdir/$random_number";
	}
	my $mkpath_result = File::Path::mkpath($rundir);
	print "mkpath_result: $mkpath_result\n";
	die "Can't create temp dir: $rundir\n" if not $mkpath_result;

	#### SET TEMP CONFIG FILE
	my $temp_jsonfile = "$rundir/temp.json";
	print "temp_jsonfile: $temp_jsonfile\n";
	$json->{db_args}->{-dir} = $rundir;
		
	#### CREATE tracks ARRAY IN JSON
	$json->{tracks} = [];
	foreach my $feature ( keys %{$json->{features}} )
	{
		push @{$json->{tracks}}, $json->{features}->{$feature};
	}

	#### PRINT CONFIG FILE
	open(JSONFILE, ">$temp_jsonfile") or die "Can't open json file: $temp_jsonfile\n";
	my $text = $jsonParser->pretty->encode($json);
	#my $text = sprintf Dumper $json;
	print "text: $text\n" if $DEBUG;
	print JSONFILE $text;
	close(JSONFILE);
	print "temp jsonfile printed: $temp_jsonfile\n" if $DEBUG;
	
	
	#### SET TEMP INPUT FILE
	my $temp_inputfile = "$rundir/$inputfile";
	print "temp_inputfile: $temp_inputfile\n";

	#### COPY INPUT FILE TO TEMP DIR
	File::Copy::copy("$inputdir/$inputfile", $temp_inputfile) or die "Can't copy input file $inputdir/$inputfile to temp file: $temp_inputfile\n";


	#### CHANGE TO OUTPUT DIRECTORY 
	#### NB: IT MUST CONTAIN A 'data' FOLDER INSIDE IT
	#### UNLESS YOU SPECIFY A DIFFERENT DIRECTOR WITH
	#### THE '--out' option __AND__ THE 'data' FOLDER
	#### MUST CONTAIN A refSeqs.js FILE

	chdir($outputdir) or die "Can't change to output dir: $outputdir\n";
	
	#### CONVERT TO GFF
	my $command = "$executable --conf $temp_jsonfile --out $outputdir";
	print "command: $command\n";
	print `$command`;
	
last;

	
	#### CLEAN UP
	print "Cleanup - removing temp dir: $rundir\n";
	File::Remove::rm(\1, $rundir);
	
	
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




sub usage
{
	print `perldoc $0`;
    exit;
}

