#!/usr/bin/perl -w

=head2
	
APPLICATION 	Installer.t

PURPOSE

	Test Agua::Installer module
	
NOTES

	1. RUN AS ROOT
	
	2. BEFORE RUNNING, SET ENVIRONMENT VARIABLES, E.G.:
	
export installdir=/aguadev
export urlprefix=aguadev

=cut

use Test::More 	tests => 8;
use Getopt::Long;
use YAML::Tiny;
use FindBin qw($Bin);
use lib "$Bin/../../../lib";


BEGIN {
	print "\n\nMUST SET installdir ENVIRONMENT VARIABLE BEFORE RUNNING TESTS\n\n" and exit if not defined $ENV{'installdir'};
    my $installdir = $ENV{'installdir'};
    unshift(@INC, "$installdir/lib");
    unshift(@INC, "$installdir/lib/external/lib/perl5");
}

#### CREATE OUTPUTS DIR
my $outputsdir = "$Bin/outputs";
`mkdir -p $outputsdir` if not -d $outputsdir;

BEGIN {
    use_ok('Conf::Yaml');
    use_ok('Test::Agua::Installer');
}
use_ok('Conf::Yaml');
require_ok('Test::Agua::Installer');

#### SET CONF FILE
my $installdir  =   $ENV{'installdir'} || "/agua";
my $urlprefix  =   $ENV{'urlprefix'} || "agua";
my $configfile	=   "$installdir/conf/config.yaml";
print "Installer.t    configfile: $configfile\n";

#### SET $Bin
$Bin =~ s/^.+\/bin/$installdir\/t\/bin/;

#### GET OPTIONS
my $logfile 	= 	"$Bin/outputs/installer.log";
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

my $conf = Conf::Yaml->new(
    inputfile	=>	$configfile,
    backup	    =>	1,
    separator	=>	"\t",
    spacer	    =>	"\\s\+",
    logfile     =>  $logfile,
	SHOWLOG     =>  2,
	PRINTLOG    =>  5    
);
isa_ok($conf, "Conf::Yaml", "conf");

my $installer = new Test::Agua::Installer({
	installdir	=>	$installdir,
	urlprefix	=>	$urlprefix,
    conf        =>  $conf
});
isa_ok($installer, "Test::Agua::Installer", "Installer");

#### METHOD TESTS
#$installer->testSetRabbitMqKey();
#$installer->testInstallRabbitMq();
$installer->testStopRabbitMq();
$installer->testStartRabbitMq();
#$installer->testInstallExchange();

#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#                                    SUBROUTINES
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

sub usage {
    print `perldoc $0`;
}

