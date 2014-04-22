package Filter::Keyword::Filter;
use Moo;

use Filter::Keyword::Parser;
use Filter::Util::Call;
use Scalar::Util qw(weaken);
use B::Hooks::EndOfScope;

use constant DEBUG => $ENV{FILTER_KEYWORD_DEBUG};
use constant DEBUG_VERBOSE => DEBUG && $ENV{FILTER_KEYWORD_DEBUG} > 1;

has parser => (is => 'lazy');
has active => (is => 'rwp', default => 0);

sub _build_parser {
  my $self = shift;
  weaken $self;
  Filter::Keyword::Parser->new(
    reader => sub { $_ = ''; my $r = filter_read; ($_, $r) },
    re_add => sub {
      DEBUG_VERBOSE && print STDERR "#re-add#";
      filter_del;
      filter_add($self)
    },
  );
}

our @ACTIVE_FILTERS;
sub install {
  my ($self) = @_;
  return if $self->active;
  push @ACTIVE_FILTERS, $self;
  $self->_set_active(1);
  filter_add($self);
  on_scope_end {
    $self->_set_active(0);
    filter_del;
    pop @ACTIVE_FILTERS;
  };
  $self;
}

sub filter {
  my ($self) = @_;
  my ($string, $code) = $self->parser->get_next;
  $_ = $string;
  DEBUG && print $string;
  return $code;
}

1;

