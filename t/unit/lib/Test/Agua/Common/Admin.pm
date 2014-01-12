use MooseX::Declare;

class Test::Agua::Common::Admin extends Agua::Admin with Test::Agua::Common {

use Data::Dumper;
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
}

method initialise () {
    $self->logDebug("");

	#### SET SESSION ID FOR HTML TESTS
	my $query = qq{insert into sessions values ('testuser', '1234567890.1234.123', NOW())};
	$self->logDebug("$query");
	$self->db()->do($query);

    $self->logDebug("AFTER reloadTestDatabase, self", $self);
}

method testAddRemoveAccess ($json) {
	diag("Test addRemoveAccess");

	my $dumpfile 	= $self->dumpfile();
	$self->reloadTestDatabase($dumpfile);
    $Test::DatabaseRow::dbh = $self->db()->dbh();	

	#### SET DBH	
	$self->logDebug("DOING setDbh");
	$self->setDbh();
	$self->logDebug("self", $self);

    #### INPUTS
    my $table       	=   "access";
    my $addmethod       =   "_addAccess";
    my $removemethod    =   "_removeAccess";
    my $requiredkeys    =   [
        'owner',
        'groupname'
	];
    my $definedkeys =   [
        'owner',
        'groupname',
        'groupwrite',
        'groupcopy',
        'groupview',
        'worldwrite',
        'worldcopy',
        'worldview'
    ];
    my $undefinedkeys =   [];
    
    $self->logDebug("Doing genericAddRemove(...)");
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
}



method testAddRemoveGroup ($json) {
	diag("Test addRemoveGroup");
	
	$self->json($json);
	
    #### INPUTS
    my $table       	=   "groups";
    my $addmethod       =   "_addGroup";
    my $removemethod    =   "_removeGroup";
    my $requiredkeys    =   [
        'username',
        'groupname'
	];
    my $definedkeys =   [
        'username',
        'groupname',
        'description',
        'notes'
    ];
    my $undefinedkeys =   [];
    
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
}


}   #### Test::Agua::Common::Admin