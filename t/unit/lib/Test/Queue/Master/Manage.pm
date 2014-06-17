use MooseX::Declare;

use strict;
use warnings;

class Test::Queue::Master::Manage extends Queue::Master with (Test::Agua::Common::Database, Agua::Common::Util) {

use Test::Synapse;

has 'logfile'		=> 	( isa => 'Str|Undef', is => 'rw', required => 1 );
has 'dumpfile'		=> 	( isa => 'Str|Undef', is => 'rw', required => 1 );
has 'osauthurl'		=> 	( isa => 'Str|Undef', is => 'rw');
has 'ospassword'	=> 	( isa => 'Str|Undef', is => 'rw');
has 'ostenantid'	=> 	( isa => 'Str|Undef', is => 'rw');
has 'ostenantname'	=> 	( isa => 'Str|Undef', is => 'rw');
has 'osusername'	=> 	( isa => 'Str|Undef', is => 'rw');

has 'synapse'	=> ( isa => 'Test::Synapse', is => 'rw', lazy	=>	1, builder	=>	"setSynapse" );


use FindBin qw($Bin);
use Test::More;

#####////}}}}}

method testManage {
	#### SET TEST DATABASE
	$self->setUpTestDatabase();

	my $testuser	=	$self->conf()->getKey("database", "TESTUSER");
	
	my $tests	=	[
		{
			testname		=>	"latest index",
			queue			=>	{
				username	=>	"testuser",
				project		=>	"CU",
				workflow	=>	"Download"
			},
			tables			=>	[
				"project",
				"provenance",
				"instance",
				"cluster",
				"instancetype",
				"queuesample"
			],
			expected			=>	1
		}
	];

	*getQueueTaskList =	sub	{
		return qq{Listing queues ...
testuser.CU.Download	8
testuser.CU.Bwa	4
testuser.CU.FreeBayes	0
testuser.Sleep.Sleep1	2
testuser.Sleep.Sleep2	2
...done.};
	};

	*listenTopics = sub {
		print "Queue::Master::Manage::testManage    OVERRIDE listenTopics\n";
	};

	*updateShutdown = sub {
		print "Queue::Master::Manage::testManage    OVERRIDE updateShutdown. Returning 'true'\n";

		return "true";
	};
	
	*queueTasks = sub {
		print "Queue::Master::Manage::testManage    OVERRIDE listenTopics\n";
	};

	*getTenants	=	sub {
		return	[
			{
				username	=>	$testuser,
				ospassword	=>	$self->ospassword(),
				osauthurl	=>	$self->osauthurl(),
				ostenantid	=>	$self->ostenantid(),
				ostenantname=>	$self->ostenantname(),
				osusername	=>	$self->osusername(),
			}
		];
	};
	
	foreach my $test ( @$tests ) {
		my $tables			=	$test->{tables};
		my $sample			=	$test->{sample};
		my $workflow		=	$test->{workflow};
		my $testname		=	$test->{testname};
		my $expected		=	$test->{expected};
		my $queue			=	$test->{queue};
		
		#### LOAD TABLES
		foreach my $table ( @$tables ) {
			$self->logDebug("loading table: $table");
			my $query	=	qq{DELETE FROM $table};
			$self->db()->do($query);
			my $tsvfile		=	"$Bin/inputs/duration/$table.tsv";
			$self->loadTsvFile($table, $tsvfile);
		}
		
		my $success	=	$self->manage();
		$self->logDebug("success", $success);
		
		ok($success == $expected, "$testname: $success")
	}
}




}

