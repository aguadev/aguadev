use MooseX::Declare;

use strict;
use warnings;

class Test::Queue::Daemon extends Queue::Daemon with (Agua::Common::Database, Test::Agua::Common::Database, Agua::Common::Util) {

#### Boolean
has 'mock'		=>  ( isa => 'Bool', is => 'rw', default	=>	1 );

#### Strings
has 'password'	=> 	( isa => 'Str|Undef', is => 'rw', required => 0 );
has 'logfile'	=> 	( isa => 'Str|Undef', is => 'rw', required => 1 );
has 'dumpfile'	=> 	( isa => 'Str|Undef', is => 'rw', required => 1 );

#### Arrays
has 'outputs'		=>  ( isa => 'ArrayRef|Undef', is => 'rw', default	=>	sub { return [] } );
has 'inputs'		=>  ( isa => 'ArrayRef|Undef', is => 'rw', default	=>	sub { return [] } );


use FindBin qw($Bin);
use Test::More;

#####////}}}}}

method initialise ($args) {
	$self->logDebug("args", $args);
	
	#### SET SLOTS
	$self->setSlots($args);

	#### NO receiveFanout	
}

method returnOutput {
	return splice($self->outputs(), 0, 1);
}

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
	
	#### SET agua:MODULES
	$self->conf()->setKey("agua:MODULES", undef, "Agua::Workflow");
	
	#### GET DB INFO
	my $dbuser		=	$self->conf()->getKey("database:TESTUSER", undef);
	my $dbpassword	=	$self->conf()->getKey("database:TESTPASSWORD", undef);
	my $database	=	$self->conf()->getKey("database:TESTDATABASE", undef);
	$self->logDebug("dbuser", $dbuser);
	
	#### TEST INFO
	my $testuser	=	$self->conf()->getKey("test:TESTUSER", undef);
	
	##### LOAD DATABASE
	$self->setUpTestDatabase();
	$self->setDatabaseHandle();
	$self->logDebug("AFTER self->setDatabaseHandle(): $self->db()");
	
	my $tests = [
	
	#### submitLogin
	{
		testname	=>	"login success",
		tsvfile		=>	"$Bin/inputs/sessions-success.tsv",
		data		=>	{		
			"sourceid"	=>	"plugins_login_Login_0",
			"callback"	=>	"handleResponse",
			"username"	=>	"guest",
			"password"	=>	"guest",
			"mode"		=>	"submitLogin",
			"module"	=>	"Agua::Workflow",
			"token"		=>	"Zi4Esi12vyy2cdk6",
			"sendtype"	=>	"request"
		}
	}	
	
	#{
	#	testname	=>	"login success",
	#	tsvfile		=>	"$Bin/inputs/users-success.tsv",
	#	username	=>	$testuser,
	#	dbuser		=>	$dbuser,
	#	user		=>	$testuser,
	#	database	=>	$database,
	#	password	=>	12345678,
	#	type		=>	"request",
	#	data		=>	{		
	#		"token"		=>	"nQDUNRuWHBAWqp1y",
	#		"sourceid"	=>	"plugins_login_Login_0",
	#		"callback"	=>	"handleResponse",
	#		"username"	=>	"guest",
	#		"password"	=>	"guest",
	#		"mode"		=>	"submitLogin",
	#		"module"	=>	"Agua::Workflow"
	#
	#		#token		=>	"CDXzZDJH8gzbuP1B",
	#		#sourceid	=>	"plugins_login_Login_0",
	#		#callback	=>	"handleResponse",
	#		#dbuser		=>	$dbuser,
	#		#username	=>	$testuser,
	#		#password	=>	12345678,
	#		#mode		=>	"submitLogin",
	#		#module		=>	"Agua::Workflow",
	#		#database	=>	$database
	#	}
	#}
	#,

	
	
	
	#### getData

#{"username":"admin","sessionid":"9999999999.9999.999","mode":"getData","module":"Agua::Workflow","token":"U1bGFhPUqHXjoE7o","type":"request"}
	#{
	#	testname	=>	"login success",
	#	tsvfile		=>	"$Bin/inputs/sessions-success.tsv",
	#	username	=>	$testuser,
	#	dbuser		=>	$dbuser,
	#	user		=>	$testuser,
	#	database	=>	$database,
	#	password	=>	12345678,
	#	data		=>	{		
	#		username	=>	$testuser,
	#		sessionid	=>	"9999999999.9999.999",
	#		mode		=>	"getData",
	#		module		=>	"Agua::Workflow",
	#		callback	=>	"loadData",
	#		sourceid	=>	"plugins_data_Controller_0",
	#		token		=>	"XBKKmIlEpHss4B0M",
	#		sendtype	=>	"request",
	#	}
	#}	
	#,
	#{
	#	token		=>	"PQGer5cxbgomMF54",
	#	sourceid	=>	"plugins_login_Login_0",
	#	callback	=>	"handleResponse",
	#	username	=>	"guest",
	#	password	=>	"guest",
	#	mode		=>	"submitLogin",
	#	module		=>	"Agua::Workflow"
	#}


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
		my $data		=	$test->{data};
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

		#### START LISTENING
		my $childpid = fork;
		if ( $childpid ) {
			$self->logDebug("IN PARENT. childpid", $childpid);
			$self->receiveFanout();
		}
		elsif ( defined $childpid ) {
			sleep(1);

			#### SEND DATA AS request
			print "Queue::Daemon::testSubmitLogin    DOING sendSocket\n";
			$self->sendData($data);
			print "Queue::Daemon::testSubmitLogin    AFTER sendSocket\n";
		}


		#	my $self	=	shift;
		#	my $data	=	shift;
		#	#$self->logDebug("data", $data);		
		#	$data->{data}->{sessionid} = "" if defined $data->{data}->{sessionid};
		#	is_deeply($data, $expected, "notifyStatus 'data' argument correct");
		
		
	}	
}

method testDuplicateQueries {
	diag("# submitLogin");
	
	#### SET AUTHENTICATION TO password
	$self->conf()->getKey("authentication:TYPE", "password");
	
	#### SET agua:MODULES
	$self->conf()->setKey("agua:MODULES", undef, "Agua::Workflow");
	
	#### GET DB INFO
	my $dbuser		=	$self->conf()->getKey("database:TESTUSER", undef);
	my $dbpassword	=	$self->conf()->getKey("database:TESTPASSWORD", undef);
	my $database	=	$self->conf()->getKey("database:TESTDATABASE", undef);
	$self->logDebug("dbuser", $dbuser);
	
	#### TEST INFO
	my $testuser	=	$self->conf()->getKey("test:TESTUSER", undef);
	
	##### LOAD DATABASE
	$self->setUpTestDatabase();
	$self->setDatabaseHandle();
	$self->logDebug("AFTER self->setDatabaseHandle(): $self->db()");
	
	my $tests = [
	
		#### submitLogin
		{
			testname	=>	"login success",
			tsvfile		=>	"$Bin/inputs/sessions-success.tsv",
			username	=>	$testuser,
			dbuser		=>	$dbuser,
			user		=>	$testuser,
			database	=>	$database,
			password	=>	12345678,
			data		=>	{		
				"sourceid"	=>	"plugins_login_Login_0",
				"callback"	=>	"handleResponse",
				"username"	=>	"guest",
				"password"	=>	"guest",
				"mode"		=>	"submitLogin",
				"module"	=>	"Agua::Workflow",
				"token"		=>	"Zi4Esi12vyy2cdk6",
				"sendtype"	=>	"request"
			}
		}	
	];

	foreach my $test ( @$tests ) {
		my $testname	=	$test->{testname};
		my $tsvfile		=	$test->{tsvfile};
		my $data		=	$test->{data};
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

		#### START LISTENING
		my $childpid = fork;
		if ( $childpid ) {
			$self->logDebug("IN PARENT. childpid", $childpid);
			$self->receiveFanout();
		}
		elsif ( defined $childpid ) {
			sleep(1);

			#### SEND DATA AS request
			print "Queue::Daemon::testSubmitLogin    DOING sendSocket\n";
			$self->sendData($data);
			print "Queue::Daemon::testSubmitLogin    AFTER sendSocket\n";
			sleep(6);
			$self->sendData($data);
			print "Queue::Daemon::testSubmitLogin    AFTER DUPLICATE sendSocket\n";
		}

		#	my $self	=	shift;
		#	my $data	=	shift;
		#	#$self->logDebug("data", $data);		
		#	$data->{data}->{sessionid} = "" if defined $data->{data}->{sessionid};
		#	is_deeply($data, $expected, "notifyStatus 'data' argument correct");
	}
}

method testGetHistory {
	diag("getHistory");

	$self->setup();
	
	my $tests = [
		{
			testname	=>	"getHistory",
			tsvfile		=>	"$Bin/inputs/sessions-success.tsv",
			table		=>	"workflow",
			data		=>	{		
				"mode"		=>	"getHistory",
				"username"	=>	"testuser",
				"sourceid"	=>	"plugins_workflow_History_0",
				"sendtype"	=>	"request",
				"callback"	=>	"validateFiles",
				"whoami"	=>	"syoung",
				"token"		=>	"EVWzBn26vO2nFs72",
				"sessionid"	=>	"9999999999.9999.999",
				"module"	=>	"Agua::Workflow"
			}
		}	
	];

	#### LOAD TSVFILE
	my $tsvfile	=	"$Bin/inputs/stage.tsv";
	$self->loadTsvFile("stage", $tsvfile);
	
	$self->runTests($tests);
	
	$self->teardown();
}

method setup {
	#### SET AUTHENTICATION TO password
	$self->conf()->setKey("authentication:TYPE", undef, "password");
	
	#### SET agua:MODULES
	$self->conf()->setKey("agua:MODULES", undef, "Agua::Workflow");
		
	##### LOAD DATABASE
	$self->setUpTestDatabase();
	$self->setDatabaseHandle();
	$self->logDebug("AFTER self->setDatabaseHandle(): $self->db()");
}

method addAuthentication ($test) {
	$self->logDebug("test", $test);
	$test->{dbuser}		=	$self->conf()->getKey("database:TESTUSER", undef);
	$test->{dbpassword}	=	$self->conf()->getKey("database:TESTPASSWORD", undef);
	$test->{database}	=	$self->conf()->getKey("database:TESTDATABASE", undef);
	$test->{testuser}	=	$self->conf()->getKey("test:TESTUSER", undef);
	$test->{sessionid}	=	$self->conf()->getKey("test:SESSIONID", undef);
	$self->logDebug("Returning test", $test);

	return $test;	
}

method teardown {
	$self->logDebug("");
}

method runTests ($tests) {
	$self->logDebug("");

	foreach my $test ( @$tests ) {
		my $testname	=	$test->{testname};
		my $tsvfile		=	$test->{tsvfile};
		my $data		=	$test->{data};
		my $expected	=	$test->{expected};
		
		#### LOAD TSVFILE
		$self->loadTsvFile("users", $tsvfile);
		
		#### SET USERNAME AND PASSWORD
		$self->username($test->{username});
		$self->password($test->{password});
		$self->logDebug("username", $self->username());
		$self->logDebug("password", $self->password());

		#### START LISTENING
		my $childpid = fork;
		if ( $childpid ) {
			$self->logDebug("IN PARENT. childpid", $childpid);
			$self->receiveFanout();
		}
		elsif ( defined $childpid ) {
			sleep(1);

			#### SEND DATA AS request
			print "Queue::Daemon::testSubmitLogin    DOING sendSocket\n";
			$self->sendData($data);
			print "Queue::Daemon::testSubmitLogin    AFTER sendSocket\n";
		}

	}	
	
}


}

