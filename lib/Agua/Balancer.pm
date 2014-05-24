#use Moose;
use MooseX::Declare;
=head2

	PACKAGE		Balancer
	
	PURPOSE
	
		MONITOR THE LOAD BALANCER RUNNING FOR EACH CLUSTER (I.E., SGE CELL)
		
		AND RESTART IT IF IT HAS BECOME INACTIVE (E.G., DUE TO A RECURRENT
		
		ERROR IN STARCLUSTER WHEN PARSING XML OUTPUT AND/OR XML ERROR MESSAGES
		
		CAUSED BY A BUG IN SGE)
	
	NOTES    
	
		1. CRON JOB RUNS THE SCRIPT checkBalancers.pl EVERY MINUTE
		
		* * * * * /agua/0.6/bin/scripts/checkBalancers.pl
		
=cut

use strict;
use warnings;
use Carp;

class Agua::Balancer with (Agua::Common::Aws,
	Agua::Common::Balancer,
	Agua::Common::Cluster,
	Agua::Common::SGE,
	Agua::Common::Util) {

#### EXTERNAL MODULES
use Data::Dumper;

use FindBin qw($Bin);
use lib "$Bin/..";

#### INTERNAL MODULES	
use Agua::DBaseFactory;
use Conf::Yaml;
use Agua::StarCluster;

# Booleans
has 'log'			=>  ( isa => 'Int', is => 'rw', default => 1 );  
has 'printlog'			=>  ( isa => 'Int', is => 'rw', default => 1 );

# Ints
has 'keydir'	=> ( isa => 'Str|Undef', is => 'rw' );
has 'adminkey'	=> ( isa => 'Str|Undef', is => 'rw' );
has 'interval'	=> ( is  => 'rw', 'isa' => 'Int', required	=>	0, default => 30	);
has 'waittime'	=> ( is  => 'rw', 'isa' => 'Int', required	=>	0, default => 100	);
has 'stabilisationtime'	=> ( is  => 'rw', 'isa' => 'Int', required	=>	0, default => 30	);
has 'minnodes'	=> ( isa => 'Int|Undef', is => 'rw', default => 0 );
has 'maxnodes'	=> ( isa => 'Int|Undef', is => 'rw', default => 0 );

# Strings
has 'configfile'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'outputdir'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'fileroot'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'cluster'	=>  ( isa => 'Str', is => 'rw'	);
has 'username'  =>  ( isa => 'Str', is => 'rw'	);
has 'queue'			=>  ( isa => 'Str|Undef', is => 'rw', default => 'default' );

# Objects
has 'json'		=> ( isa => 'HashRef', is => 'rw', required => 0 );
has 'db'	=> ( isa => 'Agua::DBase::MySQL', is => 'rw', required => 0 );

has 'conf' 	=> (
	is =>	'rw',
	'isa' => 'Conf::Yaml',
	default	=>	sub { Conf::Yaml->new( {} );	}
);

has 'starcluster'	=> (
	is 		=>	'rw',
	isa 	=> 'Agua::StarCluster',
	default	=>	sub { Agua::StarCluster->new({});	}
);



####////}	

method BUILD ($hash) {
	$self->logDebug("Agua::Balancer::BUILD()");
	
	#### SET DATABASE HANDLE
	$self->setDbh();

}


=head2

	SUBROUTINE		checkBalancers
		
	PURPOSE
	
		VERIFY THAT A LOAD BALANCER IS RUNNING FOR EACH ACTIVE CLUSTER
		
		AND RESTART THE LOAD BALANCER IF STOPPED
	
	NOTES    
	
		1. CHECKS clusterstatus DATABASE TABLE FOR RUNNING CLUSTERS
		
		2. CHECKS IF BALANCER PROCESS IS RUNNING USING ITS PID
		
		3. DOES THE FOLLOWING TO RESTART BALANCER:
			
			-   START NEW BALANCER PROCESS, CONCAT OUTPUT TO OUTPUT FILE
			
			- 	UPDATE clusterstatus TABLE WITH NEW PID
			
=cut

method checkBalancers {
    $self->logDebug("");

	#### GET ALL CLUSTERS WITH STATUS 'running' IN clusterstatus TABLE
	my $clusterobjects = $self->runningClusters(undef);
    $self->logDebug("No. active clusterobjects: " . scalar(@$clusterobjects));
	
	#### KEEP ONLY CLUSTERS WHERE THE LOAD BALANCER HAS FAILED	
	for ( my $i = 0; $i < @$clusterobjects; $i++ ) {
		my $clusterobject = $$clusterobjects[$i];
		my $cluster = $clusterobject->{cluster};
		my $pid = $clusterobject->{pid};
		$self->logDebug("pid", $pid);
		
		#### SKIP IF NO PID
		$self->logDebug("No pid for clusterobject $clusterobject->{clusterobject}") and next if not defined $pid or not $pid;

		#### SKIP IF PROCESS IS RUNNING 
		my $running = $self->processIsRunning($pid, $cluster);
		$self->logDebug("balancer is running", $running);
		
		if ( $running ) {
			$self->setClusterPolled($$clusterobjects[$i]->{username}, $$clusterobjects[$i]->{cluster});
			splice @$clusterobjects, $i, 1;
			$i--;
		}
	}
	$self->logDebug("clusterobjects", $clusterobjects);

	#### SET MISSING CLUSTERS TO 'terminated':
	#### 	1. SET STATUS 'terminated' IN clusterstatus
	#### 	2. SET STATUS 'terminated' IN ANY 'running' clusterworkflow ENTRY
	$self->logDebug("Checking if cluster NOT is running - if so set status to 'terminated'");
	my $executable = $self->conf()->getKey("agua", "STARCLUSTER");
	for ( my $i = 0; $i < @$clusterobjects; $i++ ) {
		my $username = $$clusterobjects[$i]->{username};
		my $clusterobject = $$clusterobjects[$i];
		
		$self->starcluster()->load($clusterobject);
		my $cluster = $clusterobject->{cluster};
		my $isrunning = $self->starcluster()->isRunning();
		
		if ( not $isrunning ) {
			#$self->setClusterTerminated($username, $cluster);
			$self->logDebug("clusterobject $i is not running. Splicing it out");
			splice(@$clusterobjects, $i, 1);
			$i--;
		}
	}
    $self->logDebug("No. remaining clusterobjects: " . scalar(@$clusterobjects));
	$self->logDebug("clusterobjects", $clusterobjects);

	#### OTHERWISE, IF THE CLUSTER IS **NOT** BUSY WITH WORKFLOW JOBS,
	#### MARK IT FOR TERMINATION BY SETTING ITS minnodes TO ZERO
	$clusterobjects = $self->markClustersForTermination($clusterobjects);

	$self->logDebug("clusterobjects", $clusterobjects);

	#### RESTART LOAD BALANCERS FOR REMAINING CLUSTERS
	foreach my $clusterobject (@$clusterobjects)
	{
	    $self->logDebug("Doing launchBalancer for cluster $clusterobject->{cluster}");
		$self->starcluster()->load($clusterobject);
		$self->starcluster()->launchBalancer();
	}
    $self->logDebug("END");	;
}

method setClusterPolled ($username, $cluster) {
	$self->logDebug("username", $username);
	$self->logDebug("cluster", $cluster);
	
	#### 	1. SET STATUS 'polled' IN clusterstatus
	my $query = qq{UPDATE clusterstatus
SET
polled=NOW()
WHERE username='$username'
AND cluster='$cluster'};
	$self->logDebug("$query");
	$self->db()->do($query);
}

method setClusterTerminated ($username, $cluster) {
	$self->logDebug("username", $username);
	$self->logDebug("cluster", $cluster);

	#### 	1. SET STATUS 'terminated' IN clusterstatus
	my $query = qq{UPDATE clusterstatus
SET status='terminated',
stopped=NOW()
WHERE username='$username'
AND cluster='$cluster'};
	$self->logDebug("$query");
	$self->db()->do($query);
		
	#### 	2. SET STATUS 'terminated' IN ANY 'running' clusterworkflow ENTRY
	$query = qq{UPDATE clusterworkflow
SET status='terminated'
WHERE status='running'
AND username='$username'
AND cluster='$cluster'};
	$self->logDebug("$query");
	$self->db()->do($query);	
}

method markClustersForTermination ($clusterobjects) {
#### RETURN clusterobjects ARRAY WITH minnodes SET TO ZERO IF NOT BUSY
	$self->logDebug("Checking if cluster is NOT busy - if so set minnodes to zero");
	for ( my $i = 0; $i < @$clusterobjects; $i++ )
	{
		my $clusterobject = $$clusterobjects[$i];	
		my $username = $clusterobject->{username};
		my $cluster = $clusterobject->{cluster};
		#my $configfile = $self->setConfigFile($username, $cluster);
		$clusterobject->{minnodes} = 0 if not $self->clusterIsBusy($username, $cluster);
		$self->logDebug("clusterobject $i minnodes", $clusterobject->{minnodes});
	}

	return $clusterobjects;
}

method processIsRunning ($pid, $cluster) {
	$self->logDebug("Agua::Common::Balancer::processIsRunning(pid, cluster)");
	$self->logDebug("pid", $pid);
	$self->logDebug("cluster", $cluster);
	my $command = qq{ps aux | grep " $pid " | grep " bal $cluster " | grep -v " grep "};
	$self->logDebug("command", $command);
	return `$command`;
}




} #### Agua::Balancer


