#!/usr/bin/perl -w

#### DEBUG
my $DEBUG = 0;
#$DEBUG = 1;

=head2 APPLICATION     starcluster.pl
	
PURPOSE

	DRIVE TESTS OF StarCluster.pm, WHICH PERFORMS THE FOLLOWING TASKS:

		1. MOUNT BY DEFAULT /agua, /data AND /nethome ON STARCLUSTER NODES
	
		2. SHUTS DOWN CLUSTER WHEN ALL WORKFLOWS ARE COMPLETED
		
		3. ALLOW USERS TO RUN JOBS ON SMALL, MEDIUM OR LARGE CLUSTERS

		4. RUN ONE CLUSTER FOR EACH PROJECT OR SHARE IT WITH MULTIPLE PROJECTS
		
USAGE
	
	./starcluster.pl <mode> [additional_arguments - SEE Agua API]

EXAMPLE

/data/agua/0.5/bin/apps/cluster/starcluster.pl start \
 --username admin \
 --cluster smallcluster \
 --privatekey /nethome/admin/.keypairs/private.pem \
 --publiccert /nethome/admin/.keypairs/public.pem \
 --keyname admin-key

=cut

use strict;

#### USE LIBS
use FindBin qw($Bin);
use lib "$Bin/../../lib";

my $configfile = "$Bin/../../conf/config.yaml";
my $logfile = "/tmp/agua-starcluster.log";
my $SHOWLOG = 2;
my $PRINTLOG = 5;
use Conf::Yaml;

my $conf = Conf::Yaml->new(
	inputfile	=>	$configfile,
	backup		=>	1,
	separator	=>	"\t",
	spacer		=>	"\\s\+",
	logfile		=>	$logfile,
	SHOWLOG		=>	$SHOWLOG,
	PRINTLOG	=>	$PRINTLOG
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
print "Error - mode not supported: $mode\n" and exit if not $starcluster->can($mode);

eval { $starcluster->$mode() };
if ( $@ ){
	print "Error:\n$@\n";
}

