use MooseX::Declare;

=head2


NOTES

	NOW	- USE SSH TO PARSE LOGS AND PERFORM SSH COMMANDS
	
	LATER - USE QUEUES:
	
		WORKERS REPORT STATUS TO MANAGER
	
		MANAGER DIRECT WORKERS TO:
		
			- DEPLOY APPS
			
			- PROVIDE WORKFLOW STATUS
			
			- STOP/START WORKFLOWS


=cut

use strict;
use warnings;

class Test::Synapse extends Synapse {

#####////}}}}}

use Conf::Yaml;
use Agua::Ops;

#### Strings
has 'executable'		=>  ( isa => 'Str|Undef', is => 'rw', lazy	=>	1, builder	=>	"setExecutable" );

#### Arrays
has 'outputs'		=>  ( isa => 'ArrayRef|Undef', is => 'rw', default	=>	sub { return [] } );

use FindBin qw($Bin);
use Test::More;

use Openstack::Nova;

#####////}}}}}

method getAssignments {
	$self->returnOutput();
}

method getWorkAssignment ($state) {
	$self->returnOutput();
}
method setExecutable {
	$self->returnOutput();
}

method latestVersion ($package) {
	$self->returnOutput();
}

method returnOutput {
	return splice($self->outputs(), 0, 1);
}


}