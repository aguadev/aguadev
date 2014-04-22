package Moose::Exception::AccessorMustReadWrite;
BEGIN {
  $Moose::Exception::AccessorMustReadWrite::AUTHORITY = 'cpan:STEVAN';
}
$Moose::Exception::AccessorMustReadWrite::VERSION = '2.1204';
use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::InvalidAttributeOptions';

sub _build_message {
    my $self = shift;
    "Cannot define an accessor name on a read-only attribute, accessors are read/write";
}

1;
