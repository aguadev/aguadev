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

class Synapse with Logger {

#####////}}}}}

#### Integers
has 'SHOWLOG'		=>  ( isa => 'Int', is => 'rw', default => 2 );
has 'PRINTLOG'		=>  ( isa => 'Int', is => 'rw', default => 5 );
has 'count'			=>  ( isa => 'Int', is => 'rw', default => 50 );

##### Strings
has 'synapse'		=>  ( isa => 'Str|Undef', is => 'rw', lazy	=>	1, builder	=>	"setSynapse" );

##### Objects
has 'states'		=>  ( isa => 'HashRef|Undef', is => 'rw', lazy	=>	1, builder	=>	"setStates" );
has 'activestates'	=>  ( isa => 'ArrayRef|Undef', is => 'rw', lazy	=>	1, builder	=>	"setActiveStates" );

use FindBin qw($Bin);
use Test::More;

use Openstack::Nova;

#####////}}}}}


method addSamples ($args) {
	my $count 	=	$args->{count};
	$count		=	$self->count() if not defined $count;

	my $synapse		=	$self->synapse();
	my $command 	=	"$synapse getAssignments ucsc_biofarm --count=$count";
	$self->logDebug("command", $command);
	
	print `$command`;		
}

method list ($args) {
	my $synapse		=	$self->synapse();

	my $command 	=	"$synapse getAssignments ucsc_biofarm";
	$self->logDebug("command", $command);
	
	print `$command`;	
}

method clearErrors ($args) {	
	my $state	=	$args->{state};
	$self->logDebug("state", $state);
	
	if ( not defined $state ) {
		print "state not defined. Exiting\n";
		exit;
	}

	my ($current)	=	$state	=~ /error:(.+)/;
	$self->logDebug("current", $current);
	my $previous	=	$self->getPreviousState($current);	
	
	my $uuids	=	$self->getUuidsByState($state);
	$self->logDebug("uuids", $uuids);

	foreach my $uuid ( keys %$uuids ) {
		$self->change($uuid, $previous);
	}
}

method getPreviousState ($current) {
	my $states	=	$self->states();
	$self->logDebug("states", $states);

	my $reverse	=	$self->reverse($self->states());
	$self->logDebug("reverse", $reverse);

	my $previous	=	$reverse->{$current};
	$self->logDebug("previous", $previous);

	return $previous;
}

method getNextState ($current) {
	$self->logDebug("current", $current);
	my $states	=	$self->states();
	my $next	=	$states->{$current};
	$self->logDebug("next", $next);
	
	return $next;
}

method reverse ($hash) {
	my ($hash2, $key, $value);
	while ( ($key, $value) = each %$hash ) {
		$$hash2{$value}	=	$key;
	}
	
	return $hash2;
}

method setStates {
	return {
		'unassigned' 	=>	'todownload',
		'todownload' 	=>	'downloading',
		'downloading' 	=>	'downloaded',
		'downloaded' 	=>	'splitting',
		'splitting' 	=>	'split',
		'split' 		=>	'aligning',
		'aligning' 		=>	'aligned',
		'aligned' 		=>	'uploading',
		'uploading' 	=>	'uploaded'
	}
}

method setActiveStates {
	return [
		'downloading',
		'splitting',
		'aligning',
		'uploading'
	];
}

method getUuidsByState ($state) {
	my $assigned	=	$self->getAssignments();
	$self->logDebug("list");

	my $hash	=	{};
	foreach my $key ( keys %$assigned ) {
		$hash->{$key}	=	$assigned->{$key} if $assigned->{$key} eq $state;
	}
	
	return $hash;
}

method getAssignments {
	my $synapse		=	$self->synapse();
	
	my $command		=	"$synapse getAssignments ucsc_biofarm";
	$self->logDebug("command", $command);

	my $assigned = {};	
	my $list		=	`$command`;
	foreach my $line ( split "\n", $list ) {
		my ($uuid, $state)	=	$line	=~ /^(\S+)\s+(\S+)/;
		$self->logDebug("uuid", $uuid);
		$self->logDebug("state", $state);
		
		$assigned->{$uuid}	=	$state;
	}
	
	return $assigned;
}

method changeState ($args) {	
	my $state	=	$args->{state};
	my $target	=	$args->{target};
	my $uuid	=	$args->{uuid};
	$self->logDebug("state", $state);	
	$self->logDebug("target", $target);
	$self->logDebug("uuid", $uuid);

	if ( not defined $target ) {
		print "Synapse::changeState    target not defined. Exiting\n";
		exit;
	}
	
	if ( not defined $state ) {
		if ( not defined $uuid ) {
			print "Synapse::changeState    Either state or uuid must be provided. Exiting\n";
			exit;
		}
		else {
			print "Setting to '$target' uuid: $uuid\n";
			$self->change($uuid, $target);
		}
	}
	else {
		my $uuids	=	$self->getUuidsByState($state);
		foreach my $uuid ( keys %$uuids ) {
			print "Changing state to '$target': $uuid\n";
			$self->change($uuid, $target);
		}
	}
}

method change ($uuid, $state) {	
	my $synapse		=	$self->synapse();

	my $command 	=	"$synapse resetStatus $uuid --status $state";
	$self->logDebug("command", $command);
	
	print `$command`;
}


method setSynapse {
	#my $synapse = qq{source /agua/apps/bioapps/bin/pancancer/envars.sh; /agua/apps/bioapps/bin/pancancer/synapseICGCMonitor};
	my $synapse = qq{/agua/apps/bioapps/bin/pancancer/synapseICGCMonitor};

	$self->synapse($synapse);

	return $self->synapse();
}


}