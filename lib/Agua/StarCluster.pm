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
	Agua::Common::Cluster,
	Agua::Common::SGE,
	Agua::Common::Ssh,
	Agua::Common::Util,
	Agua::Common::Database,
	Agua::Common::Logger) {

use FindBin::Real;
use lib FindBin::Real::Bin() . "/lib";

#### INTERNAL MODULES
use Agua::StarCluster::Instance;
use Agua::DBaseFactory;
use Conf::Yaml;
use Conf::StarCluster;

#### EXTERNAL MODULES
use Data::Dumper;
use File::Path;
use Getopt::Simple;

#### BALANCER VARIABLES
has 'interval'	=> ( 'isa' => 'Int', is  => 'rw', required	=>	0, default => 30	);
has 'waittime'	=> ( 'isa' => 'Int', is  => 'rw', required	=>	0, default => 100	);
has 'stabilisationtime'	=> ( 'isa' => 'Int', is  => 'rw', required	=>	0, default => 30	);
has 'sleepinterval'	=> ( 'isa' => 'Int', is  => 'rw', required	=>	0, default => 30	);


#### Boolean
has 'loaded'		=> ( isa => 'Bool', is => 'rw', default => 0 );  
has 'help'			=> ( isa => 'Bool', is  => 'rw', required	=>	0, documentation => "Print help message"	);

#### Int
has 'log'		=> ( isa => 'Int', is => 'rw', default 	=> 2 );  
has 'printlog'		=> ( isa => 'Int', is => 'rw', default 	=> 5 );
has 'sleep'			=> ( isa => 'Int', is => 'rw', default	=>	600	);
has 'workflowpid'	=> ( isa => 'Int', is => 'rw', required	=>	0	);
has 'tailwait'		=> ( isa => 'Int', is => 'rw', required	=>	0, default => 30	);
has 'slots'			=> ( isa => 'Int', is => 'rw', required	=>	0, default => 1	);
has 'pid'			=> ( isa => 'Int', is => 'rw', default	=>	0 );  

#### String
has 'nodes'			=> ( isa => 'Str', is  => 'rw', required	=>	0	);
has 'maxnodes'		=> ( isa => 'Str|Undef', is  => 'rw', required	=>	0	);
has 'minnodes'		=> ( isa => 'Str|Undef', is  => 'rw', required	=>	0	);
has 'logfile'		=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'conffile'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'configfile'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'queue'			=> ( isa => 'Str|Undef', is  => 'rw', required	=>	0	);
has 'sgeroot'		=> ( isa => 'Str', is  => 'rw', default => "/opt/sge6"	);
has 'sgecell'		=> ( isa => 'Str', is  => 'rw', required	=>	0	);
has 'fileroot'		=> ( isa => 'Str', is  => 'rw', required	=>	0	);
has 'whoami'  		=> ( isa => 'Str|Undef', is => 'rw' );
has 'username'		=> ( isa => 'Str', is  => 'rw', required	=>	0	);
has 'requestor'		=> ( isa => 'Str', is  => 'rw', required	=>	0	);
has 'clustertype'	=> ( isa => 'Str', is  => 'rw', default		=>	"SGE"	);
#has 'keyname'		=> ( isa => 'Str', is  => 'rw', required	=>	0	);
has 'keyname'	=> ( isa => 'Str', is  => 'rw', lazy	=> 1, builder => "setKeyName"	);
has 'keyfile'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'launched'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'running'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'cluster'		=> ( isa => 'Str|Undef', is  => 'rw', required	=>	0	);
has 'clusteruser'	=> ( isa => 'Str', is  => 'rw', default	=> "sgeadmin"	);
has 'availzone'		=> ( isa => 'Str', is  => 'rw', required	=>	0	);
has 'instancetype'	=> ( isa => 'Str|Undef', is  => 'rw', required	=>	0	);
has 'instanceid'	=> ( isa => 'Str|Undef', is  => 'rw', required	=>	0	);
has 'amiid'			=> ( isa => 'Str', is  => 'rw', required	=>	0	);
has 'executable'	=> ( isa => 'Str|Undef', is  => 'rw', required	=>	0	);
has 'plugins'		=> ( isa => 'Str', is  => 'rw', default	=> "automount,sge,startup"	);
has 'amazonuserid'	=> ( isa => 'Str|Undef', is  => 'rw', required	=>	0	);
has 'awsaccesskeyid'	=> ( isa => 'Str|Undef', is  => 'rw', required	=>	0	);
has 'awssecretaccesskey'=> ( isa => 'Str|Undef', is  => 'rw', required	=>	0	);
has 'privatekey'	=> ( isa => 'Str', is  => 'rw', required	=>	0	);
has 'publiccert'	=> ( isa => 'Str', is  => 'rw', required	=>	0	);
#has 'keypairfile'	=> ( isa => 'Str|Undef', is  => 'rw', required	=>	0	);
has 'keypairfile'	=> ( isa => 'Str', is  => 'rw', lazy	=> 1, builder => "setKeypairFile"	);
#has 'outputdir'		=> ( isa => 'Str|Undef', is  => 'rw', default 	=>	undef	);
has 'outputdir'	=> ( isa => 'Str', is  => 'rw', lazy	=> 1, builder => "setOutputDir"	);
has 'sources'		=> ( isa => 'Str|Undef', is  => 'rw', default 	=>	undef	);
has 'mounts'		=> ( isa => 'Str|Undef', is  => 'rw', default 	=>	undef	);
has 'devs'			=> ( isa => 'Str|Undef', is  => 'rw', default 	=>	undef	);
has 'configfile'	=> ( isa => 'Str', is  => 'rw', lazy	=> 1, builder => "setConfigFile"	);
#has 'outputfile'	=> ( isa => 'Str', is  => 'rw'	);
has 'outputfile'	=> ( isa => 'Str', is  => 'rw', lazy	=> 1, builder => "setOutputFile"	);
#has 'balancerfile'	=> ( isa => 'Str', is  => 'rw'	);
has 'balancerfile'	=> ( isa => 'Str', is => 'rw', lazy => 1, builder => "setBalancerFile" );


#### Object
has 'db'			=> ( isa => 'Agua::DBase::MySQL', is => 'rw', required => 0 );
has 'monitor'		=> ( isa => 'Maybe', is  => 'rw' );
has 'sourcedirs'	=> ( isa => 'ArrayRef[Str]', is  => 'rw' );
has 'mountpoints'	=> ( isa => 'ArrayRef[Str]', is  => 'rw' );
has 'devices'		=> ( isa => 'ArrayRef[Str]', is  => 'rw' );
has 'fields'    	=> ( isa => 'ArrayRef[Str|Undef]', is => 'ro', default => sub { ['help', 'amazonuserid', 'awsaccesskeyid', 'awssecretaccesskey', 'privatekey', 'publiccert', 'username', 'keyname', 'cluster', 'nodes', 'outputdir', 'maxnodes', 'minnodes', 'sources', 'mounts', 'devs', 'instancetype', 'availzone', 'amiid', 'configfile'] } );

has 'conf'	=> ( isa => 'Conf::Yaml', is => 'rw', lazy => 1, builder => "setConf" );
#has 'conf' 	=> (
#	is =>	'rw',
#	isa => 'Conf::Yaml',
#	default	=>	sub { Conf::Yaml->new( backup	=>	1, separator => "\t" );	}
#);

has 'config'=> (
	is 		=>	'rw',
	isa 	=> 'Conf::StarCluster',
	default	=>	sub { Conf::StarCluster->new( backup =>	1, separator => "="	);	}
);

has 'instance'=> (
	is 		=>	'rw',
	isa 	=> 'Agua::StarCluster::Instance',
	default	=>	sub { Agua::StarCluster::Instance->new({}); }
);

####/////}}}}}

=head2

	SUBROUTINE		BUILD
	
	PURPOSE

		GET AND VALIDATE INPUTS, AND INITIALISE OBJECT

=cut

method BUILD ($args) {
	$self->logDebug("DOING self->loadArgs()");
	$self->loadArgs($args);
	
	$self->logDebug("DOING self->getopts()");
	$self->getopts();
	
	$self->logDebug("DOING self->initialise()");
	$self->initialise();
}

method loadArgs ($args) {
	$self->logDebug("args", $args);

	#### IF HASH IS DEFINED, ADD VALUES TO SLOTS
	if ( defined $args ) {
		my @keys = keys %{$args};
		$self->logDebug("keys", \@keys);
		
		foreach my $key ( keys %{$args} ) {
			#$self->logDebug("CHECKING key $key");
			$args->{$key} = $self->unTaint($args->{$key});
			my $ref = ref $args->{$key};
			my $isobject = 1;
			$isobject = 0 if not $ref;
			$isobject = 0 if $ref eq "HASH";
			$isobject = 0 if $ref eq "ARRAY";
			$self->logDebug("ADDING key $key", $args->{$key}) if not $isobject;
			$self->logDebug("ADDING key $key: $args->{$key}") if $isobject;
			$self->$key($args->{$key}) if $self->can($key);
		}
	}

    $self->logDebug("Completed");
}

method load ($args) {
	$self->logDebug("");
	#$self->logDebug("args", $args);

	#$self->logDebug("DOING self->clear()");
	#$self->clear();
	
	$self->logDebug("DOING self->loadArgs()");
	$self->loadArgs($args);
	
	$self->logDebug("DOING self->initialise()");
	$self->initialise();

	$self->loaded(1);

	return $self;
}

method clear {
	#### GET ATTRIBUTES
	my $meta = Agua::StarCluster->meta();
	my $attributes;
	@$attributes = $meta->get_attribute_list();
	$self->logDebug("attributes", $attributes);

	#### RESET TO DEFAULT OR CLEAR ALL ATTRIBUTES
	foreach my $attribute ( @$attributes ) {
        next if $attribute eq "log";
        next if $attribute eq "printlog";
        next if $attribute eq "db";
        
		my $attr = $meta->get_attribute($attribute);
		my $required = $attr->is_required;
		$required = "undef" if not defined $required;
		my $default 	= $attr->default;
		my $isa  		= $attr->{isa};
		$isa =~ s/\|.+$//;		
		my $ref = ref $default;
		my $value 		= $attr->get_value($self);
		$self->logDebug("$attribute: $isa value", $value);
		next if not defined $value;

		if ( not defined $default ) {
			$self->logDebug("CLEARING NO-DEFAULT ATTRIBUTE $attribute: $isa value", $value);
			$attr->clear_value($self);
		}
		else {
			#$self->logDebug("SETTING VALUE TO DEFAULT", $default);
			if ( $ref ne "CODE" ) {
				$self->logDebug("SETTING TO DEFAULT ATTRIBUTE $attribute: $isa value", $value);
				$attr->set_value($self, $default);
			}
			else {
				$self->logDebug("SETTING TO DEFAULT CODE ATTRIBUTE $attribute: $isa value", $value);
				$attr->set_value($self, &$default);
			}
		}
		$self->logNote("CLEARED $attribute ($isa)", $attr->get_value($self));
	}

	$self->loaded(0);
}

method initialise {
	my $username 	= 	$self->username();
	my $cluster 	= 	$self->cluster();
	$self->logDebug("username", $username);
	$self->logDebug("cluster", $cluster);
	$self->logDebug("username not defined") and return if not defined $username;
	$self->logDebug("cluster not defined") and return if not defined $cluster;
		
	#### SET STARCLUSTER LOCATION
	$self->executable($self->conf()->getKey("agua", "STARCLUSTER"));
	
	#### SET Conf::Yaml INPUT FILE IF DEFINED
	$self->conf()->inputfile($self->conffile()) if $self->conffile();

	#### SET Conf::StarCluster INPUT FILE
	my $configfile = $self->setConfigFile($username, $cluster) if not defined $self->configfile();
	$self->config()->inputfile($configfile);
	$self->logDebug("configfile", $configfile);
	
	##### SET OUTPUT FILE FOR CLUSTER START & BALANCER
	#$self->setBalancerFile() if not $self->balancerfile();
	#my $balancerfile = $self->balancerfile();
	#$self->logDebug("balancerfile", $balancerfile);
	
	##### SET KEYPAIR FILE IF NOT DEFINED
	#$self->logDebug("Doing self->setKeypairFile()");
	#$self->setKeypairFile() if not $self->keypairfile();
	#$self->logDebug("self->keypairfile(): " . $self->keypairfile());	
}

method setKeyName {
	### USE ADMIN KEY IF USER IS IN ADMINUSER LIST
	my $username	=	$self->username();
	my $adminkey 	=	$self->getAdminKey($username);
	$self->logDebug("adminkey", $adminkey);
	
	my $keyname = "$username-key";
	$keyname = "admin-key" if $adminkey;
	
	return $self->keyname($keyname);
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
	foreach my $key ( keys %$switch ) {
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
	foreach my $attribute_name ( @$attributes ) {
		my $attr = $meta->get_attribute($attribute_name);
		next if not $attr;

		my $attribute_type  = $attr->{isa};
		$attribute_type =~ s/\|.+$//;
		$args -> {$attribute_name} = {  type => $option_type_map{$attribute_type}  };
	}
	return $args;
}



#### START CLUSTER
method startCluster {
#### 1. TERMINATE CLUSTER+BALANCER AND START CLUSTER
#### 2. RETURN 1 ON SUCCESS, 0 ON FAILURE

	$self->logDebug("");

	my $username 	= $self->username();
	my $project 	= $self->project();
	my $workflow 	= $self->workflow();
	my $cluster 	= $self->cluster();
	my $configfile 	= $self->configfile();
	my $executable  = $self->executable();
	my $outputdir 	= $self->outputdir();
	
	$self->logDebug("executable", $executable);
	$self->logError("username not defined") and exit if not $username;
	$self->logError("cluster not defined") and exit if not $cluster;
	$self->logError("configfile not defined") and exit if not $configfile;
	$self->logError("executable not defined") and exit if not $executable;
	$self->logError("outputdir not defined") and exit if not $outputdir;

	#### CLEAN UP PREVIOUS CLUSTER INSTANCE IF EXISTS:
	#### TERMINATE CLUSTER AND REMOVE SECURITY GROUP FROM AWS
	$self->terminateCluster(undef, undef);
	
	#### START CLUSTER
	my $started = $self->launchCluster();
	$self->logDebug("started", $started);
	#$self->logError("Could not start cluster", $cluster) and exit if not $started;

	return $started;
}

method isRunning {
#### CONFIRM CLUSTER IS RUNNING AND HAS NODES
	$self->logCaller("");
	my $username 	=	$self->username();
	my $cluster 	=	$self->cluster();
	my $configfile 	= 	$self->setConfigFile($username, $cluster);
	my $executable 	=	$self->conf()->getKey("agua", "STARCLUSTER");	
	$self->logDebug("cluster", $cluster);
	$self->logDebug("configfile", $configfile);
	$self->logDebug("executable", $executable);
	
	$self->instance()->load({
		cluster	    =>	$cluster,
		executable	=>	$executable,
		configfile	=>	$configfile,
		log		=>	$self->log()
	});
	
	my $running = $self->instance()->isRunning();
	$running = 0 if not defined $running;

	$self->logDebug("running", $running);
	return $running;	
}

method launchCluster {
	my $username 	= $self->username();
	my $cluster 	= $self->cluster();
	my $configfile 	= $self->configfile();
	my $executable  = $self->executable();
	my $outputdir 	= $self->outputdir();

	$self->logDebug("username", $username);
	$self->logDebug("cluster", $cluster);
	$self->logDebug("configfile", $configfile);
	$self->logDebug("executable: $executable");
	$self->logDebug("outputdir", $outputdir);

	#### CHECK INPUTS
	$self->logDebug("username not defined") and exit if not defined $username;
	$self->logDebug("cluster not defined") and exit if not defined $cluster;
	$self->logDebug("configfile not defined") and exit if not defined $configfile;
	$self->logDebug("executable not defined") and exit if not defined $executable;
	$self->logDebug("outputdir not defined") and exit if not defined $outputdir;
	
	#### CREATE OUTPUT DIR
	File::Path::mkpath($outputdir) if not -d $outputdir;
	$self->logDebug("outputdir: " . $outputdir);
	$self->logError("Can't create outputdir: $outputdir") and exit if not -d $outputdir;

	#### CREATE CONFIG FILE
	$self->createConfig();

	#### NB: MUST CHANGE TO CONFIGDIR FOR PYTHON PLUGINS TO BE FOUND
	my ($configdir) = $configfile =~ /^(.+?)\/[^\/]+$/;
	$self->logDebug("configdir", $configdir);

	#### SET START CLUSTER COMMAND
	my $outputfile = $self->outputfile();
	$self->logDebug("outputfile", $outputfile);
	if ( -f $outputfile ) {
		my $command = "rm -fr $outputfile";
		$self->logDebug("command", $command);
		`$command`;
	}
	
	my $command = "cd $configdir/plugins; $executable -c $configfile --logfile $outputfile start $cluster";
	$command .= " -s " . $self->nodes() if $self->nodes() and not $self->minnodes();	
	$self->logDebug("command", $command);
	
	#$command = "sleep 30";
	
	my $pid = fork();
	if ( not defined $pid or $pid == 0 ) {	
		$self->logDebug("EXECUTING COMMAND", $command);
		system($command);
	}
	else {
		$self->logDebug("AFTER FORK (PARENT) pid", $pid);
	
		##### SET PID
		#$self->pid($pid);
	
		#### RETURN PID WAIT FOR CLUSTER TO COMPLETE STARTUP
		return $self->fileTail({
			file	=>	$outputfile,
			found	=>	"The cluster has been started and configured",
			error	=>	"!!! ERROR - EBS Cluster 'admin-microcluster' already exists.",
			pause	=>	1,
			maxwait	=>	$self->tailwait()
		});
	}
	
	wait;
	
	exit(0);
}
method clusterLog ($lines) {
	my $cluster = $self->cluster();
	my $outputfile = $self->outputfile();
	$self->logDebug("outputfile", $outputfile);
	return "CLUSTER OUTPUT FILE NOT FOUND: $outputfile" if not -f $outputfile;
	$lines	=	30 if not defined $lines;
	my $tail = `tail -n$lines $outputfile`;

	$self->logDebug("BEFORE tail", $tail);
	$tail =~ s/^(Traceback|ValueError[^\n]+)\n//msg if defined $tail;
	$self->logDebug("AFTER tail", $tail);

	return $tail || "NO CLUSTER OUTPUT";
}
#### STOP CLUSTER
method stopCluster {
	$self->logDebug("");

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
	return if not $self->terminateCluster(undef, undef);

	#### STOP THE LOAD BALANCER
 	$self->logDebug("Doing self->terminateBalancer()");
	return $self->terminateBalancer();
}

method terminateCluster ($tries, $delay) {
#### RETURN 1 IF CLUSTER DOES NOT EXIST
#### OTHERWISE, TERMINATE CLUSTER:
####     - MULTIPLE RETRIES AFTER DELAY, RETURN 1 ON SUCCESS
####     - RETURN 0 ON FAILURE

	$self->logDebug("");

	my $cluster = $self->cluster();
	my $configfile = $self->configfile();
	my $executable = $self->executable();
	
	$self->logError("cluster not defined") and exit if not $cluster;
	$self->logError("configfile not defined") and exit if not $configfile;
	$self->logError("executable not defined") and exit if not $executable;
    
	#### DEFAULT NUMBER OF TRIES AND DELAY DURATION
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
	return 1 if $output =~ /!!! ERROR - cluster $cluster does not exist/;
	
	#### ENSURE THAT CLUSTER IS TERMINATED
	my $count = 0;
	while ( $count < $tries ) {	
		$count++;
		$self->logDebug($command);
		my $output = $self->captureStderr($command);
		$self->logDebug("output", $output);

		#### ERROR FORMAT:
		#### >>> Removing @sc-syoung-microcluster security group
		#### !!! ERROR - InvalidGroup.InUse: There are active instances using security group '@sc-syoung-microcluster'
		
		return 1 if $output !~ /There are active instances using security group/ms;
		sleep($delay);
	}

	return 0;
}

#### CONFIG FILE
method createConfig {
=head2

	SUBROUTINE		createConfig
	
	PURPOSE
	
		PRINT STARCLUSTER-FORMAT CONFIG FILE
		
	INPUTS
	
		privatekey 			Location of private key
		privatecert 		Location of public key
		amazonuserid 		AWS user ID
		awsaccesskeyid		AWS access key ID
		awssecretaccesskey 	AWS secret access key
		keyname				Name of keypair
		username			Change this user's config file
		help				Print help info
		cluster 			Name of cluster (e.g., microcluster) 
		nodes 				Number of nodes to begin with
		maxnodes 			Max. number of nodes (using load balancer)
		minnodes 			Min. number of nodes (using load balancer)
		outputdir 			Print load balancer STDOUT/STDERR to file in this directory
		sources 			Comma-separated list of source dirs (e.g., /data,/nethome)
		mounts 				Comma-separated list of mount points (e.g., /data,/nethome)
		devs 				Comma-separated list of devices (e.g., /dev/sdh,/dev/sdi)
		configfile 			Print config to this file (e.g., /nethome/admin/.starcluster/config)

=cut

	my $username 			= 	$self->username();	
	my $cluster 			= 	$self->cluster();
	my $amazonuserid		=	$self->amazonuserid();
	my $awsaccesskeyid		=	$self->awsaccesskeyid();
	my $awssecretaccesskey	=	$self->awssecretaccesskey();
	my $privatekey 			= 	$self->privatekey();
	my $publiccert 			= 	$self->publiccert();
	my $instancetype 		= 	$self->instancetype();
	my $availzone 			= 	$self->availzone();
	my $amiid 				= 	$self->amiid();
	my $conf 				= 	$self->conf();
	$self->logDebug("amazonuserid", $amazonuserid);
	$self->logDebug("awsaccesskeyid", $awsaccesskeyid);
	$self->logDebug("awssecretaccesskey", $awssecretaccesskey);
 	$self->logDebug("privatekey", $privatekey);
 	$self->logDebug("publiccert", $publiccert);

	#### CHECK INPUTS
	$self->logError("username not defined") and exit if not $self->username();
	$self->logError("cluster not defined") and exit if not $self->cluster();
	$self->logError("amazonuserid not defined") and exit if not $self->amazonuserid();
	$self->logError("awsaccesskeyid not defined") and exit if not $self->awsaccesskeyid();
	$self->logError("awssecretaccesskey not defined") and exit if not $self->awssecretaccesskey();
	$self->logError("privatekey not defined") and exit if not $self->privatekey();
	$self->logError("publiccert not defined") and exit if not $self->publiccert();
	$self->logError("instancetype not defined") and exit if not $self->instancetype();
	$self->logError("availzone not defined") and exit if not $self->availzone();
	$self->logError("amiid not defined") and exit if not $self->amiid();
	$self->logError("conf not defined") and exit if not $self->conf();
	$self->logError("configfile not defined") and exit if not $self->configfile();
	
	#### CREATE PLUGINS DIR AND COPY FILES IF NOT PRESENT
	$self->_createPluginsDir($username, $cluster);

	#### SET KEYPAIR FILE IF NOT DEFINED
	my $adminkey = $self->getAdminKey($username);
	$self->logDebug("adminkey", $adminkey);
	my $adminuser 		= 	$self->conf()->getKey("agua", "ADMINUSER");
	my $userdir 		= 	$self->conf()->getKey('agua', 'USERDIR');
	my $keypairfile		= 	"$userdir/$username/.starcluster/id_rsa-$username-key";
	$keypairfile		= 	"$userdir/$adminuser/.starcluster/id_rsa-admin-key" if $adminkey;
	$self->keypairfile($keypairfile);
	
	#### SET SOURCEDIRS, MOUNTPOINTS AND DEVICES
	$self->sources($self->conf()->getKey('starcluster:mounts', 'SOURCEDIRS')) if not defined $self->sources();
	$self->mounts($self->conf()->getKey('starcluster:mounts', 'MOUNTPOINTS')) if not defined $self->mounts();
	$self->devs($self->conf()->getKey('starcluster:mounts', 'DEVICES')) if not defined $self->devs();
	my @sourcedirs = 	split ",", 	$self->sources() 	|| () if $self->sources();
	my @mountpoints = 	split ",", 	$self->mounts() 	|| () if $self->mounts();
	my @devices = 		split ",", 	$self->devs() 		|| () if $self->devs();
	$self->sourcedirs(\@sourcedirs) if $self->sources();
	$self->mountpoints(\@mountpoints) if $self->mounts();
	$self->devices(\@devices) if $self->devs();
	
	#### SET NODES TO GREATER OF 1 OR minnodes
	$self->nodes(1);
	my $minnodes = $self->minnodes();
	$self->nodes($minnodes) if $self->nodes() < $minnodes;
	
	#### CREATE STARCLUSTER config FILE
	$self->logDebug("DOING self->_writeConfigFile");
	$self->writeConfigFile();
}

method writeConfigFile {
#### ADD KEYPAIR FILE, AWS ACCESS IDs AND OTHER CREDENTIAL
#### INFO TO USER'S CLUSTER CONFIG

	$self->logError("cluster not defined") if not defined $self->cluster();
	$self->logError("configfile not defined") if not defined $self->configfile();
	$self->logError("username not defined") if not defined $self->username();
	$self->logError("amazonuserid not defined") if not defined $self->amazonuserid();
	$self->logError("awsaccesskeyid not defined") if not defined $self->awsaccesskeyid();
	$self->logError("awssecretaccesskey not defined") if not defined $self->awssecretaccesskey();
	$self->logError("privatekey not defined") if not defined $self->privatekey();
	$self->logError("publiccert not defined") if not defined $self->publiccert();
	$self->logError("keyname not defined") if not defined $self->keyname();
	$self->logError("sources not defined") if not defined $self->sources();
	$self->logError("mounts not defined") if not defined $self->mounts();
	$self->logError("devs not defined") if not defined $self->devs();
	$self->logError("instancetype not defined") if not defined $self->instancetype();
	$self->logError("nodes not defined") if not defined $self->nodes();
	$self->logError("availzone not defined") if not defined $self->availzone();
	$self->logError("amiid not defined") if not defined $self->amiid();
	$self->logError("qmasterport not defined") if not defined $self->qmasterport();
	$self->logError("execdport not defined") if not defined $self->execdport();
	
	my $amazonuserid	=	$self->amazonuserid();
	my $awsaccesskeyid	=	$self->awsaccesskeyid();
	my $awssecretaccesskey	=	$self->awssecretaccesskey();
	$self->logDebug("username: " . $self->username());
	$self->logDebug("cluster: " . $self->cluster());
	$self->logDebug("configfile: " . $self->configfile());
	$self->logDebug("privatekey: " . $self->privatekey());
	$self->logDebug("publiccert: " . $self->publiccert());
	$self->logDebug("amazonuserid: " . $self->amazonuserid());
	$self->logDebug("awsaccesskeyid: " . $self->awsaccesskeyid());
	$self->logDebug("awssecretaccesskey: " . $self->awssecretaccesskey());
	$self->logDebug("keyname: " . $self->keyname());	
	$self->logDebug("sources: " . $self->sources());
	$self->logDebug("mounts: " . $self->mounts());
	$self->logDebug("devs: " . $self->devs());
	$self->logDebug("instancetype: " . $self->instancetype());
	$self->logDebug("nodes: " . $self->nodes());
	$self->logDebug("availzone: " . $self->availzone());
	$self->logDebug("amiid: " . $self->amiid());
	$self->logDebug("qmasterport: " . $self->qmasterport());
	$self->logDebug("execdport: " . $self->execdport());
	
	#### CREATE CONFIG
	my $configfile	=	$self->configfile();
	my $config = Conf::StarCluster->new(
		separator	=>	"=",
		inputfile	=>	$configfile
	);

	#### GET INPUTS
	my $keypairfile	=	$self->keypairfile();
	my $conf 		= 	$self->conf();
	my $username 	= 	$self->username();
	my $cluster 	= 	$self->cluster();
	my $userdir 	= 	$conf->getKey('agua', "USERDIR");

	$self->logDebug("keypairfile", $keypairfile);
	$self->logDebug("found keypairfile")  if -f $keypairfile;
	$self->logDebug("Can't find keypairfile")  if not -f $keypairfile;

	#### SET [global]
	$config->setKey("global", "DEFAULT_TEMPLATE", $cluster);
	$config->setKey("global", "ENABLE_EXPERIMENTAL", "True");

	#### SET [cluster <clusterName>]
	$config->setKey("cluster:$cluster", "KEYNAME", "id_rsa-" . $self->keyname());
	$config->setKey("cluster:$cluster", "AVAILABILITY_ZONE", $self->availzone());
	$config->setKey("cluster:$cluster", "CLUSTER_SIZE", $self->nodes());
	$config->setKey("cluster:$cluster", "CLUSTER_USER", $self->clusteruser());
	$config->setKey("cluster:$cluster", "NODE_IMAGE_ID", $self->amiid());
	$config->setKey("cluster:$cluster", "NODE_INSTANCE_TYPE", $self->instancetype());
	$config->setKey("cluster:$cluster", "CLUSTER_USER", $self->clusteruser());
	$config->setKey("cluster:$cluster", "PLUGINS", $self->plugins());
	
	#### SET [aws info]
	$config->setKey("aws:info", "AWS_USER_ID", $self->amazonuserid());
	$config->setKey("aws:info", "AWS_ACCESS_KEY_ID", $self->awsaccesskeyid());
	$config->setKey("aws:info", "AWS_SECRET_ACCESS_KEY", $self->awssecretaccesskey());	

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
	$config->setKey("plugin:automount", "interval", $self->sleepinterval()) if $self->sleepinterval();
	$config->setKey("plugin:automount", "mountpoints", $self->mounts()) if $self->mounts();
	$config->setKey("plugin:automount", "sourcedirs", $self->sources()) if $self->sources();
	
	$self->logDebug("privatekey", $privatekey);
	$self->logDebug("portmapport", $portmapport);
	$self->logDebug("nfsport", $nfsport);
	$self->logDebug("mountdport", $mountdport);
	$self->logDebug("devs: " . $self->devs());
	$self->logDebug("mounts: " . $self->mounts());
	$self->logDebug("sleepinterval: " . $self->sleepinterval());
	$self->logDebug("self->instancetype(), $self->instancetype()");

	#### SET sge PLUGIN
	my $slots = $self->setSlotNumber($self->instancetype());
	my $qmasterport = 	$self->qmasterport();
	my $execdport	=	$self->execdport();
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
	
	my $instanceid = $self->setInstanceId();
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

method setInstanceId {
	return $self->instanceid() if defined $self->instanceid();
	my $command = "curl --connect-timeout 8 -s http://169.254.169.254/latest/meta-data/instance-id";
	$self->logDebug("command", $command);
	my $instanceid 	= `$command`;
	
	return $instanceid || '';
}
#### CREATE VOLUME
method _createVolume ($privatekey, $publiccert, $snapshot, $availzone, $size) {
	####	CREATE AN EBS VOLUME
    my $create_command = "ec2-create-volume --snapshot $snapshot -s $size -z $availzone -K ". $self->privatekey() . " -C " . $self->publiccert() . " | grep VOLUME | cut -f2";
	$self->logDebug("create_command", $create_command);
	my $volumeid = `$create_command`;
	$self->logDebug("volumeid", $volumeid);

	return $volumeid;
}

#### KEYPAIR FILE
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
	my $keypairfile		=	$self->setKeypairFile($username);
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

#### CLUSTER
sub setOutputDir {
	my $self		=	shift;
	$self->logCaller("");

	my $username	=	$self->username();
	$self->logDebug("username", $username);

	my $outputdir = $self->setStarClusterDir($username);
	
	return $outputdir;
}

#### BALANCER
method balancerRunning {
	$self->logDebug("");

	my $username 	= $self->username();
	my $cluster 	= $self->cluster();
	my $configfile 	= $self->configfile();

	$self->logDebug("username", $username);
	$self->logDebug("cluster", $cluster);
	$self->logDebug("configfile", $configfile);
	
	#### SANITY CHECK	
	$self->logError("username not defined") and return if not defined $username;
	$self->logError("cluster not defined") and return if not defined $cluster;
	$self->logError("configfile not defined") and return if not defined $configfile;

	#### SET START BALANCER COMMAND STUB
	my $executable = $self->conf()->getKey("agua", "STARCLUSTER");
	my $command = "$executable -c $configfile bal $cluster";

	my $pid = $self->pid();
	$self->logDebug("pid: **$pid**");
	return 0 if not $pid;

	#### MATCH BY COMMAND AND THEN PID	
	my $ps = qq{ps aux | grep "$command"};
	$self->logDebug("ps", $ps);
	my $running = `$ps`;
	$self->logDebug("running", $running);
	my @lines = split "\n", $running;
	$self->logDebug("lines: " . $#lines);
	for ( my $i = 0; $i < $#lines + 1; $i++ ) {
		$self->logDebug("lines[$i]", $lines[$i]);
		my @elements = split " ", $lines[$i];
		$self->logDebug("elements[1]: **$elements[1]**");
		$self->logDebug("returning 1")  if $pid == $elements[1];
		
		return 1 if $pid == $elements[1];
	}
	
	$self->logDebug("returning 0");
	return 0;
}

method startBalancer {
#### 1. TERMINATE BALANCER IF EXISTS
#### 2. START NEW BALANCER 
#### 3. RETURN PID OF NEW BALANCER

	$self->logDebug("self->pid", $self->pid());

	#### TERMINATE BALANCER IF EXISTS
	$self->terminateBalancer() if $self->pid();

	#### LAUNCH BALANCER AND RETURN PID	
	my $pid = $self->launchBalancer();
	$self->logDebug("pid", $pid);
	return if not defined $pid;

	$self->pid($pid);
}

method launchBalancer {
	my $username = $self->username();
	my $cluster = $self->cluster();
	my $minnodes = $self->minnodes();
	my $maxnodes = $self->maxnodes();
	my $balancerfile = $self->balancerfile();
	$self->logDebug("username not defined") and exit if not defined $username;
	$self->logDebug("cluster not defined") and exit if not defined $cluster;
	$self->logDebug("minnodes not defined") and exit if not defined $minnodes;
	$self->logDebug("maxnodes not defined") and exit if not defined $maxnodes;
	$self->logDebug("balancerfile not defined") and exit if not defined $balancerfile;
	$self->logDebug("maxnodes not defined") and exit if not defined $maxnodes;
	
	#### SET Conf::StarCluster CONFIGFILE
	my $configfile = $self->setConfigFile($username, $cluster);

	#### GET executable EXECUTABLE
	my $executable = $self->conf()->getKey("agua", "STARCLUSTER");
	
	$self->logDebug("executable", $executable);
	$self->logDebug("balancerfile", $balancerfile);
	$self->logDebug("username", $username);
	$self->logDebug("configfile", $configfile);
	$self->logDebug("minnodes", $minnodes);
	$self->logDebug("maxnodes", $maxnodes);	;
	
	#### CREATE A UNIQUE QUEUE FOR THIS WORKFLOW
	my $envars = $self->getEnvars($username, $cluster);
	
	#### SET STATUS, PID, ETC. IN clusterstatus TABLE
	#### START THE LOAD BALANCER
	my $command = $envars->{tostring};
	$command .= "$executable -c $configfile bal $cluster";
	$command .= " -m ". $maxnodes;
	$command .= " -n ". $minnodes;
	$command .= " -i ". $self->interval();
	$command .= " -w ". $self->waittime();
	$command .= " -s ". $self->stabilisationtime();
	$command .= " --kill-master ";

	$self->logDebug("command", $command);
	
	#### NB: MUST CHANGE TO CONFIGDIR FOR PYTHON PLUGINS TO BE FOUND
	my ($configdir) = $configfile =~ /^(.+?)\/[^\/]+$/;
	$self->logDebug("configdir", $configdir);
	
	my $pid = fork();
	$self->logDebug("pid", $pid);
	if ( not defined $pid or $pid == 0 ) {	
		$self->logDebug("Running child");
		$self->logDebug("\$\$ pid", $$);
		$self->logDebug("Doing exec(cd $configdir/plugins; $command)");
	
		#### REDIRECT STDOUT AND STDERR TO OUTPUTFILE
		$self->logDebug("Redirecting STDOUT and STDERR to balancerfile", $balancerfile);
		open(STDOUT, ">>$balancerfile") or die "Agua::Common::Balancer::launchBalancer    Can't redirect STDOUT to balancerfile: $balancerfile\n";
		open(STDERR, ">>$balancerfile") or die "Agua::Common::Balancer::launchBalancer    Can't redirect STDERR to balancerfile: $balancerfile\n";
	
		chdir("$configdir/plugins");
		exec("$command");
	}
	else {
		$self->logDebug("AFTER FORK (PARENT) pid", $pid);
	
		#### SET PID
		$self->pid($pid);
		
		return $pid;
	}	
}

method terminateBalancer {
	my $pid 		= $self->pid();
	$self->logDebug("pid", $pid);
	return 1 if not defined $pid;
	
	my $output = $self->killPid($pid);
	$self->logDebug("output", $output);

	return $output;
}

method balancerLog ($lines) {
	my $cluster = $self->cluster();
	my $balancerfile = $self->balancerfile();
	$self->logDebug("balancerfile", $balancerfile);
	return "CLUSTER OUTPUT FILE NOT FOUND: $balancerfile" if not -f $balancerfile;
	$lines	=	30 if not defined $lines;
	my $tail = `tail -n$lines $balancerfile`;

	$self->logDebug("BEFORE tail", $tail);
	$tail =~ s/^(Traceback|ValueError[^\n]+)\n//msg if defined $tail;
	$self->logDebug("AFTER tail", $tail);

	return $tail || "";
}


method setOutputFile {
	my $cluster		=	$self->cluster();
	my $outputdir	=	$self->outputdir();
	$self->logDebug("cluster", $cluster);
	$self->logDebug("outputdir: " . $outputdir);
	
	my $outputfile = "$outputdir/$cluster-STARCLUSTER.out";
	
	$self->outputfile($outputfile); 
}

method dumpObject ($depth) { 
	$self->logDebug();
    require Data::Dumper;
    $Data::Dumper::Maxdepth = $depth if defined $depth;
    print Data::Dumper::Dumper $self;
}






}	#### class Agua::StarCluster
