package Moose::Exception::CallingMethodOnAnImmutableInstance;
BEGIN {
  $Moose::Exception::CallingMethodOnAnImmutableInstance::AUTHORITY = 'cpan:STEVAN';
}
$Moose::Exception::CallingMethodOnAnImmutableInstance::VERSION = '2.1204';
use Moose;
extends 'Moose::Exception';

has 'method_name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

sub _build_message {
    my $self = shift;
    "The '".$self->method_name."' method cannot be called on an immutable instance";
}

1;
