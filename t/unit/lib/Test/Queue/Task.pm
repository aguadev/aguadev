use MooseX::Declare;

use strict;
use warnings;

class Test::Queue::Task extends Queue::Task {

has 'sleep'	=> 	( isa => 'Int|Undef', is => 'rw', default => 10 );

has 'logfile'	=> 	( isa => 'Str|Undef', is => 'rw', required => 1 );
has 'handled'	=> 	( isa => 'Str|Undef', is => 'rw', default => 0 );

use FindBin qw($Bin);
use Test::More;

#####////}}}}}

method testHandleTask {
	my $json	=	qq{{"username":"syoung","project":"Test","workflow":"Sleep","number":1}};

	$self->handleTask($json);
	
}

method testListen {
	
	my $datas = [
		{
			username	=>	"syoung",
			project		=>	"1234567890",
			workflow	=>	"Align"
		},
		{
			username	=>	"syoung",
			project		=>	"09876543d21",
			workflow	=>	"Align"
		}
	];

	
}



}

