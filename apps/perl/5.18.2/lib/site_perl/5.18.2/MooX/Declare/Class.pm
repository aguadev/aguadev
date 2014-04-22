package MooX::Declare::Class;
use Moo;
use MooX::Declare::Methods;

with 'MooX::Declare::Filter', Methods(qw(method around before after override));

1;
