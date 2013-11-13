use MooseX::Declare;

class Test::Agua::Common::Logger with (Agua::Common::Logger, Agua::Common::Util) {
use Data::Dumper;
use Test::More;
use FindBin qw($Bin);

# Ints
has 'SHOWLOG'	=> ( isa => 'Int', 		is => 'rw', default	=> 	2);
has 'PRINTLOG'	=> ( isa => 'Int', 		is => 'rw', default	=> 	5);

# Strings

# Objects
has 'handlers'	=> ( isa => 'Any', 	is	=>	'rw', builder	=>	'setHandlers', lazy => 0 );

####///}}}

method BUILD ($hash) {
}

method setHandlers {
	$SIG{__WARN__} = sub { $self->WARN_handler(@_) };
	$SIG{__DIE__} = sub { $self->DIE_handler(@_) };
	return %SIG;
}

method test_WARN_Handler {
	diag("Test WARN_Handler");
	
	my $logfile = "$Bin/outputs/warnhandler.log";
	$self->startLog($logfile);
	$self->SHOWLOG(5);
	$self->PRINTLOG(5);

	for (my $x = 1; $x < 3; $x++) {
		warn "warning $x";
		sleep 1;
	}	

	chdir("$Bin/inputs/exists") or warn("warning 3: " . $!);
	ok(1, "WARN_handler    passed try chdir existing directory");
	chdir("$Bin/outputs/doesnotexist") or warn("warning 4: " . $!);
	
	my $contents = 	`cat $logfile`;
	ok($contents =~ /warning 1/ms, "WARN_handler    warning 1");
	ok($contents =~ /warning 2/ms, "WARN_handler    warning 2");
	ok($contents !~ /warning 3/ms, "WARN_handler    no warning 3 because directory exists");
	ok($contents =~ /warning 4/ms, "WARN_handler    warning 4 directory not exists");
	
}


method test_DIE_Handler {
	diag("Test DIE_Handler");

	my $logfile = "$Bin/outputs/diehandler.log";
	$self->startLog($logfile);
	$self->SHOWLOG(2);
	$self->PRINTLOG(5);

	chdir("$Bin/inputs/exists") or warn($!);
	ok(1, "DIE_handler    NO DIE when chdir to existing directory");

	my $pid = fork();
	if ( not $pid ) {
		$self->mustDie();
	}
	else {
		sleep(1);
		my $contents = 	`cat $logfile`;
		ok($contents =~ /No such file or directory at/ms, "DIE_handler    DIE because directory not found");
	}
}

method mustDie {
	chdir("$Bin/inputs/doesnotexist") or die($!);
}

method testStartLog () {
	diag("Test startLog");

	my $logfile = "$Bin/outputs/start.log";
	$self->startLog($logfile);
	$self->SHOWLOG(2);
	$self->PRINTLOG(5);
	my $random = rand(99999999999);
	$self->logDebug("FIRST ENTRY IN LOG FILE", $random);
	my $content = `cat $logfile`;
	ok($content =~ /FIRST ENTRY IN LOG FILE: $random/, "startLog    correct content in logfile");
	$self->stopLog();
}

method testStopLog () {
	diag("Test stopLog");

	my $logfile = "$Bin/outputs/stop.log";
	$self->startLog($logfile);
	$self->SHOWLOG(2);
	$self->PRINTLOG(5);
	my $random = rand(99999999999);
	$self->logDebug("FIRST ENTRY IN LOG FILE", $random);
	warn "BEFORE stopLog    THIS STDERR SHOULD APPEAR IN LOG FILE\n";

	$self->stopLog();
	warn "AFTER stopLog    THIS STDERR SHOULD NOT APPEAR IN LOG FILE\n";
	$self->logDebug("THIS STDOUT SHOULD NOT APPEAR IN LOG FILE");

	my $content = `cat $logfile`;
	ok($content =~ /FIRST ENTRY IN LOG FILE: $random/, "stopLog    correct log entry");
	ok($content =~ /BEFORE stopLog    THIS STDERR SHOULD APPEAR IN LOG FILE/, "stopLog    correct STDERR before stopLog");
	ok($content !~ /AFTER stopLog    THIS STDERR SHOULD NOT APPEAR IN LOG FILE/, "stopLog    correct STDERR after stopLog");
	ok($content !~ /THIS STDOUT SHOULD NOT APPEAR IN LOG FILE/, "stopLog    correctly failed to log after stopLog");
}

method testPauseLog () {
	diag("Test pauseLog");

	my $logfile = "$Bin/outputs/pause.log";
	$self->startLog($logfile);
	$self->SHOWLOG(2);
	$self->PRINTLOG(5);
	my $random = rand(99999999999);
	$self->logDebug("FIRST LOG ENTRY", $random);
	$self->logDebug("THIS STDOUT SHOULD APPEAR IN LOG FILE");
	warn "BEFORE pauseLog    THIS STDERR SHOULD APPEAR IN LOG FILE\n";
	$self->pauseLog();
	warn "AFTER pauseLog    THIS STDERR SHOULD ALSO APPEAR IN LOG FILE\n";
	$self->logDebug("BEFORE resumeLog    THIS STDOUT SHOULD NOT APPEAR IN LOG FILE");
	$self->resumeLog();
	$self->logDebug("AFTER resumeLog    THIS STDOUT SHOULD APPEAR IN LOG FILE");
	warn "AFTER resumelog    THIS STDERR SHOULD APPEAR IN LOG FILE\n";

	my $content = `cat $logfile`;
	$content = `cat $logfile`;
	ok($content =~ /FIRST LOG ENTRY: $random/, "pauseLog    correct log entry");
	ok($content !~ /BEFORE pauseLog    THIS STDOUT SHOULD NOT APPEAR IN LOG FILE/, "pauseLog    correct STDOUT before pauseLog");
	ok($content =~ /BEFORE pauseLog    THIS STDERR SHOULD APPEAR IN LOG FILE/, "pauseLog    correct STDERR before pauseLog");
	ok($content =~ /AFTER resumeLog    THIS STDOUT SHOULD APPEAR IN LOG FILE/, "pauseLog    correct STDOUT after resumeLog");
	ok($content =~ /AFTER resumelog    THIS STDERR SHOULD APPEAR IN LOG FILE/, "pauseLog    correct STDERR after resumeLog");
	
	$self->stopLog();
}

method testResumeLog {
	diag("Test resumeLog");
	
	my $logfile = "$Bin/outputs/resume.log";
	$self->startLog($logfile);
	$self->SHOWLOG(2);
	$self->PRINTLOG(5);
	my $random = rand(99999999999);
	$self->logDebug("FIRST ENTRY IN LOG FILE", $random);
	warn "BEFORE pauseLog    THIS STDERR SHOULD APPEAR IN LOG FILE\n";

	$self->pauseLog();	
	warn "AFTER pauseLog    THIS STDERR SHOULD NOT APPEAR IN LOG FILE\n";
	$self->logDebug("AFTER pauseLog    THIS STDOUT SHOULD APPEAR IN LOG FILE");

	$self->resumeLog();
	$self->logDebug("AFTER resumeLog    THIS STDOUT SHOULD APPEAR IN LOG FILE");
	warn "AFTER resumeLog    THIS STDERR SHOULD APPEAR IN LOG FILE\n";
	
	my $content = `cat $logfile`;
	ok($content =~ /FIRST ENTRY IN LOG FILE: $random/, "resumeLog    correct logging before pauseLog");
	ok($content =~ /BEFORE pauseLog    THIS STDERR SHOULD APPEAR IN LOG FILE/, "resumeLog    correct STDERR before pauseLog");
	ok($content !~ /AFTER pauseLog    THIS STDERR SHOULD APPEAR IN LOG FILE/, "resumeLog    correct STDERR after pauseLog");
	ok($content !~ /AFTER pauseLog    THIS STDOUT SHOULD NOT APPEAR IN LOG FILE/, "resumeLog    correctly not logging after pauseLog");
	ok($content =~ /AFTER resumeLog    THIS STDOUT SHOULD APPEAR IN LOG FILE/, "resumeLog    correctly logging after resumeLog");
	ok($content =~ /AFTER resumeLog    THIS STDERR SHOULD APPEAR IN LOG FILE/, "resumeLog    correct STDERR after resumeLog");
	
	$self->stopLog();
}

method testLogDebug {
	diag("Test logDebug");

	my $logfile = "$Bin/outputs/logdebug.log";
	$self->startLog($logfile);
	$self->SHOWLOG(2);
	$self->PRINTLOG(5);
	
	my $var = { test =>     1};
	my $undef = undef;
	ok($self->logDebug("one arg") =~ /one arg$/, "logDebug    one arg");
	my $result = $self->logDebug("two args, defined", $var);
	ok( $result =~ /two\s+args,\s+defined:\s+{"test":1}\s*$/ms, "logDebug    two args");
	ok($self->logDebug("two args, undefined", $undef) =~ /two args, undefined: undef$/, "logDebug    two args, undef");	
}


}   #### Test::Agua::Common::Logger