#!/usr/bin/perl -w
use strict;

#### DEBUG
my $DEBUG = 0;
#$DEBUG = 1;


=head2

    NAME		loadSampleFiles
    
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
	
		./loadSampleFiles.pl <--username String> <--project String> <--workflow String> <--workflownumber String> <--file String> [-h] 

    --username	  :   Name of user (e.g., admin)
    --project	  :   Name of project (e.g., AlignBams)
    --username	  :   Name of workflow (e.g., loadSamples)
    --username	  :   Number of workflow (e.g., 1)
    --file	  :   Location of *.tsv file
    --help        :   print this help message

	< option > denotes REQUIRED argument
	[ option ] denotes OPTIONAL argument

    EXAMPLE

perl loadSampleFiles.pl --username agua --project AlignBams --workflow loadSamples --workflownumber 1 --file /path/to/data/samplefile.tsv

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
my $workflow;
my $workflownumber;
my $file;	
my $help;
GetOptions (
	'log=i' 		=> \$log,
	'printlog=i' 	=> \$printlog,

	'username=s' 	=> \$username,
	'project=s' 	=> \$project ,
	'workflow=s' 	=> \$workflow,
	'workflownumber=s' => \$workflownumber,
	'file=s' 		=> \$file,
	'help' => \$help) or die "No options specified. Try '--help'\n";
if ( defined $help )	{	usage();	}

#### CHECK INPUTS
die "username not defined (option --username)\n" if not defined $username;
die "project not defined (option --project)\n" if not defined $project;
die "workflow not defined (option --workflow)\n" if not defined $workflow;
die "workflownumber not defined (option --workflownumber)\n" if not defined $workflownumber;
die "file not defined (option --file)\n" if not defined $file; 

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

$object->loadSampleFiles($username, $project, $workflow, $workflownumber, $file);

#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#									SUBROUTINES
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


sub usage
{
    print `perldoc $0`;
	exit;
}
