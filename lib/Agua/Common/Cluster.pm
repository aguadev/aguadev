package Agua::Common::Cluster;
use Moose::Role;
use Method::Signatures::Simple;

=head2

	PACKAGE		Agua::Common::Cluster
	
	PURPOSEgetMedaData.py
	
		CLUSTER METHODS FOR Agua::Common
		

	SUBROUTINE		addCluster
	
	PURPOSE

		ADD A CLUSTER TO THE cluster TABLE
        
		IF THE USER HAS NO AWS CREDENTIALS INFORMATION,
		
		USE THE 'admin' USER'S AWS CREDENTIALS AND STORE
		
		THE CONFIGFILE IN THE ADMIN USER'S .starcluster
		
		DIRECTORY

=cut
use Data::Dumper;
use File::Path;
use Conf::StarCluster;

#requires 'configfile';

has 'configfile'	=> ( is  => 'rw', 'isa' => 'Str|Undef', required	=>	0	);
has 'privatekey'	=> ( is  => 'rw', 'isa' => 'Str|Undef', required	=>	0, lazy	=> 1, builder => "getEc2PrivateFile" );
has 'publiccert'	=> ( is  => 'rw', 'isa' => 'Str|Undef', required	=>	0, lazy	=> 1, builder => "getEc2PublicFile"	);
has 'instancetypeslots' =>  ( isa => 'HashRef', is => 'ro', default => method {
	{
		"t1.micro"	=>	1,
		"m1.small"	=>  1,
		"m1.large"	=>	4,
		"m1.xlarge"	=>	8,
		"m2.xlarge"	=>	7,
		"m2.2xlarge"=>	13,
		"m2.4xlarge"=>	26,
		"c1.medium"	=>	5,
		"c1.xlarge"	=>	20,
		"cc1.4xlarge"=>	34,
		"cg1.4xlarge"=>	34
	}
});
#### http://aws.amazon.com/ec2/instance-types

#### BALANCER
method setBalancerFile {
	$self->logCaller("");

	my $username	=	$self->username();
	my $cluster		=	$self->cluster();
	$self->logDebug("username", $username);
	$self->logDebug("cluster", $cluster);
	
	my $outputdir	=	$self->setStarClusterDir($username, $cluster);
	$self->logDebug("outputdir: " . $outputdir);
	
	my $balancerfile = "$outputdir/$cluster-BALANCER.out";
	
	$self->balancerfile($balancerfile); 
}

#### CLUSTER
method setStarClusterDir ($username) {
	$self->logDebug("username", $username);
	
	#### GET USERDIR AND AGUADIR
	my $conf 		= 	$self->conf();
	my $userdir 	= 	$conf->getKey('agua', 'USERDIR');
	my $aguadir 	= 	$conf->getKey('agua', 'AGUADIR');
	my $adminkey 	= 	$self->getAdminKey($username);
	$self->logDebug("adminkey", $adminkey);
	return if not defined $adminkey;

	my $outputdir = "$userdir/$username/.starcluster";

	#### SET ADMIN USER OUTPUT DIR IF USER HAS ADMIN KEY ACCESS
	if ( $adminkey ) {
		my $adminuser = $self->conf()->getKey("agua", "ADMINUSER");
		$self->logDebug("adminuser", $adminuser);
		$outputdir = "$userdir/$adminuser/.starcluster";
	}
	$self->logDebug("outputdir", $outputdir);
	
	#### CREATE DIR IF NOT EXISTS
	`mkdir -p $outputdir` if not -d $outputdir;
	$self->logDebug("Can't create outputdir", $outputdir) if not -d $outputdir;

	#### CREATE PLUGINS DIR
	my $pluginsdir	=	"$outputdir/plugins";
	$self->logDebug("pluginsdir", $pluginsdir);
	`mkdir -p $pluginsdir` if not -d $pluginsdir;
	$self->logDebug("Can't create pluginsdir", $pluginsdir) if not -d $pluginsdir;
	
	$self->outputdir($outputdir);
}

method clusterIsBusy ($username, $cluster) {
	$self->logDebug("Agua::Common::Cluster::clusterIsBusy(username, cluster)");
	$self->logDebug("username", $username);
	$self->logDebug("cluster", $cluster);

	my $query = qq{SELECT 1 FROM clusterworkflow
WHERE username='$username'
AND cluster='$cluster'
AND status='running'};
	my $busy = $self->db()->query($query);
	$self->logDebug("busy", $busy)  if defined $busy;

	return 1 if defined $busy;
	return 0;
}

method getClusterVars ($username, $cluster) {
	$self->logDebug("username", $username);
	
	my $query = qq{SELECT * FROM clustervars
WHERE username='$username'
AND cluster='$cluster'};
	
	return $self->db()->queryhash($query);
}

method getClusterStatus ($username, $cluster) {
 	$self->logError("username not defined") and return if not defined $username;
 	$self->logError("cluster not defined") and return if not defined $cluster;

	my $query = qq{SELECT *
FROM clusterstatus
WHERE username='$username'
AND cluster='$cluster'};
	$self->logDebug("$query");

	return $self->db()->queryhash($query);
}

method getAdminKey ($username) { 	
	$self->logCaller("username", $username);
	$self->logError("username not defined") and return if not defined $username;

	return $self->adminkey() if $self->can('adminkey') and defined $self->adminkey();
	
	my $adminkey_names = $self->conf()->getKey('aws', 'ADMINKEY');
 	#$self->logDebug("adminkey_names", $adminkey_names);
	$adminkey_names = '' if not defined $adminkey_names;
	my @names = split ",", $adminkey_names;
	my $adminkey = 0;
	foreach my $name ( @names ) {
	 	#$self->logDebug("name", $name);
		if ( $name eq $username )	{	return $adminkey = 1;	}
	}

	$self->adminkey($adminkey) if $self->can('adminkey');
	
	return $adminkey;
}

method setConfigFile ($username, $cluster) {
	$self->logCaller();
	$self->logDebug("username", $username);
	$self->logDebug("cluster", $cluster);	
	$self->logDebug("self->conf()", $self->conf());

	$username = $self->username() if not defined $username;
	$cluster	= $self->cluster() if not defined $cluster;
	$cluster = "default" if not defined $cluster;
	
	my $userdir 	= 	$self->conf()->getKey('agua', 'USERDIR');
	my $adminkey 	= 	$self->getAdminKey($username);
	$self->logDebug("adminkey", $adminkey);
	
	my $configdir = "$userdir/$username/.starcluster";
	if ( $adminkey ) {
		my $adminuser = $self->conf()->getKey("agua", "ADMINUSER");
		#$self->logDebug("adminuser", $adminuser);
		$configdir = "$userdir/$adminuser/.starcluster";
	}
	#$self->logDebug("configdir", $configdir);
	my $whoami = $self->whoami();
	$self->logDebug("whoami", $whoami);
	
	#### CREATE DIR IF NOT EXISTS
	File::Path::mkpath($configdir) if not -d $configdir;
	$self->logDebug("Can't create configdir", $configdir) if not -d $configdir;

	my $configfile = "$configdir/$cluster.config";
	$self->logDebug("configfile", $configfile);
	$self->configfile($configfile);

	return $configfile;
}

method updateClusterNodes {
 	$self->logDebug("");
	
    my $json 			=	$self->json();
	my $query = qq{SELECT * FROM cluster
WHERE username='$json->{username}'
AND cluster='$json->{cluster}'
};
	$self->logDebug("$query");
	my $cluster = $self->db()->queryhash($query);
 	$self->logDebug("cluster", $cluster);
	
	$cluster->{minnodes} = $json->{minnodes};
	$cluster->{maxnodes} = $json->{maxnodes};
	
	my $success = $self->_removeCluster();	
	return if not defined $success;
 	$self->logError("Could not delete cluster $json->{cluster} from cluster table") and return if not $success;

	#### SET TABLE AND REQUIRED FIELDS	
	my $table = "cluster";
	my $required_fields = ["username", "cluster", "minnodes", "maxnodes", "instancetype", "amiid"];
	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $not_defined = $self->db()->notDefined($cluster, $required_fields);
    $self->logError("not defined: @$not_defined") and return if @$not_defined;

	#### DO ADD
	$success = $self->_addToTable($table, $cluster, $required_fields);	
	$self->logStatus("Could not add cluster $json->{cluster} into cluster table") if not $success;
	$self->logStatus("Successful insert of cluster $json->{cluster} into cluster table") if $success;
}

method _createPluginsDir ($username, $cluster) {
	$self->logDebug("username", $username);
	
	my $installdir 	=	$self->conf()->getKey("agua", "INSTALLDIR");
	my $userdir		=	$self->conf()->getKey("agua", "USERDIR");
	my $configfile	=	$self->setConfigFile($username, $cluster);
	my ($pluginsdir)=	$configfile =~ /^(.+?)\/[^\/]+$/;
	$pluginsdir .= "/plugins";
	$self->logDebug("pluginsdir", $pluginsdir);

	#### CREATE DIR
	`mkdir -p $pluginsdir` if not -d $pluginsdir;
	
	#### COPY FILES
	my $plugins = ["automount.py", "sge.py", "startup.py"];
	foreach my $plugin ( @$plugins ) {
		my $sourcefile = "$installdir/bin/scripts/resources/starcluster/plugins/$plugin";
		my $targetfile = "$pluginsdir/$plugin";
		$self->logDebug("sourcefile", $sourcefile);
		$self->logDebug("targetfile", $targetfile);
		
		`cp $sourcefile $targetfile` if not -f $targetfile;		
	}
}

method _isCluster ($username, $cluster) {
 	$self->logDebug("username", $username);

	my $json = $self->json();
	my $query = qq{SELECT 1 FROM cluster
WHERE username='$username'
AND cluster='$cluster'};
 	$self->logDebug("$query");
	my $is_cluster = $self->db()->query($query);
	
	return 0 if not defined $is_cluster or not $is_cluster;
	return 1;
}

method _addCluster {
	my $json 			=	$self->json();
	
	#### SET TABLE AND REQUIRED FIELDS	
	my $table = "cluster";
	my $required_fields = ["username", "cluster", "minnodes", "maxnodes", "instancetype", "amiid"];

	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $not_defined = $self->db()->notDefined($json, $required_fields);
    $self->logError("not defined: @$not_defined") and return if @$not_defined;

	#### DO ADD
	my $success = $self->_addToTable($table, $json, $required_fields);
	
	return $success if not defined $success or not $success;
	
	#### UPDATE DATETIME
	my $now = $self->db()->now();
	my $where = $self->db()->where($json, $required_fields);
	my $query = qq{UPDATE $table
SET datetime=$now
$where};
	$self->logDebug("now", $now);
	$self->db()->do($query);

	return $success;
}

method _createCellDir {
 	$self->logDebug("");	;
    my $json 			=	$self->json();
	
	#### SET TABLE AND REQUIRED FIELDS	
	my $username = $json->{username};
	my $cluster = $json->{cluster};

	#### ADD NEW CELL DIRECTORY TO HEAD NODE
	my $celldir = $self->getCellDir();
	my $defaultdir = $self->getDefaultCellDir();
	$self->logDebug("celldir", $celldir);
	my $copy = "cp -pr $defaultdir $celldir";
	if ( not -d $celldir )
	{
	 	$self->logDebug("copy", $copy);
		print `$copy`;

		my $chown = "chown -R sgeadmin:sgeadmin $celldir";
	 	$self->logDebug("chown", $chown);
		print `$chown`;
	}
	my $success = -d $celldir;
 	$self->logDebug("copyDir success", $success);

	return $success;
}

method getCellDir {
	my $json		=	$self->json();	
	my $cluster = $json->{cluster};
	my $sgeroot = $self->conf()->getKey('cluster', 'SGEROOT');
	
	return "$sgeroot/$cluster";	
}

method getDefaultCellDir {
	my $json		=	$self->json();	
	my $sgeroot = $self->conf()->getKey('cluster', 'SGEROOT');

	return "$sgeroot/default";
}

method removeCluster  {
 	$self->logDebug("");
	my $json 			=	$self->json();

	#### REMOVE FROM cluster
	my $success = $self->_removeCluster();
	return if not defined $success;
	$self->logError("Could not remove cluster $json->{cluster}") and return if not $success;

	#### REMOVE CELLDIR
	$success = $self->_removeCellDir();
	return if not defined $success;
 	$self->logDebug("_removeCellDir success", $success);

	#### REMOVE CLUSTER CONFIG FILE
	my $userdir = $self->conf()->getKey('agua', 'USERDIR');
	my $configfile = "$userdir/" . $self->username() . "/.starcluster/config";
	
	`rm -fr $configfile`;
	$self->logError("Can't remove cluster $json->{cluster} configfile: $configfile") and return if -f $configfile;

 	$self->logStatus("Removed cluster $json->{cluster}") if $success;
	return;
	
}	#### removeCluster

method _removeCluster {
	my $json 			=	$self->json();

	#### SET CLUSTER, TABLE AND REQUIRED FIELDS	
	my $cluster = $json->{cluster};
	my $table = "cluster";
	my $required_fields = ["username", "cluster"];

	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $not_defined = $self->db()->notDefined($json, $required_fields);
    $self->logError("undefined values: @$not_defined") and return if @$not_defined;

	#### REMOVE FROM cluster
	my $success = $self->_removeFromTable($table, $json, $required_fields);
 	$self->logDebug("_removeFromTable success", $success);
	return if not defined $success;
 	$self->logError("Could not remove cluster $cluster from cluster table") and return if not $success;

	#### REMOVE FROM clusterworkflow
	$self->_removeFromTable("clusterworkflow", $json, ["username", "cluster"]);
	
	#### REMOVE FROM clustervars
	$self->_removeFromTable("clustervars", $json, ["username", "cluster"]);
	
	#### REMOVE FROM clusterstatus
	$self->_removeFromTable("clusterstatus", $json, ["username", "cluster"]);
	
	return 1;
}

method _removeCellDir {
	$self->logDebug("");
	
	my $celldir = $self->getCellDir();
	$self->logDebug("Deleting celldir", $celldir);
	if ( -d $celldir )
	{
		my $remove = "rm -fr $celldir";
	 	$self->logDebug("copy", $remove);
		print `$remove`;
	}
	#### RETURNS '' IF CELL DIR IS STILL PRESENT, 1 IF ABSENT
	my $success = not (-d $celldir);
 	$self->logDebug("delete celldir success", $success);
	$self->logError("Could not delete celldir") and return if not $success;

	return $success;
}	#### _removeCellDir

method getClusters {
#### RETURN AN ARRAY OF cluster HASHES
	$self->logDebug("");

	my $json		=	$self->json();
	my $username	=	$self->username();

	#### GET ALL SOURCES
	my $query = qq{SELECT * FROM cluster
WHERE username='$username'
ORDER BY maxnodes ASC, cluster};
	$self->logDebug("$query");	;
	my $clusters = $self->db()->queryhasharray($query);

	#### SET TO EMPTY ARRAY IF NO RESULTS
	$clusters = [] if not defined $clusters;

	return $clusters;
}

method runningClusters ($username) {
    $self->logDebug("username", $username);

	my $query = qq{SELECT * FROM clusterstatus
WHERE status ='running'};
	$query .= " AND username = '$username'" if defined $username and $username;
	$self->logDebug("$query");	;
	my $clusters = $self->db()->queryhasharray($query);

	#### SET TO EMPTY ARRAY IF NO RESULTS
	$clusters = [] if not defined $clusters;

	return $clusters;	
}

method getCluster ($username, $cluster) {
	$self->logDebug("username", $username);

	#### GET ALL SOURCES
	my $query = qq{SELECT * FROM cluster
WHERE username='$username'
AND cluster='$cluster'};
	$self->logDebug("$query");	;
	
	return $self->db()->queryhash($query);
}

method getClusterWorkflow ($username, $project, $workflow) {
#### RETURN AN ARRAY OF clusterworkflow HASHES

	$self->logDebug("username", $username);
	$self->logDebug("project", $project);
	$self->logDebug("workflow", $workflow);

	#### GET ALL SOURCES
	my $query = qq{SELECT * FROM clusterworkflow
WHERE username='$username'
AND project='$project'
AND workflow='$workflow'};
	$self->logDebug("$query");	;
	my $clusterworkflow = $self->db()->queryhash($query);
	$clusterworkflow = {} if not defined $clusterworkflow;

	return $clusterworkflow;
}

method getClusterWorkflows {
#### RETURN AN ARRAY OF clusterworkflow HASHES
	$self->logDebug("");
	my $json	=	$self->json();
	my $username 	=	$self->username();
	$self->logDebug("username", $username);
	$username = $json->{username} if not defined $username and not $username and defined $json;

	#### GET ALL SOURCES
	my $query = qq{SELECT * FROM clusterworkflow
WHERE username='$username'
ORDER BY project, workflow};
	$self->logDebug("$query");	;
	my $clusters = $self->db()->queryhasharray($query);

	#### SET TO EMPTY ARRAY IF NO RESULTS
	$clusters = [] if not defined $clusters;

	return $clusters;
}

method getClusterByWorkflow ($username, $project, $workflow) {
#### RETURN THE CLUSTER FOR A GIVEN PROJECT WORKFLOW
	$self->logError("username not defined") and return if not defined $username;
	$self->logError("project not defined") and return if not defined $project;
	$self->logError("workflow not defined") and return if not defined $workflow;
	
	#### GET ALL SOURCES
	my $query = qq{SELECT cluster FROM clusterworkflow
WHERE username='$username'
AND project='$project'
AND workflow='$workflow'};
	$self->logDebug("$query");	;
	my $cluster = $self->db()->query($query);
	$self->logDebug("cluster", $cluster);

	return $cluster;
}

method saveClusterWorkflow {
#### ADD AN ENTRY OR UPDATE AN EXISTING ENTRY IN clusterworkflow TABLE
 	$self->logDebug("");
	
	my $json 			=	$self->json();

	#### GET OLD CLUSTER WORKFLOW IF EXISTS
	my $username = $self->username();
	my $project = $self->project();
	my $workflow = $self->workflow();
	my $cluster = $self->cluster();
	my $oldcluster = $self->getClusterByWorkflow($username, $project, $workflow);
	
 	$self->logDebug("username", $username);
 	$self->logDebug("project", $project);
 	$self->logDebug("workflow", $workflow);
 	$self->logDebug("cluster", $cluster);
 	$self->logDebug("oldcluster", $oldcluster);
	
	#### CHECK IF CLUSTER IS STARTED
	my $masterid = $self->getMasterId($username, $cluster);
	my $started = 1;
	$started = 0 if not defined $masterid;
	$self->logDebug("started", $started);
		
	#### IF NOT STARTED, JUST UPDATE clusterworkflow TABLE
	if ( not $started ) {
		#### REMOVE IF EXISTS ALREADY	
		my $success = $self->_removeClusterWorkflow();
		$self->logDebug("_removeClusterWorkflow success", $success);
		
		#### ADD THE NEW CLUSTER TO THE clusterworkflow TABLE
		$success = $self->_addClusterWorkflow();
		$self->logDebug("_addClusterWorkflow success", $success);

		$self->logError("Could not add workflow $workflow to cluster $json->{cluster}") and return if not $success;

		$self->logStatus("Added workflow $workflow to cluster $json->{cluster}");
		return;
	}

	#### RESTART SGE IF NOT RUNNING
	my $running = $self->checkSge($username, $cluster) if not $self->head()->ops()->qmasterRunning() or not $self->head()->ops()->execdRunning();
	$self->logDebug("running", $running);

	#### GET EXISTING QUEUE NAME AND QUEUE FILE LOCATION
	my $queue = $self->queueName($username, $project, $workflow);
	my $queuefile = $self->getQueuefile($queue);
 	$self->logDebug("queuefile", $queuefile);

	#### DELETE THE EXISTING CLUSTER ENTRY IN clusterworkflow TABLE
	if ( defined $oldcluster and $oldcluster and $oldcluster ne $cluster ) {
		#### REMOVE THE SGE QUEUE IN THE OLD CLUSTER
		my $success = $self->_removeQueue($queue, $queuefile, $running);
		$self->logDebug("_removeQueue success", $success);
	}
	
	#### QUIT IF JUST SETTING CLUSTER TO ''
	$self->logStatus("Successfully removed $oldcluster from clusterworkflow table") and return if defined $oldcluster and not $cluster;

	#### REMOVE IF EXISTS ALREADY	
	my $success = $self->_removeClusterWorkflow();
	$self->logDebug("_removeClusterWorkflow success", $success);
	
	#### ADD THE NEW CLUSTER TO THE clusterworkflow TABLE
	$success = $self->_addClusterWorkflow();
	return if not defined $success;
	$self->logError("Could not add cluster $json->{cluster}") and return if not $success;

	if ( $running ) {
		#### ADD NEW QUEUE TO WORKFLOW
		my $query = qq{SELECT instancetype
	FROM cluster
	WHERE username='$username'
	AND cluster='$cluster'};
		$self->logDebug("$query");
		my $instancetype = $self->db()->query($query);
		my $slots = $self->setSlotNumber($instancetype);
		my $parameters = { slots	=> $slots };
		$success = $self->_addQueue($queue, $queuefile, $parameters);
		$self->logDebug("_addQueue success", $success);
	}
	
	$self->logStatus("Added workflow $workflow to cluster $json->{cluster}");
}

method _addClusterWorkflow {
	my $json 			=	$self->json();
	$self->logDebug("json", $json);
    
	#### SET TABLE AND REQUIRED FIELDS	
	my $table = "clusterworkflow";
	my $required_fields = ["username", "project", "workflow", "cluster"];

	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $not_defined = $self->db()->notDefined($json, $required_fields);
    $self->logError("not defined: @$not_defined") and return if @$not_defined;

	#### DO ADD
	return $self->_addToTable($table, $json, $required_fields);	
}

method _removeClusterWorkflow {
 	$self->logDebug("");

    my $json 			=	$self->json();
    
	#### SET TABLE AND REQUIRED FIELDS	
	my $table = "clusterworkflow";
	my $required_fields = ["username", "project", "workflow"];

	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $not_defined = $self->db()->notDefined($json, $required_fields);
    $self->logError("undefined values: @$not_defined") and return if @$not_defined;

	#### REMOVE FROM cluster
	return $self->_removeFromTable($table, $json, $required_fields);
}	#### _removeClusterWorkflow

method getMonitor ($clustertype) {
	$self->logDebug("clustertype", $clustertype);

	return $self->monitor() if $self->monitor();

	$clustertype =  $self->conf()->getKey('agua', 'CLUSTERTYPE') if not defined $clustertype;
	my $classfile = "Agua/Monitor/" . uc($clustertype) . ".pm";
	my $module = "Agua::Monitor::$clustertype";
	$self->logDebug("Doing require $classfile");
	require $classfile;
$self->logDebug("Instantiating my monitor = $module->new(...)");

	my $monitor = $module->new(
		{
			'pid'		=>	$self->workflowpid(),
			'conf' 		=>	$self->conf(),
			'db'		=>	$self->db()
		}
	);
	$self->monitor($monitor);

	return $monitor;
}

method setSlotNumber ($instancetype) {
#### LOOK UP SLOTS BASED ON INSTANCETYPE
	$self->logDebug("instancetype", $instancetype);

	my $slots = $self->instancetypeslots()->{$instancetype};
	$self->logDebug("slots", $slots);

	return $slots;
}

method getMasterId ($username, $cluster) {
	$self->logDebug("username", $username);

	#### GET CLUSTER LIST
	my $clusterlist = $self->getClusterList($username, $cluster);
	$self->logDebug("clusterlist", $clusterlist);
	
    ####  FORMAT:    master running i-9edc26f3 ec2-174-129-54-141.compute-1.amazonaws.com 
	my ($masterid) = $clusterlist =~ /^.+?master\s+\S+\s+(\S+)/ms;
	$self->logDebug("masterid", $masterid);

	return $masterid;
}

method getMasterExternalFqdn ($username, $cluster) {
	$self->logDebug("username", $username);
	$self->logDebug("cluster", $cluster);

	#### GET CLUSTER LIST
	my $clusterlist = $self->getClusterList($username, $cluster);
	$self->logDebug("clusterlist", $clusterlist);
	
    ####  FORMAT:    master running i-9edc26f3 ec2-174-129-54-141.compute-1.amazonaws.com 
	my ($externalfqdn) = $clusterlist =~ /^.+?master\s+\S+\s+\S+\s+(\S+)/ms;
	$self->logDebug("externalfqdn", $externalfqdn);

	return $externalfqdn;
}

method getClusterList ($username, $cluster) {
	$self->logDebug("username", $username);

	#### SET CONFIG FILE
	my $configfile = $self->setConfigFile($username, $cluster);
	my $applications = $self->conf()->getKey("agua", "APPLICATIONS");
	my $executable = $self->conf()->getKey("agua", "STARCLUSTER");

	#### GET CLUSTER LIST
	my $command = "$executable -c $configfile listclusters $cluster";
	$self->logDebug("command", $command);
	my $clusterlist = `$command`;
	$self->logDebug("clusterlist", $clusterlist);
	
	return "" if not defined $clusterlist or not $clusterlist;
	return "" if $clusterlist =~ /!!! ERROR - cluster admin-microcluster does not exist/ms;

	return $clusterlist;
}

method getMasterInstanceInfo ($username, $cluster) {
	$self->logDebug("username", $username);
	$self->logDebug("cluster", $cluster);
	
	#### SET CONFIG FILE
	my $masterid = $self->getMasterId($username, $cluster);
	$self->logDebug("masterid", $masterid);
	return if not defined $masterid;

	my $instanceinfo = $self->getInstanceInfo($masterid);
	$self->logDebug("instanceinfo", $instanceinfo);
	
	return $instanceinfo;
}

method getQmasterIps ($username, $cluster) {
#### RETRIEVE MASTER IP INFO FROM SGE_ROOT/qmaster_info FILE
	$self->logDebug("username", $username);
	$self->logDebug("cluster", $cluster);
	
	my $sgeroot = $self->conf()->getKey('cluster', 'SGEROOT');
	my $qmasterinfo = "$sgeroot/$cluster/qmaster_info";
	return if not -f $qmasterinfo;
	
	open(FILE, $qmasterinfo) or die "Can't open qmasterinfo : $qmasterinfo\n";
	my $contents = <FILE>;
	$self->logDebug("contents", $contents);
	close(FILE) or die "Can't close qmasterinfo : $qmasterinfo\n";

	#### FILE FORMAT:
	#### SHORT INTERNAL DNS --- LONG INTERNAL DNS --- INSTANCE ID
	#### 10.220.110.244	ip-10-220-110-244.ec2.internal	i-3414664e
	$contents =~ /^(\S+)\t+(\S+)\t+(\S+)/;
	
	return $1, $2, $3;
}

method getHeadnodeInternalIp {
#### GET HEADNODE SHORT INTERNAL IP

	return `curl -s http://169.254.169.254/latest/meta-data/local-ipv4`;
}

method getInternalIps ($username, $cluster, $privatekey, $publiccert) {
#### RETRIEVE THE INTERNAL IPS FOR ALL EXECUTION NODES IN THE CLUSTER 
	$self->logDebug("username", $username);
	$self->logDebug("cluster", $cluster);
	$self->logDebug("privatekey", $privatekey);
	$self->logDebug("publiccert", $publiccert);

	my $clusternodes = $self->clusterNodesInfo();
	return if not defined $clusternodes;
	
	my $internalips = [];
	foreach my $clusternode ( @$clusternodes )
	{
		push @$internalips,  $clusternode->{internalip};
	}
	$self->logDebug("internalips: @$internalips");

	return $internalips;
}

method clusterNodesInfo ($username, $cluster, $privatekey, $publiccert) {
=head2

	SUBROUTINE		clusterNodesInfo
	
	PURPOSE
	
		RETRIEVE THE INTERNAL IPS FOR ALL EXECUTION NODES
		
		IN THE GIVEN CLUSTER OWNED BY THIS USER

	NOTES

		1. EXTRACT INSTANCE IDS FOR STARCLUSTER NODES
	
		starcluster -c /path/to/configfile listclusters
	
			-----------------------------------------------
			smallcluster (security group: @sc-smallcluster)
			-----------------------------------------------
			Launch time: 2011-01-06T14:11:09.000Z
			Zone: us-east-1a
			Keypair: id_rsa-admin-key
			EBS volumes:
				vol-fc5af194 on master:/dev/sdj (status: attached)
			Cluster nodes:
				 master running i-6f21d203 ec2-72-44-59-38.compute-1.amazonaws.com 
				node001 running i-6921d205 ec2-67-202-9-15.compute-1.amazonaws.com 
			

		2. LOOK UP INSTANCE INFO USING ec2-describe-instances
		
=cut

	$self->logDebug("username", $username);
	$self->logDebug("cluster", $cluster);
	$self->logDebug("privatekey", $privatekey);
	$self->logDebug("publiccert", $publiccert);

	#### SET CONFIG FILE
	$self->setConfigFile($username, $cluster);

	#### 1. GET LIST OF INSTANCE IDS OF NODES IN CLUSTER	
    #### -----------------------------------------------
    #### smallcluster (security group: @sc-syoung-smallcluster)
    #### -----------------------------------------------
    #### Launch time: 2010-10-15T02:53:52.000Z
    #### Zone: us-east-1a
    #### Keypair: gsg-keypair
    #### Cluster nodes:
    ####      master running i-9edc26f3 ec2-174-129-54-141.compute-1.amazonaws.com 
    ####     node001 running i-98dc26f5 ec2-75-101-225-244.compute-1.amazonaws.com 

	my $instanceids = $self->getClusterInstanceIds();
	$self->logDebug("instanceids: @$instanceids");
	
	my $clusternodes = $self->describeInstances($username, $cluster, $privatekey, $publiccert);
	return if not defined $clusternodes;
	
	my $clusternodesinfo = [];
	foreach my $instanceid ( @$instanceids )
	{
		foreach my $clusternode ( @$clusternodes )
		{
			if ( $instanceid eq $clusternode->{instanceid} )
			{
				push @$clusternodesinfo,  $clusternode;
			}
		}
	}
	$self->logDebug("clusternodesinfo", $clusternodesinfo);

	return $clusternodesinfo;
}

method getClusterInstanceIds {
=head2

	SUBROUTINE		getClusterInstanceIds
	
	PURPOSE
	
		RETRIEVE THE INTERNAL IPS FOR ALL EXECUTION NODES
		
		IN THE GIVEN CLUSTER OWNED BY THIS USER

	NOTES

		1. EXTRACT EXTERNAL IPS FOR STARCLUSTER EXEC NODES
	
		starcluster -c /path/to/configfile listclusters
	
			-----------------------------------------------
			smallcluster (security group: @sc-smallcluster)
			-----------------------------------------------
			Launch time: 2011-01-06T14:11:09.000Z
			Zone: us-east-1a
			Keypair: id_rsa-admin-key
			EBS volumes:
				vol-fc5af194 on master:/dev/sdj (status: attached)
			Cluster nodes:
				 master running i-6f21d203 ec2-72-44-59-38.compute-1.amazonaws.com 
				node001 running i-6921d205 ec2-67-202-9-15.compute-1.amazonaws.com 
			

		2. LOOK UP INTERNAL IPS USING EXTERNAL IPS IN RESERVATION
		
			RECORDS OUTPUT BY ec2-describe-instances
		
=cut

	#### 1. GET LIST OF NODES FOR THIS CLUSTER	
    #### -----------------------------------------------
    #### smallcluster (security group: @sc-smallcluster)
    #### -----------------------------------------------
    #### Launch time: 2010-10-15T02:53:52.000Z
    #### Zone: us-east-1a
    #### Keypair: gsg-keypair
    #### Cluster nodes:
    ####      master running i-9edc26f3 ec2-174-129-54-141.compute-1.amazonaws.com 
    ####     node001 running i-98dc26f5 ec2-75-101-225-244.compute-1.amazonaws.com 

	$self->logDebug("");
	
	my $command = "starcluster -c ". $self->configfile() ." listclusters " . $self->cluster();
	$self->logDebug("command", $command);
	my $list = `$command`;
	$self->logDebug("list", $list);
	my ($entry) = $list =~ /" . $self->cluster()\s+\(security group:.+?\n[-]+\n(.+)([-]+)*/ms;
	$self->logDebug("entry", $entry);
	my ($lines) = $entry =~ /Cluster nodes:\s*\n(.+)$/ms;
	$self->logDebug("lines", $lines);
	my $instanceids = {};
	my @array = split "\n", $lines;
	foreach my $line ( @array )
	{
		next if $line =~ /^\s*$/;
		$instanceids->{$1} = $2 if $line =~ /^\s+(\S+)\s+\S+\s+(i-\S+)/;
	}
	$self->logDebug("instanceids: @$instanceids");

	return $instanceids;
}

method describeInstances ($username, $cluster, $privatekey, $publiccert) {
=head2

	SUBROUTINE		describeInstances
	
	PURPOSE
	
		RETRIEVE THE INSTANCE RECORDS FOR ALL EXECUTION NODES
-		IN THE GIVEN CLUSTER OWNED BY THIS USER

	NOTES
		
			ec2din OUTPUT EXAMPLE:

			RESERVATION     r-e30f5d89      558277860346    default
			INSTANCE        i-b42f3fd9      ami-90af5ef9    ec2-75-101-214-196.compute-1.amazonaws.com      ip-10-127-158-202.ec2.internal  running aquarius        0   t1.micro 2010-12-24T09:51:37+0000        us-east-1a      aki-b51cf9dc    ari-b31cf9da            monitoring-disabled     75.101.214.196  10.127.158.202      ebs
			BLOCKDEVICE     /dev/sda1       vol-c6e346ae    2010-12-24T09:51:40.000Z
			BLOCKDEVICE     /dev/sdh        vol-266dc84e    2010-12-24T23:03:04.000Z
			BLOCKDEVICE     /dev/sdi        vol-fa6dc892    2010-12-24T23:05:50.000Z
			RESERVATION     r-6dfecb07      558277860346    @sc-masters,@sc-smallcluster
			INSTANCE        i-6f21d203      ami-a5c42dcc    ec2-72-44-59-38.compute-1.amazonaws.com ip-10-124-245-118.ec2.internal  running id_rsa-admin-key        0   m1.large 2011-01-06T14:11:09+0000        us-east-1a      aki-fd15f694    ari-7b739e12            monitoring-disabled     72.44.59.38     10.124.245.118      instance-store
			BLOCKDEVICE     /dev/sdj        vol-fc5af194    2011-01-06T14:14:11.000Z
			RESERVATION     r-63fecb09      558277860346    @sc-smallcluster
			INSTANCE        i-6921d205      ami-a5c42dcc    ec2-67-202-9-15.compute-1.amazonaws.com ip-10-124-247-224.ec2.internal  running id_rsa-admin-key        0   m1.large 2011-01-06T14:11:09+0000        us-east-1a      aki-fd15f694    ari-7b739e12            monitoring-disabled     67.202.9.15     10.124.247.224      instance-store

=cut
	$self->logDebug("username", $username);
	$self->logDebug("cluster", $cluster);
	$self->logDebug("privatekey", $privatekey);
	$self->logDebug("publiccert", $publiccert);

	#### SET CONFIG FILE
	my $configfile = $self->configfile();
	
	my $ec2din = qq{ec2-describe-instances \\
-K } . $self->privatekey() . qq{\\
-C } . $self->publiccert();	
	my $return = `$ec2din`;
	$self->logError("return from ec2din is undefined or empty") and return if not defined $return or not $return;
	
	my $nodes = [];
	my @reservations = split "RESERVATION", $return;
	shift @reservations;
	foreach my $reservation ( @reservations )
	{
		push @$nodes, $self->parseInstanceInfo($reservation);
	}
	$self->logDebug("Returning nodes:");
	foreach my $node ( @$nodes )
	{
		$self->logDebug("$node->{instanceid}", $node->{internalip});
	}
	$self->logDebug("\n");
	
	return $nodes;
}

method getInstanceInfo ($instanceid) {
=head2

	SUBROUTINE 		getInstanceInfo
	
	PURPOSE
	
		RETURN A HASH OF INSTANCE VARIABLES

	NOTES
	
		RESERVATION     r-e30f5d89      558277860346    default
		INSTANCE        i-b42f3fd9      ami-90af5ef9    ec2-75-101-214-196.compute-1.amazonaws.com      ip-10-127-158-202.ec2.internal running aquarius        0               t1.micro        2010-12-24T09:51:37+0000        us-east-1a     aki-b51cf9dc    ari-b31cf9da            monitoring-disabled     75.101.214.196  10.127.158.202        ebs
		BLOCKDEVICE     /dev/sda1       vol-c6e346ae    2010-12-24T09:51:40.000Z
		BLOCKDEVICE     /dev/sdh        vol-266dc84e    2010-12-24T23:03:04.000Z
		BLOCKDEVICE     /dev/sdi        vol-fa6dc892    2010-12-24T23:05:50.000Z
=cut
	
	my $privatekey = $self->privatekey();
	my $publiccert = $self->publiccert();
	$self->logDebug("privatekey", $privatekey);
	$self->logDebug("publiccert", $publiccert);
	
	my $command = qq{ec2-describe-instances \\
-K $privatekey \\
-C $publiccert \\
$instanceid};
	$self->logDebug("$command");
	my $reservation = `$command`;
	$self->logDebug("reservation", $reservation);

	return {} if not $reservation;
	return $self->parseInstanceInfo($reservation);
}

method parseInstanceInfo ($info) {
	$self->logDebug("info", $info);

	my $instancekeys = {
	instanceid		=>	1,
	imageid			=>	2,
	externalfqdn	=>	3,
	internalfqdn	=>	4,
	status			=>	5,
	name			=>	6,
	instancetype	=>	9,
	launched		=>	10,
	availzone		=>	11,
	kernelid		=>	12,
	externalip		=>	16,
	internalip	=>	17	
	};

	#### FORMAT:
	#### 'reservation' => '	r-2b83a744	728213020069	@sc-syoung-microcluster'
	my $reservationkeys = {
	reservationid	=>	0,
	amazonuserid	=>	1,
	securitygroup	=>	2
	};
	my $blockdevicekeys = {
	device			=>	1,
	volume			=>	2,
	attached		=>	3
	};

	my @lines = split "\n", $info;
	my $instance;
	$instance->{blockdevices} = [];
	foreach my $line ( @lines )
	{
		if ( $line =~ /^BLOCKDEVICE/ )
		{
			my $blockdevice;
			my @elements = split "\t", $line;
			foreach my $key ( keys %$blockdevicekeys )
			{
				$self->logDebug("key: $key, blockdevicekeys->{$key}: $blockdevicekeys->{$key}, elements[$blockdevicekeys->{$key}]: $elements[$blockdevicekeys->{$key}] ");
				$blockdevice->{$key} = $elements[$blockdevicekeys->{$key}];
			}
			
			push @{$instance->{blockdevices}}, $blockdevice; 
		}
		if ( $line =~ /^INSTANCE/ )
		{
			my @elements = split "\t", $line;
			foreach my $key ( keys %$instancekeys )
			{
				$self->logDebug("key: $key, instancekeys->{$key}: $instancekeys->{$key}, elements[$instancekeys->{$key}]: $elements[$instancekeys->{$key}] ");
				$instance->{$key} = $elements[$instancekeys->{$key}];
			}
		}
		if ( $line =~ /^\s+/ )
		{
			$line =~ s/^\s+//;
			my @elements = split "\t", $line;
			foreach my $key ( keys %$reservationkeys )
			{
				$self->logDebug("key: $key, reservationkeys->{$key}: $reservationkeys->{$key}, elements[$reservationkeys->{$key}]: $elements[$reservationkeys->{$key}] ");
				$instance->{$key} = $elements[$reservationkeys->{$key}];
			}
		}
	}
	$self->logDebug("instance", $instance);

	return $instance;
}

1;