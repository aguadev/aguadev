#!/usr/bin/perl -w

#### DEBUG
my $DEBUG = 1;
my $time = time();

=head2

	APPLICATION     chromosomeSizes
	    
    PURPOSE
  
        CALCULATE CHROMOSOME SIZES AND PRINT TO FILE

    INPUT

        1. FULL PATH TO DIRECTORY CONTAINING FASTA FILES

		2. [optional] REFERENCE FILE SUFFIX (DEFAULT = .fa)

    OUTPUT
    
        1. chromosome-sizes.txt FILE IN FASTA FILE DIRECTORY CONTAINING 
        
            chromosome  start   stop    length

    USAGE
    
    ./chromosomeSizes.pl <--inputdir String> [--suffix String] [-h]
    
    --inputdir		:   /full/path/to/inputdir
    --suffix		:	Fasta file suffix (DEFAULT=.fa)
    --help          :   Print help info

    EXAMPLES
    
chromosomeSizes.pl \
--inputdir /nethome/bioinfo/data/sequence/chromosomes/rat/rn4/fasta


=cut

use strict;

#### EXTERNAL MODULES
use Term::ANSIColor qw(:constants);
use Data::Dumper;
use Getopt::Long;
use FindBin qw($Bin);

#### USE LIBRARY
use lib "$Bin/../../lib";

#### INTERNAL MODULES
use Timer;
use Util;
use Conf::Yaml;
use Cluster;

#### EXTERNAL MODULES
use Term::ANSIColor qw(:constants);

#### OPTIONS
my $inputdir;
my $suffix;
my $help;
if ( not GetOptions (
    'inputdir=s'   => \$inputdir,
    'suffix=s'   	=> \$suffix,
    'help'          => \$help
) )
{ print "Use option --help for usage instructions.\n";  exit;    };

#### PRINT HELP
if ( defined $help )	{	usage();	}

#### CHECK INPUTS
die "inputdir not defined (Use --help for usage)\n" if not defined $inputdir;
print "chromosomeSizes.pl    inputdir: $inputdir\n";

#### INITIALISE CLUSTER OBJECT
my $clusterObject = Cluster->new();

#### RUN chromosomesSizes
$clusterObject->chromosomeSizes($inputdir, $suffix);

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
	print GREEN <<"EOF";

	APPLICATION     chromosomeSizes
	    
    PURPOSE
  
        CALCULATE CHROMOSOME SIZES

    INPUTS

        1. FULL PATH TO DIRECTORY CONTAINING FASTA FILES

        2. LIST OF FASTA FILES IN ORDER

    OUTPUTS
    
        1. chromosome-positions.txt FILE IN FASTA FILE DIRECTORY CONTAINING 
        
            chromosome  start   stop    length

    USAGE
    
    ./chromosome-positions.pl <-d inputdir> <-i fastafiles> [-h]
    
    -d inputdir            :   /full/path/to/inputdir
    -i inputfiles          :   comma-separated fasta file names
    -h help                :   print help info

    EXAMPLES
    
./chromosome-positions.pl -d /home/syoung/base/pipeline/human-genome -i chr1.fa,chr2.fa,chr3.fa,chr4.fa,chr5.fa,chr6.fa,chr7.fa,chr8.fa,chr9.fa,chr10.fa,chr11.fa,chr12.fa,chr13.fa,chr14.fa,chr15.fa,chr16.fa,chr17.fa,chr18.fa,chr19.fa,chr20.fa,chr21.fa,chr22.fa,chrX.fa,chrY.fa


=cut

EOF

	print RESET;

	exit;
}



