use MooseX::Declare;

use strict;
use warnings;

class Test::Queue::Worker::Receive extends Queue::Worker {

has 'sleep'	=> 	( isa => 'Int|Undef', is => 'rw', default => 5 );

has 'logfile'	=> 	( isa => 'Str|Undef', is => 'rw', required => 1 );
has 'handled'	=> 	( isa => 'Str|Undef', is => 'rw', default => 0 );

use FindBin qw($Bin);
use Test::More;

#####////}}}}}

method testReceiveTask {
	#### SET FLAG
	$self->handled(0);
	
	#### OVERRIDES
	*handleTask	=	sub {
		my $self	=	shift;
		my $sleep	=	$self->sleep();
		print "sleep: $sleep\n";
		sleep($sleep/2);
		
		$self->handled(1);
	};

	#### START LISTENING
	my $queuename	=	"test.worker.queue";
	my $childpid = fork;
	if ( $childpid ) #### ****** Parent ****** 
	{
		$self->logDebug("PARENT childpid", $childpid);
	}
	elsif ( defined $childpid ) {
		$self->receiveTask($queuename);
	}
	
	#### SET TASK
	my $data	=	{
		username	=>	"syoung",
		project		=>	"1234567890",
		workflow	=>	"Align"
	};

	#### VERIFY HANDLED
	ok($self->handled() == 0, "not yet handled");
	$self->sendTask($data, $queuename);
	my $sleep		=	$self->sleep();
	$self->logDebug("Sleeping $sleep seconds");
	sleep($sleep);
	ok($self->handled() == 0, "handled");	
}

method sendTask ($data, $queuename) {
	$self->logDebug("data", $data);

	my $jsonparser = JSON->new();
	my $json = $jsonparser->encode($data);
	$self->logDebug("json", $json);

	#### GET CONNECTION
	my $connection	=	$self->newConnection();
	$self->logDebug("DOING connection->open_channel()");
	my $channel = $connection->open_channel();
	$self->channel($channel);
	#$self->logDebug("channel", $channel);
	
	$channel->declare_queue(
		queue => $queuename,
		durable => 1,
	);
	
	#### BIND QUEUE TO EXCHANGE
	$channel->publish(
		exchange => '',
		routing_key => $queuename,
		body => $json,
	);

}

}

