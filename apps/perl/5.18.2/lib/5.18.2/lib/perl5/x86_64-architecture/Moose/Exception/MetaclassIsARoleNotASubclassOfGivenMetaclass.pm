package Moose::Exception::MetaclassIsARoleNotASubclassOfGivenMetaclass;
BEGIN {
  $Moose::Exception::MetaclassIsARoleNotASubclassOfGivenMetaclass::AUTHORITY = 'cpan:STEVAN';
}
$Moose::Exception::MetaclassIsARoleNotASubclassOfGivenMetaclass::VERSION = '2.1204';
use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::Role';

has 'metaclass' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

sub _build_message {
    my $self = shift;
    $self->role_name." already has a metaclass, but it does not inherit ".$self->metaclass.' ('.$self->role.
        '). You cannot make the same thing a role and a class. Remove either Moose or Moose::Role.';
}

1;
