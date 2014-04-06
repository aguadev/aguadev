#!/usr/bin/perl -w

=head2
	
APPLICATION 	Request.t

PURPOSE

	Test GT::Fuse module
	
NOTES

	1. RUN AS ROOT
	
	2. BEFORE RUNNING, SET ENVIRONMENT VARIABLES, E.G.:
	
		export installdir=/agua/location

=cut

use Test::More 	tests => 20;
use Getopt::Long;
use FindBin qw($Bin);
use lib "$Bin/../../../lib";
BEGIN
{
    my $installdir = $ENV{'installdir'} || "/agua";
    unshift(@INC, "$installdir/lib");
}

#### CREATE OUTPUTS DIR
my $outputsdir = "$Bin/outputs";
`mkdir -p $outputsdir` if not -d $outputsdir;

BEGIN {
    use_ok('Test::GT::Fuse');
}
require_ok('Test::GT::Fuse');

#### SET CONF FILE
my $installdir  =   $ENV{'installdir'} || "/agua";
my $urlprefix  =   $ENV{'urlprefix'} || "agua";

#### SET $Bin
$Bin =~ s/^.+\/bin/$installdir\/t\/unit\/bin/;

#### GET OPTIONS
my $logfile 	= "$Bin/outputs/gtfuse.log";
my $SHOWLOG     =   2;
my $PRINTLOG    =   5;
my $help;
GetOptions (
    'SHOWLOG=i'     => \$SHOWLOG,
    'PRINTLOG=i'    => \$PRINTLOG,
    'logfile=s'     => \$logfile,
    'help'          => \$help
) or die "No options specified. Try '--help'\n";
usage() if defined $help;

my $object = new Test::GT::Fuse(
    logfile     =>  $logfile,
	SHOWLOG     =>  $SHOWLOG,
	PRINTLOG    =>  $PRINTLOG
);
isa_ok($object, "Test::GT::Fuse", "object");

#### TESTS
$object->testGetZombies();
$object->testMount();
$object->testMountSample();

#### SATISFY Agua::Logger::logError CALL TO EXITLABEL
no warnings;
EXITLABEL : {};
use warnings;

#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#                                    SUBROUTINES
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

sub usage {
    print `perldoc $0`;
}

