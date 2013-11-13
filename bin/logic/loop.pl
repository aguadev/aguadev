#!/usr/bin/perl -w

#### DEBUG
my $DEBUG = 0;
#$DEBUG = 1;

#### TIME
my $time = time();

=head2

    APPLICATION     loop
	    
    VERSION         0.02

	HISTORY
	
		VERSION 0.02	ADDED concurrent EXECUTION OF REPLICATES
		
		VERSION 0.01	BASIC LOOP USING BACKTICKS

    PURPOSE
  
        1. REPEATEDLY EXECUTE AN APPLICATION, CHANGING THE VALUE OF
		
			A PARTICULAR PARAMETER EVERY TIME
		
		2. REPEAT FOR A SPECIFIED NUMBER OF REPLICATES

    INPUT

        1. EXECUTABLE AND ITS ARGUMENTS
		
		2. PARAMETER TO BE CHANGED
		
		3. COMMA-SEPARATED LIST OF VALUES FOR THE PARAMETER
		
		4. COMMA-SEPARATED LIST OF REPLICATES
        
    OUTPUT
    
        1. OUTPUTS OF EACH RUN OF THE EXECUTABLE USING A
		
			DIFFERENT VALUE FOR THE PARAMETER EACH TIME
		
    USAGE
    
    ./loop.pl <--executable String> <--parameter String> <--values String> <--replicates String> [--concurrent] [... arguments for executable ...] [--help]
    
		--executable	:	Location of executable
		--parameter		:   Parameter to be changed
		--values		:   Values to be used for the parameter
		--concurrent	:	Run duplicates in parallel rather than in series
		--help          :   print help info

    EXAMPLES

chmod 755 /nethome/bioinfo/apps/agua/0.4/bin/apps/loop.pl

/nethome/bioinfo/apps/agua/0.4/bin/apps/loop.pl \
--executable /nethome/bioinfo/apps/agua/0.4/bin/apps/ELAND.pl \
--parameter "--reads" \
--values 500000,1000000,1500000,2000000,2500000,3000000,3500000 \
--replicates 1,2,3,4 \
--inputtype fastq \
--cluster LSF \
--queue priority \
--tempdir /tmp \
--outputdir /nethome/syoung/base/pipeline/benchmark/eland/eland%REPLICATE%-%PARAMETER% \
--stdout /nethome/syoung/base/pipeline/benchmark/eland/eland%REPLICATE%-%PARAMETER%/eland.outerr \
--inputfile /nethome/syoung/base/pipeline/benchmark/data/duan/run12/s_1_1_sequence.fastq \
--referencedir /nethome/bioinfo/data/sequence/chromosomes/human-sq \
--jobs 600 \
--parallel



=cut

use strict;

#### EXTERNAL MODULES
use Term::ANSIColor qw(:constants);
use Data::Dumper;
use Getopt::Long;
use FindBin qw($Bin);

#### USE LIBRARY
use lib "$Bin/../../lib";	
use lib "$Bin/../../lib/external";	

#### INTERNAL MODULES
use Agua::Logic::Loop;
use Timer;
use Util;
use Conf::Yaml;

##### STORE ARGUMENTS TO PRINT TO FILE LATER
my $arguments;
@$arguments = @ARGV;

my $loop = Agua::Logic::Loop->new(
	{
		arguments	=>	$arguments
	}
);

$loop->run();

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
	print GREEN;
	print `perldoc $0`;
	print RESET;
	exit;
}


