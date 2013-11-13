package Agua::Common::Logger;
use Moose::Role;

=head2

    ROLE        Agia::Common::Logger
    
    PURPOSE
    
        FLEXIBLY PRINT MESSAGES TO STDOUT AND/OR LOG FILE BASED ON THE FOLLOWING SCHEMA:]
		

		'LOGLEVEL' VARIABLE SPECIFIES WHICH CATEGORIES OF LOG TO OUTPUT:
			
			LOGLEVEL	Outputs (incl. previous level)	Example
			
				1		logCritical 					"SYSTEM FAILURE... QUITTING"
					
				2		logWarning 						"POSSIBLE ERROR ... CONTINUING"
	
				3		logInfo 						"SOMETHING MIGHT HAPPEN HERE"
	
				4		logDebug/logCaller/logDebug	"CHECKING HERE FOR ERRORS"
				
				5		logNote 						"NOTHING HAPPENED, WE ARE HERE"

			
		'SHOWLOG' VARIABLE DETERMINES WHETHER OR NOT TO PRINT TO STDOUT:
        
			LOG		Outputs (incl. previous level)	Example

            LOG 0   No printing to STDOUT
    
            LOG 1   Print LOGLEVEL 1 messages to STDOUT

            LOG 2   Print LOGLEVEL 2 messages to STDOUT

            LOG 3   Print LOGLEVEL 3 messages to STDOUT

            LOG 4   Print LOGLEVEL 4 messages to STDOUT

            LOG 5   Print LOGLEVEL 5 messages to STDOUT


        LOG OUTPUT GENERALLY INCLUDES THE FOLLOWING INFORMATION:
		
				-	DATETIME
			
				-	CALLING CLASS
			
				-	LINE NUMBER IN FILE

				-	LOG TYPE
			
			
		THE FOLLOWING COMMANDS ARE LOGGED AND PRINTED TO STDOUT REGARDLESS OF THE LOGLEVEL:

			logError	TO LOGFILE AND JSON STDOUT: { error: ... , module, line, datetime }
			
			logStatus	TO LOGFILE JSON STDOUT: { status: ..., module, line, datetime }=cut


		ALL LOG COMMAND OUTPUTS CONTAIN THE DATETIME, CALLING CLASS AND LINE NUMBER


=cut

#Boolean
has 'backup' 	=> ( isa => 'Int', 		is => 'rw', default => 0 );
# Ints
has 'SHOWLOG'	=> ( isa => 'Int', 		is => 'rw', default	=> 	2	);  
has 'PRINTLOG'	=> ( isa => 'Int', 		is => 'rw', default	=> 	2	);
has 'OLDSHOWLOG'=> ( isa => 'Int', 		is => 'rw', default	=> 	2	);  
has 'OLDPRINTLOG'=> ( isa => 'Int', 		is => 'rw', default	=> 	2	);
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

=head2

    SUBROUTINE      logger
    
    PURPOSE
    
        1. PRINT MESSAGE TO STDOUT AND/OR LOG FILE DEPENDING ON THE VALUE
        
        OF THE 'SHOWLOG' VARIABLE:
    
            LOG 0   No printing
    
            LOG 1   Print to STDOUT only
    
            LOG 2   Print to logfile only
    
            LOG 3   Print to STDOUT and logfile

        2. PREFIX DATETIME AND CALLING CLASS, FILE AND LINE NUMBER

=cut

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

    print { $self->logfh() } $line if defined $self->logfh() and $self->PRINTLOG() > 3;
    print $line if $self->SHOWLOG() > 3;

	return $line;
}

sub logGroupEnd {
    my ($self, $message) = @_;
	$message = '' if not defined $message;
    $self->appendLog($self->logfile()) if not defined $self->logfh();

	#### SET INDENT	
	#$self->logDebug("BEFORE self->indent", $self->indent());
	my $indent = $self->indent();
	$indent -= 4;
	$indent = 2 if $indent < 4;
	$self->indent($indent);
	#$self->logDebug("AFTER self->indent", $self->indent());

	#### SET LINE
    my ($package, $filename, $linenumber) = caller;
    my $timestamp = $self->logTimestamp();
	my $callingsub = (caller 1)[3] || '';
	my $spacer = " " x $indent;
    my $line = "$timestamp$spacer". "[GROUPEND]    \t$callingsub\t$linenumber\t$message\n";

    print { $self->logfh() } $line if defined $self->logfh() and $self->PRINTLOG() > 3;
    print $line if $self->SHOWLOG() > 3;

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
	return -1 if not $self->SHOWLOG() > 4 and not $self->PRINTLOG() > 4;

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

    print { $self->logfh() } $line if defined $self->logfh() and $self->PRINTLOG() > 4;
    print $line if $self->SHOWLOG() > 4;
	return $line;
}

sub logDebug {
    my ($self, $message, $variable) = @_;
	
	return -1 if not $self->SHOWLOG() > 3 and not $self->PRINTLOG() > 3;

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

    print { $self->logfh() } $line if defined $self->logfh() and $self->PRINTLOG() > 3;
    print $line if $self->SHOWLOG() > 3;
	return $line;
}

sub logInfo {
    my ($self, $message) = @_;
	return -1 if not $self->SHOWLOG() > 2 and not $self->PRINTLOG() > 2;
	
	$message = '' if not defined $message;
    $self->appendLog($self->logfile()) if not defined $self->logfh();   
    my ($package, $filename, $linenumber) = caller;
    my $timestamp = $self->logTimestamp();
	my $callingsub = (caller 1)[3];
	my $line = "$timestamp\t[INFO]    \t$callingsub\t$linenumber\t$message\n";

    print { $self->logfh() } $line if defined $self->logfh() and $self->PRINTLOG() > 2;
    print $line if $self->SHOWLOG() > 2;
	
	return $line;
}

sub logWarning {
    my ($self, $message) = @_;
	return -1 if not $self->SHOWLOG() > 1 and not $self->PRINTLOG() > 1;
	
	$message = '' if not defined $message;
    $self->appendLog($self->logfile()) if not defined $self->logfh();   
    my ($package, $filename, $linenumber) = caller;
    my $timestamp = $self->logTimestamp();
	my $callingsub = (caller 1)[3];
	my $line = "$timestamp\t[WARNING] \t$callingsub\t$linenumber\t$message\n";

    print { $self->logfh() } $line if defined $self->logfh() and $self->PRINTLOG() > 1;
    print $line if $self->SHOWLOG() > 1;
	
	return $line;
}

sub logCritical {
    my ($self, $message) = @_;
	return -1 if not $self->SHOWLOG() > 0 and not $self->PRINTLOG() > 0;
	
	$message = '' if not defined $message;
    $self->appendLog($self->logfile()) if not defined $self->logfh();   
    my ($package, $filename, $linenumber) = caller;
    my $timestamp = $self->logTimestamp();
	my $callingsub = (caller 1)[3];
	my $line = "$timestamp\t[CRITICAL]\t$callingsub\t$linenumber\t$message\n";

    print { $self->logfh() } $line if defined $self->logfh() and $self->PRINTLOG() > 0;
    print $line if $self->SHOWLOG() > 0;
	
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

    print $line if $self->SHOWLOG() > 3;
    print { $self->logfh() } $line if defined $self->logfh() and $self->PRINTLOG() > 3;
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
    print { $self->logfh() } $line if defined $self->logfh() and $self->PRINTLOG() > 0;

    print qq{{"error":"$message","subroutine":"$callingsub","linenumber":"$linenumber","filename":"$filename","timestamp":"$timestamp"}\n};
	
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

sub logStatus {
    my ($self, $message, $data) = @_;
	$message = '' if not defined $message;
	$data = {} if not defined $data;

    $self->appendLog($self->logfile()) if not defined $self->logfh();   
	
	my ($package, $filename, $linenumber) = caller;
    my $timestamp = $self->logTimestamp();
	my $callingsub = (caller 1)[3];
    my $line = "$timestamp\t[STATUS]  \t$callingsub\t$linenumber\t$message\n";
    print { $self->logfh() } $line if defined $self->logfh() and $self->PRINTLOG() > 0;

	my $datajson = $self->objectToJson($data);
    print qq{{"status":"$message","subroutine":"$callingsub","linenumber":"$linenumber","filename":"$filename","timestamp":"$timestamp","data":$datajson}\n};

	return $line;
}

sub fakeTermination {
	my $self		=	shift;

	return;
	
	#print "Agua::Common::Logger::fakeTermination    self->oldout(): ", 	$self->oldout(), "\n";
	#print "Agua::Common::Logger::fakeTermination    self->olderr(): ", 	$self->olderr(), "\n";
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
    
	##### SAVE OLD STDOUT/STDERR
	#my $oldout;
	#open($oldout, ">&STDOUT") or die "Can't set stdout\n";
	#$self->oldout($oldout);
	#my $olderr;
	#open($olderr, ">&STDERR") or die "Can't set stderr\n";
	#$self->olderr($olderr);

	#### OPEN LOGFILE
	my $logfh;
    open($logfh, ">>$logfile") or die "Can't open logfile: $logfile\n";
	#my $errpid = open (STDERR, "| tee -ai $logfile") or die "Can't split STDERR to logfile: $logfile\n";
	#$self->errpid($errpid);
	#select STDERR;   #### UNCOMMENT TO DIVERT ALL STDOUT INTO LOG FILE

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

	return;
	
	$self->OLDSHOWLOG($self->SHOWLOG());
	$self->OLDPRINTLOG($self->PRINTLOG());
	$self->PRINTLOG(0);
	$self->SHOWLOG(0);
	
#	#### RESTORE OLD STDOUT
#    my $oldout 	= $self->oldout();
#    my $logfh 	= $self->logfh();
#	open $logfh, ">&", $oldout;
#
##	#### KILL OLD TEE FILE HANDLE
##	my $errpid = $self->errpid();
##	`kill -9 $errpid` if defined $errpid;
##
##	#### RESTORE OLD STDERR
##    my $olderr 	= $self->olderr();
##	open STDERR, ">&", $olderr;
}

sub resumeLog{
    my ($self, $logfile) = @_;
    $logfile = $self->logfile() if not defined $logfile;
    $self->logError("logfile not defined") and exit if not defined $logfile;

	$self->SHOWLOG($self->OLDSHOWLOG()) if defined $self->OLDSHOWLOG();
	$self->PRINTLOG($self->OLDPRINTLOG()) if defined $self->OLDPRINTLOG();

#
#	#### SAVE OLD STDOUT
#	my $oldout;
#	open($oldout, ">&STDOUT") or die "Can't set stdout\n";
#	$self->oldout($oldout);
#	
#	my $logfh = $self->logfh();
#	return if not defined $logfh;
#    open($logfh, ">>$logfile") or die "Can't open logfile: $logfile\n";
#
#	open (STDERR, "| tee -ai $logfile") or die "Can't split STDERR to logfile: $logfile\n";
#	select STDERR;
}

sub stopLog{
    my ($self) = @_;

	$self->PRINTLOG(0);
	$self->SHOWLOG(0);
	
#	#### RESTORE OLD STDOUT
#    my $oldout 	= $self->oldout();
#	open STDOUT, ">&", $oldout;

	#### CLOSE LOG FILEHANDLE
	my $logfh = $self->logfh();
    close($logfh) if defined $logfh;
	$self->logfh(undef);

#	#### KILL OLD TEE FILE HANDLE
#	my $errpid = $self->errpid();
#	`kill -9 $errpid` if defined $errpid;
#
#	#### RESTORE OLD STDERR
#    my $olderr 	= $self->olderr();
#	open STDERR, ">&", $olderr;

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

