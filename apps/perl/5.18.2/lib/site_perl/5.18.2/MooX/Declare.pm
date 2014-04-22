package MooX::Declare;
use strictures 1;

our $VERSION = '0.000001';
$VERSION = eval $VERSION;

use Type::Registry;
use Moo;
with 'MooX::Declare::Filter';

#TODO: with, extends
sub filters {
  (
    class => {
      match => qr/\{/,
      pattern =>
        ';{package %s;'
        .'use Moo;'
        .'BEGIN { Type::Registry->for_me->add_types(-Standard) }'
        .'use MooX::Declare::Class;',
    },
    role => {
      match => qr/\{/,
      pattern =>
        ';{package %s;'
        .'use Moo::Role;'
        .'BEGIN { Type::Registry->for_me->add_types(-Standard) }'
        .'use MooX::Declare::Role;',
    },
  )
}

1;
__END__

=head1 NAME

MooX::Declare - Declarative syntax for Moo

=head1 SYNOPSIS

  use MooX::Declare;

=head1 DESCRIPTION

Declarative syntax for Moo.

=head1 AUTHOR

haarg - Graham Knop (cpan:HAARG) <haarg@haarg.org>

=head2 CONTRIBUTORS

None yet.

=head1 COPYRIGHT

Copyright (c) 2013 the L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.

=cut
