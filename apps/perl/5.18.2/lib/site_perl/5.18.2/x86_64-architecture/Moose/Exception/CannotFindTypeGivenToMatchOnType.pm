package Moose::Exception::CannotFindTypeGivenToMatchOnType;
BEGIN {
  $Moose::Exception::CannotFindTypeGivenToMatchOnType::AUTHORITY = 'cpan:STEVAN';
}
$Moose::Exception::CannotFindTypeGivenToMatchOnType::VERSION = '2.1204';
use Moose;
extends 'Moose::Exception';

has 'to_match' => (
    is       => 'ro',
    isa      => 'Any',
    required => 1
);

has 'action' => (
    is       => 'ro',
    isa      => 'Any',
    required => 1
);

has 'type' => (
    is       => 'ro',
    isa      => 'Any',
    required => 1
);

sub _build_message {
    my $self = shift;
    my $type = $self->type;

    return "Cannot find or parse the type '$type'"
}

1;
