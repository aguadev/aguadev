use MooseX::Declare;

=head2

	PACKAGE		Agua::Ssh
	
	PURPOSE
	
		WRAPPER TO PROVIDE BASIC SSH COMMAND AND SCP FUNCTIONALITY

=cut

class Agua::Ssh with (Agua::Common::Logger) {
	
use Data::Dumper;
use File::Path;


has 'keyfile'	=> ( is  => 'rw', 'isa' => 'Str|Undef', required	=>	1	);
has 'remotehost'=> ( is  => 'rw', 'isa' => 'Str|Undef', required	=>	1	);
has 'remoteuser'=> ( is  => 'rw', 'isa' => 'Str|Undef', required	=>	1	);
#has 'command'	=> ( is  => 'rw', 'isa' => 'Str|Undef', required	=>	0	);
#has 'source'	=> ( is  => 'rw', 'isa' => 'Str|Undef', required	=>	0	);
#has 'target'	=> ( is  => 'rw', 'isa' => 'Str|Undef', required	=>	0	);

method BUILD ($hash) {
	$self->logDebug("hash", $hash);
	$self->initialise();
}

method initialise () {
	$self->logDebug("");
	my $keyfile		=	$self->keyfile();
	my $remotehost	=	$self->remotehost();
	my $remoteuser	=	$self->remoteuser();
	$self->logDebug("keyfile", $keyfile);
	$self->logDebug("remotehost", $remotehost);
	$self->logDebug("remoteuser", $remoteuser);

	#### CHECK INPUTS
	$self->logError("keyfile not defined") and exit if not defined $keyfile or not $keyfile;	
	$self->logError("remotehost not defined") and exit if not defined $remotehost or not $remotehost;	
	$self->logError("remoteuser not defined") and exit if not defined $remoteuser or not $remoteuser;
}

method execute ($command) {
#### RUN COMMAND ON REMOTE, RETURN STDOUT AND STDERR
	$self->logDebug("command", $command);
	return if not defined $command or not $command;
	
	my $keyfile		=	$self->keyfile();
	my $remotehost	=	$self->remotehost();
	my $remoteuser	=	$self->remoteuser();
	$self->logDebug("keyfile", $keyfile);
	$self->logDebug("remotehost", $remotehost);
	$self->logDebug("remoteuser", $remoteuser);

	#### RUN COMMAND
	my $remotessh = "ssh -o StrictHostKeyChecking=no -i $keyfile $remoteuser\@$remotehost";
	$self->logDebug("remotessh", $remotessh);

	my $remotecommand = qq{$remotessh "$command"};
	$self->logDebug("remotecommand", $remotecommand);
	
	my $errfile = "/tmp/ssh.stderr.$$";
	my $output = `$remotecommand 2> $errfile`;
	my $error = `cat $errfile`;
	`rm -fr $errfile`;
	$self->logDebug("output", $output);
	$self->logDebug("error", $error);	

	return ($output, $error);
}

method scpPut ($source, $target) {
#### EXECUTE SCP put COMMAND
	return $self->scp($source, $target, "put");
}

method scpPut ($source, $target) {
#### EXECUTE SCP get COMMAND
	return $self->scp($source, $target, "get");
}

method scp ($source, $target, $method) {
#### EXECUTE put OR get SCP COMMAND
	$self->logNote("source", $source);
	$self->logNote("target", $target);
	$self->logNote("method", $method);

	#### CHECK INPUTS
	$self->logError("source not defined") and exit if not defined $source or not $source;
	$self->logError("target not defined") and exit if not defined $target or not $target;
	$self->logError("method not defined") and exit if not defined $method or not $method;
	$self->logError("method not supported: $method") and exit if $method !~ /^(get|put)$/;

	my $keyfile		=	$self->keyfile();
	my $remotehost	=	$self->remotehost();
	my $remoteuser	=	$self->remoteuser();
	$self->logNote("keyfile", $keyfile);
	$self->logNote("remotehost", $remotehost);
	$self->logNote("remoteuser", $remoteuser);

	#### RUN COMMAND
	my $command;
	if ( $method eq "put" ) {
		$command = "scp -o StrictHostKeyChecking=no -i $keyfile $remoteuser\@$remotehost:$source $target";
	}
	else {
		$command = "scp -o StrictHostKeyChecking=no -i $keyfile $source $remoteuser\@$remotehost:$target";
	}
	$self->logDebug("command", $command);

	my $errfile = "/tmp/ssh.stderr.$$";
	my $output = `$command 2> $errfile`;
	my $error = `cat $errfile`;
	`rm -fr $errfile`;
	$self->logNote("output", $output);
	$self->logNote("error", $error);	

	return ($output, $error);	
}


}

