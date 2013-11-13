package Agua::Ops::Install;
use Moose::Role;
use Method::Signatures::Simple;
use JSON;

=head2

	PACKAGE		Agua::Ops::Install
	
	PURPOSE
	
		ROLE FOR GITHUB REPOSITORY ACCESS AND CONTROL

=cut

if ( 1 ) {
# Bool
has 'showreport'=> ( isa => 'Bool|Undef', is => 'rw', default		=>	1	);
has 'opsmodloaded'	=> ( isa => 'Bool|Undef', is => 'rw', default	=>	0	);

# Strings
has 'random'	=> ( isa => 'Str|Undef', is => 'rw', required	=> 	0	);
has 'pwd'		=> ( isa => 'Str|Undef', is => 'rw', required	=> 	0	);
has 'appdir'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'report'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);

requires 'opsrepo';
requires 'version';

# Objects
has 'opsdata'	=> ( isa => 'HashRef', is => 'rw', required	=>	0	);
has 'opsinfo'	=> ( isa => 'Agua::OpsInfo', is => 'rw', required	=>	0	);

use FindBin qw($Bin);
use lib "$Bin/../..";

#### EXTERNAL MODULES
use Data::Dumper;
use File::Path;
use JSON;
}

####/////}}}

#### PACKAGE INSTALLATION
method install {

	$self->logDebug("DOING setUpInstall");
	$self->setUpInstall();

	$self->logDebug("DOING runInstall");	
	return $self->runInstall();
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
	$self->logError("repotype not defined") and exit if not defined $repotype;
	$self->logError("repository not defined") and exit if not defined $repository;
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
	my $opsdir			=	$self->opsdir();
	my $package		=	$self->package();
	$self->logDebug("opsdir", $opsdir);
	$self->logDebug("package", $package);

	#### LOAD OPS MODULE IF PRESENT
	$self->logDebug("self->opsmodloaded()", $self->opsmodloaded());
	$self->loadOpsModule($opsdir, $package) if not $self->opsmodloaded();

	#### LOAD OPS INFO IF PRESENT
	$self->loadOpsInfo($opsdir, $package) if not defined $self->opsinfo();
}

method runInstall {
	#### SET USER AND REPO NAMES
	my $selectedversion	=	$self->version();
	my $installdir		=	$self->installdir();
	my $opsdir			=	$self->opsdir();
	my $repository		=	$self->repository();
	my $package			=	$self->package();
	my $owner 			= 	$self->owner();
	my $username		=	$self->username();
	my $login			=	$self->login();
	my $keyfile			=	$self->keyfile();
	my $hubtype			=	$self->hubtype();
	my $sessionid		=	$self->sessionId();
	my $privacy 		= 	$self->privacy();
	my $credentials 	= 	$self->credentials();

	#### COLLAPSE PATHS
	$installdir = $self->installdir($self->collapsePath($installdir));
	$opsdir = $self->opsdir($self->collapsePath($opsdir));

	#### SET DATABASE HANDLE IF NOT DEFINED
	$self->setDbObject();

	#### SET DEFAULT KEYFILE 
	$keyfile = $self->setKeyfile($username, $hubtype) if defined $keyfile or not $keyfile;

	$self->logDebug("selectedversion", $selectedversion);
	$self->logDebug("package", $package);
	$self->logDebug("installdir", $installdir);
	$self->logDebug("opsdir", $opsdir);
	$self->logDebug("repository", $repository);
	$self->logDebug("owner", $owner);
	$self->logDebug("username", $username);
	$self->logDebug("sessionid", $sessionid);
	$self->logDebug("self->db()", $self->db());

	my  $random 		= 	$self->random();
	$self->logDebug("random", $random);

	#### SET USERNAME
	if ( not defined $username ) {

		$username = $self->conf()->getKey('agua', 'ADMINUSER');
		$self->username($username);
	}

	#### CHECK INPUTS
	$self->logCritical("installdir not defined", $installdir) and exit if not defined $installdir;
	$self->logCritical("repository not defined", $repository) and exit if not defined $repository;
	$self->logCritical("owner not defined", $owner) and exit if not defined $owner;

	#### VALIDATE VERSION IF SUPPLIED, OTHERWISE SET TO LATEST VERSION
	my $version = $self->validateVersion($owner, $repository, $privacy, $selectedversion);
	$self->logDebug("version not defined") and exit if not defined $version;
	$self->logDebug("version", $version);
	$self->version($version);

	#### SET DATABASE OBJECT
	$self->setDbObject() if not defined $self->db();

	##### START LOGGING TO HTML FILE
	$self->startHtmlLog();

	#### STORE PWD
	$self->pwd($Bin);

	#### PRE-INSTALL
	$self->logDebug("before if ( self->can(preInstall) )");
	if ( $self->can('preInstall') ) {
		$self->logDebug("Doing self->preInstall");
		my $report = $self->preInstall();
		$self->logDebug("AFTER self->preInstall");

		#### FLUSH STDOUT
		$| = 1;
		$self->updateReport([$report]) if defined $report and $report;
		$| = 1;
	}	

	#### UPDATE PACKAGE STATUS
	$self->updateStatus("installing");
	$self->updateReport(["Updated status to 'installing'"]);
	$| = 1;

	$self->updateReport(["Installation directory: $installdir"]);		

	#### CHECK IF REPO EXISTS
	$self->logDebug("installdir", $installdir);
	my $found = $self->foundDir($installdir);
	$self->logDebug("found", $found);

	#### ADD HUB TO /root/.ssh/authorized_hosts FILE	
	$self->addHubToAuthorizedHosts($login, $hubtype, $keyfile, $privacy);

	#### CLONE REPO IF NOT EXISTS
	if ( $found == 0 ) {
		$self->updateReport(["Cloning from remote repo: $repository (owner: $owner)"]);
		$self->logDebug("Cloning from remote repo");
		$self->logDebug("installdir not found. Cloning repo $repository (owner: $owner)");
		
		#### PREPARE DIRS
		my ($basedir, $subdir) = $self->getParentChildDirs($installdir);
		$self->logDebug("basedir", $basedir);
		$self->logDebug("subdir", $subdir);
		`mkdir -p $basedir` if not -d $basedir;
		$self->logCritical("Can't create basedir", $basedir) if not -d $basedir;

		#### CLONE REPO
		$self->changeToRepo($basedir);
		$self->logDebug("keyfile", $keyfile);
		$self->logDebug("Doing self->cloneRemoteRepo()");
		$self->logDebug("FAILED to clone repo") and return if not $self->cloneRemoteRepo($owner, $repository, $hubtype, $login, $privacy, $keyfile, $subdir);
	}
	
	#### OTHERWISE, MOVE TO REPO AND PULL
	else {
		$self->updateReport(["Pulling from remote repo: $repository (owner: $owner)"]);
		$self->logDebug("Pulling from remote repo");

		#### PREPARE DIR
		$self->changeToRepo($installdir);	
		$self->initRepo($installdir) if not $self->foundGitDir($installdir);
	
		#### fetch FROM REMOTE AND DO HARD RESET
		$self->logDebug("FAILED to fetch repo") and return if not $self->fetchResetRemoteRepo($owner, $repository, $hubtype, $login, $privacy, $keyfile);
	
		#### SAVE ANY CHANGES IN A SEPARATE BRANCH
		$self->saveChanges($installdir, $version);
	}
	
	##### CHECKOUT SPECIFIC VERSION
	$self->logDebug("Doing changeToRepo installdir", $installdir);
	my $change = $self->changeToRepo($installdir);
	$self->logDebug("change", $change);
	
	$self->checkoutTag($installdir, $version);
	$self->updateReport(["Checked out version: $version"]);
	$self->logDebug("checked out version", $version);

	#### VERIFY CHECKED OUT VERSION = DESIRED VERSION
	$self->verifyVersion($version, $installdir) if $self->foundGitDir($installdir);
	$self->version($version);
	
	#### POST-INSTALL
	if ( $self->can('postInstall') ) {
		$self->updateReport(["Doing postInstall"]);
		my $report = $self->postInstall();
		$self->logDebug("postInstall report", $report);
		$self->updateReport([$report]) if defined $report and $report;
	}

	#### UPDATE PACKAGE VERSION
	$self->logDebug("Doing updateVersion");
	$self->updateVersion($version);
	
	#### UPDATE PACKAGE STATUS
	$self->updateStatus("ready");	
	$self->updateReport(["Updated status to 'ready'"]);

	#### REPORT VERSION
	$self->updateReport(["Completed installation, version: $version"]);

	#### TERMINAL INSTALL
	if ( $self->can('terminalInstall') ) {
		$self->updateReport(["Running terminalInstall method"]);
		my $report = $self->terminalInstall if $self->can('terminalInstall');
		$self->updateReport([$report]) if defined $report and $report;
	}
	
	#### E.G., DEBUG/TESTING
	return $self->report();
}

method saveChanges ($installdir, $version) {
	$self->changeToRepo($installdir);
	my $stash = $self->stashSave("before upgrade to $version");
	$self->logDebug("stash", $stash);
	if ( $stash ) {
		$self->updateReport(["Stashed changes before checkout version: $version"]);
	}	
}

method runCustomInstaller ($command) {
	$self->logDebug("command", $command);
	print $self->runCommand($command);
}

method verifyVersion ($version, $installdir) {
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

#### LOG
method setLogFile ($package, $random) {
	my $htmldir = $self->conf()->getKey('agua', 'HTMLDIR');
	my $logfile = "$htmldir/log/$package-upgradelog.$random.html";
	$self->logfile($logfile);
	
	return $logfile;
}

method setHtmlLogFile () {
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

method startHtmlLog () {

	my $logfile = $self->setHtmlLogFile();
	$self->logDebug("logfile", $logfile);
	my  $package 		= $self->package();
	my 	$version 		= $self->version();

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
	
	#### CREATE LOGFILE
	$self->SHOWLOG(2);
	$self->PRINTLOG(2);
	$self->logDebug("Doing self->startLog($source)");
	$self->startLog($source);
	
	#### SET SOURCE AS LOGFILE
	$self->logfile($source);

	$self->logDebug("Doing logReport(page)");
	$self->logReport($page);
	$self->logDebug("AFTER logReport(page)");
	
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
	my $pmfile 	= 	"$opsdir/" . lc($repository) . ".pm";
	my $location    = 	lc($repository) . ".pm";
	$self->logDebug("pmfile: $pmfile");
	my $modulename = lc($repository);
	
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
	}
	$self->opsmodloaded(1);
}

method loadOpsInfo ($opsdir, $package) {
	$self->logDebug("opsdir", $opsdir);
	$self->logDebug("package", $package);
	
	return if not defined $opsdir or not $opsdir;
	my $opsfile 	= 	"$opsdir/$package.ops";
	$self->logDebug("opsfile: $opsfile");
	
	if ( -f $opsfile ) {
		$self->logDebug("Parsing opsfile");
		my $opsinfo = $self->setOpsInfo($opsfile);
		$self->logDebug("opsinfo", $opsinfo);
		$self->opsinfo($opsinfo);
	}
}

method loadConfig ($configfile, $mountpoint) {
	my $packageconf = Conf::Agua->new({
		inputfile	=>	$configfile,
		SHOWLOG		=>	2
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
			$self->logNote("value", $value);
			$self->conf()->setKey($sectionkey, $key, $value);
		}
	}	
}

method loadTsvFile ($table, $file) {
	return if not $self->can('db');
	
	$self->logDebug("table", $table);
	$self->logDebug("file", $file);
	
	$self->setDbh() if not defined $self->db();
	return if not defined $self->db();print Dumper ;
	my $query = qq{LOAD DATA LOCAL INFILE '$file' INTO TABLE $table};
	my $success = $self->db()->do($query);
	$self->logCritical("load data failed") if not $success;
	
	return $success;	
}
#### UPDATE
method updateConfig ($sourcefile, $targetfile) {
	$self->logDebug("sourcefile", $sourcefile);
	$self->logDebug("targetfile", $targetfile);

	my $sourceconf = Conf::Agua->new({
		inputfile	=>	$sourcefile,
		SHOWLOG		=>	2
	});
	$self->logNote("sourcefile: $sourcefile");

	my $targetconf = Conf::Agua->new({
		inputfile	=>	$targetfile,
		SHOWLOG		=>	2
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
	
	my $where = $self->db()->where($object, $required);
	my $query = qq{SELECT 1 FROM $table $where};
	$self->logDebug("query", $query);
	my $exists = $self->db()->query($query);

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

method updateStatus ($status) {
	#### UPDATE DATABASE
	my $object = {
		username	=>	$self->username(),
		owner		=>	$self->owner(),
		package		=>	$self->package(),
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
		package		=>	$self->repository(),
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

method validateVersion ($owner, $repository, $privacy, $selectedversion) {
#### VALIDATE VERSION IF SUPPLIED, OTHERWISE SET TO LATEST VERSION
	$self->logDebug("owner", $owner);
	$self->logDebug("repository", $repository);
	$self->logDebug("privacy", $privacy);
	$self->logDebug("selectedversion", $selectedversion);
	
	my $tags = $self->getRemoteTags($owner, $repository, $privacy);
	$self->logDebug("no tags present in repository") and return $selectedversion if not defined $tags or not @$tags;
	#$self->logDebug("tags", $tags);
	my $validated = 0;
	foreach my $tag ( @$tags ) {
		$validated = 1 if defined $selectedversion and $tag->{name} eq $selectedversion;
	}
	if ( $validated )	{
		return $selectedversion;
	}
	elsif ( defined $selectedversion ) {
		$self->logWarning("Could not validate version: $selectedversion") and return;
	}
	
	#### SORT VERSIONS
	my $tagarray;
	$tagarray = $self->hasharrayToArray($tags, "name");

	$tagarray = $self->sortVersions($tagarray);
	$self->logDebug("tagarray", $tagarray);
	
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
		SHOWLOG		=>	$self->SHOWLOG(),
		PRINTLOG	=>	$self->PRINTLOG()
	});
	#$self->logDebug("opsinfo", $opsinfo);

	return $opsinfo;
}



1;

