#!/usr/bin/perl -w

#### DEBUG
#my $DEBUG = 1;
my $DEBUG = 0;

#### TIME
my $time = time();
my $duration = 0;
my $current_time = $time;

=head2

    APPLICATION     filetools

    PURPOSE
  
        FILE MANIPULATION, QUALITY CHECKING AND OTHER UTILITIES
		
    USAGE
    
./filetools.pl mode [args] [--help]
	
    mode			:   File manipulation or QC function
	args			:	Arguments for selected mode
    --help			:   print help info

    EXAMPLES

/nethome/bioinfo/apps/agua/0.5/bin/apps/filetools.pl filterReads \
--inputdir /nethome/bioinfo/data/sequence/chromosomes/rat/rn4/novoalign


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
use FileTools;
use Timer;

#### GET MODE AND ARGUMENTS
my @arguments = @ARGV;
my $mode = shift @ARGV;

#### PRINT HELP
if ( $mode eq "-h" or $mode eq "--help" )	{	help();	}

#### FLUSH BUFFER
$| =1;

#### RUN QUERY
no strict;
eval { &$mode() };
if ( $@ ){
	print "Mode not supported: $mode\n";
	print "Error output: $@\n";
}

sub comparePair {
	#### GET OPTIONS
	my ($inputfile, $matefile, $type, $length);
	my $help;
	if ( not GetOptions (
		'inputfile=s'   => \$inputfile,
		'matefile=s'	=> \$matefile,
		'type=s'   		=> \$type,
		'help'          => \$help
	) )
	{ print "Use option --help for usage instructions.\n";  exit;    };
	
	#### PRINT HELP
	if ( defined $help )
	{
		print qq{

	$0 comparePair <--inputfile String> <--matefile String> <--type String> [--help]
	
	--inputfile 	Full path to input FASTA or FASTQ file
	--matefile	Full path to output file
	--type			FASTA or FASTQ
	--length		Length of output read sequence (and quality)
	--help			Print help info
};
	}
	
	#### CHECK INPUTS
	die "inputfile not defined (Use --help for usage)\n" if not defined $inputfile;
	die "matefile not defined (Use --help for usage)\n" if not defined $matefile;
	die "type not defined (Use --help for usage)\n" if not defined $type;

	#### DEBUG
	print "filetools.pl    matefile: $matefile\n";
	print "filetools.pl    inputfile: $inputfile\n";
	print "filetools.pl    type: $type\n";
	
	#### DO CONVERSION
	my $filetools = FileTools->new();
	$filetools->comparePair($inputfile, $matefile, $type);

	print "filetools.pl    \n";
	print "filetools.pl    comparePairs   Completed.\n";
}



sub filterReadLength {
	#### GET OPTIONS
	my ($inputfile, $outputfile, $type, $length);
	my $help;
	if ( not GetOptions (
		'inputfile=s'   => \$inputfile,
		'outputfile=s'	=> \$outputfile,
		'type=s'   		=> \$type,
		'length=i'   	=> \$length,
		'help'          => \$help
	) )
	{ print "Use option --help for usage instructions.\n";  exit;    };
	
	#### PRINT HELP
	if ( defined $help )
	{
		print qq{

	$0 filterReadLength <--inputfile String> <--outputfile String> <--type String>
				[--length Integer] [--start Integer] [--help]
	
	--inputfile 	Full path to input FASTA or FASTQ file
	--outputfile	Full path to output file
	--type			FASTA or FASTQ
	--length		Length of output read sequence (and quality)
	--help			Print help info
};
	}
	
	#### CHECK INPUTS
	die "inputfile not defined (Use --help for usage)\n" if not defined $inputfile;
	die "outputfile not defined (Use --help for usage)\n" if not defined $outputfile;
	die "type not defined (Use --help for usage)\n" if not defined $type;
	die "length not defined (Use --help for usage)\n" if not defined $length;

	#### DEBUG
	#print "filetools.pl    outputfile: $outputfile\n";
	#print "filetools.pl    inputfile: $inputfile\n";
	#print "filetools.pl    type: $type\n";
	#print "filetools.pl    length: $length\n";
	
	#### DO CONVERSION
	my $filetools = FileTools->new();
	$filetools->filterReadLength($inputfile, $outputfile, $type, $length);

	print "filetools.pl    \n";
	print "filetools.pl    filterReadLengths   Completed.\n";
}



sub trimRead {
	#### GET OPTIONS
	my ($inputfile, $outputfile, $type, $start, $length);
	my $help;
	if ( not GetOptions (
		'inputfile=s'   => \$inputfile,
		'outputfile=s'	=> \$outputfile,
		'type=s'   		=> \$type,
		'start=i'   	=> \$start,
		'length=i'   	=> \$length,
		'help'          => \$help
	) )
	{ print "Use option --help for usage instructions.\n";  exit;    };
	
	#### PRINT HELP
	if ( defined $help )
	{
		print qq{

	$0 trimRead <--inputfile String> <--outputfile String> <--type String>
				[--length Integer] [--start Integer] [--help]
	
	--inputfile 	Full path to input FASTA or FASTQ file
	--outputfile	Full path to output file
	--type			FASTA or FASTQ
	--length		Length of output read sequence (and quality)
	--start			Remove this number of bases from the start of the sequence
	--help			Print help info
};
	}
	
	#### CHECK INPUTS
	die "inputfile not defined (Use --help for usage)\n" if not defined $inputfile;
	die "outputfile not defined (Use --help for usage)\n" if not defined $outputfile;
	die "type not defined (Use --help for usage)\n" if not defined $type;
	die "length not defined (Use --help for usage)\n" if not defined $length;

	#### DEBUG
	#print "filetools.pl    outputfile: $outputfile\n";
	#print "filetools.pl    inputfile: $inputfile\n";
	#print "filetools.pl    type: $type\n";
	#print "filetools.pl    length: $length\n";
	#print "filetools.pl    start: $start\n";
	
	#### DO CONVERSION
	my $filetools = FileTools->new();
	$filetools->trimRead($inputfile, $outputfile, $type, $length, $start);

	print "filetools.pl    \n";
	print "filetools.pl    trimReads   Completed.\n";
}




sub help {
	print qq{$0 --help
	
	filetools  mode [arguments]
	
	modes:
	
		filterReadLength 	Filter reads by sequence and quality length (FASTA/FASTQ only)
	
};

	exit;	
}

#chdir($inputdir) or die "Can't change to inputdir directory: $inputdir\n";
#my @files = <*fa>;
##### TRUNCATE inputdir FILES TO CREATE CORRECT STUB IDENTIFIER
#foreach my $file ( @files )
#{
#	my ($stub) = $file =~ /^(.+)\.fa$/;
#	my $command = "time $novoalign/novoalign-build  $file $stub";
#	print "command: $command\n";
#	`$command`;
#}

#### PRINT RUN TIME
my $runtime = Timer::runtime( $time, time() );
print "filetools.pl    \n";
print "filetools.pl    Run time: $runtime\n";
print "filetools.pl    Date: ";
print Timer::datetime(), "\n";
print "filetools.pl    Command: \n";
print "filetools.pl    $0 @arguments\n";
print "filetools.pl    \n";
print "filetools.pl    ****************************************\n\n\n";
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


