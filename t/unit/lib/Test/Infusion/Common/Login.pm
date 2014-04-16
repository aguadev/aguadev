use Moose::Util::TypeConstraints;
use MooseX::Declare;
use Method::Signatures::Modifiers;

=pod

PACKAGE		Test::Infusion::Common::Logi 

PURPOSE		TEST CLASS Infusion::Common::Login

=cut

#use Infusion::Common::Login;

class Test::Infusion::Common::Login with (Infusion::Common::Login, Test::Agua::Common::Database, Agua::Common::Logger, Agua::Common::Database, Agua::Common::Privileges) {


use strict;
use warnings;
use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../../../../lib";
use lib "$Bin/../../../../../lib";

#### INTERNAL MODULES
use Conf::Yaml;

# Strings
has 'database'		=>  ( isa => 'Str|Undef', is => 'rw' );
has 'dumpfile'		=>  ( isa => 'Str|Undef', is => 'rw' );
has 'testuser'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'testpassword'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'username'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'password'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'sessionid'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'logfile'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );

# Objects
has 'db'	=> ( isa => 'Agua::DBase::MySQL', is => 'rw', required => 0 );
has 'conf' 	=> ( isa => 'Conf::Yaml', is =>	'rw');

####/////}}}

method testLdapAuthentication () {

#### LOAD LOGIN, ETC. FROM ENVIRONMENT VARIABLES

	my $tests = [
		{
			testname	=>	"login success",
			tsvfile		=>	"$Bin/inputs/users-success.tsv",
			username	=>	$ENV{'testuser'},
			password	=>	$ENV{'testpassword'},
			expected	=>	1
		}
		,
		{
			testname	=>	"login failure",
			tsvfile		=>	"$Bin/inputs/users-success.tsv",
			username	=>	"testuser",
			password	=>	"WRONGPASSWORD",
			expected	=>	0
		}
	];
	
	#### SET testuser AND testpassword
	my $testuser = $ENV{'testuser'};
	my $testpassword = $ENV{'testpassword'};
	$self->username($testuser);
	$self->password($testpassword);
	
	my $authenticated = $self->ldapAuthentication($testuser, $testpassword);
	is($authenticated, 1, "ldapAuthentication    authentication success");
	$authenticated = $self->ldapAuthentication($testuser, "notPASSWORD");
	is($authenticated, 0, "ldapAuthentication    authentication failure");
}


method testSubmitLogin {
	diag("# submitLogin");
	
	##### GET TEST USER
	#my $user        =   $self->conf()->getKey("database", "TESTUSER");
	#my $password    =   $self->conf()->getKey("database", "TESTPASSWORD");
	my $database    =   $self->conf()->getKey("database", "TESTDATABASE");
	#$self->logDebug("user", $user);
	#$self->logDebug("password", $password);
	$self->logDebug("database", $database);
	$self->database($database);
	
	#### SET AUTHENTICATION TO password
	my $authentication = $self->conf()->getKey("authentication", undef);
	$authentication->{TYPE} = "password";
	$self->conf()->setKey('authentication', $authentication);
	
	##### LOAD DATABASE
	$self->setUpTestDatabase();
	$self->setDatabaseHandle();

	my $tests = [
		{
			testname	=>	"login success",
			tsvfile		=>	"$Bin/inputs/users-success.tsv",
			username	=>	"testuser",
			password	=>	12345678,
			expected	=>	1
		}
		,
		{
			testname	=>	"login failure",
			tsvfile		=>	"$Bin/inputs/users-success.tsv",
			username	=>	"testuser",
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
		#open(STDOUT, ">&$oldout") or die "Can't restore STDOUT from oldout\n";
		
		$self->logDebug("success", $success);
		
		$result = 1 if defined $success;
		
		$self->logDebug("result", $result);
		
		
		is_deeply($result, $expected, $testname);
	}
}




};
#### Infusion::Common::Login
