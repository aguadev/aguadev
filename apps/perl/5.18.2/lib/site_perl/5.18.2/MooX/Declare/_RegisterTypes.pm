package MooX::Declare::_RegisterTypes;
use strictures 1;
use Type::Registry;

sub import {
  my $class = shift;
  my $target = caller;
  Type::Registry->for_class($target)->add_types(@_);
}

1;
