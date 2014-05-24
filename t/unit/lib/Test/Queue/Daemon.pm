use MooseX::Declare;

use strict;
use warnings;

class Test::Queue::Daemon extends Queue::Daemon with (Test::Agua::Common::Database, Agua::Common::Util) {

#### Boolean
has 'mock'		=>  ( isa => 'Bool', is => 'rw', default	=>	1 );

#### Strings
has 'logfile'	=> 	( isa => 'Str|Undef', is => 'rw', required => 1 );
has 'dumpfile'	=> 	( isa => 'Str|Undef', is => 'rw', required => 1 );

#### Arrays
has 'outputs'		=>  ( isa => 'ArrayRef|Undef', is => 'rw', default	=>	sub { return [] } );
has 'inputs'		=>  ( isa => 'ArrayRef|Undef', is => 'rw', default	=>	sub { return [] } );


use FindBin qw($Bin);
use Test::More;

#####////}}}}}

method notifyStatus ($data) {
	my $mock	=	$self->mock();
	if ( $mock ) {
		push @{$self->inputs()}, $data;
		$self->returnOutput();
	}
	else {
		self->SUPER::notifyStatus($data);
	}
}

method testSubmitLogin {
	diag("# submitLogin");
	
	#### SET AUTHENTICATION TO password
	$self->conf()->getKey("authentication:TYPE", "password");
	
	##### LOAD DATABASE
	$self->setUpTestDatabase();
	$self->setDatabaseHandle();

	my $tests = [
	{
		testname	=>	"login success",
		tsvfile		=>	"$Bin/inputs/users-success.tsv",
		username	=>	"testuser",
		password	=>	12345678,
		data		=>	{
			"token"		=>	"Tbc3K5bPEyGMH5lm",
			"sourceid"	=>	"plugins_login_Login_0",
			"callback"	=>	"handleResponse",
			"username"	=>	"guest",
			"password"	=>	"guest",
			"mode"		=>	"submitLogin",
			"module"	=>	"Agua::Workflow",
			"database"	=>	"testdatabase"
		}
	}
		#{
		#	testname	=>	"login success",
		#	tsvfile		=>	"$Bin/inputs/users-success.tsv",
		#	username	=>	"testuser",
		#	password	=>	12345678,
		#	expected	=>	{
		#		'status' => 'ready',
		#		'data' => {
		#					'sessionid' => ''
		#				  },
		#		'username' => 'testuser',
		#		'sourceid' => '',
		#		'callback' => '',
		#		'error' => '',
		#		'queue' => 'routing',
		#		'token' => undef
		#	}
		#}
		#,
		#{
		#	testname	=>	"login failure",
		#	tsvfile		=>	"$Bin/inputs/users-success.tsv",
		#	username	=>	"testuser",
		#	password	=>	"WRONGPASSWORD",
		#	expected	=>	{
		#		'status' => 'error',
		#		'data' => {
		#			'sessionid' => undef
		#		},
		#		'username' => 'testuser',
		#		'sourceid' => '',
		#		'callback' => '',
		#		'error' => "Password does not match for user: testuser",
		#		'queue' => 'routing',
		#		'token' => undef
		#	}
		#}
	];

	##### START LISTENING
	#my $queuename	=	"test.worker.queue";
	#my $childpid = fork;
	#if ( $childpid ) #### ****** Parent ****** 
	#{
	#	$self->logDebug("PARENT childpid", $childpid);
	#}
	#elsif ( defined $childpid ) {
	#	$self->receiveSocket();
	#}
	
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

		#### OVERRIDE 
		no warnings;
		*notifyStatus = sub {
			my $self	=	shift;
			my $data	=	shift;
			#$self->logDebug("data", $data);		
			$data->{data}->{sessionid} = "" if defined $data->{data}->{sessionid};
			is_deeply($data, $expected, "notifyStatus 'data' argument correct");
		};
		use warnings;

		$self->sendSocket();
	}

	
}



}

