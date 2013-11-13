#!/usr/bin/perl -w

=head2

APPLICATION     object .t

PURPOSE         TEST Object.pm

=cut

#### USE LIBS
use FindBin qw($Bin);
use lib "$Bin/../../lib";
#use lib "$Bin/../../../../lib";



use Test::More  tests => 8;

#### EXTERNAL MODULES
use Test::Object;
use Test::Object::TestSuper;
use Test::Object::TestSlots;

my $object = Test::Object;
$object->testNew();
$object->testGet();
$object->testSet();


my $object2 = Test::Object::TestSuper->new();
$object2->testSuper();


my $object3 = Test::Object::TestSlots->new();
$object3->testGetSlots();
$object3->testGetAncestorSlots();
$object3->testGrandParentSlots();

