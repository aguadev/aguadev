use strict;
use warnings;

package App::Cmd::Command::help;
{
  $App::Cmd::Command::help::VERSION = '0.323';
}
use App::Cmd::Command;
BEGIN { our @ISA = 'App::Cmd::Command'; }

# ABSTRACT: display a command's help screen


sub command_names { qw/help --help -h -?/ }

sub description {
"This command will either list all of the application commands and their
abstracts, or display the usage screen for a subcommand with its
description.\n"
}

sub execute {
  my ($self, $opts, $args) = @_;

  if (!@$args) {
    my $usage = $self->app->usage->text;
    my $command = $0;

    # chars normally used to describe options
    my $opt_descriptor_chars = qr/[\[\]<>\(\)]/;

    if ($usage =~ /^(.+?) \s* (?: $opt_descriptor_chars | $ )/x) {
      # try to match subdispatchers too
      $command = $1;
    }

    # evil hack ;-)
    bless
      $self->app->{usage} = sub { return "$command help <command>\n" }
      => "Getopt::Long::Descriptive::Usage";

    $self->app->execute_command( $self->app->_prepare_command("commands") );
  } else {
    my ($cmd, $opt, $args) = $self->app->prepare_command(@$args);

    local $@;
    my $desc = $cmd->description;
    $desc = "\n$desc" if length $desc;

    my $ut = join "\n",
      eval { $cmd->usage->leader_text },
      $desc,
      eval { $cmd->usage->option_text };

    print "$ut\n";
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Cmd::Command::help - display a command's help screen

=head1 VERSION

version 0.323

=head1 DESCRIPTION

This command plugin implements a "help" command.  This command will either list
all of an App::Cmd's commands and their abstracts, or display the usage screen
for a subcommand with its description.

=head1 USAGE

The help text is generated from three sources:

=over 4

=item *

The C<usage_desc> method

=item *

The C<description> method

=item *

The C<opt_spec> data structure

=back

The C<usage_desc> method provides the opening usage line, following the
specification described in L<Getopt::Long::Descriptive>.  In some cases,
the default C<usage_desc> in L<App::Cmd::Command> may be sufficient and
you will only need to override it to provide additional command line
usage information.

The C<opt_spec> data structure is used with L<Getopt::Long::Descriptive>
to generate the description of the options.

Subcommand classes should override the C<discription> method to provide
additional information that is prepended before the option descriptions.

For example, consider the following subcommand module:

  package YourApp::Command::initialize;

  # This is the default from App::Cmd::Command
  sub usage_desc {
    my ($self) = @_;
    my $desc = $self->SUPER::usage_desc; # "%c COMMAND %o"
    return "$desc [DIRECTORY]";
  }

  sub description {
    return "The initialize command prepares the application...";
  }

  sub opt_spec {
    return (
      [ "skip-refs|R",  "skip reference checks during init", ],
      [ "values|v=s@",  "starting values", { default => [ 0, 1, 3 ] } ],
    );
  }

  ...

That module would generate help output like this:

  $ yourapp help initialize
  yourapp initialize [-Rv] [long options...] [DIRECTORY]

  The initialize command prepares the application...

        --help            This usage screen
        -R --skip-refs    skip reference checks during init
        -v --values       starting values

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
