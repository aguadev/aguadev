package Agua::Common::Ssh;
use Moose::Role;

has 'keyname'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);

use Agua::Ssh;

=head2

	PACKAGE		Agua::Common::Ssh
	
	PURPOSE
	
		CLUSTER METHODS FOR Agua::Common

=cut
use Data::Dumper;
use File::Path;

has 'keypairfile'	=> ( is  => 'rw', 'isa' => 'Str|Undef', required	=>	0	);

sub _setSsh {
	my $self		=	shift;
	my $username	=	shift;
	my $hostname	=	shift;
	my $keyfile		=	shift;

	$self->logDebug("username", $username);
	$self->logDebug("hostname", $hostname);
	$self->logDebug("keyfile", $keyfile);
	
	my $ssh = Agua::Ssh->new(
		remoteuser	=> 	$username,
		keyfile		=> 	$keyfile,
		remotehost	=>	$hostname
	);
	$self->ssh($ssh);
	
	return $ssh;
}

sub setKeypairFile {
#### SET SSH COMMAND IF KEYPAIRFILE, ETC. ARE DEFINED
	my $self		=	shift;
	my $username	=	shift;
	$username = $self->username() if not defined $username;
	$self->logError("username not defined") and exit if not defined $username;

	my $keyname 	= 	"$username-key";
	my $conf 		= 	$self->conf();
	$self->logDebug("conf", $conf);
	my $userdir 	= 	$conf->getKey('agua', "USERDIR");
	$self->logCaller("userdir not defined") and exit if not defined $userdir;

	my $keypairfile = "$userdir/$username/.starcluster/id_rsa-$keyname";

	my $adminkey 	= 	$self->getAdminKey($username);
	$self->logDebug("adminkey", $adminkey);
	return if not defined $adminkey;
	my $configdir = "$userdir/$username/.starcluster";
	if ( $adminkey ) {
		my $adminuser = $self->conf()->getKey("agua", "ADMINUSER");
		$self->logDebug("adminuser", $adminuser);
		my $keyname = "$adminuser-key";
		$keypairfile = "$userdir/$adminuser/.starcluster/id_rsa-$keyname";
	}
	$self->keypairfile($keypairfile);
	
	return $keypairfile;
}


sub _enableSshPasswordLogin {
	my $self	=	shift;
	
	my $configfile 	= 	$self->getSshConfigFile();
	$self->logDebug("configfile", $configfile);
	my $contents  	=	$self->getFileContents($configfile);

	#### ENABLE PASSWORD LOGIN
	$contents =~ s/PasswordAuthentication\s+\S+//;
	$contents .= qq{\n\nPasswordAuthentication yes\n\n};
	
	
	$self->printToFile($configfile, $contents);	
}

sub _disableSshPasswordLogin {
	my $self	=	shift;
	
	my $configfile 	= 	$self->getSshConfigFile();
	$self->logDebug("configfile", $configfile);
	my $contents  	=	$self->getFileContents($configfile);
	$self->logDebug("BEFORE contents", $contents);

	#### DISABLE PASSWORD LOGIN
	$contents =~ s/PasswordAuthentication\s+\S+/PasswordAuthentication no/;
	$self->logDebug("AFTER contents", $contents);
	
	$self->printToFile($configfile, $contents);	
}

sub getSshConfigFile {
	my $self		=	shift;
	
	return "/etc/ssh/ssh_config";
}


1;