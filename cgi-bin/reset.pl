#!/usr/bin/perl -w

#### DEBUG
my $DEBUG = 0;
#$DEBUG = 1;

=head2

	APPLICATION 	reset.pl
	
	PURPOSE
	
		RESET MASTER NODE AFTER STOP/START:
        
=cut

use strict;

#### DISABLE BUFFERING OF STDOUT
$| = 1;

#### DEBUG HEADER
print "Content-type: text/html\n\n";

use CGI::Carp qw(fatalsToBrowser);

#### USE LIB
use FindBin qw($Bin);
use lib "$Bin/lib";
use Data::Dumper;

#### INTERNAL MODULES
use Conf::Yaml;
use Agua::Instance;
use Agua::DBaseFactory;

#### SET CONF OBJECT
my $conf = Conf::Yaml->new(
	inputfile	=>	"$Bin/conf/config.yaml",
	backup		=>	1
);

#### GET INPUT
my $input = $ARGV[0];
my ($masterid) = $input =~ /"masterid":"([^\"]+)/;
print "masterid: $masterid\n";
$masterid = "unknown" if not defined $masterid;

#### PRINT TO LOG FILE
my $logfile 	= "$Bin/log/agua.reset.$masterid.log";
print "reset.pl     printing to logfile: $logfile\n";
open(STDOUT, ">$logfile") or die "Can't open logfile: $logfile\n" if defined $logfile;
open(STDERR, ">$logfile") or die "Can't open logfile: $logfile\n" if defined $logfile;

#### CHECK INPUT
print "reset.pl masterid not defined. Exiting\n" and exit if $masterid eq "unknown";
print "reset.pl No JSON input. Exiting.\n" and exit if not defined $input or not $input;
$input =~ s/\s+$//;
print "reset.pl     Initiated. input: $input\n";


#### CONVERT JSON TEXT TO OBJECT
use JSON;
my $jsonParser = JSON->new();
my $json = $jsonParser->
allow_nonref->decode($input);
$json->{conf} = $conf;

#### PRINT DATE
print "reset.pl    Started: ";
print `date`;

package Object;
use Moose;
use Data::Dumper;


# BOOLEANS
has 'LOG'			=>  ( isa => 'Bool', is => 'rw', default => 1 );

# STRING
has 'username'  	=>  ( isa => 'Str', is => 'rw' );
has 'cluster'  	    =>  ( isa => 'Str|Undef', is => 'rw' );
has 'queue'  	    =>  ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'root'			=>  ( isa => 'Str|Undef', is => 'rw' );
has 'cell'			=>  ( isa => 'Str|Undef', is => 'rw' );
has 'masterid'  	=>  ( isa => 'Str', is => 'rw' );

# OBJECTS
has 'dbobject'		=> ( isa => 'Agua::DBase::MySQL', is => 'rw', required => 0 );
has 'conf' 	=> (
	is =>	'rw',
	'isa' => 'Conf::Yaml',
	default	=>	sub { Conf::Yaml->new({});	}
);
#has 'ops' 	=> (
#	is =>	'rw',
#	'isa' => 'Agua::Ops',
#	default	=>	sub { Agua::Ops->new();	}
#);
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


use Moose::Util qw( apply_all_roles );
my $object = Object->new($json);
apply_all_roles( $object, 'Agua::Common::Util' );
apply_all_roles( $object, 'Agua::Common::SGE' );
apply_all_roles( $object, 'Agua::Common::Cluster' );
apply_all_roles( $object, 'Agua::Common::Aws' );
apply_all_roles( $object, 'Agua::Common::Ssh' );
#my $mode = $json->{mode};
#$object->$mode();
$object->resetMaster();
print "\nreset.pl    Completed: ";
print `date`;



sub usage {
    print `perldoc $0`;
}
