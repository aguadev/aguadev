package biorepository;
use Moose::Role;
use Method::Signatures::Simple;

has 'installdir'=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'version'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'repotype'	=> ( isa => 'Str|Undef', is => 'rw', default	=> 'github'	);
has 'mountpoint'=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);

####///}}}}

method doInstall ($installdir, $version) {
	$self->logDebug("version", $version);
	$self->logDebug("installdir", $installdir);

	$version 	= 	$self->gitUpdate($installdir, $version);
	
	$self->confirmInstall($installdir, $version);
	
	my $owner	=	$self->owner();
	my $username	=	$self->username();
	my $package	=	$self->package();
	$self->deletePackage($owner, $username, $package);
	
	return 1;
}

method setConfKey($installdir, $package, $version, $opsinfo) {
	$self->logDebug("installdir", $installdir);
	$self->logDebug("package", $package);
	$self->logDebug("version", $version);
	print "Can't update config file - 'version' not defined\n" and exit if not defined $version;
	
	my $current	=	$self->conf()->getKey("packages", $package);
	undef $current->{$version};
	$current->{$version} = {
		INSTALLDIR	=>	$installdir,
	};
	
	$self->conf()->setKey("packages", "$package", $current);
}
	

1;