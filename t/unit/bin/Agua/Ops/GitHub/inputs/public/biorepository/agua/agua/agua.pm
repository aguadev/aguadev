package agua;
use Moose::Role;
use Method::Signatures::Simple;

use Data::Dumper;

has 'tempconf'	=> ( isa => 'Str|Undef', is => 'rw', default	=>	'/agua'	);
has 'installdir'=> ( isa => 'Str|Undef', is => 'rw', default	=>	'/agua'	);
has 'version'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
#has 'repo'		=> ( isa => 'Str|Undef', is => 'rw', default	=> 'bitbucket'	);
has 'repo'		=> ( isa => 'Str|Undef', is => 'rw', default	=> 'github'	);

####///}}}}
method preInstall {
	$self->logDebug("");
	#$self->checkInputs();

	my $pwd = $self->pwd();

	my 	$username 		= $self->username();
	my 	$version 		= $self->version();
	my  $package 		= $self->package();
	my  $hubtype 		= $self->hubtype();
	my 	$owner 			= $self->owner();
	my 	$private 		= $self->private();
	my  $repository 	= $self->repository();
	
	my $currentversion = $self->conf()->getKey('agua', 'VERSION');

	$self->logError("owner not defined") and exit if not defined $owner;
	$self->logError("package not defined") and exit if not defined $package;
	$self->logError("username not defined") and exit if not defined $username;
	$self->logError("hubtype not defined") and exit if not defined $hubtype;
	$self->logError("repository not defined") and exit if not defined $repository;
	$self->logError("currentversion not defined") and exit if not defined $currentversion;
	
	$self->logDebug("owner", $owner);
	$self->logDebug("package", $package);
	$self->logDebug("username", $username);
	$self->logDebug("hubtype", $hubtype);
	$self->logDebug("repository", $repository);
	$self->logDebug("currentversion", $currentversion);
	$self->logDebug("private", $private) if defined $private;
	$self->logDebug("version", $version) if defined $version;

	#### SET HTML LOGFILE
	my $logfile = $self->setLogfile($package);

	#### SEND STATUS
	print "{ status: 'installing', url: '$logfile', version: '$version' }";

	#### FAKE TERMINATION
	$self->fakeTermination(5);
	$self->logDebug("AFTER fakeTermination");

	#### START LOGGING TO HTML FILE
	$self->logDebug("logfile", $logfile);
	$self->startHtmlLog($package, $version, $logfile);

	$self->updateReport(["Doing preInstall"]);
	$self->updateReport(["Current version: $currentversion"]);

	$self->logDebug("repository", $repository);
	$self->logDebug("owner", $owner);
	$self->logDebug("package", $package);

	#### SET VARIABLES
    $self->owner("agua");
	$self->repository("agua");
	$self->version(undef);
	$self->package("agua");
	$self->hubtype("github");
	$self->private(0);
	$self->username($self->conf()->getKey("database", "TESTUSER"));
	$self->branch("master");
	$self->installdir("$pwd/outputs/agua");	
	$self->opsdir("$pwd/../../../../../repos/public/biorepository/syoung/agua");
	
	#### COPY AND REPLACE conf FILE
	my $installdir = $self->installdir();
	my $tempconf = "/tmp/default.conf." . rand(9999);
	$self->runCommand("cp $installdir/conf/default.conf $tempconf");
	$self->runCommand("chmod 600 $tempconf");

	
	return "Completed preInstall";
}

method postInstall {
	$self->logDebug("");
	
	#### UPDATE AGUA VERSION IN CONFIG
	my $installdir	=	$self->installdir();
	$installdir = "/agua" if not defined $installdir;
	$self->logDebug("installdir", $installdir);

	my $tempconf = $self->tempconf();
	$self->logDebug("tempconf", $tempconf);
	$self->runCommand("mv $tempconf $installdir/conf/default.conf");

	#### RUN INSTALL TO SET PERMISSIONS, ETC.
	$self->changeDir("$installdir/bin/scripts");
	my $command = "$installdir/bin/scripts/install.pl --installdir $installdir";
	$self->logDebug("command", $command);
	$self->runInstaller($command);

	#### UPDATE VERSION IN CONFIG FILE
	my $version = $self->version();
	my $package	= $self->package();
	$self->setConfigVersion ($package, $version);

	return "Completed postInstall";
}


1;
