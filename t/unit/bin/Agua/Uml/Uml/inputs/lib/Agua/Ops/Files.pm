package Agua::Ops::Files;
use Moose::Role;
use Method::Signatures::Simple;

#### METHODS FOR MANAGING AND MANIPULATING FILES/DIRS
#### DIRECTORIES
method makeDir($directory) {
	return $self->createDirectory($directory);
}

method createDirectory ($directory) {
#### CREATE DIRECTORY
    $self->logDebug("Creating directory", $directory);
	return $self->runCommand("mkdir -p $directory");
}

method removeDir($directory) {
	return $self->removeDirectory($directory);
}

method removeDirectory ($directory) {
#### REMOVE DIRECTORY
    $self->logDebug("Removing directory", $directory);
	return $self->runCommand("rm -fr $directory");
	#return $self->foundDirectory($directory);
}

method foundDir($directory) {
	return $self->foundDirectory($directory);
}

method foundDirectory ($directory) {
	my $command = qq{if [ -d $directory ]; then echo 1; else echo 0; fi};
	my ($found) = $self->chompCommand($command);
	
	$self->logDebug("returning found", $found);
	return $found;
}

#### FILES
method foundFile ($file) {
	my $command = qq{if [ -f $file ]; then echo "1"; else echo "0"; fi};
	my ($output, $error) = $self->chompCommand($command);
	$self->logDebug("output", $output);
	$self->logDebug("error", $error);
	
	return $output;
}

method copyFile ($source, $destination) {
	my $command = "cp -r $source $destination";
	$self->logDebug("command", $command);
	
	return $self->runCommand($command) if not defined $self->ssh();
	return $self->sshCommand($command);
}

method copyDir ($source, $destination) {
	$self->copyFile($source, $destination);
}

method backupFile ($source, $target) {
    $self->logError("source not defined") and exit if not defined $source;
    $self->logError("target not defined") and exit if not defined $target;
    $self->logError("Can't find source: $source") and exit if not -f $source and not -d $source;
    $self->logDebug("source", $source);
	$self->logDebug("target", $target);

	#### CREATE BACKUP DIR IF NOT EXISTS
    my ($backupdir) = $target =~ /^(.+?)\/[^\/]+$/;
    $self->logDebug("backupdir", $backupdir);
	$self->createDirectory($backupdir);
	
	#### COPY ORIGINAL TO BACKUP
    return $self->copyFile($source, $target);
}

method backupDir ($source, $target) {
	return $self->backupFile($source, $target);
}

method moveFile ($source, $destination) {	
	my $command = "mv $source $destination";
	return $self->runCommand($command) if not defined $self->ssh();
	return $self->sshCommand($command);
}

method uploadFile ($source, $destination) {
	my $ssh = $self->ssh();
	my $output = $ssh->scp_put($source, $destination);
	$self->logDebug("output", $output);
	my $error = $ssh->error;
	$self->logDebug("error", $error);
	$self->logError("Failed to upload $source to $destination\nerror message: $error") and exit if $error and not $self->warn();
	#my $command = "scp $source $userhost:$destination";
	#return `$command`;
}

method downloadFile ($source, $destination) {
	my $ssh = $self->ssh();
	my $output = $ssh->scp_get($source, $destination);
	$self->logDebug("output", $output);
	my $error = $ssh->error;
	$self->logDebug("error", $error);
	$self->logError("Failed to download $source to $destination\nerror message: $error") and exit if $error and not $self->warn();
}


#### LINK METHODS
method linkFound ($link) {
	$self->logNote("link", $link);
	my $command = qq{if [ -L $link ]; then echo 1; else echo 0; fi};
	my ($found) = $self->chompCommand($command);
	$self->logNote("found", $found);
	
	return 1 if $found == 1;
	return '';
}

method addLink ($source, $target) {
	my $command = "ln -s $source $target";
	$self->logNote("command", $command);
    $self->runCommand($command);
	$self->logError("Could not create link: $target") and exit if not $self->linkFound($target);
}

method removeLink ($link) {
	$self->runCommand("rm -fr $link");
	$self->logError("Could not remove link: $link") and exit if $self->linkFound($link);
}


1;
