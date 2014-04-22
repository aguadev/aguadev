package Moose::Exception::DelegationToARoleWhichIsNotLoaded;
BEGIN {
  $Moose::Exception::DelegationToARoleWhichIsNotLoaded::AUTHORITY = 'cpan:STEVAN';
}
$Moose::Exception::DelegationToARoleWhichIsNotLoaded::VERSION = '2.1204';
use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::Attribute';

has 'role_name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

sub _build_message {
    my $self = shift;
    "The ".$self->attribute->name." attribute is trying to delegate to a role which has not been loaded - ".$self->role_name;
}

1;
