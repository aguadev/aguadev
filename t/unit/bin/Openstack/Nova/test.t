#!/usr/bin/perl -w

=head2
	
APPLICATION 	test.t

PURPOSE

	Test Openstack::Nova module
	
NOTES

	1. RUN AS ROOT
	
	2. BEFORE RUNNING, SET ENVIRONMENT VARIABLES, E.G.:
	
		export installdir=/agua/location

=cut

use Test::More 	tests => 10;
use Getopt::Long;
use FindBin qw($Bin);
use lib "$Bin/../../../../../lib";	#### PACKAGE MODULES
use lib "$Bin/../../../lib";		#### TEST MODULES
BEGIN
{
    my $installdir = $ENV{'installdir'} || "/agua";
    unshift(@INC, "$installdir/lib");
}

#### CREATE OUTPUTS DIR
my $outputsdir = "$Bin/outputs";
`mkdir -p $outputsdir` if not -d $outputsdir;

BEGIN {
	use_ok('Test::Openstack::Nova');
	use_ok('Test::Openstack::Nova::Ips');
}
require_ok('Test::Openstack::Nova');
require_ok('Test::Openstack::Nova::Ips');

#### SET CONF FILE
my $installdir  =   $ENV{'installdir'} || "/agua";
my $urlprefix  	=   $ENV{'urlprefix'} || "agua";

#### GET OPTIONS
my $logfile 	= 	"$Bin/outputs/gtfuse.log";
my $showlog     =   2;
my $printlog    =   5;
my $help;
GetOptions (
    'showlog=i'     => \$showlog,
    'printlog=i'    => \$printlog,
    'logfile=s'     => \$logfile,
    'help'          => \$help
) or die "No options specified. Try '--help'\n";
usage() if defined $help;

my $object1 = new Test::Openstack::Nova(
    logfile     =>  $logfile,
	showlog     =>  $showlog,
	printlog    =>  $printlog
);
isa_ok($object1, "Test::Openstack::Nova", "object1");

#### TESTS
$object1->testParseLine();
$object1->testParseList();
#$object1->testGetExports();
$object1->testParseVolumeId();

my $object2 = new Test::Openstack::Nova::Ips(
    logfile     =>  $logfile,
	showlog     =>  $showlog,
	printlog    =>  $printlog
);
isa_ok($object2, "Test::Openstack::Nova::Ips", "object2");

#### TESTS
$object2->testGetIps();

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

