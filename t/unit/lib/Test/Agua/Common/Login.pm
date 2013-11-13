use Moose::Util::TypeConstraints;
use MooseX::Declare;
use Method::Signatures::Modifiers;

class Test::Agua::Common::Login with (Agua::Common::Login, Test::Agua::Common::Database, Agua::Common::Logger, Agua::Common::Database, Agua::Common::Privileges) {

use Data::Dumper;
use Test::More;
use FindBin qw($Bin);

# Ints
has 'LOG'		=> ( isa => 'Int', 		is => 'rw', default	=> 	2);

# STRINGS
has 'dumpfile'		=>  ( isa => 'Str|Undef', is => 'rw' );
has 'username'		=>  ( isa => 'Str|Undef', is => 'rw' );
has 'password'		=>  ( isa => 'Str|Undef', is => 'rw' );
has 'database'		=>  ( isa => 'Str|Undef', is => 'rw' );
has 'logfile'		=>  ( isa => 'Str|Undef', is => 'rw' );
has 'requestor'		=> 	( isa => 'Str|Undef', is => 'rw' );

# OBJECTS
has 'db'		=> ( isa => 'Agua::DBase::MySQL', is => 'rw', required => 0 );
has 'conf' 	=> (
	is 		=>	'rw',
	isa 	=> 	'Conf::Yaml|Undef'
);

#####/////}}}}}

method BUILD ($args) {
	if ( defined $args ) {
		foreach my $arg ( $args ) {
			$self->$arg($args->{$arg}) if $self->can($arg);
		}
	}
	$self->logDebug("args", $args);
}

method testSubmitLogin {
	diag("# submitLogin");
	
	##### GET TEST USER
	#my $user        =   $self->conf()->getKey("database", "TESTUSER");
	#my $password    =   $self->conf()->getKey("database", "TESTPASSWORD");
	#my $database    =   $self->conf()->getKey("database", "TESTDATABASE");
	#$self->logDebug("user", $user);
	#$self->logDebug("password", $password);
	#$self->logDebug("database", $database);

	#### SET AUTHENTICATION TO password
	$self->conf()->getKey('authentication', "TYPE", "password");
	
	##### LOAD DATABASE
	$self->setUpTestDatabase();
	$self->setDatabaseHandle();

	my $tests = [
		{
			testname	=>	"login success",
			tsvfile		=>	"$Bin/inputs/users-success.tsv",
			username	=>	"aguatest",
			password	=>	12345678,
			expected	=>	1
		}
		,
		{
			testname	=>	"login failure",
			tsvfile		=>	"$Bin/inputs/users-success.tsv",
			username	=>	"aguatest",
			password	=>	"WRONGPASSWORD",
			expected	=>	0
		}
	];
	
	foreach my $test ( @$tests ) {
		my $testname	=	$test->{testname};
		my $tsvfile		=	$test->{tsvfile};
		my $expected	=	$test->{expected};
		
		#### LOAD TSVFILE
		$self->loadTsvFile("users", $tsvfile);
		
		#### SET USERNAME AND PASSWORD
		$self->username($test->{username});
		$self->password($test->{password});
		
		my $username	=	$self->username();
		my $password 	=	$self->password();
		$self->logDebug("username", $username);
		$self->logDebug("password", $password);
	
		my $result = 0;
		
		my $success;
		
		my $oldout;
		
		#### REDIRECT STDOUT TO /dev/null
		open($oldout, ">&STDOUT") or die "Can't copy STDOUT to oldout\n";
		open(STDOUT, ">/dev/null") or die "Can't redirect STDOUT to /dev/null\n";
		
		$success = $self->_submitLogin();
		
		#### SATISFY Agua::Common::Logger::logError CALL TO EXITLABEL
		no warnings;
		EXITLABEL : {};
		use warnings;
		
		#### RESTORE STDOUT
		open(STDOUT, ">&$oldout") or die "Can't restore STDOUT from oldout\n";
		
		$self->logDebug("success", $success);
		
		
		$result = 1 if defined $success;
		
		
		$self->logDebug("success", $success);
		$self->logDebug("result", $result);
		
		
		is_deeply($result, $expected, $testname);
	}
}


}	####	Agua::Login::Common
