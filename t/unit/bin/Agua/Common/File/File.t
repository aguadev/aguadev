#!/usr/bin/perl -w

use Test::More 	tests => 3;
use Getopt::Long;

use FindBin qw($Bin);
use lib "$Bin/../../../../lib";
BEGIN
{
    my $installdir = $ENV{'installdir'} || "/agua";
    unshift(@INC, "$installdir/lib");
    unshift(@INC, "$installdir/lib/external/lib/perl5");
}

#### CREATE OUTPUTS DIR
my $outputsdir = "$Bin/outputs";
`mkdir -p $outputsdir` if not -d $outputsdir;


BEGIN {
    use_ok('Test::Agua::Common::File');
}
require_ok('Test::Agua::Common::File');

#### SET CONF FILE
my $installdir  =   $ENV{'installdir'} || "/agua";
my $configfile    =   "$installdir/conf/config.yaml";

#### SET $Bin
$Bin =~ s/^.+t\/bin/$installdir\/t\/bin/;

my $logfile     =   "$Bin/outputs/file.log";
my $SHOWLOG     =   2;
my $PRINTLOG    =   5;
my $help;
GetOptions (
    'SHOWLOG=i'     => \$SHOWLOG,
    'PRINTLOG=i'    => \$PRINTLOG,
    'help'          => \$help
) or die "No options specified. Try '--help'\n";
usage() if defined $help;

my $conf = Conf::Yaml->new(
	inputfile	=>	$configfile,
	backup		=>	1,
	separator	=>	"\t",
	spacer		=>	"\\s\+",
    logfile     =>  $logfile,
    SHOWLOG     =>  $SHOWLOG,
    PRINTLOG    =>  $PRINTLOG
);

my $username	=	$conf->getKey("database", "TESTUSER");

my $object = Test::Agua::Common::File->new(
    conf        =>  $conf,
    logfile     =>  $logfile,
    SHOWLOG     =>  $SHOWLOG,
    PRINTLOG    =>  $PRINTLOG,
	username	=>	$username
);
isa_ok($object, "Test::Agua::Common::File");


###### TO DO :
##$object->testFileJson();

#### ONWORKING checkEbwt
#$object->testCheckEbwt();

#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#                                    SUBROUTINES
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

sub usage {
    print `perldoc $0`;
}

