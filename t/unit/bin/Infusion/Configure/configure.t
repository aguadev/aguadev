#!/usr/bin/perl -w

=head2

APPLICATION     testdatabase.t

PURPOSE         TEST Illumina::WGS::Util:

=cut

#### USE LIBS
use FindBin qw($Bin);
use lib "$Bin/../../../../../lib";

use Test::More  tests => 66638;

#### EXTERNAL MODULES
use Getopt::Long;

#### INTERNAL MODULES
use Test::Illumina::WGS::Util::Configure;

#### SET LOG
my $log     =   2;
my $printlog    =   2;
my $logfile = "$Bin/outputs/sync.log";

#### GET OPTIONS
my $rootpassword;
my $testdatabase;
my $testuser;
my $tableorder  =   "sample,project";  #### FIRST FILES IN REVERSE ORDER
my $help;
GetOptions (
    'log=i'         => \$log,
    'printlog=i'        => \$printlog,
    'rootpassword=s'    => \$rootpassword,
    'testdatabase=s'    => \$testdatabase,
    'testuser=s'        => \$testuser,
    'tableorder=s'      => \$tableorder,
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
$rootpassword = $ENV{'rootpassword'} if not defined $rootpassword or not $rootpassword;
$testdatabase = $ENV{'testdatabase'} if not defined $testdatabase;
$testuser = $ENV{'testuser'} if not defined $testuser;

print "Root password not defined (--rootpassword option)\n" and exit if not defined $rootpassword;

##### RUN AS ROOT
#my $whoami = `whoami`;
#$whoami =~ s/\s+//g;
#print "Must run as root\n" and exit if $whoami ne "root";

#### SET TABLES WHICH MUST BE LOADED FIRST DUE TO DEPENDENCIES (CONSTRAINT/FOREIGN KEY)
my $firsttables;
@$firsttables = split ",", $tableorder;

my $object = Test::Illumina::WGS::Util::Configure->new({
    log			=>	$log,
    printlog        =>  $printlog,
    rootpassword    =>  $rootpassword,
    testdatabase    =>  $testdatabase,
    testuser        =>  $testuser,
    firsttables     =>  $firsttables,
    conf            =>  $conf
});

$object->Test::Illumina::WGS::Util::Configure::testCreateTestDb();
$object->Test::Illumina::WGS::Util::Configure::testCreateTables();
$object->Test::Illumina::WGS::Util::Configure::testLoadTsvFiles();

#### SATISFY Agua::Common::Logger::logError CALL TO EXITLABEL
no warnings;
EXITLABEL : {};
use warnings;

sub usage { `perldoc $0`;   }


