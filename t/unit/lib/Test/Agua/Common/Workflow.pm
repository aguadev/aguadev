use MooseX::Declare;

class Test::Agua::Common::Workflow with (Agua::Common, Test::Agua::Common) {
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
has 'fileroot'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'qstat'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'queue'			=>  ( isa => 'Str|Undef', is => 'rw', default => 'default' );
has 'cluster'		=>  ( isa => 'Str|Undef', is => 'rw' );
has 'username'  	=>  ( isa => 'Str', is => 'rw' );
has 'workflow'  	=>  ( isa => 'Str', is => 'rw' );
has 'project'   	=>  ( isa => 'Str', is => 'rw' );

# OBJECTS
has 'json'		=> ( isa => 'HashRef', is => 'rw', required => 0 );
has 'db'	=> ( isa => 'Agua::DBase::MySQL', is => 'rw', required => 0 );
has 'stages'		=> 	( isa => 'ArrayRef', is => 'rw', required => 0 );
has 'stageobjects'	=> 	( isa => 'ArrayRef', is => 'rw', required => 0 );
has 'monitor'		=> 	( isa => 'Maybe|Undef', is => 'rw', required => 0 );

has 'conf' 	=> (
	is =>	'rw',
	'isa' => 'Conf::Yaml',
	default	=>	sub { Conf::Yaml->new( backup	=>	1 );	}
);


####///}}}
method BUILD ($hash) {
	$self->initialise();
}

method initialise () {
    $self->logDebug("()");
	my $dumpfile 	= $self->dumpfile();
	$self->reloadTestDatabase($dumpfile);	
    $Test::DatabaseRow::dbh = $self->db()->dbh();	
}

method testAddWorkflow ($json) {
	diag("Test addWorkflow");

    $self->json($json);

	my $table = "workflow";
	
    not_row_ok(
        table   =>  $table,
        where   =>  [
            username    =>  "$json->{username}",
            project     =>  "$json->{project}",
            name        =>  "$json->{name}",
            number      =>  "$json->{number}",
        ],
        label   =>  "Workflow doesn't exist in table BEFORE _addWorkflow"
    );

	my $username 	= $json->{username};
	my $project 	= $json->{project};
	my $name 		= $json->{name};

	my $where = "WHERE username='$username' AND project='$project' AND name='$name'";
	my $rowcount_initial = $self->rowCount($table, $where);
    #$self->logDebug("rowcount_initial", $rowcount_initial);
        
    $self->_addWorkflow($json);

    my $rowcount_afteradd = $self->rowCount($table, $where);

    ok($rowcount_initial + 1 == $rowcount_afteradd, "One row added. Current rows: $rowcount_afteradd");

	my @rows = ();
    row_ok(
        table   =>  $table,
        where   =>  [
            username    =>  "$json->{username}",
            project     =>  "$json->{project}",
            name        =>  "$json->{name}",
            number      =>  "$json->{number}"
        ],
        label   =>  "Workflow doesn't exist in table AFTER _removeWorkflow",
        store_rows =>   \@rows
    );
	ok($#rows == 0, "unique row matches added stage");
    my $inserted = $rows[0];
	ok($inserted->{name}	eq	$json->{name}, "name field value matches");
	ok($inserted->{number}	eq	$json->{number}, "number field value matches");
	ok($inserted->{project}	eq	$json->{project}, "project field value matches");
	ok($inserted->{username}	eq	$json->{username}, "username field value matches");
	ok($inserted->{description}	eq	$json->{description}, "description field value matches");
	ok($inserted->{notes}	eq	$json->{notes}, "notes field value matches");

    $self->_removeWorkflow($json);

    my $rowcount_afterremove = $self->rowCount($table, $where);

    ok($rowcount_afterremove + 1 == $rowcount_afteradd, "One row removed. Current rows: $rowcount_afterremove");


    not_row_ok(
        table   =>  $table,
        where   =>  [
            username    =>  $json->{username},
            project     =>  $json->{project},
            name        =>  $json->{name},
            number      =>  $json->{number}
        ],
        label   =>  "Workflow doesn't exist in table AFTER _removeWorkflow"
    );    
}


}   #### Test::Agua::Common::Workflow