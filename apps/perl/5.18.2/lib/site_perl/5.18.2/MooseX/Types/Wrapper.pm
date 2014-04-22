package MooseX::Types::Wrapper;
BEGIN {
  $MooseX::Types::Wrapper::AUTHORITY = 'cpan:PHAYLON';
}
# ABSTRACT: Wrap exports from a library
$MooseX::Types::Wrapper::VERSION = '0.44';
use Moose;
use Carp::Clan      qw( ^MooseX::Types );
use Module::Runtime 'use_module';

use namespace::autoclean;

extends 'MooseX::Types';

# =head1 DESCRIPTION
#
# See L<MooseX::Types/SYNOPSIS> for detailed usage.
#
# =head1 METHODS
#
# =head2 import
#
# =cut

sub import {
    my ($class, @args) = @_;
    my %libraries = @args == 1 ? (Moose => $args[0]) : @args;

    for my $l (keys %libraries) {

        croak qq($class expects an array reference as import spec)
            unless ref $libraries{ $l } eq 'ARRAY';

        my $library_class
          = ($l eq 'Moose' ? 'MooseX::Types::Moose' : $l );
        use_module($library_class);

        $library_class->import({
            -into    => scalar(caller),
            -wrapper => $class,
        }, @{ $libraries{ $l } });
    }
    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Robert "phaylon" Sedlacek Dave Luehrs John Napiorkowski Justin Hunter Karen
Etheridge Kent Fredric Matt Rolsky S Trout Paul Fenwick Rafael Kitover
'phaylon' Tomas Florian Doran (t0m) matthewt Ragwitz Graham Knop Hans
Dieter Pearcey Jesse

=head1 NAME

MooseX::Types::Wrapper - Wrap exports from a library

=head1 VERSION

version 0.44

=head1 DESCRIPTION

See L<MooseX::Types/SYNOPSIS> for detailed usage.

=head1 METHODS

=head2 import

=head1 SEE ALSO

L<MooseX::Types>

=head1 AUTHOR

Robert "phaylon" Sedlacek <rs@474.at>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Robert "phaylon" Sedlacek.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
