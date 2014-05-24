use MooseX::Declare;

class Test::Agua::Workflow::ExecuteWorkflow with (Test::Agua::Common::Database,
	Test::Agua::Common::Util) extends Agua::Workflow {

#### EXTERNAL MODULES
use Test::More;

#### INTERNAL MODULES
use Agua::DBaseFactory;
use Test::Agua::StarCluster;
use Test::Agua::Monitor::SGE;

has 'dumpfile'		=> ( isa => 'Str|Undef', is => 'rw' );
has 'conf'	=> ( isa => 'Conf::Yaml', is => 'rw', lazy => 1, builder => "setConf" );
has 'starcluster'	=> ( isa => 'Test::Agua::StarCluster', is => 'rw', lazy => 1, builder => "setStarCluster" );
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
        log     => 	$self->log(),
        printlog    =>  $self->printlog()
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

method testExecuteWorkflow {
    #### SET USERNAME AND CLUSTER
	diag("executeWorkflow");
	
	my $username 	=  	$self->conf()->getKey("database", "TESTUSER");
	my $sessionid	=	"0000000000.0000.000";
 	my $cluster 	=  	"$username-testcluster";
	my $project 	=  	"Project1";
	my $workflow 	=  	"Workflow1";
	my $workflownumber 	=  1;
	my $start 		=  	1;
	my $submit 		=  	1;
	
	$self->sessionid($sessionid);
	$self->username($username);
	$self->cluster($cluster);
	$self->project($project);
	$self->workflow($workflow);
	$self->workflownumber($workflownumber);
	$self->start($start);
	$self->submit($submit);

    $self->logDebug("username", $username);
    $self->logDebug("cluster", $cluster);
    $self->logDebug("project", $project);
    $self->logDebug("workflow", $workflow);
    $self->logDebug("workflownumber", $workflownumber);
    $self->logDebug("start", $start);
    $self->logDebug("submit", $submit);
	
    #### LOAD TSVFILES
	$self->loadTsvFile("sessions", "$Bin/inputs/sessions.tsv");

	#### SET UP STARCLUSTER
	$self->setUpStarCluster($username, $cluster);

	ok(1, "completed loadStarCluster()");
	
	#### OVERRIDE STARCLUSTER isRunning
	$self->starcluster()->overrideSequence("isRunning", [0, 1]);

	#### OVERRIDE WORKFLOW verifySgeRunning
	*{ensureSgeRunning} = sub {
		ok(1, "completed ensureStarClusterRunning and ensureBalancerRunning");
		shift->logDebug("OVERRIDE Agua::Workflow::ensureSgeRunning");
	};

	#### OVERRIDE WORKFLOW createQueue
	*{createQueue} = sub {
		shift->logDebug("OVERRIDE Agua::Workflow::createQueue");
	};

	#### OVERRIDE WORKFLOW runStages
	*{runStages} = sub {
		ok(1, "completed updateClusterWorkflow(..., 'running')");
		shift->logDebug("OVERRIDE Agua::Workflow::runStages");
	};

	my $statuses = [];
	*{updateClusterStatus} = sub {
		my $self	=	shift;
		shift; shift;
		my $status = shift;
		
		$self->logDebug("status", $status);
		push @$statuses, $status;
	};
	
	$self->starcluster()->username($username);
	$self->starcluster()->cluster($cluster);

	#### TEST START STARCLUSTER
	$self->logDebug("DOING executeWorkflow()");
	$self->executeWorkflow();
	
	#### TEST COMPLETED
	ok(1, "completed executeWorkflow()");

	$self->logDebug("statuses", $statuses);
	my $string = join ", ", @$statuses;
	is_deeply($statuses,  ["starting cluster","cluster running","balancer running"], "cluster status values sequence: $string");
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