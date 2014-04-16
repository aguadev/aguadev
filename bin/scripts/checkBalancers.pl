#!/usr/bin/perl -w
use strict;

my $DEBUG = 0;
$DEBUG = 1;

=head2

APPLICATION     checkBalancers

PURPOSE

    MONITOR THE LOAD BALANCERS RUNNING ON EACH CLUSTER (I.E., SGE CELL)
    
    AND RESTART THEM IF THEY BECOME INACTIVE (E.G., DUE TO A RECURRENT
    
    ERROR IN STARCLUSTER WHEN PARSING XML OUTPUT AND/OR XML ERROR MESSAGES
    
    CAUSED BY A BUG IN SGE)

NOTES    

    1. CRON JOB RUNS THIS SCRIPT EVERY MINUTE
    
    * * * * * /agua/0.6/bin/scripts/checkBalancers.pl --logfile /tmp/checkbalancers.out
    
    2. CHECKS clusterstatus DATABASE TABLE FOR RUNNING CLUSTERS
    
    3. FOR RUNNING CLUSTERS, CHECKS IF LOCK FILE IS OLDER THAN 1 MINUTE
    
    4. IF LOCK FILE STALE, RESTART bal FOR THE CLUSTER:
        
        -   KILL PREVIOUS PROCESS USING PID IN PID FILE
        
        -   START bal: STORE PID IN PID FILE, CONCAT OUTPUT TO OUTPUT FILE

USAGE

./checkBalancers.pl [--help]

--help      :   Print help info

EXAMPLES

checkBalancers.pl

=cut

#### FLUSH BUFFER
$| = 1;

#### USE LIB
use FindBin qw($Bin);
use lib "$Bin/../../lib";
use lib "$Bin/../../lib/external/lib/perl5";

#### EXTERNAL MODULES
use Getopt::Long;
use Data::Dumper;

#### INTERNAL MODULES
use Agua::Balancer;
use Conf;
use Conf::Yaml;

#### SET CONF OBJECT
my $conf = Conf::Yaml->new(
	inputfile	=>	"$Bin/../../conf/config.yaml",
	backup		=>	1,
	separator	=>	"\t",
	spacer		=>	"\\s\+"
);

my $tempdir = $conf->getKey('agua', 'TEMPDIR');
print "checkBalancers.pl    tempdir: $tempdir\n";
my $logfile = "$tempdir/checkbalancers.out";
print "checkBalancers.pl    logfile: $logfile\n";
open(STDOUT, ">>$logfile") or die "Can't redirect STDOUT to logfile: $logfile\n" if defined $logfile;
open(STDERR, ">>$logfile") or die "Can't redirect STDERR to logfile: $logfile\n" if defined $logfile;

#### PRINT DATE
print "setHostname.pl    Started: ";
print `date`;


#### GET OPTIONS
my $help;
GetOptions (
    'help'          => \$help
) or die "No options specified. Try '--help'\n";

#### CHECK BALANCERS
my $balancer = Agua::Balancer->new(
    {
        conf        =>  $conf
    }
);
$balancer->checkBalancers();
print "\nCompleted $0\n";
print `date`;

sub usage {
    print `perldoc $0`;
}
    


