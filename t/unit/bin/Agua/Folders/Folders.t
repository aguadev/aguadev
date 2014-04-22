#!/usr/bin/perl -w

use Test::More  tests => 22;
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

#### INTERNAL MODULES
use Test::Agua::Folders;
use Conf::Yaml;

#### SET CONF FILE
my $installdir  =   $ENV{'installdir'} || "/agua";
my $configfile  =   "$installdir/conf/config.yaml";

#### SET $Bin
$Bin =~ s/^.+t\/bin/$installdir\/t\/bin/;

#### SET DUMPFILE
my $dumpfile    =   "$Bin/../../../dump/create.dump";

#### SET LOG
my $showlog     =   2;
my $printlog    =   5;
my $logfile = "$Bin/outputs/sync.log";

#### GET OPTIONS
my $login;
my $owner;
my $username = "syoung";
my $token;
my $keyfile;
my $help;
GetOptions (
    'showlog=i'     => \$showlog,
    'printlog=i'    => \$printlog,
    'login=s'       => \$login,
    'owner=s'       => \$owner,
    'username=s'    => \$username,
    'token=s'       => \$token,
    'keyfile=s'     => \$keyfile,
    'help'          => \$help
) or die "No options specified. Try '--help'\n";
usage() if defined $help;

#### LOAD LOGIN, ETC. FROM ENVIRONMENT VARIABLES
$login = $ENV{'login'} if not defined $login or not $login;
$token = $ENV{'token'} if not defined $token;
$keyfile = $ENV{'keyfile'} if not defined $keyfile;

my $conf = Conf::Yaml->new(
    memory      =>  1,
    inputfile	=>	$configfile,
    showlog     =>  2,
    printlog    =>  2,
    logfile     =>  $logfile
);

my $object = new Test::Agua::Folders(
    showlog     =>  $showlog,
    printlog    =>  $printlog,
    logfile     =>  $logfile,
    dumpfile    =>  $dumpfile,
    conf        =>  $conf,

    login       =>  $login,
    token       =>  $token,
    keyfile     =>  $keyfile
);

#### START LOG AFRESH
$object->startLog($object->logfile());

#### TEST RENAME WORKFLOW
$object->testJsonSafe();

##### TEST RENAME WORKFLOW
$object->testRenameWorkflow();

#### CLEAN UP
`rm -fr $Bin/outputs/*`;

#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#                                    SUBROUTINES
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

sub usage {
    print `perldoc $0`;
}

