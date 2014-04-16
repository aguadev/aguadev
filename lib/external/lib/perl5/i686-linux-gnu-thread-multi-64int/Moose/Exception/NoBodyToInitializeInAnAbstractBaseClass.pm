package Moose::Exception::NoBodyToInitializeInAnAbstractBaseClass;
BEGIN {
  $Moose::Exception::NoBodyToInitializeInAnAbstractBaseClass::AUTHORITY = 'cpan:STEVAN';
}
$Moose::Exception::NoBodyToInitializeInAnAbstractBaseClass::VERSION = '2.1204';
use Moose;
extends 'Moose::Exception';

has 'package_name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

sub _build_message {
    my $self = shift;
    "No body to initialize, " .$self->package_name. " is an abstract base class";
}

1;
