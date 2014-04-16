#!/usr/bin/perl -w
use strict;

my $DEBUG = 0;
$DEBUG = 1;

=head2

APPLICATION     install

PURPOSE

    1. INSTALL THE DEPENDENCIES FOR Agua::Install
    
USAGE

sudo ./preinstall.pl [--help]

 --help          :  Print this help info
 
EXAMPLES

sudo install.pl

=cut


#### FLUSH BUFFER
$| = 1;

my $whoami = `whoami`;
if ( not $whoami =~/^root\s*$/ ) {
	print "You must be root to run config.pl\n";
	exit;
}

#### USE LIB
use FindBin qw($Bin);
use lib "$Bin/../../lib";
use lib "$Bin/../../lib/external/lib/perl5";

#### EXTERNAL MODULES
use Getopt::Long;

#### INTERNAL MODULES
use Agua::PreInstall;

#### GET OPTIONS
my $help;
GetOptions (
    'help'          =>  \$help
) or die "No options specified. Try '--help'\n";

#### PRINT HELP IF REQUESTED
if ( defined $help )	{	usage();	}


my $object = Agua::PreInstall->new();


sub usage {
    print `perldoc $0`;
    exit;
}
    
