use MooseX::Declare;
use Method::Signatures::Simple;

class Test::Agua::Common::Package::Upgrade with (Test::Agua::Common::Package,
	Agua::Common::Package,
	Test::Agua::Common::Database,
	Test::Agua::Common::Util,
	Agua::Common::Database,
	Agua::Common::Logger,
	Agua::Common::Project,
	Agua::Common::Workflow,
	Agua::Common::Privileges,
	Agua::Common::Stage,
	Agua::Common::App,
	Agua::Common::Parameter,
	Agua::Common::Base,
	Agua::Common::Util) extends Agua::Ops {

use Data::Dumper;
use Test::More;
use Agua::DBaseFactory;
use Agua::Ops;
use Agua::Instance;
use Conf::Yaml;
use FindBin qw($Bin);

####////}}

method BUILD ($hash) {
	$self->logDebug("");
	
	if ( defined $self->logfile() ) {
		$self->head()->ops()->logfile($self->logfile());
		$self->head()->ops()->keyfile($self->keyfile());
		$self->head()->ops()->SHOWLOG($self->SHOWLOG());
		$self->head()->ops()->PRINTLOG($self->PRINTLOG());
	}
}

#### UPGRADE/INSTALL
method testSetLoginCredentials {
	diag("Testing setLoginCredentials");
	
	#### LOAD DATABASE
	$self->setUpTestDatabase();
	$self->setDatabaseHandle();
	
	#### GET USERNAME
	my $username = $self->conf()->getKey("database", "TESTUSER");
	$self->logDebug("username", $username);
	
	my $privacies = [ "public", "private" ];
	
	my $hubtype = "github";
	
	foreach my $privacy ( @$privacies ) {
	
		#### SET OPSREPO
		my $opsrepo 	= 	$self->setOpsRepo($privacy);
		$self->logDebug("opsrepo", $opsrepo);
	
		#### SET LOGIN CREDENTIALS
		$self->logDebug("Doing setLoginCredentials    privacy: $privacy");
		my ($login, $token) = $self->setLoginCredentials($username, $hubtype, $privacy);
		
		$self->logDebug("login", $login);
		$self->logDebug("token", $token);
		my $credentials = $self->head()->ops()->credentials();
		$self->logDebug("self->head()->ops()->credentials", $credentials);
			
		if ( $privacy eq "public" ) {
			ok($credentials eq "", "no credentials for public repo");
		}
		else {
			ok($credentials ne "", "credentials required for private repo");
		}
	}
}

method testUpgrade {
	diag("Test testUpgrade");
    $self->logDebug("");

	#### LOAD DATABASE
	$self->setUpTestDatabase();
	$self->setDatabaseHandle();
		
	#### SET LOG
	my $logfile 	= 	"$Bin/outputs/upgrade.log";
	$self->logfile($logfile);
	$self->startLog($logfile);

	#### GET VARIABLES
	my $login 		=	$self->login();
	my $repository 	=	"testversion";
	my $branch		=	"master";
	my $privacy		=	"private";

	#### SET VARIABLES
	my $testuser 	= 	$self->conf()->getKey("database", "TESTUSER");
	$self->username($testuser);
	$self->owner($login);
	$self->branch($branch);
	$self->repository($repository);
	$self->package($repository);

	#### SET Bin
	my $aguadir		=	$self->conf()->getKey("agua", "INSTALLDIR");
	$Bin =~ s/^.+\/bin/$aguadir\/t\/bin/;
	$self->logDebug("Bin", $Bin);

	#### SET DIRS
	$self->installdir("$Bin/outputs/target");	
	$self->sourcedir("$Bin/outputs/source");
    $self->opsdir("$Bin/inputs/ops");

	#### SET SLEEP
	$self->upgradesleep(0);
	
	#### CREATE TEMP REPO
	$self->setUpRepo();

	#### RUN TESTS
	my $versions = [ "0.2.0", "0.3.0", "0.1.0", "0.4.0", "0.5.0", undef ];
	foreach my $version ( @$versions ) {
		$self->testUpgradeCycle($version);
	}

	##### SHOULD NOT WORK
	my $version = $self->validateVersion($login, $repository, $privacy, "0.6.0");
	ok( ! $version, "correctly fails to validate incorrect version: 0.6.0");

	#### DELETE TEMP REPO
    $self->deleteRepo($login, $repository);
}

method testUpgradeCycle ($version) {
	#### SET LOG
	$self->logfile("$Bin/outputs/upgrade.log");

	#### SET VERSION
	$self->version($version);

    #### RUN UPGRADE
    $self->upgrade();
    
    ##### CHECK TAG NUMBER
    $self->checkTag();

    #### CHECK TABLE ENTRY
    $self->checkTableEntry("package");	
}

method checkTag {
    my $installdir = $self->installdir();
    $self->changeToRepo("$installdir");    
    my ($tag) = $self->currentLocalTag();
    $self->logDebug("tag", $tag);
    my $version = $self->version();
    $self->logDebug("version", $version);
    ok($tag eq $version, "retrieved tag ($tag) is the same as the desired version ($version)");
}

method checkTableEntry ($table) {
    
	my $fields = [
		"username",
        "owner",
        "package",
        "opsdir",
        "installdir",
        "version",
		"status"
	];
	$self->logDebug("fields", $fields);

	my $hash = {
        username    =>  $self->username(),
        owner       =>  $self->owner(),
        package 	=>  $self->package(),
        opsdir      =>  $self->opsdir(),
        installdir  =>  $self->installdir(),
        version     =>  $self->version(),
		status		=>	"ready"
	};
	$self->logDebug("hash", $hash);
	
	my $where = $self->db()->where($hash, $fields);
	$self->logDebug("where", $where);

	my $query = qq{SELECT 1 FROM $table $where};
	$self->logDebug("query", $query);
	ok($self->db()->query($query), "field values");
}

method printLogUrl {
	#### DO NOTHING
}

method startUpgradeLog ($package, $version, $logfile, $url) {
#### CREATE LOGFILE
	#$self->logDebug("logfile", $logfile);
	#$self->LOG(3);
    $version = "none" if not defined $version;
	$self->startLog($logfile);
	my $datetime = `date`;
	$self->logDebug($datetime);
    $self->logDebug("package:\t$package\nversion:\t$version\n");
}


method setOpsDir ($username, $repository, $privacy, $package) {
	return $self->opsdir();
}   #### Test::Agua::Common::Package


}
	