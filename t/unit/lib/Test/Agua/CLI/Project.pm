use MooseX::Declare;
use Method::Signatures::Simple;

class Test::Agua::CLI::Project with (Test::Agua::Common::Database,
	Test::Common,
	Agua::Common::Database,
	Agua::Common::Base,
	Agua::Common::Package,
	Agua::Common::Util) extends Agua::CLI::Project {

use Data::Dumper;
use Test::More;
use Test::DatabaseRow;
use Agua::DBaseFactory;
use Agua::Ops;
use Agua::Instance;
use Conf::Yaml;
use FindBin qw($Bin);

# Ints
has 'showlog'		=>  ( isa => 'Int', is => 'rw', default => 2 );  
has 'printlog'		=>  ( isa => 'Int', is => 'rw', default => 5 );
has 'validated'		=> ( isa => 'Int', is => 'rw', default => 0 );

# Strings
has 'requestor'     => ( isa => 'Str|Undef', is => 'rw' );
has 'logfile'       => ( isa => 'Str|Undef', is => 'rw' );
has 'owner'	        => ( isa => 'Str|Undef', is => 'rw' );
has 'package'		=> ( isa => 'Str|Undef', is => 'rw' );
has 'remoterepo'	=> ( isa => 'Str|Undef', is => 'rw' );
has 'sourcedir'		=> ( isa => 'Str|Undef', is => 'rw' );
has 'installdir'	=> ( isa => 'Str|Undef', is => 'rw' );
has 'dumpfile'		=> ( isa => 'Str|Undef', is => 'rw' );
has 'database'		=> ( isa => 'Str|Undef', is => 'rw' );
has 'rootpassword'  => ( isa => 'Str|Undef', is => 'rw' );
has 'dbuser'        => ( isa => 'Str|Undef', is => 'rw' );
has 'dbpass'        => ( isa => 'Str|Undef', is => 'rw' );
#has 'sessionid'     => ( isa => 'Str|Undef', is => 'rw' );

# Objects
has 'json'			=> ( isa => 'HashRef', is => 'rw', required => 0 );
has 'head' 	=> (
	is =>	'rw',
	'isa' => 'Agua::Instance',
	default	=>	sub { Agua::Instance->new();	}
);
has 'master' 	=> (
	is =>	'rw',
	'isa' => 'Agua::Instance',
	default	=>	sub { Agua::Instance->new();	}
);

has 'ops' 	=> (
	is 		=>	'rw',
	isa 	=>	'Agua::Ops',
	default	=>	sub { Agua::Ops->new();	}
);

has 'conf' 	=> (
	is =>	'rw',
	isa => 'Conf::Yaml',
	default	=>	sub { Conf::Yaml->new(	memory	=>	1	);	}
);

has 'jsonparser'	=> ( isa => 'JSON', is => 'rw', lazy => 1, builder => "setJsonParser" );

####////}}

method BUILD ($hash) {
	$self->logDebug("");
	
	if ( defined $self->logfile() ) {
		$self->head()->ops()->logfile($self->logfile());
		$self->head()->ops()->showlog($self->showlog());
		$self->head()->ops()->printlog($self->printlog());
	}
}

#### DEFAULT PACKAGES
method setOpsDir ($username, $repository, $type, $package) {
#### example: /agua/0.6/repos/public/biorepository/syoung/bioapps
	$self->logNote("username", $username);
	$self->logNote("repository", $repository);
	$self->logNote("type", $type);
	$self->logNote("package", $package);

	#### ADDED FOR TESTING
	return $self->opsdir() if defined $self->opsdir();
	
	$self->logError("type is not public or private") and exit if $type !~ /^(public|private)$/;
	my $installdir = $self->conf()->getKey("agua", "INSTALLDIR");
	my $opsdir = "$installdir/repos/$type/$repository/$username/$package";
	File::Path::mkpath($opsdir);
	$self->logError("can't create opsdir: $opsdir") if not -d $opsdir;
	
	return $opsdir;
}

method setInstallDir ($username, $owner, $package, $type) {
#### RETURN LOCATION OF APPLICATION FILES - OVERRIDEN FOR TESTING
	$self->logNote("username", $username);
	$self->logNote("owner", $owner);
	$self->logNote("package", $package);
	$self->logNote("type", $type);

	return $self->installdir() if defined $self->installdir();
	
	my $userdir = $self->conf()->getKey("agua", "USERDIR");

	return "$userdir/$username/.repos/$type/$package/$owner";
}

#### WORKFLOWS
method testGetWorkflowFiles {
	require Agua::CLI::Project;
	my $projectobject = Agua::CLI::Project->new();

	#### LOAD DATABASE
	$self->setUpTestDatabase();

	#### SET USERNAME
	my $username = $self->conf()->getKey("database", "TESTUSER");
	$self->username($username);
	$self->logDebug("username", $username);

	#### SET WORKFLOW DIR
	my $type 		= 	"public";
	my $opsdir		= 	"$Bin/inputs/repos/$type/biorepository";
	my $workflowdir	= 	$self->setResourceDir($opsdir, $username, "workflows");
	$self->logDebug("workflowdir", $workflowdir);
	
	my $expectedfiles = [
		[
			'1-Workflow1.work',
			'2-Workflow2.work'
		],
		[
			'1-Workflow1.work'
		]
	];

	my $projectdir = "$workflowdir/projects";
	$self->logDebug("projectdir", $projectdir);
	
	my $projects = $self->getDirs($projectdir);
	$self->logDebug("projects", $projects);
	
	for ( my $i = 0; $i < @$projects; $i++ ) {
		my $project = $$projects[$i];
		my $subdir = "$workflowdir/projects/$project";
		$self->logDebug("subdir", $subdir);
	
		my $workflowfiles = $self->getWorkflowFiles($subdir);
		$self->logDebug("project '$project' workflowfiles: @$workflowfiles");

		for ( my $j = 0; $j < @$workflowfiles; $j++ ) {
			ok($$workflowfiles[$j] eq $$expectedfiles[$i][$j], "got workflow file [$i][$j]: $$expectedfiles[$i][$j]");
		}
	}
}

method testSortWorkflowFiles () {
	diag("Test sortWorkflowFiles");

	require Agua::CLI::Project;
	my $projectobject = Agua::CLI::Project->new();

	my $workflows = [
		'1-Workflow1',
		'11-Workflow11',
		'2-Workflow2',
		'22-Workflow22',
		'3-Workflow3'
	];

	my $expected = [
		'1-Workflow1',
		'2-Workflow2',
		'3-Workflow3',
		'11-Workflow11',
		'22-Workflow22'
	];

	$workflows = $projectobject->sortWorkflowFiles($workflows);
	$self->logDebug("workflows", $workflows);

#	ok ($self->identicalArray($workflows, $expected), "sortWorkflowFiles    correct sorted order");	
	is_deeply($workflows, $expected, "sortWorkflowFiles    correct sorted order");	
}

method testSave {
	#### SET DBH
	$self->setTestDbh();
	$self->db()->do("DELETE FROM project");
	
	my $projectfile	=	"$Bin/inputs/workflows/projects/PanCancer/PanCancer.proj";
	$self->inputfile($projectfile);

	#### SET USERNAME AND OWNER
	my $username	=	"testuser";
	$self->username($username);
	$self->owner($username);

	#### SAVE
	$self->save();

	#### GET ACTUAL
	my $name	=	$self->name();
	$self->logDebug("name", $name);
	my $entry	=	$self->db()->queryhash("SELECT * FROM project WHERE name='$name'");
	$self->logDebug("self->db->database", $self->db()->database());
	$self->logDebug("entry", $entry);
	
	#### GET EXPECTED
	my $json	=	$self->getFileContents($projectfile);
	$self->logDebug("json", $json);
	my $data	=	$self->jsonparser()->decode($json);
	$self->logDebug("data", $data);
	
	#### VERIFY
	foreach my $field ( keys %$data ) {
		next if $field eq "workflows";
		$self->logDebug("field $field: expected $data->{$field}, actual: $entry->{$field}");
		ok($data->{$field} eq $entry->{$field}, "loaded field $field");
	}
}

method testSaveWorkflow {
	#### SET DBH
	$self->setTestDbh();
	$self->db()->do("DELETE FROM workflow");

	#### INPUTS
	my $directory	=	"$Bin/outputs/workflows/projects/PanCancer";
	#my $workflows	=	["1-Download.work", "2-Split.work", "3-Align.work"];
	my $workflows	=	["1-Download.work"];
	my $project		=	"PanCancer";
	my $projectfile	=	"$directory/$project.proj";

	#### COPY FILES
	$self->setUpDirs("$Bin/inputs/workflows/projects/PanCancer", "$Bin/outputs/workflows/projects/PanCancer");
	$self->setUpFile("$Bin/inputs/workflows/projects/PanCancer/$project.proj", "$Bin/outputs/workflows/projects/PanCancer/$project.proj");
	
	#### SET INPUTFILE
	$self->inputfile($projectfile);

	#### SET USERNAME, OWNER AND PROJECT
	my $username	=	"testuser";
	$self->username($username);
	$self->owner($username);
	$self->name($project);

	foreach my $workflow (  @$workflows ) {
		my ($workflownumber, $workflowname)	= $workflow =~/^(\d+)-(.+).(wrk|wk|work)$/;
		$self->logDebug("workflowname", $workflowname);
		$self->logDebug("workflownumber", $workflownumber);

		#### SET WORKFILE
		my $wkfile	=	$self->wkfile("$directory/$workflow");
		$self->logDebug("wkfile", $wkfile);
		$self->logDebug("self->wkfile", $self->wkfile());

		#### SAVE WORKFLOW
		$self->saveWorkflow();
		
		#### VERIFY ENTRIES IN TABLES
		my $query	=	qq{SELECT * FROM workflow
WHERE username='$username'
AND project='$project'
AND name='$workflowname'
AND number='$workflownumber'};
		$self->logDebug("query", $query);
		my $workflowdata	=	$self->db()->queryhash($query);
		$self->logDebug("workflowdata", $workflowdata);
		
		#### GET EXPECTED
		my $json	=	$self->getFileContents($wkfile);
		#$self->logDebug("json", $json);
		my $data	=	$self->jsonparser()->decode($json);
		$self->logDebug("data", $data);
		
		### VERIFY
		foreach my $field ( keys %$workflowdata ) {
			ok($data->{$field} eq $workflowdata->{$field}, "loaded field $field");
		}
	}
}

method setJsonParser {
	my $jsonparser	=	JSON->new->allow_nonref;
	$self->jsonparser($jsonparser);
	
	return $jsonparser;
}


}   #### Test::Agua::CLI::Project


=head2

method insertTestData ($table, $data) {
	#### SET OWNER
	$self->owner($self->username());
	my $owner = $self->owner();
	$self->logDebug("owner", $owner);

    my $hash = {
        username    =>  $self->username(),
        owner       =>  $self->owner(),
        package 	=>  $self->package(),
        opsdir      =>  $self->opsdir(),
        installdir  =>  $self->installdir(),
        version     =>  "0.3"
    };

	my $table = "package";
    my $fields = $self->db()->fields($table);
    $self->logDebug("fields: @$fields");
    my $insert = '';
    for ( my $i = 0; $i < @$fields; $i++ )
    {
        next if $$fields[$i] eq "datetime";
        my $value = $hash->{$$fields[$i]} ? $hash->{$$fields[$i]} : '';
        $insert .= "'$value',";
    }
    $insert =~ s/,$//;
    $insert .= ", NOW()";
    my $query = qq{INSERT INTO $table VALUES ($insert)};
    $self->logDebug("query", $query);
	
	#### TEST QUERY
    ok($self->db()->do($query), "inserted testversion row into $table");

	#### TEST INSERTED FIELD VALUES
    row_ok(
        table   =>  $table,
        where   =>  [ %$hash ],
        label   =>  "testversion row values"
    );
}

method setUpTestDatabase {
    #### LOAD DATABASE FROM SCRATCH
	$self->logDebug("Doing prepareTestDatabase()");
    $self->prepareTestDatabase();

	$self->logDebug("Doing loadDatabase()");
    $self->loadDatabase();
}

method prepareTestDatabase {
    my $database = $self->database();
    my $user = $self->user();
    my $password = $self->password();
	$self->logDebug("database", $database);
	$self->logDebug("user", $user);
	$self->logNote("password not defined or empty") if not defined $password or not $password;

    $self->setDbh({
		database	=>	$database,
		user  		=>  $user,
		password    =>  $password
	});

    #### SET VARIABLES
    my $dbuser = $self->dbuser();
    my $dbpass = $self->dbpass();
    my $privileges = "ALL";
    my $host = "localhost";

    #### DROP DATABASE
	$self->logDebug("Doing dropDatabase()");
    $self->db()->dropDatabase($database) if defined $self->db()->dbh();

    #### CREATE DATABASE
	$self->logDebug("Doing createDatabase()");
    $self->db()->createDatabase($database);
}


method loadDatabase {
#### LOAD DATA INTO DATABASE
    my $dumpfile    = $self->dumpfile();
    $self->logDebug("dumpfile", $dumpfile);
    $self->reloadTestDatabase($dumpfile);
    $self->logDebug("Finished loadDatabase");
}

method setDatabaseHandle {
    #### SET DBH FOR TEST USER
    my $database = $self->database();
    my $user = $self->conf()->getKey("database", "TESTUSER");
    my $pass = $self->conf()->getKey("database", "TESTPASSWORD");
    $self->setDbh({
        database    =>  $database,
        user        =>  $user,
        password    =>  $pass
    });
}

method setTestDatabaseRow {
	$self->logDebug("");
    $Test::DatabaseRow::dbh = $self->db()->dbh();
}



=cut
