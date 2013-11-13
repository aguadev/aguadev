#!/usr/bin/perl -w
use strict;

#### DEBUG
my $DEBUG = 0;
#$DEBUG = 1;

#### TIME
my $time = time();

=head2

    APPLICATION     compareChars.pl
    
    PURPOSE
    
        USES FileTools::compareChars TO CHECK READ LENGTHS
		
			1. PRINT LIST OF DIFFERENT READ LENGTHS
			
				WITH NUMBER OF READS OF EACH LENGTH
        
    INPUT
    
        1. INPUT FASTA OR FASTQ FILE
            
    OUTPUT
    
        1. LIST OF DIFFERENT READ LENGTH AND NUMBER OF READS 

    USAGE
    
    ./compareChars.pl <--inputfile1 String> <--inputfile2 String> [--help]
    
    --inputfile1        :   /Full/path/to/first_inputfile
    --inputfile2        :   /Full/path/to/second_inputfile
    --help              :   Print help info

    EXAMPLES


perl compareChars.pl --inputfile1 6/run12+15-s_2_1.6.fastq --inputfile2 7/run12+15-s_2_1.7.fastq

 


=cut

#### FLUSH BUFFER
$| = 1;

#### EXTERNAL MODULES
use FindBin qw($Bin);
use Data::Dumper;
use Term::ANSIColor qw(:constants);
use Getopt::Long;

#### USE LIB
use lib "$Bin/../../lib";

#### INTERNAL MODULES  
use Timer;
use FileTools;

#### GET OPTIONS
my $inputfile1;
my $inputfile2;
my $help;
GetOptions (
    'inputfile1=s' => \$inputfile1,
    'inputfile2=s' => \$inputfile2,
    'help' => \$help) or die "No options specified. Try '--help'\n";

#### PRINT HELP IF REQUESTED
if ( defined $help )	{	usage();	}

#### INSTANTIATE FileTools OBJECT
my $filetools = FileTools->new();
my $criteria = $filetools->compareChars($inputfile1, $inputfile2);

print "compareChars counts:\n";
foreach my $criterion ( keys %$criteria )
{
	print "$criterion\t$criteria->{$criterion}->{count}\n";

	my $hasharray = $criteria->{$criterion}->{characters};
	foreach my $character ( @$hasharray )
	{
		my @keys = keys ( %$character );
		my $key = $keys[0];
		print "$key\t$character->{$key}\n";
	}

}




#### PRINT RUN TIME
my $runtime = Timer::runtime( $time, time() );
print "\nRun time: $runtime\n";
print "Completed $0\n";
print Timer::datetime(), "\n";
print "****************************************\n\n\n";
exit;

#### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### 
#### #### #### ####             SUBROUTINES                 #### #### #### ####  
#### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### 


sub usage
{
	print GREEN;
    print `perldoc $0`;
	print RESET;

	exit;
}

