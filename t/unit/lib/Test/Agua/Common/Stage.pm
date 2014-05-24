use MooseX::Declare;

class Test::Agua::Common::Stage with (Test::Agua::Common,
	Test::Common,
	Test::Agua::Common::Util,
	Agua::Common::Base,
	Agua::Common::Database,
	Agua::Common::Logger,
	Agua::Common::Privileges,
	Agua::Common::Stage) {

use Data::Dumper;
use Test::More;
use Test::DatabaseRow;
use Agua::DBaseFactory;

our $DEBUG = 0;
#$DEBUG = 1;

# Ints
has 'workflowpid'	=> ( isa => 'Int|Undef', is => 'rw', required => 0 );
has 'workflownumber'=>  ( isa => 'Str', is => 'rw' );
has 'start'     	=>  ( isa => 'Int', is => 'rw' );
has 'submit'  		=>  ( isa => 'Int', is => 'rw' );
has 'log'		=>  ( isa => 'Int', is => 'rw', default => 2 );  
has 'printlog'		=>  ( isa => 'Int', is => 'rw', default => 5 );

# Strings
has 'dumpfile'		=> ( isa => 'Str|Undef', is => 'rw', required => 1 );
has 'database'		=> ( isa => 'Str|Undef', is => 'rw', required => 1 );
has 'user'			=> ( isa => 'Str|Undef', is => 'rw', required => 1 );
has 'password'		=> ( isa => 'Str|Undef', is => 'rw', required => 1 );

has 'fileroot'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'qstat'			=> ( isa => 'Str|Undef', is => 'rw', default => '' );

has 'queue'			=>  ( isa => 'Str|Undef', is => 'rw', default => 'default' );
has 'cluster'		=>  ( isa => 'Str|Undef', is => 'rw' );
has 'username'  	=>  ( isa => 'Str', is => 'rw' );
has 'workflow'  	=>  ( isa => 'Str', is => 'rw' );
has 'project'   	=>  ( isa => 'Str', is => 'rw' );

# Objects
has 'json'			=> ( isa => 'HashRef', is => 'rw', required => 0 );
has 'db'		=> ( isa => 'Agua::DBase::MySQL', is => 'rw', required => 0 );
has 'stages'		=> 	( isa => 'ArrayRef', is => 'rw', required => 0 );
has 'stageobjects'	=> 	( isa => 'ArrayRef', is => 'rw', required => 0 );
has 'monitor'		=> 	( isa => 'Maybe|Undef', is => 'rw', required => 0 );

has 'conf' 	=> (
	is =>	'rw',
	'isa' => 'Conf::Yaml',
	default	=>	sub { Conf::Yaml->new( backup	=>	1 );	}
);


####///}}

method BUILD ($hash) {
	$self->initialise($hash);
}

method testAddRemoveStage ($json) {
    diag("Test addRemoveStage");

	#### RELOAD DATABASE
	my $dumpfile 	= $self->dumpfile();
	$self->reloadTestDatabase($dumpfile);	
    $Test::DatabaseRow::dbh = $self->db()->dbh();	

    #### TABLE
    my $table       =   "stage";
    my $addmethod       =   "_addStage";
    my $removemethod    =   "_removeStage";
    my $requiredkeys    =   [
        'username',
		'project',
		'workflow',
		'name',
		'number',
		'workflownumber'
    ];
    my $definedkeys =   [
		'name',
		'owner',
		'type',
		'executor',
		'location',
		'number',
		'project',
		'workflow',
		'username',
		'workflownumber'
    ];

    my $undefinedkeys =   [
		'localonly',
		'notes',
		'description'
    ];

    $self->logDebug("Doing genericAddRemove(..)");
    $self->genericAddRemove(
        {
            json	        =>	$json,
            table	        =>	$table,
            addmethod	    =>	$addmethod,
            addmethodargs	=>	$json,
            removemethod	=>	$removemethod,
            removemethodargs=>	$json,
            requiredkeys	=>	$requiredkeys,
            definedkeys	    =>	$definedkeys,
            undefinedkeys	=>	$undefinedkeys
        }        
    );
    
}   #### testAddRemoveStage

method testInsertStage {

	diag("parseEmbossEntry");
	my $tests = [
		#{
		#	name	=>	"matcher",
		#	file	=>	"$Bin/inputs/insertstage/matcher.json";
		#	expected=>	"$Bin/inputs/insertstage/matcher.expected"
		#}
		#,
		{
			name	=>	"drfinddata",
			file	=>	"$Bin/inputs/insertstage/drfinddata.json",
			expected=>	"$Bin/inputs/insertstage/drfinddata.expected"
		}
	];

	foreach my $test ( @$tests ) {
		my $testname	=	$test->{name};
		my $inputfile 	= 	$test->{file};
		my $json 	=	$self->getFileContents($inputfile);
		$self->logDebug("json", $json);

		#### CLEAR OBJECT
		$self->clear();
		
		#### INITIALISE OBJECT
		my $data	=	$self->jsonToObject($json);
		$self->logDebug("data", $data);
		$self->initialise($data);
		
		#### RELOAD DATABASE
		my $dumpfile	=	"inputs/insertstage/agua.dump";
		$self->reloadTestDatabase($dumpfile);	
		
		#### INSERT STAGE
		my $success = $self->_insertStage($data);
		$self->logDebug("success", $success);
		ok($success, "_insertStage")
	}
}



}   #### Test::Agua::Common::Stage