package aguatest;
use Moose::Role;
use Method::Signatures::Simple;

use Data::Dumper;

has 'installdir'=> ( isa => 'Str|Undef', is => 'rw', default	=>	'/agua/t'	);
has 'version'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'repo'		=> ( isa => 'Str|Undef', is => 'rw', default	=> 'github'	);
has 'conffile'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'tempconffile'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);

####///}}}}

#### PRE-INSTALL
method preInstall {
	$self->logDebug("");

	#### SET VARIABLES
    $self->owner("agua");
	$self->repository("aguatest");
	$self->package("aguatest");
	$self->hubtype("github");
	$self->private(0);

	#### CHECK INPUTS
	$self->checkInputs();

	#### START LOGGING TO HTML FILE
	my  $package 		= $self->package();
	my 	$version 		= $self->version();
	my  $random 		= $self->random();
	$self->logDebug("version", $version);
	$self->logDebug("random", $random);

	#### SET HTML LOG FILE
	my $logfile = $self->setHtmlLogFile($package, $random);
	$self->logDebug("logfile", $logfile);

	#### START LOGGING TO HTML FILE
	$self->startHtmlLog($package, $version, $logfile);

	#### REPORT PROGRESSS
	$self->updateReport(["Doing preInstall"]);
	my 	$aguaversion 	= $self->conf()->getKey('agua', 'VERSION');
	$self->updateReport(["Current version: $aguaversion"]);
	
	return "Completed preInstall";
}

method checkInputs {
	my 	$pwd 			= $self->pwd();
	my 	$username 		= $self->username();
	my 	$version 		= $self->version();
	my  $package 		= $self->package();
	my  $hubtype 		= $self->hubtype();
	my 	$owner 			= $self->owner();
	my 	$private 		= $self->private();
	my  $repository 	= $self->repository();	
	my 	$aguaversion 	= $self->conf()->getKey('agua', 'VERSION');

	$self->logError("owner not defined") and exit if not defined $owner;
	$self->logError("version not defined") and exit if not defined $version;
	$self->logError("package not defined") and exit if not defined $package;
	$self->logError("username not defined") and exit if not defined $username;
	$self->logError("hubtype not defined") and exit if not defined $hubtype;
	$self->logError("repository not defined") and exit if not defined $repository;
	$self->logError("aguaversion not defined") and exit if not defined $aguaversion;
	
	$self->logDebug("owner", $owner);
	$self->logDebug("package", $package);
	$self->logDebug("username", $username);
	$self->logDebug("hubtype", $hubtype);
	$self->logDebug("repository", $repository);
	$self->logDebug("aguaversion", $aguaversion);
	$self->logDebug("private", $private);
	$self->logDebug("version", $version);
}

#### POST-INSTALL
method postInstall {
	$self->logDebug("");

	return "Completed postInstall";
}


1;
