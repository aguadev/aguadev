use MooseX::Declare;

use strict;
use warnings;

#### USE LIB FOR INHERITANCE
use FindBin qw($Bin);
use lib "$Bin/../";

class Agua::DBaseFactory {

sub new {
    my $class          = shift;
    my $requested_type = shift;
    
    my $location    = "Agua/DBase/$requested_type.pm";
    $class          = "Agua::DBase::$requested_type";
    require $location;

    return $class->new(@_);
}
    
Agua::DBaseFactory->meta->make_immutable(inline_constructor => 0);

} #### END

1;
