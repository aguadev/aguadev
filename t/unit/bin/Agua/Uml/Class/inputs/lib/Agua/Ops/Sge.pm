package Agua::Ops::Sge;
use Moose::Role;
use Method::Signatures::Simple;

#### SUN GRID ENGINE METHODS

method stopSgeProcess ($port) {
	$self->logDebug("Ops::stopSgeProcess(port)");
	$self->logDebug("port", $port);
	#### INPUT FORMAT: netstat -ntulp | grep sge_*
	#### tcp        0      0 0.0.0.0:36472           0.0.0.0:*               LISTEN      9855/sge_exec
	my $netstat = qq{netstat -ntulp | grep sge | grep $port};
	$self->logDebug("netstat", $netstat);
	my $output = $self->runCommand($netstat);
	my ($pid) = $output =~ /^\s*\S+\s+\S+\s+\S+\s+[^:]+:\d+\s+\S+\s+\S+\s+(\d+)\/\S+\s*/;
	$self->logDebug("pid", $pid)  if defined $pid;
	$self->logDebug("pid NOT DEFINED. No running SGE port") if not defined $pid;
	return if not defined $pid;
	
	$self->killProcess($pid);
}

method killProcess ($pid) {
	$self->logError("pid is empty") and exit if $pid eq '';
	my $command = "kill -9 $pid";
	$self->logDebug("command", $command);
	$self->runCommand($command);
}

method qmasterRunning ($port) {
#### VERIFY THAT THE SGE MASTER DAEMON IS LISTENING AT CORRECT PORT
	$self->logDebug("port", $port);
	return $self->sgeProcessListening($port, "sge_qmaster");
}

method execdRunning ($port) {
#### VERIFY THAT SGE EXEC DAEMON IS LISTENING AT CORRECT PORT
	$self->logDebug("port", $port);
	return $self->sgeProcessListening($port, "sge_execd");
}

method sgeProcessListening ($port, $pattern) {
#### LISTENER VERIFIER. LATER: REDO WITH REGEX
	$self->logDebug("port", $port);
	$self->logDebug("pattern", $pattern)  if defined $pattern;
	$self->logError("Neither port nor pattern are defined") and exit if not defined $port and not defined $pattern;

	my $command = "netstat -ntulp ";
	$command .= "| grep $port " if defined $port;
	$command .= "| grep $pattern " if defined $pattern;

	#### EXPECTED OUTPUT FORMAT:
	####tcp        0      0 0.0.0.0:36361           0.0.0.0:*               LISTEN      5920/sge_qmaster
	####tcp        0      0 0.0.0.0:36362           0.0.0.0:*               LISTEN      4780/sge_execd
	
	my ($result) = $self->runCommand($command);	
	$result =~ s/\s+$//;
	$self->logDebug("result", $result);

	return $result if defined $result and $result;
	return 0;
}


1;
