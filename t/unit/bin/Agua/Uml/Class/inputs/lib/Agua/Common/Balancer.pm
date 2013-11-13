package Agua::Common::Balancer;
use Moose::Role;

=head2

	PACKAGE		Agua::Common::Balancer
	
	PURPOSE
	
		LOAD BALANCER METHODS FOR Agua::Common
		
=cut
use Data::Dumper;
use File::Path;

#requires 'username';
#requires 'cluster';
#requires 'outputdir';

has 'interval'	=> ( is  => 'rw', 'isa' => 'Int', required	=>	0, default => 30	);
has 'waittime'	=> ( is  => 'rw', 'isa' => 'Int', required	=>	0, default => 100	);
has 'stabilisationtime'	=> ( is  => 'rw', 'isa' => 'Int', required	=>	0, default => 30	);
has 'sleepinterval'	=> ( is  => 'rw', 'isa' => 'Int', required	=>	0, default => 30	);

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

sub launchBalancer {
	my $self			=	shift;
	my $clusterobject 	=	shift;
	$self->logDebug("clusterobject", $clusterobject);
	my $username = $clusterobject->{username};
	my $cluster = $clusterobject->{cluster};
	my $minnodes = $clusterobject->{minnodes};
	my $maxnodes = $clusterobject->{maxnodes};

	#### SET Conf::StarCluster CONFIGFILE
	my $configfile = $self->getConfigFile($username, $cluster);

	#### SET OUTPUT DIR
	my $outputdir = $self->getBalancerOutputdir($username, $cluster);

	#### GET STARCLUSTER EXECUTABLE
	my $starcluster = $self->conf()->getKey("agua", "STARCLUSTER");
	
	$self->logDebug("starcluster", $starcluster);
	$self->logDebug("outputdir", $outputdir);
	$self->logDebug("username", $username);
	$self->logDebug("configfile", $configfile);
	$self->logDebug("minnodes", $minnodes);
	$self->logDebug("maxnodes", $maxnodes);	;

	#### CREATE A UNIQUE QUEUE FOR THIS WORKFLOW
	my $envars = $self->getEnvars($username, $cluster);
	#my $queue = $envars->{queue};

	#### SET STATUS, PID, ETC. IN clusterstatus TABLE
	#### START THE LOAD BALANCER
	my $command = $envars->{tostring};
	$command .= "$starcluster -c $configfile bal $cluster";
	$command .= " -m ". $maxnodes;
	$command .= " -n ". $minnodes;
	$command .= " -i ". $self->interval();
	$command .= " -w ". $self->waittime();
	$command .= " -s ". $self->stabilisationtime();

#### DEBUG
#### DEBUG
#### DEBUG
	#$command .= " --kill-master ";
#### DEBUG
#### DEBUG
#### DEBUG

	$self->logDebug("command", $command);

	#### CREATE OUTPUT DIR
	File::Path::mkpath($outputdir) if not -d $outputdir;
	$self->logError("Can't create outputdir: " . $outputdir) and return if not -d $outputdir;
	$self->logDebug("outputdir: " . $outputdir);

	#### SET OUTPUT FILE
	my $outputfile = $self->getBalancerOutputfile($cluster, $outputdir);

	#### NB: MUST CHANGE TO CONFIGDIR FOR PYTHON PLUGINS TO BE FOUND
	my ($configdir) = $configfile =~ /^(.+?)\/[^\/]+$/;
	$self->logDebug("configdir", $configdir);

	my $pid = fork();
	$self->logDebug("pid", $pid);
	if ( $pid == 0 ) {
		#### SET InactiveDestroy ON DATABASE HANDLE
		$self->db()->dbh()->{InactiveDestroy} = 1;
		my $dbh = $self->db()->dbh();
		undef $dbh;

		$self->logDebug("Running child");
		$self->logDebug("\$\$ pid", $$);
		$self->logDebug("Doing exec(cd $configdir/plugins; $command)");

		#### REDIRECT STDOUT AND STDERR TO OUTPUTFILE
		$self->logDebug("Redirecting STDOUT and STDERR to outputfile", $outputfile);
		open(STDOUT, ">>$outputfile") or die "Agua::Common::Balancer::launchBalancer    Can't redirect STDOUT to outputfile: $outputfile\n";
		open(STDERR, ">>$outputfile") or die "Agua::Common::Balancer::launchBalancer    Can't redirect STDERR to outputfile: $outputfile\n";

		chdir("$configdir/plugins");
		exec("$command");
	}

	#### RESET DBH IF NOT DEFINED
	$self->logDebug("DOING self->setDbh() if not defined self->db()");
	$self->setDbh() if not defined $self->db();
	
	my $query = qq{SELECT 1 FROM clusterstatus
WHERE username='$username'
AND cluster='$cluster'};
	$self->logDebug("$query");
	my $exists = $self->db()->query($query);
	$self->logDebug("clusterstatus entry exists", $exists) if defined $exists;

	#### SET STATUS TO 'running'
	my $table = "clusterstatus";	
	my $now = $self->db()->now();
	if ( defined $exists ) {
		$query = qq{UPDATE $table
SET pid='$pid',
polled=$now,
status='running'
WHERE username='$username'
AND cluster='$cluster'};
		$self->logDebug("$query");
		$self->db()->do($query);
	}
	else {
		$query = qq{SELECT *
FROM cluster
WHERE username='$username'
AND cluster='$cluster'};
		$self->logDebug("$query");
		my $object = $self->db()->queryhash($query);
		$object->{pid} = $pid;
		$object->{started} = $now;
		$object->{polled} = $now;
		$object->{status} = 'running';
		
		my $required = ["username","cluster"];
		my $required_fields = ["username", "cluster"];
	
		#### CHECK REQUIRED FIELDS ARE DEFINED
		my $not_defined = $self->db()->notDefined($object, $required_fields);
		$self->logError("undefined values: @$not_defined") and return if @$not_defined;
	
		#### DO THE ADD
		my $inserted_fields = $self->db()->fields($table);
		my $success = $self->_addToTable($table, $object, $required_fields, $inserted_fields);
		$self->logDebug("insert success", $success)  if defined $success;
	}
}



sub checkBalancers {
	my $self		=	shift;
    $self->logDebug("Common::Balancers::checkBalancers()");

	#### GET ALL CLUSTERS WITH STATUS 'running' IN clusterstatus TABLE
	my $clusterobjects = $self->runningClusters(undef);
    $self->logDebug("No. active clusterobjects: " . scalar(@$clusterobjects));
	
	#### KEEP ONLY CLUSTERS WHERE THE LOAD BALANCER HAS FAILED	
	for ( my $i = 0; $i < @$clusterobjects; $i++ )
	{
		my $clusterobject = $$clusterobjects[$i];
		my $cluster = $clusterobject->{cluster};
		my $pid = $clusterobject->{pid};
		$self->logDebug("pid", $pid);
		
		$self->logDebug("No pid for clusterobject $clusterobject->{clusterobject}") and next if not defined $pid or not $pid;
		my $running = $self->processIsRunning($pid, $cluster);
		$self->logDebug("balancer is running", $running);
		if ( $running )
		{
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
	my $starcluster = $self->conf()->getKey("agua", "STARCLUSTER");
	for ( my $i = 0; $i < @$clusterobjects; $i++ )
	{
		my $username = $$clusterobjects[$i]->{username};
		my $clusterobject = $$clusterobjects[$i];	
		my $cluster = $clusterobject->{cluster};
		my $configfile = $self->getConfigFile($username, $cluster);
		if ( not $self->clusterIsRunning($cluster, $configfile, $starcluster) )
		{
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
		$self->launchBalancer($clusterobject);
	}
    $self->logDebug("END");	;
}

sub setClusterPolled {
	my $self			=	shift;
	my $username		=	shift;
	my $cluster			=	shift;
	$self->logDebug("Agua::Common::Balancer::setClusterPolled(username, cluster)");

	#### 	1. SET STATUS 'polled' IN clusterstatus
	my $query = qq{UPDATE clusterstatus
SET
polled=NOW()
WHERE username='$username'
AND cluster='$cluster'};
	$self->logDebug("$query");
	$self->db()->do($query);
}

sub setClusterTerminated {
	my $self			=	shift;
	my $username		=	shift;
	my $cluster			=	shift;
	$self->logDebug("Agua::Common::Balancer::setClusterTerminated(username, cluster)");

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

sub markClustersForTermination {
#### RETURN clusterobjects ARRAY WITH minnodes SET TO ZERO IF NOT BUSY
	my $self			=	shift;
	my $clusterobjects	=	shift;
	$self->logDebug("Agua::Common::Balancer::markClustersForTermination(clusterobject)");

	$self->logDebug("Checking if cluster is NOT busy - if so set minnodes to zero");
	for ( my $i = 0; $i < @$clusterobjects; $i++ )
	{
		my $clusterobject = $$clusterobjects[$i];	
		my $username = $clusterobject->{username};
		my $cluster = $clusterobject->{cluster};
		my $configfile = $self->getConfigFile($username, $cluster);
		$clusterobject->{minnodes} = 0 if not $self->clusterIsBusy($username, $cluster);
		$self->logDebug("clusterobject $i minnodes", $clusterobject->{minnodes});
	}

	return $clusterobjects;
}

sub processIsRunning {
	my $self		=	shift;
	my $pid			=	shift;
	my $cluster		=	shift;
	$self->logDebug("Agua::Common::Balancer::processIsRunning(pid, cluster)");
	$self->logDebug("pid", $pid);
	$self->logDebug("cluster", $cluster);
	my $command = qq{ps aux | grep " $pid " | grep " bal $cluster " | grep -v " grep "};
	$self->logDebug("command", $command);
	return `$command`;
}

sub balancerRunning {
	my $self			=	shift;
	my $username		=	shift;
	my $cluster			=	shift;
	my $configfile 		= 	shift;
	$self->logDebug("Agua::Common::Balancer::balancerRunning(cluster)");

	$self->logDebug("username", $username);
	$self->logDebug("cluster", $cluster);
	$self->logDebug("configfile", $configfile);
	
	#### SANITY CHECK	
	$self->logError("username not defined") and return if not defined $username;
	$self->logError("cluster not defined") and return if not defined $cluster;
	$self->logError("configfile not defined") and return if not defined $configfile;

	#### SET START BALANCER COMMAND STUB
	my $starcluster = $self->conf()->getKey("agua", "STARCLUSTER");
	my $command = '';
	$command = "$starcluster -c $configfile bal $cluster";

	my $clusterstatus = $self->getClusterStatus($username, $cluster);
	return 0 if not defined $clusterstatus;
	my $pid = $clusterstatus->{pid};
	return 0 if not defined $pid;
	$self->logDebug("pid: **$pid**");

	#### MATCH BY COMMAND AND THEN PID	
	my $ps = qq{ps aux | grep "$command"};
	$self->logDebug("ps", $ps);
	my $running = `$ps`;
	$self->logDebug("running", $running);
	my @lines = split "\n", $running;
	$self->logDebug("lines: " . $#lines);
	for ( my $i = 0; $i < $#lines + 1; $i++ )
	{
		$self->logDebug("lines[$i]", $lines[$i]);
		my @elements = split " ", $lines[$i];
		$self->logDebug("elements[1]: **$elements[1]**");
		$self->logDebug("returning 1")  if $pid == $elements[1];
		
		return 1 if $pid == $elements[1];
	}
	
	$self->logDebug("returning 0");
	return 0;
}

sub stopBalancer {
	my $self			=	shift;
	my $clusterobject	=	shift;
    $self->logDebug("clusterobject", $clusterobject);
	
	$clusterobject = $self->clusterInputs($clusterobject);
	return if not defined $clusterobject;
	
	my $pid = $clusterobject->{pid};
	$self->logDebug("pid", $pid);

	my $kill = "kill -9 $pid";
	`$kill`;
	$self->logDebug("No pid for clusterobject $clusterobject->{clusterobject}") and next if not defined $pid or not $pid;
}

sub getBalancerOutputfile {
	my $self		=	shift;
	my $cluster		=	shift;
	my $outputdir	=	shift;

	$outputdir = $self->outputdir() if not defined $outputdir or not $outputdir;
	$self->logDebug("cluster", $cluster);
	$self->logDebug("outputdir: " . $outputdir);
	
	return "$outputdir/$cluster-loadbalancer.out";
}

sub getBalancerOutputdir {
	my $self		=	shift;
	my $username	=	shift;
	my $cluster		=	shift;
	$self->logDebug("Agua::Balancer::getBalancerOutputdir(username, cluster)");
	$self->logDebug("username", $username);
	$self->logDebug("cluster", $cluster);
	
	#### GET USERDIR AND AGUADIR
	my $conf 		= 	$self->conf();
	my $userdir 	= 	$conf->getKey('agua', 'USERDIR');
	my $aguadir 	= 	$conf->getKey('agua', 'AGUADIR');
	my $adminkey 	= 	$self->getAdminKey($username);
	$self->logDebug("adminkey", $adminkey);
	return if not defined $adminkey;

	my $outputdir = "$userdir/$username/$aguadir/.cluster";
	if ( $adminkey )
	{
		my $adminuser = $self->conf()->getKey("agua", "ADMINUSER");
		$self->logDebug("adminuser", $adminuser);
		$outputdir = "$userdir/$adminuser/$aguadir/.cluster";
	}
	$self->logDebug("outputdir", $outputdir);
	
	#### CREATE DIR IF NOT EXISTS
	#File::Path::mkpath($outputdir) if not -d $outputdir;
	`mkdir -p $outputdir` if not -d $outputdir;
	$self->logDebug("Can't create outputdir", $outputdir) if not -d $outputdir;
	
	return $outputdir;
}

sub balancerOutput {
	my $self		=	shift;
	my $cluster		=	shift;
	my $lines		=	shift;
	my $outputfile = $self->getBalancerOutputfile($cluster);
	$self->logDebug("outputfile", $outputfile);
	return "CLUSTER OUTPUT FILE NOT FOUND: $outputfile" if not -f $outputfile;
	$lines	=	30 if not defined $lines;
	my $tail = `tail -$lines $outputfile`;

	$self->logDebug("BEFORE tail", $tail);
	$tail =~ s/^(Traceback|ValueError)[^\n]+\n//msg if defined $tail;
	$self->logDebug("AFTER tail", $tail);

	return $tail || "NO CLUSTER OUTPUT";
}

sub terminateBalancer {
	my $self		=	shift;
	my $username	=	shift;
	my $cluster		=	shift;
	$self->logDebug("username", $username);
	$self->logDebug("cluster", $cluster);
	
	#### CHANGE STATUS TO COMPLETED IN clusterstatus TABLE
	my $query = qq{SELECT pid FROM clusterstatus
WHERE username='$username'
AND cluster='$cluster'};
	$self->logDebug("$query");

	my $pid = $self->db()->query($query);
	my $childpid = $pid + 1;
	$self->logDebug("pid", $pid);
	my $command = "kill -9 $pid $childpid";
	$self->logDebug("command", $command);
	my $result = `$command`;
	$self->logDebug("result", $result);

	return $result;
}


1;