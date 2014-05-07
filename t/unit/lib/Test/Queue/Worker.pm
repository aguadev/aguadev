use MooseX::Declare;

use strict;
use warnings;

class Test::Queue::Worker extends Queue::Worker with Test::Agua::Common::Database {

has 'sleep'	=> 	( isa => 'Int|Undef', is => 'rw', default => 10 );
has 'logfile'	=> 	( isa => 'Str|Undef', is => 'rw', required => 1 );
has 'handled'	=> 	( isa => 'Str|Undef', is => 'rw', default => 0 );

use FindBin qw($Bin);
use Test::More;

#####////}}}}}

method testShutdown {
	$self->logDebug("");
	$self->shutdown();	
}

method testVerifyShutdown {
	diag("verifyShutdown");

	my $shuttingdown	=	"false";
	#*shutdown = sub {
	#	$shuttingdown	=	"true";
	#};
	
	#### ENABLE SHUTDOWN	
	$self->conf()->memory(1);
	$self->conf()->setKey("agua:SHUTDOWN", undef, "true");
	
	#### VERIFY SHUTDOWN
	$self->verifyShutdown();
	ok($shuttingdown eq "true", "shutdown");
	
	#### DISABLE SHUTDOWN	
	$shuttingdown	=	"false";
	$self->conf()->setKey("agua:SHUTDOWN", undef, "false");
	
	#### VERIFY SHUTDOWN
	$self->verifyShutdown();	
	ok($shuttingdown eq "false", "no shutdown");

	#### ENABLE SHUTDOWN	
	$self->conf()->setKey("agua:SHUTDOWN", undef, "true");
	
	#### VERIFY SHUTDOWN
	$self->verifyShutdown();
	ok($shuttingdown eq "true", "shutdown");
}

method testHandleTask {
	$self->setTestDbh();
	
	$self->db()->do("DELETE FROM project");
	$self->db()->do("DELETE FROM workflow");
	$self->db()->do("DELETE FROM stage");
	$self->db()->do("DELETE FROM stageparameter");
	
	$self->loadTsvFile("project", "$Bin/inputs/project.tsv");
	$self->loadTsvFile("workflow", "$Bin/inputs/workflow.tsv");
	$self->loadTsvFile("stage", "$Bin/inputs/stage.tsv");
	$self->loadTsvFile("stageparameter", "$Bin/inputs/stageparameter.tsv");
	
	#my $json	=	qq{{
	#	"username"		:	"testuser",
	#	"project"		:	"PanCancer",
	#	"workflow"		:	"Sleep",
	#	"workflownumber":	1,
	#	"number"		:	1,
	#	"database"		:	"aguatest",
	#	"sample"		:	"e1234567890"
	#}};
	
	my $json	=	qq{{
		"username"		:	"syoung",
		"project"		:	"PanCancer",
		"workflow"		:	"Align",
		"workflownumber":	3,
		"number"		:	3,
		"database"		:	"agua",
		"sample"		:	"f68ceda0-e068-46b3-a07b-2fa064a9709d"
	}};

	$self->handleTask($json);

	my $errors	=	$?;
	$self->logDebug("errors", $errors);
	ok($errors eq "0", "exitcode is 0");
}

method testMethod {
	return undef;
}

method testSendTopic {
	#my $data	=	{
	#	username	=>	"syoung",
	#	project		=>	"Test",
	#	workflow	=>	"Sleep",
	#	workflownumber	=>	"1",
	#	
	#	package		=>	"bioapps",
	#	version		=>	"0.0.1",
	#	installdir	=>	"apps/bioapps",
	#	username	=>	"syoung",
	#	name		=>	"sleep",
	#	number		=>	1,
	#	type		=>	"test",
	#	location	=>	"bin/test/sleep.pl",
	#	queued		=>	"Fri May  2 14:49:22 PDT 2014",
	#	started		=>	"Fri May  2 14:49:22 PDT 2014",
	#	completed	=>	"Fri May  2 14:52:00 PDT 2014",
	#	status		=>	"completed"
	#};
	#
	
	my $data 	=	{
		"stderr"	=>	"",
		"number"	=>	"1",
		"status"	=>	"completed",
		"project"	=>	"PanCancer",
		"stdout"	=>	"ubuntu.example.comSat May  3 06:53:26 UTC 2014Completed",
		"completed"	=>	"2014-05-03 06:49:30",
		"workflownumber"	=>	"1",
		"sample"	=>	"e9012345678",
		"location"	=>	"bin/test/sleep.sh",
		"executor"	=>	"",
		"name"		=>	"sleep",
		"username"	=>	"testuser",
		"host"		=>	"10.0.2.15",
		"workflow"	=>	"Sleep",
		"started"	=>	"20",
		"queued"	=>	"20"
	};
	
	my $key	=	"update.job.status";
	$self->sendTopic($data, $key);	
}

method testReceiveTask {
	#### VERIFY CONNECTION IS LISTENING
	my $taskqueue	=	"testuser.PanCancer.Sleep";
	$self->receiveTask($taskqueue);	
}



}

