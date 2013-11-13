package Test::Object::TestSuper;

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

use Super;
use Super2;
use base qw(Super Super2);
#use base qw(Super2);


sub new {
 	my $class 		=	shift;
    my $arguments 	=	shift;
        
    my $self = {};
    bless $self, $class;

    return $self;
}

sub testSuper {
	diag("super");
	
	my $self		=	shift;

	my $slots = $self->SUPER::getSlots();
	my $slot = $$slots[0];
	is($slot, "SUPER1", "SUPER::getSlots");

	my $slots2 = $self->getSlots();
	my $slot2 = $$slots[0];
	is($slot2, "SUPER1", "self->getSlots");
}

sub testDoSlots {
	diag("doSlots");
	
	my $self		=	shift;

	$self->doSlots();
	
}

#### END Object::TestSuper

1;