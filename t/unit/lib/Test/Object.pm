package Test::Object;

=pod

PACKAGE		Test::Object

PURPOSE		TEST CLASS Object

=cut

use strict;
use warnings;

use FindBin qw($Bin);
use lib "inputs/lib";
use lib "$Bin/../../../lib";

#### EXTERNAL MODULES
use Test::More;

#### INTERNAL MODULES
use Test::Common;
use Object;

####/////}}}

#sub new {
# 	my $class 		=	shift;
#    my $arguments 	=	shift;
#        
#    my $self = {};
#    bless $self, $class;
#
#    return $self;
#}

sub testNew {
	diag("new");
	
	my $object = Object->new();
	isa_ok($object, "Object", "object");
}

sub testGet {
	diag("get");
	
	my $object = Logger->new({
		showlog	=>	"TEST"
	});

	my $showlog = $object->showlog();
	is($showlog, "TEST", "get: $showlog");
}

sub testSet {
	diag("set");

	my $object = Logger->new({
		showlog	=>	"TEST"
	});

	$object->showlog("TEST2");
	my $showlog = $object->showlog();
	is($showlog, "TEST2", "set: TEST2");
}

#### END Object

1;