package MooX::Declare::HasParams;
use Types::Standard qw(Any Optional);
use Type::Params;
use Type::Registry;
use Moo::Role;

sub param_filter {
  my ($self, $pattern) = @_;
  return {
    match => qr/(?:\(([^()]*)\)\s*)?\{/,
    process => sub {
      my ($name, $stripped, $matches) = @_;

      my $param_string = '';
      my $params = $matches->[0];
      if (defined $params) {
        $param_string = $self->parse_signature($params);
      }
      $stripped =~ s/.*?\{/$param_string/;

      return (sprintf($pattern, $name) . $stripped, 1);
    },
  };
}

my $param_re = qr/([^()]*?\s)\s*(:?)(\$[a-zA-Z_]\w*)/;

our @PARAM_CHECK;

sub parse_signature {
  my ($self, $params) = @_;
  my $registry = Type::Registry->for_class($self->target);

  my @params;
  my @types;
  while ($params =~ /\G\s*$param_re\s*(?:,|$)/gc) {
    my ($type, $optional, $param) = ($1, $2, $3);
    my $type_object = $type ? $registry->lookup($type) : Any;
    if (!defined $type_object) {
      die "invalid type $type";
    }
    if ($optional) {
      $type_object = Optional[$type_object];
    }
    push @params, $param;
    push @types, $type_object;
  }

  if (pos $params != length $params) {
    die "invalid parameter string '$params'";
  }

  my $assign = '';
  if (@params) {
    $assign = 'my (' . join(', ', @params) . ') = ';
  }
  push @PARAM_CHECK, Type::Params::compile(@types);
  return $assign . '$' . __PACKAGE__ . "::PARAM_CHECK[$#PARAM_CHECK]->(\@_);";
}

1;
