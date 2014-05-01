use MooseX::Declare;

=head2

NOTES

	Use SSH to parse logs and execute commands on remote nodes
	
TO DO

	Use queues to communicate between master and nodes:
	
		WORKERS REPORT STATUS TO MANAGER
	
		MANAGER DIRECTS WORKERS TO:
		
			- DEPLOY APPS
			
			- PROVIDE WORKFLOW STATUS
			
			- STOP/START WORKFLOWS

=cut

use strict;
use warnings;

class Queue::Task with (Logger, Exchange, Agua::Common::Database) {

#####////}}}}}

# Integers
has 'showlog'	=>  ( isa => 'Int', is => 'rw', default => 4 );
has 'printlog'	=>  ( isa => 'Int', is => 'rw', default => 5 );

# Strings
has 'database'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0 );
has 'user'		=> ( isa => 'Str|Undef', is => 'rw', required	=>	0 );
has 'pass'		=> ( isa => 'Str|Undef', is => 'rw', required	=>	0 );
has 'host'		=> ( isa => 'Str|Undef', is => 'rw', required	=>	0 );
has 'vhost'		=> ( isa => 'Str|Undef', is => 'rw', required	=>	0 );
has 'modulestring'	=> ( isa => 'Str|Undef', is => 'rw', default	=> "Agua::Workflow" );

# Objects
has 'conf'		=> ( isa => 'Conf::Yaml', is => 'rw', required	=>	0 );
has 'nova'		=> ( isa => 'Openstack::Nova', is => 'rw', lazy	=>	1, builder	=>	"setNova" );
has 'synapse'	=> ( isa => 'Synapse', is => 'rw', lazy	=>	1, builder	=>	"setSynapse" );
has 'jsonparser'=> ( isa => 'JSON', is => 'rw', lazy	=>	1, builder	=>	"setJsonParser" );
has 'db'	=> ( isa => 'Agua::DBase::MySQL|Undef', is => 'rw', required	=>	0 );

use FindBin qw($Bin);
use Test::More;

use Openstack::Nova;
use Agua::Workflow;

#####////}}}}}

method BUILD ($args) {
	$self->initialise($args);	
}

method initialise ($args) {
	#$self->logDebug("args", $args);	
}

method listen {
	my $taskqueue =	$self->conf()->getKey("queue:taskqueue", undef);
	$self->logDebug("taskqueue", $taskqueue);
	
	$self->receiveTask($taskqueue);	
}

method receiveTask ($taskqueue) {
	$self->logDebug("queue", $taskqueue);
	
	#### OPEN CONNECTION
	my $connection	=	$self->newConnection();	
	my $channel 	= 	$connection->open_channel();
	$self->channel($channel);
	$self->channel()->declare_queue(
		queue => $taskqueue,
		durable => 1,
	);
	
	print " [*] Waiting for tasks in queue: $taskqueue\n";
	
	$self->channel()->qos(prefetch_count => 1,);
	
	no warnings;
	my $handler	= *handleTask;
	use warnings;
	my $this	=	$self;
	
	$self->channel()->consume(
		on_consume	=>	sub {
			my $var 	= 	shift;
			print "Exchange::receiveTask    DOING CALLBACK";
			#print Dumper $var;
		
			my $body 	= 	$var->{body}->{payload};
			print " [x] Received $body\n";
		
			my @c = $body =~ /\./g;
			sleep(10);
			#sleep(scalar(@c));
		
			print " [x] Done\n";
			$channel->ack();
			#print " AFTER channel->ack()\n";

			&$handler($this, $body);
		},
		no_ack => 0,
	);
	
	# Wait forever
	AnyEvent->condvar->recv;	
}

method handleTask ($json) {
	$self->logDebug("json", $json);
	my $data = $self->jsonparser()->decode($json);    
	$self->logDebug("data", $data);

	$self->setDbh() if not defined $self->db();

	$data->{start}		=  1;
	$data->{conf}		=  $self->conf();
	#$data->{db}			=  $self->db();
	$data->{showlog}	=  $self->showlog();
	$data->{printlog}	=  $self->printlog();
	
	my $workflow = Agua::Workflow->new($data);
	print "workflow: $workflow\n";
	$self->logDebug("workflow");

	$workflow->executeWorkflow();
}

method setJsonParser {
	return JSON->new->allow_nonref;
}




} #### END