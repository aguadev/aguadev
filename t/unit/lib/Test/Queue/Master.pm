use MooseX::Declare;

use strict;
use warnings;

class Test::Queue::Master extends Queue::Master with (Test::Agua::Common::Database, Agua::Common::Util) {

use Test::Synapse;

has 'logfile'	=> 	( isa => 'Str|Undef', is => 'rw', required => 1 );
has 'dumpfile'	=> 	( isa => 'Str|Undef', is => 'rw', required => 1 );

has 'synapse'	=> ( isa => 'Test::Synapse', is => 'rw', lazy	=>	1, builder	=>	"setSynapse" );


use FindBin qw($Bin);
use Test::More;

#####////}}}}}

method testUpdateQueueSamples {
	diag("updateQueueSamples");
	
	#### SET TEST DATABASE
	$self->setUpTestDatabase();

	#### SAMPLE ID
	my $sample	=	"01497a54-775c-479f-a540-d69dd6aa5d8e";
	
	my $query	=	qq{DELETE FROM queuesample};
	$self->db()->do($query);
	$query	=	qq{INSERT INTO queuesample VALUES
('syoung'PanCancer', 'Download', '1', '$sample')};
	$self->logDebug("query", $query);
	$self->db()->do($query);

	my $expected	=	{
		username	=>	"syoung",
		project		=>	"PanCancer",
		workflow	=>	"Align",
		workflownumber	=>	2,
		sample		=>	$sample,
		status		=>	"started"
	};
	
	$self->updateQueueSamples($expected);
	
	$query	=	qq{SELECT * FROM queuesample WHERE sample='$sample'};
	my $result	=	$self->db()->queryhasharray($query);
	$self->logDebug("result", $result);
	ok(scalar(@$result) == 1, "one result only");
	
	my $actual	=	$$result[0];
	is_deeply($actual, $expected, "new entry replaced old");
}

method testUpdateSamples {
	diag("updateSamples");
	
	#### SET TEST DATABASE
	$self->setUpTestDatabase();

	#### FRESH START	
	$self->db()->do("DELETE FROM provenance");
	$self->db()->do("DELETE FROM queuesample");
	
	#### SET QUEUES
	my $queues	=	[
	{
		username	=>	"testuser",
		project		=>	"PanCancer",
		workflow	=>	"Download",
		workflownumber	=>	1
	},
	{
		username	=>	"testuser",
		project		=>	"PanCancer",
		workflow	=>	"Split",
		workflownumber	=>	2
	},
	{
		username	=>	"testuser",
		project		=>	"PanCancer",
		workflow	=>	"Align",
		workflownumber	=>	3
	}];

	my $tests	=	[
		{
			testname		=>	"empty table",
			tsvfile			=>	"",
			expectedfile	=>	"$Bin/inputs/updateSamples/expected.tsv"	
		}
		,
		{
			testname		=>	"already populated table - no duplicates",
			tsvfile			=>	"$Bin/inputs/updateSamples/queuesample.tsv",
			expectedfile	=>	"$Bin/inputs/updateSamples/expected-added.tsv"	
		}
	];

	#### PRELOAD 'synapse' ENTRIES INTO FAKE Synapse.pm OBJECT
	my $assignmentfile	=	"$Bin/inputs/assignments.txt";
	$self->logDebug("assignmentfile", $assignmentfile);
	my $contents	=	$self->fileContents($assignmentfile);
	my @entries		=	split "\n", $contents;
	$self->logDebug("No. entries", $#entries + 1);
	$self->synapse()->outputs([\@entries, \@entries]);
	
	foreach my $test ( @$tests ) {
		my $tsvfile		=	$test->{tsvfile};
		my $testname	=	$test->{testname};
		
		#### LOAD TABLE
		my $query	=	qq{DELETE FROM queuesample};
		$self->logDebug("query", $query);
		$self->db()->do($query);

		#### LOAD TSVFILE IF NOT EMPTY		
		$self->loadTsvFile("queuesample", $tsvfile) if $tsvfile ne "";
		
		#### UPDATE SAMPLES
		$self->updateSamples($queues);
	
		$query	=	qq{SELECT * FROM queuesample};
		$self->logDebug("query", $query);
		my $samples	=	$self->db()->queryhasharray($query);
		
		my $expectedfile=	$test->{expectedfile};
		my $fields		=	$self->db()->fields("queuesample");
		my $expected	=	$self->fileToHasharray($expectedfile, $fields);
	
		is_deeply($samples, $expected, $testname);
	}
}

method fileToHasharray ($file, $fields) {
	$self->logDebug("file", $file);
	
	my $hasharray	=	[];
	my $contents	=	$self->fileContents($file);
	my @lines		=	split "\n", $contents;
	foreach my $line ( @lines ) {
		next if $line =~ /^\s*$/;
		
		my $hash;
		my @elements	=	split "\t", $line;
		for ( my $i = 0; $i < @$fields; $i++ ) {
			my $value	=	$elements[$i] || "";
			$hash->{$$fields[$i]}	=	$value;
		}
		
		push @$hasharray, $hash;
	}
	
	return $hasharray;
}

method testUpdateQueueSamples {
	diag("updateQueue");

	#### SET UP DATABASE
	my $database	=	$self->conf()->getKey("database:TESTDATABASE", undef);
	$self->logDebug("database", $database);
	$self->database($database);
	$self->setTestDbh();
	$self->db()->do("DELETE FROM queuesample");

	my $data 	=	{
"username"	=>	"testuser",
"project"	=>	"PanCancer",
"workflow"	=>	"Align",
"workflownumber"=>	"1",
"sample"	=>	"a9012345678",
"stage"		=>	"align",
"stagenumber"=>	"1",
"application"=>	"sleep",
"owner"		=>	"syoung",
"package"	=>	"package",
"version"	=>	"0.8.0",
"installdir"=>	"/agua/apps/bioapps",
"location"	=>	"bin/test/sleep.sh",
"host"		=>	"10.0.2.15",
"queued"	=>	"2014-05-03 06:49:30",
"started"	=>	"2014-05-03 06:49:30",
"completed"	=>	"2014-05-03 06:51:10",
"status"	=>	"completed",
"stdout"	=>	"ubuntu.example.com\\nSat May  3 06:53:26 UTC 2014\\nCompleted\\n",
"stderr"	=>	""
};

	ok($self->updateQueueSamples($data), "updated queuesample table");
}

method testGetSynapseStatus {
	diag("getSynapseStatus");

	my $data 	=	{
"username"	=>	"testuser",
"project"	=>	"PanCancer",
"workflow"	=>	"Align",
"workflownumber"=>	"1",
"sample"	=>	"a9012345678",
"stage"		=>	"align",
"stagenumber"=>	"1",
"application"=>	"sleep",
"owner"		=>	"syoung",
"package"	=>	"package",
"version"	=>	"0.8.0",
"installdir"=>	"/agua/apps/bioapps",
"location"	=>	"bin/test/sleep.sh",
"host"		=>	"10.0.2.15",
"queued"	=>	"2014-05-03 06:49:30",
"started"	=>	"2014-05-03 06:49:30",
"completed"	=>	"2014-05-03 06:51:10",
"status"	=>	"completed",
"stdout"	=>	"ubuntu.example.com\\nSat May  3 06:53:26 UTC 2014\\nCompleted\\n",
"stderr"	=>	""
};

	my $expected		=	"aligned";
	my $synapsestatus	=	$self->getSynapseStatus($data);
	$self->logDebug("synapsestatus", $synapsestatus);
	
	ok($synapsestatus eq $expected, "aligned");
}

method testHandleTopic {
	diag("handleTopic");

	#### HANDLE SEQUENTIAL ADDITIONS TO THE provenance TABLE
	
	#### SET TEST DATABASE
	$self->setUpTestDatabase();

	#### SET UP DATABASE
	my $database	=	$self->conf()->getKey("database:TESTDATABASE", undef);
	$self->logDebug("database", $database);
	$self->database($database);
	$self->setTestDbh();
	
	my $tests	=	[
		{
			file	=>	"$Bin/inputs/handleTopic/topic-split.json",
			testname=>	"split topic"
		}
		,
		{
			file	=>	"$Bin/inputs/handleTopic/topic-align.json",
			testname=>	"align topic"
		}
	];

	#### FRESH START	
	$self->db()->do("DELETE FROM provenance");
	$self->db()->do("DELETE FROM queuesample");
		
	my $expectedarray	=	[];
	foreach my $test ( @$tests ) {
		my $file		=	$test->{file};
		my $testname	=	$test->{testname};
		$self->logDebug("file", $file);
		
		#### GET TEST DATA
		$self->logDebug("file not found: $file") and die if not -f $file;
		my $json	=	$self->fileContents($file);
		$self->logDebug("json length", length($json));
	
		#### HANDLE TOPIC
		$self->handleTopic($json);
	
		#### SET EXPECTED
		my $expected	=	$self->jsonparser()->decode($json);
		delete $expected->{mode};
		delete $expected->{number};
		$self->logDebug("expected->owner", $expected->{owner});
		$self->logDebug("expected", $expected);
		
		push (@$expectedarray, $expected);
		
		#### GET ACTUAL
		my $query =	"SELECT * FROM provenance ORDER BY workflownumber DESC";
		$self->logDebug("query", $query);
		my $actualarray	=	 $self->db()->queryhasharray($query);
		$self->logDebug("actualarray", $actualarray);

		#### COMPARE	
		is_deeply($actualarray, $expectedarray, "$testname added to provenance table");	
	}
}

method testReceiveTopic {
	diag("receiveTopic");
	
	$self->receiveTopic();	
}
method testListenTopics {
	diag("listenTopics");
	
	
	$self->listenTopics();
}
method testMaintainQueue {
	diag("maintainQueue");
	
	#### SET TEST DATABASE
	$self->setUpTestDatabase();
	
	my $tsvfile	=	"$Bin/inputs/queuesample.tsv";
	$self->loadTsvFile("queuesample", $tsvfile);
	
	my $queuedata	=	{
		username	=>	"testuser",
		project		=>	"PanCancer",
		workflow	=>	"Sleep",
		workflownumber	=>	1,
		database	=>	"aguatest"
	};
	
	#my $queuedata	=	{
	#	username	=>	"syoung",
	#	project		=>	"PanCancer",
	#	workflow	=>	"Align",
	#	workflownumber	=>	3,
	#	database	=>	"agua"
	#};
	
	$self->maintainQueue($queuedata);

	#### TO DO: MOCK OUT QUEUE REPONSES
}


method testGetNumberQueuedJobs {
	diag("getNumberQueuedJobs");

	my $queuelist	=	 qq{amq.gen-dQQNw7zLy1jLpGMLpnue3g	0
amq.gen-fbZhLQXxwwSxTp6z3Oj0BQ	0
amq.gen-mv6DB2AzWKA9tt8txfcz5g	0
amq.gen-p1uC9ZDwNUCmZr4stDBsEQ	0
amq.gen-pWogrdvCMkSEvJgvBzvFcg	0
amq.gen-pbszDnl91iOfUU0QBNd1Kw	0
amq.gen-xXCpu19zUBC2sZWVXuPOHQ	0
syoung.PanCancer.Align	8
syoung.PanCancer.Download	9
syoung.PanCancer.Split	10
...done.
};

	my $tests =	[
		{
			testname=>	"align queue",
			queue	=>	"syoung.PanCancer.Align",
			expected	=>	8
		},
		{
			testname=>	"download queue",
			queue	=>	"syoung.PanCancer.Download",
			expected	=>	9
		},
		{
			testname=>	"split queue",
			queue	=>	"syoung.PanCancer.Split",
			expected	=>	10
		},
		{
			testname=>	"queue not found - undef expected",
			queue	=>	"syoung.PanCancer.QueueNotFound",
			expected	=>	undef
		}
	];
	
	foreach my $test ( @$tests ) {
		my $queue		=	$test->{queue};
		my $queuedjobs	=	$self->getNumberQueuedJobs($queuelist, $queue);
		my $expected	=	$test->{expected};
		$self->logDebug("queuedjobs", $queuedjobs);
		$self->logDebug("expected", $expected);
		
		is_deeply($queuedjobs, $expected, $test->{testname});
	}
}

method testWorkflowStatus {
	my $configfile	=	"$Bin/inputs/config.yaml";
	$self->conf()->inputfile($configfile);

	$self->workflowStatus();
}

method testDownloadPercent {
	diag("downloadPercent");
	my $status		=	q{Status:  195 GB downloaded (40.401% complete) current rate:        /s
};
	my $expected	=	"40.401";

	my $percent	=	$self->downloadPercent($status);
	is($percent, $expected, "percent");	
}

method testParseUuid {
	diag("parseUuid");
	my $contents	=	qq{root     18375  0.0  0.0   4400   604 ?        S    Apr12   0:00 sh -c time /usr/bin/gtdownload \?--max-children 8 \?-c /home/ubuntu/annai-cghub.key \?-v -d \?eba7900a-2e1d-4a55-a3ba-e900be55642e \?-l syslog:full?
root     18376  0.0  0.0   4168   348 ?        S    Apr12   0:00 time /usr/bin/gtdownload --max-children 8 -c /home/ubuntu/annai-cghub.key -v -d eba7900a-2e1d-4a55-a3ba-e900be55642e -l syslog:full
root     18377  0.0  0.0 156940 11796 ?        S    Apr12   0:23 /usr/bin/gtdownload --max-children 8 -c /home/ubuntu/annai-cghub.key -v -d eba7900a-2e1d-4a55-a3ba-e900be55642e -l syslog:full
root     18378  1.4  0.4 641056 321376 ?       Sl   Apr12  55:57 /usr/bin/gtdownload --max-children 8 -c /home/ubuntu/annai-cghub.key -v -d eba7900a-2e1d-4a55-a3ba-e900be55642e -l syslog:full
root     18382  1.5  0.4 641060 324292 ?       Sl   Apr12  56:36 /usr/bin/gtdownload --max-children 8 -c /home/ubuntu/annai-cghub.key -v -d eba7900a-2e1d-4a55-a3ba-e900be55642e -l syslog:full
root     18386  1.3  0.4 641064 324900 ? Sl   Apr12  51:28 /usr/bin/gtdownload --max-children 8 -c /home/ubuntu/annai-cghub.key -v -d eba7900a-2e1d-4a55-a3ba-e900be55642e -l syslog:full
root     18390  1.4  0.4 641068 324672 ?       Sl   Apr12  54:10 /usr/bin/gtdownload --max-children 8 -c /home/ubuntu/annai-cghub.key -v -d eba7900a-2e1d-4a55-a3ba-e900be55642e -l syslog:full
root     18394  1.6  0.4 641072 323988 ?       Sl   Apr12  62:22 /usr/bin/gtdownload --max-children 8 -c /home/ubuntu/annai-cghub.key -v -d eba7900a-2e1d-4a55-a3ba-e900be55642e -l syslog:full
root     18398  1.3  0.4 641076 323128 ?       Sl   Apr12  50:52 /usr/bin/gtdownload --max-children 8 -c /home/ubuntu/annai-cghub.key -v -d eba7900a-2e1d-4a55-a3ba-e900be55642e -l syslog:full
root     18402  1.3  0.4 641080 321196 ?       Sl   Apr12  51:05 /usr/bin/gtdownload --max-children 8 -c /home/ubuntu/annai-cghub.key -v -d eba7900a-2e1d-4a55-a3ba-e900be55642e -l syslog:full
root     18406  1.4  0.4 641084 325152 ?       Sl   Apr12  56:02 /usr/bin/gtdownload --max-children 8 -c /home/ubuntu/annai-cghub.key -v -d eba7900a-2e1d-4a55-a3ba-e900be55642e -l syslog:full
ubuntu   20477  0.0  0.0  11144  1540 pts/1    Ss+  13:50   0:00 bash -c ps aux | grep /usr/bin/gtdownload
ubuntu   20482  0.0  0.0   8112   920 pts/1    S+   13:50   0:00 grep /usr/bin/gtdownload
};
	my @lines		=	split "\n", $contents;
	my $expected	=	"eba7900a-2e1d-4a55-a3ba-e900be55642e";
	$self->logDebug("expected", $expected);
	
	my $uuid	=	$self->parseUuid(\@lines);
	$self->logDebug("uuid", $uuid);
	
	ok($uuid eq $expected, "uuid");	
}

method fileContents ($file) {
	$self->logNote("file", $file);
	return undef if not -f $file;
	
	my $contents;
	open(FILE, $file) or die "Can't open file: $file\n";
	{
		$/ = undef;
		$contents	=	<FILE>;
	}
	close(FILE) or die "Can't close file: $file\n";
	$self->logNote("contents", $contents);
	
	return $contents;
}

method identicalFiles ($actualfile, $expectedfile) {
	$self->logDebug("actualfile", $actualfile);
	$self->logDebug("expectedfile", $expectedfile);
	
	my $command = "diff -wB $actualfile $expectedfile";
	$self->logDebug("command", $command);
	my $diff = `$command`;
	
	return 1 if $diff eq '';
	return 0;
}


method setSynapse {
	$self->logDebug("");

	my $synapse	= Test::Synapse->new({
		conf		=>	$self->conf(),
		showlog     =>  $self->showlog(),
		printlog    =>  $self->printlog(),
		logfile     =>  $self->logfile()
	});

	$self->synapse($synapse);
}


}

