#!/usr/bin/perl -w

=head2
	
APPLICATION 	MySQL.t

PURPOSE

	Test Agua::DBase::MySQL module
	
NOTES

	1. RUN AS ROOT
	
	2. BEFORE RUNNING, SET ENVIRONMENT VARIABLES, E.G.:
	
		export installdir=/aguadev

=cut

use Test::More 	tests => 7;
use Getopt::Long;
use FindBin qw($Bin);
use lib "$Bin/../../../../lib";
BEGIN {
    my $installdir = $ENV{'installdir'} || "/agua";
    unshift(@INC, "$installdir/lib");
    unshift(@INC, "$installdir/lib/external/lib/perl5");
}

#### CREATE OUTPUTS DIR
my $outputsdir = "$Bin/outputs";
`mkdir -p $outputsdir` if not -d $outputsdir;

BEGIN {
    use_ok('Conf::Yaml');
    use_ok('Test::Agua::DBase::MySQL');
}
require_ok('Conf::Yaml');
require_ok('Test::Agua::DBase::MySQL');

#### SET CONF FILE
my $installdir  =   $ENV{'installdir'} || "/agua";
my $configfile	=   "$installdir/conf/config.yaml";

#### SET $Bin
$Bin =~ s/^.+\/bin/$installdir\/t\/bin/;

#### GET OPTIONS
my $logfile 	= "/tmp/testuser.dbase.mysql.log";
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

my $conf = Conf::Yaml->new(
    inputfile	=>	$configfile,
    backup	    =>	1,
    separator	=>	"\t",
    spacer	    =>	"\\s\+",
    logfile     =>  $logfile,
	showlog     =>  2,
	printlog    =>  5    
);
isa_ok($conf, "Conf::Yaml", "conf");

#### SET DUMPFILE
my $dumpfile    =   "$Bin/../../../../../db/dump/infusion.dump";

#### GET MYSQL ARGS
my $database	=	$conf->getKey("database", "DATABASE");
my $user		=	$conf->getKey("database", "USER");
my $password	=	$conf->getKey("database", "PASSWORD");

my $object = new Test::Agua::DBase::MySQL(
    database    =>  $database,
    user        =>  $user,
    password    =>  $password,
    logfile     =>  $logfile,
    dumpfile    =>  $dumpfile,
	showlog     =>  $showlog,
	printlog    =>  $printlog
);
isa_ok($object, "Test::Agua::DBase::MySQL", "object");

#### METHOD TESTS
$object->testFieldTypes();
$object->testFileFields();
$object->testVerifyFieldType();

#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#                                    SUBROUTINES
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

sub usage {
    print `perldoc $0`;
}

