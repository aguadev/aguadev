package Moose::Exception::CouldNotGenerateInlineAttributeMethod;
BEGIN {
  $Moose::Exception::CouldNotGenerateInlineAttributeMethod::AUTHORITY = 'cpan:STEVAN';
}
$Moose::Exception::CouldNotGenerateInlineAttributeMethod::VERSION = '2.1204';
use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::Instance';

has 'option' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has 'error' => (
    is       => 'ro',
    isa      => 'Str|Moose::Exception',
    required => 1
);

sub _build_message {
    my $self = shift;
    "Could not generate inline ".$self->option." because : ".$self->error;
}

1;
