use MooseX::Declare;
use Method::Signatures::Simple;

class Test::Agua::Ops::GitHub with (Agua::Common::Package,
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
has 'SHOWLOG'		=>  ( isa => 'Int', is => 'rw', default => 2 );  
has 'PRINTLOG'		=>  ( isa => 'Int', is => 'rw', default => 5 );

# Strings
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



#### TEST GET USER INFO
method testGetUserInfo {
	diag("Test getUserInfo");
	
	my $username = $self->username();
	my $login = $self->login();
	my $token = $self->token();

	my $userinfo = $self->getUserInfo($username, $login, $token);
	$self->logDebug("userinfo", $userinfo);
	
	ok($userinfo->{login} eq $login, "getUserInfo");
}

#### TEST SET CREDENTIALS
method testSetCredentials {
	diag("Test setCredentials");
	
	#### SET LOG
	my $pwd = $self->pwd();
	my $logfile = "$pwd/outputs/credentials.log";
	$self->logfile($logfile);
	$self->startLog($logfile);
	
	#my $privacies = [ "public", "private" ];
	my $privacies = [ "private", "public" ];
	my $hubtype = "github";
	
	#### CREATE PUBLIC OR PRIVATE REPO AND TEST
	#### ACCESS AFTER self->setCredentials
	foreach my $privacy ( @$privacies ) {
		
		my $credentials = '';
		$credentials = $self->setCredentials() if $privacy eq "private";
		$self->logDebug("credentials", $credentials);
			
		if ( $privacy eq "public" ) {
			ok($credentials eq "", "no credentials for public repo");
		}
		else {
			ok($credentials ne "", "credentials required for private repo");
		}
		
	}
}

#### TEST GET REPO
method testGetRepo {
	diag("Test getRepo");
	
	#### SET LOG
	my $pwd = $self->pwd();
	my $logfile = "$pwd/outputs/getrepo.log";
	$self->logfile($logfile);
	$self->startLog($logfile);
	
	#### GET LOGIN
	my $login 		= "agua";	
	my $repository 	= "agua";	
	my $privacy 	= "public";	
	ok($self->getRepo($login, $repository, $privacy), "getRepo");
}

#### TEST GET REMOTE TAGS
method testGetRemoteTags {
	diag("Test getRemoteTags");
	
	#### SET LOG
	my $pwd = $self->pwd();
	my $logfile = "$pwd/outputs/getremotetags.log";
	$self->logfile($logfile);
	$self->startLog($logfile);
	
	#### VARIABLES
	my $owner 		= 	"agua";	
	my $repository 	= 	"agua";	
	my $privacy 	= 	"public";
	$self->privacy($privacy);
	
	ok(scalar(@{$self->getRemoteTags($owner, $repository, $privacy)}) != 0, "getRemoteTags");
}


#### TEST CREATE REPO
method testCreateRepo {
	diag("Test createRepo");
	
	#### SET LOG
	my $pwd = $self->pwd();
	my $logfile = "$pwd/outputs/createrepo.log";
	$self->logfile($logfile);
	$self->startLog($logfile);
	
	#### GET LOGIN
	my $login = $self->login();	
	
	#### CREATE PUBLIC OR PRIVATE REPO AND TEST DELETE
	#my $privacies = [ "public", "private" ];
	my $privacies = [ "public" ];
	my $hubtype = "github";
	foreach my $privacy ( @$privacies ) {
	
		#### SET OPSREPO
		my $repository	= "testcreate-" . $privacy;
		$self->logDebug("repository", $repository);
		
		my $isrepo = $self->isRepo($login, $repository, $privacy);
		$self->logDebug("isrepo", $isrepo);
		$self->deleteRepo($login, $repository) if $isrepo;
		sleep(3);
		
		if ( $privacy eq "public" ) {
			$self->logDebug("Doing createPublicRepo()");
			my $description = "My public repo";
			$self->createPublicRepo($login, $repository, $description);
			ok($self->isRepo($login, $repository, $privacy), "createPublicRepo");
		}
		else {
			
			$self->logDebug("Doing createPrivateRepo()");
			my $description = "My private repo";
			$self->createPrivateRepo($login, $repository, $description);
			ok($self->isRepo($login, $repository, $privacy), "createPrivateRepo");
		}

		
		$self->logDebug("Deleting repo...");
		$self->deleteRepo($login, $repository);

		ok( $self->isRepo($login, $repository, $privacy) == 0, "deleteRepo");
	}
}

#### TEST CREATE REPO
method testForkRepo {
	diag("Test forkRepo");
	
	#### SET LOG
	my $pwd = $self->pwd();
	my $logfile = "$pwd/outputs/getrepo.log";
	$self->logfile($logfile);
	$self->startLog($logfile);
	
	#### GET LOGIN
	my $login 		= 	$self->login();	
	my $repository 	= 	"agua";	
	my $privacy 	= 	"public";
	my $owner		=	"agua";
	ok($self->createRepo($login, $repository, $privacy, "createRepo"), "createRepo");
	ok($self->isRepo($login, $repository, $privacy), "isRepo");
	
	ok($self->forkPublicRepo($owner, $repository, $privacy), "forkRepo");
	ok($self->deleteRepo($login, $repository), "deleteRepo");
	ok(! $self->isRepo($login, $repository, $privacy), "repo absent after deleteRepo");
}

#### TEST ADD ACCESS TOKEN
method testAddOAuthToken {
	#### **** CREATE GITHUB OAUTH ACCESS TOKEN USING login AND password

	diag("Testing addOAuthToken");

	##### LOAD DATABASE
	$self->setUpTestDatabase();
	$self->setDatabaseHandle();

	#### LOAD DATA
	my $hubfile		=	"$Bin/inputs/tsv/workflows/hub.tsv";
	$self->loadTsvFile("hub", $hubfile);

	#### CREATE TOKEN
	my $scopes 		= 	"public_repo,repo,delete_repo";
	my $name		=	"agua";
	my $login		=	$self->login();
	my $password 	= 	$self->password();

	#### FIRST ADD
	my ($token, $tokenid) = $self->addOAuthToken($login, $password, $scopes, $name);
	$self->logDebug("token", $token);
	$self->logDebug("tokenid", $tokenid);
	ok($token, "First addOAuthToken");
	
	##### SECOND ADD (UPDATE)
	($token, $tokenid) = $self->addOAuthToken($login, $password, $scopes, $name);
	$self->logDebug("token", $token);
	$self->logDebug("tokenid", $tokenid);
	ok($token, "Second addOAuthToken");
	
	#### DELETE TOKEN
	ok($self->removeOAuthToken($login, $password, $tokenid), "removeAuthToken");
}

#### TEST REMOVE ACCESS TOKEN
method testRemoveOAuthToken {
	#### **** DELETE GITHUB OAUTH ACCESS TOKEN USING login AND password
	
	diag("Testing removeOAuthToken");

	##### LOAD DATABASE
	$self->setUpTestDatabase();
	$self->setDatabaseHandle();

	#### LOAD DATA
	my $hubfile	=	"$Bin/inputs/tsv/workflows/hub-remove.tsv";
	$self->loadTsvFile("hub", $hubfile);

	#### CREATE TOKEN
	my $scopes = "public_repo,repo,delete_repo";
	my $name = "agua";
	my $login		=	$self->login();
	my $password 	= 	$self->password();

	my ($token, $tokenid) = $self->addOAuthToken($login, $password, $scopes, $name);
	ok($token, "addOAuthToken");

	#### REMOVE TOKEN
	ok($self->removeOAuthToken($login, $password, $tokenid), "removeOAuthToken");

	#### CONFIRM TOKEN DELETED FROM HUB ACCOUNT
	ok(! $self->isOAuthToken($login, $password, $tokenid), "NOT isOAuthToken");
}


}