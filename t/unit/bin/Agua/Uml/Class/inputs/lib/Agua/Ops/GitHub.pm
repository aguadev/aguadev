package Agua::Ops::GitHub;
use Moose::Role;
use Method::Signatures::Simple;
use JSON;
=head2

	PACKAGE		Agua::Ops::GitHub
	
	PURPOSE
	
		ROLE FOR GITHUB REPOSITORY ACCESS AND CONTROL

=cut
# Ints
has 'sleep'		=> ( is  => 'rw', 'isa' => 'Int', default	=>	600	);

# Strings
has 'hubtype'	=> ( isa => 'Str|Undef', is => 'rw', default	=> 'github'	);
has 'username'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
#has 'tempdir'	=> ( isa => 'Str|Undef', is => 'rw', default	=>	"/tmp"	);
has 'repository'=> ( isa => 'Str|Undef', is => 'rw'	);
has 'apiroot'	=> ( isa => 'Str|Undef', is => 'rw', default	=>	"https://api.github.com"	);
has 'githubapi'	=> ( isa => 'Str|Undef', is => 'rw', default	=>	"https://api.github.com"	);
has 'credentials'	=> ( is  => 'rw', 'isa' => 'Str|Undef', default	=> "" );
has 'gitssh'	=> ( is  => 'rw', 'isa' => 'Str|Undef' );

# Objects
#has 'opsdata'	=> ( isa => 'HashRef', is => 'rw', required	=>	0	);
has 'tag'		=> ( isa => 'HashRef', is => 'rw', required	=>	0	);
has 'tags'		=> ( isa => 'HashRef', is => 'rw', required	=>	0	);
has 'userinfo'	=> ( isa => 'HashRef', is => 'rw', required	=>	0	);
has 'search'	=> ( isa => 'HashRef', is => 'rw', required	=>	0	);
has 'trees'		=> ( isa => 'HashRef', is => 'rw', required	=>	0	);
has 'network'	=> ( isa => 'HashRef', is => 'rw', required	=>	0	);
has 'parser'=> (
	is 		=>	'rw',
	isa 	=> 'JSON',
	default	=>	sub { JSON->new();	}
);
has 'db'	=> ( is  => 'rw', 'isa' => 'Agua::DBase::MySQL', required	=>	0	);
has 'conf' 	=> (
	is =>	'rw',
	'isa' => 'Conf::Agua',
	default	=>	sub { Conf::Agua->new(	backup	=>	1, separator => "\t"	);	}
);

use FindBin qw($Bin);
use lib "$Bin/../..";

#### EXTERNAL MODULES
use Data::Dumper;
use File::Path;
use JSON;

####/////}}}

#### REMOTE COMMANDS
method curlCommand ($command) {
	$self->logCaller("");
	$self->logDebug("PASSED command", $command);
	my $credentials = $self->credentials() || '';
	$command = "curl $credentials $command";
	$self->logDebug("command", $command);
	my ($output, $error) = $self->runCommand($command);
	return '', $error if $output =~ /"message": "Not Found"/;
	return $output, $error;
}

method decodeJson ($json) {
	#$self->logDebug("json", $json);
	$self->logError("json not defined") and exit if not defined $json;	
	return if $json eq '';
	return $self->parser()->decode($json);
}

method setCredentials () {

	$self->logDebug("");
	my $login = $self->login();
	my $token = $self->token();
	$self->logCaller("");
	$self->logDebug("login", $login);
	$self->logDebug("token", $token);
	
	$self->logDebug("returning because login not defined or empty") if not defined $login or not $login;
	return '' if not defined $login;	
	$self->logDebug("returning because token not defined or empty") if not defined $token or not $token;
	return '' if not defined $token;
	return '' if not $login;	
	return '' if not $token;

	my $credentials = qq{-H 'Authorization: token $token'};
	$self->credentials($credentials);
	$self->logDebug("credentials", $credentials);
	
	return ($credentials);
}

#### OAUTH TOKENS
method getOAuthTokens ($login, $password) {
	
	$self->logDebug("login", $login);

	#### CREATE CURL AUTHENTICATION FILE
	my $loginfile	= $self->createLoginFile($login, $password);

	### DO ADD
	my $apiroot = $self->apiroot();
	my $command = qq(curl -K $loginfile $apiroot/authorizations);
	$self->logDebug("command", $command);
	my ($json) = $self->runCommand($command);

	#### REMOVE LOGIN FILE
	`rm -fr $loginfile`;

	my $object = $self->decodeJson($json);
	$self->logDebug("object", $object);

	return $object;
}

method isOAuthToken ($login, $password, $tokenid) {
	$self->logDebug("login", $login);
	$self->logDebug("tokenid", $tokenid);

	my $tokens 	=	$self->getOAuthTokens($login, $password);
	return 0 if not defined $tokens;
	foreach my $token ( @$tokens ) {
		return 1 if $token->{id} eq $tokenid;
	}

	return 0;
}

method addOAuthToken ($login, $password, $scopes, $name) {
	$self->logDebug("login", $login);
	$self->logDebug("scopes", $scopes);
	$self->logDebug("name", $name);
	$scopes = ["public_repo"] if not defined $scopes;
	$name = "auto" if not defined $name or not $name;
	
	#### CREATE LOGIN FILE
	my $loginfile = $self->createLoginFile($login, $password);
	
	### DO ADD
	my $apiroot = $self->apiroot();
	my $command = qq(curl -K $loginfile $apiroot/authorizations -d '{"note":"$name","scopes":[);
	my @scopearray = split ",", $scopes;
	$self->logDebug("scopearray", @scopearray);
	foreach my $scope ( @scopearray ) {
		$command .= '"' . $scope . '",';
	}
	$command =~ s/,$//;
	$command .= qq(]}');
	$self->logDebug("command", $command);
	
	my ($json) = $self->runCommand($command);
	my $object = $self->decodeJson($json);
	$self->logDebug("object", $object);
	$self->logDebug("object not defined") and exit if not defined $object;	

	my $token = $object->{token};
	$self->logDebug("token", $token);
	my $tokenid =	$object->{id};
	$self->logDebug("tokenid", $tokenid);
	$self->logError("token not defined") and exit if not defined $token;	
	$self->logError("tokenid not defined") and exit if not defined $tokenid;	

	#### REMOVE LOGIN FILE
	`rm -fr $loginfile`;

	return $token, $tokenid;
}

method removeOAuthToken ($login, $password, $tokenid) {

	#### CREATE CURL AUTHENTICATION FILE
	my $loginfile = $self->createLoginFile($login, $password);
	
	#### DO DELETE
	my $apiroot = $self->apiroot();
	my $command = qq(curl -X DELETE -K $loginfile $apiroot/authorizations/$tokenid);	
	$self->logDebug("command", $command);
	my $output = $self->runCommand($command);
	$self->logDebug("output", $output);
	
	#### REMOVE AUTHENTICATION FILE
	`rm -fr $loginfile`;

	return 1;
}

#### CLONE/PULL FROM GITHUB REMOTE
method getPrefix ($login, $hubtype, $keyfile, $privacy) {
	$self->logDebug("keyfile", $keyfile);
	my $prefix = '';
	return $prefix if $privacy eq "public";
	
	if ( $keyfile ) {
		my $gitssh = $self->setGitSsh($login, $hubtype, $keyfile);
		$prefix = "export GIT_SSH=$gitssh; ";
	}

	return $prefix;
}

method cloneRemoteRepo ($owner, $repository, $hubtype, $login, $privacy, $keyfile, $target) {
	$self->logDebug("keyfile", $keyfile);
	my $prefix = $self->getPrefix($login, $hubtype, $keyfile, $privacy);
	my $command = "git clone git://github.com/$owner/$repository.git $target  2>&1 ";
	$command = "$prefix git clone git\@github.com:$owner/$repository.git $target  2>&1" if $prefix;
	$self->logDebug("command", $command);

	my ($output, $error) = $self->repoCommand($command);
	$self->logDebug("output", $output);
	$self->logDebug("error", $error);
	
	return 0 if $output =~ /ERROR: Repository not found/ms
		or $output =~ /fatal: The remote end hung up unexpectedly/;
	return 1;
}

method fetchResetRemoteRepo ($owner, $repository, $hubtype, $login, $privacy, $keyfile) {
#### DO FETCH THEN HARD RESET (E.G., TO AVOID pull CONFLICTS)
	$self->logDebug("owner", $owner);
	$self->logDebug("repository", $repository);
	$self->logDebug("hubtype", $hubtype);
	$self->logDebug("login", $login);
	$self->logDebug("keyfile", $keyfile);

	my $prefix = $self->getPrefix($login, $hubtype, $keyfile, $privacy);
	my $command = "git fetch git://github.com/$owner/$repository.git ";
	$command = "$prefix git fetch git\@github.com:$owner/$repository.git " if $prefix;
	$self->logDebug("command", $command);

	my ($output, $error) = $self->runCommand($command);

	#### GET TAGS
	$command = "git fetch git://github.com/$owner/$repository.git --tags ";
	$command = "$prefix git fetch git\@github.com/$owner/$repository.git --tags " if $prefix;
	$self->logDebug("command", $command);
	($output, $error) = $self->runCommand($command);

	#### DO HARD RESET
	$command = "$prefix git reset --hard FETCH_HEAD 2> /dev/null ";
	$self->logDebug("command", $command);
	($output, $error) = $self->runCommand($command);
	$self->logDebug("output", $output);
	$self->logDebug("error", $error);

	return $output;
}

method pullRemoteRepo ($owner, $repository, $hubtype, $login, $privacy, $keyfile) {
	$self->logDebug("keyfile", $keyfile);
	my $prefix = '';
	if ( $privacy eq "private" ) {
		$prefix = $self->getPrefix($login, $hubtype, $keyfile, $privacy);
		$self->setGitSsh($login, $hubtype, $keyfile);
	}
	my $command = "git pull git://github.com/$owner/$repository.git 2> /dev/null ";
	$command = "$prefix git pull git\@github.com/$owner/$repository.git 2> /dev/null " if $prefix;
	$self->logDebug("command", $command);
	my ($output, $error) = $self->runCommand($command);

	#### GET TAGS
	$command = "git pull git://github.com/$owner/$repository.git --tags 2> /dev/null ";
	$command = "$prefix git pull git\@github.com/$owner/$repository.git --tags 2> /dev/null " if $prefix;
	$self->logDebug("command", $command);	
	($output, $error) = $self->runCommand($command);

	return $output;
}

method pushToRemote ($login, $hubtype, $remote, $branch, $keyfile, $privacy, $force) {
	$self->logDebug("keyfile", $keyfile);
	my $gitssh = $self->setGitSsh($login, $hubtype, $keyfile);
	my $prefix = "export GIT_SSH=$gitssh; ";
	
	my $command = "$prefix git push -u $remote $branch";
	$command .= " --force" if defined $force and $force;
	$self->logDebug("command", $command);

	return $self->repoCommand($command);
}

#### REMOTE
method isRemote ($login, $repository, $remote) {
	$self->logDebug("login", $login);
	$self->logDebug("repository", $repository);
	$self->logDebug("remote", $remote);
	
	my $command = "git remote --verbose";
	my ($output) = $self->repoCommand($command);
	$self->logDebug("output", $output);
	my $lines;
	@$lines = split "\n", $output;
	foreach my $line ( @$lines ) {
		use re 'eval';
		return 1 if $line =~ /^$remote\s+/;
		no re 'eval';		
	}

	$self->logDebug("Returning 0");
	return 0;
}

method removeRemote ($remote) {
	$remote = "master" if not defined $remote;
	$self->logDebug("remote", $remote);

	my $command = "git remote rm $remote";
	$self->repoCommand($command);
}

method addRemote ($login, $repository, $remote) {
	$remote = "master" if not defined $remote;
	$self->logError("login not defined") and exit if not defined $login;
	$self->logError("repository not defined") and exit if not defined $repository;

	$self->logDebug("login", $login);
	$self->logDebug("repository", $repository);
	$self->logDebug("remote", $remote);

	my $command = "git remote add $remote git\@github.com/$login/$repository.git";
	$self->repoCommand($command);
}

#### FILES
method fetchRepoFile ($login, $repository, $filepath) {
	$self->logDebug("login", $login);
	$self->logDebug("repository", $repository);
	$self->logDebug("filepath", $filepath);

	my $sha = $self->getFileSha($login, $repository, $filepath);	
$self->logDebug("sha", $sha);
	return if not defined $sha or not $sha;
	return $self->repoFileContents($login, $repository, $sha);
}

method getFileSha($login, $repository, $filepath) {
	my $githubapi = $self->githubapi();
	my $json = $self->curlCommand("$githubapi/repos/$login/$repository/git/trees/master?recursive=1");
	$self->logDebug("json", $json);
	my $object = $self->decodeJson($json);
	my $trees = $object->{tree};
	foreach my $tree ( @$trees ) {
		return $tree->{sha} if $tree->{path} eq $filepath;
	}
}

method repoFileContents ($login, $repository, $sha) {
# GET FILE CONTENTS BY URL (NB: AND SPECIAL MIME TYPE)
	my $githubapi = $self->githubapi();
	my $command = qq{curl $githubapi/repos/$login/$repository/git/blobs/$sha -H "Accept: application/vnd.github-blob.raw"};
	return $self->curlCommand($command);
}

#### REMOTE REPO
method searchRepos ($repository) {
	$self->logDebug("repository", $repository);
	my $apiroot = $self->apiroot();
	return $self->curlCommand("curl $apiroot/repos/search/$repository");
}

method getRepo ($login, $repository, $privacy) {

	$self->logDebug("login", $login);
	$self->logDebug("repository", $repository);
	$self->logDebug("privacy", $privacy);
	
	$self->setCredentials() if $privacy eq "private";
	my $apiroot = $self->apiroot();
	my $command = "$apiroot/repos/$login/$repository";
	my ($json) = $self->curlCommand($command);
	
	return $self->decodeJson($json);
}

method isRepo ($login, $repository, $privacy) {
	$self->logCaller("");
	my $object = $self->getRepo($login, $repository, $privacy);
	
	return 1 if defined $object and $object;
	return 0;
}

method forkPublicRepo ($login, $repository) {
	
	my $credentials = $self->setCredentials();
	my $apiroot = $self->apiroot();
	
	my $command = "curl -X POST $credentials $apiroot/repos/$login/$repository/forks";
	$self->logDebug("command", $command);
	
	my ($json) = $self->runCommand($command);
	#$self->logDebug("json", $json);

	return $self->decodeJson($json);
}

#### TAGS
method currentRemoteTag ($login, $repository, $privacy) {
	my $remotetags = $self->getRemoteTags($login, $repository, $privacy);
	$self->logDebug("remotetags", $remotetags);
	my $tags = $self->hasharrayToArray($remotetags, "name");
	$self->logDebug("tags", $tags);
	$tags = $self->sortVersions($tags);
	$self->logDebug("tags", $tags);
	my $latestversion;
	$latestversion = pop @$tags if defined $tags and @$tags;
	
	return $latestversion;
}

method getRemoteTagsTimeout ($login, $repository, $timeout) {	
	$self->logCaller("");
	$self->logDebug("login", $login);
	$self->logDebug("repository", $repository);

	#### SET CURL AUTHENTICATION FILE
	my $token 		=	$self->token();
	$self->logDebug("token", $token);
	my $contents 	= 	'';
	$contents = qq{header = "Authorization: token $token"} if defined $token;
	my $curlfile 	= 	$self->createCurlFile($login, $contents);

	#### RUN COMMAND
	my $apiroot 	= 	$self->apiroot();
	my $command = "curl --connect-timeout $timeout -K $curlfile $apiroot/repos/$login/$repository/tags";
	$self->logDebug("command", $command);
	my ($json, $error) = $self->runCommand($command);
	$self->logDebug("json", $json);
	$json = '' if $json =~ /"message": "Not Found"/;

	#### REMOVE CURL FILE
	`rm -fr $curlfile`;

	return $self->parseTags($json);
}

method getRemoteTags ($login, $repository, $privacy) {
	$self->logCaller("");
	$self->logDebug("login", $login);
	$self->logDebug("repository", $repository);
	$self->logDebug("privacy", $privacy);

	my $token 		=	$self->token();
	return $self->getPrivateRemoteTags($login, $repository, $token) if $privacy eq "private";
	
	#### RUN COMMAND
	my $apiroot 	= $self->apiroot();
	my $command 	= "curl $apiroot/repos/$login/$repository/tags";
	$self->logDebug("command", $command);
	my ($json) 		= $self->runCommand($command);	
	$self->logDebug("json", $json);

	return $self->parseTags($json);
}

method getPrivateRemoteTags ($login, $repository, $token) {
	#### SET CURL AUTHENTICATION FILE
	my $contents 	= 	qq{header = "Authorization: token $token"};
	my $curlfile 	= 	$self->createCurlFile($login, $contents);

	#### RUN COMMAND
	my $apiroot = $self->apiroot();
	my $command = "curl -K $curlfile $apiroot/repos/$login/$repository/tags";
	$self->logDebug("command", $command);
	my ($json) = $self->runCommand($command);	
	$self->logDebug("json", $json);

	#### REMOVE CURL FILE
	`rm -fr $curlfile`;

	return $self->parseTags($json);
	
}

method parseTags ($json) {
	my $objects = $self->decodeJson($json);
	$self->logDebug("objects", $objects);
	$self->logDebug("ref objects", ref($objects));
	return [] if not defined $objects;
	return [] if ref($objects) ne "ARRAY";
	
	my $tags = [];
	foreach my $object ( @$objects ) {
		push @$tags, {
			name 	=>	$object->{name},
			sha		=>  $object->{commit}->{sha}
		};
	}
	$self->logDebug("tags", $tags);

	return $tags;
}

#### FORKERS/USERS
method getForkers ($login, $repository) {
	my $apiroot = $self->apiroot();
	my $json = $self->curlCommand("$apiroot/repos/fork/$login/$repository/network");
	my $result = $self->decodeJson($json);
	return $result->{network};	
}

method getUserInfo ($username, $login, $token) {
	$self->logDebug("username", $username);
	$self->logDebug("login", $login);
	$self->logDebug("token", $token);
	return if not defined $username or not $username;
	return if not defined $login or not $login;
	return if not defined $token or not $token;
	
	#### CREATE CURL AUTHENTICATION FILE
	my $contents = qq{header = "Authorization: token $token"};
	my $curlfile = $self->createCurlFile($login, $contents);

	#### GET USER INFO
	my $apiroot = $self->apiroot();
	my $command = "curl -K $curlfile $apiroot/user";
	$self->logDebug("command", $command);
	my ($json) = $self->runCommand($command);
	$self->logDebug("json", $json);
	my $userinfo = $self->decodeJson($json);
	$self->logDebug("userinfo", $userinfo);

	#### REMOVE AUTHENTICATION FILE
	`rm -fr $curlfile`;
	
	return $userinfo;
}

#### ADD/DELETE REMOTE REPO
method createPrivateRepo ($login, $repository, $description) {
	$self->logDebug("login", $login);
	$self->logDebug("repository", $repository);
	
	my $privacy = "private";
	$self->createRepo($login, $repository, $privacy, $description);
}

method createPublicRepo ($login, $repository, $description) {
	$self->logDebug("login", $login);
	$self->logDebug("repository", $repository);

	my $privacy = "public";
	$self->createRepo($login, $repository, $privacy, $description);
}

method createRepo ($login, $repository, $privacy, $description) {
	$self->logError("repository not defined") and exit if not defined $repository;
	$self->logError("privacy not defined") and exit if not defined $privacy;
	$description = '' if not defined $description;	
	
	my $private = $privacy eq "private" ? 1 : 0;
	$self->logDebug("private", $private);
	
	my $apiroot = $self->apiroot();
	my $token = $self->token();
	$self->logCritical("token not defined") and exit if not defined $token;

	#### CREATE CURL AUTHENTICATION FILE
	my $contents = qq{header = "Authorization: token $token"};
	my $curlfile = $self->createCurlFile($login, $contents);

	my $command = qq{curl -X POST -K $curlfile $apiroot/user/repos -d '{"name":"$repository","description": "$description"}'};
	$command = qq{curl -X POST -K $curlfile $apiroot/user/repos -d '{"name":"$repository","description": "$description","private":$private}'} if $privacy eq "private";
	$self->logDebug("command", $command);
	
	my $sleep 	= 	0.5;
	my $tries 	=	5;
	my $errorregex	=	qq{"errors":};
	my $result = $self->repeatCommand($command, $sleep, $tries, $errorregex);
	
	#### REMOVE AUTHENTICATION FILE
	`rm -fr $curlfile`;

	return $result;
}

method deleteRepo ($login, $repository) {
	$self->logError("login not defined") and exit if not defined $self->login();
	$self->logError("token not defined") and exit if not defined $self->token();
	my $apiroot = $self->apiroot();
	my $token = $self->token();
	$self->logCritical("token not defined") and exit if not defined $token;

	#### CREATE CURL AUTHENTICATION FILE
	my $contents = qq{header = "Authorization: token $token"};
	my $curlfile = $self->createCurlFile($login, $contents);

	#### DELETE /repos/:user/:repo
	my $command = "curl -X DELETE -K $curlfile $apiroot/repos/$login/$repository";
	$self->logDebug("command", $command);
	my ($result) = $self->runCommand($command);
	$self->logDebug("result", $result);
	
	#### REMOVE AUTHENTICATION FILE
	`rm -fr $curlfile`;

	return 1 if $result eq '';
	return 0;
}

method setPrivate ($login, $repository) {
	$self->logError("login not defined") and exit if not defined $self->login();
	$self->logError("repository not defined") and exit if not defined $self->repository();

	#### GET CREDENTIALS
	my $credentials = $self->setCredentials();
	$self->logError("credentials not defined") and exit if not defined $self->credentials();
	$self->logError("credentials is empty") and exit if not $self->credentials();

	my $apiroot = $self->apiroot();
	my $command = qq{curl -X PATCH $credentials $apiroot/repos/$login/$repository -d '{"name":"$repository","private":true}'};
	$self->logDebug("command", $command);
	
	return $self->runCommand($command);	
}
method setPublic ($login, $repository) {
	$self->logError("login not defined") and exit if not defined $self->login();
	$self->logError("repository not defined") and exit if not defined $self->repository();

	#### GET CREDENTIALS
	my $credentials = $self->setCredentials();
	$self->logError("credentials not defined") and exit if not defined $self->credentials();
	$self->logError("credentials is empty") and exit if not $self->credentials();

	my $apiroot = $self->apiroot();
	my $command = qq{curl -X PATCH $credentials $apiroot/repos/$login/$repository -d '{"name":"$repository","private":false}'};
	$self->logDebug("command", $command);

	return $self->runCommand($command);	
}

#### SET ACCESS CREDENTIALS
method setGitSsh ($login, $hubtype, $keyfile) {
	$self->logDebug("login", $login);
	$self->logDebug("hubtype", $hubtype);
	$self->logDebug("keyfile", $keyfile);

	$login = $self->login() if not defined $login;
	$hubtype = $self->hubtype() if not defined $hubtype;
	$keyfile = $self->keyfile() if not defined $keyfile;

	#### CREATE KEYDIR IF NOT PRESENT
	my $keydir 		= 	$self->getHubKeyDir($login);
	`mkdir -p $keydir` if not -d $keydir;
	$self->logError("Can't create keydir", $keydir) and exit if not -d $keydir;

	#### SET GIT SSH FILE
	my $gitssh = "$keydir/git-ssh.sh";
	$self->gitssh($gitssh);

	#### CREATE DIR
	$self->logDebug("Doing createdir($keydir)");
	$self->createDir($keydir);

	#### PRINT FILE
	my $content = qq{#!/bin/sh
	
exec ssh -T -i $keyfile -o "StrictHostKeyChecking no" -o "IdentitiesOnly yes" "\$\@"

exit 0
};
	$self->logDebug("content", $content);
	`echo '$content' > $gitssh`;
	`chmod 700 $gitssh`;

	#### SET 'GIT_SSH'
	$self->runCommand("export GIT_SSH=$gitssh");
	
	#### SET 'GIT SSH KEYFILE'
	$self->runCommand("export GITSSH_KEYFILE=$keyfile");

	return $gitssh;
}

#### UTILS
method createCurlFile($login, $contents) {
#### CREATE CURL AUTHENTICATION FILE
	$self->logDebug("contents", $contents);

	#### CREATE KEYDIR IF NOT PRESENT
	my $keydir 		= 	$self->getHubKeyDir($login);
	`mkdir -p $keydir` if not -d $keydir;
	$self->logError("Can't create keydir", $keydir) and exit if not -d $keydir;

	my $curlfile	= 	"$keydir/curl.txt";
	$self->logDebug("curlfile", $curlfile);
	`touch $curlfile`;
	`chmod 600 $curlfile`;
	`echo '$contents' > $curlfile`;
	
	return $curlfile;
}

method createLoginFile($login, $password) {
#### CREATE CURL AUTHENTICATION FILE
	$self->logDebug("login", $login);
	$self->logDebug("password", $password);

	my $contents = "user = $login:$password";
	$self->logDebug("contents", $contents);

	#### CREATE KEYDIR IF NOT PRESENT
	my $keydir 		= 	$self->getHubKeyDir($login);
	`mkdir -p $keydir` if not -d $keydir;
	$self->logError("Can't create keydir", $keydir) and exit if not -d $keydir;

	my $loginfile	= 	"$keydir/curl.txt";
	$self->logDebug("loginfile", $loginfile);
	`touch $loginfile`;
	`chmod 600 $loginfile`;
	`echo '$contents' > $loginfile`;
	
	return $loginfile;
}

method getHubKeyDir ($login) {

	my $hubtype		=	$self->hubtype();
	$self->logDebug("login", $login);
	$self->logDebug("hubtype", $hubtype);
	$self->logError("login not defined") and exit if not defined $login;
	$self->logError("hubtype is empty") and exit if not $hubtype;

	my $installdir = $self->conf()->getKey("agua", 'INSTALLDIR');
	$self->logDebug("installdir", $installdir);	
	
	return "$installdir/conf/.repos/$hubtype/$login";
}

method hasharrayToArray ($hasharray, $key) {
	$self->logError("hasharray not defined.") and exit if not defined $hasharray;
	$self->logError("key not defined.") and exit if not defined $key;

	my $array = [];
	foreach my $entry ( @$hasharray )	{
		push @$array, $entry->{$key};
	}

	return $array;	
}

method addHubToAuthorizedHosts ($login, $hubtype, $keyfile, $privacy) {
	my $prefix = '';
	if ( $privacy eq "private" ) {
		$prefix = $self->getPrefix($login, $hubtype, $keyfile, $privacy);
		$self->setGitSsh($login, $hubtype, $keyfile);
	}
	my $command = "$prefix ssh -T git\@github.com -o StrictHostKeyChecking=no";
	$self->logDebug("command", $command);
	$self->runCommand($command);
}


1;

