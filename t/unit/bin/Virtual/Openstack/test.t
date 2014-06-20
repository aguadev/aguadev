#!/usr/bin/perl -w

=head2
	
APPLICATION 	test.t

PURPOSE

	Test Virtual::Openstack module
	
NOTES

	1. RUN AS ROOT
	
	2. BEFORE RUNNING, SET ENVIRONMENT VARIABLES, E.G.:
	
		source /my/envars.sh
		
	REQUIRED ENVIRONMENT VARIABLES ARE:
	
		ospassword, osauthurl, ostenantid, ostenantname, osusername

=cut

use Test::More 	tests =>	17;
use Getopt::Long;
use FindBin qw($Bin);
BEGIN
{
    my $installdir = $ENV{'installdir'} || "/agua";
    unshift(@INC, "$installdir/lib");
    unshift(@INC, "$installdir/t/common/lib");
    unshift(@INC, "$installdir/t/unit/lib");
}

BEGIN {
    use_ok('Test::Virtual::Openstack');
    #use_ok('Test::Virtual::Openstack::Nova');
}
require_ok('Test::Virtual::Openstack');
#require_ok('Test::Virtual::Openstack::Nova');

#### SET CONF FILE
my $installdir  =   $ENV{'installdir'} || "/agua";
my $urlprefix  	=   $ENV{'urlprefix'} || "agua";
my $ospassword	=	$ENV{'ospassword'};
my $osauthurl	=	$ENV{'osauthurl'};
my $ostenantid	=	$ENV{'ostenantid'};
my $ostenantname=	$ENV{'ostenantname'};
my $osusername	=	$ENV{'osusername'};
my $keypair		=	$ENV{'keypair'};

#### SET $Bin
$Bin =~ s/^.+\/unit\/bin/$installdir\/t\/unit\/bin/;

#### GET OPTIONS
my $logfile 	= "$Bin/outputs/test.log";
my $log     	=   2;
my $printlog    =   5;
my $help;
GetOptions (
    'log=i'     	=> \$log,
    'printlog=i'    => \$printlog,
    'logfile=s'     => \$logfile,
    'help'          => \$help
) or die "No options specified. Try '--help'\n";
usage() if defined $help;

my $configfile	=	"$installdir/conf/config.yaml";
my $conf	=	Conf::Yaml->new({
	inputfile	=>	$configfile,
	log			=>	$log,
	printlog	=>	$printlog
});

my $dumpfile	=	"$installdir/bin/sql/dump/agua/create-agua.dump";
my $object1 = new Test::Virtual::Openstack(
	conf		=>	$conf,
    logfile     =>  $logfile,
    dumpfile    =>  $dumpfile,
	log			=>	$log,
	printlog    =>  $printlog
);
isa_ok($object1, "Test::Virtual::Openstack", "object1");

#### AUTOMATED
$object1->testLaunchNode();
$object1->testParseNovaBoot();
$object1->testParseNovaList();
$object1->testDeleteNode();

#my $object2 = new Test::Virtual::Openstack::Nova(
#
#	ospassword	=>	$ospassword,
#	osauthurl	=>	$osauthurl,
#	ostenantid	=>	$ostenantid,
#	ostenantname=>	$ostenantname,
#	osusername	=>	$osusername,
#
#	conf		=>	$conf,
#    logfile     =>  $logfile,
#    dumpfile    =>  $dumpfile,
#	log			=>	$log,
#	printlog    =>  $printlog
#);
#isa_ok($object2, "Test::Virtual::Openstack::Nova", "object2");

#$object2->testNova();



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

