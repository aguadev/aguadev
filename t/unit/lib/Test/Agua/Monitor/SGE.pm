use MooseX::Declare;

#### NB: EXTEND Agua::Monitor::SGE IN ORDER TO PROVIDE DUMMY FUNCTIONS

class Test::Agua::Monitor::SGE extends Agua::Monitor::SGE with (Test::Agua::Common, Agua::Common) {
#with (Test::Agua::Common::Util, Agua::Common::Database,  Agua::Common::Cluster, Agua::Common::Base, Agua::Common::Util) {

use Data::Dumper;
use Test::More;
use Test::DatabaseRow;
use Agua::DBaseFactory;
use Conf::Yaml;

our $DEBUG = 0;
#$DEBUG = 1;

# INTS
has 'workflowpid'	=> ( isa => 'Int|Undef', is => 'rw', required => 0 );
has 'workflownumber'=>  ( isa => 'Str', is => 'rw' );
has 'start'     	=>  ( isa => 'Int', is => 'rw' );
has 'submit'  		=>  ( isa => 'Int', is => 'rw' );

# STRINGS
has 'dumpfile'	=> ( isa => 'Str|Undef', is => 'rw', required => 0 );

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

####///}}}

method BUILD ($hash) {
}

method initialise () {
    
	#### SET LOG FILE
	my $logfile = $self->logfile();
	$self->logDebug("logfile", $logfile);
	$self->conf()->logfile($logfile);

	#### RELOAD DATABASE
	my $dumpfile 	= $self->dumpfile();
	$self->logDebug("dumpfile", $dumpfile);
	return if not defined $dumpfile;
	
	$self->reloadTestDatabase($dumpfile);
    $Test::DatabaseRow::dbh = $self->db()->dbh();
}

method testSetMonitor {
	diag("Test setMonitor");
	
	my $clustertype =  $self->conf()->getKey('agua', 'CLUSTERTYPE');
	my $classfile = "Agua/Monitor/" . uc($clustertype) . ".pm";
	my $module = "Agua::Monitor::$clustertype";
	$self->logInfo("Doing require $classfile");
	require $classfile;

	my $monitor = $module->new(
		{
			pid		=>	$$,
			conf 		=>	$self->conf(),
			db	=>	$self->db(),
			username	=>	$self->username(),
			cluster		=>	$self->cluster()
		}
	);

	return $monitor;
}

method testRemainingJobs {
	diag("Test remainingJobs");
	
	#### CHECK SMART MATCH OPERATOR '~~'
	#### (WORKS ONLY IN PERL 5.10+)
	use 5.010;
	ok(1, "testRemainingJobs    We have Perl 5.10 or greater");

	my $job_ids = ['122.1-1:1'];
	my $remaining_jobs = $self->remainingJobs($job_ids);
	my $statushash = $self->statusHash();
	my $expected = {
	  '170' => 'queued',
	  '136' => 'error',
	  '169' => 'running',
	  '122' => 'running',
	  '135' => 'error'
	};
	ok($statushash ~~ $expected, "testRemainingJobs    statushash is as expected");
}

method testJobLines {
#my $DEBUG = 1;
	$self->logDebug("()");

	#### TRY REPEATEDLY TO GET A CLEAN QSTAT REPORT
	my $sleep		=	$self->sleep();	
	my $tries		=	$self->tries();	

	#### 
	#### GET ERROR MESSAGES ALSO
	my $sgebin = $self->sgeBinCommand("head");
	my $command = "$sgebin/qstat 2>&1 |";
	$self->logDebug("command", $command);

	#### REPEATEDLY TRY SYSTEM CALL UNTIL A NON-ERROR RESPONSE IS RECEIVED
	my $error_regex = $self->errorregex();

	#my $result = $self->repeatTries($command, $sleep, $tries);
	#$self->logDebug("repeatTries result", $result);

	my $result = $self->qstat($command);
	
	my @lines = split "\n", $result;
	my $jobs_list = [];
	foreach my $line ( @lines )
	{
		use re 'eval';# EVALUATE AS REGEX
		my $jobid_regex = $self->jobidregex();
		push @$jobs_list, $line if $line =~ /$jobid_regex/;
		no re 'eval';# EVALUATE AS REGEX
	}
	
	return \@lines;
}

method jobLines {
	#### TEST DATA
	my $qstat_output = qq{ job-ID  prior   name       user         state submit/start at     queue                          slots ja-task-ID 
-----------------------------------------------------------------------------------------------------------------
122 0.50000 tophatBatc www-data     r     04/12/2011 21:20:00 default\@hp                         3 1
135 0.50000 tophatBatc www-data     Eqw   04/13/2011 00:39:46                                    3 1
136 0.50000 tophatBatc www-data     Eqw   04/13/2011 01:14:03                                    3 1
169 0.50000 tophatBatc www-data     r     04/13/2011 16:34:31 default\@hp                         3 1
170 0.00000 tophatBatc root         qw    04/13/2011 17:00:25                                    3 1      
};
	my @array = split "\n", $qstat_output;

	return \@array;
}


method qstat {
	return qq{job-ID  prior   name       user         state submit/start at     queue                          slots ja-task-ID 
-----------------------------------------------------------------------------------------------------------------
     95 0.00000 test       root         qw    05/17/2011 05:33:18                                    1        
     96 0.00000 test       root         qw    05/17/2011 05:33:18                                    1        
     97 0.00000 test       root         qw    05/17/2011 05:33:18                                    1        
     98 0.00000 test       root         qw    05/17/2011 05:33:18                                    1        
     99 0.00000 test       root         qw    05/17/2011 05:33:18                                    1        
    100 0.00000 test       root         qw    05/17/2011 05:33:18                                    1        
    101 0.00000 test       root         qw    05/17/2011 05:33:18                                    1        
    102 0.00000 test       root         qw    05/17/2011 05:33:18                                    1        
    103 0.00000 test       root         qw    05/17/2011 05:33:18                                    1        
    104 0.00000 test       root         qw    05/17/2011 05:33:18                                    1        
    105 0.00000 test       root         qw    05/17/2011 05:33:18                                    1        
    106 0.00000 test       root         qw    05/17/2011 05:33:18                                    1        
    107 0.00000 test       root         qw    05/17/2011 05:33:18                                    1        
    108 0.00000 test       root         qw    05/17/2011 05:33:18                                    1        
    109 0.00000 test       root         qw    05/17/2011 05:33:19                                    1        
    110 0.00000 test       root         qw    05/17/2011 05:33:19                                    1        
    111 0.00000 test       root         qw    05/17/2011 05:33:19                                    1        
    112 0.00000 test       root         qw    05/17/2011 05:33:19                                    1        
    113 0.00000 test       root         qw    05/17/2011 05:33:19                                    1        
    114 0.00000 test       root         qw    05/17/2011 05:33:19                                    1        
    115 0.00000 test       root         qw    05/17/2011 05:33:19                                    1        
    116 0.00000 test       root         qw    05/17/2011 05:33:19                                    1        
    117 0.00000 test       root         qw    05/17/2011 05:33:19                                    1        
    118 0.00000 test       root         qw    05/17/2011 05:33:19                                    1        
    119 0.00000 test       root         qw    05/17/2011 05:33:19                                    1        
    120 0.00000 test       root         qw    05/17/2011 05:33:19                                    1        
    121 0.00000 test       root         qw    05/17/2011 05:33:19                                    1        
    122 0.00000 test       root         qw    05/17/2011 05:33:19                                    1        
    123 0.00000 test       root         qw    05/17/2011 05:33:19\n};
	
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



}   #### Test::Agua::Monitor::SGE