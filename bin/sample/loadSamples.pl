#!/usr/bin/perl -w
use strict;

#### DEBUG
my $DEBUG = 0;
#$DEBUG = 1;


=head2

    NAME		loadSamples
    
    PURPOSE
	
		Load a list of sample ids, filenames and file sizes

    INPUT
	
		1. USERNAME
		2. PROJECT NAME
		3. WORKFLOW NAME
		4. WORKFLOW NUMBER
		5. LOCATION OF .TSV FILE

    OUTPUT
	
		1. POPULATED ROWS IN queuesample DATABASE TABLE

    USAGE
	
		./loadSamples.pl <--username String> <--project String> <--table String> <--tablenumber String> <--file String> [-h] 

    --username	  :   Name of user (e.g., admin)
    --project	  :   Name of project (e.g., AlignBams)
    --username	  :   Name of table (e.g., loadSamples)
    --username	  :   Number of table (e.g., 1)
    --file	  :   Location of *.tsv file
    --help        :   print this help message

	< option > denotes REQUIRED argument
	[ option ] denotes OPTIONAL argument

    EXAMPLE

perl loadSamples.pl --username agua --project AlignBams --table loadSamples --tablenumber 1 --file /path/to/data/samplefile.tsv

=cut

#### EXTERNAL MODULES
use Data::Dumper;
use Getopt::Long;
use FindBin qw($Bin);

#### INTERNAL MODULES
use lib "$Bin/../../lib";
use Agua::Workflow;
use Conf::Yaml;

#### SET LOG
my ($script)	=	$0	=~	/([^\.^\/]+)\.pl/;
my $logfile 	= "/tmp/$script.$$.log";

#### GET OPTIONS
my $log 		= 	2;
my $printlog 	= 	5;

my $username;
my $project;
my $table;
my $sqlfile;	
my $tsvfile;	
my $help;
GetOptions (
	'username=s' 	=> \$username,
	'project=s' 	=> \$project,
	'table=s' 		=> \$table,
	'sqlfile=s' 	=> \$sqlfile,
	'tsvfile=s' 	=> \$tsvfile,

	'log=i' 		=> \$log,
	'printlog=i' 	=> \$printlog,
	'help' => \$help) or die "No options specified. Try '--help'\n";
if ( defined $help )	{	usage();	}

#### CHECK INPUTS
die "username not defined (option --username)\n" if not defined $username;
die "project not defined (option --project)\n" if not defined $project;
die "table not defined (option --table)\n" if not defined $table;
die "sqlfile not defined (option --sqlfile)\n" if not defined $sqlfile; 
die "tsvfile not defined (option --tsvfile)\n" if not defined $tsvfile; 

#### GET CONF
my $configfile = "$Bin/../../conf/config.yaml";
my $conf = Conf::Yaml->new({
	inputfile 	=> $configfile,
	logfile		=>	$logfile,
	log			=>	2,
	printlog	=>	5
});

my $object = Agua::Workflow->new({
	conf		=>	$conf,
	configfile	=>	$configfile,
	logfile		=>	$logfile,
	log			=>	$log,
	printlog	=>	$printlog
});

$object->loadSamples($username, $project, $table, $sqlfile, $tsvfile);

#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#									SUBROUTINES
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


sub usage
{
    print `perldoc $0`;
	exit;
}
