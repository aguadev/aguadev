#!/usr/bin/perl -w
use strict;

#my $LOG = 0;
#$LOG = 1;

=head2

APPLICATION     updateHostname

PURPOSE

    RUN THIS AFTER REBOOT TO:
	
		1. SET HEADNODE HOSTNAME TO NEW INTERNAL DNS NAME

		2. UPDATE HOSTNAME IN CLUSTERS
		
			- REMOVE OLD HOSTNAME AS ADMIN/SUBMIT HOST
			
			- ADD NEW HOSTNAME AS ADMIN/SUBMIT HOST

USAGE

./updateHostname.pl [--help]

--help      :   Print help info

EXAMPLES

updateHostname.pl

=cut

#### FLUSH BUFFER
$| = 1;

#### USE LIB
use FindBin qw($Bin);
use lib "$Bin/../../lib";

#### EXTERNAL MODULES
use Getopt::Long;
use Data::Dumper;

#### INTERNAL MODULES
use Conf::Yaml;
use Agua::DBaseFactory;
use Agua::Ops;
use Agua::Instance;

#### SET CONF OBJECT
my $conf = Conf::Yaml->new(
	inputfile	=>	"$Bin/../../conf/config.yaml",
	backup		=>	1,
	separator	=>	"\t",
	spacer		=>	"\\s\+"
);

#### GET OPTIONS
my $help;
my $SHOWLOG      =    2;
my $PRINTLOG     =    5;
GetOptions (
    'SHOWLOG=i'     => \$SHOWLOG,
    'PRINTLOG=i'    => \$PRINTLOG,
    'help'          => \$help
) or die "No options specified. Try '--help'\n";

my $tempdir = $conf->getKey('agua', 'TEMPDIR');
my $logfile = "$tempdir/agua.updatehostname.log";
print "updateHostname.pl     printing to logfile: $logfile\n";
open(STDOUT, ">$logfile") or die "Can't open logfile: $logfile\n";
open(STDERR, ">$logfile") or die "Can't open logfile: $logfile\n";
 
#### PRINT DATE
print "updateHostname.pl    Started: ";
print `date`;

package UpdateHosts;
use Moose;
use Data::Dumper;

# INTS
has 'SHOWLOG'			=>  ( isa => 'Int', is => 'rw', default => 2 );
has 'PRINTLOG'			=>  ( isa => 'Int', is => 'rw', default => 5 );

# STRINGS
has 'cluster'		=>  ( isa => 'Str|Undef', is => 'rw' );
has 'username'  	=>  ( isa => 'Str', is => 'rw' );
has 'queue'			=>  ( isa => 'Str|Undef', is => 'rw', default => 'default' );

# OBJECTS
has 'conf' 	=> (
	is =>	'rw',
	'isa' => 'Conf::Yaml',
	default	=>	sub { Conf::Yaml->new(	backup	=>	1, separator => "\t"	);	}
);
has 'ops' 	=> (
	is =>	'rw',
	'isa' => 'Agua::Ops',
	default	=>	sub { Agua::Ops->new();	}
);
has 'master' 	=> (
	is =>	'rw',
	'isa' => 'Agua::Instance',
	default	=>	sub { Agua::Instance->new();	}
);
has 'head' 	=> (
	is =>	'rw',
	'isa' => 'Agua::Instance',
	default	=>	sub { Agua::Instance->new();	}
);
has 'db'		=> ( isa => 'Agua::DBase::MySQL', is => 'rw', required => 0 );

use Moose::Util qw( apply_all_roles );

my $object = UpdateHosts->new({
	conf	 	=>  $conf,
	tempdir		=>	$tempdir,
    SHOWLOG     =>  $SHOWLOG,
    PRINTLOG    =>  $PRINTLOG	
});
apply_all_roles( $object, 'Agua::Common::Logger' );
apply_all_roles( $object, 'Agua::Common::Util' );
apply_all_roles( $object, 'Agua::Common::SGE' );
apply_all_roles( $object, 'Agua::Common::Cluster' );
apply_all_roles( $object, 'Agua::Common::Aws' );
apply_all_roles( $object, 'Agua::Common::Ssh' );

my $adminuser = $object->conf()->getKey('agua', "ADMINUSER");
print "updateHostname.pl    adminuser: $adminuser\n";
$object->username($adminuser);
$object->updateHostname();
print "\nupdateHostname.pl    Completed: ";
print `date`;

sub usage {
    print `perldoc $0`;
}