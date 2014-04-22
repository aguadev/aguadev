use MooseX::Declare;

our $DEBUG;

class Test::Agua::Cluster::Jobs with (Agua::Cluster::Jobs,
	Test::Agua::Common,
	Test::Agua::Common::Database,
	Agua::Common) {

use Data::Dumper;
use Test::More;
use Test::DatabaseRow;
use Agua::DBaseFactory;
use Conf::Yaml;

# Integers
has 'showlog'		=>  ( isa => 'Int', is => 'rw', default => 2 );  
has 'printlog'		=>  ( isa => 'Int', is => 'rw', default => 2 );
has 'workflowpid'	=> ( isa => 'Int|Undef', is => 'rw', required => 0 );
has 'workflownumber'=>  ( isa => 'Str', is => 'rw' );
has 'start'     	=>  ( isa => 'Int', is => 'rw' );
has 'submit'  		=>  ( isa => 'Int', is => 'rw' );

# Strings
has 'dumpfile'	=> ( isa => 'Str|Undef', is => 'rw', required => 0 );
has 'fileroot'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'qstat'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'dumpfile'	=> ( isa => 'Str|Undef', is => 'rw', required => 1 );
has 'queue'		=>  ( isa => 'Str|Undef', is => 'rw', default => 'default' );
has 'cluster'	=>  ( isa => 'Str|Undef', is => 'rw' );
has 'username'  =>  ( isa => 'Str', is => 'rw' );
has 'workflow'  =>  ( isa => 'Str', is => 'rw' );
has 'project'   =>  ( isa => 'Str', is => 'rw' );

# OBJECTS
has 'json'		=> ( isa => 'HashRef', is => 'rw', required => 0 );
has 'stages'	=> 	( isa => 'ArrayRef', is => 'rw', required => 0 );
has 'stageobjects'	=> 	( isa => 'ArrayRef', is => 'rw', required => 0 );
has 'monitor'	=> 	( isa => 'Maybe|Undef', is => 'rw', required => 0 );

has 'conf' 		=> (
	is 			=>	'rw',
	isa 		=> 'Conf::Yaml',
	required	=> 1
);

#has 'db'	=> ( isa => 'Agua::DBase::MySQL', is => 'rw', required => 0 );
has 'db' 	=> (
	isa => 'Agua::DBase::MySQL',
	is => 'rw', 
	lazy	=> 1,
	builder => "initialiseDbh"
);

#####///}}}

method BUILD ($hash) {    
	$self->initialise();
}

method initialise () {
	#### START LOGFILE
	my $username 	=	$self->username() || $self->json()->{username};
	my $identifier 	= 	"jobs";
	my $mode 		=	"test";
	my $logfile = 	$self->setUserLogfile($username, $identifier, $mode);

	#### RELOAD DATABASE	
	$self->logDebug("Doing reloadTestDatabase");
	my $dumpfile 	= $self->dumpfile();
	$self->logDebug("dumpfile", $dumpfile);
	$self->reloadTestDatabase($dumpfile);
	
    $Test::DatabaseRow::dbh = $self->db()->dbh();	
}

method initialiseDbh () {
	my $database = $self->conf()->getKey('database', 'TESTDATABASE');	
	my $user = $self->conf()->getKey('database', 'TESTUSER');	
	my $password = $self->conf()->getKey('database', 'TESTPASSWORD');	
	
	return $self->setDbh({
		database	=>	$database,
		user		=>	$user,
		password	=>	$password
	})
}


method openLogfile ($logfile) {
    $logfile = $self->incrementFile($logfile);
	open (STDOUT, "| tee -ai $logfile") or die "Can't split STDOUT to logfile: $logfile\n";
	return $logfile;	
}

method testCreateTaskDirs () {
	diag("Test createTaskDirs");
	
	#### GET TEST DATA
	my $index = $self->getIndex();
	$self->logDebug("index", $index);
	my $inputdir = "$Bin/$index";
	$self->logDebug("inputdir", $inputdir);
	
	#### RUN TEST
	my $outputdirs = $self->createTaskDirs($inputdir, 1);
	ok(scalar(@$outputdirs) > 0, "outputdir returned from createTaskDirs");
	my $outputdir = $$outputdirs[0];
	$self->logDebug("outputdir", $outputdir);
	ok( defined $outputdir, "outputdir is defined");        
	ok( $outputdir, "outputdir is not empty");
	ok( $outputdir eq "$Bin/1", "Expected and actual outputdir match");	
}

method incrementFile ($logfile) {
	$logfile .= ".1";	
	if ( -f $logfile )
	{
		my ($stub, $index) = $logfile =~ /^(.+?)\.(\d+)$/;
		$index++;
		$logfile = $stub . "." . $index;
	}

    return $logfile;    
}

method testSetMonitor {
$self->logDebug("");
	my $clustertype =  $self->conf()->getKey('agua', 'CLUSTERTYPE');
	my $classfile = "Agua/Monitor/" . uc($clustertype) . ".pm";
	my $module = "Agua::Monitor::$clustertype";
	require $classfile;

	my $monitor = $module->new(
		{
			pid			=>	$$,
			conf 		=>	$self->conf(),
			db	=>	$self->db(),
			username	=>	$self->username(),
			cluster		=>	$self->cluster()
		}
	);

    isa_ok($monitor, "Agua::Monitor::$clustertype", "monitor");
    isa_ok($monitor->db(), 'Agua::DBase::MySQL', "monitor->db");
    isa_ok($monitor->conf(), 'Conf::Yaml', "monitor->conf");
    ok($monitor->conf() == $self->conf(), "monitor->conf and self->conf are identical");
    ok($monitor->db() == $self->db(), "monitor->db and self->db are identical");
    
	return $monitor;
}





}   #### Test::Agua::Cluster::Jobs