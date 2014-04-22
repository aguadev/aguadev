package MooX::Declare::Filter;
use Filter::Keyword;
use Moo::Role;
use namespace::clean;

has target => (is => 'ro');

sub import {
  my ($class) = @_;
  my $target = caller;
  my $self = $class->new(target => $target);
  my %filters = $self->filters;

  my @keywords = map {
    my $parser = $filters{$_};
    if (ref $parser ne 'CODE') {
      my ($match, $pattern, $process) = @{$parser}{qw(match pattern process)};
      my @match = ref $match eq 'ARRAY' ? @$match : ('', $match);
      $parser = sub {
        my ($keyword, $kwp) = @_;
        if (my ($stripped, $matches) = $kwp->match_source(@match)) {
          my $name = $kwp->current_match;
          if ($pattern) {
            $stripped =~ s/$match[1]/sprintf($pattern, $name)/e;
            return ($stripped, 1);
          }
          else {
            return ($process->($name, $stripped, $matches), 1);
          }
        }
        else {
          return ('', 1);
        }
      };
    }
    Filter::Keyword->new(
      target_package => $target,
      keyword_name => $_,
      parser => $parser,
    );
  } keys %filters;
  $_->install for @keywords;
}

sub filters { () }

1;
