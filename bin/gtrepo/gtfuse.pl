#!/usr/bin/perl -w


=head2

APPLICATION 	gtfuse

PURPOSE

	1. Set up a GTFuse file mount
	
	2. Clear out any lingering lock, etc. files to ensure the mount succeeds
	
HISTORY

	v0.0.1	Base functionality

USAGE

uuid   	:    UUID of the sample
gtrepo  :    URL of the GTRepo


EXAMPLE

Mount a UUID from CGHub 
./gtfuse.pl --uuid 54b4c169-bdef-4d71-99be-f6458d753f1c 


=cut

#### USE LIBS
use FindBin qw($Bin);

#### USE LIBRARY
use lib "$Bin/../../lib";	
use lib "$Bin/../../lib/external";	

#### EXTERNAL MODULES
use Term::ANSIColor qw(:constants);
use Data::Dumper;
use Getopt::Long;

#### INTERNAL MODULES
use GT::Fuse;

##### STORE ARGUMENTS TO PRINT TO FILE LATER
my $arguments;
@$arguments = @ARGV;
my $SHOWLOG 	=	2;
my $PRINTLOG	=	5;
my $unmount;
my $uuid;
my $gtrepo;
my $keyfile;
my $help;
my $logfile		=	"/tmp/gtfuse-$$.log";
GetOptions (
    'u'  			=> 	\$unmount,
    'uuid=s'  		=> 	\$uuid,
    'gtrepo=s'  	=> 	\$gtrepo,
    'keyfile=s'  	=> 	\$keyfile,
    'help'          => \$help,
    'SHOWLOG=i'     => \$SHOWLOG,
    'PRINTLOG=i'    => \$PRINTLOG,
) or die "No options specified. Try '--help'\n";
usage() if defined $help;

print "uuid not defined\n" and exit if not defined $uuid;

my $object	=	GT::Fuse->new({
	keyfile		=>	$keyfile,
	logfile		=>	$logfile,
    SHOWLOG     =>  $SHOWLOG,
    PRINTLOG    =>  $PRINTLOG,
});

$object->mountSample($uuid, $gtrepo) if not defined $unmount;
$object->unmountSample($uuid) if defined $unmount;

##############################################################

sub usage {
	print `perldoc $0`;
	exit;
}
