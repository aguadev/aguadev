#!/usr/bin/perl -w
use strict;

my $DEBUG = 0;
#$DEBUG = 1;

=head2

APPLICATION     config

PURPOSE

    1. CONFIGURE THE Agua DATABASE AND LOAD TABLES AND SKELETON DATA
    
    2. CONFIGURE CRON JOB TO CHECK LOAD BALANCER
    
    3. ADD 'admin' USER TO AGUA DATABASE
    
    4. FIX /etc/fstab TO ALLOW EC2 MICRO INSTANCES TO REBOOT PROPERLY
        
INPUT

    1. MODE OF ACTION, E.G., admin, config, cron

OUTPUT

    MYSQL DATABASE CONFIGURATION AND EDITED CONFIG FILE            

USAGE

sudo ./config.pl <--mode String> \ 
 [--key String] \ 
 [--value String] \ 
 [--help]

 --mode      :    admin | config | cron | ... (see below)
 --database  :    Name of database
 --configfile:    Location of configfile
 --logfile   :    Location of logfile
 --help      :    Print help info

The 'mode' options are as follows:

adminUser       Create the Linux user account for the Agua admin user 

cron            Configure a cron job to monitor the StarCluster
                load balancer

disableSsh      Disable SSH password login

enableSsh       Enable SSH password login

fixFstab        Edit /etc/fstab to enable reboot for micro instances

mysql           Run following: setMysqlRoot, setAguaUser,
                setTestUser, reloadDatabase

reloadDatabase  Reload Agua MySQL database from dump file (backs up
                existing data)

setAguaUser     Set Agua MySQL user name and password

setMysqlRoot    Set MySQL root user password

setTestUser     Set Agua test MySQL user name and password

testUser        Create the Linux user account for the Agua test user 


The config option is the default:

config          Do all of the above (default)


EXAMPLES

sudo config.pl --mode mysql --database agua

=cut

#### FLUSH BUFFER
$| = 1;

my $whoami = `whoami`;
if ( not $whoami =~/^root\s*$/ ) {
	print "You must be root to run config.pl\n";
	exit;
}

#### USE LIB
use FindBin qw($Bin);
use lib "$Bin/../../lib";

#### EXTERNAL MODULES
use Getopt::Long;
use Data::Dumper;

#### INTERNAL MODULES
use Agua::Configure;
use Agua::DBaseFactory;
use Conf::Yaml;

#### GET OPTIONS
my $dumpfile     = "$Bin/../sql/dump/agua.dump";
my $mode         = "config";
my $database;
my $configfile   = "$Bin/../../conf/config.yaml";
my $logfile      = "/tmp/agua-config.log";
my $SHOWLOG      =    2;
my $PRINTLOG     =    5;
my $help;
GetOptions (
    'mode=s'        => \$mode,
    'database=s'    => \$database,
    'configfile=s'  => \$configfile,
    'dumpfile=s'    => \$dumpfile,
    'logfile=s'     => \$logfile,
    'SHOWLOG=i'     => \$SHOWLOG,
    'PRINTLOG=i'    => \$PRINTLOG,
    'help'          => \$help
) or die "No options specified. Try '--help'\n";
usage() if defined $help;

my $conf = Conf::Yaml->new(
    memory      =>  1,
    inputfile   =>  $configfile,
    backup      =>  1,
    SHOWLOG     =>  2,
    PRINTLOG    =>  2,
    logfile     =>  $logfile
);

my $object = Agua::Configure->new({
    conf        =>  $conf,
    mode        =>  $mode,
    database    =>  $database,
    configfile  =>  $configfile,
    logfile     =>  $logfile,
    dumpfile    =>  $dumpfile,
    SHOWLOG     =>  $SHOWLOG,
    PRINTLOG    =>  $PRINTLOG
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
    
