package Agua::Common::Volume;
use Moose::Role;
use Method::Signatures::Simple;


method automount () {
=head2

**** DEPRECATED: automount.py STARCLUSTER PLUGIN TAKES CARE OF THIS **
	
	SUBROUTINE		automount

	PURPOSE

		MAKE SURE THAT THE NODES ARE FULLY OPERATIONAL BEFORE THE MOUNTS ARE ATTEMPTED

=cut

	#### OPEN NFS AND SGE PORTS IN SECURITY GROUP
	my $cluster 	= 	$self->cluster();
	$self->logDebug("cluster", $cluster);
	$self->logDebug("Doing self->openPorts()");
	$self->openPorts("\@sc-$cluster");
	
	#### SETUP SHARES FROM HEAD
	$self->addNfsMounts();
	
	#### MOUNT SHARES ON MASTER AND ALL NEW NODES
	$self->mountShares($self->privatekey(), $self->publiccert(), $self->username(), $self->keyname(), $self->cluster(), $self->nodes());

	##### **** DEPRECATED: sge.py STARCLUSTER PLUGIN TAKES CARE OF THIS **
	##### SET THE DEFAULT QUEUE ON MASTER
	#$self->setQueue("default");
	#	
	###### SET threaded PARALLEL ENVIRONMENT ON MASTER
	#$self->logDebug("Doing self->setPE('threaded')");
	#$self->setPE("threaded", "default");	
}

method monitorAddedNodes  ($outputfile) {
=head2

	#############################################################
	####
	####	DEPRECATED		DEPRECATED		DEPRECATED
	####
	#### automount.py STARCLUSTER PLUGIN TAKES CARE OF THIS
	####
	####
	#############################################################

	SUBROUTINE		monitorAddedNodes
	
	PURPOSE
	
		MONITOR ADDED STARCLUSTER NODES BY TRACKING LOAD
		
		BALANCER OUTPUT, E.G:

			...
			>>> *** ADDING 1 NODES at 2011-02-09 02:42:52.871015.
			>>> Launching node(s): node002
			...

	NOTES
	
		1. PERIODICALLY CHECK FOR '*** ADDING 1 NODES ' IN 
		   <cluster>-starcluster.out FILE

		2. FOR EACH FOUND, GET NODE NAME (E.G., 'node002') AND
		   USE starcluster listclusters <cluster> TO RETRIEVE
		   INTERNAL IP

		3. CHECK AGAINST LIST OF COMPLETED NODES

		4. IF NOT COMPLETED, SET NFS EXPORTS ON THE HEAD NODE
			
			FOR THIS NEWLY ADDED NODE

		5. ADD NODE TO LIST OF COMPLETED NODES
		
=cut

	#### SET KEYPAIR FILE
	my $keypairfile = $self->keypairfile();
	$self->logDebug("keypairfile", $keypairfile);
	
	#### SET CONFIG FILE
	my $configfile = $self->configfile();
	$self->logDebug("StarCluster::monitorAddedNodes(username, keyname, cluster)");

	my $sleepinterval = $self->sleepinterval();
	$self->logDebug("sleepinterval", $sleepinterval);

	####	1. PERIODICALLY CHECK FOR '*** ADDING 1 NODES ' IN 
	####	   <cluster>-starcluster.out FILE
	my $completed_nodes = [];
	while ( 1 )
	{
		$self->logDebug("in loop");
		open(FILE, $outputfile) or die "Can't open outputfile: $outputfile\n";
		$/ = "*** ADDING";
		####	2. FOR EACH FOUND, GET NODE NAME (E.G., 'node002') AND
		####	   USE starcluster listclusters <cluster> TO RETRIEVE
		####	   INTERNAL IP
		my @nodes = <FILE>;
		close(FILE);
		shift @nodes;

		####	3. CHECK AGAINST LIST OF COMPLETED NODES
		foreach my $node ( @nodes )
		{
			my $completed = 0;
			foreach my $completed_node ( @$completed_nodes )
			{
				$completed = 1 if $completed_node->{internalip} eq $node->{internalip};
				last if $completed;
			}
			####	4. IF NOT COMPLETED, SET NFS EXPORTS FOR THIS NODE ON HEAD
			$self->setNfsExports($self->sourcedirs(), [$node->{internalip}]);			
			####	5. ADD NODE TO LIST OF COMPLETED NODES
			$self->logDebug("completed node", $node->{name}) and next if $completed;
			push @$completed_nodes, $node;
		}
		
		sleep($self->sleepinterval());
	}
}

method setNfsExports ($volumes, $internalips) {

	$self->addToExports($volumes, $internalips);
	
	#### RESTART PORTMAP AND NFS DAEMONS
	$self->restartDaemons();
}

method addToExports ($volumes, $recipientips, $remotehost, $keypairfile) {
=head2

	SUBROUTINE		addToExports
	
	PURPOSE
	
		ON MASTER, SET UP EXPORT TO HEAD INSTANCE IN /etc/exports:

		/home ip-10-124-247-224.ec2.internal(async,no_root_squash,no_subtree_check,rw)
		/opt/sge6 ip-10-124-247-224.ec2.internal(async,no_root_squash,no_subtree_check,rw)
		/data ip-10-124-247-224.ec2.internal(async,no_root_squash,no_subtree_check,rw)
	*** /data ip-10-127-158-202.ec2.internal(async,no_root_squash,no_subtree_check,rw)

=cut

	#### sourceip IS THE HOST DOING THE SHARING
	#### remotehost IS THE HOST MOUNTING THE SHARE
	$self->logDebug("StarCluster::addToExports(volumes, recipientips, remotehost, keypairfile)");
	$self->logDebug("username: " . $self->username());
	$self->logDebug("recipientips: @$recipientips");
	$self->logDebug("volume: @$volumes");
	$self->logDebug("keypairfile", $keypairfile) if defined $keypairfile;
	$self->logDebug("remotehost", $remotehost) if defined $remotehost;

	#### SET CONFIG FILE
	my $configfile = $self->configfile();

	#### GET CONTENTS OF /etc/exports
	my $exportsfile = "/etc/exports";
	my ($exports) = $self->remoteCommand({
		remotehost	=>	$remotehost,
		command		=>	"cat $exportsfile"
	}); 
	$exports =~ s/\s+$//;
	#### REMOVE EXISTING ENTRY FOR THESE VOLUMES
	my @lines = split "\n", $exports;
	foreach my $volume ( @$volumes )
	{
		foreach my $recipientip ( @$recipientips )
		{
			for ( my $i = 0; $i < $#lines + 1; $i++ )
			{
				if ( $lines[$i] =~ /^$volume\s+$recipientip/ )
				{
					splice @lines, $i, 1;
					$i--;
				}
			}
		}
	}
	foreach my $volume ( @$volumes )
	{
		foreach my $recipientip ( @$recipientips )
		{
			push @lines, "$volume $recipientip(async,no_root_squash,no_subtree_check,rw)";
		}
	}
	my $output = join "\n", @lines;

	$self->remoteCommand({
		remotehost	=>	$remotehost,
		command		=>	"mv -f $exportsfile $exportsfile.bkp"
	}); 
	
	#### WRITE TEMP FILE TO USER-OWNED /tmp DIRECTORY
	#### IN PREPARATION FOR COPY AS ROOT TO REMOTE HOST
	my $tempdir = "/tmp/" . $self->username();
	File::Path::mkpath($tempdir) if not -d $tempdir;
	my $tempfile = "/$tempdir/exports";
	open(OUT, ">$tempfile") or die "Can't open tempfile: $tempfile\n";
	print OUT $output;
	close(OUT) or die "Can't close tempfile: $tempfile\n";

	my $result;
	if ( defined $keypairfile and $keypairfile )
	{
		($result) = $self->remoteCommand({
			remotehost	=>	$remotehost,
			source		=>	$tempfile,
			target		=>	$exportsfile
		});
	}
	else {
		$result = `cp $tempfile $exportsfile`;
	}
	$self->logDebug("result", $result);
}

method autoMount () {
=head2

	SUBROUTINE		autoMount
	
	PURPOSE
	
		MAKE REMOTE CALLS TO NODES TO SET UP NFS MOUNTS
		
	#############################################################
	####
	####	DEPRECATED		DEPRECATED		DEPRECATED
	####
	#### automount.py STARCLUSTER PLUGIN TAKES CARE OF THIS
	####
	####
	#############################################################
=cut
	#### SET KEYPAIR FILE
	my $keypairfile = $self->keypairfile();
	$self->logDebug("keypairfile", $keypairfile);

	### GET INTERNAL IP OF HEAD NODE
	my ($externalip, $headip) = $self->getLocalIps();
	$self->logDebug("headip", $headip);
	
	#### GET INTERNAL IPS OF ALL NODES
	my $nodeips = $self->getInternalIps();
	$self->logDebug("nodeips: @$nodeips");
	return if not defined $nodeips;

	#### MOUNT ON MASTER AND EXEC NODES
	foreach my $nodeip ( @$nodeips )
	{
		my $inserts = [];
		my $removex = [];
		for ( my $i = 0; $i < @{$self->sourcedirs()}; $i++ )
		{
			my $sourcedir = ${$self->sourcedirs()}[$i];
			my $mountpoint = ${$self->mountpoints()}[$i];

			$self->mountNfs($sourcedir, $headip, $mountpoint, $keypairfile, $nodeip);
		
			push @$inserts, "$headip:$sourcedir  $mountpoint nfs nfsvers=3,defaults 0 0";
			push @$removex, "$headip:$sourcedir";
		}
	
		$self->addFstab($removex, $inserts, $keypairfile, $nodeip);
	}
}

method addFstab ($removex, $inserts, $keypairfile, $remotehost) {
=head2

	SUBROUTINE		addFstab
	
	PURPOSE
	
		ADD ENTRIES TO /etc/fstab TO AUTOMOUNT NFS IMPORTS, I.E.:
		
			/dev/sdh  /data      nfs     rw,vers=3,rsize=32768,wsize=32768,hard,proto=tcp 0 0
			/dev/sdi  /nethome      nfs     rw,vers=3,rsize=32768,wsize=32768,hard,proto=tcp 0 0

=cut

	#### remotehost IS THE HOST MOUNTING THE SHARE
	$self->logDebug("removex", $removex);
	$self->logDebug("inserts: @$inserts");
	$self->logDebug("keypairfile", $keypairfile);
	$self->logDebug("remotehost", $remotehost);
	
	#### SET SSH
	if ( not defined $self->ssh() ) {
		$self->_setSsh("root", $remotehost, $keypairfile);
	}
	else {
		$self->ssh()->keyfile($keypairfile);
		$self->ssh()->remotehost($remotehost);
		$self->ssh()->remoteuser("root");
	}
	
	#### SET CONFIG FILE
	my $configfile = $self->configfile();

	#### GET CONTENTS OF /etc/exports
	my $fstabfile = "/etc/fstab";
	my ($exports) = $self->SSH()->remoteCommand("cat $fstabfile"); 
	$exports =~ s/\s+$//;
	
	#### REMOVE EXISTING ENTRY FOR THESE VOLUMES
	my @lines = split "\n", $exports;
	for ( my $i = 0; $i < $#lines + 1; $i++ )
	{
		foreach my $remove ( @$removex )
		{
			if ( $lines[$i] =~ /^$remove/ )
			{
				splice @lines, $i, 1;
				$i--;
			}
		}
	}

	foreach my $insert ( @$inserts ) {
		push @lines, $insert;
	}
	my $output = join "\n", @lines;

	$self->remoteCommand("mv -f $fstabfile $fstabfile.bkp"); 
	
	#### WRITE TEMP FILE TO USER-OWNED /tmp DIRECTORY
	#### IN PREPARATION FOR COPY AS ROOT TO REMOTE HOST
	my $tempdir = "/tmp/" . $self->username();
	File::Path::mkpath($tempdir) if not -d $tempdir;
	my $tempfile = "$tempdir/exports";
	open(OUT, ">$tempfile") or die "Can't open tempfile: $tempfile\n";
	print OUT $output;
	close(OUT) or die "Can't close tempfile: $tempfile\n";

	my $result;
	if ( not defined $remotehost ) {
		$result = $self->ssh()->scpPut($tempfile, $fstabfile);
	}
	else {
		$result = `cp $tempfile $fstabfile`;
	}
}

method mountShares () {
=head2

	#############################################################
	####
	####	DEPRECATED		DEPRECATED		DEPRECATED
	####
	#### automount.py STARCLUSTER PLUGIN TAKES CARE OF THIS
	####
	####
	#############################################################

=cut
	#### SET KEYPAIR FILE
	my $keypairfile = $self->keypairfile();
	$self->logDebug("keypairfile", $keypairfile);

	#### SET CONFIG FILE
	my $configfile = $self->configfile();

	#### WHILE CLUSTER IS STARTING UP, SEARCH FOR IPS OF NODES
	#### AND ADD THEM TO /etc/exports
	my $completed_nodes = [];
	while ( scalar(@$completed_nodes) < $self->nodes() )
	{
		#### GET INTERNAL IPS, ETC. OF ALL NODES IN CLUSTER
		my $launched_nodes = $self->getLaunchedNodes();
		
		#### IGNORE ALREADY COMPLETED NODES
		foreach my $launched_node ( @$launched_nodes )
		{
			my $completed = 0;
			foreach my $completed_node ( @$completed_nodes )
			{
				$completed = 1 if $completed_node->{internalip} eq $launched_node->{internalip};
				last if $completed;
			}
			next if $completed;

			push @$completed_nodes, $launched_node;
			
			if ( $launched_node->{name} eq "master" )
			{
				##### AUTOMATE RESTART sge MASTER AND EXECD AFTER REBOOT MASTER
				my $masterip = $launched_node->{internalip};
				$self->setSgeStartup($self->username(), $masterip, $keypairfile);
			
				#### EXCLUDE MASTER NODE FROM EXEC NODES LIST
				$self->excludeMasterHost($masterip);
			}

			#### ADD ENTRIES TO /etc/exports
			$self->setNfsExports($self->sourcedirs, $launched_node->{internalip});
		}
	}
}

method setSgeStartup ($remotehost) {
=head2

	SUBROUTINE 		setSgeStartup
	
	PURPOSE
	
		ADD CALL TO START SGE TO /etc/init.d/rc.local

=cut

	my $removex = [
	"",
	"/etc/init.d/sgemaster.starcluster start",
	"echo 'sgemaster.starcluster started'",
	"/etc/init.d/sgeexecd.starcluster start",
	"echo 'sgeexecd.starcluster started'"
];
	my $inserts;
	@$inserts = @$removex;

	#### remotehost IS THE HOST MOUNTING THE SHARE
	$self->logDebug("StarCluster::setSgeStartup(username, keypairfile, remotehost, sourceip, volume)");
	$self->logDebug("username", $self->username());
	$self->logDebug("removex", $removex);
	$self->logDebug("inserts: @$inserts");
	$self->logDebug("remotehost", $remotehost);

	#### GET CONTENTS OF /etc/exports
	my $startupfile = "/etc/init.d/rc.local";
	my ($contents) = $self->remoteCommand({
		remotehost	=>	$remotehost,
		command		=>	"cat $startupfile"
	}); 
	$contents =~ s/\s+$//;
	#### REMOVE EXISTING ENTRY FOR THESE VOLUMES
	my @lines = split "\n", $contents;
	for ( my $i = 0; $i < $#lines + 1; $i++ )
	{
		foreach my $remove ( @$removex )
		{
			if ( $lines[$i] =~ /^$remove/ )
			{
				splice @lines, $i, 1;
				$i--;
			}
		}
	}
	foreach my $insert ( @$inserts )
	{
		push @lines, $insert;
	}
	my $output = join "\n", @lines;

	$self->remoteCommand({
		remotehost	=>	$remotehost,
		command		=>	"mv -f $startupfile $startupfile.bkp"
	});

	#### WRITE TEMP FILE TO USER-OWNED /tmp DIRECTORY
	#### IN PREPARATION FOR COPY AS ROOT TO REMOTE HOST
	my $tempdir = "/tmp/" . $self->username();
	File::Path::mkpath($tempdir) if not -d $tempdir;
	my $tempfile = "$tempdir/startup";
	open(OUT, ">$tempfile") or die "Can't open tempfile: $tempfile\n";
	print OUT $output;
	close(OUT) or die "Can't close tempfile: $tempfile\n";

	my $result;
	if ( defined $remotehost and $remotehost ) {
		$result = $self->remoteCopy({
			remotehost	=>	$remotehost,
			source		=>	$tempfile,
			target		=>	$startupfile
		});
	}
	else {
		$result = `cp $tempfile $startupfile`;
	}
	$self->logDebug("result", $result);
	my ($catnew) = $self->remoteCommand({
		remotehost	=>	$remotehost,
		command		=>	"cat $startupfile"
	});
	$self->logDebug("catnew", $catnew);
}


method excludeMasterHost ($remotehost) {
=head2

	SUBROUTINE 		excludeMasterHost
	
	PURPOSE
	
		1. REMOVE MASTER FROM EXEC HOST LIST
		
		2. REMOVE MASTER FROM CONFIGURATION LIST:
		
		3. REMOVE MASTER FROM HOST LIST
		
		4. RESTART sgemaster DAEMON
		
	NOTES
	
		MUST BE RUN AS root
	
=cut

	#### remotehost IS THE HOST MOUNTING THE SHARE
	$self->logDebug("StarCluster::excludeMasterHost(remotehost)");
	$self->logDebug("remotehost", $remotehost);

	#### SET CONFIG FILE
	my $configfile 		= 	$self->configfile();
	my $keypairfile 	= 	$self->keypairfile();

	#### SET QCONF
	my $conf 			= 	$self->conf();
	my $sge_root		= 	$conf->getKey("cluster", "SGE_ROOT");
	my $sge_qmaster_port= 	$conf->getKey("cluster", "SGE_QMASTER_PORT");
	my $qconf			= 	$conf->getKey("cluster", "QCONF");

	#### 1. REMOVE MASTER FROM EXEC HOST LIST
	#	Host object "ip-10-124-245-118.ec2.internal" is still referenced in cluster queue "all.q"
	my $exec = "export SGE_ROOT=$sge_root; export SGE_QMASTER_PORT=$sge_qmaster_port; $qconf -de $remotehost";
	$self->logDebug("\n$exec\n");
	my ($exec_result) = $self->remoteCommand({
		remotehost => $remotehost,
		command	=>	$exec
	});
	$self->logDebug("exec_result", $exec_result);


	#### 2. REMOVE MASTER FROM CONFIGURATION LIST:
	#    root@ip-10-124-245-118.ec2.internal removed "ip-10-124-245-118.ec2.internal" from configuration list
	my $config = "export SGE_ROOT=$sge_root; export SGE_QMASTER_PORT=$sge_qmaster_port; $qconf -dconf $remotehost";
	$self->logDebug("config command:\n$config\n");
	my ($config_result) = $self->remoteCommand({
		remotehost => $remotehost,
		command	=>	$config
	});
	$self->logDebug("config_result", $config_result);

	#### 3. REMOVE MASTER FROM HOST LIST
	#### GET CURRENT GROUP CONFIG
	#    group_name @allhosts
	#    hostlist ip-10-124-245-118.ec2.internal ip-10-124-247-224.ec2.internal
	my ($hostlist) = 	$self->remoteCommand({
		remotehost 	=> 	$remotehost,
		command		=>	"qconf -shgrp \@allhosts"
	});

	$hostlist =~ s/\s+$//;
	$self->logDebug("BEFORE hostlist", $hostlist);
	
	#### WRITE TEMP FILE TO USER-OWNED /tmp DIRECTORY
	#### IN PREPARATION FOR COPY AS ROOT TO REMOTE HOST
	my $tempdir = "/tmp/" . $self->username();
	File::Path::mkpath($tempdir) if not -d $tempdir;
	my $groupfile = "allhosts.group";
	open(OUT, ">/$tempdir/$groupfile") or die "Can't open groupfile: $groupfile\n";
	print OUT $hostlist;
	close(OUT) or die "Can't close groupfile: /$tempdir/$groupfile\n";

	#### COPY GROUP CONFIG FILE TO '~' ON TARGET HOST
	my $copy = $self->remoteCopy({
		
		
	});
	$copy = qq{scp -i $keypairfile /$tempdir/$groupfile root\@$remotehost:$groupfile} if defined $keypairfile;
	$copy = qq{cp /$tempdir/$groupfile ~/$groupfile} if not defined $keypairfile;
	$self->logDebug("copy", $copy);
	my $result = `$copy`;	
	$self->logDebug("result", $result);

	#### SET GROUP CONFIG FROM FILE ON TARGET HOST
	my ($qconf_result) = $self->remoteCommand({
		remotehost 	=> 	$remotehost,
		command		=>	"export SGE_ROOT=$sge_root; export SGE_QMASTER_PORT=$sge_qmaster_port; $qconf -Mhgrp ~/$groupfile"
	});
	#    root@ip-10-124-245-118.ec2.internal modified "@allhosts" in host group list
	$self->logDebug("qconf_result", $qconf_result);
	
	#### RESTART sgemaster
	#### SET GROUP CONFIG FROM FILE ON TARGET HOST
	my ($restart_result) = $self->remoteCommand({
		remotehost 	=> 	$remotehost,
		command		=>	"/etc/init.d/sgemaster.starcluster stop; /etc/init.d/sgemaster.starcluster start"
	});
	$self->logDebug("restart_result", $restart_result);
}


method getLaunchedNodes () {
	my $command = "starcluster -c " . $self->configfile . " listclusters ". $self->cluster();
	$self->logDebug("command", $command);
	####	    Cluster nodes:
	####         master running i-9b3e5ff7 ec2-50-17-20-70.compute-1.amazonaws.com 
	####        node001 running i-953e5ff9 ec2-67-202-10-108.compute-1.amazonaws.com 
	####    Total nodes: 2
	my $list = `$command`;
	$self->logDebug("list result not defined or empty")
		and return if not defined $list or not $list;
	$self->logDebug("list", $list);

	my ($nodelist) = $list =~ /Cluster nodes:\s*\n(.+)$/ms;
	my @lines = split "\n", $nodelist;
	my $nodes = [];
	foreach my $line ( @lines )
	{
		next if $line =~ /^\s*$/;
		my ($name, $status, $instanceid, $internalip) =
			$line =~ /^\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/;
		push @$nodes, {
			name=> $name,
			status=>$status,
			instanceid=> $instanceid,
			internalip=> $internalip
		};
	}
	
	return $nodes;
}

method addNfsMounts () {
#### CONFIGURE NFS SHARES ON HEAD NODE (I.E., NOT MASTER)
	
	#### CHECK INPUTS
	$self->logDebug("privatekey not defined")and exit if not $self->privatekey();
	$self->logDebug("publiccert not defined")and exit if not $self->publiccert();
	$self->logDebug("username not defined")and exit if not $self->username();
	$self->logDebug("cluster not defined")and exit if not $self->cluster();
	$self->logDebug("keyname not defined")and exit if not $self->keyname();
	$self->logDebug("sourcedirs not defined")and exit if not $self->sourcedirs();
	$self->logDebug("devices not defined")and exit if not $self->devices();

	##### SET FIXED PORT FOR HEAD NODE NFS
	$self->setMountdPort(undef, undef);

	#### ADD ENTRIES TO /etc/fstab
	my $inserts = [];
	my $removes = [];
	for ( my $i = 0; $i < @{$self->sourcedirs()}; $i++ )
	{
		my $sourcedir = ${$self->sourcedirs()}[$i];
		my $device = ${$self->devices()}[$i];

		push @$inserts, "$device  $sourcedir    nfs     rw,vers=3,rsize=32768,wsize=32768,hard,proto=tcp 0 0";
		push @$removes, "$device\\s+$sourcedir\\s+nfs";
	}
	
	#### RESTART PORTMAP AND NFS DAEMONS
	$self->restartDaemons(undef, undef);

	#### SET /etc/fstab ENTRIES FOR SHARES
	$self->addFstab($removes, $inserts, undef, undef);
}

method setMountdPort ($keypairfile, $remotehost) {	
=head2

	SUBROUTINE		setMountdPort
	
	PURPOSE
	
		ADD FIXED PORT FOR mountd IN /etc/default/nfs-kernel-server
	
			- 	ON REMOTE HOST IF KEYPAIRFILE AND IP PROVIDED
			
			-	OTHERWISE, ON LOCAL HOST

=cut
	$self->logDebug("StarCluster::setMountdPort(keypairfile, remotehost)");
	
	#### GET UNAME
	my ($uname) = $self->remoteCommand({
		remotehost 	=> $remotehost,
		command		=>	"uname -a"
	});
	$self->logDebug("uname", $uname);
	
	my $conf = $self->conf();
	my $mountdport = $conf->getKey("starcluster:nfs", "MOUNTDPORT");	
	$self->logDebug("mountdport", $mountdport);

	my $insert = qq{MOUNTD_PORT=32767};
	my $filter = qq{MOUNTD_PORT};
	my $nfsconfigfile = "/etc/sysconfig/nfs";
	if ( $uname =~ /ubuntu/i )
	{
		$insert = qq{RPCMOUNTDOPTS="--port $mountdport --manage-gids"};
		$filter = qq{RPCMOUNTDOPTS};
		$nfsconfigfile = "/etc/default/nfs-kernel-server";
	}
	$self->logDebug("insert", $insert);
	$self->logDebug("filter", $filter);
	$self->logDebug("nfsconfigfile", $nfsconfigfile);

	#### GET NFS CONFIG FILE CONTENTS
	my ($nfsconfig) = $self->remoteCommand({
		remotehost 	=> $remotehost,
		command		=>	"cat $nfsconfigfile"
	});
	$self->logDebug("BEFORE nfsconfig", $nfsconfig);

	#### BACKUP NFS CONFIG FILE
	print $self->remoteCommand({
		remotehost 	=> $remotehost,
		command		=>	"mv -f $nfsconfigfile $nfsconfigfile.bkp"
	});
	
	#### COMMENT OUT EXISTING RPCMOUNTOPTS LINES
	my @lines = split "\n", $nfsconfig;
	for ( my $i = 0; $i < $#lines + 1; $i++ )
	{
		if ( $lines[$i] =~ /^$filter/ )
		{
			splice @lines, $i, 1;
			$i--;
		}
	}

	#### ADD NEW RPCMOUNTOPTS LINE
	push @lines, "$insert\n";
	#### WRITE TEMP FILE TO USER-OWNED /tmp DIRECTORY
	#### IN PREPARATION FOR COPY AS ROOT TO REMOTE HOST
	my $tempdir = "/tmp/" . $self->username();
	File::Path::mkpath($tempdir) if not -d $tempdir;
	my $tempfile = "$tempdir/nfs-kernel-server";
	open(OUT, ">$tempfile") or die "Can't open tempfile: $tempfile\n";
	my $content = join "\n", @lines;
	print OUT $content;
	close(OUT) or die "Can't close tempfile: $tempfile\n";

	my $result;
	if ( defined $keypairfile and $keypairfile ) {
		$result = $self->remoteCopy({
			remotehost	=>	$remotehost,
			source		=>	$tempfile,
			target		=>	$nfsconfigfile
		});
	}
	else {
		$result = `cp $tempfile $nfsconfigfile`;
	}
	$self->logDebug("result", $result);
}

method mountNfs ($source, $sourceip, $mountpoint, $keypairfile, $remotehost) {	
=head2

	SUBROUTINE		mountNfs
	
	PURPOSE
	
		MOUNT EXPORTED NFS volume FROM MASTER ON AQ-7

	NOTES
	
		CHECK IF MASTER'S MOUNT IS SEEN BY AQ-7:
	
		showmount -e ip-10-124-245-118
		
			Export list for ip-10-124-245-118:
			/data     ip-10-127-158-202.ec2.internal,ip-10-124-247-224.ec2.internal
			/opt/sge6 ip-10-124-247-224.ec2.internal
			/home     ip-10-124-247-224.ec2.internal

=cut

	#### remotehost IS THE HOST MOUNTING THE SHARE
	$self->logDebug("StarCluster::mountNfs(source, sourceip, mountpoint, keypairfile, remotehost)");
	$self->logDebug("source", $source);
	$self->logDebug("sourceip", $sourceip);
	$self->logDebug("mountpoint", $mountpoint);
	$self->logDebug("keypairfile", $keypairfile);
	$self->logDebug("remotehost", $remotehost);

	#### CREATE MOUNTPOINT DIRECTORY
	print $self->remoteCommand({
		remotehost 	=> $remotehost,
		command		=>	"mkdir -p $mountpoint"
	});

	#### MOUNT NFS SHARE TO MOUNTPOINT
	print $self->remoteCommand({
		remotehost 	=> $remotehost,
		command		=>	"mount -t nfs $sourceip:$source $mountpoint"
	});
}


method restartDaemons ($keypairfile, $remotehost) {
=head2

	SUBROUTINE		restartDaemons
	
	PURPOSE
	
		ON MASTER, RESTART NFS

=cut


	#### CHECK LINUX FLAVOUR
	my ($uname) = $self->remoteCommand({
		remotehost 	=> $remotehost,
		command		=>	"uname -a"
	});
	#### SET BINARIES ACCORDING TO FLAVOUR
	my $portmapbinary = "service portmap";
	my $nfsbinary = "service nfs";
	if ( $uname =~ /ubuntu/i )
	{
		$portmapbinary = "/etc/init.d/portmap";
		$nfsbinary = "/etc/init.d/nfs";
	}

	#### RESTART SERVICES
	$self->remoteCommand({
		remotehost 	=> $remotehost,
		command		=>	"$portmapbinary restart"
	});
	$self->remoteCommand({
		remotehost 	=> $remotehost,
		command		=>	"$nfsbinary restart"
	});
}

method getLocalIps () {
	my $instance = $self->getInstanceInfo();
	my @elements = split " ", $instance->{instance};
	
	return $elements[3], $elements[4];
}



method openPorts ($group) {
=head2

	SUBROUTINE		openPorts
	
	PURPOSE
	
		OPEN NFS PORTS FOR THE GIVEN GROUP ON EC2

=cut
	$self->logDebug("StarCluster::openPorts(privatekey, publiccert, group)");
	$self->logError("group not defined or empty") and exit if not defined $group or not $group;

	my $conf 	= 	$self->conf();
	my $portmap	= 	$conf->getKey("starcluster:nfs", "PORTMAPPORT");
	my $nfs 	= 	$conf->getKey("starcluster:nfs", "NFSPORT");
	my $mountd 	= 	$conf->getKey("starcluster:nfs", "MOUNTDPORT");
	my $sge 	= 	$conf->getKey("cluster", "SGEQMASTERPORT");
	my $ec2 	= 	$conf->getKey("applications:aquarius-8", "EC2");	
	my $java_home= 	$conf->getKey("aws", "JAVAHOME");	
	$self->logError("ec2 not defined") and exit if not defined $ec2;

	#### SET EC2_HOME ENVIRONMENT VARIABLE
	my $ec2_home = $ec2;
	$ec2_home =~ s/\/bin$//;
	
	$ENV{'EC2_HOME'} = $ec2_home;
	$ENV{'JAVA_HOME'} = $java_home;

	##### CREATE SECURITY GROUP
	#my $creategroup = "$ec2/ec2-add-group $group -d 'StarCluster group'";
	my $tasks = [
		#### PORTMAP
		"$group -p $portmap -P tcp",
		"$group -p $portmap -P udp",
		
		#### NFS
		"$group -p $nfs -P udp",
		"$group -p $nfs -P tcp",

		#### MOUNTD
		"$group -p $mountd -P udp",
		"$group -p $mountd -P tcp",

		#### SGE_QMASTER_PORT
		"$group -p $sge -P udp",
		"$group -p $sge -P tcp"
	];
	
	#### RUN COMMANDS
	foreach my $task ( @$tasks )
	{
		my $command = qq{$ec2/ec2-authorize \\
-K } . $self->privatekey() . qq{ \\
-C } . $self->publiccert() . qq{ \\
$task\n};
		print $command;
		print `$command`;
	}
}



method removeNfsMounts () {
=head2

	SUBROUTINE 		removeNfsMounts
	
	PURPOSE
	
		REMOVE NFS MOUNT INFORMATION FROM SYSTEM FILES
		
		AND RESTART NFS DAEMONS

=cut

	$self->logDebug("privatekey: " . $self->privatekey());
	$self->logDebug("publiccert: " . $self->publiccert());
	$self->logDebug("username: " . $self->username());
	$self->logDebug("cluster: " . $self->cluster());
	$self->logDebug("keyname: " . $self->keyname());

	#### CHECK INPUTS
	$self->logDebug("privatekey not defined")and exit if not defined $self->privatekey();
	$self->logDebug("publiccert not defined")and exit if not defined $self->publiccert();
	$self->logDebug("username not defined")and exit if not defined $self->username();
	$self->logDebug("cluster not defined")and exit if not defined $self->cluster();
	$self->logDebug("keyname not defined")and exit if not defined $self->keyname();

	#### SET DEFAULT KEYNAME
	my $keypairfile = $self->keypairfile();
	$self->logDebug("keypairfile", $keypairfile);

	#### GET INTERNAL IPS OF ALL NODES IN CLUSTER
	my $nodeips = $self->getInternalIps($self->username(), $self->cluster(), $self->privatekey(), $self->publiccert());
	#my $nodeips = [ "ip-10-124-241-66.ec2.internal" ];
	$self->logDebug("nodeips: @$nodeips");
	return if not defined $nodeips;

	#### REMOVE ENTRIES FROM /etc/exports
	my $volumes = [ "/agua", "/data", "/nethome" ];
	$self->removeExports($self->username(), $volumes, $nodeips);
}

method removeExports ($volumes, $recipientips, $remotehost) {
=head2

	SUBROUTINE		removeExports
	
	PURPOSE
	
		ON MASTER, SET UP EXPORT TO HEAD INSTANCE IN /etc/exports:

		/home ip-10-124-247-224.ec2.internal(async,no_root_squash,no_subtree_check,rw)
		/opt/sge6 ip-10-124-247-224.ec2.internal(async,no_root_squash,no_subtree_check,rw)
		/data ip-10-124-247-224.ec2.internal(async,no_root_squash,no_subtree_check,rw)
	*** /data ip-10-127-158-202.ec2.internal(async,no_root_squash,no_subtree_check,rw)

=cut

	#### sourceip IS THE HOST DOING THE SHARING
	#### remotehost IS THE HOST MOUNTING THE SHARE
	$self->logDebug("StarCluster::removeExports(volumes, recipientips, remotehost)");
	$self->logDebug("recipientips: @$recipientips");
	$self->logDebug("volume: @$volumes");
	$self->logDebug("remotehost", $remotehost) if defined $remotehost;

	#### SET CONFIG FILE
	my $configfile = $self->configfile();
	my $keypairfile = $self->keypairfile();

	#### GET CONTENTS OF /etc/exports
	my $exportsfile = "/etc/exports";
	my ($exports) = $self->remoteCommand({
		remotehost 	=> 	$remotehost,
		command		=>	"cat $exportsfile"
	});
	$exports =~ s/\s+$//;
	#### REMOVE EXISTING ENTRY FOR THESE VOLUMES
	my @lines = split "\n", $exports;
	foreach my $volume ( @$volumes )
	{
		foreach my $recipientip ( @$recipientips )
		{
			for ( my $i = 0; $i < $#lines + 1; $i++ )
			{
				if ( $lines[$i] =~ /^$volume\s+$recipientip/ )
				{
					splice @lines, $i, 1;
					$i--;
				}
			}
		}
	}
	my $output = join "\n", @lines;

	my ($output) = $self->remoteCommand({
		remotehost 	=> $remotehost,
		command		=>	"mv -f $exportsfile $exportsfile.bkp"
	});
	$self->logDebug("output", $output);
	
	#### WRITE TEMP FILE TO USER-OWNED /tmp DIRECTORY
	#### IN PREPARATION FOR COPY AS ROOT TO REMOTE HOST
	my $tempdir = "/tmp/" . $self->username();
	File::Path::mkpath($tempdir) if not -d $tempdir;
	my $tempfile = "/$tempdir/exports";
	open(OUT, ">$tempfile") or die "Can't open tempfile: $tempfile\n";
	print OUT $output;
	close(OUT) or die "Can't close tempfile: $tempfile\n";

	my $result;
	if ( defined $keypairfile and $keypairfile ) {
		$result = $self->remoteCopy({
			remotehost	=>	$remotehost,
			source		=>	$tempfile,
			target		=>	$exportsfile
		});
	}
	else {
		$result = `cp $tempfile $exportsfile`;
	}
	$self->logDebug("result", $result);
}



