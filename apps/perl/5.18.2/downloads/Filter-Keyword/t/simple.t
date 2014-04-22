use strictures 1;
use Test::More;
use Filter::Keyword;

my $shadowed_called = 0;
sub shadowed ($&) {
  my ($name, $sub) = @_;
  $shadowed_called++;
  is($name, 'fun', 'shadowed sub called with correct name');
  is($sub->(), 'OH WHAT FUN', 'shadowed sub called with correct sub');
}

BEGIN {
  (our $Kw = Filter::Keyword->new(
    target_package => __PACKAGE__,
    keyword_name => 'method',
    parser => sub {
      my $kw = shift;
      if (my ($stripped, $matches) = $kw->match_source('', '{')) {
        my $name = $kw->current_match;
        $stripped =~ s/{/sub ${name} { my \$self = shift;/;
        return ($stripped, 1);
      }
      else {
        return ('', 1);
      }
    },
  ))->install;
  (our $Kw2 = Filter::Keyword->new(
    target_package => __PACKAGE__,
    keyword_name => 'shadowed',
    parser => sub {
      my $kw = shift;
      if (my ($stripped, $matches) = $kw->match_source('', '{')) {
        my $name = $kw->current_match;
        $stripped =~ s/{/shadowed "${name}", sub { BEGIN { Filter::Keyword::inject_after_scope(';') } /;
        return ($stripped, 1);
      }
      else {
        return ('', 1);
      }
    },
  ))->install;
}

my ($line1, $line2);
#line 1
method yay { $line1 = __LINE__; "YAY $self" } $line2 = __LINE__;
is(__LINE__, 2, 'line number correct after first keyword');

is(__PACKAGE__->yay, 'YAY ' . __PACKAGE__, 'result of keyword correct');
is($line1, 1, 'line number correct in keyword');
is($line2, 1, 'line number correct on same line as keyword');

#line 1
my $x = __LINE__ . " @{[ __LINE__ ]} method foo @{[ __LINE__ ]} " . __LINE__;
is(__LINE__, 2, 'line number correct after string with keyword');
is($x, '1 1 method foo 1 bar baz 1', 'line numbers in constructed string are correct');

undef $line1;
undef $line2;
#line 1
method spoon {
  $line1 = __LINE__;
  'I HAZ A SPOON'
}

is(__PACKAGE__->spoon, 'I HAZ A SPOON', 'result of multiline keyword');
is($line1, 2, 'line number correct in multiline keyword');

#line 1
method spoon2 {
  $line2 = __LINE__;
  'I HAZ A SPOON'
}

is(__PACKAGE__->spoon2, 'I HAZ A SPOON', 'result of second multiline keyword correct');
is($line2, 2, 'line number correct in second multiline keyword');

undef $line1;
undef $line2;
#line 1
shadowed fun { $line1 = __LINE__; 'OH WHAT FUN' }
is($line1, 1, 'line number correct inside second keyword');

shadowed fun { $line2 = __LINE__; 'OH WHAT FUN' }
is($line1, 4, 'line number correct inside second keyword repeat');

undef $line1;
undef $line2;
#line 1
shadowed fun {
  $line1 = __LINE__;
  'OH WHAT FUN';
}
is($line1, 2, 'line number correct inside second keyword multiline');

shadowed fun {
  $line2 = __LINE__;
  'OH WHAT FUN';
};
is($line2, 8, 'line number correct inside second keyword multiline');

is($shadowed_called, 4, 'shadowed sub called only by filter output');

is(__LINE__, 15, 'line number after shadowed correct');

my $comment_run = 0;
# comment with method keyword $comment_run++;
is $comment_run, 0, 'comments not executed';

done_testing;
