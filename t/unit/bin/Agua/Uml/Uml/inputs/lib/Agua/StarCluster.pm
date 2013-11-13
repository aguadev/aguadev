use MooseX::Declare;

=head2

	PACKAGE		StarCluster

    PURPOSE
    
        1. START A CLUSTER, MOUNT AQUARIUS /data AND /nethome
		
			ON ITS NODES
    
        2. USERS CAN RUN small, medium, large OR CUSTOM CLUSTERS
            (ALL USERS USE admin USER'S CONFIG FILE)
        
        3. EACH WORKFLOW USES A SINGLE CLUSTER TO RUN ALL ITS STAGES
		
		4. MORE THAN ONE WORKFLOW CAN USE A CLUSTER AT THE SAME TIME
		
        5. THE CLUSTER SHUTS DOWN WHEN THERE ARE NO RUNNING WORKFLOWS
        
	NOTES
	
		THIS MODULE WORKS WITH OPERATIONAL CLUSTERS CONFIGURED BY
		
		THE automount.py STARCLUSTER PLUGIN, WHICH DOES THE FOLLOWING:
		
			1. OPEN NFS AND SGE PORTS IN SECURITY GROUP
	
			2. SETUP SHARES FROM HEAD
	
			3. MOUNT SHARES ON MASTER AND ALL NEW NODES
	
			4. SET THE DEFAULT QUEUE ON MASTER
	
			5. SET threaded PARALLEL ENVIRONMENT ON MASTER

			6. ADDITIONAL SGE CONFIGURATION


		StarCluster.pm IS BASED ON THE FOLLOWING METHODOLOGY:

	    1. A NEW SGE CELL IS CREATED ON THE AGUA HEAD NODE FOR EACH
		
			CLUSTER THAT IS STARTED E.G., /opt/sge6/syoung-smallcluster

	    2. WITHIN EACH CELL, A NEW QUEUE IS CREATED FOR EACH WORKFLOW
    
	        E.G., syoung-project1-workflow1

		3. ADD THE threaded PARALLEL ENVIRONMENT TO EACH QUEUE SO THAT
		
			JOBS CAN USE MULTIPLE CPUS (LATER: CHECK IF NECESSARY)
		
		
    TO DO

        1. ALLOW USERS TO SPECIFY MAX NUMBER OF NODES, AMIs, ETC.
        
            BY EDITING USER-SPECIFIC CONFIG FILES CONTAINING
			
			[cluster myClusterName] SECTIONS	

            USERNAME    CONFIGFILE
            admin       /home/admin/.starcluster/config
            jgilbert    /home/jgilbert/.starcluster/config

        2. ALLOW USER TO SPECIFY A CLUSTER FOR EACH WORKFLOW
    
            (ALL STAGES IN THE SAME WORKFLOW USE THE SAME CLUSTER)
        
        3. IMPLEMENT AUTO-LEVELLING TO AUTOMATICALLY 

            INCREASE/DECREASE THE NUMBER OF NODES BASED ON
            
            THE NUMBER OF QUEUED JOBS	
		
=cut

class Agua::StarCluster with (Agua::Common::Aws,
	Agua::Common::Base,
	Agua::Common::Balancer,
	Agua::Common::Cluster,
	Agua::Common::SGE,
	Agua::Common::Ssh,
	Agua::Common::Util,
	Agua::Common::Database,
	Agua::Common::Logger) {

use FindBin::Real;
use lib FindBin::Real::Bin() . "/lib";

#### INTERNAL MODULES
use Agua::Instance::StarCluster;
use Agua::DBaseFactory;
use Conf::Agua;
use Conf::StarCluster;

#### EXTERNAL MODULES
use Data::Dumper;
use File::Path;
use Getopt::Simple;

#### Boolean
has 'SHOWLOG'			=>  ( isa => 'Int', is => 'rw', default => 4 );  
has 'PRINTLOG'			=>  ( isa => 'Int', is => 'rw', default => 4 );
has 'help'			=> ( is  => 'rw', 'isa' => 'Bool', required	=>	0, documentation => "Print help message"	);

#### Int
has 'sleep'			=> ( is  => 'rw', 'isa' => 'Int', default	=>	600	);
has 'workflowpid'	=> ( is  => 'rw', 'isa' => 'Int', required	=>	0	);
has 'nodes'			=> ( is  => 'rw', 'isa' => 'Str', required	=>	0	);
has 'maxnodes'		=> ( is  => 'rw', 'isa' => 'Str|Undef', required	=>	0	);
has 'minnodes'		=> ( is  => 'rw', 'isa' => 'Str|Undef', required	=>	0	);
has 'tailwait'	=> ( is  => 'rw', 'isa' => 'Int', required	=>	0, default => 30	);
has 'slots'			=> ( is  => 'rw', 'isa' => 'Int', required	=>	0, default => 1	);

#### String
has 'logfile'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'conffile'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'configfile'=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'queue'			=> ( is  => 'rw', 'isa' => 'Str|Undef', required	=>	0	);
has 'sgeroot'		=> ( is  => 'rw', 'isa' => 'Str', default => "/opt/sge6"	);
has 'sgecell'		=> ( is  => 'rw', 'isa' => 'Str', required	=>	0	);
has 'fileroot'		=> ( is  => 'rw', 'isa' => 'Str', required	=>	0	);
has 'username'		=> ( is  => 'rw', 'isa' => 'Str', required	=>	0	);
has 'requestor'		=> ( is  => 'rw', 'isa' => 'Str', required	=>	0	);
has 'clustertype'	=> ( is  => 'rw', 'isa' => 'Str', required	=>	0	);
has 'keyname'		=> ( is  => 'rw', 'isa' => 'Str', required	=>	0	);
has 'cluster'		=> ( is  => 'rw', 'isa' => 'Str|Undef', required	=>	0	);
has 'clusteruser'	=> ( is  => 'rw', 'isa' => 'Str', default	=> "sgeadmin"	);
has 'availzone'		=> ( is  => 'rw', 'isa' => 'Str', required	=>	0	);
has 'instancetype'	=> ( is  => 'rw', 'isa' => 'Str|Undef', required	=>	0	);
has 'nodeimage'		=> ( is  => 'rw', 'isa' => 'Str', required	=>	0	);
has 'executable'	=> ( is  => 'rw', 'isa' => 'Str|Undef', required	=>	0	);
has 'plugins'		=> ( is  => 'rw', 'isa' => 'Str', default	=> "automount,sge,startup"	);
has 'amazonuserid'	=> ( is  => 'rw', 'isa' => 'Str|Undef', required	=>	0	);
has 'accesskeyid'	=> ( is  => 'rw', 'isa' => 'Str|Undef', required	=>	0	);
has 'awssecretaccesskey'=> ( is  => 'rw', 'isa' => 'Str|Undef', required	=>	0	);
has 'privatekey'	=> ( is  => 'rw', 'isa' => 'Str', required	=>	0	);
has 'publiccert'	=> ( is  => 'rw', 'isa' => 'Str', required	=>	0	);
has 'keypairfile'	=> ( is  => 'rw', 'isa' => 'Str|Undef', required	=>	0	);
has 'outputdir'		=> ( is  => 'rw', 'isa' => 'Str', default 	=>	''	);
has 'sources'		=> ( is  => 'rw', 'isa' => 'Str', default 	=>	''	);
has 'mounts'		=> ( is  => 'rw', 'isa' => 'Str', default 	=>	''	);
has 'devs'			=> ( is  => 'rw', 'isa' => 'Str', default 	=>	''	);
has 'configfile'	=> ( is  => 'rw', 'isa' => 'Str'	);
has 'outputfile'	=> ( is  => 'rw', 'isa' => 'Str'	);

#### Object
has 'db'		=> ( isa => 'Agua::DBase::MySQL', is => 'rw', required => 0 );
has 'monitor'		=> ( is  => 'rw', 'isa' => 'Maybe' );
has 'sourcedirs'	=> ( is  => 'rw', 'isa' => 'ArrayRef[Str]' );
has 'mountpoints'	=> ( is  => 'rw', 'isa' => 'ArrayRef[Str]' );
has 'devices'		=> ( is  => 'rw', 'isa' => 'ArrayRef[Str]' );
has 'fields'    	=> ( isa => 'ArrayRef[Str|Undef]', is => 'ro', default => sub { ['help', 'amazonuserid', 'accesskeyid', 'awssecretaccesskey', 'privatekey', 'publiccert', 'username', 'keyname', 'cluster', 'nodes', 'outputdir', 'maxnodes', 'minnodes', 'sources', 'mounts', 'devs', 'instancetype', 'availzone', 'nodeimage', 'configfile'] } );
has 'conf' 	=> (
	is =>	'rw',
	'isa' => 'Conf::Agua',
	default	=>	sub { Conf::Agua->new( backup	=>	1, separator => "\t" );	}
);
has 'config'=> (
	is 		=>	'rw',
	isa 	=> 'Conf::StarCluster',
	default	=>	sub { Conf::StarCluster->new( backup =>	1, separator => "="	);	}
);
has 'clusterinstance'=> (
	is 		=>	'rw',
	isa 	=> 'Agua::Instance::StarCluster',
	default	=>	sub { Agua::Instance::StarCluster->new({}); }
);

####/////}}

=head2

	SUBROUTINE		BUILD
	
	PURPOSE

		GET AND VALIDATE INPUTS, AND INITIALISE OBJECT

=cut

method BUILD ($hash) {
	#$self->logDebug("hash", $hash);
	#### IF HASH IS DEFINED, ADD VALUES TO SLOTS
	if ( defined $hash )
	{
		foreach my $key ( keys %{$hash} ) {
			$self->logDebug("ADDING key $key", $hash->{$key});
			$hash->{$key} = $self->unTaint($hash->{$key});
			$self->$key($hash->{$key}) if $self->can($key);
		}
	}
	$self->logDebug("hash", $hash);
	
	$self->logDebug("DOING self->getopts()");
	$self->getopts();
	
	$self->logDebug("DOING self->initialise()");
	$self->initialise();
}

#### INITIALISE
method initialise {
	my $username 	= 	$self->username();
	my $cluster 	= 	$self->cluster();
	$self->logDebug("username", $username);
	$self->logDebug("cluster", $cluster);
	$self->logError("username is not defined") and exit if not defined $username;
	$self->logError("cluster is not defined") and exit if not defined $cluster;
	
	#### SET DATABASE HANDLE
	$self->logDebug("BEFORE self->setDbh()");
	$self->setDbh();
	$self->logDebug("AFTER self->setDbh()");
	
	#### SET STARCLUSTER LOCATION
	$self->executable($self->conf()->getKey("agua", "STARCLUSTER"));
	
	#### SET Conf::Agua INPUT FILE IF DEFINED
	$self->conf()->inputfile($self->conffile()) if $self->conffile();
	
	#### SET Conf::StarCluster INPUT FILE IF DEFINED
	#### OTHERWISE, DETERMINE LOCATION USING USERNAME AND CLUSTER
	my $configfile = $self->configfile();
	$configfile = $self->getConfigFile($username, $cluster) if not $configfile;
	$self->config()->inputfile($configfile);
	$self->logDebug("configfile", $configfile);
	
	#### SET CLUSTER TYPE
	$self->clustertype($self->conf()->getKey('agua', "CLUSTERTYPE"));
	
	#### SET KEYNAME IF NOT DEFINED
	$self->keyname("$username-key") if not $self->keyname();
	
	#### SET KEYPAIR FILE IF NOT DEFINED
	$self->logDebug("Doing self->setKeypairfile()");
	$self->setKeypairfile() if not $self->keypairfile();
	$self->logDebug("self->keypairfile(): " . $self->keypairfile());
	
	#### SET OUTPUT DIR IF NOT DEFINED
	if ( not $self->outputdir() )
	{
		my $outputdir = $self->getBalancerOutputdir($username, $cluster);
		$self->logDebug("outputdir: " . $outputdir);
		$self->outputdir($outputdir);
	}
}

#### LOAD
method load ($hash) {
	foreach my $key ( keys %$hash ) {
		$self->$key($hash->{$key});
	}

	#### SET SOURCEDIRS AND MOUNTPOINTS
	my @sourcedirs = 	split ",", 	$self->sources() 	|| () if $self->sources();
	my @mountpoints = 	split ",", 	$self->mounts() 	|| () if $self->mounts();
	my @devices = 		split ",", 	$self->devs() 		|| () if $self->devs();
	$self->sourcedirs(\@sourcedirs) if $self->sources();
	$self->mountpoints(\@mountpoints) if $self->mounts();
	$self->devices(\@devices) if $self->devs();
}

#### START CLUSTER
method start {
#### 1. START CLUSTER AND RESTART BALANCER IF CLUSTER NOT RUNNING
#### 2. START BALANCER IF BALANCER NOT RUNNING 
	$self->logDebug("");

	my $username 	= $self->username();
	my $project 	= $self->project();
	my $workflow 	= $self->workflow();
	my $cluster 	= $self->cluster();
	my $configfile 	= $self->configfile();
	my $executable = $self->executable();
	my $outputdir 	= $self->outputdir();
	
	$self->logDebug("executable", $executable);
	$self->logError("username not defined") and exit if not $username;
	$self->logError("cluster not defined") and exit if not $cluster;
	$self->logError("configfile not defined") and exit if not $configfile;
	$self->logError("executable not defined") and exit if not $executable;
	$self->logError("outputdir not defined") and exit if not $outputdir;

	my $cluster_running = $self->clusterIsRunning($cluster, $configfile, $executable);
	$self->logDebug("cluster_running", $cluster_running);



$self->logDebug("DEBUG EXIT") and exit;
	

	#### TERMINATE CLUSTER+BALANCER AND START CLUSTER IF CLUSTER NOT RUNNING
	my $started = 1;
	if ( not $cluster_running ) {
		#### TERMINATE CLUSTER AND REMOVE SECURITY GROUP FROM AWS
		$self->terminateCluster($cluster, $configfile, $executable, undef, undef);
		
		#### TERMINATE BALANCER IF EXISTS
		$self->terminateBalancer($username, $cluster);
		
		#### START CLUSTER
		$started = $self->launchCluster($username, $cluster, $configfile, $executable, $outputdir);
	}
	$self->logDebug("started", $started);
	$self->logError("Could not start cluster", $cluster) and exit if not $started;
	
	#### START LOAD BALANCER IF NOT RUNNING
	my $balancer_running = $self->balancerRunning($username, $cluster, $configfile, $outputdir);
	$self->logDebug("balancer_running", $balancer_running);
	if ( not $balancer_running ) {
		my $clusterobject = $self->getCluster($username, $cluster);
		$self->launchBalancer($clusterobject) ;
	}
	
	return 1;
}

method isRunning {
#### CONFIRM CLUSTER IS RUNNING AND HAS NODES
	#my $cluster_running = $self->clusterIsRunning($cluster, $configfile, $executable);
	#$self->logDebug("cluster_running", $cluster_running);
	#my $cluster		=	shift;
	#my $configfile	=	shift;
	#my $starcluster	=	shift;

	my $cluster 	=	$self->cluster();
	my $configfile 	= 	$self->conf()->inputfile();
	my $executable 	=	$self->conf()->getKey("agua", "STARCLUSTER");	
	$self->logDebug("cluster", $cluster);
	$self->logDebug("configfile", $configfile);
	$self->logDebug("executable", $executable);

	$self->instance()->load({
		cluster	    =>	$cluster,
		executable	=>	$executable,
		configfile	=>	$configfile,
		SHOWLOG		=>	4
	});
	
	#my $clusterinstance = Agua::Instance::StarCluster->new(
	#	{
	#		cluster	    =>	$cluster,
	#		executable	=>	$executable,
	#		configfile	=>	$configfile
	#	}
	#);
	
	my $running = $self->instance()->isRunning();
	$running = 0 if not defined $running;

	my $hasnodes = $self->instance()->hasNodes();
	$running = 0 if not $hasnodes;
	
	$self->logDebug("running", $running);
	return $running;	
}
method launchCluster ($username, $cluster, $configfile, $executable, $outputdir) {
	$self->logDebug("username", $username);
	$self->logDebug("cluster", $cluster);
	$self->logDebug("configfile", $configfile);
	$self->logDebug("executable: $executable");
	$self->logDebug("outputdir", $outputdir);

	#### CREATE OUTPUT DIR
	File::Path::mkpath($outputdir) if not -d $outputdir;
	$self->logDebug("outputdir: " . $outputdir);
	$self->logError("Can't create outputdir: $outputdir") and exit if not -d $outputdir;

	#### CREATE CONFIG FILE
#### DEBUG
#### DEBUG
	#$self->_createConfigFile() if not -f $configfile;
	$self->_createConfigFile();
#### DEBUG
#### DEBUG

	#### NB: MUST CHANGE TO CONFIGDIR FOR PYTHON PLUGINS TO BE FOUND
	my ($configdir) = $configfile =~ /^(.+?)\/[^\/]+$/;
	$self->logDebug("configdir", $configdir);

	#### SET START CLUSTER COMMAND
	my $logfile = "/tmp/$cluster.log";
	$self->logDebug("logfile", $logfile);
	if ( -f $logfile ) {
		my $command = "rm -fr $logfile";
		$self->logDebug("command", $command);
		`rm -fr $logfile`;
		$self->logDebug("ls $logfile", `ls $logfile`);
	}
	$self->logError("Can't remove logfile", $logfile) and exit if -f $logfile;

	my $command = "cd $configdir/plugins; $executable -c $configfile --logfile $logfile start $cluster";
	$command .= " -s " . $self->nodes() if $self->nodes() and not $self->minnodes();	
	$self->logDebug("command", $command);

	#my $outputfile = "$outputdir/$cluster-executable.out";
	
	my $pid = fork();
	if ( not defined $pid or $pid == 0 ) {
		#### SET InactiveDestroy ON DATABASE HANDLE
		$self->db()->dbh()->{InactiveDestroy} = 1;
		my $dbh = $self->db()->dbh();
		undef $dbh;

		$self->logDebug("EXECUTING COMMAND", $command);
		system($command);
	}
	else {
		$self->logDebug("AFTER FORK (PARENT)");
		#### WAIT FOR CLUSTER TO COMPLETE STARTUP
		return $self->fileTail($logfile, "The cluster has been started and configured", 1, $self->tailwait());
	}	
}

#### STOP CLUSTER
method stop {
	$self->logDebug("StarCluster::stop(username, cluster)");

	my $username = $self->username();
	my $cluster = $self->cluster();
	my $configfile = $self->configfile();
	my $executable = $self->executable();
	my $outputdir = $self->outputdir();
	
	$self->logError("username not defined") and exit if not $username;
	$self->logError("cluster not defined") and exit if not $cluster;
	$self->logError("configfile not defined") and exit if not $configfile;
	$self->logError("executable not defined") and exit if not $executable;
	$self->logError("outputdir not defined") and exit if not $outputdir;
	
	#### TERMINATE THE CLUSTER
 	$self->logDebug("Doing self->terminateCluster()");
	return if not $self->terminateCluster($username, $cluster, $configfile, $executable, undef, undef);

	#### STOP THE LOAD BALANCER
 	$self->logDebug("Doing self->terminateBalancer()");
	return if not defined $self->terminateBalancer($username, $cluster);
}

#### TERMINATE CLUSTER
method terminateCluster ($cluster, $configfile, $executable, $tries, $delay) {
	
	#### DEFAULT NUMBER TRIES AND DELAY DURATION
	$tries = 10 if not defined $tries;
	$delay = 10 if not defined $delay;
	
	#### MOVE TO CONFIG DIR
	my ($configdir) = $configfile =~ /^(.+?)\/[^\/]+$/;
	$self->logDebug("configdir", $configdir);
	chdir("$configdir/plugins");
	
	### TERMINATE THE CLUSTER	
	my $command = "$executable -c $configfile terminate --confirm $cluster 2>&1";
	$self->logDebug("command", $command);
	my $output = $self->captureStderr($command);
	return 0 if not defined $output;
	$self->logDebug("output", $output);
	return 1 if $output =~ /!!! ERROR - cluster admin-microcluster does not exist/;
	
	#### ENSURE THAT CLUSTER IS TERMINATED
	my $count = 0;
	while ( $count < $tries ) {	
		$count++;
		$self->logDebug("$command");
		my $output = $self->captureStderr($command);
		$self->logDebug("output", $output);

		# ERROR FORMAT:
		# !!! ERROR - InvalidGroup.InUse: There are active instances using security group '@sc-admin-microcluster'
		
		return 1 if $output !~ /There are active instances using security group/ms;
		sleep($delay);
	}

	return 0;
}

#### WRITE CONFIG FILE
method writeConfigfile {

=head2

	SUBROUTINE 		writeConfigfile
	
	PURPOSE
	
		ADD KEYPAIR FILE, AWS ACCESS IDs AND OTHER CREDENTIAL
		
		INFO TO USER'S CLUSTER CONFIG

=cut

	$self->logDebug("");

	#### PRINT HELP
	if ( defined $self->help() ) {
		print qq{

	$0 writeConfigfile <--amazonuserid String> <--accesskeyid String> [--help]
	
	--privatekey 		Location of private key
	--privatecert 		Location of public key
	--amazonuserid 		AWS user ID
	--accesskeyid		AWS access key ID
	--awssecretaccesskey 	AWS secret access key
	--keyname			Name of keypair
	--username			Change this user's config file
	--help				Print help info
	--cluster 			Name of cluster (e.g., microcluster) 
	--nodes 			Number of nodes to begin with
	--maxnodes 			Max. number of nodes (using load balancer)
	--minnodes 			Min. number of nodes (using load balancer)
	--outputdir 		Print load balancer STDOUT/STDERR to file in this directory
	--sources 			Comma-separated list of source dirs (e.g., /data,/nethome)
	--mounts 			Comma-separated list of mount points (e.g., /data,/nethome)
	--devs 				Comma-separated list of devices (e.g., /dev/sdh,/dev/sdi)
	--configfile 		Print config to this file (e.g., /nethome/admin/.starcluster/config)
};
	}
	
	$self->logError("username not defined") and exit if not $self->username();
	$self->logError("configfile not defined") and exit if not $self->configfile();
	
	#### SET DEFAULT KEYNAME
	$self->keyname() = $self->username(). "-key" if not defined $self->keyname();

	#### SET TARGET KEYPAIR FILE
	my $keypairfile	=	$self->keypairfile();

	#### SET INPUTFILE
	my $configfile	=	$self->configfile();
	my $conf 		= 	$self->conf();
	my $username 	= 	$self->username();
	my $cluster 	= 	$self->cluster();
	my $userdir 	= 	$conf->getKey('agua', "USERDIR");

	$self->logDebug("keypairfile", $keypairfile);
	$self->logDebug("found keypairfile")  if -f $keypairfile;
	$self->logDebug("Can't find keypairfile")  if not -f $keypairfile;
	my $config = Conf::StarCluster->new(
		separator	=>	"=",
		inputfile	=>	$configfile
	);

	$self->logDebug("privatekey: " . $self->privatekey());
	$self->logDebug("publiccert: " . $self->publiccert());
	$self->logDebug("amazonuserid: " . $self->amazonuserid());
	$self->logDebug("accesskeyid: " . $self->accesskeyid());
	$self->logDebug("awssecretaccesskey: " . $self->awssecretaccesskey());
	$self->logDebug("keyname: " . $self->keyname());
	
	$self->logDebug("username: " . $self->username());
	$self->logDebug("sources: " . $self->sources());
	$self->logDebug("mounts: " . $self->mounts());
	$self->logDebug("devs: " . $self->devs());
	$self->logDebug("instancetype: " . $self->instancetype());
	$self->logDebug("nodes: " . $self->nodes());
	$self->logDebug("availzone: " . $self->availzone());
	$self->logDebug("nodeimage: " . $self->nodeimage());
	$self->logDebug("cluster: " . $self->cluster());
	$self->logDebug("configfile: " . $self->configfile());

	#### SET [global]
	$config->setKey("global", "DEFAULT_TEMPLATE", $cluster);
	$config->setKey("global", "ENABLE_EXPERIMENTAL", "True");

	#### SET [cluster <clusterName>]
	$config->setKey("cluster:$cluster", "KEYNAME", "id_rsa-" . $self->keyname());
	$config->setKey("cluster:$cluster", "AVAILABILITY_ZONE", $self->availzone());
	$config->setKey("cluster:$cluster", "CLUSTER_SIZE", $self->nodes());
	$config->setKey("cluster:$cluster", "CLUSTER_USER", $self->clusteruser());
	$config->setKey("cluster:$cluster", "NODE_IMAGE_ID", $self->nodeimage());
	$config->setKey("cluster:$cluster", "NODE_INSTANCE_TYPE", $self->instancetype());
	$config->setKey("cluster:$cluster", "CLUSTER_USER", $self->clusteruser());
	$config->setKey("cluster:$cluster", "PLUGINS", $self->plugins());
	
	#### SET [aws info]
	if ( not $self->amazonuserid() )
	{
		my $aws =  $self->getAws($username);
		$self->logDebug("aws", $aws);
		
		$config->setKey("aws:info", "AWS_USER_ID", $aws->{amazonuserid});
		$config->setKey("aws:info", "AWS_ACCESS_KEY_ID", $aws->{accesskeyid});
		$config->setKey("aws:info", "AWS_SECRET_ACCESS_KEY", $aws->{awssecretaccesskey});	
	}
	else
	{
		$config->setKey("aws:info", "AWS_USER_ID", $self->amazonuserid());
		$config->setKey("aws:info", "AWS_ACCESS_KEY_ID", $self->accesskeyid());
		$config->setKey("aws:info", "AWS_SECRET_ACCESS_KEY", $self->awssecretaccesskey());	
	}

	#### GET KEY FILES
	my $privatekey = $self->privatekey();
	my $publiccert = $self->publiccert();
	
	#### SET [key <keyname>]
	my $keyname = $self->keyname();
	$config->setKey("key:id_rsa-$keyname", "KEYNAME", "id_rsa-$keyname");
	$config->setKey("key:id_rsa-$keyname", "KEY_LOCATION", $keypairfile);

	#### GET PORTS	
	my $portmapport = $self->conf()->getKey("starcluster:nfs", "PORTMAPPORT");
	my $nfsport 	= $self->conf()->getKey("starcluster:nfs", "NFSPORT");
	my $mountdport 	= $self->conf()->getKey("starcluster:nfs", "MOUNTDPORT");

	#### GET WWW USER
	my $apacheuser	= $self->conf()->getKey("agua", "APACHEUSER");
	$self->logDebug("apacheuser", $apacheuser);

	#### SET [plugin automount]
	$config->setKey("plugin:automount", "setup_class", "automount.NfsShares");
	$config->setKey("plugin:automount", "privatekey", $privatekey);
	$config->setKey("plugin:automount", "publiccert", $publiccert);
	$config->setKey("plugin:automount", "cluster", $cluster);
	$config->setKey("plugin:automount", "portmapport", $portmapport);
	$config->setKey("plugin:automount", "nfsport", $nfsport);
	$config->setKey("plugin:automount", "mountdport", $mountdport);
	$config->setKey("plugin:automount", "interval", $self->sleepinterval())
		if $self->sleepinterval();
	$config->setKey("plugin:automount", "mountpoints", $self->mounts())
		if $self->mounts();
	$config->setKey("plugin:automount", "sourcedirs", $self->sources())
		if $self->sources();
	
	$self->logDebug("privatekey", $privatekey);
	$self->logDebug("portmapport", $portmapport);

	$self->logDebug("nfsport", $nfsport);
	$self->logDebug("mountdport", $mountdport);
	$self->logDebug("devs: " . $self->devs());
	$self->logDebug("mounts: " . $self->mounts());
	$self->logDebug("sleepinterval: " . $self->sleepinterval());
	
	#### SET sge PLUGIN
	my $slots = $self->setSlots($self->instancetype());
	my ($qmasterport, $execdport) = $self->getPorts();
	$self->logDebug("slots", $slots);
	$self->logDebug("qmasterport", $qmasterport);
	$self->logDebug("execdport", $execdport);
	$config->setKey("plugin:sge", "setup_class", "sge.CreateCell");
	$config->setKey("plugin:sge", "privatekey", $privatekey);
	$config->setKey("plugin:sge", "publiccert", $publiccert);
	$config->setKey("plugin:sge", "root", $self->sgeroot());
	$config->setKey("plugin:sge", "cell", $cluster);
	$config->setKey("plugin:sge", "qmasterport", $qmasterport);
	$config->setKey("plugin:sge", "execdport", $execdport);
	$config->setKey("plugin:sge", "slots", $slots);


	my $installdir 	= 	$conf->getKey('agua', "INSTALLDIR");
	$self->logDebug("installdir", $installdir);
	my $instanceid 	= `curl -s http://169.254.169.254/latest/meta-data/instance-id`;
	$self->logDebug("instanceid", $instanceid);
	my $version 	= 	$conf->getKey('agua', "VERSION");
	
	#### WRITE startup PLUGIN
	$config->setKey("plugin:startup", "setup_class", "startup.StartUp");
	$config->setKey("plugin:startup", "privatekey", $privatekey);
	$config->setKey("plugin:startup", "publiccert", $publiccert);
	$config->setKey("plugin:startup", "cell", $cluster);
	#$config->setKey("plugin:startup", "qmasterport", $qmasterport);
	#$config->setKey("plugin:startup", "execdport", $execdport);
	$config->setKey("plugin:startup", "root", $installdir);
	$config->setKey("plugin:startup", "installdir", $installdir);
	$config->setKey("plugin:startup", "headnodeid", $instanceid);
	$config->setKey("plugin:startup", "version", $version);

	$self->logDebug("Configfile printed", $configfile);
}

method setQueue ($queue) {
	$self->logDebug("DOING slots = self->setSlots(undef)");
	my $slots = $self->setSlots(undef);
	$slots = 1 if not defined $slots;
	$self->logDebug("slots", $slots);
	
	my $parameters = {
		qname			=>	$queue,
		slots			=>	$slots,
		shell			=>	"/bin/bash",
		hostlist		=>	"\@allhosts",
		load_thresholds	=>	"np_load_avg=20"
	};

	my $queuefile = $self->getQueuefile("queue-$queue");
	$self->logDebug("queuefile", $queuefile);
	
	my $exists = $self->queueExists($queue);
	$self->logDebug("exists", $exists);
	
	$self->_addQueue($queue, $queuefile, $parameters) if not $exists;
}

method unsetQueue ($queue) {
	my $queuefile = $self->getQueuefile("queue-$queue");
	$self->logDebug("queuefile", $queuefile); 
	
	$self->_removeQueue($queue, $queuefile);
}
method setPE ($pe, $queue) {
 	$self->logDebug("pe", $pe);
 	$self->logDebug("queue", $queue);

	my $slots = $self->setSlots(undef);
	$self->logDebug("slots", $slots); 

	my $pefile = $self->getQueuefile("pe-$pe");
	$self->logDebug("pefile", $pefile); 
	my $queuefile = $self->getQueuefile("queue-$queue");
	$self->logDebug("queuefile", $queuefile); 

	$self->addPE($pe, $pefile, $slots);

	#$self->addPEToQueue($pe, $queue, $queuefile);

	$self->logDebug("Completed"); 
}

method getMonitor {
#### OVERRIDES Agua::Common::Cluster::getMonitor
	$self->logDebug("Agua::StarCluster::getMonitor()");

	return $self->monitor() if $self->monitor();
	my $classfile = "Agua/Monitor/" . uc($self->clustertype()) . ".pm";
	my $module = "Agua::Monitor::" . $self->clustertype();
	$self->logDebug("Doing require $classfile");
	require $classfile;
$self->logDebug("Instantiating my monitor = $module->new(...)");

	my $monitor = $module->new(
		{
			conf 		=>	$self->conf(),
			username	=>	$self->username(),
			cluster		=>	$self->cluster()
		}
	);
	$self->monitor($monitor);

	return $monitor;
}



method dump { 
	$self->logDebug();
    require Data::Dumper;
    $Data::Dumper::Maxdepth = shift if @_;
    print Data::Dumper::Dumper $self;
}

method _createVolume ($privatekey, $publiccert, $snapshot, $availzone, $size) {
	####	CREATE AN EBS VOLUME
    my $create_command = "ec2-create-volume --snapshot $snapshot -s $size -z $availzone -K ". $self->privatekey() . " -C " . $self->publiccert() . " | grep VOLUME | cut -f2";
	$self->logDebug("create_command", $create_command);
	my $volumeid = `$create_command`;
	$self->logDebug("volumeid", $volumeid);

	return $volumeid;
}

method generateKeypair () {
#### GENERATE A KEYPAIR USING PRIVATE AND PUBLIC KEYS

	#### SET DEFAULT KEYNAME
	my $username 	=	$self->username();
	my $privatekey	=	$self->privatekey();
	my $publiccert	=	$self->publiccert();
	$self->logDebug("username", $username);
	
	my $keyname = $self->keyname();
	$keyname = "$username-key" if not $keyname;
	$self->keyname($keyname);
	$self->logDebug("privatekey", $privatekey);
	$self->logDebug("publiccert", $publiccert);
	$self->logDebug("username", $username);
	$self->logDebug("keyname", $keyname);

	#### PRINT HELP
	if ( defined $self->help() ) {
		print qq{

		$0 start <--privatekey String> <--publiccert String> [--help]
		
		--privatekey 	Location of private key
		--privatecert 	Location of public key
		--username		Name of user 
		--keyname		Name of key
		--help			Print help info
};
	}
	
	#### SET KEYPAIR FILE
	my $keypairfile		=	$self->keypairfile();
	my ($keypairdir)	=	$keypairfile =~ /^(.+)\/[^\/]+$/;
	`mkdir -p $keypairdir` if not -d $keypairdir;
	$self->logError("can't create keypairdir: $keypairdir") and exit if not -d $keypairdir;

	#### DELETE KEYPAIR
	$self->deleteKeypair($privatekey, $publiccert, $keyname);
	
	##### PAUSE AWS PROMULGATION OF KEYPAIR DELETION
	#my $seconds = 5;
	#$self->logDebug("Pausing after deleteKeyPair: $seconds seconds");
	
	#### ADD KEYPAIR
	$self->addKeypair($privatekey, $publiccert, $keyname, $keypairfile);
}

method deleteKeypair ($privatekey, $publiccert, $keyname) {
	my $errorfile = "/tmp/ec2-delete-keypair.$$.err";
	my $delete = qq{ec2-delete-keypair \\
-K $privatekey \\
-C $publiccert \\
id_rsa-$keyname  2>&1 	> $errorfile};
	$self->logDebug("$delete");
	my $output = `$delete`;
	my $length = 150;
	$output = $self->shortenString($output, $length);
	
	$self->logDebug("Problem deleting keypair from EC2: $output") if $output ne '';
	$self->logDebug("Completed deleting keypair from EC2") if $output eq '';
}

method addKeypair ($privatekey, $publiccert, $keyname, $keypairfile) {
	my $errorfile = "/tmp/ec2-add-keypair.$$.err";
	my $add = qq{ec2-add-keypair \\
-K $privatekey \\
-C $publiccert \\
id_rsa-$keyname \\
1> $keypairfile 2> $errorfile
};
	$self->logDebug("$add");
	my $output = `$add`;
	my $length = 150;
	$output = $self->shortenString($output, $length);

	$self->logError("Problem adding keypair to EC2: $output") and exit if $output ne '';
	$self->logDebug("Completed add keypair to EC2") if $output eq '';
}

method shortenString ($string, $length) {
	$self->logDebug("string", $string);
	$self->logDebug("length", $length);

	$string =~ s/\n//g;
    my $templength = length($string);
	$string = substr($string, 0, $length);
	$string .= "..." if $templength > $length;

	$self->logDebug("Returning string", $string);
	return $string;
}







method getopts {
	my @temp = @ARGV;
	my $args = $self->args();

	my $olderr;
	#open $olderr, ">&STDERR";	
	#open(STDERR, ">/dev/null") or die "Can't redirect STDERR to /dev/null\n";
	no warnings;

	my $options = Getopt::Simple->new();
	$options->getOptions($args, "Usage: blah blah blah");
	
	
	#open STDERR, ">&", $olderr;
	use warnings;

	my $switch = $options->{switch};
	foreach my $key ( keys %$switch )
	{
		$self->$key($switch->{$key}) if defined $switch->{$key};
	}

	@ARGV = @temp;

	$self->logDebug("help:			", $self->help());
	$self->logDebug("privatekey:	", $self->privatekey());
	$self->logDebug("publiccert:	", $self->publiccert());
	$self->logDebug("keyname: 		", $self->keyname());
	$self->logDebug("username:		", $self->username());
	$self->logDebug("cluster: 		", $self->cluster());
	$self->logDebug("nodes: 		", $self->nodes());
	$self->logDebug("maxnodes: 		", $self->maxnodes());
	$self->logDebug("minnodes: 		", $self->minnodes());
	$self->logDebug("configfile: 	", $self->configfile());

}

method args {
	my $meta = $self->meta();

	my %option_type_map = (
		'Bool'     => '!',
		'Str'      => '=s',
		'Int'      => '=i',
		'Num'      => '=f',
		'ArrayRef' => '=s@',
		'HashRef'  => '=s%',
		'Maybe'    => ''
	);
	
	my $attributes = $self->fields();
	my $args = {};
	foreach my $attribute_name ( @$attributes )
	{
		my $attr = $meta->get_attribute($attribute_name);
		my $attribute_type  = $attr->{isa};
		$attribute_type =~ s/\|.+$//;
		$args -> {$attribute_name} = {  type => $option_type_map{$attribute_type}  };
	}
	return $args;
}



}	#### class Agua::StarCluster



