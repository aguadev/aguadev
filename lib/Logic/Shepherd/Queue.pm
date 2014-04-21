use MooseX::Declare;
class Logic::Shepherd::Queue with (Agua::Common::Exchange, Agua::Common::Util) extends Logic::Shepherd {

#### EXTERNAL MODULES
use Data::Dumper;
use File::Path;
use threads ('yield',
			'stack_size' => 64*4096,
			'exit' => 'threads_only',
			'stringify');

use FindBin::Real;
use lib FindBin::Real::Bin() . "/lib";
use lib FindBin::Real::Bin() . "../../../../lib";
use Conf::Yaml;

# Strings
has 'sleep'			=> 	( isa => 'Str|Undef', is => 'rw', default => 10 );
has 'max'			=> 	( isa => 'Str|Undef', is => 'rw', default => 10 );
has 'commandfile'	=> 	( isa => 'Str|Undef', is => 'rw' );

# Objects
has 'commands'		=> 	( isa => 'ArrayRef|Undef', is => 'rw', default => undef );
has 'nodes'			=>	( isa => 'ArrayRef|Undef', is => 'rw', default => undef );
has 'conf'	=> ( isa => 'Conf::Yaml', is => 'rw', lazy => 1, builder => "setConf" );

####////}}}

method BUILD ($args) {
	if ( defined $args ) {
		foreach my $arg ( keys %$args ) {
			$self->$arg($args->{$arg}) if defined $args->{$arg};
		}
	}
	$self->logDebug("args", $args);

	if ( not defined $self->commands() ) {
		my $commandfile	=	$self->commandfile();
		if ( defined $commandfile ) {
			open(FILE, $commandfile) or die "Can't open commandfile: $commandfile\n";
			$/ = "\n";
			my @lines 		=	<FILE>;
			close(FILE) or die "Can't close commandfile: $commandfile\n";
			my $commands	=	[];
			foreach my $line ( @lines ) {
				next if $line =~ /^#/;
				next if $line =~ /^\s*$/;
				push @$commands, $line;
			}
			
			$self->commands($commands);
		}
	}	
}

method run {
	my $commands	=	$self->commands();
	my $sleep		=	$self->sleep();
	my $max			=	$self->max();
	$self->logDebug("max", $max);
	$self->logDebug("commands", $commands);
	$self->logDebug("# commands", scalar(@$commands));
	
	#### COPY COMMANDS
	$commands = $self->copyArray($commands);
	
	my $outputs = [];
	my $threads = [];

	while ( scalar(@$commands) > 0 ) {
		$threads	=	$self->loadThreads($commands, $threads, $max);
#		$self->logDebug("threads", $threads);
		$self->logDebug("# threads", scalar(@$threads));
#
		sleep($sleep);
#
		($outputs, $threads)	=	$self->pollThreads($outputs, $threads);
		$self->logDebug("outputs", $outputs);
#		$self->logDebug("threads", $threads);
		$self->logDebug("# threads", scalar(@$threads));
	}
	while ( scalar(@$threads) > 0 ) {
		for ( my $i = 0; $i < @$threads; $i++ ) {
			my $thread	=	$$threads[$i];
			if ( $thread->is_joinable() ) {
				my $output = $thread->join;
				splice @$threads, $i, 1;
				$i--;
				push @$outputs, $output;
			}
		}
		sleep($sleep);
	}
	$self->logDebug("Finished doing parallel jobs");
	
	return $outputs;
}

method loadThreads ($commands, $threads, $max) {
	return undef if not defined $max;
	return undef if not defined $commands;
	$threads = [] if not defined $threads;
	$self->logDebug("commands", $commands);
	
	$max = scalar(@$commands) if $max > scalar(@$commands);
	
	for ( my $i = 0; $i < $max; $i++ ) {
		my $command = splice @$commands, 0, 1;
		my $thread = threads->new(
			sub {
				$self->logDebug("thread $i Running command: $command\n");
				my $output =	`$command`;
				chomp($output);
				
				return $output;
			}
		);
		push @$threads, $thread;
	}
	$self->logDebug("Returning # threads", scalar(@$threads));

	return ($commands, $threads);	
}

method pollThreads ($outputs, $threads) {

	for ( my $i = 0; $i < @$threads; $i++ ) {
		my $thread 	=	$$threads[$i];
		if ( $thread->is_joinable() ) {
			my $output = $thread->join;
			splice @$threads, $i, 1;
			push @$outputs, $output;
			$i--;
		}			
	}

	return ($outputs, $threads);
}



method copyArray ($array) {
	my $output	=	[];
	for ( my $i = 0; $i < @$array; $i++ ) {
		$$output[$i]	=	$$array[$i];
	}
	$self->logDebug("returning output", $output);
	
	return $output;
}


}

