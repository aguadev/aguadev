use MooseX::Declare;

use strict;
use warnings;

class Test::GT::Fuse extends GT::Fuse {

has 'logfile'	=> 	( isa => 'Str|Undef', is => 'rw', required => 1 );
has 'uuid'		=> 	( isa => 'Str|Undef', is => 'rw', default => "916d6813-e7df-422a-a1d9-6b9eeebfe277" );
has 'gtrepo'	=>	( isa => 'Str|Undef', is => 'rw', default	=>	"https://cghub.ucsc.edu/cghub/data/analysis/download");
has 'cachedir'		=> 	( isa => 'Str|Undef', is => 'rw', lazy	=>	1, 	builder => 	"getCacheDir");
has 'mountdir'		=> 	( isa => 'Str|Undef', is => 'rw', lazy	=>	1,	builder	=>	"getMountDir");

use FindBin qw($Bin);
use Test::More;

#####////}}}}}

method removeOutputs {
	my $cachedir	=	$self->cachedir();
	$self->runCommand("rm -fr $cachedir");	

	my $mountdir	=	$self->mountdir();
	$self->runCommand("rm -fr $mountdir");	
	
	#my $homedir		=	$self->getHomeDir();
	#my $configfile	=	$self->getConfigFile($homedir);
	#$self->runCommand("rm -fr $configfile");
}

method getCacheDir {
	return "$Bin/outputs/tmp/fusecache";
}
method getMountDir {
	return "$Bin/outputs/tmp/fusemnt";
}
method getHomeDir {
	return "$Bin/outputs";
}
method identicalFiles ($actualfile, $expectedfile) {
	$self->logDebug("actualfile", $actualfile);
	$self->logDebug("expectedfile", $expectedfile);
	
	my $command = "diff -wB $actualfile $expectedfile";
	$self->logDebug("command", $command);
	my $diff = `$command`;
	
	return 1 if $diff eq '';
	return 0;
}

method testCreateDirs {
	#### REMOVE OUTPUTS
	$self->removeOutputs();
	
	#### SET VARIABLES
	my $uuid	=	$self->uuid();
	my $cachedir	=	$self->cachedir();
	my $mountdir	=	$self->getMountDir();
	$self->logDebug("uuid", $uuid);
	$self->logDebug("cachedir", $cachedir);
	$self->logDebug("mountdir", $mountdir);

	my $uuidmount	=	"$mountdir/$uuid";
	$self->logDebug("uuidmount", $uuidmount);
	
	ok(! -d $cachedir, "cachedir cleared: $cachedir");
	ok(! -d $mountdir, "mountdir cleared: $mountdir");
	ok(! -d $uuidmount, "uuidmount cleared: $uuidmount");	
	
	$self->createDirs($uuid, $cachedir, $mountdir);
	
	ok(-d $cachedir, "cachedir created: $cachedir");
	ok(-d $mountdir, "mountdir created: $mountdir");
	ok(-d $uuidmount, "uuidmount created: $uuidmount");	
}

method testDownloadKeyFile {
	my $keyfile		=	$self->keyfile();
	my $homedir		=	$self->getHomeDir();
	my $filepath	=	"$homedir/$keyfile";
	$self->runCommand("rm -fr $filepath*");
	
	#### VERIFY FILE CLEARED
	ok(! -f $filepath, "keyfile cleared: $filepath");
	
	#### DOWNLOAD KEYFILE
	$self->downloadKeyFile();

	#### VERIFY FILE CREATED
	ok(-f $filepath, "keyfile created: $filepath");
}
method testCreateConfigFile {
	#### REMOVE OUTPUTS
	$self->removeOutputs();

	#### VERIFY FILE REMOVED
	my $homedir		=	$self->getHomeDir();
	my $configfile	=	$self->getConfigFile($homedir);
	ok(! -f $configfile, "configfile cleared: $configfile");
	
	#### CREATE CONFIG FILE
	$self->createConfigFile();

	#### VERIFY CREATED	
	ok(-f $configfile, "configfile created: $configfile");
	
	#### SET EXPECTED FILE
	my $expectedfile	=	"$Bin/inputs/.gtfuse.cfg";
	$self->setExpectedFile($expectedfile, $homedir, $self->keyfile(), $self->cachedir());

	#### VERIFY IDENTICAL
	ok($self->identicalFiles($configfile, $expectedfile), "configfile contents verified");
}

method setExpectedFile ($expectedfile, $homedir, $keyfile, $fusecache) {
	my $templatefile	=	"$expectedfile.template";
	my $contents	=	`cat $templatefile`;
	$self->logDebug("contents", $contents);
	$contents	=~ s/<CREDENTIAL-FILE>/$homedir\/$keyfile/ms;
	$contents	=~ s/<FUSECACHE>/$fusecache/ms;
	$self->logDebug("contents", $contents);
	
	`cat <<EOF > $expectedfile
$contents
EOF`;
}

method testMount {
	##### REMOVE OUTPUTS
	#$self->removeOutputs();
	#
	###### DOWNLOAD KEYFILE
	##$self->downloadKeyFile();
	#
	##### CREATE DIRECTORIES
	#$self->createDirs($self->uuid(), $self->cachedir(), $self->mountdir());
	#
	#### CREATE CONFIG
	my $configfile	=	$self->createConfigFile();

	my $uuidmount	=	$self->mountdir() . "/" . $self->uuid();
#$self->logDebug("DEBUG EXIT") and exit;

	$self->cleanUp($self->uuid(), $self->cachedir(), $self->mountdir());

	$self->mount($self->uuid(), $self->gtrepo(), $self->mountdir(), $configfile)
}

method testMountSample () {
	#$self->logDebug("uuid", $uuid);
	#$self->logDebug("gtrepo", $gtrepo);

	#my $cachedir	=	$self->cachedir();
	#my $mountdir	=	$self->mountdir();
	#$self->logDebug("cachedir", $cachedir);
	#$self->logDebug("mountdir", $mountdir);	
	#
	##### UNMOUNT
	#$self->unmount($uuid, $mountdir);
	#
	##### REMOVE OLD DIRECTORIES, AND LOCK FILES
	#$self->cleanUp($uuid, $cachedir, $mountdir);
	#
	##### CREATE DIRECTORIES IF MISSING
	#$self->createDirs($uuid, $cachedir, $mountdir);
	#
	##### CREATE CONFIG
	#$self->createConfigFile();
	#
	##### MOUNT
	#$self->mount($uuid, $gtrepo, $mountdir);
}

method testCleanUp () {
	##### UNMOUNT
	#$self->runCommand("fusermount -u $mountdir/$uuid");
	#
	##### CLEAN UP FILES/DIRS
	#$self->logDebug("cachedir", $cachedir);
	#
	#my $lockfile	=	"$cachedir/$uuid/$uuid.lock";
	#my $reservationfile	=	"$cachedir/$uuid/$uuid.reservation";
	#my $gtofile	=	"$cachedir/$uuid/$uuid.gto";
	#
	#print $self->runCommand("rm -fr $lockfile") if -f $lockfile;
	#print $self->runCommand("rm -fr $reservationfile") if -f $reservationfile;
	#print $self->runCommand("rm -fr $gtofile") if -f $gtofile;
	#
	##### REMOVE CACHECIR	
	#my $uuiddir	=	"$cachedir/$uuid";
	#print $self->runCommand("rm -fr $uuiddir") if -f $uuiddir;
}


method testUnmountSample () {
	##### REMOVE OLD DIRECTORIES, AND LOCK FILES
	#cleanUp($uuid);
}

method testUnmount () {
	##### UNMOUNT
	#$self->runCommand("fusermount -u $mountdir/$uuid");	
}



}

