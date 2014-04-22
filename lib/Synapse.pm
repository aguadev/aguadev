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


use Conf::Yaml;
use Agua::Ops;

#### Integers
has 'showlog'		=>  ( isa => 'Int', is => 'rw', default => 2 );
has 'printlog'		=>  ( isa => 'Int', is => 'rw', default => 5 );
has 'count'			=>  ( isa => 'Int', is => 'rw', default => 50 );

##### Strings
has 'executable'		=>  ( isa => 'Str|Undef', is => 'rw', lazy	=>	1, builder	=>	"setExecutable" );

##### Objects
has 'states'		=>  ( isa => 'HashRef|Undef', is => 'rw', lazy	=>	1, builder	=>	"setStates" );
has 'activestates'	=>  ( isa => 'ArrayRef|Undef', is => 'rw', lazy	=>	1, builder	=>	"setActiveStates" );
has 'conf'	=> ( isa => 'Conf::Yaml', is => 'rw', lazy => 1, builder => "setConf" );
has 'ops'	=> ( isa => 'Agua::Ops', is => 'rw', lazy => 1, builder => "setOps" );


use FindBin qw($Bin);
use Test::More;

use Openstack::Nova;

#####////}}}}}

method BUILD ($args) {
		#use Data::Dumper;
		#print "Synapse::BUILD    args:\n";
		#print Dumper $args;
}

method returnAssignment ($uuid) {
	my $executable		=	$self->executable();
	my $command		=	"$executable returnAssignment $uuid";
	$self->logDebug("command", $command);
	
	return `$command`;	
}

method assignError ($uuid, $error) {
	my $executable		=	$self->executable();
	my $command		=	qq{$executable errorAssignment $uuid "$error"};
	$self->logDebug("command", $command);
	
	return `$command`;
}

method addSamples ($args) {
	my $count 	=	$args->{count};
	$count		=	$self->count() if not defined $count;

	my $executable		=	$self->executable();
	my $command 	=	"$executable getAssignments ucsc_biofarm --count=$count";
	$self->logDebug("command", $command);
	
	print `$command`;		
}

method list ($args) {
	my $executable		=	$self->executable();
	my $command 	=	"$executable getAssignments ucsc_biofarm";
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
	my $executable		=	$self->executable();
	my $command		=	"$executable getAssignments ucsc_biofarm";
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

method getWorkAssignment ($state) {
		my $executable		=	$self->executable();
		my $command		=	"$executable getAssignmentForWork ucsc_biofarm $state";
		$self->logDebug("command", $command);
		
		my $uuid	=		`$command`;
		$uuid	=~ s/\s+$//;
		
		return $uuid;
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
	my $executable		=	$self->executable();
	my $command 	=	"$executable resetStatus $uuid --status $state";
	$self->logDebug("command", $command);
	
	print `$command`;
}


method setExecutable {

		#### SET PYTHON ON PATH
		my $python	=	$self->conf()->getKey("packages:python", "2.7.3");
		$self->logDebug("python", $python);
		my $installdir	=	$python->{INSTALLDIR};
		$self->logDebug("installdir", $installdir);
		my $export	=	"export PATH=$installdir";

		#### SET SYNAPSE EXECUTABLE
		my $version = $self->latestVersion("synapse");
		$self->logDebug("version", $version);
		my $app	=	$self->conf()->getKey("packages:synapse", $version);
		my $location	=	$app->{INSTALLDIR};
		$self->logDebug("location", $location);

		return "$export; $location";
}

method latestVersion ($package) {
	$self->logDebug("package", $package);
	my $subkey	=	undef;
	my $installations	=	$self->conf()->getKey("packages", $package);
	$self->logDebug("installations", $installations);

	my $versions;
	@$versions	=	keys %$installations;
	$self->logDebug("versions", $versions);

	$versions	=	$self->ops()->sortVersions($versions);
	$self->logDebug("versions", $versions);
	
	my $latest	=	$$versions[ scalar(@$versions) - 1];
	$self->logDebug("latest", $latest);
	
	return $latest;
}

method setConf {
	my $conf 	= Conf::Yaml->new({
		backup		=>	1,
		showlog		=>	$self->showlog(),
		printlog	=>	$self->printlog()
	});
	
	$self->conf($conf);
}

method setOps () {
	my $ops = Agua::Ops->new({
		conf		=>	$self->conf(),
		showlog		=>	$self->showlog(),
		printlog	=>	$self->printlog()
	});

	$self->ops($ops);	
}



}