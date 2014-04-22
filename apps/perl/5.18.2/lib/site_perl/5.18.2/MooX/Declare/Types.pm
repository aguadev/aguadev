package MooX::Declare::Types;
use Moo::Role;

around filters => sub {
  my $orig = shift;
  my $self = shift;
  (
    $self->$orig,
    types => {
      match => qr//,
      process => sub {
        my ($name, $stripped) = @_;
        if ($stripped =~ s/((?:::[a-zA-Z0-9_]+)*)//) {
          $name .= $1;
        }
        return qq{;use MooX::Declare::_RegisterTypes "$name"} . $stripped;
      },
    },
  )
};

1;
