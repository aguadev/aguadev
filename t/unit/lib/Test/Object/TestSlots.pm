package Test::Object::TestSlots;

=pod

PACKAGE		Test::Object

PURPOSE		TEST CLASS Object

=cut

use strict;
use warnings;
use Carp;

use FindBin qw($Bin);
use lib "inputs/lib";
#use lib "$Bin/../../../../lib";

#### EXTERNAL MODULES
use Test::More;
use Data::Dumper;

#### INTERNAL MODULES
use Test::Common;
use Object;

####/////}}}

use Object;
use Illumina::WGS::Util::Configure;
use Logger;
use base qw(Object Illumina::WGS::Util::Configure Logger);

sub new {
 	my $class 		=	shift;
    my $arguments 	=	shift;
        
    my $self = {};
    bless $self, $class;

    return $self;
}



sub testGetSlots {
	my $self		=	shift;

	my $object		=	Illumina::WGS::Util::Configure->new();
	my $slots		=	$object->getSlots();
	#print "Test::Object::TestSlots::testGetSlots    slots:\n";
	#print Dumper $slots;
	
	my $expected = [
		'PRINTLOG',
		'SHOWLOG',
		'conf',
		'configfile',
		'database',
		'db',
		'dbtype',
		'dumpfile',
		'logfile',
		'outputdir',
		'password',
		'requestor',
		'rootpassword',
		'testdatabase',
		'testpassword',
		'testuser',
		'user',
		'username',
		'validated'
	];
	#print "Test::Object::TestSlots::testGetSlots    expected:\n";
	#print Dumper $expected;

	is_deeply($slots, $expected, "getSlots");
}

sub testGetAncestorSlots {
	my $self		=	shift;

	diag("ancestorSlots");
	
	my $object		=	Illumina::WGS::Util::Configure->new();

	#print "Test::Object::TestSlots::testGetAncestorSlots    DOING $object->getAncestorSlots()\n";
	my $slots = $object->getAncestorSlots();
	#print "Test::Object::TestSlots::testGetAncestorSlots    slots:\n";
	#print Dumper $slots;
	
	my $expected = [
		'OLDPRINTLOG',
		'OLDSHOWLOG',
		'PRINTLOG',
		'SHOWLOG',
		'backup',
		'errortype',
		'errpid',
		'indent',
		'logfh',
		'logfile',
		'olderr',
		'oldout',
		'username'
	];

	is_deeply($slots, $expected, "ancestorSlots");	
}


sub testGrandParentSlots {
	my $self		=	shift;

	diag("ancestorSlots    grandParents");
	
	my $object		=	Illumina::WGS::Util::Configure->new();
	my $slots 		= 	$object->slots();
	#print "Test::Object::TestSlots::testGetAncestorSlots    slots:\n";
	#print Dumper $slots;
	
	my $expected = [
		'OLDPRINTLOG',
		'OLDSHOWLOG',
		'PRINTLOG',
		'SHOWLOG',
		'backup',
		'conf',
		'configfile',
		'database',
		'db',
		'dbtype',
		'dumpfile',
		'errortype',
		'errpid',
		'indent',
		'logfh',
		'logfile',
		'olderr',
		'oldout',
		'outputdir',
		'password',
		'requestor',
		'rootpassword',
		'testdatabase',
		'testpassword',
		'testuser',
		'user',
		'username',
		'validated'
    ];

	is_deeply($slots, $expected, "ancestorSlots    grandParents");	
}

sub testDoSlots {
	diag("doSlots");
	
	my $self		=	shift;

	$self->doSlots();
	
}

#### END Object::TestSlots

1;