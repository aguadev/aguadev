package MooX::Declare::Methods;
use strictures 1;
use Package::Variant
  importing => ['Moo::Role'],
  subs => [ qw(around with) ],
;

my $add_semi = "BEGIN { Filter::Keyword::inject_after_scope(';') }";

my %filters = (
  method => '; sub %s { my $self = shift; ',
  around =>
    ";around %s => sub { $add_semi my \$orig = shift; my \$self = shift; ",
  map { $_ => ";$_ %s => sub { $add_semi my \$self = shift; " }
    qw(before after override),
);

sub make_variant {
  my ($class, $target_package, @methods) = @_;
  with 'MooX::Declare::HasParams';
  around filters => sub {
    my $orig = shift;
    my $self = shift;
    (
      $self->$orig,
      ( map { $_ => $self->param_filter($filters{$_}) } @methods ),
    )
  };
}

1;
