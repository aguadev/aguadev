use MooseX::Declare;

use strict;
use warnings;

class Test::GT::Fuse extends GT::Fuse {

has 'logfile'	=> 	( isa => 'Str|Undef', is => 'rw', required => 1 );
has 'uuid'		=> 	( isa => 'Str|Undef', is => 'rw', default => "54b4c169-bdef-4d71-99be-f6458d753f1c" );
has 'gtrepo'	=>	( isa => 'Str|Undef', is => 'rw', default	=>	"https://cghub.ucsc.edu/cghub/data/analysis/download");
has 'cachedir'		=> 	( isa => 'Str|Undef', is => 'rw', lazy	=>	1, 	builder => 	"getCacheDir");
has 'mountdir'		=> 	( isa => 'Str|Undef', is => 'rw', lazy	=>	1,	builder	=>	"getMountDir");

use FindBin qw($Bin);
use Test::More;

#####////}}}}}

method removeOutputs ($uuid, $cachedir, $mountdir) {
	$self->logDebug("uuid", $uuid);
	$self->logDebug("cachedir", $cachedir);
	$self->logDebug("mountdir", $mountdir);

	#### UNFUSE IS STILL MOUNTED
	$self->unFuse($mountdir, $uuid);
	
	$self->runCommand("rm -fr $cachedir/$uuid*");	
	$self->runCommand("rm -fr $mountdir/$uuid");	
	
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
	return "$Bin/outputs/tmp";
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
	diag("mount");
	
	my $uuid		=	$self->uuid();
	my $mountdir	=	$self->mountdir();
	my $cachedir	=	$self->cachedir();
	
	#### REMOVE OUTPUTS
	$self->removeOutputs($uuid, $cachedir, $mountdir);
	
	#### COPY KEYFILE FROM inputs TO outputs
	$self->copyKeyFile();

	#### CREATE DIRECTORIES
	$self->createDirs($uuid, $cachedir, $mountdir);
	
	#### CREATE CONFIG
	my $configfile	=	$self->createConfigFile();

	#### RUN fusemount -u AND REMOVE ANY LINGERING LOCK FILES, ETC.
	$self->cleanUp($uuid, $cachedir, $mountdir);

	#### CONFIRM BAM FILE NOT PRESENT
	my $uuidmount	=	"$mountdir/$uuid";
	my $containerdir=	"$uuidmount/$uuid";
	my $filename	=	"HCC1143.7x.n25t65s10.bam";
	my $bamfile		=	"$uuidmount/$uuid/$filename";
	$self->logDebug("bamfile", $bamfile);

	#### CONFIRM NOT PRESENT
	ok(! -f $bamfile, "before mount: bamfile not present");
	ok(! -d $containerdir, "before mount: containerdir not present");
	ok(-d $uuidmount, "before mount: UUID mount directory present");

	#### MOUNT BAM FILE
	my $gtrepo		=	$self->gtrepo();
	$self->mount($uuid, $gtrepo, $mountdir, $configfile);
	
	#### CONFIRM BAM FILE PRESENT	
	ok(-d $uuidmount, "after mount: UUID mount directory present");
	ok(-d $containerdir, "after mount: containerdir present");
	ok(-f $bamfile, "after mount: bam file present");

	$self->cleanUp($uuid, $cachedir, $mountdir);
}

method testGetZombies {
	diag("getZombies");

	my $zombies	=	$self->getZombies();
	$self->logDebug("zombies", $zombies);
	my $expected	=	["11702","12203","12225","12599","12613"];
	
	is_deeply($zombies, $expected, "zombie pids");
}

method getPs {
	my $psfile	=	"$Bin/inputs/ps.txt";
	$self->logDebug("psfile", $psfile);
	open(FILE, $psfile) or die "Can't open psfile: $psfile\n";
	my @lines	=	<FILE>;
	close(FILE) or die "Can't close psfile: $psfile\n";
	#$self->logDebug("lines", @lines);
	
	return \@lines;
}

method copyKeyFile {
	my $keyfile		=	$self->keyfile();
	my $sourcefile	=	"$Bin/inputs/$keyfile";
	my $targetfile	=	"$Bin/outputs/$keyfile";
	$self->logDebug("sourcefile", $sourcefile);
	$self->logDebug("targetfile, $targetfile");
	
	$self->runCommand("rm -fr $targetfile");
	$self->runCommand("cp -f $sourcefile $targetfile");
}

method testMountSample {
	diag("mountSample");

	#### COPY KEYFILE FROM inputs TO outputs
	$self->copyKeyFile();

	my $tests	=	[
		{
			uuid		=>	"54b4c169-bdef-4d71-99be-f6458d753f1c",
			filename	=>	"HCC1143.7x.n25t65s10.bam"
		},
		{
			uuid		=>	"eaa56631-c802-47ff-8118-3ed40d10302b",
			filename	=>	"HCC1954.7x.n25t55s20.bam"
		}
	];
	
	my $gtrepo	=	$self->gtrepo();
	my $mountdir	=	$self->mountdir();
	my $cachedir	=	$self->cachedir();

	foreach my $test ( @$tests ) {
		my $uuid		=	$test->{uuid};
		my $filename	=	$test->{filename};
		
		$self->uuid($uuid);
		
		#### REMOVE OUTPUTS
		$self->removeOutputs($uuid, $cachedir, $mountdir);
		
		#### CONFIRM BAM FILE NOT PRESENT
		my $uuidmount	=	"$mountdir/$uuid";
		my $containerdir=	"$uuidmount/$uuid";
		my $bamfile	=	"$mountdir/$uuid/$uuid/$filename";

		#### CONFIRM NOT PRESENT
		ok(! -f $bamfile, "before mount: bamfile not present");
		ok(! -d $containerdir, "before mount: containerdir not present");
	
		#### MOUNT BAM FILE
		$self->mountSample($uuid, $gtrepo);
		
		#### CONFIRM BAM FILE PRESENT	
		ok(-d $uuidmount, "after mount: UUID mount directory present");
		ok(-d $containerdir, "after mount: containerdir present");
		ok(-f $bamfile, "after mount: bam file present");

		#### CLEAN UP
		$self->cleanUp($uuid, $cachedir, $mountdir);
	}
}



}

