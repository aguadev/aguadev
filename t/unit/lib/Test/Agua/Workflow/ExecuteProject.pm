use MooseX::Declare;

class Test::Agua::Workflow::ExecuteProject with (Test::Agua::Common::Database,
	Test::Agua::Common::Util) extends Agua::Workflow {

#### EXTERNAL MODULES
use Test::More;
use FindBin qw($Bin);

#### INTERNAL MODULES
use Agua::DBaseFactory;
use Test::Virtual;

has 'dumpfile'		=> ( isa => 'Str|Undef', is => 'rw' );
has 'conf'	=> ( isa => 'Conf::Yaml', is => 'rw', lazy => 1, builder => "setConf" );


#####/////}}}}

method BUILD ($hash) {
	$self->initialise($hash);
}

method initialise ($hash) {
	if ( $hash ) {
		foreach my $key ( keys %{$hash} ) {
			$self->$key($hash->{$key}) if $self->can($key);
		}
	}
	#$self->logDebug("hash", $hash);
}

method testRunSiphon {
	
# TO DO: SPIN THIS OUT INTO RunSiphonWorkflows.pm

    #### SET USERNAME AND CLUSTER
	diag("runSiphon");
	
	#### SET TEST DATABASE
	$self->setUpTestDatabase();

	#### SET CONF READONLY
	$self->conf()->memory(1);
	
	#### COPY OPENRC FILE
	my $installdir	=	$self->conf()->getKey("agua", "INSTALLDIR");
	my $path		=	"bin/install/resources/openstack";
	my $testdir		=	"$Bin/inputs/$path";
	my $testfile	=	"$testdir/openrc.sh";
	`mkdir -p $testdir` if not -d $testdir; 
	my $command		=	"cp $installdir/$path/openrc.sh $testdir";
	$self->logDebug("command", $command);
	`$command` if not -f $testfile;
	
	my $tests	=	[
		{
			testname	=>	"runSiphonWorkflows success",
			project		=>	"Project1",
			expected	=>	[
				"$Bin/inputs/conf/.openstack/secretservices-openrc.sh",
				"bcf.8c.64g",
				"5",
				"30",
				"$Bin/inputs/conf/.openstack/testuser.Project1.Bwa.sh",
				"Bwa"
			]
		}
	];

	my $username 	=  	$self->conf()->getKey("database", "TESTUSER");

	*executeWorkflow = sub {
		$self->logDebug("OVERRIDE executeWorkflow");
		return 1;
	};

	foreach my $test ( @$tests ) {
		my $testname 	=  	$test->{testname};
		my $project 	=  	$test->{project};
		my $expected	=	$test->{expected};
		$self->username($username);
		$self->project($project);
		$self->logDebug("username", $username);
		$self->logDebug("project", $project);
		
		#### LOAD TSVFILES
		my $tables = [
			"project",
			"workflow",
			"stage",
			"tenant",
			"stageparameter",
			"cluster",
			"clusterworkflow"
		];

		foreach my $table ( @$tables ) {
			#### CLEAR TABLE
			my $query	=	qq{DELETE FROM $table};
			#$self->logDebug("query", $query);
			$self->db()->do($query);
			
			#### LOAD TABLE
			$self->logDebug("loading table: $table");
			my $tsvfile		=	"$Bin/inputs/$table.tsv";
			$self->loadTsvFile($table, $tsvfile);
		}

		#### RESET INSTALLDIR
		$self->conf()->setKey("agua", "INSTALLDIR", "$Bin/inputs");

		#my $args;
		#$self->virtual()->launchNodes	=	sub	{
		#	my $self	=	shift;
		#	$args	=	\@_;
		#	$self->logDebug("OVERRIDE launchOpenstackNodes    args", $args);
		#	return 1;
		#};
		
		
		#### TEST START STARCLUSTER
		$self->logDebug("DOING ExecuteProject()");
		my $success	=	$self->executeProject();
		$self->logDebug("success", $success);
		
		#### RETURNED OK
		ok($success, $testname);

		##### ARGS TO launchOpenstackNodes
		#$self->logDebug("args", $args);
		#is_deeply($args, $expected, "launchNodes call args");
	}
}

method testExecuteProject {
    #### SET USERNAME AND CLUSTER
	diag("executeProject");
	
	#### SET TEST DATABASE
	$self->setUpTestDatabase();

	#### SET CONF READONLY
	$self->conf()->memory(1);
	
	#### COPY OPENRC FILE
	my $installdir	=	$self->conf()->getKey("agua", "INSTALLDIR");
	my $path		=	"bin/install/resources/openstack";
	my $testdir		=	"$Bin/inputs/$path";
	`mkdir -p $testdir` if not -d $testdir;
	my $targetfile	=	"$testdir/openrc.sh";
	my $command		=	"cp $installdir/$path/openrc.sh $targetfile";
	$self->logDebug("command", $command);
	`$command` if not -f $targetfile;
	
	my $tests	=	[
		{
			testname	=>	"executeProject continues on executeWorkflow success",
			subroutine	=>	sub {
				#print "ExecuteProject::testExecuteProjects    RETURNING 1\n";
				return 1;
			},
			project		=>	"Project1",
			expected	=>	1
		}
		,
		{
			testname	=>	"executeProject halts on executeWorkflow error",
			subroutine	=>	sub {
				warn "test warning";
				return 0;
			},
			project		=>	"Project1",
			expected	=>	0
		}
	];

	my $username 	=  	$self->conf()->getKey("database", "TESTUSER");

	*launchOpenstackNodes	=	sub	{
		my $self	=	shift;
		$self->logDebug("OVERRIDE launchOpenstackNodes");
		return 1;
	};
	
	*logError	=	sub	{
		my $self	=	shift;
		my $message	=	shift;
		$self->logDebug("OVERRIDE logError    message", $message);
	};

	foreach my $test ( @$tests ) {
		my $testname 	=  	$test->{testname};
		my $project 	=  	$test->{project};
		my $subroutine 	=  	$test->{subroutine};
		my $expected	=	$test->{expected};
		$self->username($username);
		$self->project($project);
		$self->logDebug("username", $username);
		$self->logDebug("project", $project);
		
		#### LOAD TSVFILES
		my $tables = [
			"project",
			"workflow",
			"stage",
			"stageparameter",
			"tenant",
			"cluster",
			"clusterworkflow"
		];
		foreach my $table ( @$tables ) {
			#### CLEAR TABLE
			my $query	=	qq{DELETE FROM $table};
			#$self->logDebug("query", $query);
			$self->db()->do($query);
			
			#### LOAD TABLE
			$self->logDebug("loading table: $table");
			my $tsvfile		=	"$Bin/inputs/$table.tsv";
			$self->loadTsvFile($table, $tsvfile);
		}

		#### OVERRIDE
		no warnings;
		*{executeWorkflow} = $subroutine;
		use warnings;

		#### RESET INSTALLDIR
		$self->conf()->setKey("agua", "INSTALLDIR", "$Bin/inputs");

		#### TEST START STARCLUSTER
		$self->logDebug("DOING ExecuteProject()");
		my $success	=	$self->executeProject();
		$self->logDebug("success", $success);
		
		#### TEST COMPLETED
		ok($success == $expected, $testname);
	}
}

method testPrintAuth {
    #### SET USERNAME AND CLUSTER
	diag("printAuth");
	
	#### SET TEST DATABASE
	$self->setUpTestDatabase();
	
	my $installdir		=	$self->conf()->getKey("agua", "INSTALLDIR");
	
	my $tests	=	[
		{
			username	=>	"testuser",
			testname	=>	"authfile printed",
			templatefile=>	"$installdir/bin/install/resources/openstack/openrc.sh",
			expectedfile=>	"$Bin/inputs/conf/expected-openrc.sh",
			tables		=>	[
				"tenant"
			]
		}
	];
	
	#### MAKE CONF READ ONLY
	$self->conf()->memory(1);
	
	#### REASSIGN INSTALLDIR
	$installdir	=	"$Bin/inputs";
	$self->conf()->setKey("agua", "INSTALLDIR", $installdir);

	foreach my $test ( @$tests ) {
		my $testname 	=  	$test->{testname};
		my $tables 		=  	$test->{tables};
		my $username 	=  	$test->{username};
		my $templatefile=  	$test->{templatefile};
		my $expectedfile=	$test->{expectedfile};
		
		$self->logDebug("username", $username);
		$self->logDebug("testname", $testname);
		$self->logDebug("templatefile", $templatefile);
		$self->logDebug("expectedfile", $expectedfile);
		
		#### LOAD TSVFILES
		foreach my $table ( @$tables ) {
			$self->logDebug("loading table: $table");
			my $query	=	qq{DELETE FROM $table};
			$self->db()->do($query);
			my $tsvfile		=	"$Bin/inputs/tsv/$table.tsv";
			$self->loadTsvFile($table, $tsvfile);
		}
		
		my $openrcfile	=	$self->printAuth($username);
		$self->logDebug("openrcfile", $openrcfile);
		
		my $diff	=	$self->diff($openrcfile, $expectedfile);
		$self->logDebug("diff", $diff);
		ok($diff, "openrcfile contents");
	
	}

}

method testPrintConfig {
	diag("printConfig");

	#### SET TEST DATABASE
	$self->setUpTestDatabase();
	
	my $tests	=	[
		{
			testname		=>	"userdata file printed",
			project			=>	"CU",
			tables			=>	[
				"stage"
			],
			expected		=> ""
		}
	];

	foreach my $test ( @$tests ) {
		my $tables			=	$test->{tables};
		#my $queues			=	$test->{queues};
		#my $durations		=	$test->{durations};
		my $project			=	$test->{project};
		my $metric			=	$test->{metric};
		#my $instancecounts	=	$test->{instancecounts};
		my $testname		=	$test->{testname};
		my $expected		=	$test->{expected};
		
		#### LOAD TABLES
		foreach my $table ( @$tables ) {
			$self->logDebug("loading table: $table");
			my $query	=	qq{DELETE FROM $table};
			$self->db()->do($query);
			my $tsvfile		=	"$Bin/inputs/$table.tsv";
			$self->loadTsvFile($table, $tsvfile);
		}
		
		*setTemplateFile	=	sub {
			return "$Bin/inputs/data/userdata.tmpl";
		};
		
		my $installdir		=	$self->conf()->getKey("agua", "INSTALLDIR");
		my $templatefile	=	"$installdir/data/userdata.tmpl";
		$self->logDebug("templatefile", $templatefile);
	
		my $workflowobject	=	{
			username	=>	"testuser",
			project		=>	"Project1",
			workflow	=>	"Download"
		};
	
		#### MAKE CONF READ ONLY
		$self->conf()->memory(1);
	
		#### REASSIGN INSTALLDIR
		$installdir	=	"$Bin/inputs";
		$self->conf()->setKey("agua", "INSTALLDIR", $installdir);
		
		my $userdatafile	=	$self->printConfig($workflowobject);
		$self->logDebug("userdatafile", $userdatafile);
		
		my $expectedfile	=	"$Bin/inputs/data/expected.tmpl";
		$self->logDebug("expectedfile", $expectedfile);
		
		my $diff	=	$self->diff($userdatafile, $expectedfile);
		$self->logDebug("diff", $diff);
		ok($diff, "userdatafile contents");
	}	

}

#### OVERRIDE
method overrideSequence ($method, $sequence) {
	$self->logDebug("method", $method);
	$self->logDebug("sequence", $sequence);

	#### SET ATTRIBUTES - SEQUENCE AND COUNTER
	my $attribute = "$method-sequence";
	my $counter = "$method-counter";
	$self->custom_field($attribute, $sequence);
	$self->custom_field($counter, 0);

	my $sub = sub {
		my $self	=	shift;
		$self->logDebug("method", $method);

		my $sequence = $self->custom_field($attribute);
		$self->logDebug("sequence", $sequence);

		my $count 	= $self->custom_field($counter);
		my $value 	= 	$$sequence[$count];
		$self->logDebug("counter $count value", $value);
		
		$count++;
		$self->custom_field($counter, $count);
	
		return $value;
	};

	{
		no warnings;
		no strict;
		*{$method} = $sub;
	}
}


#### SET Test::Virtual

method setVirtual {
	my $virtualtype		=	$self->conf()->getKey("agua", "VIRTUALTYPE");
	$self->logDebug("virtualtype", $virtualtype);

	#### RETURN IF TYPE NOT SUPPORTED	
	$self->logDebug("virtual virtualtype not supported: $virtualtype") and return if $virtualtype !~	/^(openstack|vagrant)$/;

   #### CREATE DB OBJECT USING DBASE FACTORY
    my $virtual = Test::Virtual->new( $virtualtype,
        {
			conf		=>	$self->conf(),
            username	=>  $self->username(),
			
			logfile		=>	$self->logfile(),
			log			=>	2,
			printlog	=>	2
        }
    ) or die "Can't create virtual of type: $virtualtype. $!\n";
	$self->logDebug("virtual", $virtual);

	$self->virtual($virtual);
}


}   #### Test::Agua::Workflow