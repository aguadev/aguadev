#!/usr/bin/perl -w

=head2
	
APPLICATION 	Upload.t

PURPOSE

	Test Agua::Upload module
	
NOTES

	1. RUN AS ROOT
	
	2. BEFORE RUNNING, SET ENVIRONMENT VARIABLES, E.G.:
	
		export installdir=/aguadev

=cut

use Test::More 	tests => 32;
use Getopt::Long;
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
    use_ok('Test::Agua::Upload');
}
require_ok('Conf::Yaml');
require_ok('Test::Agua::Upload');

#### SET CONF FILE
my $installdir  =   $ENV{'installdir'} || "/agua";
my $configfile	=   "$installdir/conf/config.yaml";

#### SET $Bin
$Bin =~ s/^.+\/bin/$installdir\/t\/bin/;

#### GET OPTIONS
my $logfile 	= "/tmp/testuser.upload.log";
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
    backup	    =>	0,
    memory	    =>	1,
    separator	=>	"\t",
    spacer	    =>	"\\s\+",
    logfile     =>  $logfile,
	SHOWLOG     =>  2,
	PRINTLOG    =>  2    
);
isa_ok($conf, "Conf::Yaml", "conf");

#### SET DUMPFILE
my $dumpfile    =   "$Bin/../../../../db/dump/infusion.dump";

my $uploader = new Test::Agua::Upload(
    dumpfile    =>  $dumpfile,
    conf        =>  $conf,
    json        =>  {
        username    =>  'syoung'
    },
    username    =>  "test",
    project     =>  "Project1",
    uploader    =>  "Workflow1",
    logfile     =>  $logfile,
	SHOWLOG     =>  $SHOWLOG,
	PRINTLOG    =>  $PRINTLOG
);
isa_ok($uploader, "Test::Agua::Upload", "uploader");

#### METHOD TESTS
$uploader->testSetData();
$uploader->testNextData();
$uploader->testGetBoundary();
$uploader->testParseFilename();
$uploader->testPrintTempfile();
$uploader->testParseParams();
$uploader->testNotifyStatus();

#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#                                    SUBROUTINES
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

sub usage {
    print `perldoc $0`;
}

