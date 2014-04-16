#!/usr/bin/perl -w

#### DEBUG
my $DEBUG = 0;
#$DEBUG = 1;

#### TIME
my $time = time();

=head2

	APPLICATION     gtf2gff
	    
    PURPOSE
  
        CONVERT A GTF FILE TO GFF FORMAT
            
    INPUT
    
		1. inputfile 

        2. outputfile 
		
    OUTPUT
        
        1. PROCESSED FILES FOUND IN DIRECTORY agua/data/seq AND agua/data/tracks
        
    USAGE
    
    ./gtf2gff.pl  <--inputfile String> <--outputfile String> [-h]
    
        --inputfile	           :   Name or full path to inputfile directory
        --outputfile	       :   Name or full path to outputfile directory
        --help                 :   print help info

    EXAMPLES

BATCH JOB:

RUN gtf2gff.pl

cd /nethome/syoung/base/pipeline/jbrowse1/ucsc/gff

/data/agua/0.4/bin/apps/gtf2gff.pl \
--configfile /nethome/syoung/base/pipeline/jbrowse1/ucsc/chr1/data/refSeqs.js \
--inputdir /nethome/syoung/base/pipeline/jbrowse1/ucsc/gtf \
--outputdir /nethome/syoung/base/pipeline/jbrowse1/ucsc/gff \
--jsonfile /nethome/syoung/base/pipeline/jbrowse1/ucsc/conf/ucsc-gff.json



/data/agua/0.4/bin/apps/gtf2gff.pl \
--configfile /nethome/syoung/base/pipeline/jbrowse1/ucsc/chr1/data/refSeqs.js \
--inputdir /nethome/syoung/base/pipeline/jbrowse1/ucsc/chromosome-gtf/chr1 \
--outputdir /nethome/syoung/base/pipeline/jbrowse1/ucsc/chromosome-gff/chr1 \
--jsonfile /nethome/syoung/base/pipeline/jbrowse1/ucsc/conf/ucsc-gff.json



THEN RUN biodb-to-json.pl

cd /nethome/syoung/base/pipeline/jbrowse1/ucsc/chr1
/var/www/html/jbrowse/bin/biodb-to-json.pl \
--conf /nethome/syoung/base/pipeline/jbrowse1/ucsc/chr1/data/human-chr1.json




SINGLE FILE:

cd /nethome/syoung/base/pipeline/jbrowse1/ucsc/gff

/data/agua/0.4/bin/apps/gtf2gff.pl \
--configfile /nethome/syoung/base/pipeline/jbrowse1/ucsc/chr1/data/refSeqs.js \
--inputfile /nethome/syoung/base/pipeline/jbrowse1/ucsc/gtf/hs-cytoBand-chr1-gtf \
--outputfile /nethome/syoung/base/pipeline/jbrowse1/ucsc/gff/hs-cytoBand-chr1.gff \
--feature cytoband


WHICH PRODUCES THIS OUTPUT FILE:

head /nethome/syoung/base/pipeline/jbrowse1/ucsc/gff/hs-cytoBand-chr1.gff

	### /data/agua/0.4/bin/apps/gtf2gff.pl --configfile /nethome/syoung/base/pipeline/jbrowse1/ucsc/chr1/data/refSeqs.js --inputfile /nethome/syoung/base/pipeline/jbrowse1/ucsc/gtf/hs-cytoBand-chr1-gtf --outputfile /nethome/syoung/base/pipeline/jbrowse1/ucsc/gff/hs-cytoBand-chr1.gff
	####3:23AM, 8 December 2009
	
	chr1    hg18_cytoBand   exon    0       247249719       .       .       .       Name=chr1
	chr1    hg18_cytoBand   exon    1       2300000 0       .       .       Name=p36.33
	chr1    hg18_cytoBand   exon    2300001 5300000 0       .       .       Name=p36.32
	chr1    hg18_cytoBand   exon    5300001 7100000 0       .       .       Name=p36.31
	chr1    hg18_cytoBand   exon    7100001 9200000 0       .       .       Name=p36.23
	chr1    hg18_cytoBand   exon    9200001 12600000        0       .       .       Name=p36.22
	chr1    hg18_cytoBand   exon    12600001        16100000        0       .       .       Name=p36.21


WHICH WORKS AS INPUT FOR biodb-to-json.pl:

cd /jbrowse1/ucsc/conf/ucsc.json
/var/www/html/jbrowse/bin/biodb-to-json.pl --conf /nethome/syoung/base/pipeline/jbrowse1/ucsc/conf/ucsc.json

	working on refseq chr1
	working on track exon
	got 64 features for exon


NOTES:

	INPUT FILES ARE DOWNLOADED UCSC GTF FILES WITH THE FOLLOWING FORMAT:

head hs-conrad-dels-chr1-gtf 		

	chr1    hg18_delConrad2 CDS     45258   76166   1000.000000     +       0       gene_id "chr1.1"; transcript_id "chr1.1"; 
	chr1    hg18_delConrad2 exon    76167   988364  1000.000000     +       .       gene_id "chr1.1"; transcript_id "chr1.1"; 
	chr1    hg18_delConrad2 exon    6624739 6717817 1000.000000     +       .       gene_id "chr1.2"; transcript_id "chr1.2"; 
	chr1    hg18_delConrad2 CDS     6717818 6720271 1000.000000     +       0       gene_id "chr1.2"; transcript_id "chr1.2"; 
	chr1    hg18_delConrad2 exon    6720272 6726334 1000.000000     +       .       gene_id "chr1.2"; transcript_id "chr1.2"; 



=cut

use strict;

#### USE LIBRARY
use FindBin qw($Bin);
use lib "$Bin/../../lib";
use lib "$Bin/../../lib/external/lib/perl5";

#### FLUSH BUFFER
$| = 1;

#### INTERNAL MODULES
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

#### GET OPTIONS
my $inputfile;
my $outputfile;
my $configfile;
my $feature;
my $jsonfile;
my $inputdir;
my $outputdir;
my $help;
if ( not GetOptions (
    'inputfile=s' => \$inputfile,
    'outputfile=s' => \$outputfile,
    'configfile=s' => \$configfile,
    'feature=s' => \$feature,
    'jsonfile=s' => \$jsonfile,
    'inputdir=s' => \$inputdir,
    'outputdir=s' => \$outputdir,
	'help' => \$help
) )
{	usage(); exit;	};

#### PRINT HELP
if ( defined $help )	{	usage();	}

#### CHECK INPUTS
die "configfile not defined (use --help option for usage)\n" if not defined $configfile;
die "jsonfile not defined (use --help option for usage)\n" if not defined $jsonfile;
if ( not defined $inputdir or not defined $outputdir )
{
	die "Inputfile not defined (use --help option for usage)\n" if not defined $inputfile;
	die "Outputfile not defined (use --help option for usage)\n" if not defined $outputfile;
}
else
{
	die "Inputdir not defined (use --help option for usage)\n" if not defined $inputdir;
	die "Outputdir not defined (use --help option for usage)\n" if not defined $outputdir;
}

#### CHECK INPUT FILES
die "Can't find input file: $inputfile\n" if defined $inputfile and not -f $inputfile;
die "Can't find config file: $configfile\n" if defined $configfile and not -f $configfile;
die "Can't find json file: $jsonfile\n" if defined $jsonfile and not -f $jsonfile;


#### GET CHROMOSOME NAME AND LENGTH FROM CONFIG FILE
open(CONF, $configfile) or die "Can't open config file: $configfile\n";
$/ = undef;
my $contents = <CONF>;
close(CONF) or die "Can't close config file: $configfile\n";
#print "contents: $contents\n" if $DEBUG;
$contents =~ s/^\s*refSeqs = \s*\[\s*//;
$contents =~ s/\]\s*$//;
$contents =~ s/\s+//g;

#### PARSE CONFIG FILE JSON
######## FORMAT:
####	refSeqs =
####	[
####	   {
####		  "length" : 247249719,
####		  "name" : "chr1",
####		  "seqDir" : "data/seq/chr1",
####		  "seqChunkSize" : 20000,
####		  "end" : 247249719,
####		  "start" : 0
####	   }
####	]
my $jsonParser = JSON->new();
my @refseqs = $jsonParser->decode($contents);
print "\@refseqs:" if $DEBUG;
print Dumper @refseqs if $DEBUG;


#### GET REFSEQ HASH (CONTAINS NAME, START AND END)
my $refseq = $refseqs[0];

#### GET .json FILE HASH
open(ARGS, $jsonfile) or die "Can't open args file: $jsonfile\n";
$/ = undef;
$contents = <ARGS>;
close(ARGS);
die "Json file is empty\n" if $contents =~ /^\s*$/;
my $json = $jsonParser->decode($contents);


if ( not defined $inputdir or not defined $outputdir )
{
	my ($inputfile_name) = $inputfile =~ /([^\/]+)$/;
	my $featurehash = $json->{features}->{$inputfile_name};
	die "Input file not included in .json file: $inputfile_name\n" if not defined $featurehash;
	gtf2gff($inputfile, $outputfile, $featurehash, $refseq);
}
else
{
	print "Doing files in input directory: $inputdir\n";

	#### GET FILES
	opendir(DIR, $inputdir) or die "Can't open directory: $inputdir\n";
	my @inputfiles = readdir(DIR);
	closedir(DIR);	
	

	#### DO ALL FILES SPECIFIED IN FEATURES HASH
	my $file_counter = 0;
	foreach my $inputfile ( @inputfiles )
	{
		$file_counter++;
		print "file $file_counter: $inputfile\n" if $DEBUG;

		next if $inputfile =~ /^\.+$/;
		
		
		my $featurehash = featurehash($json, $inputfile);

		#next if $file_counter < 14 and $DEBUG;

		#### SET OUTPUT FILE
		my $outputfile = $inputfile;
		$outputfile =~ s/[\.\-\_]gtf$/.gff/;
		$outputfile = "$outputdir/$outputfile";

		#### SET INPUT FILE
		$inputfile = "$inputdir/$inputfile";
		
		#### CONVERT TO GFF
		gtf2gff($inputfile, $outputfile, $featurehash, $refseq);

		last if $file_counter == 14 and $DEBUG;

	}
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
		}
		#no re 'eval';# EVALUATE $pattern AS REGULAR EXPRESSION
	}

	print "feature hash not defined\n\n" and next if not defined $featurehash;
	print "featurehash: \n" if $DEBUG;
	print Dumper $featurehash if $DEBUG;

	return $featurehash;
}

sub gtf2gff
{
	my $inputfile	=	shift;
	my $outputfile	=	shift;
	my $featurehash	=	shift;
	my $refseq		=	shift;

	#### GET REFERENCE SEQUENCE INFO FOR FIRST LINE OF OUTPUT FILE	
	my $name = $refseq->{name};
	my $start = $refseq->{start};
	my $end = $refseq->{end};
	
	####### ADD 1 TO START AND END FOR 1-INDEXED GFF FORMAT
	###$start++;
	###$end++;
	print "name: $name\n" if $DEBUG;
	print "start: $start\n" if $DEBUG;
	print "end: $end\n" if $DEBUG;

	#### OPEN OUTPUT FILE AND PRINT RUN COMMAND, DATE AND REFERENCE SEQUENCE LINE
	open(OUTFILE, ">$outputfile") or die "Can't open output file: $outputfile\n";
	print OUTFILE "### $0 @args\n";
	print OUTFILE "####", Util::datetime(), "\n\n";
	print OUTFILE "$name\trefseq\trefseq\t$start\t$end\t.\t.\t.\tName=$name\n";
		
	#### OPEN INPUT FILE
	open(FILE, $inputfile) or die "Can't open input file: $inputfile\n";
	$/ = "\n";
	my $counter = 0;
	print "Doing input file: $inputfile\n";
	while ( <FILE> )
	{
		next if $_ =~ /^\s*$/;
		$counter++;
		if ( $counter % 10000 == 0 ) {	print "$counter\n";	}
		
		print "\n\n****************************\n" if $DEBUG;
		print "LINE: $_" if $DEBUG;
	
		my ($start, $last) = $_ =~ /^(\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+)(.+)$/;
		#print "start: $start\n" if $DEBUG;
		#print "last: $last\n" if $DEBUG;
	
		my @elements = split ";", $last;
		$last = '';
		foreach my $element ( @elements )
		{
			next if $element =~ /^\s*$/;
			$element =~ s/^\s+//;
			$element =~ s/\s+$//;
			
			
			my ($key, $value) = $element =~ /^(\S+)\s+(.+)$/;
			
			if ( $key eq "transcript_id" )
			{
				$value =~ s/"//g;
				$last = "Name=$value";
			}
		}
		$last =~ s/;$//;
	
		my @fields = split " ", $start;
		
		#### SET FEATURE
		$fields[2] = ${$featurehash->{feature}}[0];
		
		#### CORRECT SCORE TO NO DECIMAL PLACES
		$fields[5] =~ s/\.[0]+//g;
	
		#### ADD LAST ENTRY TO FIELDS
		push(@fields, $last);
	
		#print "FIELDS: \n";
		#print Dumper @fields;
	
	
		my $line = join "\t", @fields;
		print "OUTPUT: $line" if $DEBUG;
		print OUTFILE "$line\n";
	
	#exit;

	#last if $counter >= 6 and $DEBUG;
	
	
	}
	close(FILE);
	close(OUTFILE);
	print "Output file printed:\n\n$outputfile\n\n";

	
}




sub usage
{
	print `perldoc $0`;
    exit;
}

