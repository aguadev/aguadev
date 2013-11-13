use MooseX::Declare;

class Test::Agua::Common::Jobs with (Test::Agua::Common::Util, Agua::Common::Database,  Agua::Cluster::Jobs, Agua::Common::Base, Agua::Common::Util) {
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
has 'fileroot'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'qstat'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );

# STRINGS
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

method BUILD ($hash) {
    $self->setDbh();
    $Test::DatabaseRow::dbh = $self->db()->dbh();
}


method testSetMonitor {
my $DEBUG = 1;
	my $clustertype =  $self->conf()->getKey('agua', 'CLUSTERTYPE');
	my $classfile = "Agua/Monitor/" . uc($clustertype) . ".pm";
	my $module = "Agua::Monitor::$clustertype";
	$self->logDebug("Doing require $classfile");
	require $classfile;

	my $monitor = $module->new(
		{
			'pid'		=>	$$,
			'conf' 		=>	$self->conf(),
			'db'	=>	$self->db()
		}
	);

	return $monitor;
}





}   #### Test::Agua::Common::Jobs