use MooseX::Declare;

class Test::Agua::Common::Cluster with (Test::Agua::Common, Agua::Common) {

use Test::More;
use Test::DatabaseRow;
use Agua::DBaseFactory;

# INTS
has 'workflowpid'	=> ( isa => 'Int|Undef', is => 'rw', required => 0 );
has 'workflownumber'=>  ( isa => 'Str', is => 'rw' );
has 'start'     	=>  ( isa => 'Int', is => 'rw' );
has 'submit'  		=>  ( isa => 'Int', is => 'rw' );

# STRINGS
has 'dumpfile'		=>  ( isa => 'Str|Undef', is => 'rw' );
has 'database'		=>  ( isa => 'Str|Undef', is => 'rw' );
has 'fileroot'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'qstat'			=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'queue'			=>  ( isa => 'Str|Undef', is => 'rw', default => 'default' );
has 'cluster'		=>  ( isa => 'Str|Undef', is => 'rw' );
has 'username'  	=>  ( isa => 'Str', is => 'rw' );
has 'workflow'  	=>  ( isa => 'Str', is => 'rw' );
has 'project'   	=>  ( isa => 'Str', is => 'rw' );

# OBJECTS
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

####////}}

method BUILD ($hash) {
	$self->initialise();
}

method initialise () {
	my $dumpfile 	= $self->dumpfile();
	$self->reloadTestDatabase($dumpfile);	
    $Test::DatabaseRow::dbh = $self->db()->dbh();
}

method testAddRemoveCluster ($json) {
	diag("Test addRemoveCluster");

	
    #### INPUTS
    my $table       	=   "cluster";
    my $addmethod       =   "_addCluster";
    my $removemethod    =   "_removeCluster";
    my $requiredkeys    =   [
        'username',
        'availzone',
        'cluster',
        'minnodes',
        'maxnodes',
        'instancetype',
        'amiid'
    ];
    my $definedkeys =   [
        'username',
        'availzone',
        'cluster',
        'minnodes',
        'maxnodes',
        'instancetype',
        'amiid',
        'description'
    ];
    my $undefinedkeys =   [];
    
    $self->logDebug("Doing genericAddRemove(..)");
    $self->genericAddRemove(
        {
            json	        =>	$json,
            table	        =>	$table,
            addmethod	    =>	$addmethod,
            removemethod	=>	$removemethod,
            requiredkeys	=>	$requiredkeys,
            definedkeys	    =>	$definedkeys,
            undefinedkeys	=>	$undefinedkeys
        }        
    );
}


}   #### Test::Agua::Common::Cluster