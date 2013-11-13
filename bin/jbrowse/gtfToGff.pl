#!/usr/bin/perl -w

#### DEBUG
my $DEBUG = 0;
#$DEBUG = 1;

#### TIME
my $time = time();

=head2

	APPLICATION     gtfToGff
	    
    PURPOSE
  
        CONVERT A GTF FILE TO GFF FORMAT
            
    INPUTS
    
		1. LOCATION OF INPUT DIRECTORY CONTAINING 'reference1', 'reference2'
		
			SUB-DIRECTORIES
			
		2. NAME OF THE INPUT FILE INSIDE THE SUBDIRECTORIES
		
		3. OUTPUT DIRECTORY FOR PRINTING GFF FILES

        4. NAME FOF FEATURE
		
		5. 
		
    OUTPUT
        
        1. PROCESSED FILES FOUND IN DIRECTORY agua/data/seq AND agua/data/tracks
        
	NOTES:

		INPUT FILE GTF FORMAT:

		head hs-conrad-dels-chr1-gtf 		
		
		chr1    hg18_delConrad2 CDS     45258   76166   1000.000000     +       0       gene_id "chr1.1"; transcript_id "chr1.1"; 
		chr1    hg18_delConrad2 exon    76167   988364  1000.000000     +       .       gene_id "chr1.1"; transcript_id "chr1.1"; 
		chr1    hg18_delConrad2 exon    6624739 6717817 1000.000000     +       .       gene_id "chr1.2"; transcript_id "chr1.2"; 
		chr1    hg18_delConrad2 CDS     6717818 6720271 1000.000000     +       0       gene_id "chr1.2"; transcript_id "chr1.2"; 
		chr1    hg18_delConrad2 exon    6720272 6726334 1000.000000     +       .       gene_id "chr1.2"; transcript_id "chr1.2"; 


		OUTPUT GFF FORMAT:
		
		head /nethome/syoung/base/pipeline/jbrowse1/ucsc/gff/hs-cytoBand-chr1.gff
		
		### /data/agua/0.4/bin/apps/gtfToGff.pl --refseqfile /nethome/syoung/base/pipeline/jbrowse1/ucsc/chr1/data/refSeqs.js --inputfile /nethome/syoung/base/pipeline/jbrowse1/ucsc/gtf/hs-cytoBand-chr1-gtf --outputfile /nethome/syoung/base/pipeline/jbrowse1/ucsc/gff/hs-cytoBand-chr1.gff
		####3:23AM, 8 December 2009
		chr1    hg18_cytoBand   exon    0       247249719       .       .       .       Name=chr1
		chr1    hg18_cytoBand   exon    1       2300000 0       .       .       Name=p36.33
		chr1    hg18_cytoBand   exon    2300001 5300000 0       .       .       Name=p36.32
		chr1    hg18_cytoBand   exon    5300001 7100000 0       .       .       Name=p36.31
		chr1    hg18_cytoBand   exon    7100001 9200000 0       .       .       Name=p36.23
		chr1    hg18_cytoBand   exon    9200001 12600000        0       .       .       Name=p36.22
		chr1    hg18_cytoBand   exon    12600001        16100000        0       .       .       Name=p36.21


    USAGE
    
    ./gtfToGff.pl  <--inputfile String> <--outputfile String> [-h]
    
        --inputdir		:   Directory containing 'ref1', 'ref2' subdirectories
        --inputfile		:   Name of input file in subdirectories
        --feature		:   Name of feature
        --outputdir		:   Print GFF files to this output directory
        --help			:   print help info

	EXAMPLES

/nethome/bioinfo/apps/agua/0.5/bin/apps/gtfToGff.pl \
--refseqfile /nethome/syoung/base/pipeline/jbrowse/ucsc/0.5/rat/rn4/refSeqs.js \
--inputdir /nethome/syoung/base/pipeline/jbrowse/ucsc/0.5/rat/rn4/gtf \
--outputdir /nethome/syoung/base/pipeline/jbrowse/ucsc/0.5/rat/rn4/gff \
--feature CpG \
--inputfile CpG.gtf


=cut

use strict;

#### USE LIBRARY
use FindBin qw($Bin);
use lib "$Bin/../../../lib";
use lib "$Bin/../../../lib/external";

#### FLUSH BUFFER
$| = 1;

#### INTERNAL MODULES
use Agua::JBrowse;
use Timer;
use Util;
use Conf::Yaml;


#### SAVE ARGUMENTS
my @args = @ARGV;

#### EXTERNAL MODULES
use JSON;
use Term::ANSIColor qw(:constants);
use Getopt::Long;
use Data::Dumper;
use File::Path;

#### GET OPTIONS
my $inputdir;
my $inputfile;
my $outputdir;
my $refseqfile;
my $feature;
my $help;
if ( not GetOptions (
    'inputdir=s' 	=> \$inputdir,
    'inputfile=s' 	=> \$inputfile,
    'outputdir=s' 	=> \$outputdir,
    'refseqfile=s' 	=> \$refseqfile,
    'feature=s' 	=> \$feature,
	'help' 			=> \$help
) )
{	usage();	};

#### PRINT HELP
if ( defined $help )	{	usage();	}

#### CHECK INPUTS
print "Either inputdir or inputfile must be defined (use --help)\n" and exit if not defined $inputdir and not defined $inputfile;
print "refseqfile not defined (use --help)\n" and exit if not defined $refseqfile;

#### CHECK INPUT FILES
print "Can't find inputdir: $inputdir\n" if not -d $inputdir;
$outputdir = $inputdir if not defined $outputdir;
File::Path::mkpath($outputdir) if not -d $outputdir;
print "Can't create outputdir: $outputdir\n" if not -d $outputdir;

#### INITIALISE JBROWSE OBJECT
my $jbrowse = Agua::JBrowse->new();
$jbrowse->gtfToGff(
	{
		inputdir 	=> $inputdir,
		inputfile 	=> $inputfile,
		outputdir 	=> $outputdir,
		refseqfile 	=> $refseqfile,
		feature 	=> $feature
	}
);

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

