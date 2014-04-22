package Filter::Keyword::Parser;
use Moo;

use constant DEBUG => $ENV{FILTER_KEYWORD_DEBUG};
use constant DEBUG_VERBOSE => DEBUG && $ENV{FILTER_KEYWORD_DEBUG} > 1;

has reader => (is => 'ro', required => 1);

has re_add => (is => 'ro', required => 1);

has keywords => (is => 'ro', default => sub { [] });

sub add_keyword {
  push @{$_[0]->keywords}, $_[1];
}
sub remove_keyword {
  my ($self, $keyword) = @_;
  my $keywords = $self->keywords;
  for my $idx (0 .. $#$keywords) {
    if ($keywords->[$idx] eq $keyword) {
      splice @$keywords, $idx, 1;
      last;
    }
  }
}

has current_match => (is => 'rw');

has short_circuit => (is => 'rw');

has code => (is => 'rw', default => sub { '' });

has current_keyword => (is => 'rw', clearer => 1);
has keyword_matched => (is => 'rw');
has keyword_parsed => (is => 'rw');

sub get_next {
  my ($self) = @_;
  if ($self->short_circuit) {
    $self->short_circuit(0);
    $self->${\$self->re_add};
    return ('', 0);
  }
  if (my $keyword = $self->current_keyword) {
    if ($self->keyword_parsed) {
      DEBUG_VERBOSE && print STDERR "#after parse#";
      $keyword->clear_globref;
      $self->clear_current_keyword;
      $self->keyword_parsed(0);
    }
    elsif ($self->keyword_matched) {
      DEBUG_VERBOSE && print STDERR "#after match#";
      $keyword->clear_globref;
      $self->short_circuit(1);
      $self->keyword_parsed(1);
      return $keyword->parse($self);
    }
    elsif ($keyword->have_match) {
      DEBUG_VERBOSE && print STDERR "#just matched#";
      $self->keyword_matched(1);
      $self->short_circuit(1);
      my $match = $self->current_match;
      my $end = $match eq '{' ? '}'
              : $match eq '(' ? ')'
                              : '';
      return ("$end;", 1);
    }
    else {
      $keyword->restore_shadow;
      $self->clear_current_keyword;
    }
  }
  return $self->check_match;
}

sub fetch_more {
  my ($self) = @_;
  my $code = $self->code||'';
  my ($extra_code, $not_eof) = $self->reader->();
  $code .= $extra_code;
  $self->code($code);
  return $not_eof;
}

sub match_source {
  my ($self, $first, $second) = @_;
  $self->fetch_more while $self->code =~ /\A$first\s+\z/;
  if (my @match = ($self->code =~ /(.*?${first}\s+${second})((?s).*)\z/)) {
    my $code = pop @match;
    $self->code($code);
    my $found = shift(@match);
    return ($found, \@match);
  }
  return;
}

sub check_match {
  my ($self) = @_;
  unless ($self->code) {
    $self->fetch_more
      or return ('', 0);
  }
  for my $keyword (@{ $self->keywords }) {
    if (
      my ($stripped, $matches)
        = $self->match_source(
            $keyword->keyword_name, qr/(\(|[A-Za-z][A-Za-z_0-9]*|{)/
          )
    ) {
      $keyword->install_matcher($matches->[0]);
      $self->current_match($matches->[0]);
      $self->current_keyword($keyword);
      $self->keyword_matched(0);
      $self->short_circuit(1);
      return ($stripped, 1);
    }
  }
  my $code = $self->code;
  $self->code('');
  return ($code, 1);
}

1;
