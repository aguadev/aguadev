#!/usr/bin/perl -w

=head2

APPLICATION     dumper.t

PURPOSE         TEST Infusion::Common::Login

=cut

#### USE LIBS
use FindBin qw($Bin);
use lib "$Bin/../../../../lib";
use lib "$Bin/../../../../../lib";

#### EXTERNAL MODULES
use Getopt::Long;
use Test::More  tests => 2;

#### INTERNAL MODULES
use Test::Infusion::Common::Login;

#### SET LOG
my $log     =   2;
my $printlog    =   5;
my $logfile     =   "$Bin/outputs/sync.log";
my $testpassword;
my $testuser;

#### GET OPTIONS
my $help;
GetOptions (
    'log=i'         => \$log,
    'printlog=i'        => \$printlog,
    'testpassword=s'    => \$testpassword,
    'testuser=s'        => \$testuser,
    'help'              => \$help
) or die "No options specified. Try '--help'\n";
usage() if defined $help;

#### GET CONF
my $configfile = "$Bin/../../../../../conf/config.yaml";
my $conf = Conf::Yaml->new({
    configfile	=>  $configfile,
    backup	    =>  1,
    log			=>	$log,
    printlog    =>  $printlog    
});

#### LOAD LOGIN, ETC. FROM ENVIRONMENT VARIABLES
$testpassword = $ENV{'testpassword'} if not defined $testpassword or not $testpassword;
$testuser = $ENV{'testuser'} if not defined $testuser;

my $object = Test::Infusion::Common::Login->new({
    log			=>	$log,
    printlog        =>  $printlog,
    testpassword    =>  $testpassword,
    testuser        =>  $testuser,
    logfile         =>  $logfile,
    conf            =>  $conf
});

$object->testLdapAuthentication();

sub usage { `perldoc $0`;   }

