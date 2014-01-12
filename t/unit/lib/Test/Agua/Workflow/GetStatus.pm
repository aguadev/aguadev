use MooseX::Declare;

class Test::Agua::Workflow::GetStatus with (Test::Agua::Common::Database,
	Test::Agua::Common::Util) extends Agua::Workflow {

#### EXTERNAL MODULES
use Test::More;

#### INTERNAL MODULES
use Agua::DBaseFactory;
use Test::Agua::StarCluster;
use Test::Agua::Monitor::SGE;

has 'dumpfile'		=> ( isa => 'Str|Undef', is => 'rw' );
#has 'conf' 	=> (
#	is =>	'rw',
#	'isa' => 'Conf::Yaml',
#	default	=>	sub {
#		Conf::Yaml->new( backup	=>	1 );
#	}
#);
#
has 'conf'	=> ( isa => 'Conf::Yaml', is => 'rw', lazy => 1, builder => "setConf" );

has 'starcluster'	=> ( isa => 'Test::Agua::StarCluster', is => 'rw', lazy => 1, builder => "setStarCluster" );
	
#has 'starcluster'	=> (
#	is =>	'rw',
#	isa => 'Test::Agua::StarCluster',
#	default	=>	sub { Test::Agua::StarCluster->new({
#        SHOWLOG     => 2,
#        PRINTLOG    =>  5
#    });	}
#);

has 'monitor'	=> (
	is 		=>	'rw',
	isa 	=> 'Test::Agua::Monitor::SGE',
	default	=>	sub { Test::Agua::Monitor::SGE->new({});	}
);

has custom_fields => (
    traits     => [qw( Hash )],
    isa        => 'HashRef',
    builder    => '_build_custom_fields',
    handles    => {
        custom_field         => 'accessor',
        has_custom_field     => 'exists',
        custom_fields        => 'keys',
        has_custom_fields    => 'count',
        delete_custom_field  => 'delete',
    },
);

sub _build_custom_fields { {} }

#####/////}}}}

method BUILD ($hash) {
	print "Test::Agua::Workflow::BUILD\n";
	
	$self->initialise($hash);
}

method initialise ($hash) {
	print "Test::Agua::Workflow::initialise\n";
	if ( $hash ) {
		foreach my $key ( keys %{$hash} ) {
			$self->$key($hash->{$key}) if $self->can($key);
		}
	}
	$self->logDebug("hash", $hash);
}

method setStarCluster {
	$self->logDebug("");
	my $starcluster = Test::Agua::StarCluster->new({
		username	=>	$self->username(),
		cluster		=>  $self->cluster(),
		conf		=>	$self->conf(),
        SHOWLOG     => 	$self->SHOWLOG(),
        PRINTLOG    =>  $self->PRINTLOG()
    });

	$self->starcluster($starcluster);
}
method setUpStarCluster ($username, $cluster) {
    $self->logDebug("");

    #### TEST StarCluster ISA Test::Agua::StarCluster
    isa_ok($self->starcluster(), "Test::Agua::StarCluster");

	#### COPY SOURCE TO TARGET DIRS, CREATE DATABASE AND LOAD TABLE DATA
	$self->setWorkflowTestDatabase();

    #### SET JSON
    $self->json({
        username    =>  $username,
        cluster     =>  $cluster
    });

    #### SET OUTPUT DIR    
    $self->outputdir("$Bin/outputs/testuser/.starcluster");    

    #### SET CONFIG FILE
    $self->configfile("$Bin/outputs/testuser/.starcluster/testuser-testcluster.config");
    
    #### SET INSTALL DIR FOR EC2 KEY FILE
    $self->conf()->setKey("agua", 'INSTALLDIR', "$Bin/outputs");

	##### SET STARCLUSTER BINARY
	my $executable = "$Bin/outputs/starcluster";
	`chmod 755 $executable`;
	$self->conf()->setKey("agua", "STARCLUSTER", $executable);

	##### SET USERDIR FOR BALANCER OUTPUT DIR/FILE
	$self->conf()->setKey("agua", "USERDIR", "$Bin/outputs");

    #### SET STARCLUSTER CONF
    $self->starcluster()->conf($self->conf());

	#### LOAD STARCLUSTER
	$self->logDebug("DOING loadStarCluster()");
	$self->loadStarCluster($username, $cluster);
}

method setWorkflowTestDatabase {
	$self->logDebug("");
	
   	#### RESET DATABASE
	$self->setUpTestDatabase();
	$self->setDatabaseHandle();

    #### SET DIRS
    my $sourcedir = "$Bin/inputs";
    my $targetdir = "$Bin/outputs";
    $self->setUpDirs($sourcedir, $targetdir);    

    #### LOAD TSVFILES
	$self->loadTsvFile("aws", "$Bin/outputs/aws.tsv");
	$self->loadTsvFile("cluster", "$Bin/outputs/cluster.tsv");
	$self->loadTsvFile("clusterstatus", "$Bin/outputs/clusterstatus.tsv");
	$self->loadTsvFile("clustervars", "$Bin/outputs/clustervars.tsv");
	$self->loadTsvFile("clusterworkflow", "$Bin/outputs/clusterworkflow.tsv");
	$self->loadTsvFile("stage", "$Bin/outputs/stage.tsv");
	$self->loadTsvFile("stageparameter", "$Bin/outputs/stageparameter.tsv");
	$self->loadTsvFile("workflow", "$Bin/outputs/workflow.tsv");
}

method testGetStatus {
	diag("getStatus - cluster not started");

    #### SET USERNAME AND CLUSTER
	my $username =  $self->conf()->getKey("database", "TESTUSER");
	my $cluster = "$username-testcluster";
	my $start = 1;
	my $project =  "Project1";
	my $workflow =  "Workflow1";

	#### SET SLOTS
    $self->username($username);
    $self->cluster($cluster);
    $self->start($start);
    $self->project($project);
    $self->workflow($workflow);
	my $json = {
		username	=>	$username,
		start		=>	$start,
		project		=>	$project,
		workflow	=>	$workflow
	};
	$self->json($json);
	
    $self->logDebug("username", $username);
    $self->logDebug("start", $start);
    $self->logDebug("project", $project);
    $self->logDebug("workflow", $workflow);
	
	#### SET UP STARCLUSTER
	$self->setUpStarCluster($username, $cluster);
	
	#### TESTS
	my $status;
	my $expected;
	
	#### STARCLUSTER NOT RUNNING, WORKFLOW COMPLETED
	$status = $self->_getStatus($username, $start, $project, $workflow, $json);
	$self->logDebug("status", $status);
	$expected = $self->getExpected("getstatus-notstarted");
	$self->logDebug("expected", $expected);
	$expected = $self->copyStagesField($status, $expected, "now");
	$self->logDebug("expected", $expected);
	is_deeply($status, $expected, "getStatus    cluster not started status");


	#### CLUSTER RUNNING
	diag("getStatus - cluster running");
	
	#### OVERRIDE STARCLUSTER isRunning
	$self->starcluster()->overrideSequence("isRunning", [1]);
	
	#### OVERRIDE WORKFLOW ensureSgeRunning
	$self->overrideSequence("ensureSgeRunning", [1]);

	#### OVERRIDE WORKFLOW clusterStatus
	my $clusterstatus = $self->getExpected("getstatus-clusterstatus");
	$self->logDebug("clusterstatus", $clusterstatus);
	$self->overrideSequence("clusterStatus", [$clusterstatus]);

	#### OVERRIDE WORKFLOW queueStatus
	my $queueoutput = $self->getExpected("getstatus-queueoutput");
	$self->monitor()->overrideSequence("queueStatus", [$queueoutput]);

	#### OVERRIDE WORKFLOW getWorkflowStatus
	$self->overrideSequence("getWorkflowStatus", ["pending"]);
	
	#### OVERRIDE WORKFLOW loadStarCluster
	$self->overrideSequence("loadStarCluster", [""]);
	$self->starcluster()->overrideSequence("isRunning", [0]);

	#### SET SGEROOT IN CONF
	$self->conf()->setKey("cluster", "SGEROOT", "$Bin/outputs/opt/sge6");
	
	#### SET ENVIRONMENT VARIABLES
	my $envarcommand = "export SGE_QMASTER_PORT=56321; export SGE_EXECD_PORT=56322; export SGE_ROOT=$Bin/outputs/opt/sge6; export SGE_CELL=$username-testcluster; export USERNAME=$username;";
	`$envarcommand`;
	
	#### SET CLUSTER RUNNING
	$self->updateClusterStatus($username, $cluster, 'cluster running');

	#### GET STATUS
	$status = $self->_getStatus($username, $cluster, $project, $workflow, $json);
	$self->logDebug("status", $status);
	$expected = $self->getExpected("getstatus-started");
	$expected = $self->copyStagesField($status, $expected, "now");
	$expected->{clusterstatus}->{polled} = $status->{clusterstatus}->{polled};
	$self->logDebug("expected", $expected);
	is_deeply($status, $expected, "getStatus    cluster running status");

}


method testGetClusterWorkflow {
	diag("getClusterWorkflow");

    #### SET USERNAME AND CLUSTER
	my $username 	=  	$self->conf()->getKey("database", "TESTUSER");
	my $cluster 	= 	"$username-testcluster";
	my $project 	=  	"Project1";
	my $workflow 	=  	"Workflow1";
	my $status 		= 	"stopped";
	
	#### SET SLOTS
    $self->username($username);
    $self->cluster($cluster);
    $self->project($project);
    $self->workflow($workflow);

   	#### RESET DATABASE AND LOAD DATA
	$self->setWorkflowTestDatabase();	

	my $clusterworkflow = $self->getClusterWorkflow($username, $project, $workflow);
	$self->logDebug("clusterworkflow", $clusterworkflow);

	my $expected = {
		username	=>	$username,
		cluster		=>	$cluster,
		project		=>	$project,
		workflow	=>	$workflow,
		status		=>	$status
	};
	
	is_deeply($clusterworkflow, $expected, "retrieved clusterworkflow hash");
}

method testUpdateClusterWorkflow {
	diag("updateClusterWorkflow");

    #### SET USERNAME AND CLUSTER
	my $username 	=  	$self->conf()->getKey("database", "TESTUSER");
	my $cluster 	= 	"$username-testcluster";
	my $project 	=  	"Project1";
	my $workflow 	=  	"Workflow1";
	my $status 		= 	"running";
	
	#### SET SLOTS
    $self->username($username);
    $self->cluster($cluster);
    $self->project($project);
    $self->workflow($workflow);

   	#### RESET DATABASE
	$self->setUpTestDatabase();
	$self->setDatabaseHandle();

	#### CHECK BEFORE UPDATE
	my $clusterworkflow = $self->getClusterWorkflow($username, $project, $workflow);
	$self->logDebug("clusterworkflow", $clusterworkflow);
	is_deeply($clusterworkflow, {}, "nonexistent status before update");
	
	#### CHECK AFTER UPDATE
	my $expected = {
		username	=>	$username,
		cluster		=>	$cluster,
		project		=>	$project,
		workflow	=>	$workflow,
		status		=>	$status
	};
	$self->updateClusterWorkflow($username, $cluster, $project, $workflow, $status);
	$clusterworkflow = $self->getClusterWorkflow($username, $project, $workflow);
	$self->logDebug("clusterworkflow", $clusterworkflow);
	is_deeply($clusterworkflow, $expected, "status after 1st update");
	
	#### CHECK AFTER 2ND UPDATE
	$status = "stopped";
	$expected = {
		username	=>	$username,
		cluster		=>	$cluster,
		project		=>	$project,
		workflow	=>	$workflow,
		status		=>	$status
	};
	$self->updateClusterWorkflow($username, $cluster, $project, $workflow, $status);
	$clusterworkflow = $self->getClusterWorkflow($username, $project, $workflow);
	$self->logDebug("clusterworkflow", $clusterworkflow);
	is_deeply($clusterworkflow, $expected, "status after 2nd update");
	
}

method testUpdateWorkflowStatus {
	diag("updateWorkflowStatus");

    #### SET USERNAME AND CLUSTER
	my $username 	=  	$self->conf()->getKey("database", "TESTUSER");
	my $cluster 	= 	"$username-testcluster";
	my $project 	=  	"Project1";
	my $workflow 	=  	"Workflow1";
	my $status 		= 	"running";
	
	#### SET SLOTS
    $self->username($username);
    $self->cluster($cluster);
    $self->project($project);
    $self->workflow($workflow);

   	#### RELOAD DATABASE
	$self->setWorkflowTestDatabase("updateworkflowstatus");
	
	#### CHECK BEFORE UPDATE
	my $workflowobject		= $self->getWorkflow($username, $project, $workflow);
	$self->logDebug("workflowobject", $workflowobject);
	ok($workflowobject, "workflow retrieved");
	my $expectedworkflow = $self->getExpected("updateworkflowstatus-workflow");
	$self->logDebug("expectedworkflow", $expectedworkflow);
	is_deeply($workflowobject, $expectedworkflow, "workflow contents");
	my $workflowstatus 	= $workflowobject->{status};
	$self->logDebug("workflowstatus", $workflowstatus);
	is($workflowstatus, '', 'no workflow status');

	$workflowstatus 	=	$self->getWorkflowStatus($username, $project, $workflow);
	$self->logDebug("workflowstatus", $workflowstatus);
	is($workflowstatus, '', 'getWorkflowStatus - retrieved empty status');

	#### CHECK AFTER UPDATE
	my $expected = {
		username	=>	$username,
		cluster		=>	$cluster,
		project		=>	$project,
		workflow	=>	$workflow,
		status		=>	""
	};
	$self->updateWorkflowStatus($username, $cluster, $project, $workflow, 'pending');
	$status = $self->getWorkflowStatus($username, $project, $workflow);
	$self->logDebug("status", $status);
	is($status, "pending", "getWorkflowStatus - status pending retrieved");
	
	#### CHECK AFTER 2ND UPDATE
	$self->updateWorkflowStatus($username, $cluster, $project, $workflow, "running");
	$status = $self->getWorkflowStatus($username, $project, $workflow);
	$self->logDebug("status", $status);
	is($status, "running", "getWorkflowStatus - status running retrieved");

}

#### UTILS
method copyStagesField ($source, $target, $field) {
	return $target if not defined $source->{stagestatus} or not defined $source->{stagestatus}->{stages};
	for ( my $i = 0; $i < @{$source->{stagestatus}->{stages}}; $i++ ) {
		${$target->{stagestatus}->{stages}}[$i]->{$field} = ${$source->{stagestatus}->{stages}}[$i]->{$field};
	}
	
	#$self->logDebug("FINAL target", $target);
	#$self->SHOWLOG(1);

	return $target;	
}

method getExpected ($key) {
	$self->logDebug("key", $key);
	my $data = {

		"updateworkflowstatus-workflow" => {
			"number"		=>	"1",
			"provenance"	=>	"",
			"status"		=>	"",
			"project"		=>	"Project1",
			"name"			=>	"Workflow1",
			"description"	=>	"",
			"username"		=>	"testuser",
			"notes"			=>	""
		},
	
		"getstatus-notstarted" => {
			"queuestatus"	=> 	{
				"status"	=> 	"",
				"queue"		=>	"NO QUEUE INFORMATION AVAILABLE"
			},
			"stagestatus"	=>	{
				"workflow" 	=> "Workflow1",
				"status" 	=> "",
				"project" 	=> "Project1",
				"stages" 	=> [
					{"stagedescription"=>"","stagepid"=>"7860","number"=>"1","status"=>"completed","project"=>"Project1","submit"=>"0","workflowpid"=>"0","stagenotes"=>"","stagename"=>"","stagejobid"=>"0","completed"=>"2012-02-26 04:36:30","owner"=>"testuser","workflownumber"=>"1","cluster"=>"","stderrfile"=>"/nethome/admin/agua/Project1/Workflow1/stdout/1-FTP.stderr","location"=>"bin/utils/FTP.pl","version"=>"0.6.0","installdir"=>"/agua/bioapps","executor"=>"/usr/bin/perl","name"=>"FTP","stdoutfile"=>"/nethome/admin/agua/Project1/Workflow1/stdout/1-FTP.stdout","package"=>"bioapps","username"=>"testuser","workflow"=>"Workflow1","now"=>"2012-11-09 19:07:01","started"=>"2012-02-26 04:24:14","type"=>"utility","queued"=>"0000-00-00 00:00:00"},
					{"stagedescription"=>"","stagepid"=>"8997","number"=>"2","status"=>"completed","project"=>"Project1","submit"=>"0","workflowpid"=>"0","stagenotes"=>"","stagename"=>"","stagejobid"=>"0","completed"=>"2012-02-27 03:39:27","owner"=>"testuser","workflownumber"=>"1","cluster"=>"","stderrfile"=>"/nethome/admin/agua/Project1/Workflow1/stdout/2-unzipFiles.stderr","location"=>"bin/utils/unzipFiles.pl","version"=>"0.6.0","installdir"=>"/agua/bioapps","executor"=>"/usr/bin/perl","name"=>"unzipFiles","stdoutfile"=>"/nethome/admin/agua/Project1/Workflow1/stdout/2-unzipFiles.stdout","package"=>"bioapps","username"=>"testuser","workflow"=>"Workflow1","now"=>"2012-11-09 19:07:01","started"=>"2012-02-27 03:39:00","type"=>"utility","queued"=>"0000-00-00 00:00:00"},
					{"stagedescription"=>"","stagepid"=>"0","number"=>"3","status"=>"","project"=>"Project1","submit"=>"0","workflowpid"=>"0","stagenotes"=>"","stagename"=>"","stagejobid"=>"0","completed"=>"0000-00-00 00:00:00","owner"=>"testuser","workflownumber"=>"1","cluster"=>"","stderrfile"=>"","location"=>"bin/converters/elandIndex.pl","version"=>"0.6.0","installdir"=>"/agua/bioapps","executor"=>"/usr/bin/perl","name"=>"elandIndex","stdoutfile"=>"","package"=>"bioapps","username"=>"testuser","workflow"=>"Workflow1","now"=>"2012-11-09 19:07:01","started"=>"0000-00-00 00:00:00","type"=>"converter","queued"=>"0000-00-00 00:00:00"
					}
				]
			},
			"clusterstatus"	=>	{
				"cluster" 	=> "testuser-testcluster",
				"balancer" 	=> "",
				"status" 	=> "none",
				"log" 		=> "NO CLUSTER OUTPUT",
				"list" 		=> "NO CLUSTER OUTPUT"
			}
		},

		"getstatus-started" => {
			
			"queuestatus"=> {
				"status"	=> 	"",
				"queue"		=>	"NO QUEUE INFORMATION AVAILABLE"
			},
			"stagestatus" => {
				"workflow" 	=> "Workflow1",
				"status" 	=> "pending",
				"project"	=> "Project1",
				"stages" 	=> [
					{"stagedescription"=>"","stagepid"=>"7860","number"=>"1","status"=>"completed","project"=>"Project1","submit"=>"0","workflowpid"=>"0","stagenotes"=>"","stagename"=>"","stagejobid"=>"0","completed"=>"2012-02-26 04:36:30","owner"=>"testuser","workflownumber"=>"1","cluster"=>"","stderrfile"=>"/nethome/admin/agua/Project1/Workflow1/stdout/1-FTP.stderr","location"=>"bin/utils/FTP.pl","version"=>"0.6.0","installdir"=>"/agua/bioapps","executor"=>"/usr/bin/perl","name"=>"FTP","stdoutfile"=>"/nethome/admin/agua/Project1/Workflow1/stdout/1-FTP.stdout","package"=>"bioapps","username"=>"testuser","workflow"=>"Workflow1","now"=>"2012-11-09 19:07:01","started"=>"2012-02-26 04:24:14","type"=>"utility","queued"=>"0000-00-00 00:00:00"},
					{"stagedescription"=>"","stagepid"=>"8997","number"=>"2","status"=>"completed","project"=>"Project1","submit"=>"0","workflowpid"=>"0","stagenotes"=>"","stagename"=>"","stagejobid"=>"0","completed"=>"2012-02-27 03:39:27","owner"=>"testuser","workflownumber"=>"1","cluster"=>"","stderrfile"=>"/nethome/admin/agua/Project1/Workflow1/stdout/2-unzipFiles.stderr","location"=>"bin/utils/unzipFiles.pl","version"=>"0.6.0","installdir"=>"/agua/bioapps","executor"=>"/usr/bin/perl","name"=>"unzipFiles","stdoutfile"=>"/nethome/admin/agua/Project1/Workflow1/stdout/2-unzipFiles.stdout","package"=>"bioapps","username"=>"testuser","workflow"=>"Workflow1","now"=>"2012-11-09 19:07:01","started"=>"2012-02-27 03:39:00","type"=>"utility","queued"=>"0000-00-00 00:00:00"},
					{"stagedescription"=>"","stagepid"=>"0","number"=>"3","status"=>"","project"=>"Project1","submit"=>"0","workflowpid"=>"0","stagenotes"=>"","stagename"=>"","stagejobid"=>"0","completed"=>"0000-00-00 00:00:00","owner"=>"testuser","workflownumber"=>"1","cluster"=>"","stderrfile"=>"","location"=>"bin/converters/elandIndex.pl","version"=>"0.6.0","installdir"=>"/agua/bioapps","executor"=>"/usr/bin/perl","name"=>"elandIndex","stdoutfile"=>"","package"=>"bioapps","username"=>"testuser","workflow"=>"Workflow1","now"=>"2012-11-09 19:07:01","started"=>"0000-00-00 00:00:00","type"=>"converter","queued"=>"0000-00-00 00:00:00"}
				]
			},

			"clusterstatus"	=>	{
				"hours"			=>	undef,
				"polled"		=>	"2013-10-01 00:35:16",
				"cluster"		=>	"testuser-testcluster",
				"status"		=>	"cluster running",
				"minnodes"		=>	"0",
				"username"		=>	"testuser",
				"stopped"		=>	"0000-00-00 00:00:00",
				"termination"	=>	"0000-00-00 00:00:00",
				"pid"			=>	"0",
				"maxnodes"		=>	"1",
				"started"		=>	"0000-00-00 00:00:00"
			}
		},

		"getstatus-clusterstatus" => {
			clusterlist => qq{	StarCluster - (http://web.mit.edu/starcluster)
    Software Tools for Academics and Researchers (STAR)
    Please submit bug reports to starcluster\@mit.edu
    
    
    -----------------------------------------------
    smallcluster (security group: \@sc-testuser-testcluster)
    -----------------------------------------------
    Launch time: 2012-10-15T05:49:36.000Z
    Zone: us-east-1a
    Keypair: gsg-keypair
    Cluster nodes:
         master running i-7609f31b ec2-67-202-25-182.compute-1.amazonaws.com 
        node001 running i-7209f31f ec2-184-72-81-94.compute-1.amazonaws.com
		},
			clusterLog	=>qq{BALANCER IS RUNNING FOR CLUSTER: testuser-testcluster
SLEEPING FOR 30 seconds
COMPLETED BALANCER RUN
},
			status 	=> "cluster running",
			cluster	=> "testuser-testcluster"
		},
		
		"getstatus-queueoutput" => qq{=================================================================================
queuename                      qtype resv/used/tot. load_avg arch          states
---------------------------------------------------------------------------------
Project1-Workflow1\@master      BIP   0/1/1          1.13     lx24-amd64    
     37 0.55500 test       root         t     05/17/2011 03:43:54     1        
---------------------------------------------------------------------------------
Project1-Workflow1\@node001     BIP   0/1/1          1.29     lx24-amd64    
     38 0.55500 test       root         t     05/17/2011 03:43:54     1        
---------------------------------------------------------------------------------
all.q\@master                   BIP   0/1/1          1.13     lx24-amd64    
     35 0.55500 test       root         r     05/17/2011 03:43:54     1        
---------------------------------------------------------------------------------
all.q\@node001                  BIP   0/1/1          1.29     lx24-amd64    
     36 0.55500 test       root         r     05/17/2011 03:43:54     1        

PENDING JOBS:
test	56 jobs
}
	};

#			"clusterstatus"=> {
#				list => qq{	StarCluster - (http://web.mit.edu/starcluster)
#    Software Tools for Academics and Researchers (STAR)
#    Please submit bug reports to starcluster\@mit.edu
#    
#    
#    -----------------------------------------------
#    smallcluster (security group: \@sc-testuser-testcluster)
#    -----------------------------------------------
#    Launch time: 2012-10-15T05:49:36.000Z
#    Zone: us-east-1a
#    Keypair: gsg-keypair
#    Cluster nodes:
#         master running i-7609f31b ec2-67-202-25-182.compute-1.amazonaws.com 
#        node001 running i-7209f31f ec2-184-72-81-94.compute-1.amazonaws.com
#		},
#				log	=>	qq{BALANCER IS RUNNING FOR CLUSTER: testuser-testcluster
#SLEEPING FOR 30 seconds
#COMPLETED BALANCER RUN
#},
#				status 		=> 	"cluster running",
#				balancer 	=> 	"",
#				cluster		=> 	"testuser-testcluster",
#				hours		=>	undef

	
	return $data->{$key};
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




}   #### Test::Agua::Workflow