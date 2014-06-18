use MooseX::Declare;

use strict;
use warnings;

#### USE LIB FOR INHERITANCE
use FindBin qw($Bin);
use lib "$Bin/../";

class Virtual {

sub new {
    my $class          = shift;
    my $type = shift;
    
    $type = uc(substr($type, 0, 1)) . substr($type, 1);
    #print "Virtual::new    type: $type\n";
    
    my $location    = "Virtual/$type.pm";
    $class          = "Virtual::$type";
    require $location;

    return $class->new(@_);
}
    
Virtual->meta->make_immutable(inline_constructor => 0);

} #### END

1;
