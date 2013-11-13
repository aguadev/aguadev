#!/usr/bin/perl -w

#### DEBUG
my $DEBUG = 0;
#$DEBUG = 1;

#### TIME
my $time = time();
my $duration = 0;
my $current_time = $time;

=head2

APPLICATION     jbrowseView
	
PURPOSE

	1. INCORPORATE JBROWSE FEATURES AS DYNAMIC TRACKS INTO A
	
		WHOLE-GENOME VIEW WITH DEFAULT STATIC TRACKS
		
	2. COPY SELECTED data DIRECTORY FROM THE USER'S JBROWSE
	
		FEATURE DIRECTORY:
		
			username/project/workflow/view/species/data
	
		THE WEB ROOT DIRECTORY FOR THIS VIEW:
		
			jbrowse/username/project/workflow/viewname/data 
	
	3. ADD FEATURES TO tracksInfo.js FILE
	
INPUT

	1. data FOLDER LOCATIONS OF JBROWSE FEATURES
	
	2. LOCATION OF 
	
	3. LOCATES pileup FILES USING THE STANDARD DIRECTORY ARCHITECTURE
	
		LAID OUT IN PARENT Cluster.pm
	
NOTES
		
	INHERITS Cluster.pm IN ORDER TO:
	
		1. ACCESS THE DIRECTORY ARCHITECTURE INFO TO LOCATE INPUT FILES
	
		2. RUN SCRIPTS ON AN HPC CLUSTER

USAGE

./jbrowseView.pl <--inputfiles String> <--outputdir String>
	<--inputdir String> [--splitfile String] [--reads Integer] [--convert]
	[--clean] [--queue String] [--maxjobs Integer] [--cpus Integer] [--help]

--outputdir       :   Directory with one subdirectory per reference chromosome
						containing an out.sam or out.bam alignment output file
--inputdir    :   Location of directory containing chr*.fa reference files
--chromodir         :   Name of the reference chromodir (e.g., 'mouse')
--queue           :   Cluster queue name
--cluster         :   Cluster type (LSF|PBS)
--help            :   print help info


EXAMPLES

/nethome/bioinfo/apps/agua/0.5/bin/apps/jbrowseView.pl \
--refseqfile /nethome/syoung/base/pipeline/jbrowse/ucsc/reference/refSeqs.js \
--outputdir /scratch/syoung/base/pipeline/jbrowse/agua/0.5/maq1 \
--inputdir /scratch/syoung/base/pipeline/SRA/NA18507/maq/maq1 \
--filetype bam \
--filename "out.bam" \
--label maq1 \
--key maq1 \
--queue large \
--cluster LSF


=cut

use strict;

#### EXTERNAL MODULES
use Term::ANSIColor qw(:constants);
use Data::Dumper;
use Getopt::Long;
use FindBin qw($Bin);

#### USE LIBRARY
use lib "$Bin/../../../lib";	
use lib "$Bin/../../../lib/external";	

#### INTERNAL MODULES
use JBrowse;
use Timer;
use Util;
use Conf::Yaml;

##### STORE ARGUMENTS TO PRINT TO FILE LATER
my @arguments = @ARGV;
unshift @arguments, $0;

#### FLUSH BUFFER
$| =1;

#### SET JBrowse LOCATION
my $conf = Conf::Yaml->new(inputfile=>"$Bin/../../../conf/config.yaml");
my $jbrowse = $conf->getKey("data", 'JBROWSE');
print "JBROWSE: $jbrowse\n";
my $samtools = $conf->getKey("applications", 'SAMTOOLS');

#### DEFAULT MAX FILE LINES (MULTIPLE OF 4 BECAUSE EACH FASTQ RECORD IS 4 LINES)
my $maxlines = 4000000;

#### GET OPTIONS
my $outputdir;
my $inputdir;
my $filename;
my $filetype;
my $label;
my $key;
my $refseqfile;

#### CLUSTER OPTIONS
my $tempdir = "/tmp";
my $cluster = "PBS";
my $queue = "gsmall";
my $maxjobs = 30;
my $cpus = 1;
my $sleep = 5;
my $parallel;
my $verbose;
my $dot = 1;

my $help;
print "jbrowseView.pl    Use option --help for usage instructions.\n" and exit if not GetOptions (	
	#### JBROWSE
    'inputdir=s'	=> \$inputdir,
    'outputdir=s'	=> \$outputdir,
    'filename=s' 	=> \$filename,
    'filetype=s' 	=> \$filetype,
    'label=s' 		=> \$label,
    'key=s' 		=> \$key,
    'refseqfile=s' 	=> \$refseqfile,
    'jbrowse=s' 	=> \$jbrowse,

	#### CLUSTER
    'maxjobs=i' 	=> \$maxjobs,
    'cpus=i'        => \$cpus,
    'cluster=s' 	=> \$cluster,
    'queue=s' 		=> \$queue,
    'sleep=i' 		=> \$sleep,
    'verbose' 		=> \$verbose,
    'tempdir=s' 	=> \$tempdir,
    'help' 			=> \$help
);

#### PRINT HELP
if ( defined $help )	{	usage();	}

#### CHECK INPUTS
die "outputdir not defined (Use --help for usage)\n" if not defined $outputdir;
die "inputdir not defined (Use --help for usage)\n" if not defined $inputdir;
die "filetype not defined (Use --help for usage)\n" if not defined $filetype;
die "filename not defined (Use --help for usage)\n" if not defined $filename;
die "label not defined (Use --help for usage)\n" if not defined $label;
die " not defined (Use --help for usage)\n" if not defined $key;
die "refseqfile not defined (Use --help for usage)\n" if not defined $refseqfile;
die "jbrowse not defined (Use --help for usage)\n" if not defined $jbrowse;
print "Can't find outputdir: $outputdir\n" if not -d $outputdir;

#### CHECK FILETYPE IS SUPPORTED
print "filetype not supported (bam|gff): $filetype\n" and exit if $filetype !~ /^(bam|gff)$/;

#### DEBUG
print "jbrowseView.pl    outputdir: $outputdir\n";
print "jbrowseView.pl    inputdir: $inputdir\n";
print "jbrowseView.pl    filetype: $filetype\n";
print "jbrowseView.pl    refseqfile: $refseqfile\n";

#### INSTANTIATE JBrowse OBJECT
my $jbrowseObject = JBrowse->new(
	{
		#### JBROWSE
		inputdir	=> 	$inputdir,
		outputdir 	=> 	$outputdir,
		refseqfile 	=> 	$refseqfile,
		filetype	=>	$filetype,
		filename	=>	$filename,
		label		=>	$label,
		key			=>	$key,
		jbrowse		=>	$jbrowse,

		#### CLUSTER
		cluster 	=> $cluster,
		queue 		=> $queue,
		maxjobs 	=> $maxjobs,
		cpus        => $cpus,
		sleep 		=> $sleep,
		tempdir 	=> $tempdir,
		dot 		=> $dot,
		verbose 	=> $verbose,
		
		command 	=>	\@arguments
	}
);

#### GENERATE FEATURES
$jbrowseObject->jbrowseFeatures();

#### PRINT RUN TIME
my $runtime = Timer::runtime( $time, time() );
print "jbrowseView.pl    Run time: $runtime\n";
print "jbrowseView.pl    Completed $0\n";
print "jbrowseView.pl    ";
print Timer::current_datetime(), "\n";
print "jbrowseView.pl    ****************************************\n\n\n";
exit;

#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#									SUBROUTINES
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


sub usage
{
	print GREEN;
	print `perldoc $0`;
	print RESET;
	exit;
}

