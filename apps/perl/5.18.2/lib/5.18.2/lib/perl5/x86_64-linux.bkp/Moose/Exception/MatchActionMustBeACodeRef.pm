package Moose::Exception::MatchActionMustBeACodeRef;
BEGIN {
  $Moose::Exception::MatchActionMustBeACodeRef::AUTHORITY = 'cpan:STEVAN';
}
$Moose::Exception::MatchActionMustBeACodeRef::VERSION = '2.1204';
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
    isa      => 'Moose::Meta::TypeConstraint',
    required => 1
);

sub _build_message {
    my $self = shift;
    my $action = $self->action;

    return "Match action must be a CODE ref, not $action";
}

1;
