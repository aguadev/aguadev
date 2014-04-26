package Agua::Ops::Install;
use Moose::Role;
use Method::Signatures::Simple;
use JSON;

=head2

	PACKAGE		Agua::Ops::Install
	
	PURPOSE
	
		ROLE FOR GITHUB REPOSITORY ACCESS AND CONTROL

=cut

# Bool
has 'showreport'=> ( isa => 'Bool|Undef', is => 'rw', default		=>	1	);
has 'opsmodloaded'	=> ( isa => 'Bool|Undef', is => 'rw', default	=>	0	);

# Strings
has 'arch'		=> ( isa => 'Str|Undef', is => 'rw', required	=> 	0	);
has 'random'	=> ( isa => 'Str|Undef', is => 'rw', required	=> 	0	);
has 'pwd'		=> ( isa => 'Str|Undef', is => 'rw', required	=> 	0	); # TESTING
has 'appdir'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'report'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);

requires 'opsrepo';
requires 'version';

# Objects
has 'opsfields'	=> ( isa => 'ArrayRef', is => 'rw', required	=>	0	, default	=>	sub {[
	"package",
	"repository",
	"version",
	"privacy",
	"owner",
	"login",
	"hubtype"
]}
);
has 'opsdata'	=> ( isa => 'HashRef', is => 'rw', required	=>	0	);
has 'opsinfo'	=> ( isa => 'Agua::OpsInfo', is => 'rw', required	=>	0	);
has 'dependents'=> ( isa => 'ArrayRef', is => 'rw', required	=>	0,	default	=>	sub {[]});

use FindBin qw($Bin);
use lib "$Bin/../..";

#### EXTERNAL MODULES
use Data::Dumper;
use File::Path;
use JSON;

####/////}}}

#### PACKAGE INSTALLATION
method install {
	$self->logDebug("DOING setUpInstall");
	$self->setUpInstall();

	#### SET INSTALLDIR
	my $installdir		=	$self->installdir();
	$installdir = $self->installdir($self->collapsePath($installdir));

	#### SET OPSDIR
	my $opsdir			=	$self->opsdir();
	$opsdir = $self->opsdir($self->collapsePath($opsdir));

	my $package		=	$self->package();
	my $version		=	$self->version();
	$self->logDebug("version", $version);
	
	#### RUN INSTALL
	$self->logDebug("installdir", $installdir);
	$self->logDebug("DOING runInstall");
	
	return $self->runInstall($opsdir, $installdir, $package, $version);
}

method checkInputs {
	$self->logDebug("");

	my 	$username 		= $self->username();
	my 	$version 		= $self->version();
	my  $package 		= $self->package();
	my  $repotype 		= $self->repotype();
	my 	$owner 			= $self->owner();
	my 	$privacy 		= $self->privacy();
	my  $repository 	= $self->repository();
	my  $installdir 	= $self->installdir();
	my  $random 		= $self->random();

	if ( not defined $package or not $package ) {
		$package = $self->repository();
		$self->package($package);
	}
	$self->logError("owner not defined") and exit if not defined $owner;
	$self->logError("package not defined") and exit if not defined $package;
	$self->logError("version not defined") and exit if not defined $version;
	$self->logError("username not defined") and exit if not defined $username;
	$self->logError("installdir not defined") and exit if not defined $installdir;
	
	$self->logDebug("owner", $owner);
	$self->logDebug("package", $package);
	$self->logDebug("username", $username);
	$self->logDebug("repotype", $repotype);
	$self->logDebug("repository", $repository);
	$self->logDebug("installdir", $installdir);
	$self->logDebug("privacy", $privacy);
	$self->logDebug("version", $version);
	$self->logDebug("random", $random);
}

method setUpInstall {
	
	my $opsdir		=	$self->opsdir();
	my $installdir	=	$self->installdir();
	my $package		=	$self->package();
	$self->logDebug("opsdir", $opsdir);
	$self->logDebug("package", $package);

	#### LOAD OPS MODULE IF PRESENT
	$self->logDebug("self->opsmodloaded()", $self->opsmodloaded());
	$self->loadOpsModule($opsdir, $package) if not $self->opsmodloaded();
	
	#### LOAD OPS INFO IF PRESENT
	$self->loadOpsInfo($opsdir, $package) if not defined $self->opsinfo();

	#### SET USERNAME
	my $username		=	$self->username();
	if ( not defined $username ) {
		$username = $self->conf()->getKey('agua', 'ADMINUSER');
		$self->username($username);
	}

	#### SET PWD - USED IN TESTING
	$self->pwd($Bin) if not defined $self->pwd();

	#### SET DATABASE HANDLE IF NOT DEFINED
	$self->setDbObject() if not defined $self->db() or not defined $self->db()->dbh();

	#### CHECK DEPENDENCIES
	$self->installDependencies($opsdir, $installdir);
}

method installDependencies ($opsdir, $installdir) {
	$self->logDebug("opsdir", $opsdir);
	$self->logDebug("installdir", $installdir);

	return if not defined $self->opsinfo();
	
	my $dependencies	=	$self->opsinfo()->dependencies();
	$self->logDebug("dependencies", $dependencies);
	$dependencies = [] if not defined $dependencies;
	
	my $missing	=	[];
	foreach my $dependency ( @$dependencies ) {
		$self->logDebug("dependency", $dependency);
		
		push @$missing, $dependency if not $self->dependencyIsMet($dependency);
	}
	$self->logDebug("missing", $missing);

	my $dependents	=	$self->dependents();
	push @$dependents, $self->package();

	foreach my $missed ( @$missing ) {
		my $package	=	$missed->{package};
		my $version	=	$missed->{version};
		my $targetdir;
		$self->logDebug("package", $package);
		$self->logDebug("version", $version);
		if ( $missed->{installdir} ) {
			$targetdir	=	"$missed->{installdir}/$package";
			$targetdir =~ s/%INSTALLDIR%/$installdir/g;
		}
		else {
			my $basedir	=	$self->getBaseDir($installdir);
			$targetdir	=	"$basedir/$package";
		}

		my $opsdir 	=	$self->opsdir();
		($opsdir)	=	$opsdir	=~ /^(.+?)\/[^\/]+$/;
		$opsdir 	.= "/$package";
		$self->logDebug("opsdir", $opsdir);

		my $packagename	=	$package;
		$packagename	=~ s/\-//g;
		my $opsfile	=	"$opsdir/$package/$packagename.ops";
		my $pmfile	=	"$opsdir/$package/$packagename.pm";
		$self->logDebug("opsfile", $opsfile);
		$self->logDebug("pmfile", $pmfile);
		
		$self->logDebug("DOING object = Agua::Deploy->new()");
		my $object = Agua::Ops->new({
			conf        =>  $self->conf(),
			opsrepo  	=>  $self->opsrepo(),
			opsdir  	=>  $opsdir,
			installdir	=>	$targetdir,
			package  	=>  $package,
			version  	=>  $version,
			opsfile  	=>  $opsfile,
			pmfile  	=>  $pmfile,
			dependents	=>	$dependents,
			repository  =>  $missed->{repository},
			owner  		=>  $missed->{owner},

			login  		=>  $self->login(),
			token  		=>  $self->token(),
			keyfile  	=>  $self->keyfile(),
			password  	=>  $self->password(),
		
			showlog     =>  $self->showlog(),
			printlog    =>  $self->printlog(),
			logfile     =>  $self->logfile()
		});

		$object->install();
	}
}

method dependencyIsMet ($dependency) {
	$self->logDebug("dependency", $dependency);
	
	my $package		=	$dependency->{package};
	my $version		=	$dependency->{version};
	my $query	=	qq{SELECT 1 FROM package
WHERE package='$package'
AND version='$version'};
	$self->logDebug("query", $query);

	return $self->db()->query($query);
}


method runInstall ($opsdir, $installdir, $package, $version) {

	$self->logDebug("opsdir", $opsdir);
	$self->logDebug("installdir", $installdir);
	$self->logDebug("package", $package);
	$self->logDebug("version", $version);
	$self->version($version);

	#### PRE-INSTALL
	$self->logDebug("BEFORE preInstall");
	my $report = $self->preInstall($installdir, $version) if $self->can('preInstall');
	#$self->updateReport([$report]) if defined $report;
	#$report = undef;
	#$self->logDebug("AFTER self->preInstall");

	#### SET VARIABLES
	my $repository		=	$self->repository();
	my $owner 			= 	$self->owner();
	my $login			=	$self->login();
	my $keyfile			=	$self->keyfile();
	my $hubtype			=	$self->hubtype();
	my $username		=	$self->username();
	$self->logDebug("repository", $repository);
	$self->logDebug("owner", $owner);

	#### SET DATABASE OBJECT
	$self->setDbObject() if not defined $self->db();

	#### DO INSTALL
	$self->logDebug("DOING self->doInstall");
	return 0 if $self->can('doInstall') and not $self->doInstall($installdir, $version);

	#### POST-INSTALL
	$version = $self->version();
	return 0 if $self->can('postInstall') and not $self->postInstall($installdir, $version);
	
	##### UPDATE REPORT
	#$self->updateReport([$report]) if defined $report;
	
	#### UPDATE PACKAGE IN DATABASE
	#$self->logger()->write("Updating 'package' table");
	$self->updatePackage($owner, $username, $package, $version);
	
	#### SET CONF
	$self->logDebug("DOING setConfKey    version", $version);
	$self->setConfKey($package, $version, $installdir, $self->opsinfo());

	#### REPORT VERSION
	#$self->logger()->write("Completed installation, version: $version");

	#### TERMINAL INSTALL
	#$self->logger()->write("BEFORE terminalInstall method");
	$version = $self->version();
	$report = $self->terminalInstall($installdir, $version);
	$self->updateReport([$report]) if defined $report and $report;
	
	#### E.G., DEBUG/TESTING
	#return $self->logger->report();
}
method setConfKey ($package, $version, $installdir, $opsinfo) {
	$self->logDebug("package", $package);
	$self->logDebug("version", $version);
	$self->logDebug("opsinfo", $opsinfo);
	print "Can't update config file - 'version' not defined\n" and exit if not defined $version;

	my $current	=	$self->conf()->getKey("packages", $package);
	undef $current->{$version};
	$current->{$version} = {
		#AUTHORS 	=> 	$opsinfo->authors(),
		#PUBLICATION	=>	$opsinfo->publication(),
		INSTALLDIR	=>	"$installdir/$version",
	};

	$self->conf()->setKey("packages", "$package", $current);
}

method installedVersions ($package) {
	my $query	=	qq{SELECT package,installdir, version
FROM package
WHERE package='$package'};
	$self->logDebug("query", $query);
	
	return $self->db()->queryhasharray($query);
}
#### INSTALL TYPES
method gitInstall ($installdir, $version) {

	my $repository		=	$self->repository();
	my $owner 			= 	$self->owner();
	my $login			=	$self->login() || "";
	my $keyfile			=	$self->keyfile() || "";
	my $privacy 		= 	$self->privacy();
	my $credentials 	= 	$self->credentials();
	my $username		=	$self->username();
	my $hubtype			=	$self->hubtype();

	#### ENSURE MINIMUM DATA IS AVAILABLE
	$self->logCritical("repository not defined") and exit if not defined $repository;
	$self->logCritical("owner not defined") and exit if not defined $owner;
	$self->logCritical("hubtype not defined") and exit if not defined $hubtype;

	$self->logDebug("login", $login);
	$self->logDebug("version", $version);
	$self->logDebug("installdir", $installdir);
	$self->logDebug("repository", $repository);
	$self->logDebug("owner", $owner);
	$self->logDebug("login", $login);
	$self->logDebug("username", $username);
	$self->logDebug("hubtype", $hubtype);
 	$self->logDebug("privacy", $privacy);
	$self->logDebug("keyfile", $keyfile);

	if ( not defined $version ) {
		$version	=	$self->latestVersion($owner, $repository, $privacy, $hubtype);
		$self->logDebug("version", $version);
		$self->version($version);
	}	

	#### MAKE INSTALL DIRECTORY
	$self->makeDir($installdir) if not -d $installdir;	
	$self->logCritical("Can't create installdir", $installdir) and return 0 if not -d $installdir;

	#### SET DEFAULT KEYFILE
	$keyfile = $self->setKeyfile($username, $hubtype) if $privacy ne "public" and $keyfile eq "";
	
	#### DELETE DIRECTORY IF EXISTS
	my $targetdir = "$installdir/$version";
	`rm -fr $targetdir`;
	$self->logCritical("Can't delete targetdir: $targetdir") and return 0 if -d $targetdir;
	
	#### ADD HUB TO /root/.ssh/authorized_hosts FILE	
	$self->addHubToAuthorizedHosts($login, $hubtype, $keyfile, $privacy);	
	$self->logDebug("login", $login);
	
	#### UPDATE REPORT
	$self->updateReport(["Cloning from remote repo: $repository (owner: $owner, login: $login)"]);
	$self->logDebug("Cloning from remote repo");
	
	#### CLONE REPO
	$self->logDebug("Doing self->changeDir()");
	$self->changeToRepo($installdir);
	$self->logDebug("Doing self->cloneRemoteRepo()");
	my $success = $self->cloneRemoteRepo($owner, $repository, $hubtype, $login, $privacy, $keyfile, $version);
	$self->logDebug("FAILED to clone repo    success: $success") and return 0 if not $success;
	
	##### CHECKOUT SPECIFIC VERSION
	$self->logDebug("Doing changeToRepo installdir", "$targetdir");
	my $change = $self->changeToRepo("$targetdir");
	$self->logDebug("change", $change);
	$self->checkoutTag("$targetdir", $version);
	#$self->logger()->write("Checked out version: $version");
	$self->logDebug("checked out version", $version);
	
	#### VERIFY CHECKED OUT VERSION == DESIRED VERSION
	$self->verifyVersion("$targetdir", $version) if $self->foundGitDir("$targetdir");
	$self->version($version);
	
	return 1;
}

method gitUpdate ($installdir, $version) {

	my $repository		=	$self->repository();
	my $owner 			= 	$self->owner();
	my $login			=	$self->login();
	my $keyfile			=	$self->keyfile();
	my $privacy 		= 	$self->privacy();
	my $credentials 	= 	$self->credentials();
	my $username		=	$self->username();
	my $hubtype			=	$self->hubtype();

	#### ENSURE MINIMUM DATA IS AVAILABLE
	$self->logCritical("repository not defined") and exit if not defined $repository;
	$self->logCritical("owner not defined") and exit if not defined $owner;
	$self->logCritical("hubtype not defined") and exit if not defined $hubtype;

	$self->logDebug("login", $login);
	$self->logDebug("version", $version);
	$self->logDebug("installdir", $installdir);
	$self->logDebug("repository", $repository);
	$self->logDebug("owner", $owner);
	$self->logDebug("login", $login);
	$self->logDebug("username", $username);
	$self->logDebug("hubtype", $hubtype);

	#### SET DEFAULT KEYFILE
	$keyfile = $self->setKeyfile($username, $hubtype) if not defined $keyfile or not $keyfile;

	#### VALIDATE VERSION IF SUPPLIED, OTHERWISE SET TO LATEST VERSION
	if ( defined $version ) {
		if ( $version eq "latest" ) {
			$version	=	$self->getLatestVersion($login, $repository, $privacy, $version);
			$self->version($version);
		}
		elsif ( $version ne "" ) {
			$self->logDebug("Failed to validate version: $version'") and return 0 if not $self->validateVersion($login, $repository, $privacy, $version);
		}
	}
	$self->logDebug("version", $version);

	#### CHECK IF REPO EXISTS
	$self->logDebug("installdir", $installdir);
	my $found = $self->foundDir($installdir);
	$self->logDebug("found", $found);
	
	#### ADD HUB TO /root/.ssh/authorized_hosts FILE	
	$self->addHubToAuthorizedHosts($login, $hubtype, $keyfile, $privacy);
	
	$self->logDebug("login", $login);

	#### CLONE REPO IF NOT EXISTS
	my $loginpresent = $login;
	$loginpresent = "" if not defined $login;
	if ( $found == 0 ) {
		$self->updateReport(["Cloning from remote repo: $repository (owner: $owner, login: $loginpresent)"]);
		$self->logDebug("Cloning from remote repo");
		$self->logDebug("installdir not found. Cloning repo $repository (login: $loginpresent)");
		
		#### PREPARE DIRS
		my ($basedir, $subdir) = $self->getParentChildDirs($installdir);
		$self->logDebug("basedir", $basedir);
		$self->logDebug("subdir", $subdir);
		`mkdir -p $basedir` if not -d $basedir;
		$self->logCritical("Can't create basedir", $basedir) and return 0 if not -d $basedir;
	
		#### CLONE REPO
		$self->changeToRepo($basedir);
		$self->logDebug("keyfile", $keyfile);
		$self->logDebug("Doing self->cloneRemoteRepo()");
		$self->logDebug("FAILED to clone repo") and return 0 if not $self->cloneRemoteRepo($owner, $repository, $hubtype, $login, $privacy, $keyfile, $subdir);
	}
	
	#### OTHERWISE, MOVE TO REPO AND PULL
	else {
		$self->updateReport(["Pulling from remote repo: $repository (owner: $owner, login: $loginpresent)"]);
		$self->logDebug("Pulling from remote repo");
	
		#### PREPARE DIR
		$self->changeToRepo($installdir);	
		$self->initRepo($installdir) if not $self->foundGitDir($installdir);
	
		#### fetch FROM REMOTE AND DO HARD RESET
		$self->logDebug("FAILED to fetch repo") and return 0 if not $self->fetchResetRemoteRepo($owner, $repository, $hubtype, $login, $privacy, $keyfile);
	
		#### SAVE ANY CHANGES IN A SEPARATE BRANCH
		$self->saveChanges($installdir, $version);
	}
	
	##### CHECKOUT SPECIFIC VERSION
	$self->logDebug("Doing changeToRepo installdir", $installdir);
	my $change = $self->changeToRepo($installdir);
	$self->logDebug("change", $change);
	
	$self->checkoutTag($installdir, $version);
	#$self->logger()->write("Checked out version: $version");
	$self->logDebug("checked out version", $version);
	
	#### VERIFY CHECKED OUT VERSION = DESIRED VERSION
	$self->verifyVersion($installdir, $version) if $self->foundGitDir($installdir);
	$self->version($version);
	
	return 1;
}

method zipInstall ($installdir, $version) {
	$self->logDebug("self->opsinfo", $self->opsinfo());
	my $fileurl	=	$self->opsinfo()->url();
	$fileurl =~ s/\$version\s*/$version/g;
	$self->logDebug("fileurl", $fileurl);
	
	my ($filename)	=	$fileurl	=~ /^.+?([^\/]+)$/;
	$self->logDebug("filename", $filename);
	
	#### CHECK IF FILE IS AVAILABLE
	my $exists 	=	$self->remoteFileExists($fileurl);
	$self->logDebug("exists", $exists);
	if ( not $exists ) {
		$self->logDebug("Remote file does not exist. Exiting");
		print "Remote file does not exist: $fileurl\n";
		exit;
	}
	
	#### DELETE DIRECTORY AND ZIPFILE IF EXIST
	my $targetdir = "$installdir/$version";
	`rm -fr $targetdir`;
	$self->logCritical("Can't delete targetdir: $targetdir") and exit if -d $targetdir;
	my $targetfile	=	"$installdir/$filename";
	`rm -fr $targetfile` if -f $targetfile;
	$self->logCritical("Can't delete targetfile: $targetfile") and exit if -d $targetfile;

	#### MAKE INSTALL DIRECTORY
	$self->makeDir($installdir) if not -d $installdir;	

	#$self->logger()->write("Changing to installdir: $installdir");
    $self->changeDir($installdir);

	#$self->logger()->write("Downloading file: $filename");
	$self->runCommand("wget -c $fileurl --output-document=$filename --no-check-certificate");
	
	my $filepath	=	"$installdir/$filename";
	$self->logDebug("filepath", $filepath);
	return 0 if not -f $filepath or -z $filepath;

	#### GET ZIPTYPE
	my $ziptype = 	"tar";
	$ziptype	=	"bz" if $filename =~ /\.bz2$/;
	$ziptype	=	"zip" if $filename =~ /\.zip$/;
	$self->logDebug("ziptype", $ziptype);

	#### GET UNZIPPED FOLDER NAME
	my ($unzipped)	=	$filename	=~ /^(.+)\.tar\.gz/;
	($unzipped)	=	$filename	=~ /^(.+)\.tar\.bz2/ if $ziptype eq "bz";
	($unzipped)	=	$filename	=~ /^(.+)\.zip/ if $ziptype eq "zip";
	if ( defined $self->opsinfo()->unzipped() ) {
		$unzipped	=	$self->opsinfo()->unzipped();
		$unzipped	=~ s/\$version\s*/$version/g;
	}
	$self->logDebug("unzipped", $unzipped);

	#### REMOVE UNZIPPED IF EXISTS
	$self->runCommand("rm -fr $unzipped");

	#### SET UNZIP COMMAND
    $self->changeDir($installdir);
	my $command	=	"tar xvfz $filename";
	$command	=	"tar xvfj $filename" if $ziptype eq "bz";
	$command	=	"unzip $filename" if $ziptype eq "zip";
	$self->logDebug("command", $command);

	#### UNZIP AND CHANGE UNZIPPED TO VERSION
	$self->runCommand($command);	
	$self->runCommand("mv $unzipped $version");	
	
	#### REMOVE ZIPFILE
	$self->runCommand("rm -fr $filename");
	
	my $package	=	$self->opsinfo()->package();
	
	#$self->logger()->write("Completed installation of $package, version $version");
	
	return $version;	
}
method downloadInstall ($installdir, $version) {
	$self->logDebug("self->opsinfo", $self->opsinfo());
	my $fileurl	=	$self->opsinfo()->url();
	$fileurl =~ s/\$version/$version/g;
	$self->logDebug("fileurl", $fileurl);
	
	my ($filename)	=	$fileurl	=~ /^.+?([^\/]+)$/;
	$self->logDebug("filename", $filename);
	
	#### CHECK IF FILE IS AVAILABLE
	my $exists 	=	$self->remoteFileExists($fileurl);
	$self->logDebug("exists", $exists);
	if ( not $exists ) {
		$self->logDebug("Remote file does not exist. Exiting");
		print "Remote file does not exist: $fileurl\n";
		exit;
	}
	
	#### MAKE INSTALL DIRECTORY
	my $targetdir	=	"$installdir/$version";
	$self->makeDir($targetdir) if not -d $targetdir;	

	#$self->logger()->write("Changing to targetdir: $targetdir");
    $self->changeDir($targetdir);

	#$self->logger()->write("Downloading file: $filename");
	$self->runCommand("wget -c $fileurl --output-document=$filename --no-check-certificate");
	
	#### CHANGE NAME IF downloaded DEFINED
	if ( defined $self->opsinfo()->downloaded() ) {
		my $downloaded	=	$self->opsinfo()->downloaded();
		$downloaded	=~ s/\$version/$version/g;
		$self->logDebug("downloaded", $downloaded);
	
		$self->runCommand("mv $filename $downloaded");
	}

	#my $package	=	$self->opsinfo()->package();
	#$self->logger()->write("Completed installation of $package, version $version");
	
	return $version;	
}
method configInstall ($installdir, $version) {
	$self->logDebug("version", $version);
	$self->logDebug("version", $version);

	#### CHANGE DIR
    $self->changeDir("$installdir/$version");
	
	#### MAKE
	$self->runCommand("./configure");
	$self->runCommand("make");
	$self->runCommand("make install");
}

method makeInstall ($installdir, $version) {
	$self->logDebug("version", $version);
	$self->logDebug("version", $version);

	#### CHANGE DIR
    $self->changeDir("$installdir/$version");
	
	#### MAKE
	my ($out, $err) = $self->runCommand("make");
	$self->logDebug("out", $out);
	$self->logDebug("err", $err);
	($out, $err) = $self->runCommand("make install");
	$self->logDebug("out", $out);
	$self->logDebug("err", $err);
}

method confirmInstall ($installdir, $version) {
	$self->logDebug("version", $version);
	$self->logDebug("installdir", $installdir);
	
	my $opsdir		=	$self->opsdir();
	$self->logDebug("opsdir", $opsdir);
	my $file		=	"$opsdir/t/$version/output.txt";
	$self->logDebug("file", $file);
	return 1 if not -f $file;

	my $lines		=	$self->fileLines($file);
	my $command 	=	shift @$lines;
	$command		=~ s/^#//;
	my $executor	=	"";
	if ( $$lines[0] =~ /^#/ ) {
		$executor	=	shift @$lines;
		$executor		=~ s/^#//;
	}
	$self->logDebug("command", $command);
	$self->logDebug("executor", $executor);

	$command 	=	"cd $installdir/$version; $executor $command";
	$self->logDebug("FINAL command", $command);

	my ($output, $error)	=	$self->runCommand($command);
	$output		=	$error if not defined $output or $output eq "";
	my $actual;
	@$actual	=	split "\n", $output;
	#print "actual: ", join "\n", @$actual, "\n";

	for ( my $i = 0; $i < @$lines; $i++ ) {
		my $got	=	$$actual[$i] || ""; #### EXTRA EMPTY LINES
		my $expected	=	$$lines[$i];
		next if $expected =~ /^SKIP/;
		
		if ( $got ne $expected ) {
			$self->logDebug("FAILED TO INSTALL. Mismatch between expected and actual output!\nExpected:\n$expected\n\nGot:\n$got\n\n");
			return 0;
		}
	}
	$self->logDebug("**** CONFIRMED INSTALLATION ****");
	
	return 1;
}
method remoteFileExists ($url) {
	$self->logDebug("url", $url);
	my $checkurl	=	$self->opsinfo()->checkurl();
	$self->logDebug("checkurl", $checkurl);
	return 1 if $checkurl eq "false";
	
	my ($output, $error) =	$self->runCommand("wget --spider $url");
	$self->logDebug("output", $output);
	$self->logDebug("error", $error);
	
	if ( $error =~ /Remote file exists.$/ms ) {
		return 1;
	}
	
	return 0;
}
method preInstall ($installdir, $version) {
	#### OVERRIDE THIS METHOD

	$self->logDebug("installdir", $installdir);
	$self->logDebug("version", $version);

	#### CHECK INPUTS
	$self->logCritical("installdir not defined", $installdir) and exit if not defined $installdir;
}
method doInstall ($installdir, $version) {
	#### OVERRIDE THIS METHOD
	$self->logDebug("installdir", $installdir);
	$self->logDebug("version", $version);
	#$self->logger()->write("Doing doInstall");
	
	return $self->gitInstall($installdir, $version);
}

method postInstall ($installdir, $version) {
	#### OVERRIDE THIS METHOD
	$self->logDebug("installdir", $installdir);
	$self->logDebug("version", $version);
	#$self->logger()->write("Doing postInstall");	
	
	return 1;
}

method terminalInstall ($installdir, $version) {
	#### OVERRIDE THIS METHOD
	$self->logDebug("installdir", $installdir);
	$self->logDebug("version", $version);
	#$self->logger()->write("Doing terminalInstall");	
	
	return 1;
}

#### UTILS
method saveChanges ($installdir, $version) {
	$self->changeToRepo($installdir);
	my $stash = $self->stashSave("before upgrade to $version");
	$self->logDebug("stash", $stash);
	if ( $stash ) {
		#$self->logger()->write("Stashed changes before checkout version: $version");
	}	
}

method runCustomInstaller ($command) {
	$self->logDebug("command", $command);
	print $self->runCommand($command);
}

method verifyVersion ($installdir, $version) {
	$self->logDebug("version", $version);
	$self->logDebug("installdir", $installdir);

	return if not -d $installdir;
	$self->changeToRepo($installdir);	
	my ($currentversion) = $self->currentLocalTag();
	return if not defined $currentversion or not $currentversion;
	$currentversion =~ s/\s+//g;
	if ( $currentversion ne $version ) {
		#### UPDATE PACKAGE STATUS
		$self->updateStatus("error");
		$self->logCritical("Current version ($currentversion) does not match checked out version ($version)");
		exit;
	}
}

method reducePath ($path) {
	while ( $path =~ s/[^\/]+\/\.\.\///g ) { }
	
	return $path;
}

method getArch {    
	my $arch = $self->arch();
    $self->logDebug("STORED arch", $arch) if defined $arch;

	return $arch if defined $arch;
	
	$arch 	= 	"linux";
	my $command = "uname -a";
    my $output = `$command`;
	#$self->logDebug("output", $output);
	
    #### Linux ip-10-126-30-178 2.6.32-305-ec2 #9-Ubuntu SMP Thu Apr 15 08:05:38 UTC 2010 x86_64 GNU/Linux
    $arch	=	 "ubuntu" if $output =~ /ubuntu/i;
    #### Linux ip-10-127-158-202 2.6.21.7-2.fc8xen #1 SMP Fri Feb 15 12:34:28 EST 2008 x86_64 x86_64 x86_64 GNU/Linux
    $arch	=	 "centos" if $output =~ /fc\d+/;
    $arch	=	 "centos" if $output =~ /\.el\d+\./;
	$arch	=	 "debian" if $output =~ /debian/i;
	$arch	=	 "freebsd" if $output =~ /freebsd/i;
	$arch	=	 "osx" if $output =~ /darwin/i;

	$self->arch($arch);
    $self->logDebug("FINAL arch", $arch);
	
	return $arch;
}
method installCpanm {
	$self->changeDir("/usr/bin");
	$self->runCommand("curl -LOk http://xrl.us/cpanm");
	$self->runCommand("chmod 755 cpanm");
}

method installAnt {
	my $arch = $self->getArch();
	$self->logDebug("arch", $arch);
	$self->runCommand("apt-get -y install ant") if $arch eq "ubuntu";
	$self->runCommand("yum -y install ant") if $arch eq "centos";	
}

method getBaseDir ($installdir) {
	$self->logDebug("installdir", $installdir);	
	my ($basedir) 	= 	$installdir	=~	/^(.+?)\/[^\/]+$/;

	return $basedir;
}

#### LOG
method setLogFile ($package, $random) {
	my $htmldir = $self->conf()->getKey('agua', 'HTMLDIR');
	my $logfile = "$htmldir/log/$package-upgradelog.$random.html";
	$self->logfile($logfile);
	
	return $logfile;
}

method setHtmlLogFile {
	my  $package 	= $self->package();
	my  $random 	= $self->random();

	my $htmldir		=	$self->conf()->getKey("agua", 'HTMLDIR');
	my $urlprefix	=	$self->conf()->getKey("agua", 'URLPREFIX');
	my $htmlroot 	=	"$htmldir/$urlprefix";
	$self->logDebug("package", $package);
	$self->logDebug("random", $random);
	$self->logDebug("htmldir", $htmldir);
	$self->logDebug("urlprefix", $urlprefix);
	$self->logDebug("htmlroot", $htmlroot);

	my $logfile = 	"$htmlroot/log/$package-upgradelog";
	$logfile 	.= 	".$random" if defined $random;
	$logfile 	.= 	".html";
	
	#### SET logfile
	$self->logfile($logfile);
	
	return $logfile;
}

method startHtmlLog {

	my $logfile = $self->setHtmlLogFile();
	$self->logDebug("logfile", $logfile);
	my  $package 		= 	$self->package();
	my 	$version 		= 	$self->version();
	#$version			=	"" if not defined $version;

	#### FLUSH STDOUT
	$| = 1;

	$self->logCaller("");
	$self->logDebug("logfile", $logfile);
	`rm -fr $logfile` if -f $logfile;

	#### SET SOURCE AND TARGET
	my $target = $logfile;
	my $found = $self->linkFound($target);
	$self->logDebug("found", $found);
	my $source = "/tmp/$package-upgradelog.html";

	#### CREATE LINK
	$self->removeLink($target);
	$self->addLink($source, $target);
	$self->logDebug("AFTER addLink()");
	
	my $page = $self->setHtmlLogTemplate($package, $version);
	$self->logDebug("AFTER setHtmlLogTemplate()");
	
	#### SET LOGGER
	$self->logDebug("self->logger", $self->logger());
	$self->logger()->showlog(2);
	$self->logger()->printlog(2);
	$self->logDebug("Doing self->logger()->startLog($source)");
	$self->logger()->startLog($source);
	
	$self->logDebug("Doing self->logger->write(page)");
	$self->logger()->write($page);
	$self->logDebug("AFTER self->logger->write(page)");

	#### FLUSH STDOUT
	$| = 1;
}

method setHtmlLogTemplate ($package, $version) {
	my $datetime = `date`;
	return qq{
<html>
<head>
	<title>$package upgrade log</title>
</head>
<body>
<center>
<div class="message"> Upgrading $package to version $version</div>
$datetime<br>
</center>

<pre>};
}

method printLogUrl ($externalip, $aguaversion, $package, $version) {
	my $logurl = "http://$externalip/agua/$aguaversion/log/$package-upgradelog.html";
	print "{ url: '$logurl', version: '$version' }";
}

#### LOAD FILES
method loadOpsModule ($opsdir, $repository) {
	$self->logDebug("opsdir", $opsdir);
	$self->logDebug("repository", $repository);

	return if not defined $opsdir;
	
	my $modulename = lc($repository);
	$modulename =~ s/[\-]+//g;
	$self->logDebug("modulename", $modulename);

	my $pmfile 	= 	"$opsdir/$modulename.pm";
	$self->logDebug("pmfile: $pmfile");
	
	if ( -f $pmfile ) {
		$self->logDebug("\nFound modulefile: $pmfile\nDoing require $modulename");
		unshift @INC, $opsdir;
		my ($olddir) = `pwd` =~ /^(\S+)/;
		$self->logDebug("olddir", $olddir);
		chdir($opsdir);
		eval "require $modulename";
		
		Moose::Util::apply_all_roles($self, $modulename);
	}
	else {
		$self->logDebug("\nCan't find modulefile: $pmfile\n");
		print "Deploy::setOps    Can't find pmfile: $pmfile\n";
		exit;
	}
	$self->opsmodloaded(1);
}

method loadOpsInfo ($opsdir, $package) {
	$self->logDebug("opsdir", $opsdir);
	$self->logDebug("package", $package);
	return if not defined $opsdir or not $opsdir;
	
	return if not defined $opsdir or not $opsdir;

	#### REMOVE -
	$package =~ s/[\-]+//g;
	$self->logDebug("package", $package);

	my $opsfile 	= 	"$opsdir/" . lc($package) . ".ops";
	$self->logDebug("opsfile: $opsfile");
	
	if ( -f $opsfile ) {
		$self->logDebug("Parsing opsfile");
		my $opsinfo = $self->setOpsInfo($opsfile);
		$self->logDebug("opsinfo", $opsinfo);
		$self->opsinfo($opsinfo);
		
		#### LOAD VALUES FROM INFO FILE
		$self->package($opsinfo->package()) if not defined $self->package();
		$self->repository($opsinfo->repository()) if not defined $self->repository();
		$self->version($opsinfo->version()) if not defined $self->version();

		#### SET PARAMS
		my $params = $self->opsfields();
		foreach my $param ( @$params ) {
			$self->$param($self->opsinfo()->$param())
				if $self->can($param)
				and not defined $self->$param()
				and $self->opsinfo()->can($param)
				and defined $self->opsinfo()->$param();
		}
	}
	else {
		
		$self->logDebug("Can't find opsfile", $opsfile);
		
		print "Opsfile not found: $opsfile\n";
	}
}

method loadConfig ($configfile, $mountpoint, $installdir) {

	my $packageconf = Conf::Yaml->new({
		inputfile	=>	$configfile,
		showlog		=>	2
	});

	$self->logNote("packageconf: $packageconf");
	
	my $sectionkeys = $packageconf->getSectionKeys();
	foreach my $sectionkey ( @$sectionkeys ) {
		$self->logNote("sectionkey", $sectionkey);
		my $keys = $packageconf->getKeys($sectionkey);
		$self->logNote("keys", $keys);
		
		#### NB: WILL NOT TRANSFER COMMENTS!!
		foreach my $key ( @$keys ) {
			my $value = $packageconf->getKey($sectionkey, $key);
			$value =~ s/<MOUNTPOINT>/$mountpoint/g;
			$value =~ s/<INSTALLDIR>/$installdir/g;
			$self->logNote("value", $value);
			$self->conf()->setKey($sectionkey, $key, $value);
		}
	}	

}

method loadTsvFile ($table, $file) {
	$self->logCaller("");
	return if not $self->can('db');
	
	$self->logDebug("table", $table);
	$self->logDebug("file", $file);
	
	$self->setDbh() if not defined $self->db();
	return if not defined $self->db();
	my $query = qq{LOAD DATA LOCAL INFILE '$file' INTO TABLE $table};
	my $success = $self->db()->do($query);
	$self->logCritical("load data failed") if not $success;
	
	return $success;	
}

#### UPDATE
method updateConfig ($sourcefile, $targetfile) {
	$self->logDebug("sourcefile", $sourcefile);
	$self->logDebug("targetfile", $targetfile);

	my $sourceconf = Conf::Yaml->new({
		inputfile	=>	$sourcefile,
		showlog		=>	2
	});
	$self->logNote("sourcefile: $sourcefile");

	my $targetconf = Conf::Yaml->new({
		inputfile	=>	$targetfile,
		showlog		=>	2
	});
	$self->logNote("targetconf: $targetconf");

	my $sectionkeys = $sourceconf->getSectionKeys();
	foreach my $sectionkey ( @$sectionkeys ) {
		$self->logNote("source sectionkey", $sectionkey);
		my $keys = $sourceconf->getKeys($sectionkey);
		$self->logNote("source keys", $keys);
		
		#### NB: WILL NOT TRANSFER COMMENTS!!
		foreach my $key ( @$keys ) {
			my $value = $sourceconf->getKey($sectionkey, $key);
			if ( not $targetconf->hasKey($sectionkey, $key) ) {
				
				$self->logNote("key $key value", $value);
				
				$targetconf->setKey($sectionkey, $key, $value);
			}
		}
	}
}

method updateTable ($object, $table, $required, $updates) {
	$self->logCaller("object", $object);
	
	#### SET DEFAULT OBJECT
	$object->{owner} = $object->{username} if not defined $object->{owner};
	
	my $where = $self->db()->where($object, $required);
	my $query = qq{SELECT 1 FROM $table $where};
	$self->logDebug("query", $query);
	my $exists = $self->db()->query($query);
	$self->logDebug("exists", $exists);

	if ( not $exists ) {
		my $fields = $self->db()->fields($table);
		my $insert = $self->db()->insert($object, $fields);
		$query = qq{INSERT INTO $table VALUES ($insert)};
		$self->logDebug("query", $query);
		$self->db()->do($query);
	}
	else {
		my $set = $self->db()->set($object, $updates);
		$query = qq{UPDATE package $set$where};
		$self->logDebug("query", $query);
		$self->db()->do($query);
	}
}

method updateReport ($lines) {
	$self->logWarning("non-array input") if ref($lines) ne "ARRAY";
	return if not defined $lines or not @$lines;
	my $text = join "\n", @$lines;
	
	$self->logReport($text);
	print "$text\n" if $self->showreport();
	
	my $report = $self->report();
	$report .= "$text\n";
	$self->report($report);
}

method updatePackage ($owner, $username, $package, $version) {
	$self->logDebug("owner", $owner);
	$self->logDebug("username", $username);
	$self->logDebug("package", $package);
	$self->logDebug("version", $version);
	#$self->logDebug("self->opsinfo()", $self->opsinfo());

	my $description = "";
	$description = $self->opsinfo()->description() if defined $self->opsinfo();
	my $website = "";
	$website = $self->opsinfo()->website() if defined $self->opsinfo();

	#### UPDATE DATABASE        
	my $object = {
		owner           =>      $owner,
		username        =>      $username,
		package         =>      $package,
		repository      =>      $self->repository() || "",
		status          =>      "ready",
		version         =>      $version,
		opsdir          =>      $self->opsdir() || '',
		installdir      =>      $self->installdir(),
		privacy         =>      $self->privacy() || $self->opsinfo()->privacy(),
		description     =>      $description,
		website         =>      $website
	};
	$self->logDebug("object", $object);

	my $table = "package";
	my $fields	=	$self->db()->fields($table);
	my $required = ["username", "package", "version"];
	
	return $self->updateTable($object, $table, $required, $fields);
}
method deletePackage ($owner, $username, $package) {
	$self->logDebug("owner", $owner);
	$self->logDebug("username", $username);
	$self->logDebug("package", $package);

	#### UPDATE DATABASE
	my $object = {
		owner		=>	$owner,
		username	=>	$username,
		package		=>	$package
	};
	$self->logDebug("object", $object);

	my $table = "package";
	my $fields	=	$self->db()->fields($table);
	my $required = ["owner", "username", "package"];
	
	return $self->db()->_removeFromTable($table, $object, $required);	
}
method updateStatus ($status) {

	$self->logDebug("status", $status);
	#### UPDATE DATABASE
	my $object = {
		username	=>	$self->username(),
		owner		=>	$self->owner(),
		package		=>	$self->package(),
		repository	=>	$self->repository(),
		status		=>	$status,
		version		=>	$self->version(),
		opsdir		=>	$self->opsdir() || '',
		installdir	=>	$self->installdir()
	};
	$self->logDebug("object", $object);
	
	my $table = "package";
	my $required = ["username", "package"];
	my $updates = ["status", "datetime"];
	
	return $self->updateTable($object, $table, $required, $updates);
}

method updateVersion ($version) {
	#### UPDATE DATABASE
	my $object = {
		username	=>	$self->username(),
		owner		=>	$self->owner(),
		package		=>	$self->package(),
		repository	=>	$self->repository(),
		version		=>	$version,
		opsdir		=>	$self->opsdir() || '',
		installdir	=>	$self->installdir()
	};
	$self->logNote("object", $object);
	
	my $table = "package";
	my $required = ["username", "package"];
	my $updates = ["version"];
	
	return $self->updateTable($object, $table, $required, $updates);
}

method validateVersion ($login, $repository, $privacy, $version) {
#### VALIDATE VERSION IF SUPPLIED, OTHERWISE SET TO LATEST VERSION
	$self->logCaller("");
	$self->logDebug("login", $login);
	$self->logDebug("repository", $repository);
	$self->logDebug("privacy", $privacy);
	
	my $tags = $self->getRemoteTags($login, $repository, $privacy);
	$self->logDebug("tags", $tags);

	return if not defined $tags or not @$tags;

	foreach my $tag ( @$tags ) {
		return 1 if $tag->{name} eq $version;
	}

	return 0;
}

method getLatestVersion ($login, $repository, $privacy) {
#### VALIDATE VERSION IF SUPPLIED, OTHERWISE SET TO LATEST VERSION
	$self->logCaller("");
	$self->logDebug("login", $login);
	$self->logDebug("repository", $repository);
	$self->logDebug("privacy", $privacy);
	
	my $tags = $self->getRemoteTags($login, $repository, $privacy);
	#$self->logDebug("tags", $tags);

	return if not defined $tags or not @$tags;
	
	#### SORT VERSIONS
	my $tagarray;
	$tagarray = $self->hasharrayToArray($tags, "name");
	$tagarray = $self->sortVersions($tagarray);
	$self->logDebug("tagarray", $tagarray);

	##### ORDER: FIRST TO LAST
	#@$tagarray = reverse(@$tagarray);
	
	return $$tagarray[scalar(@$tagarray) - 1];
}

#### GET/SETTERS 
method setConfigVersion ($package, $version) {
#### UPDATE VERSION IN CONFIG FILE
	$self->logDebug("package", $package);
	$self->logDebug("version", $version);

	$self->logDebug("Setting version in conf file, version", $version);
	$self->conf()->setKey($package, 'VERSION', $version);
}

method getParentChildDirs ($directory) {
	my ($parent, $child) = $directory =~ /^(.+)*\/([^\/]+)$/;
	$parent = "/" if not defined $parent;

	return if not defined $child;
	return $parent, $child;
}

method setOpsInfo ($opsfile) {	
	my $opsinfo = Agua::OpsInfo->new({
		inputfile	=>	$opsfile,
		logfile		=>	$self->logfile(),
		showlog		=>	4,
		printlog	=>	4
		#showlog		=>	$self->showlog(),
		#printlog	=>	$self->printlog()
	});
	#$self->logDebug("opsinfo", $opsinfo);

	return $opsinfo;
}



1;
