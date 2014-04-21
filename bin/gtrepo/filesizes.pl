#!/usr/bin/perl -w


=head2

APPLICATION 	filesizes

PURPOSE

	1. Get the file sizes for a list of UUIDS in a GeneTorrent Repository (e.g., CGHub)
	
	2. Print the results to file

HISTORY

	v0.0.1	Base functionality

USAGE


inputfile   :    File containing list of UUIDs
outputdir   :    Print output file and intermediate files to this directory

=cut

#### EXTERNAL MODULES
use Term::ANSIColor qw(:constants);
use Data::Dumper;
use Getopt::Long;

##### STORE ARGUMENTS TO PRINT TO FILE LATER
my $arguments;
@$arguments = @ARGV;

my $inputfile;
my $outputdir;
my $help;
GetOptions (
    'inputfile=s'  	=> \$inputfile,
    'outputdir=s'  		=> \$outputdir,
    'help'          => \$help
) or die "No options specified. Try '--help'\n";
usage() if defined $help;

print "inputfile not defined\n" and exit if not defined $inputfile;
print "outputdir not defined\n" and exit if not defined $outputdir;

open($inputfile, FILE) or die "Can't open inputfile: $inputfile\n";
my @lines	=	<FILE>;
close(FILE) or die "Can't open inputfile: $inputfile\n";
for ( my $i = 0; $i < $#lines + 1; $i++ ) {
	my @array = split "\t", $lines[$i];
	next if not defined $array[0];
	next if $array[0] eq "";
	
	if ( $array[0] =~ /TCGA, US$/ ) {
		my ($disease)	=	$array[0]	=~ 	/^\s*(.+)-\s*TCGA,\s+US\s*$/;
		print "disease: $disease\n";
		
	}
	
}




##############################################################

sub usage {
	print `perldoc $0`;
	exit;
}
