use MooseX::Declare;
class agua extends Agua::Ops {

use Data::Dumper;

has 'installdir'=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'version'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
#has 'repo'		=> ( isa => 'Str|Undef', is => 'rw', default	=> 'bitbucket'	);
has 'repo'		=> ( isa => 'Str|Undef', is => 'rw', default	=> 'github'	);

####///}}}}

sub install {
	my $self		=	shift;

	my $version		=	$self->version();
	my $installdir	=	$self->installdir();
	$installdir = "/agua" if not defined $installdir;
	my $credentials = 	$self->credentials();
	#print "agua.pm    credentials: $credentials\n" if defined $credentials;
	
	#### GET TAGS
	my $tags = $self->getRepoTags("syoung", "agua");
	#print "agua.pm    tags: \n";	print Dumper $tags;
	#my $contents = $self->fetchRepoFile("syoung", "biorepository", "README");
	#my $contents = $self->fetchRepoFile("syoung", "biorepository", "syoung/README");
	#print "contents not defined\n" and exit if not defined $contents;
	#print "contents: $contents\n";
	
	my $validversion = 0;
	print "agua.pm    version: $version\n" if defined $version;
	foreach my $tag ( @$tags ) {
		$validversion = 1 if defined $version and $tag->{name} eq $version;
	}
	#print "validversion: $validversion\n";
	
	#### CREATE DOWNLOAD DIR AND MOVE TO IT
	my $subdir = "temp";
	$self->changeDir($installdir);
	$self->makeDir($subdir);
	$self->changeDir($subdir);

	#### DOWNLOAD SPECIFIC VERSION *.tar.gz FILE		
	if ( defined $version and $validversion) {
		print "agua.pm    Downloading version: $version\n";
		$self->runCommand("curl https://nodeload.github.com/syoung/agua/zipball/$version > $installdir/$subdir/agua-$version.tar.gz");
		$self->runCommand("tar xvfz agua-$version.tar.gz");
	}
	#### OTHERWISE, DOWNLOAD THE LATEST BUILD
	else {
		print "agua.pm    Downloading latest build\n";	
		$self->cloneRemoteRepo("syoung", "agua");
	}
	
	#### CHANGE TO DOWNLOADED REPO	
	my $temprepo = "$installdir/$subdir/agua";
	$self->localrepo($temprepo);
	$self->changeDir($temprepo);

	#### GET VERSION, ITERATION AND BUILD OF DOWNLOAD
	my $localtags = $self->getLocalTags();
	@$localtags = sort @$localtags;
	$version = $$localtags[scalar(@$localtags) - 1];
	my $iteration = $self->currentIteration();
	my $localbuild = $self->currentBuild();
	print "agua.pm    version: $version\n";
	print "agua.pm    iteration: $iteration\n";		
	print "agua.pm    build: $localbuild\n";
	
	#### SET CORRECT REPO DIRECTORY
	my $repodir = "$installdir/$version-$iteration-$localbuild";
	print "agua.pm    repodir: $repodir\n";
	
	##### BACKUP ANY EXISTING REPO DIRECTORY
	my $backup = $self->incrementFile($repodir);
	print "agua.pm    backup: $backup\n";
	$self->backupFile($temprepo, $backup) if $self->dirFound($repodir);
	$self->removeDir($repodir);
	
	#### MOVE REPO TO CORRECT REPO DIRECTORY
	$self->runCommand("mv $temprepo $repodir");
	$self->changeDir($repodir);
	
	#### LINK TO VERSION
	my $versiondir = "$installdir/$version";
	$self->removeLink($versiondir);
	$self->addLink($repodir, $versiondir);
	
	#### INSTALL
	$self->changeDir("$installdir/$version/bin/scripts");
	print $self->runCommand("$installdir/$version/bin/scripts/install.pl --installdir $installdir");		
}

}