#!/usr/bin/perl -w

#### DEBUG
my $DEBUG = 0;
#$DEBUG = 1;

=head2

APPLICATION     starcluster.pl
	
PURPOSE

	DRIVE TESTS OF StarCluster.pm, WHICH PERFORMS THE FOLLOWING TASKS:

		1. MOUNT BY DEFAULT /agua, /data AND /nethome ON STARCLUSTER NODES
	
		2. SHUT DOWN CLUSTER WHEN ALL WORKFLOWS ARE COMPLETED
		
		3. ALLOW USERS TO RUN JOBS ON SMALL, MEDIUM OR LARGE CLUSTERS

		4. RUN ONE CLUSTER FOR EACH PROJECT OR SHARE IT WITH MULTIPLE PROJECTS
		
USAGE
	
	./starcluster.pl <mode> [additional_arguments - SEE Agua API]

EXAMPLE

./starcluster.pl start \
 --username admin \
 --cluster smallcluster \
 --privatekey /nethome/admin/.keypairs/private.pem \
 --publiccert /nethome/admin/.keypairs/public.pem \
 --keyname admin-key

=cut

use strict;

#### USE LIBS
use FindBin qw($Bin);
use lib "$Bin/../../../lib/";

my $configfile = "$Bin/../../../conf/default.conf";
my $logfile = "/tmp/agua-starcluster.log";
my $log = 2;
my $printlog = 5;
use Conf::Agua;
my $conf = Conf::Agua->new(
	inputfile	=>	$configfile,
	backup		=>	1,
	separator	=>	"\t",
	spacer		=>	"\\s\+",
	logfile		=>	$logfile,
	log			=>	$log,
	printlog	=>	$printlog
);

#### INTERNAL MODULES
use Agua::StarCluster;
my $starcluster = Agua::StarCluster->new(
	conf 		=>	$conf
);

#### GET MODE AND ARGUMENTS
my @arguments = @ARGV;
my $mode = shift @ARGV;

#### PRINT HELP
if ( $mode eq "-h" or $mode eq "--help" )	{	help();	}

#### FLUSH BUFFER
$| =1;

#### RUN QUERY
no strict;
eval { $starcluster->$mode() };
if ( $@ ){
	print "Error - mode '$mode' might not be supported\nDetailed error output:\n$@\n";
}

