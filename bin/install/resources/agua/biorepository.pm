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
	
	return $version;
}

1;