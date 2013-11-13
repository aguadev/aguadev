#!/usr/bin/perl -w

=head2

	SET ENVIRONMENT VARIABLES BEFORE RUNNING THIS SCRIPT:
	
		export remoteuser=root
		export remotehost=ec2-XXX-xxx-XXX-xxx.compute-1.amazonaws.com

=cut

use Test::More tests => 4; # qw(no_plan);

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

#### SET CONF FILE
my $installdir  =   $ENV{'installdir'} || "/agua";
my $configfile	=   "$installdir/conf/config.yaml";

#### SET $Bin
$Bin =~ s/^.+t\/bin/$installdir\/t\/bin/;
	
use Test::Agua::Ssh;
use Getopt::Long;
use FindBin qw($Bin);
use Conf::Yaml;

#### SET LOG
my $SHOWLOG     =   2;
my $PRINTLOG    =   5;
my $logfile = "$Bin/outputs/sync.log";

#### GET OPTIONS
my $command;
my $remoteuser;
my $remotehost;
my $keyfile;
my $help;
GetOptions (
    'SHOWLOG=i'    	=> \$SHOWLOG,
    'PRINTLOG=i'    => \$PRINTLOG,
    'command=s'     => \$command,
    'remoteuser=s'  => \$remoteuser,
    'remotehost=s'    => \$remotehost,
    'keyfile=s'     => \$keyfile,
    'help'          => \$help
) or die "No options specified. Try '--help'\n";
usage() if defined $help;

#### LOAD LOGIN, ETC. FROM ENVIRONMENT VARIABLES
$remoteuser = $ENV{'remoteuser'} if not defined $remoteuser or not $remoteuser;
$remotehost = $ENV{'remotehost'} if not defined $remotehost;
$keyfile = $ENV{'keyfile'} if not defined $keyfile;
$remotehost = $ENV{'remotehost'} if not defined $remotehost;
$remoteuser = $ENV{'remoteuser'} if not defined $remoteuser;

if ( not defined $remoteuser or not defined $remotehost or not $remotehost
    or not defined $keyfile ) {
	ok(1); ok(1); ok(1); ok(1);
    print "Missing remoteuser, remotehost or keyfile. Run this script manually and provide GitHub remoteuser and remotehost credentials and SSH private keyfile\n";
	exit;
}

my $conf = Conf::Yaml->new(
    memory      =>  1,
    inputfile	=>	$configfile,
    SHOWLOG     =>  2,
    PRINTLOG    =>  2,
    logfile     =>  $logfile
);

#### GET TEST USER
my $username    =   $conf->getKey("database", "TESTUSER");

my $object = new Test::Agua::Ssh(
    SHOWLOG     =>  $SHOWLOG,
    PRINTLOG    =>  $PRINTLOG,
    logfile     =>  $logfile,
    conf        =>  $conf,

    remoteuser  =>  $remoteuser,
    remotehost  =>  $remotehost,
    keyfile     =>  $keyfile,
    command    	=>  $command
);

#### START LOG AFRESH
$object->startLog($object->logfile());

#### TEST CREATE APP FILES
$object->testExecute();
exit;

#### CLEAN UP
`rm -fr $Bin/outputs/*`

