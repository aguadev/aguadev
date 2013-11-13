use MooseX::Declare;
use Method::Signatures::Simple;

class Test::Agua::Folders extends Agua::Folders with (Test::Agua::Common::Database,
	Test::Agua::Common::Util) {

use Data::Dumper;
use Test::More;
use Agua::DBaseFactory;
use Conf::Yaml;
use FindBin qw($Bin);

# Ints
has 'SHOWLOG'		=>  ( isa => 'Int', is => 'rw', default => 5 );  
has 'PRINTLOG'		=>  ( isa => 'Int', is => 'rw', default => 5 );
has 'validated'		=> ( isa => 'Int', is => 'rw', default => 0 );

# Strings
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
has 'conf' 	=> (
	is =>	'rw',
	isa => 'Conf::Yaml',
	default	=>	sub { Conf::Yaml->new(	memory	=>	1	);	}
);

####////}}

#method BUILD ($hash) {
#	$self->logDebug("");	
#}

#### FILE SYSTEM
method testJsonSafe {
	diag("Doing test jsonSafe");
	my $inputdir = "$Bin/inputs/fileSystem";
	my $filetests = [
		{
			file 		=>	"$inputdir/files/run3-s_1_sequence.txt",
			test		=>	"backslashes",
			expected	=>	qq{\@HWI-EAS185:1:17:17:481#0/1&nbsp;NAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA&nbsp;\\n+HWI-EAS185:1:17:17:481#0/1&nbsp;DW&#93;\\\\X\\\\XZ\\\\&#93;&#93;X\\\\\\\\_\\\\\\\\W_\\\\\\\\\\\\\\\\Y\\\\&#91;X`\\\\XYTRQ&#91;\\\\&#93;`Y^&nbsp;\\n\@HWI-EAS185:1:17}
		}
		,
		{
			file 		=>	"$inputdir/files/typescript",
			test		=>	"unicode-escape",
			expected	=>	qq{Non-ASCII characters in file}
		}
		,
		{
			file 		=>	"$inputdir/files/escape-character",
			test		=>	"escape",
			expected	=>	qq{Non-ASCII characters in file}
		}
		,
		{
			file 		=>	"$inputdir/files/\$TASKS/testfile",
			test		=>	"dollar-in-filename",
			expected	=>	qq{TEST FILE\\n}
		}
	];

	my $bytes = 200;
	foreach my $filetest ( @$filetests ) {
		my $sample = $self->sampleFile($filetest->{file}, $bytes);
		$self->logDebug("sample", $sample);
		my $expected = $filetest->{expected};
		my $testname = $filetest->{test};
		is($sample, $expected, $testname);
	}
}

#### WORKFLOWS
method testRenameWorkflow {
	diag("Doing test renameWorkflow");

	#### RESET DATABASE
	$self->setUpTestDatabase();
	$self->setDatabaseHandle();
	
	#### COPY OPSDIR AFRESH
	my $sourcedir	= "$Bin/inputs";
	my $targetdir	= "$Bin/outputs";
	$self->setUpDirs($sourcedir, $targetdir);
	
	#### LOAD WORKFLOWS
	my $projectfile			=	"$Bin/outputs/tsv/project.tsv";
	my $workflowfile		=	"$Bin/outputs/tsv/workflow.tsv";
	my $stagefile			=	"$Bin/outputs/tsv/stage.tsv";
	my $stageparameterfile	=	"$Bin/outputs/tsv/stageparameter.tsv";
	$self->loadTsvFile("project", $projectfile);
	$self->loadTsvFile("workflow", $workflowfile);
	$self->loadTsvFile("stage", $stagefile);
	$self->loadTsvFile("stageparameter", $stageparameterfile);
	
	my $username		=	"aguatest";
	my $project			=	"Project1";
	my $oldworkflow		=	"Workflow1";
	my $newworkflow		=	"downloadFiles";

	#### OVERRIDE DEFAULT CONFIG FILE KEY-VALUES
	my $userdir = "$Bin/outputs/nethome";
	$self->conf()->setKey("agua", 'USERDIR', $userdir);
	
	my $aguadir = $self->conf()->getKey("agua", 'AGUADIR');

	#### CREATE DUMMY WORKFLOW
	my $mkdir = "mkdir -p $userdir/$username/$aguadir/$project/$oldworkflow";
	$self->logDebug("mkdir", $mkdir);
	`$mkdir`;

	#### RENAME WORKFLOW
	$self->_renameWorkflow($username, $project, $oldworkflow, $newworkflow);

	#### EXPECTED FILES
	$projectfile		=	"$Bin/outputs/expected/project.tsv";
	$workflowfile		=	"$Bin/outputs/expected/workflow.tsv";
	$stagefile			=	"$Bin/outputs/expected/stage.tsv";
	$stageparameterfile	=	"$Bin/outputs/expected/stageparameter.tsv";

	#### VERIFY
	diag("Test loaded projects");
	$self->checkTsvLines("project", $projectfile, "renameWorkflow    project values");
	
	diag("Test loaded workflows");
	$self->checkTsvLines("workflow", $workflowfile, "renameWorkflow    workflow values");
	
	diag("Test loaded stages");
	$self->checkTsvLines("stage", $stagefile, "renameWorkflow    stage values");	
	
	diag("Test loaded parameters");
	$self->checkTsvLines("stageparameter", $stageparameterfile, "renameWorkflow    stage parameter values");	
}

#### UTILS
method copyDirs {
    $self->logDebug("");
	
	#### COPY OPSDIR AFRESH
	my $sourcedir	= "$Bin/inputs/private/biorepository";
	my $targetdir	= "$Bin/outputs/private/biorepository";
	$self->setUpDirs($sourcedir, $targetdir);
}

method cleanUpDirs{
#### CLEAN UP TARGET DIR
    $self->logDebug("");
	
	my $targetdir	= "$Bin/outputs/biorepository";
	`rm -fr $targetdir/*`;
}

method validate {
	return 1;
}

method getFileroot {
	my $username = $self->username();
	$self->logDebug("username", $username);
	
	my $userdir = $self->conf()->getKey('agua', 'USERDIR');
	my $aguadir = $self->conf()->getKey('agua', 'AGUADIR');
	my $fileroot = "$Bin/outputs$userdir/$username/$aguadir";
	$self->logDebug("fileroot", $fileroot);

	return $fileroot;
}

method setSession ($login, $sessionid) {
	#### SET SESSION ID
	$self->sessionid($sessionid);

	#### INSERT USERNAME AND SESSION ID INTO DATABASE
	my $query = "SELECT 1 FROM sessions where username='$login' and sessionid='$sessionid'";
	my $present = $self->db()->query($query);
	if ( not $present ) {
		$query = qq{INSERT INTO sessions VALUES ('$login', '$sessionid', NOW())};
		$self->logDebug("query", $query);
		$self->db()->do($query);
	}	
}



}   #### Test::Agua::Folders


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
