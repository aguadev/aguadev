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

./gtfuse.pl --uuid 54b4c169-bdef-4d71-99be-f6458d753f1c --gtrepo https://cghub.ucsc.edu


=cut



#### EXTERNAL MODULES
use Term::ANSIColor qw(:constants);
use Data::Dumper;
use Getopt::Long;

#### INTERNAL MODULES
use GT::Fuse;

##### STORE ARGUMENTS TO PRINT TO FILE LATER
my $arguments;
@$arguments = @ARGV;

my $uuid;
my $gtrepo;
my $help;
GetOptions (
    'uuid=s'  	=> \$uuid,
    'gtrepo=s'  		=> \$gtrepo,
    'help'          => \$help
) or die "No options specified. Try '--help'\n";
usage() if defined $help;

print "uuid not defined\n" and exit if not defined $uuid;
print "gtrepo not defined\n" and exit if not defined $gtrepo;

my $object	=	GT::Fuse->new();

$object->mountSample({
	uuid	=>	$uuid,
	gtrepo	=>	$gtrepo
});

##############################################################

sub usage {
	print `perldoc $0`;
	exit;
}
