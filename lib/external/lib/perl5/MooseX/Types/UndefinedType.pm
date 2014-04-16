use warnings;
use strict;
package MooseX::Types::UndefinedType;
BEGIN {
  $MooseX::Types::UndefinedType::AUTHORITY = 'cpan:PHAYLON';
}
# ABSTRACT: a fallback type for when a type cannot be found
$MooseX::Types::UndefinedType::VERSION = '0.44';
use Moose::Util::TypeConstraints ();
use Carp::Clan '^MooseX::Types';
use namespace::clean;   # TODO: namespace::autoclean does not yet respect overloads

use overload '""'     => sub { shift->name },
             fallback => 1;

# =head1 DESCRIPTION
#
# Whenever a type handle function (e.g. C<Int()> can't find a type
# constraint under its full name, it assumes it has not yet been defined.
# It will then return an instance of this class, handling only
# stringification, name and possible identification of undefined types.
#
# Later, when you try to use the Undefined Type Constraint, autovivification will
# be attempted.
#
# =head1 METHODS
#
# =head2 new
#
# Takes a full type name as argument and returns an instance of this
# class.
#
# =cut

sub new {
    return bless { name => $_[1] }, $_[0];
}

# =head2 name
#
# Returns the stored type name.
#
# =cut

sub name {
    return $_[0]->{name};
}

# =head2 __autovivify
#
# Try to see if the type constraint has yet been defined and if so create it.
#
# =cut

sub __autovivify {
    my ($self) = @_;
    if(my $tc = $self->{instance}) {
        return $tc;
    } elsif( my $new_tc = Moose::Util::TypeConstraints::find_type_constraint($self->name)) {
        $self->{instance} = $new_tc;
        return $new_tc;
    } else {
        return;
    }
}

# =head2 can_be_inlined
#
# Make sure that if a type hasn't been defined yet when Moose wants to inline it,
# we don't allow inlining.
#
# =cut

sub can_be_inlined {
    my $self = shift;
    if(my $type_constraint = $self->__autovivify) {
        return $type_constraint->can_be_inlined;
    } else {
        return;
    }
}

# =head2 AUTOLOAD
#
# Try to autovivify and delegate
#
# =cut

sub AUTOLOAD {
    my ($self, @args)  = @_;
    my ($method) = our $AUTOLOAD =~ /([^:]+)$/;

    if(my $type_constraint = $self->__autovivify) {
        return $type_constraint->$method(@args);
    } else {
        croak "Method '$method' is not supported for " . $self->name;
    }
}

# =head2 DESTROY
#
# Moose::Meta::TypeConstraint::Parameterizable complains if this isn't here. TODO
# to find out why.
#
# =cut

sub DESTROY {
    return;
}

# =head1 SEE ALSO
#
# L<MooseX::Types::Moose>,
# L<Moose::Util::TypeConstraints>,
# L<Moose::Meta::TypeConstraint>,
# L<Carp::Clan>
#
# =cut


1;

__END__

=pod

=encoding UTF-8

=for :stopwords Robert "phaylon" Sedlacek

=head1 NAME

MooseX::Types::UndefinedType - a fallback type for when a type cannot be found

=head1 VERSION

version 0.44

=head1 DESCRIPTION

Whenever a type handle function (e.g. C<Int()> can't find a type
constraint under its full name, it assumes it has not yet been defined.
It will then return an instance of this class, handling only
stringification, name and possible identification of undefined types.

Later, when you try to use the Undefined Type Constraint, autovivification will
be attempted.

=head1 METHODS

=head2 new

Takes a full type name as argument and returns an instance of this
class.

=head2 name

Returns the stored type name.

=head2 __autovivify

Try to see if the type constraint has yet been defined and if so create it.

=head2 can_be_inlined

Make sure that if a type hasn't been defined yet when Moose wants to inline it,
we don't allow inlining.

=head2 AUTOLOAD

Try to autovivify and delegate

=head2 DESTROY

Moose::Meta::TypeConstraint::Parameterizable complains if this isn't here. TODO
to find out why.

=head1 SEE ALSO

L<MooseX::Types::Moose>,
L<Moose::Util::TypeConstraints>,
L<Moose::Meta::TypeConstraint>,
L<Carp::Clan>

=head1 AUTHOR

Robert "phaylon" Sedlacek <rs@474.at>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Robert "phaylon" Sedlacek.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
