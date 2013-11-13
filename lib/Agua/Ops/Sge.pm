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

	#### ARBITRARY TIMEOUT
	my $timeout = 10;

	my $output = $self->timeoutCommand($netstat, $timeout);
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
	#### ARBITRARY TIMEOUT
	my $timeout = 10;
	return $self->sgeProcessListening($port, "sge_qmaster", $timeout);
}

method execdRunning ($port) {
#### VERIFY THAT SGE EXEC DAEMON IS LISTENING AT CORRECT PORT
	$self->logDebug("port", $port);
	#### ARBITRARY TIMEOUT
	my $timeout = 10;
	return $self->sgeProcessListening($port, "sge_execd", $timeout);
}

method sgeProcessListening ($port, $pattern, $timeout) {
#### LISTENER VERIFIER. LATER: REDO WITH REGEX
	$self->logDebug("port", $port);
	$self->logDebug("pattern", $pattern)  if defined $pattern;
	$self->logDebug("timeout", $timeout);
	$self->logError("Neither port nor pattern are defined") and exit if not defined $port and not defined $pattern;

	my $command = "netstat -ntulp ";
	$command .= "| grep $port " if defined $port;
	$command .= "| grep $pattern " if defined $pattern;
	$self->logDebug("command", $command);

	#### EXPECTED OUTPUT FORMAT:
	####tcp        0      0 0.0.0.0:36361           0.0.0.0:*               LISTEN      5920/sge_qmaster
	####tcp        0      0 0.0.0.0:36362           0.0.0.0:*               LISTEN      4780/sge_execd
	
	my ($result) = $self->timeoutCommand($command, $timeout);	
	$result =~ s/\s+$//;
	$self->logDebug("result", $result);

	return $result if defined $result and $result;
	return 0;
}

method getSgeBinRoot {
#### 	Return the CPU architecture-dependent path to the SGE binaries
####	NB: Assumes 64-bit system

	$self->logNote("Getting SGE bin root on MASTER");
	my $command = "grep vendor_id	/proc/cpuinfo";
	$self->logNote("command", $command);
	my ($vendorid) = $self->runCommand($command);
	$self->logNote("vendorid", $vendorid);

	#### ASCERTAIN IF CPU IS INTEL TYPE (ELSE, MUST BE AMD TYPE);
	my $isintel = $self->isIntel($vendorid);
	$self->logNote("isintel", $isintel);

	#### GET BIN DIR SUBDIRS
	#$self->logDebug("self->conf()", $self->conf());
	my $sgeroot = $self->conf()->getKey("agua", "SGEROOT");
	$self->logNote("sgeroot", $sgeroot);
	$command = "ls $sgeroot/bin";
	$self->logNote("command", $command);
	my ($filelist) = $self->runCommand($command);
	$self->logNote("filelist", $filelist);
	my @files   = split "\n", $filelist;
	$self->logNote("files", @files);

	my $binroot = $self->_getSgeBinRoot($sgeroot, $isintel, \@files);        
	$self->logNote("binroot", $binroot);    

	return $binroot
}

method isIntel ($vendorid) {
	#$self->logNote("$vendorid", $vendorid);

	my $match = $vendorid =~ /vendor_id\s+:\s+GenuineIntel\s*/;
	my $isintel = $match ? 1 : 0;
	$self->logNote("Returning isintel", $isintel);
	
	return $isintel
}

method _getSgeBinRoot ($sgeroot, $isintel, $files) {
	$self->logDebug("files", $files);

	my $binroot = "";
	foreach my $file ( @$files ) {
		if ( $isintel ) {
			if ( $file eq "lx24-x86" ) {
				$binroot = $sgeroot . "/bin/lx24-x86";
				last;
			}
			elsif ( $file eq "linux-x64" ) {
				$binroot = $sgeroot . "/bin/linux-x64";
				last;
			}
		}
		else {
			if ( $file eq "lx24-amd64" ) {
				$binroot = $sgeroot . "/bin/lx24-amd64";
				last;
			}
			elsif ( $file eq "linux-x64" ) { 
				$binroot = $sgeroot . "/bin/linux-x64";
				last;
			}
		}
	}
	$self->logNote("Returning binroot", $binroot);    

	return $binroot
}



1;
