package Moose::Exception::MetaclassIsNotASubclassOfGivenMetaclass;
BEGIN {
  $Moose::Exception::MetaclassIsNotASubclassOfGivenMetaclass::AUTHORITY = 'cpan:STEVAN';
}
$Moose::Exception::MetaclassIsNotASubclassOfGivenMetaclass::VERSION = '2.1204';
use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::Class';

has 'metaclass' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

sub _build_message {
    my $self = shift;
    $self->class_name." already has a metaclass, but it does not inherit ".$self->metaclass.' ('.$self->class.').';
}

1;
