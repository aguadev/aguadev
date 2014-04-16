package Moose::Exception::IllegalMethodTypeToAddMethodModifier;
BEGIN {
  $Moose::Exception::IllegalMethodTypeToAddMethodModifier::AUTHORITY = 'cpan:STEVAN';
}
$Moose::Exception::IllegalMethodTypeToAddMethodModifier::VERSION = '2.1204';
use Moose;
extends 'Moose::Exception';

has 'class_or_object' => (
    is       => 'ro',
    isa      => "Any",
    required => 1,
);

has 'params' => (
    is       => 'ro',
    isa      => 'ArrayRef',
    required => 1,
);

has 'modifier_name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

sub _build_message {
    my $self = shift;
    "Methods passed to ".$self->modifier_name." must be provided as a list, arrayref or regex, not ".$self->params->[0];
}

1;
