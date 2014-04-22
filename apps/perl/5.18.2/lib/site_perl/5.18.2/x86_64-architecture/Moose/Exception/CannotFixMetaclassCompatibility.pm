package Moose::Exception::CannotFixMetaclassCompatibility;
BEGIN {
  $Moose::Exception::CannotFixMetaclassCompatibility::AUTHORITY = 'cpan:STEVAN';
}
$Moose::Exception::CannotFixMetaclassCompatibility::VERSION = '2.1204';
use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::Class';

has 'superclass' => (
    is       => 'ro',
    isa      => 'Object',
    required => 1
);

has 'metaclass_type' => (
    is       => 'ro',
    isa      => 'Str',
);

sub _build_message {
    my $self = shift;
    my $class_name = $self->class_name;
    "Can't fix metaclass incompatibility for $class_name because it is not pristine.";
}

1;
