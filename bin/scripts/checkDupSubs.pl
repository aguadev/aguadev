#!/usr/bin/perl -w
use strict;

#### DEBUG
my $DEBUG = 0;
#$DEBUG = 1;


=head2

    NAME		checkDupSubs
    
    PURPOSE
	
		CHECK FOR DUPLICATE SUBROUTINES IN ALL MODULES FOUND
		
		IN THE GIVEN FILEST

    INPUT
	
		1. DATABASE NAME
		
		2. LOCATION TO PRINT .TSV FILES

    OUTPUT
	
		1. ONE .TSV FILE FOR EACH TABLE IN DATABASE

    USAGE
	
		./checkDupSubs.pl <--basedir String> [-h] 

    --db          :   Name of database
    --outputdir   :   Location of output directory
    --help        :   print this help message

	< option > denotes REQUIRED argument
	[ option ] denotes OPTIONAL argument

    EXAMPLE

perl checkDupSubs.pl --db agua --outputdir /agua/0.6/bin/sql/dump

=cut

#### TIME
my $time = time();

#### USE LIBS
use FindBin qw($Bin);
use lib "$Bin/../../lib";

#### EXTERNAL MODULES
use Data::Dumper;
use Getopt::Long;

#### GET OPTIONS
my $basedir;
my $help;
GetOptions (
	'basedir=s' => \$basedir,
	'help' => \$help) or die "No options specified. Try '--help'\n";
if ( defined $help )	{	usage();	}

#### FLUSH BUFFER
$| =1;

#### CHECK INPUTS
die "Database not defined (option --basedir)\n" if not defined $basedir;

#### GET SUBS/METHODS
my ($subs, $methods);
my $command = qq{egrep -Rn -e "^\\s*sub " $basedir};
`echo '$command' > /tmp/out.txt`;
my $grep = `$command`;
@$subs = split "\n", $grep;
print "No. subs           : ", scalar(@$subs), "\n";
$command = qq{egrep -Rn -e "^\\s*method " $basedir};
$grep = `$command`;
@$methods = split "\n", $grep;
print "No. methods        : ", scalar(@$methods), "\n";
@$subs = (@$subs, @$methods);
print "No. subs + methods : ", scalar(@$subs), "\n";

my $stopwordhash = stopWordHash();
my $direxp = $basedir;
$direxp =~ s/\//\\\//g;
#print "direxp: $direxp\n";

my $subroutines;
for ( my $i = 0; $i < @$subs; $i++ ) {
	my $regex = "^$direxp(.*)\.pm:\\d+:(sub|method)\\s+(\\w+)";
	next if not $$subs[$i] =~ /$regex/;
	my $module = $1;
	my $subname = $3;
	next if not defined $module or not defined $subname;
	$module =~ s/\//::/g;
	next if exists $stopwordhash->{$subname};

	if ( defined $subroutines->{$subname} ) {
		print "$subroutines->{$subname}::$subname\n";
		print "$module" . "::$subname\n\n";
	}
	else {
		$subroutines->{$subname} = $module;
	}
}


#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#									SUBROUTINES
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

sub stopWordHash {
	
	my $stopwords;
	@$stopwords = qw(
	new
	initialise
	value
	validate_arguments
	is_valid
	AUTOLOAD
	DESTROY
	);
	#print "stopwords: @$stopwords\n";

	my $stopwordhash;
	foreach my $stopword ( @$stopwords ) {
		$stopwordhash->{$stopword} = 1;
	}

	return $stopwordhash;
}

sub usage {
    print `perldoc $0`;
	exit;
}


