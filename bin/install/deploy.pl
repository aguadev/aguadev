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
 [--SHOWLOG String] \
 [--PRINTLOG String] \
 [--help]

 --mode       :	deploy | bioapps | biorepo | ... options (see below)
 --configfile :	Location of configfile
 --logfile    :	Location of logfile
 --configfile :	Location of *.yaml config file
 --opsrepo    :	Name of ops repo (e.g., biorepodev, default: biorepo)
 --opsfile    :	Location of *.ops file containing configuration information
 --pmfile     :	Location of *.pm file containing installation instructions
 --repository :	Name of Git repository to be used as the code source
 --logfile    :	Location of log file
 --SHOWLOG    :	Print debug and other information to STDOUT (levels 1-5)
 --PRINTLOG   :	Print debug and other information to logfile (levels 1-5)
 --help       :	Print help info

The 'mode' options are as follows:

package		Install a package (must specify with --package option)
aguatest    Install the Agua tests package
bioapps     Install the Bioapps package
biorepo     Install the Biorepository package
sge         Install the SGE (Sun Grid Engine) package
starcluster Install the StarCluster package
deploy      (DEFAULT) Do all of the above

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
use lib "$Bin/../../lib/external/lib/perl5";

#### EXTERNAL MODULES
use Getopt::Long;
use Data::Dumper;

#### INTERNAL MODULES
use Agua::Deploy;
use Agua::DBaseFactory;
use Conf::Yaml;

#### GET OPTIONS
my $mode         =	"deploy";
my $configfile   =	"$Bin/../../conf/config.yaml";
my $opsrepo;
my $opsfile;
my $pmfile;
my $s3bucket;
my $package;
my $version;
my $repository;
my $login;
my $token;
my $keyfile;
my $password;
my $logfile      =	"/tmp/agua-deploy.log";
my $SHOWLOG      =	2;
my $PRINTLOG     =	5;
my $help;
GetOptions (
    'mode=s'        => \$mode,
    'configfile=s'  => \$configfile,
    'opsrepo=s'  	=> \$opsrepo,
    'opsfile=s'  	=> \$opsfile,
    'pmfile=s'  	=> \$pmfile,
    'package=s'  	=> \$package,
    'version=s'  	=> \$version,
    'repository=s'  => \$repository,
    'logfile=s'     => \$logfile,
    'SHOWLOG=i'     => \$SHOWLOG,
    'PRINTLOG=i'    => \$PRINTLOG,
    'help'          => \$help
) or die "No options specified. Try '--help'\n";
usage() if defined $help;

my $conf = Conf::Yaml->new(
    memory      =>  0,
    inputfile   =>  $configfile,
    backup      =>  1,

    SHOWLOG     =>  $SHOWLOG,
    PRINTLOG    =>  $PRINTLOG,
    logfile     =>  $logfile
);


$login 		= 	$ENV{'login'} if defined $ENV{'login'};
$token 		= 	$ENV{'token'} if defined $ENV{'token'};
$keyfile 	= 	$ENV{'keyfile'} if defined $ENV{'keyfile'};
$password 	= 	$ENV{'password'} if defined $ENV{'password'};
#print "deploy.pl    login: $login\n";
#print "deploy.pl    token: $token\n";

my $object = Agua::Deploy->new({
    conf        =>  $conf,
    mode        =>  $mode,
    configfile  =>  $configfile,
    opsrepo  	=>  $opsrepo,
    opsfile  	=>  $opsfile,
    pmfile  	=>  $pmfile,
    package  	=>  $package,
    version  	=>  $version,
    repository  =>  $repository,
    login  		=>  $login,
    token  		=>  $token,
    keyfile  	=>  $keyfile,
    password  	=>  $password,

    SHOWLOG     =>  $SHOWLOG,
    PRINTLOG    =>  $PRINTLOG,
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
    
