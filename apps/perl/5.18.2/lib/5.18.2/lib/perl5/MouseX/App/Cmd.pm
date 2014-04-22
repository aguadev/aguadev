use 5.006;

package MouseX::App::Cmd;
use Mouse;

our $VERSION = '0.27';    # VERSION
use namespace::clean -except => 'meta';
extends 'MooseX::App::Cmd';
__PACKAGE__->meta->make_immutable();   ## no critic (RequireExplicitInclusion)
no Mouse;
1;

# ABSTRACT: Mashes up MouseX::Getopt and App::Cmd

__END__

=pod

=for :stopwords Yuval Kogman Guillermo Roditi Daisuke Maki Vladimir Timofeev Bruno Vecchi
Offer Kaye Mark Gardner Yanick Champoux Dann Ken Crowell Michael Joyce
Infinity Interactive, cpan testmatrix url annocpan anno bugtracker rt
cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 NAME

MouseX::App::Cmd - Mashes up MouseX::Getopt and App::Cmd

=head1 VERSION

version 0.27

=head1 SYNOPSIS

    package YourApp::Cmd;
    use Mouse;

    extends qw(MouseX::App::Cmd);


    package YourApp::Cmd::Command::blort;
    use Mouse;

    extends qw(MouseX::App::Cmd::Command);

    has blortex => (
        traits => [qw(Getopt)],
        isa => 'Bool',
        is  => 'rw',
        cmd_aliases   => 'X',
        documentation => 'use the blortext algorithm',
    );

    has recheck => (
        traits => [qw(Getopt)],
        isa => 'Bool',
        is  => 'rw',
        cmd_aliases => 'r',
        documentation => 'recheck all results',
    );

    sub execute {
        my ( $self, $opt, $args ) = @_;

        # you may ignore $opt, it's in the attributes anyway

        my $result = $self->blortex ? blortex() : blort();

        recheck($result) if $self->recheck;

        print $result;
    }

=head1 DESCRIPTION

This module marries L<App::Cmd|App::Cmd> with L<MouseX::Getopt|MouseX::Getopt>.

It extends L<MooseX::App::Cmd|MooseX::App::Cmd> which uses
L<Any::Moose|Any::Moose> to work with either L<Moose|Moose> or
L<Mouse|Mouse>.  Consult those modules' documentation for full
usage information.

=head1 SEE ALSO

=over

=item L<MooseX::App::Cmd|MooseX::App::Cmd>

=item L<App::Cmd|App::Cmd>

=item L<App::Cmd::Tutorial|App::Cmd::Tutorial>

=item L<MouseX::Getopt|MouseX::Getopt>

=item L<MouseX::App::Cmd::Command|MouseX::App::Cmd::Command>

=back

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc MooseX::App::Cmd

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/MooseX-App-Cmd>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/MooseX-App-Cmd>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/MooseX-App-Cmd>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.perl.org/dist/overview/MooseX-App-Cmd>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/M/MooseX-App-Cmd>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=MooseX-App-Cmd>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=MooseX::App::Cmd>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the web
interface at L<https://github.com/mjgardner/moosex-app-cmd/issues>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/mjgardner/moosex-app-cmd>

  git clone git://github.com/mjgardner/moosex-app-cmd.git

=head1 AUTHORS

=over 4

=item *

Yuval Kogman <nothingmuch@woobling.org>

=item *

Guillermo Roditi <groditi@cpan.org>

=item *

Daisuke Maki <dmaki@cpan.org>

=item *

Vladimir Timofeev <vovkasm@gmail.com>

=item *

Bruno Vecchi <brunov@cpan.org>

=item *

Offer Kaye <offerk@cpan.org>

=item *

Mark Gardner <mjgardner@cpan.org>

=item *

Yanick Champoux <yanick+cpan@babyl.dyndns.org>

=item *

Dann <techmemo@gmail.com>

=item *

Ken Crowell <oeuftete@gmail.com>

=item *

Michael Joyce <ubermichael@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive, Yuval Kogman.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
