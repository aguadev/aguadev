#!/usr/bin/perl -w
use strict;

my $DEBUG = 0;
#$DEBUG = 1;

=head2

APPLICATION     deploy

PURPOSE

    1. INSTALL KEY AGUA DEPENDENCIES
    
INPUT

    1. MODE OF ACTION, E.G., deploy, bioapps, biorepo, sge, starcluster

OUTPUT

    MYSQL DATABASE CONFIGURATION AND EDITED CONFIG FILE            

USAGE

sudo ./deploy.pl \
 [--mode String] \ 
 [--configfile String] \ 
 [--logfile String] \ 
 [--s3bucket String] \
 [--opsrepo String] \
 [--opsfile String] \
 [--pmfile String] \
 [--repository String] \
 [--logfile String] \
 [--log String] \
 [--printlog String] \
 [--help]

 --mode       :    deploy | bioapps | biorepo | ... options (see below)
 --configfile :    Location of configfile
 --logfile    :    Location of logfile
 --configfile :    Location of *.yaml config file
 --opsrepo    :    Name of ops repo (e.g., biorepodev, default: biorepo)
 --opsfile    :    Location of *.ops file containing configuration information
 --pmfile     :    Location of *.pm file containing installation instructions
 --repository :    Name of Git repository to be used as the code source
 --logfile    :    Location of log file
 --log    	  :    Print debug and other information to STDOUT (levels 1-5)
 --printlog   :    Print debug and other information to logfile (levels 1-5)
 --help       :    Print help info

The 'mode' options are as follows:

    --mode aguatest    Install the Agua tests package
    --mode bioapps     Install the Bioapps package
    --mode biorepo     Install the Biorepository package
    --mode sge         Install the SGE (Sun Grid Engine) package
    --mode starcluster Install the StarCluster package
    --mode deploy      (DEFAULT) Do all of the above

The --mode option can also be used to install other packages:

    --mode install --package packagename
                       Install the 'packagename' package

Alternately, show the full list of installed packages and the latest versions of available packages:

    --mode list
    
Or, install all of the listed packages:

    --mode all
    
EXAMPLES

Install all dependencies
sudo deploy.pl

Install the Biorepository package ('biorepo')
sudo deploy.pl --mode biorepo

Install the Biorepository package ('biorepo') from the 'biorepodev' repository
sudo deploy.pl --mode biorepo --repository biorepodev


=cut

#### FLUSH BUFFER
$| = 1;

my $whoami = `whoami`;
if ( not $whoami =~/^root\s*$/ ) {
    print "You must be root to run deploy.pl\n";
    exit;
}

#### USE LIB
use FindBin qw($Bin);
use lib "$Bin/../../lib";

#### EXTERNAL MODULES
use Getopt::Long;
use Data::Dumper;

#### INTERNAL MODULES
use Agua::Deploy;
use Agua::DBaseFactory;
use Conf::Yaml;

#### GET OPTIONS
my $mode         =    "deploy";
my $configfile   =    "$Bin/../../conf/config.yaml";
my $opsrepo;
my $opsfile;
my $pmfile;
my $methods;
my $versionfile = "";
my $s3bucket;
my $package;
my $version;
my $repository;
my $login;
my $token;
my $keyfile;
my $password;
my $logfile     =    "/tmp/agua-deploy.log";
my $log          =    2;
my $printlog    =    5;
my $help;
GetOptions (
    'mode=s'        => \$mode,
    'methods=s'      => \$methods,
    'configfile=s'  => \$configfile,
    'opsrepo=s'      => \$opsrepo,
    'opsfile=s'      => \$opsfile,
    'pmfile=s'      => \$pmfile,
    'versionfile=s' => \$versionfile,
    'package=s'      => \$package,
    'version=s'      => \$version,
    'repository=s'  => \$repository,
    'logfile=s'     => \$logfile,
    'log=i'     => \$log,
    'printlog=i'    => \$printlog,
    'help'          => \$help
) or die "No options specified. Try '--help'\n";
usage() if defined $help;

my $conf = Conf::Yaml->new(
    memory      =>  0,
    inputfile   =>  $configfile,
    backup      =>  1,

    log            =>    $log,
    printlog    =>    $printlog,
    logfile     =>  $logfile
);


$login         =     $ENV{'login'} if defined $ENV{'login'};
$token         =     $ENV{'token'} if defined $ENV{'token'};
$keyfile     =     $ENV{'keyfile'} if defined $ENV{'keyfile'};
$password     =     $ENV{'password'} if defined $ENV{'password'};
#print "deploy.pl    login: $login\n";
#print "deploy.pl    token: $token\n";

my $object = Agua::Deploy->new({
    conf        =>  $conf,
    mode        =>  $mode,
    methods      =>  $methods,
    configfile  =>  $configfile,
    opsrepo      =>  $opsrepo,
    opsfile      =>  $opsfile,
    pmfile      =>  $pmfile,
    versionfile =>  $versionfile,
    package      =>  $package,
    version      =>  $version,
    repository  =>  $repository,
    login          =>  $login,
    token          =>  $token,
    keyfile      =>  $keyfile,
    password      =>  $password,

    log            =>    $log,
    printlog    =>    $printlog,
    logfile     =>  $logfile
});

#### CHECK MODE
print "mode not supported: $mode\n" and exit if not $object->can($mode);
print "mode not supported (private method): $mode\n" and exit if $mode =~ /^_/;

#### RUN QUERY
no strict;
eval { $object->$mode() };
if ( $@ ){
    print "Error: $mode): $@\n";
}
print "\nCompleted $0\n";

sub usage {
    print `perldoc $0`;
    exit;
}
    
