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

class Queue::Monitor with (Logger, Agua::Common::Util, Agua::Common::Exchange) {

#####////}}}}}

# Integers
has 'showlog'	=> ( isa => 'Int', 		is => 'rw', default	=> 	2	);  
has 'printlog'	=> ( isa => 'Int', 		is => 'rw', default	=> 	2	);

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

method systemCommand {
	$self->logDebug("");
	my $command	=	$self->command();
	$self->logDebug("command", $command);
	#my $ops	=	$self->ops();
	#print Dumper $ops;
	
	my ($stdout, $stderr)	=	$self->runCommand($command);
	$self->logDebug("stdout", $stdout);
	$self->logDebug("stderr", $stderr);
	
	$self->notifyStatus({
		#username	=>	$self->username(),
		status		=>	"ready",
		error		=>	"",
		queue		=> 	"routing",
		data 		=> {
			stdout => $stdout,
			stderr => $stderr,
		}
	});
	print "AFTERRRRRRRRRRRRRR\n";
	
	return 1;
}

method runCommand ($command) {
#### RUN COMMAND LOCALLY OR ON REMOTE HOST
	#### ADD ENVIRONMENT VARIABLES IF EXIST
	$self->showlog(4);
	$self->logDebug("command", $command);

	my $stdoutfile = "/tmp/$$.out";
	my $stderrfile = "/tmp/$$.err";
	my $output = '';
	my $error = '';
	
	#### TAKE REDIRECTS IN THE COMMAND INTO CONSIDERATION
	if ( $command =~ />\s+/ ) {
		#### DO NOTHING, ERROR AND OUTPUT ALREADY REDIRECTED
		if ( $command =~ /\s+&>\s+/
			or ( $command =~ /\s+1>\s+/ and $command =~ /\s+2>\s+/)
			or ( $command =~ /\s+1>\s+/ and $command =~ /\s+2>&1\s+/) ) {
			print `$command`;
		}
		#### STDOUT ALREADY REDIRECTED - REDIRECT STDERR ONLY
		elsif ( $command =~ /\s+1>\s+/ or $command =~ /\s+>\s+/ ) {
			$command .= " 2> $stderrfile";
			print `$command`;
			$error = `cat $stderrfile`;
		}
		#### STDERR ALREADY REDIRECTED - REDIRECT STDOUT ONLY
		elsif ( $command =~ /\s+2>\s+/ or $command =~ /\s+2>&1\s+/ ) {
			$command .= " 1> $stdoutfile";
			print `$command`;
			$output = `cat $stdoutfile`;
		}
	}
	else {
		$command .= " 1> $stdoutfile 2> $stderrfile";
		print `$command`;
		$output = `cat $stdoutfile`;
		$error = `cat $stderrfile`;
	}
	
	$self->logNote("output", $output) if $output;
	$self->logNote("error", $error) if $error;
		
	##### CHECK FOR PROCESS ERRORS
	$self->logError("Error with command: $command ... $@") and exit if defined $@ and $@ ne "" and $self->can('warn') and not $self->warn();

	#### CLEAN UP
	`rm -fr $stdoutfile`;
	`rm -fr $stderrfile`;
	chomp($output);
	chomp($error);
	
	return $output, $error;
}



}

