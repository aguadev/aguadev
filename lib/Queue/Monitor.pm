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

class Queue::Monitor with (Logger, Agua::Common::Util, Exchange) {

#####////}}}}}

# Integers
has 'log'	=> ( isa => 'Int', 		is => 'rw', default	=> 	2	);  
has 'printlog'	=> ( isa => 'Int', 		is => 'rw', default	=> 	2	);
has 'sleep'		=>  ( isa => 'Int', is => 'rw', default => 300 );

# Strings
has 'command'	=> ( isa => 'Str|Undef', is => 'rw'	);
has 'logfile'	=> ( isa => 'Str|Undef', is => 'rw'	);

# Objects
has 'conf'		=> ( isa => 'Conf::Yaml', is => 'rw', required	=>	0 );
has 'ops'		=> ( isa => 'Agua::Ops', is => 'rw', lazy => 1, builder => "setOps" );

use FindBin qw($Bin);
use Test::More;
use Data::Dumper;

#####////}}}}}

method initialise ($hash) {
	#### SET SLOTS
	$self->setSlots($hash);
	$self->logDebug("AFTER self->setSlots()");
}

method monitor {
	$self->logDebug("");

	#### PERIODICALLY CHECK FOR WORKER UPSTART HEARTBEAT
	while ( 1 ) {
		$self->logDebug("DOING self->checkWorker");
		$self->checkWorker();
		my $sleep	=	$self->sleep();
		print "Queue::Monitor::monitor    Sleeping $sleep seconds before checkWorker\n";
		sleep($sleep);
	}	
}

method checkWorker {
	my $name		=	"worker";
	my $logfile		=	"/var/log/upstart/$name.log";
	
	$self->logDebug("logfile", $logfile);
	print "Returning. Can't find logfile: $logfile\n" and return if not -f $logfile;

	my $command		=	"tail $logfile";
	$self->logDebug("command", $command);
	my $log	=	`$command`;
	$self->logDebug("log", $log);
	if ( $log =~	/Heartbeat lost/msi ) {
		print "HEARTBEAT LOST. Doing restartUpstart($name, $logfile)\n";
		$self->logDebug("HEARTBEAT LOST    Doing restartUpstart($name, $logfile)");	
		$self->restartUpstart($name, $logfile);
	}
}

method restartUpstart ($name, $logfile) {
	$self->logDebug("name", $name);
	$self->logDebug("logfile", $logfile);

	my $command		=	qq{ps aux | grep "perl /usr/bin/$name"};
	$self->logDebug("ps command", $command);
	my $output	=	`$command`;
	#$self->logDebug("output", $output);
	my $processes;
	@$processes	=	split "\n", $output;
	#$self->logDebug("processes", $processes);
	foreach my $process ( @$processes ) {
		#$self->logDebug("process", $process);
		my ($pid)	=	$process	=~	/^\S+\s+(\S+)/;
		my $command	=	"kill -9 $pid";
		$self->logDebug("KILL command", $command);
		`$command`;
	}
	
	#### REMOVE LOG FILE
	$command	=	"rm -fr $logfile";
	$self->logDebug("DELETE command", $command);
	`$command`;
	
	#### RESTART UPSTART PROCESS
	$command	=	"service $name restart";
	$self->logDebug("RESTART command", $command);
	`$command`;
	
	$self->logDebug("END");
}



}

