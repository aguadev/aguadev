use MooseX::Declare;

use strict;
use warnings;

class Test::Queue::Task::Receive extends Queue::Task {

has 'sleep'	=> 	( isa => 'Int|Undef', is => 'rw', default => 10 );

has 'logfile'	=> 	( isa => 'Str|Undef', is => 'rw', required => 1 );
has 'handled'	=> 	( isa => 'Str|Undef', is => 'rw', default => 0 );

use FindBin qw($Bin);
use Test::More;

#####////}}}}}

method testReceiveTask {
	#### LOAD DATABASE
	$self->handled(0);
	
	#### OVERRIDES
	*handleTask	=	sub {
		my $self	=	shift;
		print "INSIDE handleTask    self:\n";
		print Dumper $self;
		my $sleep	=	$self->sleep();
		print "sleep: $sleep\n";
		sleep($sleep/2);
		
		$self->received(1);
	};

	#### SET TASK
	my $data	=	{
		username	=>	"syoung",
		project		=>	"1234567890",
		workflow	=>	"Align"
	};

	$self->receiveTask($data);
	ok($self->handled() == 0, "not yet handled");
	my $sleep	=	$self->sleep();
	$self->logDebug("Sleeping $sleep seconds");
	sleep($sleep);
	ok($self->handled() == 0, "handled");	
}

}

