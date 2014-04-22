use MooseX::Declare;
use Method::Signatures::Simple;

class Test::Agua::Ops::Install with (Agua::Common::Package,
	Test::Agua::Common::Database,
	Test::Agua::Common::Util,
	Agua::Common::Database,
	Agua::Common::Logger,
	Agua::Common::Privileges,
	Agua::Common::Stage,
	Agua::Common::App,
	Agua::Common::Parameter,
	Agua::Common::Base,
	Agua::Common::Util) extends Agua::Ops {

use Data::Dumper;
use Test::More;
use Test::DatabaseRow;
use Agua::DBaseFactory;
use Agua::Ops;
use Agua::Instance;
use Conf::Yaml;
use FindBin qw($Bin);

# Ints
has 'showlog'		=>  ( isa => 'Int', is => 'rw', default => 2 );  
has 'printlog'		=>  ( isa => 'Int', is => 'rw', default => 5 );

# Strings
has 'installdir'	=> ( isa => 'Str|Undef', is => 'rw' );
has 'logfile'       => ( isa => 'Str|Undef', is => 'rw' );
has 'owner'	        => ( isa => 'Str|Undef', is => 'rw' );
has 'package'		=> ( isa => 'Str|Undef', is => 'rw' );
has 'remoterepo'	=> ( isa => 'Str|Undef', is => 'rw' );
has 'dumpfile'		=> ( isa => 'Str|Undef', is => 'rw' );
has 'database'		=> ( isa => 'Str|Undef', is => 'rw' );
#has 'sessionid'     => ( isa => 'Str|Undef', is => 'rw' );

# Objects
has 'json'			=> ( isa => 'HashRef', is => 'rw', required => 0 );
has 'conf' 	=> (
	is =>	'rw',
	isa => 'Conf::Yaml',
	default	=>	sub { Conf::Yaml->new(	memory	=>	1	);	}
);

####////}}

method BUILD ($hash) {	
	foreach my $key ( keys %$hash ) {
		$self->$key($hash->{$key}) if defined $hash->{$key} and $self->can($key);
	}
}

#### TEST INSTALL AGUA
method testInstallAgua {
	diag("Test installAgua");

	#### SET LOG
	my $pwd = $self->pwd();
	my $logfile = "$pwd/outputs/install-agua.log";
	$self->logfile($logfile);
	$self->startLog($logfile);
	
	#### SET WWW DIRECTORY
	my $wwwdir = "$pwd/outputs/log";
	$self->conf()->setKey("agua", "WWWDIR", $wwwdir);
	`mkdir -p $wwwdir` if not -d $wwwdir;
	$self->logCritical("Can't create wwwdir", $wwwdir) and exit if not -d $wwwdir;
	
	#### LOAD DATABASE
	$self->setUpTestDatabase();
	
	#### SET VARIABLES
    $self->owner("agua");
	$self->repository("agua");
	$self->version(undef);
	$self->package("agua");
	$self->hubtype("github");
	$self->privacy("public");
	$self->username($self->conf()->getKey("database", "TESTUSER"));
	$self->branch("master");
	$self->installdir("$Bin/outputs/agua");	
	$self->opsdir("$Bin/../../../../../biorepository/syoung/agua");

	#### TEST INSTALL
	$self->logDebug("Doing _testInstall");
	$self->_testInstall();	

	#### VERIFY DATABASE ENTRY
	$self->verifyEntry();
}

#### TEST AGUA terminalInstall
method testTerminalInstall {
	diag("Test terminalInstall");
	my $installdir = $self->installdir();
	$self->logDebug("installdir", $installdir);
	my $login = $self->login();
	$self->logDebug("login", $login);
	
	#### SET LOG
	my $pwd = $self->pwd();
	my $logfile = "$pwd/outputs/install-agua.log";
	$self->logfile($logfile);
	$self->startLog($logfile);
	
	#### SET WWW DIRECTORY
	my $wwwdir = "$pwd/outputs/log";
	$self->conf()->setKey("agua", "WWWDIR", $wwwdir);
	`mkdir -p $wwwdir` if not -d $wwwdir;
	$self->logCritical("Can't create wwwdir", $wwwdir) and exit if not -d $wwwdir;
	
	#### LOAD DATABASE
	$self->setUpTestDatabase();
	
	#### SET VARIABLES
    $self->owner("agua");
	$self->repository("agua");
	$self->version(undef);
	$self->package("agua");
	$self->hubtype("github");
	$self->privacy("public");
	$self->username($self->conf()->getKey("database", "TESTUSER"));
	$self->branch("master");
	$self->opsdir("$installdir/repos/public/syoung/biorepository/syoung/agua");

	#### SET UP INSTALL
	$self->setUpInstall();
	
	#### TEST INSTALL
	$self->logDebug("Doing _testInstall");
	$self->terminalInstall();	

}


method runCustomInstaller ($command) {
$self->logDebug("command", $command);	
}

method verifyEntry {
	
	#### CHECK DATABASE ENTRY
	my $table = "package";
	my $hash = {
		owner		=>	$self->owner(),
		version		=>	$self->version(),
		status		=>	"ready",
		package		=>	$self->repository(),
		installdir	=>	$self->installdir(),
		opsdir		=>	$self->opsdir(),
		username	=>	$self->username()
	};
	my $fields = ["owner", "username", "installdir", "opsdir", "version", "status", "package"];
	ok($self->hasEntry($table, $hash, $fields), "install    package table entry");
}

#### TEST INSTALL BIOAPPS
method testInstallBioApps {
	diag("Test installBioApps");

	#### COPY INPUT DIRS
	$self->setUpDirs("$Bin/inputs/public", "$Bin/outputs/public");
	
	#### SET LOG
	my $logfile = "$Bin/outputs/install-bioapps.log";
	$self->logfile($logfile);
	$self->startLog($logfile);
	
	#### LOAD DATABASE
	$self->setUpTestDatabase();
	
	#### SET VARIABLES
	my $pwd 		= $self->pwd($Bin);
    my $owner 		= $self->owner("agua");
    my $login 		= $self->login("syoung");

	my $version 	= $self->version(undef);
	my $hubtype 	= $self->hubtype("github");
	my $username 	= $self->username($self->conf()->getKey("database", "TESTUSER"));
	my $branch 		= $self->branch("master");

	#my $opsrepo		= $self->opsrepo("biorepository");
	#my $repository 	= $self->repository("bioapps");
	#my $package 	= $self->package("bioapps");
	#my $privacy 	= $self->privacy("public");
	#my $installdir 	= $self->installdir("$Bin/outputs/agua/bioapps");	

	my $opsrepo		= $self->opsrepo("biorepodev");
	my $repository 	= $self->repository("bioappsdev");
	my $package 	= $self->package("bioapps");
	my $privacy 	= $self->privacy("private");
	my $installdir 	= $self->conf()->getKey("agua", "INSTALLDIR");	



	my $opsdir 		= $self->opsdir("$installdir/repos/$privacy/$login/$opsrepo/$login/$package");

	####my $opsdir 		= $self->opsdir("$Bin/outputs/$privacy/$opsrepo/$login/$repository");
	my $appdir		= $self->appdir("$Bin/outputs/$privacy/$login/$opsrepo/$login/$package/apps");
	
	##### CREATE APP FILES
	#$self->createBioAppFiles($owner, $package, $username, "$opsdir/apps");
	
	#### CREATE SOURCE FILES
	$self->createSourceFiles($owner, "$opsdir/sources");

	#### TEST INSTALL
	$self->_testInstall();

	#### VERIFY DATABASE ENTRY
	$self->verifyEntry();
}

method createBioAppFiles ($owner, $package, $username, $appdir) {
	$self->logDebug("Bin", $Bin);
	
	my $appfile = "$Bin/inputs/tsv/app.tsv";
	my $parameterfile = "$Bin/inputs/tsv/parameter.tsv";
	$self->loadTsvFile("app", $appfile);
	$self->loadTsvFile("parameter", $parameterfile);
	
	#### SELECT FROM DATABASE
	my $query = qq{SELECT * FROM app WHERE owner='$owner' AND package='$package'};
	my $apps = $self->db()->queryhasharray($query);
	$apps = [] if not defined $apps or not $apps;
	$self->logDebug("no. apps", scalar(@$apps));
	
	#### CREATE APP FILES	
	foreach my $app ( @$apps ) {
		$app->{appname} = $app->{name};
		#$self->logDebug("app", $app);
		my $parameters = $self->getParametersByApp($app);
		$parameters = [] if not defined $parameters;
		$self->logDebug("no. parameters", scalar(@$parameters));

		$self->_createAppFile($app, $parameters, $username, $appdir);
	}
}

#### TEST INSTALL TESTS
method testInstallTests {
	diag("Test installTests");

	#### COPY INPUT DIRS
	$self->setUpDirs("$Bin/inputs/public", "$Bin/outputs/public");
	
	#### SET LOG
	my $logfile = "$Bin/outputs/install-testuser.log";
	$self->logfile($logfile);
	$self->startLog($logfile);
	
	#### LOAD DATABASE
	$self->setUpTestDatabase();
	
	#### SET VARIABLES
    my $owner 		= $self->owner("agua");
	my $repository 	= $self->repository("aguatestdev");
	my $package 	= $self->package("aguatestdev");
	#my $hubtype 	= $self->hubtype("github");
	my $version 	= $self->version(undef);
	my $privacy 	= $self->privacy("private");
	my $username 	= $self->username($self->conf()->getKey("database", "TESTUSER"));
	my $branch 		= $self->branch("master");
	my $opsdir 		= $self->opsdir("$Bin/outputs/public/biorepository/syoung/$username");
	my $installdir 	= $self->installdir("$Bin/outputs/agua/t");	
	
	#### TEST INSTALL
	$self->_testInstall();

	#### VERIFY DATABASE ENTRY
	$self->verifyEntry();
}

method _testInstall {
	#### GET LATEST VERSION IF NOT DEFINED
	my $installversion = $self->version();
	if ( not defined $self->version() ) {
		$installversion = $self->currentRemoteTag($self->login(), $self->repository(), $self->privacy());
		$self->logDebug("installversion", $installversion);
		$self->version($installversion);
	}

	#### DO INSTALL
	my $report = $self->install();
	$self->logDebug("report", $report);

	#### SET VERSION TO REPORTED VERSION
	my $version = $self->parseReport($report);
	$self->logDebug("version", $version);
	$self->logCritical("reported version is not defined") and return if not defined $version or not $version;
	$self->version($version);
	
	#### INSTALLED IS LATEST VERSION
	ok($installversion eq $version, "install    installed version");
	
	$self->logDebug("completed");
}

#### TEST PARSE REPORT
method testParseReport {
	diag("Test parseReport");

	my $reportfiles = [
		"$Bin/inputs/report/report1.txt",
		"$Bin/inputs/report/report2.txt",
		"$Bin/inputs/report/report3.txt"
	];
	my $expected = [
		"0.8.0-alpha.1+build7",
		"0.8.0-alpha.1+build7",
		"0.7.2"
	];
	
	for ( my $i = 0; $i < @$reportfiles; $i++ ) {
		my $reportfile = $$reportfiles[$i];
		my $report = $self->fileContents($reportfile);
		my $version = $self->parseReport($report);
		$self->logDebug("version", $version);
		
		is($version, $$expected[$i], "correct version: $version");
	}
}

method parseReport ($report) {
	my ($version) = $report =~ /^.+Completed\s+installation,\s+version:\s+(\S+)/ms;
	$self->logDebug("version", $version);
	
	return $version;
}

method hasEntry ($table, $hash, $fields) {
	$fields 	=	$self->db()->fields($table) if not defined $fields;
	my $where 	= 	$self->db()->where($hash, $fields);
		
	#### FILTER BACKSLASHES
	$where =~ s/\\\\/\\/g;
	my $query = qq{SELECT 1 FROM $table $where};
	$self->logDebug("query", $query);
	return $self->db()->query($query);
}

method setDbObject {
	#$self->logCaller("");
	$self->conf()->inputfile($self->conffile()) if defined $self->conffile();
	$self->logDebug("self->conf()->inputfile not defined") and return if not defined $self->conf()->inputfile() and not defined $self->conf();
	
	my $database 	= 	$self->database();
	my $user		=	$self->user();
	my $password	=	$self->password();

	$self->logNote("BEFORE database", $database);
	$self->logNote("BEFORE user", $user);
	$self->logNote("BEFORE password", $password);
		
	$database 	=	$self->conf()->getKey("database", "TESTDATABASE") if not defined $database;
	$user 		= 	$self->conf()->getKey("database", "TESTUSER") if not defined $user;
	$password 	= 	$self->conf()->getKey("database", "TESTPASSWORD") if not defined $password;
	
	$self->logNote("AFTER database", $database);
	$self->logNote("AFTER user", $user);
	$self->logNote("AFTER password", $password);
	
	$self->logDebug("database not defined. Returning") and return if not defined $database;
	$self->logDebug("user not defined. Returning") and return if not defined $user;
	$self->logDebug("password not defined. Returning") and return if not defined $password;

	require Agua::DBaseFactory;
	Moose::Util::apply_all_roles($self, 'Agua::Common::Database');	
	
	return $self->setDbh({
		database 	=>	$database,
		user		=>	$user,
		password	=>	$password
	});
}

method fakeTermination ($sleep) {
	#### DO NOTHING
}

#### TEST CONFIG
method testLoadConfig {
	my $originalfile	=	"$Bin/inputs/conf/load-original.conf";
	my $inputfile		=	"$Bin/outputs/conf/load.conf";
	my $packageconf		=	"$Bin/inputs/conf/bioapps.conf";
	my $expectedfile	=	"$Bin/inputs/conf/load-expected.conf";
	
	#### GET INSTALLDIR
	my $installdir = $self->installdir();
	$self->logDebug("installdir", $installdir);

	#### CREATE CONF FILE DIRECTORY
	my $confdir = "$Bin/outputs/conf";
	`mkdir -p $confdir` if not -d $confdir;
	$self->logError("Can't create confdir: $confdir") and exit if not -d $confdir;
	
	#### REFRESH INPUT FILE
	$self->setUpFile($originalfile, $inputfile);
	
	my $conf = Conf::Yaml->new({
		inputfile	=>	$inputfile,
		showlog		=>	2
	});
	$self->conf($conf);
	
	my $mountpoint = "/data2";
	$self->loadConfig($packageconf, $mountpoint, $installdir);

	ok($self->diff($expectedfile, $inputfile), "loadConfig    expected file output");
	
	#### RESET CONFIG
	$self->conf()->inputfile("$installdir/conf/config.yaml");
	$self->conf()->sections(undef);
}

method testUpdateConfig {
	my $originalfile	=	"$Bin/inputs/conf/update-original.conf";
	my $targetfile		=	"$Bin/outputs/conf/update.conf";
	my $sourcefile		=	"$Bin/inputs/conf/update-source.conf";
	my $expectedfile	=	"$Bin/inputs/conf/update-expected.conf";
	
	#### CREATE CONF FILE DIRECTORY
	my $confdir = "$Bin/outputs/conf";
	`mkdir -p $confdir` if not -d $confdir;
	$self->logError("Can't create confdir: $confdir") and exit if not -d $confdir;
	
	#### REFRESH INPUT FILE
	$self->setUpFile($originalfile, $targetfile);
	
	#### UPDATE CONFIG
	$self->updateConfig($sourcefile, $targetfile);

	#### CONFIRM OUTPUT
	ok($self->diff($expectedfile, $targetfile), "updateConfig    expected file output")
}



}