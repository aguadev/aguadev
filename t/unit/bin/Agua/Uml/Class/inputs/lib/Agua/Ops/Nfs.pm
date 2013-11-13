package Agua::Ops::Nfs;
use Moose::Role;
use Method::Signatures::Simple;
#### NFS METHODS

method restartNfs {
	#### CHECK LINUX FLAVOUR
	my $uname = $self->runCommand("uname -a");
	$self->logDebug("uname", $uname);
	
	#### SET BINARIES ACCORDING TO FLAVOUR
	my $portmapbinary = "service portmap";
	my $nfsbinary = "service nfs";
	if ( $uname =~ /ubuntu/i )
	{
		$portmapbinary = "/etc/init.d/portmap";
		$nfsbinary = "/etc/init.d/nfs";
	}

	$self->logDebug("$portmapbinary restart");
	$self->logDebug("$nfsbinary restart");

	#### RESTART SERVICES
	$self->runCommand("$portmapbinary restart");
	$self->runCommand("$nfsbinary restart");
}

method mountNfs ($source, $sourceip, $mountpoint) {
#### MOUNT EXPORTED NFS volume
	#### remotehost IS THE HOST MOUNTING THE SHARE
	$self->logDebug("Ops::mountNfs(source, sourceip, mountpoint, keypairfile, remotehost)");
	$self->logDebug("source", $source);
	$self->logDebug("sourceip", $sourceip);
	$self->logDebug("mountpoint", $mountpoint);

	##### CREATE MOUNTPOINT DIRECTORY
	$self->runCommand("mkdir -p $mountpoint") if not $self->foundDirectory($mountpoint);

	my $command = "mount -t nfs $sourceip:$source $mountpoint";
	$self->logDebug("command", $command);

	#### MOUNT NFS SHARE TO MOUNTPOINT
	$self->runCommand($command);
}

method unmount ($mountpoint, $args) {
#### MOUNT EXPORTED NFS volume
	#### remotehost IS THE HOST MOUNTING THE SHARE
	$self->logDebug("Ops::unmount(source, sourceip, mountpoint, keypairfile, remotehost)");
	$args = '' if not defined $args;
	my $command = "umount $args $mountpoint";
	$self->logDebug("command", $command);

	#### MOUNT NFS SHARE TO MOUNTPOINT
	$self->runCommand($command);
}


1;