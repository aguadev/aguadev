package Virtual::Openstack::Nova;
use Moose::Role;
use Method::Signatures::Simple;

=head2


=cut

#####////}}}}}

#### Integers

#### Strings


use FindBin qw($Bin);

method getMetaData ($type) {
	return if not defined $type or $type eq "";
	my $command		=	"curl http://169.254.169.254/2009-04-04/meta-data/$type";
	$self->logDebug("command", $command);

	return	`$command`;
}

method list ($args) {
	my $username	=	$args->{username};
	my $name		=	$args->{name};
	my $regex		=	$args->{regex};
	my $command		=	$args->{command};
	
	print "Neither name nor regex is defined. XXX Exiting\n\n" and $self->usage() if not defined $name and not defined $regex;
	
	my $emptyname	=	undef;
	my $entries	=	$self->getEntries($emptyname);
	#$self->logDebug("entries", $entries);

	my $ips	=	[];
	for my $entry ( @$entries ) {
		push @$ips, "$entry->{name}\t$entry->{internalip}\t$entry->{externalip}" if defined $regex and $entry->{name} =~ /$regex/;
		push @$ips, "$entry->{name}\t$entry->{internalip}\t$entry->{externalip}" if not defined $regex and $entry->{name} eq $name;
	}
	$self->logDebug("ips", $ips);
	print join "\n", @$ips;
	print "\n";
}

method command ($args) {
	my $username	=	$args->{username};
	my $name		=	$args->{name};
	my $regex		=	$args->{regex};
	my $command		=	$args->{command};
	
	print "Neither name nor regex is defined. Exiting\n\n" and $self->usage() if not defined $name and not defined $regex;
	
	my $emptyname	=	undef;
	my $entries	=	$self->getEntries($emptyname);
	#$self->logDebug("entries", $entries);

	my $ips	=	[];
	for my $entry ( @$entries ) {
		push @$ips, $entry->{internalip} if defined $regex and $entry->{name} =~ /$regex/;
		push @$ips, $entry->{internalip} if not defined $regex and $entry->{name} eq $name;
	}
	$self->logDebug("ips", $ips);
	
	foreach my $ip ( @$ips ) {
		my $sshcommand	=	qq{ssh -o LogLevel=quiet -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t $username\@$ip "$command"};
		print "$sshcommand\n";
		$self->logDebug("sshcommand", $sshcommand);
		my $output = `$command`;
		
		print "$output\n";
		sleep(1);
	}
}

method attach ($instanceid, $volumeid, $device, $size, $type, $mountpoint) {
	$self->logDebug("size", $size);
	$self->logDebug("type", $type);
	
	$instanceid	=	$self->getInstanceId() if not defined $instanceid;
	$self->logDebug("instanceid", $instanceid);
		
	$device		=	$self->getDevice() if not defined $device;
	$self->logDebug("device", $device);
	
	if ( not defined $volumeid ) {
		$self->logDebug("volumeid NOT DEFINED. DOING CREATE, ATTACH AND FORMAT");
		$volumeid	=	$self->createVolume($size, $type);
		$self->logDebug("volumeid", $volumeid);
	
		$self->_attachVolume($instanceid, $volumeid, $device);
		sleep(4);
	
		$self->formatVolume($device);
	}
	else {
		$self->logDebug("volumeid DEFINED. DOING ATTACH");
		$self->attachVolume($instanceid, $volumeid, $device);
	}
	
	$self->mountVolume($device, $mountpoint);
}

method describeHost ($instanceid) {
	my $exports	=	$self->getExports();
	my $command	=	"$exports nova host-list $instanceid";
	$self->logDebug("command", $command);	
}
method formatVolume ($device) {
	my $command	=	"mkfs.ext4 $device";
	$self->logDebug("command", $command);
	
	return `$command`;
}

method detachVolume ($instanceid, $volumeid, $device, $size, $type, $mountpoint) {
	print "Virtual::Openstack::detach    volumeid not defined. Exiting\n" and exit if not defined $volumeid;
	$self->logDebug("volumeid", $volumeid);

	$instanceid	=	$self->getInstanceId() if not defined $instanceid;
	$self->logDebug("instanceid", $instanceid);
	
	$device		=	$self->getDevice() if not defined $device;

	$self->_detachVolume($instanceid, $volumeid, $device);
}

method _detachVolume ($instanceid, $volumeid, $device) {
#### nova volume-detach SERVER VOLUME
	my $exports	=	$self->getExports();
	my $command	=	"$exports nova volume-detach $instanceid $volumeid $device";
	$self->logDebug("command", $command);

	return `$command`;
}

method trashVolume ($instanceid, $volumeid, $device, $size, $type, $mountpoint) {
	$self->logDebug("mountpoint", $mountpoint);
	
	$instanceid	=	$self->getInstanceId();
	$self->logDebug("instanceid", $instanceid);
	
	$volumeid	=	$self->getVolumeByInstance($instanceid);
	$self->logDebug("volumeid", $volumeid);
	
	$device 	=	$self->getDeviceByMountpoint($mountpoint);
	$self->logDebug("device", $device);

	#### UNMOUNT
	my $command	=	"umount -f $mountpoint";
	$self->logDebug("command", $command);
	`$command`;
	
	#### DETACH
	$self->_detachVolume($instanceid, $volumeid, $device);

	#### DELETE
	$self->_deleteVolume($volumeid);

	$self->logDebug("COMPLETED");
}

method getVolumeByInstance ($instanceid) {
	$self->logDebug("instanceid", $instanceid);	

	my $exports	=	$self->getExports();
	my $command	=	"$exports nova volume-list";
	$self->logDebug("command", $command);
	my $output	=	`$command`;

	#| ID                                   | Status    | Display Name | Size | Volume Type | Attached to                          |
	#| 41dd473d-0840-4e21-b170-3b96efc03610 | in-use    | -            | 100  | Standard    | be0a67bd-bb64-4cb5-92b7-d716bd101632 |

	my ($volumeid)	=	$output	=~	/\n\s*\|\s+(\S+)[^\n]+$instanceid\s*\|\s*\n/msg;
	$self->logDebug("volumeid", $volumeid);

	return $volumeid;
}

method getDeviceByMountpoint ($mountpoint) {
	#$self->logDebug("mountpoint", $mountpoint);
	
	my $df		=	`df -ah`;
#	$self->logDebug("df", $df);
	
	my ($device)	=	$df	=~	/\n(\S+)[^\n]+$mountpoint\s*\n/msg;
	$device	=~	s/\d+$//;
#	$self->logDebug("device", $device);

	return $device;
}

method createVolume ($size, $type) {
	my $exports	=	$self->getExports();
	my $command	=	"$exports cinder create --volume-type $type $size";
	$self->logDebug("command", $command);
	
	my $output	=	`$command`;
	
	my $volumeid	=	$self->parseVolumeId($output);
	$self->logDebug("volumeid", $volumeid);

	return $volumeid;	
}

method mountVolume ($device, $mountpoint) {
	`mkdir -p $mountpoint` if not -d $mountpoint;
	
	my $command	=	"mount -t ext4 $device $mountpoint";
	
	return `$command`;
}

method parseVolumeId ($output) {
	my ($volumeid)	=	$output	=~ /\|\s+id\s+\|\s+(\S+)\s+/ms;
	$self->logDebug("volumeid", $volumeid);

	return $volumeid;
}

method _attachVolume ($instanceid, $volumeid, $device) {
#### nova volume-attach SERVER VOLUME DEVICE
	my $exports	=	$self->getExports();
	my $command	=	"$exports nova volume-attach $instanceid $volumeid $device";
	$self->logDebug("command", $command);

	return `$command`;
}

method deleteVolume ($instanceid, $volumeid, $device, $size, $type, $mountpoint) {
	$self->_deleteVolume($volumeid);	
}


method _deleteVolume ($volumeid) {
	my $exports	=	$self->getExports();
	my $command	=	"$exports nova volume-delete $volumeid";
	$self->logDebug("command", $command);
	my $output	=	`$command`;
	
	return 1;	
}

method getDevice {
	my $devicestub	=	"/dev/vd";
	my $device 	="/dev/vda";
	for my $letter ( "b".."z" ) {
		$self->logDebug("device", $device);
		last if `stat -f $device 2> /dev/null` eq "";
		$device	=	$devicestub . $letter;
	}

	return $device;
}

method getInstanceId {
	my $command		=	"curl curl http://169.254.169.254/openstack/latest/meta_data.json 2> /dev/null";
	#$self->logDebug("command", $command);

	my $json	=	`$command 2&>1`;
	#$self->logDebug("json", $json);
	
	my $data	=	$self->jsonparser()->decode($json);
	#$self->logDebug("data", $data);
	
	my $instanceid	=	$data->{uuid};
	#$self->logDebug("instanceid", $instanceid);
	
	return $instanceid;
}


method getEntries ($nodename) {
	$self->logDebug("nodename", $nodename);

	my $username	=	$self->username();
	$self->logDebug("username", $username);
	
	my $list	=	$self->novaList($nodename);
	my $entries	=	$self->parseEntries($list);
	
	return $entries;
}

method getIps ($nodename) {
	$self->logDebug("nodename", $nodename);

	my $username	=	$self->username();
	$self->logDebug("username", $username);
	
	my $list	=	$self->novaList($nodename);
	
	my $entries	=	$self->parseList($list);
	my $ips		=	$self->parseIps($entries);
	
	return $ips;
}

method parseIps ($entries) {
	my $ips	=	[];
	foreach my $entry ( @$entries ) {
		my $ipentry	=	$$entry[5];
		$ipentry	=~ s/^.+=//;
		$ipentry 	=~ s/\s+//;
		$self->logDebug("entry", $ipentry);
		
		if ( $ipentry =~ /,/ ) {
			my @pair	=	split ",", $ipentry;
			push @$ips, {
				internal	=>	$pair[0],
				external	=>	$pair[1]
			};
		}
		else {
			push @$ips, {
				internal	=>	$ipentry,
				external	=>	""
			};
		}
	}

	return $ips;	
}

method novaList ($nodename) {
	my $exports	=	$self->getExports();
	$self->logDebug("exports", $exports);
	
	#### CHECK IF NOVA IS INSTALLED
	print "'nova' executable not found in path\n" and exit if `which nova` eq "";
	
	my $command	=	"$exports nova list";
	$command	=	"$exports nova list --name $nodename" if defined $nodename and $nodename ne "";
	$self->logDebug("command", $command);

	return `$command`;
}

method novaDelete ($id) {
	$self->logDebug("id", $id);

	return if not defined $id or $id eq "";
	$self->logDebug("DOING novaDelete");
	
	my $exports	=	$self->getExports();
	#$self->logDebug("exports", $exports);
	
	my $command	=	"$exports nova delete $id";
	$self->logDebug("command", $command);

	return `$command`;
}

method getExports {
	my $keypairs	=	{
		"username"		=>	"OS_USERNAME",
		"tenantid"		=>	"OS_TENANT_ID",
		"tenantname"	=>	"OS_TENANT_NAME",
		"authurl"		=>	"OS_AUTH_URL",
		"password"		=>	"OS_PASSWORD"
	};
	my $exports = "";
	foreach my $key ( keys %$keypairs ) {
		my $value	=	$self->conf()->getKey("openstack:$key", undef);
		if ( defined $value and $value ne "" ) {
			my $label	=	$keypairs->{$key};
			#$self->logDebug("label", $label);
			$exports	.=	"export $label='$value'; ";
		}
	}
	#$self->logDebug("exports", $exports);
	
	return $exports;
}

method parseList ($list) {
	my $ips		=	[];
	
	my @lines	=	split "\n", $list;
	shift @lines;
	shift @lines;
	shift @lines;
	foreach my $line ( @lines ) {
		next if $line =~ /\+\-\-\-\-\-/;
		push @$ips, $self->parseLine($line);
	}

	return $ips;	
}

method parseEntries ($list) {
	my $entries		=	[];
	
	my @lines	=	split "\n", $list;
	shift @lines;
	my $columns	=	$self->parseLine(shift @lines);
	shift @lines;
	shift @lines;
	foreach my $line ( @lines ) {
		next if $line =~ /\+\-\-\-\-\-/;
		my $array	=	$self->parseLine($line);
		#$self->logDebug("array", $array);
		my $hash = {};
		for ( my $i = 0; $i < @$array; $i++ ) {
			my $key	=	lc($$columns[$i]);
			if ( $key eq "networks" ) {
				my ($internal, $external)	=	$self->parseNetworks($$array[$i]);
				
				$hash->{internalip}	=	$internal;
				$hash->{externalip}	=	$external;
			}
			else {
				$key =~ s/\s+//g;
				$hash->{$key}	=	$$array[$i]
			}
		}
		push @$entries, $hash;
		#$self->logDebug("hash", $hash);
	}

	return $entries;	
}

method parseNetworks ($entry) {
	$entry	=~ s/^.+=//;
	$entry 	=~ s/\s+//;
	#$self->logDebug("entry", $entry);

	if ( $entry =~ /,/ ) {
		my @array	=	split ",", $entry;
		return $array[0], $array[1];
	}
	else {
		return $entry, "";
	}
}

method parseLine ($line) {
	$line =~ s/^\s*\|\s*//;
	my @array	=	split "\\|", $line;
	#$self->logDebug("array", \@array);
	foreach my $entry ( @array ) {
		$entry =~ s/^\s+//;
		$entry =~ s/\s+$//;
	}
	#$self->logDebug("array", \@array);
	
	return \@array;
}

method setUsername {
	$self->logDebug("");

	return $self->conf()->getKey("openstack:username", undef);
}

method setJsonParser {
	return JSON->new->allow_nonref;
}

method usage {
	print `perldoc $0`;
	exit;
}



1;