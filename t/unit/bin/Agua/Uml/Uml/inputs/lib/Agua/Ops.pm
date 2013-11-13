use MooseX::Declare;

=head2

	PACKAGE		Agua::Ops
	
	PURPOSE
	
		CARRY OUT COMMON SYSTEM COMMANDS, INSTALL PACKAGES AND OTHER OPERATIONS

=cut

class Agua::Ops with (Agua::Ops::Ec2,
	Agua::Ops::Edit,
	Agua::Ops::Files,
	Agua::Ops::Git,
	Agua::Ops::Install,
	Agua::Ops::Nfs,
	Agua::Ops::Sge,
	Agua::Ops::Stager,
	Agua::Ops::Version,
	Agua::Common::App,
	Agua::Common::Aws,
	Agua::Common::Base,
	Agua::Common::Cluster,
	Agua::Common::Logger,
	Agua::Common::Package,
	Agua::Common::Parameter,
	Agua::Common::Ssh,
	Agua::Common::Util) {

use FindBin qw($Bin);
use lib "$Bin/..";

#### EXTERNAL MODULES
use Data::Dumper;
use File::Path;
use Getopt::Simple;
use Moose::Util qw(apply_all_roles);

#### INTERNAL MODULES
use Agua::OpsInfo;
use Conf::Agua;

# Booleans
has 'warn'		=> ( isa => 'Bool', is 	=> 'rw', default	=>	1	);
has 'help'		=> ( isa => 'Bool', is  => 'rw', required	=>	0, documentation => "Print help message"	);
has 'backup'	=> ( isa => 'Bool', is  => 'rw', default	=>	0, documentation => "Automatically back up files before altering"	);

# Ints
has 'SHOWLOG'		=> ( isa => 'Int', is => 'rw', default 	=> 	2 	);  
has 'PRINTLOG'		=> ( isa => 'Int', is => 'rw', default 	=> 	2 	);
has 'sleep'			=> ( is  => 'rw', 'isa' => 'Int', default	=>	600	);

# Strings
has 'opsrepo'	=> ( isa => 'Str|Undef', is => 'rw', required	=> 	0	);
has 'installdir'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'database'	=> ( isa => 'Str|Undef', is => 'rw', required	=> 	0	);
has 'user'	=> ( isa => 'Str|Undef', is => 'rw', required	=> 	0	);
has 'password'	=> ( isa => 'Str|Undef', is => 'rw', required	=> 	0	);
has 'conffile'	=> ( isa => 'Str|Undef', is => 'rw', required	=> 	0	);

has 'logfile'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'envfile'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'hostname'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'username'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'sessionId'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'cwd'		=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'envars'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'tempdir'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'hubtype'	=> ( isa => 'Str|Undef', is => 'rw', default	=>	"github" );
has 'remote'	=> ( isa => 'Str|Undef', is => 'rw', required	=> 	0	);

#### Objects
has 'db'		=> ( isa => 'Agua::DBase::MySQL', is => 'rw', required => 0 );
has 'ssh'		=> ( isa => 'Agua::Ssh', is => 'rw', required	=>	0	);

#### INITIALIZATION VARIABLES FOR Agua::Ops::GitHub
has 'owner'		=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'package'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'login'		=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'token'		=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'password'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'installdir'=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'version'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'keyfile'	=> ( isa => 'Str|Undef', is => 'rw', default	=>	''	);
has 'conf' 	=> (
	is =>	'rw',
	'isa' => 'Conf::Agua',
	default	=>	sub { Conf::Agua->new();	}
);
has 'opsinfo' 	=> (
	is 			=>	'rw',
	isa 		=> 'Agua::OpsInfo'
	#,
	#'builder'	=>	'setOpsInfo',
	#'lazy'		=>	1
);
	#default	=>	sub { Agua::OpsInfo->new();	}

####/////}}}}

method BUILD ($hash) {
	$self->logDebug("hash", $hash);
	$self->initialise();
}

method initialise () {
	$self->logDebug("");
	#### OPEN LOGFILE IF DEFINED
	my $logfile = $self->logfile();
	$self->startLog($logfile) if defined $logfile;
	$self->logNote("logfile", $logfile)  if defined $logfile;

	$self->setEnv();

	$self->setSsh();
	
	$self->logDebug("DOING self->setHubType(self->hubtype())");
	$self->setHubType($self->hubtype());

	$self->setDbObject() if not defined $self->db() and $self->can('setDbObject') and defined $self->database() and not $self->database();
}

method setHubType ($hubtype) {
	return if not $hubtype;
	apply_all_roles($self, 'Agua::Ops::GitHub') if $hubtype eq "github";
}

method setSsh () {
	my $username	=	$self->username();
	my $hostname 	=	$self->hostname();
	my $keyfile 	= 	$self->keyfile();

	$self->logDebug("username", $username);
	$self->logDebug("hostname", $hostname);
	$self->logDebug("keyfile", $keyfile);
	
	return if not defined $self->username() or not $self->username();
	return if not defined $self->hostname() or not $self->hostname();
	return if not defined $self->keyfile() or not $self->keyfile();

	return $self->_setSsh($username, $hostname, $keyfile);
}

method setEnv {
	return if not defined $self->envfile();
	my $envfile = $self->envfile();
	my $lines = $self->fileLines($envfile);
	my $envars = '';
	foreach my $line ( @$lines )
	{
		next if not $line =~ /^\s*(\S+)\s+(\S+)\s*$/;
		my $key = $1;
		my $value = $2;
		$envars .= "$key=$value";
	}
	$self->envars($envars);
}

method args() {
	my $meta = $self->meta();

	my %option_type_map = (
		'Bool'     => '!',
		'Str'      => '=s',
		'Int'      => '=i',
		'Num'      => '=f',
		'ArrayRef' => '=s@',
		'HashRef'  => '=s%',
		'Maybe'    => ''
	);
	
	my $attributes = $self->fields();
	my $args = {};
	foreach my $attribute_name ( @$attributes )
	{
		my $attr = $meta->get_attribute($attribute_name);
		my $attribute_type  = $attr->{isa};
		$attribute_type =~ s/\|.+$//;
		$args -> {$attribute_name} = {  type => $option_type_map{$attribute_type}  };
	}

	return $args;
}

method localCommand ($command) {
#### RUN COMMAND LOCALLY
	$self->logDebug("command", $command);
	return `$command`;
}

method clearChangeDir () {
	$self->logNote();
	$self->cwd("");	
}
method changeDir ($directory) {
	$self->logNote("directory", $directory);
	my $cwd = $self->cwd();
	if ( defined $cwd and $directory !~ /^\// ) {
		$cwd =~ s/\/$//;
		$cwd = "$cwd/$directory";
		return 0 if not $self->foundDir($cwd);
		return 0 if not chdir($cwd);
		$self->cwd($cwd);
	}
	else {
		return 0 if not $self->foundDir($directory);
		return 0 if not chdir($directory);
		$self->cwd($directory);
		$cwd = $directory;
	}
	
	return 1;
}

method runCommand ($command) {
#### RUN COMMAND LOCALLY OR ON REMOTE HOST
	#### ADD ENVIRONMENT VARIABLES IF EXIST
	$command = $self->envars() . $command if defined $self->envars();
	$command = "cd ".  $self->cwd() . "; " . $command if defined $self->cwd() and $self->cwd();
	$self->logDebug("command", $command);

	if ( defined $self->ssh() ) {
		$self->logDebug("DOING ssh->execute($command)");
		return $self->ssh()->execute($command);
	}
	else {
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
		
		$self->logDebug("output", $output);
		$self->logDebug("error", $error);
		
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

method chompCommand ($command) {
#### RETURN CHOMPED RESULT OF runCommand
	my ($output, $error) = $self->runCommand($command);
	return if not defined $output;
	$self->logNote("output", $output);
	$self->logNote("error", $error);
	$output =~ s/\s+$//;
	$error =~ s/\s+$//;
	$self->logNote("Returning '$output', '$error'");
	return ($output, $error);
}


method repeatCommand ($command, $sleep, $tries, $errorregex) {
#### REPEATEDLY TRY SYSTEM CALL UNTIL A NON-ERROR RESPONSE IS RECEIVED
	$errorregex = "(error|Error|ERROR)" if not defined $errorregex; 
	$self->logDebug("command", $command);
	$self->logDebug("sleep", $sleep);
	$self->logDebug("tries", $tries);
	$self->logDebug("errorregex", $errorregex);
	
	my $output;
	my $error;
	my $error_message = 1;
	while ( $error_message and $tries )
	{
		($output, $error) = $self->runCommand($command);
		$self->logDebug("output", $output);
		$self->logDebug("error", $error);
		
		use re 'eval';	# EVALUATE AS REGEX
		$error_message = $output =~ /$errorregex/;
		$self->logDebug("error_message", $error_message) if not $output;
		no re 'eval';# STOP EVALUATING AS REGEX

		#### DECREMENT TRIES AND SLEEP
		$tries--;
		$self->logDebug("$tries tries left.")  if not $output and not $error;
		$self->logDebug("sleeping $sleep seconds") and sleep($sleep) if $error_message;
	}
	$self->logDebug("Returning output", $output);
	$self->logDebug("Returning error", $error);
	
	return $output, $error;
}

#### CONTROL METHODS
method timeoutCommand ($command, $timeout) {
	eval {
		local %SIG;
		$SIG{ALRM}=	sub{ print "timeout reached, after $timeout seconds!\n"; die; };
		alarm $timeout;
		return $self->runCommand($command);
		
		alarm 0;
	};

	$self->logDebug("end of timeout returning 0");
	alarm 0;
	
}

method repeatTry ($command, $regex, $tries, $sleep) {
#### REPEAT COMMAND UNTIL NON-ERROR RETURNED OR LIMIT REACHED
	$self->logDebug("Agua::Ops::repeatTry(command)");
	$self->logDebug("command", $command);
	$self->logDebug("sleep", $sleep);
	$self->logDebug("tries", $tries);
	
	my $result = '';	
	my $error = 1;
	while ( $error and $tries )
	{
		open(COMMAND, $command) or die "Can't exec command: $command\n";
		while(<COMMAND>) {
			$result .= $_;
		}
		close (COMMAND);
		$self->logDebug("result", $result);

		use re 'eval';	# EVALUATE AS REGEX
		$error = $result =~ /$regex/;
		$self->logDebug("error", $error);
		no re 'eval';# STOP EVALUATING AS REGEX

		#### DECREMENT TRIES AND SLEEP
		$tries--;
		$self->logDebug("$tries tries left. Sleeping $sleep seconds") if $error;
		$self->logDebug("current datetime: ");
		$self->logDebug(`date`);

		sleep($sleep) if $error;
	}
	$self->logDebug("Returning result", $result);
	
	return $result;
}

####s USER INPUT METHODS
method yes ($message, $max_times) {    
    $/ = "\n";
    my $input = <STDIN>;
    my $counter = 0;
    while ( $input !~ /^Y$/i and $input !~ /^N$/i )
    {
    	if ( $counter > $max_times )	{
			$self->logCritical("Exceeded 10 tries. Exiting.");
		}
    	
    	$self->logCritical("$message");
    	$input = <STDIN>;
    	$counter++;
    }	

    if ( $input =~ /^N$/i )	{	return 0;	}
    else {	return 1;	}
}

#### DATABASE METHODS
method setDbObject () {
	my $database 	= $self->conf()->getKey("database", "DATABASE");
	my $user		= $self->conf()->getKey("database", "USER");
	my $password	= $self->conf()->getKey("database", "PASSWORD");
	$self->logDebug("database", $database);
	$self->logDebug("user", $user);
	$self->logDebug("password", $password);

   #### CREATE DB OBJECT USING DBASE FACTORY
    my $db = Agua::DBaseFactory->new( 'MySQL',
        {
			database	=>	$database,
            user      	=>  $user,
            password  	=>  $password,
			logfile		=>	$self->logfile(),
			SHOWLOG		=>	2,
			PRINTLOG	=>	2
        }
    ) or die "Can't create database object to create database: $database. $!\n";

	$self->db($db);
}




}

