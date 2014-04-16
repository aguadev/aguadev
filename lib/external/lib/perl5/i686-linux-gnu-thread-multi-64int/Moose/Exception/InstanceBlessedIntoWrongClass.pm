package Moose::Exception::InstanceBlessedIntoWrongClass;
BEGIN {
  $Moose::Exception::InstanceBlessedIntoWrongClass::AUTHORITY = 'cpan:STEVAN';
}
$Moose::Exception::InstanceBlessedIntoWrongClass::VERSION = '2.1204';
use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::ParamsHash', 'Moose::Exception::Role::Class', 'Moose::Exception::Role::Instance';

sub _build_message {
    my $self = shift;
    "Objects passed as the __INSTANCE__ parameter must already be blessed into the correct class, but ".$self->instance." is not a " . $self->class->name;
}

1;
