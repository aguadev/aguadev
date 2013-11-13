package Agua::Ops::Git;
use Moose::Role;
use Method::Signatures::Simple;
use JSON;
=head2

	PACKAGE		Agua::Ops::GitHub
	
	PURPOSE
	
		Moose ROLE FOR LOCAL REPO CREATION AND MANAGEMENT

=cut

if ( 1 ) {
has 'localrepo'	=> ( isa => 'Str|Undef', is => 'rw'	);

use FindBin qw($Bin);
use lib "$Bin/../..";

#### EXTERNAL MODULES
use Data::Dumper;
use File::Path;
use JSON;

}

####/////}}}

method repoCommand ($command) {
	$self->logCritical("localrepo not defined") and exit if not defined $self->localrepo();
	return $self->runCommand($command);
}

method changeToRepo ($directory) {
	
	#$self->logCaller("");
	#$self->logDebug("directory", $directory);	
	$self->logError("directory not defined") and exit if not defined $directory;
	$self->localrepo($directory);
	my ($result) = $self->changeDir($directory);
	#$self->logDebug("result", $result);
	
	return $result;
}

method exitRepo () {
	$self->logNote("");
	$self->clearChangeDir();
}
method foundGitDir ($directory) {
	$self->logCritical("directory not defined") and exit if not defined $directory;
	my $gitrefs = "$directory/.git";
	$self->logDebug("gitrefs", $gitrefs);
	my $lines = `find $gitrefs -type d -name refs 2> /dev/null`;
	return 1 if $lines;
	return 0;	
}

#### LOGS
method gitLog ($branch) {
	$branch = "HEAD" if not defined $branch;
	return $self->repoCommand("git log $branch");
}

method gitLogShort ($branch) {
	$branch = "HEAD" if not defined $branch;
	return $self->repoCommand("git log --short $branch");
}

method gitStatus {	
	#### FORCE ERROR OUTPUT TO STDERR
	my $oldwarn = $self->warn();
	$self->warn(1);
	my ($result, $error) = $self->repoCommand("git status");
	$self->warn($oldwarn);

	#### fatal: Not a git repository (or any of the parent directories): .git
	return 0 if $error =~ /Not a git repository/;
	return 1;	
}

#### CREATE/ADD/COMMIT TO REPO
method initRepo () {
	$self->logDebug("");
	my ($result, $error) = $self->repoCommand("git init");
	return 0 if defined $error and $error;
	return 1;	
}

method addToRepo {
	my ($result, $error) = $self->repoCommand("git add --ignore-errors .");
	$self->logDebug("result", $result);
	$self->logDebug("error", $error);
}

#### COMMIT/PUSH
method commitToRepo ($message) {
	#$self->logDebug("message", $message);
	my $command = "git commit -a";
	$command .= qq{ -m "$message" --cleanup=verbatim } if defined $message and $message; 
	$self->logDebug("command", $command);
	my ($result, $error) = $self->repoCommand($command);	
	$self->logDebug("result", $result) if $result;
	$self->logDebug("error", $error) if $error;
}

#### TAGS
method addLocalTag ($tag, $description) {
	$self->logDebug("tag", $tag);
	$self->logDebug("description", $description);
	my $command = qq{git tag -a $tag};
	$command .= qq{ -m "[$tag] $description"} if defined $description;
	$self->repoCommand($command);
}

method pushTags ($login, $hubtype, $remote, $branch, $keyfile) {
	$self->logDebug("remote", $remote);
	$self->logDebug("branch", $branch);
	$branch = '' if not defined $branch;

	my $gitssh = $self->setGitSsh($login, $hubtype, $keyfile);
	my $command = "export GIT_SSH=$gitssh; git push -u $remote $branch --tags";
	$self->logDebug("command", $command);
	$self->repoCommand($command);
}

method getLocalTags () {
	my ($output) = $self->repoCommand("git tag");
	my @tags = split "\n", $output;
	return \@tags;
}

method currentLocalTag () {
	my $command = "git describe --abbrev=0 --tags";
	$self->logDebug("command", $command);
	my ($output) = $self->repoCommand($command);
	$self->logDebug("output", $output);
	return $output;
}

method checkoutTag($repodir, $tag) {
	$self->logCaller("");
	$self->logDebug("repodir", $repodir);
	$self->logDebug("tag", $tag);

	my $gitdir = "$repodir/.git";
	$self->logError("Can't find gitdir: $gitdir") and exit if not -d $gitdir;
	$self->logError("Can't change to repo", $gitdir) and exit if not $self->changeToRepo($repodir);

	my $command = "git checkout $tag --force";
	$self->logDebug("command", $command);
	my ($output) = $self->repoCommand($command);
	$self->logDebug("output", $output);
	my @tags = split "\n", $output;
	return \@tags;
}

method stashSave($message) {
	#my $command = qq{git stash save --keep-index "$message"};
	my $command = qq{git stash save "$message"};
	$self->logDebug("command", $command);
	my ($result) = $self->repoCommand($command);
	$self->logDebug("result", $result);
	return 0 if $result =~ /No local changes to save/;
	
	return 1;
}
#### BRANCH
method checkoutBranch ($repodir, $branch) {
	$self->logDebug("repodir", $repodir);
	$self->logDebug("branch", $branch);

	my $gitdir = "$repodir/.git";
	$self->logError("Can't find gitdir: $gitdir") and exit if not -d $gitdir;
	$self->logError("Can't change to repo", $gitdir) and exit if not $self->changeToRepo($repodir);

	my $command = "git checkout $branch";
	$self->logDebug("command", $command);
	my ($output) = $self->repoCommand($command);
	$self->logDebug("output", $output);
}

#### VERSION
method currentIteration  {
	my ($iteration) = $self->repoCommand("git log --oneline | wc -l");
	$iteration =~ s/\s+//g;	
	$iteration = "0" x ( 5 - length($iteration) ) . $iteration;
	return $iteration;
}

method currentBuild {
	my ($build) = $self->repoCommand("git rev-parse --short HEAD");
	$build =~ s/\s+//g;
	
	return $build;
}

method currentVersion  {
	my ($version) = $self->repoCommand("git tag -ln");
	($version) = $version =~ /\n(\S+)[^\n]+$/;	
}

method lastRepoVersion ($tags) {
	$self->logDebug("tags", $tags);

	sub sort_tags {
		my ($aa) = $a->{name} =~ /([\.\d]+)/;
		my ($bb) = $b->{name} =~ /([\.\d]+)/;
	}

	@$tags = sort sort_tags (@$tags);
	$self->logDebug("tags", $tags);
	
	my $latest = shift @$tags;
	
	return $latest->{name};
}


#### GET/SETTERS
method getUserName {
	my $command = " git config --global user.name";
	my ($name) = $self->repoCommand($command);
	return $name;
}

method setUserName ($name) {
	my $command = " git config --global user.name $name";
	return $self->repoCommand($command);
}

method getUserEmail {
	my $command = " git config --global user.email";
	my ($email) = $self->repoCommand($command);
	return $email;
}

method setUserEmail ($email) {
	my $command = " git config --global user.email $email";
	return $self->repoCommand($command);
}



1;