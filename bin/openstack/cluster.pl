#!/usr/bin/env perl

use warnings;

=head2

APPLICATION 	cluster

PURPOSE

	1. Send SSH commands to VMs (filtered by name or pattern)

	2. List VMs (filtered by name or pattern)
	
HISTORY

	v0.01	Basic wrappers around nova and cinder API clients

USAGE

$0 <--mode (command|list)> [--regex String] [--name String] [--command String]

NB: --regex option takes precedence over --name option

=cut

#print `perl -V`;

#### EXTERNAL MODULES
use Term::ANSIColor qw(:constants);
use Getopt::Long;
use FindBin qw($Bin);

#### USE LIBRARY
use lib "$Bin/../../lib";	
BEGIN {
    my $installdir = $ENV{'installdir'} || "/agua";
    unshift(@INC, "$installdir/lib");
}

#### INTERNAL MODULES
use Conf::Yaml;
use Openstack::Nova;

my $installdir = $ENV{'installdir'} || "/agua";
my $configfile	=	"$installdir/conf/config.yaml";

my $mode		=	"command";
my $username	=	"ubuntu";
my $name;
my $regex;
my $command;
my $log		=	2;
my $printlog	=	2;
my $logfile		=	"/tmp/pancancer-volume.$$.log";
my $help;
GetOptions (
    'mode=s'		=> \$mode,
    'username=s'	=> \$username,
    'name=s'		=> \$name,
    'regex=s'		=> \$regex,
    'command=s'		=> \$command,
    'log=i'     => \$log,
    'printlog=i'    => \$printlog,
    'help'          => \$help
) or die "No options specified. Try '--help'\n";
usage() if defined $help;

#### SUPPORTED MODES
print "Mode not defined\n" and usage() if not defined $mode;
print "Mode not supported: $mode\n" and exit if $mode !~ /(command|list)/;

my $conf = Conf::Yaml->new(
    memory      =>  0,
    inputfile   =>  $configfile,
    backup      =>  1,

    log			=>	$log,
    printlog	=>	$printlog,
    logfile     =>  $logfile
);

my $object = Openstack::Nova->new({
	conf		=>	$conf,
    log			=>	$log,
    printlog	=>	$printlog,
    logfile     =>  $logfile
});

$object->$mode({
	name		=>	$name,
	username	=>	$username,
	command		=>	$command,
	regex		=>	$regex
});

exit 0;

##############################################################

sub usage {
	print `perldoc $0`;
	exit;
}

