package Moose::Exception::CannotAutoDereferenceTypeConstraint;
BEGIN {
  $Moose::Exception::CannotAutoDereferenceTypeConstraint::AUTHORITY = 'cpan:STEVAN';
}
$Moose::Exception::CannotAutoDereferenceTypeConstraint::VERSION = '2.1204';
use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::Attribute', 'Moose::Exception::Role::Instance', 'Moose::Exception::Role::TypeConstraint';

sub _build_message {
    my $self = shift;
    "Can not auto de-reference the type constraint '" . $self->type_name . "'";
}

1;
