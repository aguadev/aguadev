#!/usr/bin/perl -w

=head2

NAME		Configure.t

PURPOSE		DRIVE TESTS OF Agua::Configure

	NB: THIS SCRIPT MUST BE RUN AS ROOT OR CHMODDED:

		chmod 4755 Configure.t; chown root Configure.t

USAGE		./Configure.t [Int --log] [Int --printlog]
                            [String logfile] [--help]

		--log		Displayed log level (1-5)	
		--printlog		Logfile log level (1-5)	
		--logfile		Location of logfile
		--help			Show this message
=cut

#### EXTERNAL MODULES
use Test::More tests => 4;
use Getopt::Long;

use FindBin qw($Bin);
use lib "$Bin/../../../lib";
BEGIN
{
    my $installdir = $ENV{'installdir'} || "/agua";
    unshift(@INC, "$installdir/lib");
    unshift(@INC, "$installdir/lib/external/lib/perl5");
}

#### CREATE OUTPUTS DIR
my $outputsdir = "$Bin/outputs";
`mkdir -p $outputsdir` if not -d $outputsdir;

#### SET CONF FILE
my $installdir  =   $ENV{'installdir'} || "/agua";
my $configfile  =   "$installdir/conf/config.yaml";

#### SET $Bin
$Bin =~ s/^.+bin/$installdir\/t\/bin/;

#### INTERNAL MODULES
use Test::Agua::Configure;
use Conf::Yaml;

#### CHECK ROOT
my $whoami = `whoami` || '';
$whoami =~ s/\s+//;
if ( $whoami ne "root" ) {
    print "You must run this script as root\n";
	ok(1, "Quitting");
	done_testing(1);
	exit;
}

#### GET OPTIONS
my $log     =   2;
my $printlog    =   5;
my $help;
GetOptions (
    'log=i'     => \$log,
    'printlog=i'    => \$printlog,
    'help'          => \$help
) or die "No options specified. Try '--help'\n";
usage() if defined $help;


my $logfile = "$Bin/outputs/configure.log";

my $conf = Conf::Yaml->new(
    memory      =>  1,
    inputfile	=>	$configfile,
	backup		=>	1,
    log     =>  2,
    printlog    =>  2,
    logfile     =>  $logfile
);

my $object = new Test::Agua::Configure(
    log			=>	$log,
    printlog    =>  $printlog,
    logfile     =>  $logfile,
    conf        =>  $conf
);

### TEST enableSsh
$object->testEnableSsh();

### TEST disableSsh
$object->testDisableSsh();

#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#                                    SUBROUTINES
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

sub usage {
    print `perldoc $0`;
}




