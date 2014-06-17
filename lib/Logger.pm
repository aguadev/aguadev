package Logger;
use Moose::Role;

=head2

ROLE        Logger

PURPOSE

	1. PRINT MESSAGE TO STDOUT AND/OR LOG FILE

	2. PREFIX DATETIME AND CALLING CLASS, FILE AND LINE NUMBER

	3. 'LOGLEVEL' VARIABLE SPECIFIES WHICH CATEGORIES OF LOG TO OUTPUT:
		
		LOGLEVEL	Outputs (incl. previous level)	Example
		
			1		logCritical 	"SYSTEM FAILURE... QUITTING"
				
			2		logWarning 		"POSSIBLE ERROR ... CONTINUING"

			3		logInfo 		"SOMETHING MIGHT HAPPEN HERE"

			4		logDebug		"CHECKING HERE FOR ERRORS"
					logCaller
					logDebug	
			
			5		logNote 		"NOTHING HAPPENED, WE ARE HERE"

	4. logCaller METHOD INCLUDES THE FOLLOWING INFORMATION:
	
			-	DATETIME
		
			-	NAME OF THE CALLING METHOD
		
			-	LINE NUMBER IN FILE OF CALLING METHOD

		
	5. logError AND logStatus PRINT REGARDLESS OF THE LOGLEVEL

		logError	LOGFILE & STDOUT 	{ error: ... , module, line, datetime }
		
		logStatus	STDOUT	 			{ status: ..., module, line, datetime }

=cut

#Boolean
has 'backup' 	=> ( isa => 'Int', 		is => 'rw', default => 0 );
# Ints
has 'log'	=> ( isa => 'Int', 		is => 'rw', default	=> 	2	);  
has 'printlog'	=> ( isa => 'Int', 		is => 'rw', default	=> 	2	);
has 'oldlog'=> ( isa => 'Int', 		is => 'rw', default	=> 	2	);  
has 'oldprintlog'=> ( isa => 'Int', 		is => 'rw', default	=> 	2	);
has 'errpid' 	=> ( isa => 'Int', 		is => 'rw', required => 0 );
has 'indent'	=> ( isa => 'Int', 		is => 'rw', default	=>	4 );

# Strings
has 'logfile'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'username' 	=> ( isa => 'Str|Undef', 		is => 'rw', required => 0 );

# Objects
has 'logfh'     => ( isa => 'FileHandle|Undef', is => 'rw', required => 0 );
has 'oldout' 	=> ( isa => 'FileHandle', is => 'rw', required => 0 );
has 'olderr' 	=> ( isa => 'FileHandle', is => 'rw', required => 0 );

#### EXTERNAL MODULES
use Data::Dumper;
use PadWalker qw/peek_my peek_our/;

sub get_name_my {
    my $pad = peek_my($_[0] + 1);
    for (keys %$pad) {
        return $_ if $$pad{$_} == \$_[1]
    }
}
sub get_name_our {
    my $pad = peek_our($_[0] + 1);
    for (keys %$pad) {
        return $_ if $$pad{$_} == \$_[1]
    }
}
sub get_name_stash {
    my $caller = caller($_[0]) . '::';
    my $stash = do {
        no strict 'refs';
        \%$caller
    };
    my %lookup;
    for my $name (keys %$stash) {
        if (ref \$$stash{$name} eq 'GLOB') {
            for (['$' => 'SCALAR'],
                 ['@' => 'ARRAY'],
                 ['%' => 'HASH'],
                 ['&' => 'CODE']) {
                if (my $ref = *{$$stash{$name}}{$$_[1]}) {
                    $lookup{$ref} ||= $$_[0] . $caller . $name
                }
            }
        }
    }
    $lookup{\$_[1]}
}
sub get_name {
    unshift @_, @_ == 2 ? 1 + shift : 1;
    &get_name_my  or
    &get_name_our or
    &get_name_stash
}


sub log {
    my ($self, $variable) = @_;

	my $name = get_name(1, $variable) || 'name not found';
	print "$name: $name\n";
	
	return -1 if not $self->log() > 3 and not $self->printlog() > 3;

	$name = '' if not defined $name;
    $self->appendLog($self->logfile()) if not defined $self->logfh();   

	my $text = $variable;
	if ( not defined $variable and $#_ == 2 )	{
		$text = "undef";
	}
	elsif ( ref($variable) )	{
		$text = $self->objectToJson($variable);
	}

    my ($package, $filename, $linenumber) = caller;
    my $timestamp = $self->logTimestamp();
	my $callingsub = (caller 1)[3] || '';
	
	my $indent = $self->indent();
	my $spacer = " " x $indent;
	my $line = "$timestamp$spacer" . "[DEBUG]   \t$callingsub\t$linenumber\t$name\n";
	$line = "$timestamp$spacer" . "[DEBUG]   \t$callingsub\t$linenumber\t$name: $text\n" if $#_ == 2;

    print { $self->logfh() } $line if defined $self->logfh() and $self->printlog() > 3;
    print $line if $self->log() > 3;
	return $line;
}


sub setUserLogfile {
	my ($self, $username, $identifier, $mode) =	@_;
	
	return "/tmp/$username.$identifier.$mode.log";
}

sub WARN_handler {
    my($self, $signal) = @_;

    my ($package, $filename, $linenumber) = caller;
    my $timestamp = $self->logTimestamp();
	my $callingsub = (caller 1)[3] || '';
	my $line = "$timestamp\t[WARN]   \t$callingsub\t$linenumber\t$signal";
	
    print STDERR $line;
	print { $self->logfh() } $line if defined $self->logfh();
}

sub DIE_handler {
    my($self, $signal) = @_;

    my ($package, $filename, $linenumber) = caller;
    my $timestamp = $self->logTimestamp();
	my $callingsub = (caller 1)[3] || '';
	my $line = "$timestamp\t[DIE]   \t$callingsub\t$linenumber\t$signal";
	
    print STDERR $line;
	print { $self->logfh() } $line if defined $self->logfh();
}

sub logGroup {
    my ($self, $message) = @_;
	$message = '' if not defined $message;
    $self->appendLog($self->logfile()) if not defined $self->logfh();

	#### SET INDENT	
	#$self->logDebug("BEFORE self->indent", $self->indent());
	my $indent = $self->indent();
	$indent += 4;
	$self->indent($indent);
	#$self->logDebug("AFTER self->indent", $self->indent());

	#### SET LINE
    my ($package, $filename, $linenumber) = caller;
    my $timestamp = $self->logTimestamp();
	my $callingsub = (caller 1)[3] || '';
	my $spacer = " " x $indent;
    my $line = "$timestamp$spacer". "[GROUP]    \t$callingsub\t$linenumber\t$message\n";

    print { $self->logfh() } $line if defined $self->logfh() and $self->printlog() > 3;
    print $line if $self->log() > 3;

	return $line;
}

sub logGroupEnd {
    my ($self, $message) = @_;
	$message = '' if not defined $message;
    $self->appendLog($self->logfile()) if not defined $self->logfh();

	#### SET INDENT	
	#$self->logDebug("BEFORE self->indent", $self->indent());
	my $indent = $self->indent();
	#$self->logDebug("AFTER self->indent", $self->indent());

	#### SET LINE
    my ($package, $filename, $linenumber) = caller;
    my $timestamp = $self->logTimestamp();
	my $callingsub = (caller 1)[3] || '';
	my $spacer = " " x $indent;
    my $line = "$timestamp$spacer". "[GROUPEND]    \t$callingsub\t$linenumber\t$message\n";

    print { $self->logfh() } $line if defined $self->logfh() and $self->printlog() > 3;
    print $line if $self->log() > 3;

	$indent -= 4;
	$indent = 2 if $indent < 4;
	$self->indent($indent);

	return $line;
}

sub logReport {
    my ($self, $message) = @_;
	$message = '' if not defined $message;
    $self->appendLog($self->logfile()) if not defined $self->logfh();

    my $timestamp = $self->logTimestamp();
	my $line = "$timestamp\t[REPORT]   \t$message\n";

    print { $self->logfh() } $line if defined $self->logfh();

	return $line;
}

sub logNote {
    my ($self, $message, $variable) = @_;
	return -1 if not $self->log() > 4 and not $self->printlog() > 4;

	$message = '' if not defined $message;
    $self->appendLog($self->logfile()) if not defined $self->logfh(); 

	my $text = $variable;
	if ( not defined $variable and $#_ == 2 )	{
		$text = "undef";
	}
	elsif ( ref($variable) )	{
		$text = $self->objectToJson($variable);
	}

    my ($package, $filename, $linenumber) = caller;
    my $timestamp = $self->logTimestamp();
	my $callingsub = (caller 1)[3] || '';

	my $indent = $self->indent();
	my $spacer = " " x $indent;
	my $line = "$timestamp$spacer" . "[NOTE]   \t$callingsub\t$linenumber\t$message\n";
	$line = "$timestamp$spacer" . "[NOTE]   \t$callingsub\t$linenumber\t$message: $text\n" if $#_ == 2;

    print { $self->logfh() } $line if defined $self->logfh() and $self->printlog() > 4;
    print $line if $self->log() > 4;
	return $line;
}

sub logDebug {
    my ($self, $message, $variable) = @_;
	
	return -1 if not $self->log() > 3 and not $self->printlog() > 3;

	$message = '' if not defined $message;
    $self->appendLog($self->logfile()) if not defined $self->logfh();   

	my $text = $variable;
	if ( not defined $variable and $#_ == 2 )	{
		$text = "undef";
	}
	elsif ( ref($variable) )	{
		$text = $self->objectToJson($variable);
	}

    my ($package, $filename, $linenumber) = caller;
    my $timestamp = $self->logTimestamp();
	my $callingsub = (caller 1)[3] || '';
	
	my $indent = $self->indent();
	my $spacer = " " x $indent;
	my $line = "$timestamp$spacer" . "[DEBUG]   \t$callingsub\t$linenumber\t$message\n";
	$line = "$timestamp$spacer" . "[DEBUG]   \t$callingsub\t$linenumber\t$message: $text\n" if $#_ == 2;

    print { $self->logfh() } $line if defined $self->logfh() and $self->printlog() > 3;
    print $line if $self->log() > 3;
	return $line;
}

sub logInfo {
    my ($self, $message) = @_;
	return -1 if not $self->log() > 2 and not $self->printlog() > 2;
	
	$message = '' if not defined $message;
    $self->appendLog($self->logfile()) if not defined $self->logfh();   
    my ($package, $filename, $linenumber) = caller;
    my $timestamp = $self->logTimestamp();
	my $callingsub = (caller 1)[3];
	my $line = "$timestamp\t[INFO]    \t$callingsub\t$linenumber\t$message\n";

    print { $self->logfh() } $line if defined $self->logfh() and $self->printlog() > 2;
    print $line if $self->log() > 2;
	
	return $line;
}

sub logWarning {
    my ($self, $message) = @_;
	return -1 if not $self->log() > 1 and not $self->printlog() > 1;
	
	$message = '' if not defined $message;
    $self->appendLog($self->logfile()) if not defined $self->logfh();   
    my ($package, $filename, $linenumber) = caller;
    my $timestamp = $self->logTimestamp();
	my $callingsub = (caller 1)[3];
	my $line = "$timestamp\t[WARNING] \t$callingsub\t$linenumber\t$message\n";

    print { $self->logfh() } $line if defined $self->logfh() and $self->printlog() > 1;
    print $line if $self->log() > 1;
	
	return $line;
}

sub logCritical {
    my ($self, $message) = @_;
	return -1 if not $self->log() > 0 and not $self->printlog() > 0;
	
	$message = '' if not defined $message;
    $self->appendLog($self->logfile()) if not defined $self->logfh();   
    my ($package, $filename, $linenumber) = caller;
    my $timestamp = $self->logTimestamp();
	my $callingsub = (caller 1)[3];
	my $line = "$timestamp\t[CRITICAL]\t$callingsub\t$linenumber\t$message\n";

    print { $self->logfh() } $line if defined $self->logfh() and $self->printlog() > 0;
    print $line if $self->log() > 0;
	
	#### FOR FASTCGI: SKIP TO END OF SCRIPT WITHOUT EXITING
	#### NB: MUST PUT THIS AT END OF SCRIPT:
	####
	#### EXITLABEL:{};
	#### 
	#### OR YOU CAN WRITE A MESSAGE INSIDE IT:
	#### 
	#### EXITLABEL:{ warn "We have skipped to the end of the program\n"; };
	goto EXITLABEL;
	
	return $line;
}

sub logCaller {
#### 1. PRINT MESSAGE TO BOTH LOGFILE AND STDOUT
#### 2. PREFIX DATETIME AND CALLING CLASS, FILE AND LINE NUMBER
    my ($self, $message, $variable) = @_;
	
	$message = '' if not defined $message;
    $self->appendLog($self->logfile()) if not defined $self->logfh();   
    my ($package, $filename, $linenumber) = caller;
    my $timestamp = $self->logTimestamp();
	my $callingsub = (caller 1)[3] || '';
	my $caller = (caller 2)[3] || '';
	my $callerline = (caller 2)[2] || '';

	my $text = $variable;
	if ( not defined $variable and $#_ == 2 )	{
		$text = "undef";
	}
	elsif ( ref($variable) )	{
		$text = $self->objectToJson($variable);
	}

	my $indent = $self->indent();
	my $spacer = " " x $indent;
	my $line = "$timestamp$spacer" . "[CALLER]   \t$callingsub\t$linenumber\tcaller: $caller\t$callerline\t$message\n";
	$line = "$timestamp$spacer" . "[CALLER]   \t$callingsub\t$linenumber\tcaller: $caller\t$callerline\t$message: $text\n" if $#_ == 2;

#	my $callerline = (caller 2)[2];
#    my $line = "$timestamp\t[CALLER]  \t$callingsub\t$linenumber\tcaller: $caller\t$callerline\t$message\n";

    print $line if $self->log() > 3;
    print { $self->logfh() } $line if defined $self->logfh() and $self->printlog() > 3;
	return $line;
}

sub logError {
    my ($self, $message) = @_;
	$message = '' if not defined $message;
    $self->appendLog($self->logfile()) if not defined $self->logfh();   
    my ($package, $filename, $linenumber) = caller;
    my $timestamp = $self->logTimestamp();
	my $callingsub = (caller 1)[3];
    my $line = "$timestamp\t[ERROR]   \t$callingsub\t$linenumber\t$message\n";
    print { $self->logfh() } $line if defined $self->logfh() and $self->printlog() > 0;

    print qq{{"error":"$message","subroutine":"$callingsub","linenumber":"$linenumber","filename":"$filename","timestamp":"$timestamp"}\n};
	
	#### FOR FASTCGI: SKIP TO END OF SCRIPT WITHOUT EXITING
	#### NB: MUST PUT THIS AT END OF SCRIPT:
	####
	#### EXITLABEL:{};
	#### 
	#### OR YOU CAN WRITE A MESSAGE INSIDE IT:
	#### 
	#### EXITLABEL:{ warn "We have skipped to the end of the program\n"; };
	
	return $line;
}

sub logStatus {
    my ($self, $message, $data) = @_;
	$message = '' if not defined $message;
	$data = {} if not defined $data;

    $self->appendLog($self->logfile()) if not defined $self->logfh();   
	
	my ($package, $filename, $linenumber) = caller;
    my $timestamp = $self->logTimestamp();
	my $callingsub = (caller 1)[3];
    my $line = "$timestamp\t[STATUS]  \t$callingsub\t$linenumber\t$message\n";
    print { $self->logfh() } $line if defined $self->logfh() and $self->printlog() > 0;

	my $datajson = $self->objectToJson($data);
    print qq{{"status":"$message","subroutine":"$callingsub","linenumber":"$linenumber","filename":"$filename","timestamp":"$timestamp","data":$datajson}\n};

	return $line;
}

sub fakeTermination {
	my $self		=	shift;

	return;
	
	#print "Logger::fakeTermination    self->oldout(): ", 	$self->oldout(), "\n";
	#print "Logger::fakeTermination    self->olderr(): ", 	$self->olderr(), "\n";
	#
	#### FORK: PARENT MESSAGES AND QUITS, CHILD DOES THE WORK
	if ( my $child_pid = fork() ) 
	{
		$| = 1;

		#### SET InactiveDestroy ON DATABASE HANDLE
		$self->db()->dbh()->{InactiveDestroy} = 1;
		my $dbh = $self->db()->dbh();
		undef $dbh;	

		close(STDOUT);  
		close(STDERR);
		close(STDIN);

		#### PARENT EXITS
		exit(0);
	}

	else
	{
		#### CHILD CONTINUES THE JOB
	
		##### CLOSE OUTPUT SO CGI SCRIPT WILL QUIT
		#close(STDOUT);  
		#close(STDERR);
		#close(STDIN);
		#
		#open(STDOUT);
		#open(STDERR);
		#open(STDIN);
		#

		#sleep(2);

		#### ENSURE DB HANDLE STAYS ALIVE
		
		#$self->logDebug("child", $self);
		#
		#$self->setDbh() if $self->can('db');
	
	}
}

sub startLog {
    my ($self, $logfile) = @_;
	
	$self->logfile($logfile);
	$self->backupLogfile($logfile) if $self->backup();

	
	#### OPEN LOGFILE
	my $logfh;
    open($logfh, ">$logfile") or die "Can't open logfile: $logfile\n";
	$self->logfh($logfh);
}

sub appendLog{
    my ($self, $logfile) = @_;
    return if not defined $logfile or not $logfile;
    $self->logfile($logfile);
    
	#### OPEN LOGFILE
	my $logfh;
    open($logfh, ">>$logfile") or die "Can't open logfile: $logfile\n";

    $self->logfh($logfh);    
}


sub startLogStderr {
	#my $errpid = open (STDERR, "| tee -ai $logfile") or die "Can't split STDERR to logfile: $logfile\n";
	#$self->errpid($errpid);
	#select STDERR;
	
	##### SAVE OLD STDOUT/STDERR
	#my $oldout;
	#open($oldout, ">&STDOUT") or die "Can't set stdout\n";
	#$self->oldout($oldout);
	#my $olderr;
	#open($olderr, ">&STDERR") or die "Can't set stderr\n";
	#$self->olderr($olderr);
}

sub stopLogStderr {
	
	###### RESTORE OLD STDOUT & STDERR
	#open STDERR, ">&", $self->olderr() if defined $self->olderr();
	#open STDOUT, ">&", $self->oldout() if defined $self->oldout();
}

sub pauseLog{
    my ($self) = @_;

	$self->oldlog($self->log());
	$self->oldprintlog($self->printlog());
	$self->printlog(0);
	$self->log(0);
	return;	
}

sub resumeLog{
    my ($self, $logfile) = @_;
    $logfile = $self->logfile() if not defined $logfile;
    $self->logError("logfile not defined") and exit if not defined $logfile;

	$self->log($self->oldlog()) if defined $self->oldlog();
	$self->printlog($self->oldprintlog()) if defined $self->oldprintlog();
}

sub stopLog{
    my ($self) = @_;

	$self->printlog(0);
	$self->log(0);
	
	#### CLOSE LOG FILEHANDLE
	my $logfh = $self->logfh();
    close($logfh) if defined $logfh;
	$self->logfh(undef);
}

sub backupLogfile {
#### MOVE OLD LOGFILE TO *.N WITH N INCREMENTED EACH TIME
    my ($self, $logfile) = @_;
	return if not defined $logfile or not $logfile;
    return if not -f $logfile;
    
    my $oldfile = $logfile;
    $oldfile .= ".1";	
	while ( -f $oldfile )
	{
		my ($stub, $index) = $oldfile =~ /^(.+?)\.(\d+)$/;
		$index++;
		$oldfile = $stub . "." . $index;
	}
    `mv $logfile $oldfile`;
}

sub logTimestamp {
    my ($self) = @_;
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    return sprintf "%4d-%02d-%02d %02d:%02d:%02d",
        $year+1900,$mon+1,$mday,$hour,$min,$sec;
}

sub objectToJson {
	my ($self, $object) = @_;

	my $json = sprintf "%s", Dumper $object;
	$json =~ s/^\s*\$VAR1\s*=\s*//;
	$json =~ s/;\s\n*\s*$//ms;
	$json =~ s/'/"/gms;
	$json =~ s/\s*\n\s*//gms;
	$json =~ s/\s+=>\s+/:/gms;
	#$json =~ s/,/,\n/gms;

	return $json;	
}

sub set_signal_handlers {
  my $self=shift;

	#### SET SIGNAL HANDLERS
	$self->logDebug("Setting SIG{'Warn'} to WARN_handler");
	$SIG{__WARN__} =sub { $self->WARN_handler() };
	$SIG{__DIE__}=sub { $self->DIE_handler() };

##### SET SIGNAL HANDLERS
#$SIG{__WARN__} = \&WARN_handler;
#$SIG{__DIE__}  = \&DIE_handler;

}



no Moose::Role;

1;

