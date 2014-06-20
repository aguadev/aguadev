use MooseX::Declare;

use strict;
use warnings;

#### USE LIB FOR INHERITANCE
use FindBin qw($Bin);
use lib "$Bin/../";

class Mock::Virtual {

sub new {
    my $class          = shift;
    my $type = shift;
    
    $type = uc(substr($type, 0, 1)) . substr($type, 1);
    #print "Virtual::new    type: $type\n";
    
    my $location    = "Mock/Virtual/$type.pm";
    $class          = "Mock::Virtual::$type";

    #print "Virtual::new    DOING require $location\n";
    require $location;

    return $class->new(@_);
}
    
Mock::Virtual->meta->make_immutable(inline_constructor => 0);

} #### END

1;
